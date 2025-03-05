function animate_ultraleap_data(file_path)
    % Visualizes recorded Ultraleap hand tracking data in 3D.
    % Includes an interactive timeline to control playback.

    fprintf('[INFO] Loading data from: %s\n', file_path);

    % === Declare Global Variables for Timeline Interaction ===
    global is_paused selected_time;
    is_paused = false;
    selected_time = NaN; % If NaN, play normally

    % Load timestamps
    timestamps = h5read(file_path, '/timestamps');
    time_vals = timestamps(:,2); % Extract timestamps (MATLAB serial date numbers)
    num_frames = length(time_vals);

    % Convert MATLAB serial date number to seconds
    time_vals = (time_vals - time_vals(1)) * 86400; % Convert to seconds
    total_time = time_vals(end); % Duration of original recording

    % Compute frame intervals for accurate playback speed
    frame_intervals = diff(time_vals);
    frame_intervals = [frame_intervals; mean(frame_intervals)]; % Approximate last frame interval

    % Determine the number of hands in the dataset
    num_hands = max(timestamps(:,3));
    fprintf('[INFO] Total Frames: %d | Max Hands: %d | Recording Duration: %.2f seconds\n', ...
        num_frames, num_hands, total_time);

    % === Load Camera Images (DISABLED BY DEFAULT) ===
    has_camera_data = false; % Default: Camera images are not displayed
    % Uncomment the following lines to enable camera image playback
    % try
    %     camera_images = h5read(file_path, '/camera_images');
    %     has_camera_data = true;
    % catch
    %     warning('[WARN] No camera images found in dataset.');
    % end

    % Set up figure layout
    figure;
    
    % Unified 3D Axis for Hand Motion
    ax1 = subplot(2,1,1); % Hand tracking (takes top half)
    hold on; grid on; axis equal;
    xlabel('X'); ylabel('Y'); zlabel('Z');
    title('Ultraleap Hand Motion');
    view(3);

    % Timeline Progress Bar (Bottom Interactive Control)
    ax2 = subplot(2,1,2);
    timeline = plot(ax2, [0, total_time], [0, 0], 'k-', 'LineWidth', 2); % Full timeline
    progress_marker = plot(ax2, 0, 0, 'ro', 'MarkerSize', 8, 'MarkerFaceColor', 'r'); % Moving dot
    xlim(ax2, [0 total_time]);
    ylim(ax2, [-1 1]);
    xlabel(ax2, 'Time (seconds)');
    title(ax2, 'Playback Progress');

    % Enable interactive timeline
    set(ax2, 'ButtonDownFcn', @timeline_click_callback);

    % Define colors for each hand
    colors = lines(num_hands);

    % Initialize a **single** axis for all hands
    hand_plots = gobjects(1, num_hands);
    finger_plots = gobjects(num_hands, 5, 4); % 5 fingers, 4 bones each

    for h = 1:num_hands
        hand_plots(h) = scatter3(ax1, nan, nan, nan, 100, colors(h, :), 'filled', 'square');
        for f = 1:5
            for b = 1:4
                finger_plots(h, f, b) = plot3(ax1, nan, nan, nan, 'o-', 'Color', colors(h, :), 'LineWidth', 2);
            end
        end
    end

    % Animation Variables
    start_time = tic; % Start real-time counter

    % Animation Loop
    for i = 1:num_frames
        elapsed_time = toc(start_time); % Get real elapsed time
        target_time = time_vals(i); % Target timestamp for the current frame

        % Pause functionality
        while is_paused
            pause(0.1); % Small pause while waiting for user input
        end

        % Jump to selected time if set
        if ~isnan(selected_time)
            [~, i] = min(abs(time_vals - selected_time)); % Find closest frame
            selected_time = NaN; % Reset to normal playback
        end

        % Adjust playback speed
        while elapsed_time < target_time
            pause(0.01); % Small delay to sync frame timing
            elapsed_time = toc(start_time);
        end

        % Update each detected hand
        hands_detected = false; % Track whether any hands are present

        for h = 1:num_hands
            hand_group = sprintf('/hand_%d/palm', h);
            try
                palm_pos = h5read(file_path, hand_group, [i, 1], [1, 3]); % Read X, Y, Z position
                set(hand_plots(h), 'XData', palm_pos(1), 'YData', palm_pos(2), 'ZData', palm_pos(3));
                hands_detected = true;
            catch
                set(hand_plots(h), 'XData', nan, 'YData', nan, 'ZData', nan);
            end

            % Update fingers & bones
            for f = 1:5
                for b = 1:4
                    bone_group = sprintf('/hand_%d/finger_%d/bone_%d', h, f, b);
                    try
                        bone_data = h5read(file_path, bone_group, [i, 1], [1, 6]); % Read prev_joint & next_joint
                        prev_joint = bone_data(1:3);
                        next_joint = bone_data(4:6);
                        set(finger_plots(h, f, b), 'XData', [prev_joint(1), next_joint(1)], ...
                            'YData', [prev_joint(2), next_joint(2)], ...
                            'ZData', [prev_joint(3), next_joint(3)]);
                        hands_detected = true;
                    catch
                        set(finger_plots(h, f, b), 'XData', nan, 'YData', nan, 'ZData', nan);
                    end
                end
            end
        end

        % Update the timeline progress
        set(progress_marker, 'XData', target_time, 'YData', 0);

        % Draw updates
        drawnow;
    end

    fprintf('[INFO] Playback finished.\n');

    % === Callback for Clicking on the Timeline ===
    function timeline_click_callback(~, event)
        is_paused = true; % Pause playback
        clicked_time = event.IntersectionPoint(1); % Get clicked X coordinate
        clicked_time = max(0, min(clicked_time, total_time)); % Clamp to valid range
        selected_time = clicked_time;
        is_paused = false; % Resume playback
    end
end
