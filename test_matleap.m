% @file test_matleap.m
% @brief test matleap functionality
% @author Jeff Perry <jeffsp@gmail.com>
% @version 1.0
% @date 2013-09-12

function test_matleap
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
    while(toc<10)
        % get a frame
        f=matleap_frame;
        % only count it if it has a different id
        if f.id~=frame_id
            frame_id=f.id;
            print(f)
            frames=frames+1;
        end
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
    
    
    for i=1:length(f.hands)
        fprintf('hand %d\n',i);
        fprintf('\tpalm position ');
        fprintf(' %f',f.hands(i).palm.position); 
        fprintf('\n');
    end
end
