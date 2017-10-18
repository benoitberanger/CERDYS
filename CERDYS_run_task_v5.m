function [par_screen,t_start_EXP] = CERDYS_run_task_v5(par_exp,par_general)

%% OUTPUT FILES
%
%  == run_summary
%  Summarizes each run in a row.
%  col 1: deviation angle (alpha_dev_loop)
%  col 2: target angle (angle_target_loop)
%  col 3: index when run starts in behavioral data (ind_run_start)
%  col 4: index when run ends in behavioral data (ind_run_end)
%  col 5: x-position of target (x_target_center)
%  col 6: y-position of target (y_target_center)
%  col 7: time when run started
%  col 8: run time
%
% ==  behave_data
% Summarizes the behavioral data. Updated after each time-point; for some
% conditions (MEG) additional lines are included.

% col 1: total time (total_time)
% col 2: run time (run_time)
% col 4: displayed coordinates in X (coords_disp(1))
% col 5: displayed coordinates in Y (coords_disp(2))
% col 6: status of cursor: 1-center; 0-neither center nor target; 2-target in X (pos_cursor
% col 7: position of target in X (x_target_center)
% col 8: position of target in Y (y_target_center)
% col 9: trigger for MEG 0;


%% INITIALIZE PARAMETERS
% Baseline time in seconds
blink = 1;  % time ffor blink, befoer baseline
baseline = 1;   % minimum baseline, plus user defined random time
blocksPerMEGRun = 2;    % number of blocks recorded continuously in one MEG run

%- defines trigger sent to MEG acquisition via parallel port
trigger_start_Block  = 1; % block start
trigger_start_trial = 2; % trial start
trigger_out_center  = 3; % out center
trigger_in_target   = 4; % trigger in the target
trigger_end         = 5;    % successfull end
trigger_error       = 6;  % end with cursor outside target
trigger_end_Block    = 7; % block end
angle_offset        = 8;   % target angle in bits 4-8 (with start_trial)
bias_offset        = 8;   % trajectory bias in bits 4-8 (with start_block)
eyetracker = 0;


%=== Experimental parameters
flag_input_mode    = par_general.flag_input_mode;
flag_blocks   = par_general.flag_blocks;
screen_init   = par_general.screen_init;
screen_delete = par_general.screen_delete;

t_start_EXP   = par_exp.t_start_EXP;

%==== From joystick / mouse calibration

%- JOYSTICK (USB)
if sum(flag_input_mode == [1  3  4  5 ])
    gamepadIndices = par_exp.gamepadIndices;
    prop_axes_joy  = par_exp.prop_axes_joy;
    status_center  = par_exp.status_center;
    
    behave_data_buffer = -1 * ones(1,5);
    
    %- MOUSE
elseif flag_input_mode == 2
    status_center = 0;
    scale_cursor  = 300;
    coords_0      = par_exp.coords_0;
end

%==== Other parameters

%- Save output files
file_name_save = par_exp.file_name_save;
path_name_save = par_exp.path_name_save;

%- Experimental parameters
run_sequence_def = par_exp.run_sequence_def;
N_run_total      = par_exp.N_run_total;

time_run_max         = par_exp.time_run_max;
time_target_complete = par_exp.time_target_complete;
time_pause           = par_exp.time_pause;
time_pause_rand      = par_exp.time_pause_rand;


%=== General parameters
par_screen    = par_general.par_screen;
ind_run       = par_general.ind_run;
ind_block     = par_general.ind_block;

instruct_font_size = par_general.instruct_font_size;

cursor_size   = par_general.cursor_size;    % Size of cursor
radius_center = par_general.radius_center;% Radius of circle in center (starting point)
radius_target = par_general.radius_target; % Radius of target(s)
cross_length  = par_general.cross_length;   % Length of arms of the cross which is shown during the pause

dt              = par_general.dt;  % Delta-t, time the programs pauses between runs
radius_outer    = par_general.radius_outer;     % Radius of outer circle (location of targets)
axis_limit      = par_general.axis_limit;


%% EXECUTE RUN

%==== Initiate screen

if screen_init
    
    %- Prepare figure and display relevant elements
    h_figure = figure('units','normalized','outerposition',[0 0 1 1]);
    h_ax     = axes;
    set(gcf,'Color',[0.8 0.8 0.8])
    set(gcf,'MenuBar','none')
    set(h_ax,'Position',[0 0 1 1])
    axis equal
    axis off
    
    %- Generate all graphical elements and their handles
    hold on
    h_bounding   = rectangle('Position',[-axis_limit,-axis_limit,2*axis_limit,2*axis_limit],'Curvature',[1,1],'FaceColor',[0.8 0.8 0.8],'LineWidth',2,'EdgeColor',[0.8 0.8 0.8]);
    h_outer      = rectangle('Position',[-radius_outer,-radius_outer,2*radius_outer,2*radius_outer],'Curvature',[1,1],'FaceColor',[0.8 0.8 0.8],'LineWidth',2);
    h_center     = rectangle('Position',[-radius_center,-radius_center,2*radius_center,2*radius_center],'Curvature',[1,1],'FaceColor',[0.8 0.8 0.8],'LineWidth',2);
    h_cross_vert = plot ([0,0],[-cross_length,cross_length],'-k','LineWidth',4);
    h_cross_hor  = plot ([-cross_length,cross_length],[0,0],'-k','LineWidth',4);
    hold off
    
    %- Get available size of figure
    axis_disp = axis;
    prop_axes_disp.x_min  = axis_disp(1);
    prop_axes_disp.x_max  = axis_disp(2);
    prop_axes_disp.y_min  = axis_disp(3);
    prop_axes_disp.y_max  = axis_disp(4);
    prop_axes_disp.x_diff = prop_axes_disp.x_max-prop_axes_disp.x_min;
    prop_axes_disp.y_diff = prop_axes_disp.y_max-prop_axes_disp.y_min;
    
    
    %==== Calculate off-set of center: joystick center is not necessarily center
    %  of screen
    if status_center
        val_ax1 = prop_axes_joy.ax1_center;
        val_ax2 = prop_axes_joy.ax2_center;
        
        val_ax1_norm  = (val_ax1-prop_axes_joy.ax1_min) / prop_axes_joy.ax1_diff;
        val_ax2_norm  = (val_ax2-prop_axes_joy.ax2_min) / prop_axes_joy.ax2_diff;
        
        %- Invert ax2
        val_ax2_norm = 1-val_ax2_norm;
        
        ax_offset.ax1 = val_ax1_norm*prop_axes_disp.y_diff + prop_axes_disp.y_min;
        ax_offset.ax2 = val_ax2_norm*prop_axes_disp.y_diff + prop_axes_disp.y_min;
    else
        ax_offset.ax1 = 0;
        ax_offset.ax2 = 0;
    end
    
    % ==== Warn user that run will start
    h_help2 = helpdlg('Press ok when ready to start the experiment. ','Experiment');
    uiwait(h_help2)
    
    %-  Hide cursor
    set(gcf, 'PointerShapeCData', nan(16, 16));
    set(gcf, 'Pointer', 'custom');
    
else
    h_center     = par_screen.h_center;
    h_cross_vert = par_screen.h_cross_vert;
    h_cross_hor  = par_screen.h_cross_hor;
    axis_disp    = par_screen.axis_disp;
    h_figure     = par_screen.h_figure;
    prop_axes_disp = par_screen.prop_axes_disp;
    ax_offset      = par_screen.ax_offset;
end



% ==== Loop over all the runs
iData      = 1;              % Counter to save behavioral data
pos_cursor = 0;
clear('h_target')

%== Here is real start, we wait for the first trigger (fMRI)
trigger = 0;
% trigger = 1;

if flag_input_mode == 3 || flag_input_mode == 5
    while ~trigger
        [x, y, trigger] = SerialJoyStick(gamepadIndices);
    end
end


%- Start timer of experiment only if not already defined
if isempty(t_start_EXP)
    t_start_EXP = tic;
end


if flag_input_mode == 3 || flag_input_mode == 5
    
    total_time = toc(t_start_EXP);
    alpha_dev_loop  = run_sequence_def(1,1);  % same deviation for all trials in task
    if (alpha_dev_loop > 90)
        choice_bias = 31;
    elseif (alpha_dev_loop < -90)
        choice_bias = 0;
    else
        choice_bias = floor((alpha_dev_loop + 90) * 31 /180);
    end
    trigger = trigger_start_Block + bias_offset * choice_bias;
    %     SendTrigger(trigger); %== Here is real start, signal it to MEG acquisition by sending trigger
    behave_data(iData,:) = [toc(t_start_EXP) behave_data_buffer GetSecs() trigger];
    iData = iData+1;
    if  eyetracker == 1 && mod(par_general.ind_block, blocksPerMEGRun) == 1
        
        dummymode = 0; % set to 1 to run in dummymode (using mouse as pseudo-eyetracker)
        screenNum = 2;
        
        [wPtr, rect] = Screen('OpenWindow', screenNum);
        el = EyelinkInitDefaults(wPtr);
        % Initialization of the connection with the Eyelink Gazetracker.
        % exit program if this fails.
        if ~EyelinkInit(dummymode, 1)
            fprintf('Eyelink Init aborted.\n');
            return
        end
        
        [v vs]=Eyelink('GetTrackerVersion');
        fprintf('Running experiment on a ''%s'' tracker.\n', vs );
        
        % make sure that we get event data from the Eyelink
        %Eyelink('command', 'file_sample_data = LEFT,RIGHT,GAZE,GAZERES,AREA,STATUS'); %"file_sample_data" specifies what type of samples will be wrtten to the EDF file
        %Eyelink('command', 'link_sample_data = LEFT,RIGHT,GAZE,GAZERES,AREA,STATUS'); %"link_sample_data" specifies what type of samples will be sent to link
        %Eyelink('command', 'drift_correct_cr_disable = OFF'); % To enable the drift correction procedure to adjust the calibration rather than simply allowing a drift check
        % Calibrate the eye tracker (this is the pause)
        EyelinkDoTrackerSetup(el);
        Screen('Close', wPtr);
        %EDFname = sprintf([num2str(subNo) '_' num2str(block)]);
        Eyelink('Openfile', par_general.edfFile);
        
        % Calibrate the eye tracker
        % EyelinkDoTrackerSetup(el);
        
        % start recording eye position
        Eyelink('StartRecording');
        % record a few samples before we actually start displaying
        WaitSecs(0.1);
        % mark zero-plot time in data file
        Eyelink('message', 'start recording Eyelink');
        %     else
        %         while ~KbCheck, end; % pause en psychtoolbox (attend un appui sur n'importe quelle touche du clavier)
    end
    
    
end

run_summary = [];

%- Hide cursor
set(gcf, 'PointerShapeCData', nan(16, 16));
set(gcf, 'Pointer', 'custom');

alpha_dev_loop_old = 0;

h_blockend = text(0,0,'Fin de bloc...','FontSize',instruct_font_size, 'Visible', 'off', 'HorizontalAlignment', 'center');

for iRun = 1:N_run_total
    
    
    %- Get parameters for this run
    alpha_dev_loop    = run_sequence_def(iRun,1);
    angle_target_loop = run_sequence_def(iRun,2);
    
    %target_reached = 0;     % Indicate if target is reached or not
    time_in_target = 0;
    
    %- Determine target position
    x_target_center = radius_outer*cosd(angle_target_loop);
    y_target_center = radius_outer*sind(angle_target_loop);
    
    if (exist('h_target'))
        delete(h_target)
    end
    set(h_blockend,'Visible','off');
    
    h_target = rectangle('Position',[x_target_center-radius_target,y_target_center-radius_target,2*radius_target,2*radius_target],'Curvature',[1,1],'FaceColor',[0.8,0.8,0.8],'LineWidth',2);
    set(h_target,'Visible','off')
    
    
    %=== Allow user to center cursor
    
    %- Visibility of different elements
    set(h_center,'Visible','on')
    set(h_cross_vert,'Visible','on')
    set(h_cross_hor,'Visible','on')
    hold on
    
    h_instruct = text(-1,1,' ','FontSize',instruct_font_size);
    axis(axis_disp);
    
    time_in_center        = 0;
    pos_cursor_center     = 0;
    pos_cursor_center_old = 0;
    time_in_center_start  = tic;
    
    while(time_in_center <= time_target_complete)
        %==== Get coordinates
        
        %- JOYSTICK
        if sum(flag_input_mode == [1  3  4  5 ])
            coords_rescale = get_joystick_pos_v2(gamepadIndices,prop_axes_joy,prop_axes_disp,ax_offset,status_center,flag_input_mode);
            
            %- Mouse
        elseif flag_input_mode == 2
            coords         = get(0,'PointerLocation');
            coords_rescale = (coords-coords_0)/scale_cursor;
        end
        
        
        %- Calculate new cursor position with old deviations
        %  See cart2pol and pol2cart for functions of
        alpha = atan2(coords_rescale(2),coords_rescale(1));
        r     = sqrt(power(coords_rescale(1),2)+power(coords_rescale(2),2));
        
        if alpha ~= 0
            alpha_new = alpha-alpha_dev_loop_old*(pi/180);       % In RADIAN
            
            coords_disp(1) = r.*cos(alpha_new);
            coords_disp(2) = r.*sin(alpha_new);
        else
            coords_disp = coords_rescale;
        end
        
        
        %- Get coordinates and plot them
        h_cursor    = plot(coords_disp(1),coords_disp(2),'ok','MarkerEdgeColor','k','MarkerFaceColor','k','MarkerSize',cursor_size);
        dist_center = sqrt((coords_disp(1))^2+(coords_disp(2))^2);
        
        if  dist_center <= radius_center
            pos_cursor_center = 1;
            set(h_center ,'FaceColor','g')
            
            if pos_cursor_center_old == 1
                time_in_center = toc(time_in_center_start);
            else
                time_in_center_start = tic;
            end
            
        else
            set(h_center,'FaceColor',[0.8,0.8,0.8])
            time_in_center = 0;
        end
        
        pos_cursor_center_old = pos_cursor_center;
        
        pause(dt)
        delete(h_cursor)         % Delete cursor only
    end
    
    % blink time, center in blue
    %     set(h_center,'FaceColor','b')
    %     pause(blink);
    %     set(h_center,'Visible','off')
    
    delete(h_instruct)
    
    %=== Pause before run, including minimum baseline: still show cursor position
    set(h_center,'Visible','off')
    set(h_target,'Visible','off')
    set(h_cross_vert,'Visible','on')
    set(h_cross_hor,'Visible','on')
    axis(axis_disp);
    % after blink time, set total baseline = minimum baseline + random
    % time
    time_pause_loop_rand = rand(1)*time_pause_rand;
    pause(baseline + time_pause_loop_rand);
    
    %== ===========  ===========  ===========  ===========  ===========
    %   ACTUAL RUN
    
    set(h_center,'Visible','on')
    %set(h_target,'Visible','on')   % now targer shown after baseline
    set(h_cross_vert,'Visible','off')
    set(h_cross_hor,'Visible','off')
    axis(axis_disp);
    
    t_start_RUN   = tic;
    run_time      = toc(t_start_RUN);
    ind_run_start = iData;
    
    
    %== Here is trial start, signal it to MEG acquisition by sending trigger
    if flag_input_mode == 3 || flag_input_mode == 5
        % code target angle (positive!)at start of trial
        if (angle_target_loop >= 180)
            choice_angle = 31;
        elseif (angle_target_loop <= 0)
            choice_angle = 0;
        else
            choice_angle = floor(angle_target_loop * 31 /180);
        end
        trigger = trigger_start_trial + choice_angle * angle_offset;
        %         SendTrigger(trigger);
        behave_data(iData,:) = [toc(t_start_EXP) behave_data_buffer GetSecs() trigger];
        iData = iData+1;
    end
    
    %- Get beginning time of RUN
    while( (run_time <= time_run_max) && (time_in_target < time_target_complete) )
        
        %- Get coordinates
        
        %- JOYSTICK
        if sum(flag_input_mode == [1  3  4  5 ])
            coords_rescale = get_joystick_pos_v2(gamepadIndices,prop_axes_joy,prop_axes_disp,ax_offset,status_center,flag_input_mode);
            
            %- MOUSE
        elseif flag_input_mode == 2
            coords         = get(0,'PointerLocation');
            coords_rescale = (coords-coords_0)/scale_cursor;
        end
        
        %- Calculate new cursor position with deviations: cart2pol and pol2cart
        alpha = atan2(coords_rescale(2),coords_rescale(1));
        r     = sqrt(power(coords_rescale(1),2)+power(coords_rescale(2),2));
        
        if alpha ~= 0
            alpha_new = alpha-alpha_dev_loop*(pi/180);       % In RADIAN
            
            coords_disp(1) = r.*cos(alpha_new);
            coords_disp(2) = r.*sin(alpha_new);
        else
            coords_disp = coords_rescale;
        end
        
        h_cursor = plot(coords_disp(1),coords_disp(2),'ok','MarkerEdgeColor','k','MarkerFaceColor','k','MarkerSize',cursor_size);
        axis(axis_disp);
        
        %- Calculate if cursor is in center
        dist_center = sqrt((coords_disp(1))^2+(coords_disp(2))^2);
        
        if  dist_center <= radius_center
            set(h_target,'Visible','on')
            set(h_center,'FaceColor','r')
            pos_cursor = 1;
        end
        
        %- Calculate if cursor is in target
        dist_target = sqrt((x_target_center-coords_disp(1))^2+(y_target_center-coords_disp(2))^2);
        if  dist_target <= radius_target
            set(h_target,'FaceColor','g')
            pos_cursor = 2;
            
            
            if flag_input_mode == 3 || flag_input_mode == 5
                if (pos_cursor_old ~= 2)
                    %                    SendTrigger(trigger_in_target); % signal it to MEG acquisition by sending trigger
                    behave_data(iData,:) = [toc(t_start_EXP) behave_data_buffer GetSecs() trigger_in_target];
                    iData = iData+1;
                end
            end
            
            
            %=== Calculate time in target
            %- Cursor was already in target before
            if pos_cursor_old == 2
                time_in_target = toc(time_in_target_start);
            else
                time_in_target_start = tic;
            end
        end
        
        % Neither in center nor in target
        if  (dist_center > radius_center) && (dist_target > radius_target)
            set(h_target,'FaceColor',[0.8,0.8,0.8])
            set(h_center,'FaceColor',[0.8,0.8,0.8])
            
            if flag_input_mode == 3 || flag_input_mode == 5
                if (pos_cursor == 1)
                    %                     SendTrigger(trigger_out_center); % signal it to MEG acquisition by sending trigger
                    behave_data(iData,:) = [toc(t_start_EXP) behave_data_buffer GetSecs() trigger_out_center];
                    iData = iData+1;
                end
            end
            
            pos_cursor = 0;
        end
        
        pause(dt)
        
        run_time       = toc(t_start_RUN);
        total_time     = toc(t_start_EXP);
        pos_cursor_old = pos_cursor;     % Save old cursor position to calculate time in target.
        
        %- Store relevant parameters
        behave_data(iData,:) = [total_time run_time coords_disp(1) coords_disp(2) pos_cursor x_target_center  y_target_center 0];
        iData = iData+1;
        alpha_dev_loop_old = alpha_dev_loop; % Save old angle
        
        delete(h_cursor)         % Delete cursor only
        
        if flag_input_mode == 3 || flag_input_mode == 5
            if (time_in_target > time_target_complete)
                %== Here is end trial, signal it to MEG acquisition by sending trigger
                %                SendTrigger(trigger_end);
                behave_data(iData,:) = [toc(t_start_EXP) behave_data_buffer GetSecs() trigger_end];
                iData = iData+1;
            elseif  (run_time > time_run_max) && (dist_center > radius_center) && (dist_target > radius_target)
                %== Signal error to MEG acquisition by sending trigger
                %                SendTrigger(trigger_error);
                behave_data(iData,:) = [toc(t_start_EXP) behave_data_buffer GetSecs() trigger_error];
                iData = iData+1;
            end
        end
        
    end
    
    hold off
    
    
    if ~isempty(behave_data)
        behave_data(iData,:) = -1*ones(1,size(behave_data,2)); % [-1 -1 -1 -1 -1 -1 -1];
    end
    ind_run_end = iData-1;
    
    % Save general properties of run
    run_T_start    = behave_data(ind_run_start,1);
    run_T_end      = behave_data(ind_run_end,1);
    run_T_duration = run_T_end - run_T_start;
    run_summary(iRun,:) = [alpha_dev_loop angle_target_loop ind_run_start ind_run_end x_target_center  y_target_center run_T_start run_T_duration];
    
    % Update counters
    iData = iData+1;
    
end
% Hide everything while saving
set(h_target,'Visible','off');
set(h_center,'Visible','off');
set(h_blockend,'Visible','on');

if flag_input_mode == 3 || flag_input_mode == 5
    %     SendTrigger(trigger_end_Block);  %== Here is end block, signal it to MEG acquisition by sending trigger
    behave_data(iData,:) = [toc(t_start_EXP) behave_data_buffer GetSecs() trigger_end_Block];
    iData = iData+1;
    if  eyetracker == 1 && mod(par_general.ind_block, blocksPerMEGRun) == 0
        Eyelink('StopRecording');
        
        Eyelink('CloseFile');
        fprintf('Receiving data file ''%s''...\n', par_general.edfFile );
        % leave time for eyelink to compute file events
        pause(5);
        
        for l=1:3
            
            status = Eyelink('ReceiveFile'); %this collects the file from the eyelink
            if status >= 0
                
                movefile(par_general.edfFile, '../Data/')
                break
            else
                fprintf('problem receiving the file, retrying\n');
                pause(1);
            end
        end
        if status == 0
            fprintf('couldn''t transfer file');
            
        end
    else
        pause(par_general.block_pause);
    end
end

if flag_input_mode == 1 || flag_input_mode == 4 % ajout pour avoir une pause entre les blocs avec le mode 'usb'
    pause(par_general.block_pause);
end

%- Save output parameters
par_screen.h_center = h_center;
par_screen.h_cross_vert = h_cross_vert;
par_screen.h_cross_hor = h_cross_hor;
par_screen.axis_disp = axis_disp;
par_screen.h_figure = h_figure;
par_screen.prop_axes_disp = prop_axes_disp;
par_screen.ax_offset = ax_offset;

%- Clean up
if screen_delete
    close(h_figure)
    clear('h_target')
else
    
    %- Delete target
    if (exist('h_target'))
        delete(h_target)
    end
    delete(h_blockend);
    %- Visibility of different elements
    set(h_center,'Visible','on')
    set(h_cross_vert,'Visible','on')
    set(h_cross_hor,'Visible','on')
    hold on
    
end





%% Save data with specified file-name
%  NOTE: fprintf works column wise!!!!!

if file_name_save ~= 0
    
    %- Extract parts of file-name to save data
    [dum, file_name] =  fileparts(file_name_save);
    
    %- Save workspace
    if ~flag_blocks
        file_name_save_mat = [file_name,'_Run_',num2str(ind_run)];
    else
        file_name_save_mat = [file_name,'_Run_',num2str(ind_run),'_Block_',num2str(ind_block)];
    end
    
    save(fullfile(path_name_save,file_name_save_mat),'-v6');
    
    %- Save behave_data
    if ~flag_blocks
        file_name_behave = [file_name,'_Run_',num2str(ind_run),'_time_series.txt'];
    else
        file_name_behave = [file_name,'_Run_',num2str(ind_run),'_Block_',num2str(ind_block),'_time_series.txt'];
    end
    
    N_col = size(behave_data,2);
    str_print = [repmat('%f\t',1,N_col-1) , '%f\n'];
    fid = fopen(fullfile(path_name_save,file_name_behave),'w');
    fprintf(fid,'BEHAVIORAL DATA v1.11, %s \n', date);
    fprintf(fid, str_print, behave_data');
    fclose(fid);
    
    disp('=== CERDYS: behavioural data written to file:')
    disp(fullfile(path_name_save,file_name_behave))
    
    
    %- Data of run
    if ~flag_blocks
        file_name_run = [file_name,'_Run_',num2str(ind_run),'_run_summary.txt'];
    else
        file_name_run = [file_name,'_Run_',num2str(ind_run),'_Block_',num2str(ind_block),'_run_summary.txt'];
    end
    
    N_col = size(run_summary,2);
    str_print = [repmat('%f\t',1,N_col-1) , '%f\n'];
    
    fid = fopen(fullfile(path_name_save,file_name_run),'w');
    fprintf(fid,'RUN SUMMARY v1.11, %s \n', date);
    fprintf(fid, str_print ,run_summary');
    fclose(fid);
    
    disp('=== CERDYS: run data written to file:')
    disp(fullfile(path_name_save,file_name_run))
    
end