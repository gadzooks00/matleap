% Ultraleap Logger Launcher
% Edit the variables below before running the script.

clc; clear;

%% === CONFIGURATION (EDIT THESE BEFORE RUNNING) ===
save_path = fullfile(pwd, 'data');  % Directory where data will be saved
subject_id = 'sub-test';            % Set the Subject ID (REQUIRED)
file_name = 'LeapLog';              % Set the File Name (OPTIONAL, defaults to 'LeapLog')
debug_mode = false;                 % Set Debug Mode (true for ON, false for OFF)
% ================================================

% Ensure the data folder exists
if ~exist(save_path, 'dir')
    mkdir(save_path);
end

% Display selected settings before starting
fprintf('\n[INFO] Starting Ultraleap Logger with settings:\n');
fprintf('  - Save Path: %s\n', save_path);
fprintf('  - Subject ID: %s\n', subject_id);
fprintf('  - File Name: %s\n', file_name);
fprintf('  - Debug Mode: %s\n', ternary(debug_mode, 'ON', 'OFF'));

% Start the Ultraleap Logger
ultraleap_logger(save_path, subject_id, file_name, debug_mode);

% Ternary helper function
function result = ternary(condition, trueVal, falseVal)
    if condition
        result = trueVal;
    else
        result = falseVal;
    end
end
