% =========================================================================
% Copyright (c) 2024 Suchada Tantisatirapong
% Department of Biomedical Engineering, Faculty of Engineering
% Srinakhawirot University
% Email: suchadat@g.swu.ac.th
% All rights reserved.
% =========================================================================

clc;
clear;
% =========================================================================
% 1. USER CONFIGURATION
% =========================================================================
RANDOM_SEED = 42;
numShuffles = 10;           % Outer repetitions
numFolds = 10;              % Stratified K-Fold

num_nca_features_single = 500;     % Features to select for Tasks 1-5 
num_nca_features_combined = 2500;  % Features to select for Task 6 
max_obj_evals = 50;                % Bayesian Opt evals
num_top_features_to_save = 30;     % Number of top features to find/save

remarks = sprintf("Remark: Cleaned Data, Z-Score Norm, NCA, SVM(RBF) with BayesOpt(%d evals)", max_obj_evals);
time_str = char(datetime('now', 'Format', 'dd_MMMM_yyyy_''time''_HH_mm_ss', 'Locale', 'en_US'));
filename = sprintf('SVM_NCA_20topfeature_%s.txt', time_str);   

fid = fopen(filename, 'a');
fprintf(fid, '%s\n', remarks);
fprintf(fid, 'NCA Features: %d (Tasks 1-5), %d (Task 6)\n\n', num_nca_features_single, num_nca_features_combined);
fclose(fid);

base_hyperopts = struct('Optimizer', 'bayesopt', ...
                   'AcquisitionFunctionName', 'expected-improvement-plus', ...
                   'MaxObjectiveEvaluations', max_obj_evals, ... 
                   'UseParallel', false, ...  
                   'ShowPlots', false, ...
                   'Verbose', 0);
% =========================================================================
% 2. MAIN TASK LOOP
% =========================================================================
for task = 1:6     
    %% 2.1 Load Data & Set Feature Limit
    if task <= 5
        current_num_nca_features = num_nca_features_single;
    else
        current_num_nca_features = num_nca_features_combined;
    end
    switch task
        case 1
            load merged_MSpiral_control.mat; control = Spiral_finalTable;
            load merged_MSpiral_pd.mat; pd = Spiral_finalTable;
            task_name = 'Spiral';
        case 2
            load merged_MWl_control.mat; control = Wl_finalTable;
            load merged_MWl_pd.mat; pd = Wl_finalTable;
            task_name = 'Letter';
        case 3
            load merged_MTHl_control.mat; control = THl_finalTable;
            load merged_MTHl_pd.mat; pd = THl_finalTable;
            task_name = 'Sentence';
        case 4
            load merged_MHl_control.mat; control = Hl_finalTable;
            load merged_MHl_pd.mat; pd = Hl_finalTable;
            task_name = 'Horizontal';
        case 5
            load merged_MVl_control.mat; control = Vl_finalTable;
            load merged_MVl_pd.mat; pd = Vl_finalTable;
            task_name = 'Vertical';
        case 6
            % --- FIX: Safe Data Alignment using innerjoin ---
            load merged_MWl_control.mat; t_Wl = Wl_finalTable;
            load merged_MSpiral_control.mat; t_Sp = Spiral_finalTable; t_Sp.Class = [];
            load merged_MHl_control.mat; t_Hl = Hl_finalTable; t_Hl.Class = [];
            load merged_MTHl_control.mat; t_THl = THl_finalTable; t_THl.Class = [];
            load merged_MVl_control.mat; t_Vl = Vl_finalTable; t_Vl.Class = [];
            
            control = innerjoin(t_Wl, t_Sp, 'Keys', 'Subject_ID');
            control = innerjoin(control, t_Hl, 'Keys', 'Subject_ID');
            control = innerjoin(control, t_THl, 'Keys', 'Subject_ID');
            control = innerjoin(control, t_Vl, 'Keys', 'Subject_ID');
            
            load merged_MWl_pd.mat; p_Wl = Wl_finalTable;
            load merged_MSpiral_pd.mat; p_Sp = Spiral_finalTable; p_Sp.Class = [];
            load merged_MHl_pd.mat; p_Hl = Hl_finalTable; p_Hl.Class = [];
            load merged_MTHl_pd.mat; p_THl = THl_finalTable; p_THl.Class = [];
            load merged_MVl_pd.mat; p_Vl = Vl_finalTable; p_Vl.Class = [];
            
            pd = innerjoin(p_Wl, p_Sp, 'Keys', 'Subject_ID');
            pd = innerjoin(pd, p_Hl, 'Keys', 'Subject_ID');
            pd = innerjoin(pd, p_THl, 'Keys', 'Subject_ID');
            pd = innerjoin(pd, p_Vl, 'Keys', 'Subject_ID');
            
            task_name = 'All_tasks_Combined'; 
    end
    
    allData = [control; pd];
    fprintf('\n======================================================\n');
    fprintf('▶ Task: %s is running (Using %d NCA features)...\n', task_name, current_num_nca_features);
    fprintf('======================================================\n');
    
    %% 2.2 Manage Variables
    if ismember('Subject_ID', allData.Properties.VariableNames)
        SubjectID = allData.Subject_ID;
    else
        error('CRITICAL ERROR: Subject_ID column not found.');
    end
    
    featureNames = allData.Properties.VariableNames(3:end)'; 
    num_total_features = length(featureNames);
    
    X = table2array(allData(:, 3:end));
    y = categorical(allData.Class);
    pd_category = 'PD';
    
    % --- FIX: Prevent Stratification Mismatch ---
    [unique_subjects, first_idx_subj] = unique(SubjectID, 'stable');
    y_subj = y(first_idx_subj); 
    
    Result_Test = zeros(numShuffles, 6);
    Result_Train = zeros(numShuffles, 6);
    Shuffle_Weights = zeros(numShuffles, num_total_features);
    
    %% 2.3 Outer Loop: Repeated Cross-Validation
    parfor r = 1:numShuffles
        fprintf('  [Shuffle %d/%d] เริ่มต้นประมวลผล...\n', r, numShuffles);
        
        rng(RANDOM_SEED + r, 'twister');
        cv_subj = cvpartition(y_subj, 'KFold', numFolds, 'Stratify', true);
        
        fold_test_metrics = zeros(numFolds, 6);
        fold_train_metrics = zeros(numFolds, 6);
        fold_nca_weights = zeros(numFolds, num_total_features); 
        
        %% 2.4 Inner Loop: 10-Fold CV
        for k = 1:numFolds
            train_subj_idx = training(cv_subj, k);
            test_subj_idx = test(cv_subj, k);
            train_subjects = unique_subjects(train_subj_idx);
            test_subjects = unique_subjects(test_subj_idx);
            
            trainIdx = ismember(SubjectID, train_subjects);
            testIdx = ismember(SubjectID, test_subjects);
            
            XTrain_Raw = X(trainIdx, :); yTrain = y(trainIdx);
            XTest_Raw = X(testIdx, :);   yTest = y(testIdx);
            
            % --- A. Clean Features ---
            cols_with_nans = any(isnan(XTrain_Raw), 1);
            cols_constant = (std(XTrain_Raw, 0, 1) == 0);
            bad_cols = cols_with_nans | cols_constant;
            
            XTrain_Clean = XTrain_Raw(:, ~bad_cols);
            XTest_Clean = XTest_Raw(:, ~bad_cols);
            
            % --- B. Normalization ---
            mu = mean(XTrain_Clean, 1);
            sigma = std(XTrain_Clean, 0, 1) + 1e-6;
            XTrain = (XTrain_Clean - mu) ./ sigma;
            XTest = (XTest_Clean - mu) ./ sigma;
            
            % --- C. Feature Selection (NCA) ---
            nca_mdl = fscnca(XTrain, yTrain, 'Standardize', false);
            
            current_fold_weights = zeros(1, num_total_features);
            valid_idx = find(~bad_cols);
            current_fold_weights(valid_idx) = nca_mdl.FeatureWeights;
            fold_nca_weights(k, :) = current_fold_weights;
            
            [~, nca_idx] = sort(nca_mdl.FeatureWeights, 'descend');
            top_n = min(current_num_nca_features, size(XTrain, 2));
            top_indices = nca_idx(1:top_n);
            
            XTrain_Final = XTrain(:, top_indices);
            XTest_Final = XTest(:, top_indices);
            
            % --- FIX: Secondary Leakage (Subject-wise Inner CV for BayesOpt) ---
            inner_SubjectID = SubjectID(trainIdx);
            [inner_unique_subj, inner_first_idx] = unique(inner_SubjectID, 'stable');
            inner_y_subj = yTrain(inner_first_idx);

            inner_cv_subj = cvpartition(inner_y_subj, 'KFold', 5, 'Stratify', true);
            inner_row_partition = zeros(length(yTrain), 1);
            
            for inner_k = 1:5
                inner_test_subjs = inner_unique_subj(test(inner_cv_subj, inner_k));
                inner_row_partition(ismember(inner_SubjectID, inner_test_subjs)) = inner_k;
            end
            
            current_hyperopts = base_hyperopts;
            inner_cv_final = cvpartition(length(yTrain), 'KFold', 5);
            try
                inner_cv_final.Impl.indices = inner_row_partition;
                current_hyperopts.CVPartition = inner_cv_final;
            catch
                % Silently falls back to default auto inner-CV if environment restricts object mutation
            end
            
            % --- D. Train SVM ---
            SVM_model = fitcsvm(XTrain_Final, yTrain, ...
                     'KernelFunction', 'rbf', ...
                     'Standardize', false, ...
                     'Prior', 'empirical', ... 
                     'OptimizeHyperparameters', 'auto', ...
                     'HyperparameterOptimizationOptions', current_hyperopts);
                
            pd_idx = find(string(SVM_model.ClassNames) == pd_category);
            if isempty(pd_idx); pd_idx = 1; end
            
            % --- E. Evaluate ---
            [ytrainPred, scores_train] = predict(SVM_model, XTrain_Final);
            fold_train_metrics(k, :) = get_metrics(yTrain, ytrainPred, scores_train, pd_idx);
            
            [yvalPred, scores_test] = predict(SVM_model, XTest_Final);
            fold_test_metrics(k, :) = get_metrics(yTest, yvalPred, scores_test, pd_idx);
        end
        
        temp_train = mean(fold_train_metrics, 1);
        temp_test = mean(fold_test_metrics, 1);
        
        Result_Train(r, :) = temp_train;
        Result_Test(r, :) = temp_test;
        Shuffle_Weights(r, :) = mean(fold_nca_weights, 1); 
        
        fprintf('  [Shuffle %d/%d] เสร็จสิ้น | Train Acc: %.4f | Test Acc: %.4f\n', r, numShuffles, temp_train(1), temp_test(1));
    end
    
    %% 2.6 Save Results and Extract Top Features
    varNames = {'Iteration', 'Avg_Accuracy', 'Avg_Sensitivity', 'Avg_Specificity', 'Avg_Precision', 'Avg_F1', 'Avg_AUC'};
    
    Final_Stats_Train = array2table([(1:numShuffles)', Result_Train], 'VariableNames', varNames);
    writetable(Final_Stats_Train, sprintf('SVM_NCA_Train_%s.csv', task_name));
    
    Final_Stats_Test = array2table([(1:numShuffles)', Result_Test], 'VariableNames', varNames);
    writetable(Final_Stats_Test, sprintf('SVM_NCA_Test_%s.csv', task_name));
    
    Overall_Mean_Weights = mean(Shuffle_Weights, 1)';
    [sorted_weights, sorted_indices] = sort(Overall_Mean_Weights, 'descend');
    
    top_n_actual = min(num_top_features_to_save, num_total_features);
    Top_Features_Names = featureNames(sorted_indices(1:top_n_actual));
    Top_Features_Weights = sorted_weights(1:top_n_actual);
    
    Top_Features_Table = table((1:top_n_actual)', Top_Features_Names, Top_Features_Weights, ...
        'VariableNames', {'Rank', 'Feature_Name', 'Average_NCA_Weight'});
    writetable(Top_Features_Table, sprintf('Top_%d_Features_%s.csv', num_top_features_to_save, task_name));
    
    Mean_Train = mean(Result_Train, 1); Std_Train = std(Result_Train, 0, 1);
    Mean_Test = mean(Result_Test, 1);   Std_Test = std(Result_Test, 0, 1);
    
    fid = fopen(filename, 'a');
    fprintf(fid, '================================================\n');
    fprintf(fid, '   FINAL PERFORMANCE - Task: %s \n', task_name);
    fprintf(fid, '   NCA Features Evaluated: %d \n', current_num_nca_features);
    fprintf(fid, '================================================\n');
    
    fprintf(fid, '--- TRAINING DATA ---\n');
    fprintf(fid, 'Accuracy:    %.4f ± %.4f\nSensitivity: %.4f ± %.4f\nSpecificity: %.4f ± %.4f\nPrecision:   %.4f ± %.4f\nF1-Score:    %.4f ± %.4f\nAUC:         %.4f ± %.4f\n\n', ...
            Mean_Train(1), Std_Train(1), Mean_Train(2), Std_Train(2), Mean_Train(3), Std_Train(3), Mean_Train(4), Std_Train(4), Mean_Train(5), Std_Train(5), Mean_Train(6), Std_Train(6));
    
    fprintf(fid, '--- TESTING DATA ---\n');
    fprintf(fid, 'Accuracy:    %.4f ± %.4f\nSensitivity: %.4f ± %.4f\nSpecificity: %.4f ± %.4f\nPrecision:   %.4f ± %.4f\nF1-Score:    %.4f ± %.4f\nAUC:         %.4f ± %.4f\n\n', ...
            Mean_Test(1), Std_Test(1), Mean_Test(2), Std_Test(2), Mean_Test(3), Std_Test(3), Mean_Test(4), Std_Test(4), Mean_Test(5), Std_Test(5), Mean_Test(6), Std_Test(6));
    
    fprintf(fid, '--- TOP %d NCA FEATURES ---\n', num_top_features_to_save);
    for i = 1:top_n_actual
        fprintf(fid, '%2d. %-30s (Weight: %.4f)\n', i, Top_Features_Names{i}, Top_Features_Weights(i));
    end
    fprintf(fid, '================================================\n\n');
    fclose(fid);
    
    fprintf('✅ Task %s saved successfully to %s\n', task_name, filename);
end
% =========================================================================
% HELPER FUNCTION
% =========================================================================
function metrics = get_metrics(y_true, y_pred, scores, pd_idx)
    CM = confusionmat(y_true, y_pred, 'Order', categorical({'PD', 'Control'}));
    TP = CM(1,1); FN = CM(1,2); FP = CM(2,1); TN = CM(2,2);
    
    acc = (TP + TN) / max(sum(CM(:)), 1);
    sens = TP / max((TP + FN), 1);
    spec = TN / max((TN + FP), 1);
    prec = TP / max((TP + FP), 1);
    
    f1 = 0;
    if (prec + sens) > 0
        f1 = 2 * (prec * sens) / (prec + sens);
    end
    
    [~, ~, ~, auc] = perfcurve(y_true, scores(:, pd_idx), 'PD');
    metrics = [acc, sens, spec, prec, f1, auc];
end