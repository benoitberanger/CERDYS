function run_summary_analyze = CERDYS_analyze_runs_v2(par_analyze)

% ==== OUTPUT
%
% === run_summary_analyze
%  Matrix where each row corresponds to one independent run 
% 1st col: deviation angle
% 2nd col: start of run
% 3rd col: duration
% 4th col: reaction time
% 5th col: time to reach target
% 6th col: area under trajectory
% 7th col: deviation angle at start
% 8th col: time to correct trajectory
% 9th col: status of analysis


%% Some general parameters
time_reaction_min_frames = 3;    % Number of consecutive frames the cursor has to be outside of the center to be considered really outside (for calculation of reactiong time)
time_tartget_min_frames  = 3;    % Number of consecutive frames the cursor has to be inside the target to be considered really inside (for calculation of time to reach the target)
time_calc_angle          = 0.25; % Time to record initial deviation   

%% Input parameters
run_summary    = par_analyze.run_summary;
path_name_load = par_analyze.path_name_load;
behave_data = par_analyze.behave_data;

save_file               = par_analyze.save_file;
path_name_save_analysis = par_analyze.path_name_save_analysis;
file_name_save_analysis = par_analyze.file_name_save_analysis;
file_name               = par_analyze.file_name;


%% Analyze runs
nRun_analyze        = size(run_summary,1);
run_summary_analyze = [];

warning off all
ind_plot = 1;
pos_cursor_plot = [];

%- Control for plots: 1 for yes, 0 for no
flag_output    = 2;   % 1 - Show output
                      % 2 - Save results
                      
% -- Generate folders to save all results
if flag_output == 2
    path_name_img = fullfile(path_name_load,file_name);
    if ~exist(path_name_img,'dir')
        mkdir(path_name_img);
    end
end


%- Save cursor positions for later
flag_plot_save = 1;

for iRun_analyze =1:nRun_analyze
     
    status_analysis  = 0;
    
    %==== Analyze the runs
    iRun_start = run_summary(iRun_analyze,3);
    iRun_end   = run_summary(iRun_analyze,4);
    
    x_pos_target = run_summary(iRun_analyze,5);
    y_pos_target = run_summary(iRun_analyze,6);
    target_angle_run = run_summary(iRun_analyze,2);
    
    behave_data_run = behave_data(iRun_start:iRun_end,:);
    
    
    run_T_start    = behave_data(iRun_start,1);
    run_T_end      = behave_data(iRun_end,1);
    run_T_duration = run_T_end - run_T_start;
    
    %==================================================================
    %  == Get rid of MEG triggers (if present)
    %==================================================================
    %  These triggers are added for MEG imaging to column 8 of the 
    %  behavioral data and have values > 0. For the analysis these rows are 
    %  deleted.

    if size(behave_data_run,2) >= 8
        ind_row_delete = behave_data_run(:,8) > 0;
        behave_data_run(ind_row_delete,:) = [];
    end
    time_run_total  = behave_data_run(:,2);
    
    
    %==================================================================
    %  == Calculate reaction time to move outside of the center
    %==================================================================
    
    
    % Indix to indicate if not in center anymore
    ind_center = (behave_data_run(:,5) ~= 1);
    
    N_ind_center = length(ind_center);
    ind_dist_next_zero = zeros(size(ind_center));
    
    for ind_pos = 1:N_ind_center-1
   
        % Find next occuring zero, minus 0 to make the distance to the next
        % neighbour equal to zero,
        
        dum = find(ind_center(ind_pos:end)==0,1,'first');
        dum=dum-1;
        
        % Empty means that there is not zero till the end
        if isempty (dum)
            dum = N_ind_center-ind_pos;
        end
         
         ind_dist_next_zero(ind_pos) = dum;
    end
    
    ind_reaction_frame = find(ind_dist_next_zero>time_reaction_min_frames,1,'first');
    
    
    %- Cursor stayed in center for the entire duration of the run    
    if isempty(ind_reaction_frame)
        reaction_time   = behave_data_run(end,2);
        target_time     = 0;
        traject_area    = 0;
        time_correct_p  = 0;  
        status_analysis = 1;
        angle_dev       = 0;
    
    %- Cursor actually move outside of center    
    else
        
        reaction_time = behave_data_run(ind_reaction_frame,2);

        %===== Calculate time to find the target    

        % Index to indicate if already in target
        ind_target = (behave_data_run(:,5) == 2);

        N_ind_target = length(ind_target);
        ind_dist_next_zero = zeros(size(ind_target));

        for ind_pos = 1:N_ind_target-1

            % Find next occuring zero, minus 0 to make the distance to the next
            % neigbhor equal to zero
            dum = find(ind_target(ind_pos:end)==0,1,'first');
            dum = dum-1;
            % Empty means that there is not zero till the end
            if isempty (dum)
                dum = N_ind_target-ind_pos;
            end

             ind_dist_next_zero(ind_pos) = dum;
        end

        ind_target_frame = find(ind_dist_next_zero>time_tartget_min_frames,1,'first');  
        
        %- Target not reached
        if isempty(ind_target_frame)
             % If target was not hit 
             %   - Target time is set to time of run
             %   - Area is calculated from reaction time till end
           
            target_time      = time_run_total(end);
            ind_target_frame = length(time_run_total); 
            status_analysis  = 2;
        else
            target_time = behave_data_run(ind_target_frame,2);
        end
        
        
        %================================================================== 
        % == Calculate area under trajetory
        %==================================================================
                
        %  After leaving center and before reaching target

        %- Rotate cursor position such that target is on positive x-axis
        pos_cursor_run = behave_data_run(ind_reaction_frame:ind_target_frame,3:4);

        %- Transform to polar coordinates
        [pos_cursor_theta,pos_cursor_R] = cart2pol(pos_cursor_run(:,1),pos_cursor_run(:,2));

        %   Calculate angle after rotation
        pos_cursor_theta_new            = pos_cursor_theta - target_angle_run*(pi/180);

        %  The ones exactly in the center will not be turned (angle 0)
        pos_cursor_theta_new(pos_cursor_theta == 0) = 0; 

        %- Calculate new positions
        pos_cursor_run_new = [];
        [pos_cursor_run_new(:,1), pos_cursor_run_new(:,2)] = pol2cart(pos_cursor_theta_new,pos_cursor_R);   

        pos_cursor_run_new(isnan(pos_cursor_run_new)) = 0;    % Catch any isnan if they occur
        traject_area = abs(trapz(pos_cursor_run_new(:,1),pos_cursor_run_new(:,2)));           

        if flag_output  

            x_target_center = run_summary(iRun_analyze,5);
            y_target_center = run_summary(iRun_analyze,6);
            radius_target = 0.075; % Radius of target(s)
            radius_center = 0.075; % Radius of circle in center (starting point)

            h_fig1 = figure; 
            if flag_output == 2; set(gcf,'visible','off'); end
            hold on
            plot(pos_cursor_run(:,1),pos_cursor_run(:,2),'b')
            plot(pos_cursor_run_new(:,1),pos_cursor_run_new(:,2),'r')
            rectangle('Position',[x_target_center-radius_target,y_target_center-radius_target,2*radius_target,2*radius_target],'Curvature',[1,1],'FaceColor','w','LineWidth',2);
            rectangle('Position',[-radius_center,-radius_center,2*radius_center,2*radius_center],'Curvature',[1,1],'FaceColor','w','LineWidth',2);

            hold off
            axis equal
            axis([-1.1125    1.1125   -1.1125    1.1125]);        
            box on 
            legend('Initial trajectory','Rotated trajectory','Target', 'Center',4)
            set(h_fig1,'Color','w')
            
            if flag_output == 2
                file_save = fullfile(path_name_img,['Run_',sprintf('%02d',iRun_analyze),'_traj__rotated']);
                saveas(h_fig1,file_save,'png')
                close(h_fig1);
            end
            
        end

        %- Save cursor position for later
        if flag_plot_save
            pos_cursor_plot(ind_plot).raw             = pos_cursor_run;
            pos_cursor_plot(ind_plot).rot             = pos_cursor_run_new;
            pos_cursor_plot(ind_plot).x_target_center = run_summary(iRun_analyze,5);
            pos_cursor_plot(ind_plot).y_target_center = run_summary(iRun_analyze,6);

            ind_plot = ind_plot +1 ;         
        end

        
        %==================================================================
        % == Calculate intial deviation angle and time to correct movement
        %==================================================================
        time_run = time_run_total(ind_reaction_frame:ind_target_frame);
        time_run = time_run - time_run(1);

        ind_fit = find(time_run>time_calc_angle,1);    


        %- Fit linear model
        xdata_all = pos_cursor_run_new(:,1)-pos_cursor_run_new(1,1);
        ydata_all = pos_cursor_run_new(:,2)-pos_cursor_run_new(1,2);  

        xdata = xdata_all(1:ind_fit,1);        % Move to zero to obtain better fit
        ydata = ydata_all(1:ind_fit,1);        % Move to zero to obtain better fit

        f = @(k,xdata) k*xdata;

        k_fit         = lsqcurvefit(f,1,xdata,ydata);
        y_fit_linear  = f(k_fit,xdata);

        angle_dev = atan2(k_fit,1)*180/pi;

        if flag_output 
            h_fig1 = figure; 
            if flag_output == 2; set(gcf,'visible','off'); end
            hold on
            plot(xdata_all,ydata_all,'k')
            plot(xdata,ydata,'r')
            plot(xdata,y_fit_linear,'b')
            hold off
            box on
            axis equal
            legend('Trajectory','Part used to estimate deviation angle', 'Fit to linear model')
            set(h_fig1,'Color','w')
            
            if flag_output == 2
                file_save = fullfile(path_name_img,['Run_',sprintf('%02d',iRun_analyze),'_traj_deviation']);
                saveas(h_fig1,file_save,'png')
                close(h_fig1);
            end            
            
            
        end

        
        %==================================================================
        % == Reaction time to correct movement
        %==================================================================
        
        % Fit with polynomial and calculate time when maximum is reached. In
        % idealized situation this should roughly correspond to the time where
        % the trajectory was changed. 
        [p,S]     = polyfit(xdata_all,ydata_all,4);
        ydata_fit = polyval(p,xdata_all);

        p_min           = max(abs(ydata_fit));
        ind_t_correct_p = find(abs(ydata_fit) == p_min);    
        time_correct_p  = time_run(ind_t_correct_p);

        if isempty(time_correct_p)
            time_correct_p = 0;
        end

        if flag_output
           h_fig1 = figure;
           if flag_output == 2; set(gcf,'visible','off'); end
           hold on
           plot(xdata_all,ydata_all,'k')
           plot(xdata_all,ydata_fit,'r')
           plot(xdata_all(ind_t_correct_p(1)),ydata_all(ind_t_correct_p(1)),'og')
           legend('Trajectory','Fit to polynomial model',['Time for correction:' , num2str(time_correct_p(1),2)])
           title('Fit with polynomial')
           box on
           hold off
           axis equal
           set(h_fig1,'Color','w');
           
                       
            if flag_output == 2
                file_save = fullfile(path_name_img,['Run_',sprintf('%02d',iRun_analyze),'_traj_time_react']);
                saveas(h_fig1,file_save,'png')
                close(h_fig1);
            end
           
        end        
    
    end
    
    
   %==== Save all parameters to matrix
   run_summary_analyze(iRun_analyze,:) = [run_summary(iRun_analyze,1) run_T_start run_T_duration reaction_time target_time traject_area angle_dev time_correct_p(1) status_analysis ];
   
   
end
warning on all


%% == Save results to file
if save_file ~= 0
   fid = fopen(fullfile(path_name_save_analysis,file_name_save_analysis),'w');
   fprintf(fid,'CERDYS: ANALYSIS OF BEHAVIORAL DATA, %s \n', date);
   fprintf(fid, 'Angle_dev\tT_start\tRUN_duration\tT_react\tT_target\tArea\tAngle_dev_start\tT_correct\tStatus_analysis\n');
   fprintf(fid, '%g\t%g\t%g\t%g\t%g\t%g\t%g\t%g\t%g\n', run_summary_analyze');
   fclose(fid);   
end