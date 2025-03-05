function ultraleap_logger(save_path, subject_id, file_name, debug_mode)
    % Ensure subject_id is specified
    if nargin < 2
        error('[ERROR] Subject ID must be specified.');
    end
    
    % Set default file_name if not provided
    if nargin < 3 || isempty(file_name)
        file_name = 'LeapLog';
    end
    
    % Set default debug mode if not provided
    if nargin < 4
        debug_mode = false;
    end

    % Ensure MatLeap is available
    [version] = matleap_version;
    if debug_mode
        fprintf('[DEBUG] MatLeap version %d.%d detected.\n', version(1), version(2));
    end

    % Check if Ultraleap device is connected
    try
        f = matleap_frame;  % Try to get a frame
    catch
        error('[ERROR] Ultraleap device not detected. Please check the connection and try again.');
    end

    % Initialize Logging Parameters
    max_frames_per_file = 100000; % File splitting threshold
    file_count = 1;
    frame_index = 1;
    frame_id = -1;
    max_hands = 2; 

    % Create First HDF5 File
    filename = create_hdf5_structure(save_path, file_name, subject_id, file_count);
    fprintf('[INFO] Logging data to %s\n', filename);

    try
         while true
            % Get a frame
            try
                f = matleap_frame; % Capture hand tracking frame
                % img = matleap_image(); % Capture an image
            catch
                error('[ERROR] Ultraleap device disconnected unexpectedly. Stopping data collection.');
            end

            if f.id ~= frame_id
                frame_id = f.id;
                num_hands = length(f.hands);

                % Debugging Output Every 100 Frames
                if mod(frame_index, 100) == 0
                    fprintf('[INFO] Frame %d | Hands Detected: %d\n', frame_id, num_hands);
                end

                % Store MATLAB serial date number (numeric, avoids corruption)
                timestamp = now;

                % Store frame metadata correctly
                h5write(filename, '/timestamps', [frame_id, timestamp, length(f.hands)], ...
                    [frame_index, 1], [1, 3]);  % Now storing (Frame ID, Time, Hand Count)

                % Store the camera image (Grayscale & Compressed)
                % h5write(filename, '/camera_images', uint8(img.image.data), [1, 1, frame_index], [512, 512, 1]);

                % Ensure File Splitting
                if frame_index >= max_frames_per_file
                    file_count = file_count + 1;
                    filename = create_hdf5_structure(save_path, file_name, subject_id, file_count);
                    frame_index = 1; % Reset frame index
                    fprintf('[INFO] Creating new data file: %s\n', filename);
                end

                % If more than preallocated hands exist, create additional datasets
                if length(f.hands) > max_hands
                    for h = (max_hands + 1):length(f.hands)
                        hand_group = sprintf('/hand_%d', h);
                        h5create(filename, sprintf('%s/palm', hand_group), [Inf, 20], 'ChunkSize', [1, 20]);
                        h5create(filename, sprintf('%s/arm', hand_group), [Inf, 11], 'ChunkSize', [1, 11]);

                        for d = 1:5 % Assume 5 fingers
                            finger_group = sprintf('%s/finger_%d', hand_group, d);
                            h5create(filename, sprintf('%s/properties', finger_group), [Inf, 2], 'ChunkSize', [1, 2]);

                            for b = 1:4 % Assume 4 bones per finger
                                bone_group = sprintf('%s/bone_%d', finger_group, b);
                                h5create(filename, bone_group, [Inf, 11], 'ChunkSize', [1, 11]);
                            end
                        end
                    end
                    max_hands = length(f.hands); % Update max hands
                end

                % Store hand, palm, and finger data
                for h = 1:length(f.hands)
                    hand = f.hands(h);
                    hand_group = sprintf('/hand_%d', h);
                    
                    % Palm properties
                    palm_data = [hand.palm.position, hand.palm.stabilized_position, hand.palm.velocity, ...
                                 hand.palm.normal, hand.palm.width, hand.palm.direction, hand.palm.orientation];
                    h5write(filename, sprintf('%s/palm', hand_group), palm_data, [frame_index, 1], [1, 20]);

                    % Arm properties
                    arm_data = [hand.arm.prev_joint, hand.arm.next_joint, hand.arm.width, hand.arm.rotation];
                    h5write(filename, sprintf('%s/arm', hand_group), arm_data, [frame_index, 1], [1, 11]);

                    % Store each finger separately
                    for d = 1:5
                        finger = hand.digits(d);
                        finger_group = sprintf('%s/finger_%d', hand_group, d);

                        % Finger properties (is_extended, etc.)
                        finger_data = [finger.finger_id, finger.is_extended];
                        h5write(filename, sprintf('%s/properties', finger_group), finger_data, [frame_index, 1], [1, 2]);

                        % Store each bone separately
                        for b = 1:4
                            bone_group = sprintf('%s/bone_%d', finger_group, b);
                            bone_data = [finger.bones(b).prev_joint, finger.bones(b).next_joint,...
                                finger.bones(b).width, finger.bones(b).rotation];
                            h5write(filename, bone_group, bone_data, [frame_index, 1], [1, 11]);
                        end
                    end
                end

                % Debug Console Output
                if debug_mode
                    fprintf('[DEBUG] Frame %d | Hands: %d\n', frame_id, length(f.hands));
                end

                frame_index = frame_index + 1; % Increment write index
                drawnow;
            end
         end
    catch ME
        fprintf('[ERROR] Logging stopped due to an error: %s\n', ME.message);
    end
end

% Function to create HDF5 file structure before logging
function filename = create_hdf5_structure(save_path, file_name, subject_id, file_count)
    % Construct filename with subject_id, base name, and file number
    timestamp_str = datestr(now, 'yyyymmdd_HHMMSS');
    filename = fullfile(save_path, sprintf('%s_%s_part%d_%s.h5', subject_id, file_name, file_count, timestamp_str));

    % Create an HDF5 file
    fid = H5F.create(filename, 'H5F_ACC_TRUNC', 'H5P_DEFAULT', 'H5P_DEFAULT');
    H5F.close(fid);

    % Session metadata
    date_str = datestr(now, 'yyyy-mm-dd HH:MM:SS');
    session_info = string({date_str, subject_id, filename});

    % Create and write session metadata as a fixed-size dataset
    h5create(filename, '/session_info', [1 3], 'Datatype', 'string');
    h5write(filename, '/session_info', session_info);

    % Create main datasets
    h5create(filename, '/timestamps', [Inf, 3], 'ChunkSize', [1, 3]);  % Frame ID, Time, Hand Count

    % Preallocate for 2 hands initially
    for h = 1:2
        hand_group = sprintf('/hand_%d', h);
        h5create(filename, sprintf('%s/palm', hand_group), [Inf, 20], 'ChunkSize', [1, 20]);
        h5create(filename, sprintf('%s/arm', hand_group), [Inf, 11], 'ChunkSize', [1, 11]);

        for d = 1:5
            finger_group = sprintf('%s/finger_%d', hand_group, d);
            h5create(filename, sprintf('%s/properties', finger_group), [Inf, 2], 'ChunkSize', [1, 2]);

            for b = 1:4
                bone_group = sprintf('%s/bone_%d', finger_group, b);
                h5create(filename, bone_group, [Inf, 11], 'ChunkSize', [1, 11]);
            end
        end
    end

    % Allocate for images
    % h5create(filename, '/camera_images', [512, 512, Inf], 'ChunkSize', [512, 512, 1], 'Datatype', 'uint8');
end