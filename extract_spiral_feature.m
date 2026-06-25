% =========================================================================
% Copyright (c) 2024 Suchada Tantisatirapong
% Department of Biomedical Engineering, Faculty of Engineering
% Srinakhawirot University
% Email: suchadat@g.swu.ac.th
% All rights reserved.
% =========================================================================

%% --------------- Spiral Task (Updated v2) --------------------------- 
function [Features] = extract_spiral_feature(currentSubfolderPath, decode, fs_target, fc)

% --- Metadata Extraction ---
DominantHand = string(decode.DominantHand);
Subject_ID = string(decode.ID);

%% 1. Process Spiral Data logic
% Use fn Helper for Cleaning, Stroke Detection, Resampling และ Tremor Extraction
[Sp_signals, Sp_summary] = process_core_logic_spiral(decode, DominantHand, fs_target, fc);

%% 2. Compile Statistical Feature Table
% Use fn Helper for generataing statistics (Stats, SN, MSE) for 15 signals
Features = compile_feature_table_spiral(Sp_signals, Sp_summary, Subject_ID, 'Sp');

% Save the result
save(fullfile(currentSubfolderPath, Subject_ID + "_MSpiral.mat"), 'Features');

end

%% --- Helper: Core Logic for Spiral (Cleaning, Stroke Detection, Resampling, Tremor) ---
function [signals, kin_summary] = process_core_logic_spiral(decode, DominantHand, fs_target, fc)
    % Define field names for spiral data (Handle specific naming: LDX vs RDx)
    if DominantHand == 'R'
        NameX = 'Spiral' + DominantHand + 'Dx'; 
        NameY = 'Spiral' + DominantHand + 'Dy';
    else
        NameX = 'Spiral' + DominantHand + 'DX'; 
        NameY = 'Spiral' + DominantHand + 'DY';
    end
    NameT = 'Spiral' + DominantHand + 'Timestamp';
    NameP = 'Spiral' + DominantHand + 'PenPressure';
    
    % --- Data Cleaning ---
    X_raw = str2double(split(decode.(NameX)(1:end-2), ', '));
    Y_raw = str2double(split(decode.(NameY)(1:end-2), ', '));
    T_raw = str2double(split(decode.(NameT)(2:end-2), ', '));
    P_raw = str2double(split(decode.(NameP)(2:end-2), ', '));
    
    clean_mat = rmmissing([X_raw(:), Y_raw(:), T_raw(:), P_raw(:)]);
    X = clean_mat(:,1); Y = clean_mat(:,2); T = clean_mat(:,3); P = clean_mat(:,4);
    T = T - min(T);

    % % Get raw kinematic summary using calSP (Spiral Specific)
    % [~, ~, ~, ~, Ratio_pause, total_dur, smoothness, min_dl, max_dl] = calSP(X, Y, T);
    % kin_summary = {Ratio_pause, total_dur, smoothness, min_dl, max_dl};

    % --- Automatic Threshold for Stroke Detection ---
    dT = [0; diff(T)];
    med_dT = median(dT);
    mad_dT = mad(dT, 1);
    k = 350;
    gap_threshold = med_dT + max(k * mad_dT, 0.005);
    
    stroke_start_idx = [1; find(dT > gap_threshold); length(T)+1];
    
    % --- Filtering Setup ---
    dt_target = 1/fs_target;
    [b, a_filt] = butter(2, fc / (fs_target/2), 'high');
    
    X_res_all = []; Y_res_all = []; P_res_all = [];
    X_trem_all = []; Y_trem_all = []; P_trem_all = [];

    % --- Process Each Stroke ---
    for i = 1:(length(stroke_start_idx)-1)
        idx_start = stroke_start_idx(i);
        idx_end = stroke_start_idx(i+1) - 1;
        T_s = T(idx_start:idx_end);
        X_s = X(idx_start:idx_end);
        Y_s = Y(idx_start:idx_end);
        P_s = P(idx_start:idx_end);

        if length(T_s) < 15 || (T_s(end) - T_s(1) < 15*dt_target), continue; end

        t_steps = (T_s(1) : dt_target : T_s(end))';
        if length(t_steps) < 15, continue; end
        
        X_res = interp1(T_s, X_s, t_steps, 'pchip');
        Y_res = interp1(T_s, Y_s, t_steps, 'pchip');
        P_res = interp1(T_s, P_s, t_steps, 'pchip');

        X_tremor = filtfilt(b, a_filt, X_res);
        Y_tremor = filtfilt(b, a_filt, Y_res);
        P_tremor = filtfilt(b, a_filt, P_res);

        X_res_all = [X_res_all; X_res];
        Y_res_all = [Y_res_all; Y_res];
        P_res_all = [P_res_all; P_res];
        X_trem_all = [X_trem_all; X_tremor];
        Y_trem_all = [Y_trem_all; Y_tremor];
        P_trem_all = [P_trem_all; P_tremor];
    end
    
    % Final Tremor Pass
    X_trem_all = filtfilt(b, a_filt, X_trem_all);
    Y_trem_all = filtfilt(b, a_filt, Y_trem_all);
    P_trem_all = filtfilt(b, a_filt, P_trem_all);

     % Get raw kinematic summary using calSP (Spiral Specific)
    [~, ~, ~, ~, Ratio_pause, total_dur, smoothness, min_dl, max_dl] = calSP(X_res_all, Y_res_all, (0:fs_target:fs_target*(length(X_res_all)-1))');
    kin_summary = {Ratio_pause, total_dur, smoothness, min_dl, max_dl};


    % --- Feature Extraction (Kinematics & Angular) ---
    vx = [0; diff(X_res_all) / dt_target];
    vy = [0; diff(Y_res_all) / dt_target];
    v_abs = sqrt(vx.^2 + vy.^2);
    accel = [0; diff(v_abs) / dt_target];
    jerk  = [0; diff(accel) / dt_target];

    dx = diff(X_res_all); dy = diff(Y_res_all);
    theta = [0; unwrap(atan2(dy, dx))];
    afi = [0; diff(theta) / dt_target];
    aai = [0; diff(afi) / dt_target];

    pv = [0; diff(P_res_all)];
    pa = [0; diff(pv) / dt_target];
    pj = [0; diff(pa) / dt_target];

    % Package signals (15 signals total)
    signals.P = P_res_all; signals.X = X_res_all; signals.Y = Y_res_all;
    signals.Ptrem = P_trem_all; signals.Xtrem = X_trem_all; signals.Ytrem = Y_trem_all;
    signals.Pv = pv; signals.Pa = pa; signals.Pj = pj;
    signals.V = v_abs; signals.A = accel; signals.J = jerk;
    signals.Theta = theta; signals.Afi = afi; signals.Aai = aai;

    % z-score normalization
    signals = structfun(@(x) zscore(x), signals, 'UniformOutput', false);
end

%% --- Helper: Compile Stats into Table (Standardized with Letters v2) ---
function Tbl = compile_feature_table_spiral(S, K, ID, tag)
    [Ratio_pause, total_dur, smoothness, min_dl, max_dl] = K{:};
    
    fields = {'P','X','Y','Ptrem','Xtrem','Ytrem','Pv','Pa','Pj','V','A','J','Theta','Afi','Aai'};
    short_names = {'p','x','y','pt','xt','yt','pv','pa','pj','v','a','j','th','afi','aai'};
    
    all_names = {'Subject_ID', [tag '_Ratio_pause'], [tag '_total_duration'], [tag '_smoothness'], ...
                 [tag '_Min_dlocs'], [tag '_Max_dlocs']};
    
    current_data = [Ratio_pause, total_dur, smoothness, min_dl, max_dl];
    
    % Loop through 15 signals
    for i = 1:length(fields)
        sig = S.(fields{i});
        s_name = [tag '_' short_names{i}];
        
        [f_sig, se_sig] = calSN(sig, (1:length(sig))');
        [sSTD, sVAR, sMEAN, sMED, sMax, sP10, sP90, sPrange, sArea] = calStats(sig);
        [fSTD, fVAR, fMEAN, fMED, fMax, fP10, fP90, fPrange, fArea] = calStats(f_sig);
        [mSTD, mVAR, mMEAN, mMED, mArea, m1, m2, m3, m4, m5, m6, m7, m8, m9, m10] = calMSE(se_sig);
        
        new_row = [sSTD, sVAR, sMEAN, sMED, sMax, sP10, sP90, sPrange, sArea, ...
                   fSTD, fVAR, fMEAN, fMED, fMax, fP10, fP90, fPrange, fArea, ...
                   mSTD, mVAR, mMEAN, mMED, mArea, m1, m2, m3, m4, m5, m6, m7, m8, m9, m10];
        
        current_data = [current_data, new_row];
        
        % Build Variable Names
        stats = {'STD','VAR','MEAN','MED','Max','PRC10','PRC90','PRC_range','Area'};
        for st = stats, all_names{end+1} = [s_name st{1}]; end
        for st = stats, all_names{end+1} = [s_name 'filt' st{1}]; end
        mse = {'MSE_STD','MSE_VAR','MSE_MEAN','MSE_MED','MSE_Area','MSE1','MSE2','MSE3','MSE4','MSE5','MSE6','MSE7','MSE8','MSE9','MSE10'};
        for st = mse, all_names{end+1} = [s_name st{1}]; end
    end
    
    Tbl = array2table([0, current_data], 'VariableNames', all_names); 
    Tbl.Subject_ID = ID;
end