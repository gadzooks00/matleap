% @file test_matleap.m
% @brief test matleap functionality
% @author Jeff Perry <jeffsp@gmail.com>
% @version 1.0
% @date 2013-09-12

function plot_matleap
    % remove matleap mex-file from memory
    % set debug on
    %matleap_debug
    % show version
    [version]=matleap_version;
    fprintf('matleap version %d.%d\n',version(1),version(2));
    % pause to let the hardware wake up
    sleep(1)
    % get some frames
    frame_id=-1;
    frames=0;
    tic
    figure; 
    while(toc<10)
        % get a frame
        f=matleap_frame;
        % i=matleap_image;
        % only count it if it has a different id
        if f.id~=frame_id
            frame_id=f.id;
            print(f)
            frames=frames+1;
        end
        % if i.id == frame_id
        %     imshow(insertText(imrotate(i.image.data,-90),[1 1],"TEST"));
        % end
    end
    s=toc;
    % display performance
    fprintf('%d frames\n',frames);
    fprintf('%f seconds\n',s);
    fprintf('%f fps\n',frames/s);
end

% sleep for t seconds
function sleep(t)
    tic;
    while (toc<t)
    end
end

% print the contents of a leap frame
function print(f)
    fprintf('frame id %d\n',f.id);
    fprintf('frame timestamp %d\n',f.timestamp);
    fprintf('frame hands %d\n',length(f.hands));
    
    color = ['r', 'b'];
    for i=1:length(f.hands)
        for j=1:length(f.hands(i).digits)
            for k=1:length(f.hands(i).digits(j).bones)
            if all([i == 1, j == 1, k == 1])
                
            else
                hold on;
            end
                xyz(1,:) = f.hands(i).digits(j).bones(k).prev_joint;
                xyz(2,:) = f.hands(i).digits(j).bones(k).next_joint;
                plot3(xyz(:,1), xyz(:,2), xyz(:,3), 'o-');                
            end
        end
        xyz = f.hands(i).palm.position;
        scatter3(xyz(1), xyz(2), xyz(3), color(i), 'filled', 'square');  
    end
    axis equal;
    axis vis3d;
    % xlim([-200 200]);
    % ylim([-200 200]);
    % zlim([-200 200]);
    drawnow();
    hold off
end
