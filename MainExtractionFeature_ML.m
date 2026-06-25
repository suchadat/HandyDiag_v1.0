% =========================================================================
% Copyright (c) 2024 Suchada Tantisatirapong
% Department of Biomedical Engineering, Faculty of Engineering
% Srinakhawirot University
% Email: suchadat@g.swu.ac.th
% All rights reserved.
% =========================================================================

clear, clc
close all force 

%% 1. Define Paths
% folder Control และ PD
parentFolders = { ...
    'C:\Users\User\Desktop\HandyDiag Scientific Report\HandWritingData\Control', ...
    'C:\Users\User\Desktop\HandyDiag Scientific Report\HandWritingData\PD' ...
};

%% 2. Signal Processing Parameters
fs_target = 64;  % resampling frequency (Hz)
fc = 3;          % Cut-off frequency for tremor filtering

%% 3. Loop Through Parent Folders (Control & PD)
for p = 1:length(parentFolders)
    mainFolder = parentFolders{p};
    fprintf('\n--- Processing Group: %s ---\n', mainFolder);
   
    % ดึงรายชื่อ Subject (Subfolders)
    items = dir(mainFolder);
    isSubfolder = [items.isdir] & ~ismember({items.name}, {'.', '..'});
    subfolders = items(isSubfolder);
   

    %% Loop through each subfolder (Subject)
    for i = 1:length(subfolders)
       
        currentSubfolderPath = fullfile(mainFolder, subfolders(i).name);
        jsonFileList = dir(fullfile(currentSubfolderPath, '*.json'));

        if ~isempty(jsonFileList)
            % Decode JSON
            jsonFilePath = fullfile(currentSubfolderPath, jsonFileList(1).name);
            fid = fopen(jsonFilePath, 'r');
            rawContent = fscanf(fid, '%c');
            fclose(fid);
            decode = jsondecode(rawContent);

            % Display status of execution
            if endsWith(mainFolder, 'Control')
                fprintf('Processing Control subject no: %d | Name: %s\n', i, subfolders(i).name);
            else
                fprintf('Processing PD subject no: %d | Name: %s\n', i, subfolders(i).name);
            end
            
            Subject_ID = string(decode.ID);

            % 4. Extract features 
            % improve with fs_target and fc
            
            % Extract Spiral
            extract_spiral_feature(currentSubfolderPath, decode, fs_target, fc);
            
            %Extract Letters & Sentences 
            extract_letters_feature(currentSubfolderPath, decode, fs_target, fc);
            
            % Extract Lines (Horizontal & Vertical)
            extract_lines_feature(currentSubfolderPath, decode, fs_target, fc);

            % % 5. รวม Features ทั้งหมดเข้าด้วยกัน (ข้ามคอลัมน์แรกที่เป็น Subject_ID ของแต่ละ Table)
            % all_features = [feature_spiral, ...
            %                 feature_Wl(:, 2:end), ...
            %                 feature_THl(:, 2:end), ...
            %                 feature_Hl(:, 2:end), ...
            %                 feature_Vl(:, 2:end)];
            % 
            % % 6. save Subject ID.mat 
            % save(fullfile(currentSubfolderPath, Subject_ID + ".mat"), 'all_features');
            % 
            % ปิดหน้าต่างที่อาจค้างอยู่จาก Toolbox
            close all hidden;

        else
            fprintf('No JSON file found in: %s\n', subfolders(i).name);
        end
    end
end

fprintf('\n=============== Feature Extraction Completed ===============\n');