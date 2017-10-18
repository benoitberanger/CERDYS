function CERDYS_analyze_indiv_v2

% CERDYS: Analyze behavior data v2.b
%
% Uses two matrices which are generated from the main program
%   behave_data   AND run_summary
%
%
%  run_summary   ... stores the main parameter of one run. Each run is
%                   stored in a seperate row.
%     1st col: alpha_dev_loop    ... deviation angle
%     2nd col: angle_target_loop ... angle of target
%     3rd col: ind_run_start     ... Starting index of run in behavioral data
%     4th col: ind_run_end       ... End index of run in behavioral data
%     5th col: x_target_center   ... x-coordinate of target
%     6th col: y_target_center   ... y-coordinate of target 
%     7th col: total time when run started
%     8th col: run time
%
%  behave_data    .... stores the details of all the runs. Each row c
%                      corresponds to one time-point. Individual runs are
%                      separated by a row of -1
%
%     1st col: total_time     ... total run time
%     2nd col: run_time       ... Run time of this run
%     3rd col: coords_new(1)  ... X-pos of cursor after deflection
%     4th col: coords_new(2)  ... Y-pos of cursor after deflection
%     5th col: pos_cursor     ... Flag to indicate where cursor is. 
%                                      1 ... in center
%                                      2 ... in target
%                                      0 ... Neither center nor target  
%  
%
% ADD folder with Matlab files to Matlab path defintion (File > Set Path
% ...)
%
% === OUTPUT 
%
%  For each run which is saved in one row of run_summary the following
%  parameters are calculated and stored in one row of run_summary_analyze:
%
%  deviation angle (Input)
%
%  reaction_time ... time until the cursor leaves the center. Stored in 1st
%                    column
%  target_time   ... time until the cursor reaches the target, calculated 
%                    from beginning of run, i.e. includes reaction time. 
%                    Stored in 2nd column
%  traject_area  ... Area of the trajectory. The smaller the value the more
%                    accurate the movement. It's basically the area between 
%                    actual trajectory and the ideal trajectory connecting
%                    the center and the target. Stored in 3rd column
%  angle_dev     ... Initial deviation angle when suject starts run. 
%  time_correct_p ... Time until movement is corrected. Estimated by
%                     fitting the trajectory first with a parable and then 
%                     estimating the minimum of this parabel. The time of
%                     this minimum will be the reaction time.
%
%  status_analysis ... Status of the anlysis 
%        0 ... all good
%        1 ... Cursor didn't leave center
%        2 ... Cursor didn't reach target

% === VERSION history from fomer versions
%
%
% v 1.10, May 20,2011
% - Corrected bugs if cursor doesn't leave the center, e.g. user doesn't
%   react.
% - Additional status indicator
%
% v 1.9, April 8, 2011
% - New visualization method to plot multiple trajectories. Use the
%   function varycolor.
%   http://www.mathworks.com/matlabcentral/fileexchange/21050
%
% v1.8, April 5,2011
% - Correct bug in summary write-out when target was not reached
% - Add deviation angle to output file
%
% v1.6-7, March 15,2011
% - Some improvements
%
% v1.5, Feb 10,2011
% - Correction of bug that some plots are shown even with flag_output set
%   to 0
% - Correction of bug that reaction time asignment is not alwasy working 
%
% v1.4
% - Analyze the initial deviation angle
% - Reaction time for correction - estimated with two methods 
% - Deactivate all warning during loop
%
% v1.3
% - Allow user to load save data for analysis
% - Save results to file
%
% v1.2 
% - Analyze data from main program v1.2 and higher. Was necessary since
%   data structure was changed
%
% v 1.1
% - Rotation is implemented by a transformation to polar coordinates
% - If target is not hit at the end of the run the target time is set to
%   the run time (as defined in time_run) and the are under the curve is
%   calculated till the end of the run


%% Ask user if he want to analyze workspace or open files
choice_load = questdlg('Which data-sets should be processed','Data analysis','Workspace','Load file','Load file');

if strcmp(choice_load,'Load file')
    
    [file_name_load,path_name_load] = uigetfile('*.mat','Specify file which should be processed');
    
    
    if file_name_load == 0
        return
    end
    
    %- Extract parts of file-name to save data
    [dum, file_name] =  fileparts(file_name_load);
    
    %====== Load behavorial data: flexibel with number of columns
    file_name_behave = [file_name,'_time_series.txt'];
    fid              = fopen(fullfile(path_name_load,file_name_behave),'r');
    if fid == -1
        disp(' ')
        disp('== CAN NOT OPEN TIME SERIES FILE')
        disp(['File  : ', file_name_behave])
        disp(['Folder: ', path_name_load])
        
        return
    else
        header_dum  = fgetl(fid);
        first_row   = fgetl(fid);
        first_row_v = str2num(first_row);

        N_tab = length(strfind(first_row,sprintf('\t')));
        string_read = [repmat('%f\t',1,N_tab),'%f'];          
        behave_data_cell = textscan(fid, string_read,'headerlines',0);
        fclose(fid);    
    end
    
    %- Transform into matrix and add back first row
    behave_data = cell2mat(behave_data_cell);  % Result of textscan is a cell
    behave_data = [first_row_v;behave_data];    
    
    %===== Load information about runs
    file_name_run    = [file_name,'_run_summary.txt'];
    fid              = fopen(fullfile(path_name_load,file_name_run),'r');
  
    if fid == -1
        disp(' ')
        disp('== CAN NOT OPEN RUN SUMMARY')
        disp(['File  : ', file_name_run])
        disp(['Folder: ', path_name_load])
        return
    else 
        header_dum  = fgetl(fid);
        first_row   = fgetl(fid);
        first_row_v = str2num(first_row);

        N_tab = length(strfind(first_row,sprintf('\t')));
        string_read = [repmat('%f\t',1,N_tab),'%f']; 
        run_summary_cell = textscan(fid, string_read,'headerlines',0);
        fclose(fid);    
        
    end
    
    %- Transform into matrix and add back first row
    run_summary = cell2mat(run_summary_cell);  % Result of textscan is a cell
    run_summary = [first_row_v; run_summary]; 
    
elseif strcmp(choice_load,'Workspace')
    save_file  = 0;  
    path_name_load = path_name_save;    
    
else
   return
end


%% Dialog for file-save
choice_save = questdlg('Do you want to save the results of the analysis?','Save analysis','YES','NO','YES');

if strcmp(choice_save,'YES')
    current_directory = pwd;
    cd(path_name_load)
    if exist('file_name','var')
        file_default = [file_name,'_analysis_', datestr(date, 'yymmdd'), '.txt'];
    else      
        file_default = ['behave_data_analysis_', datestr(date, 'yymmdd'), '.txt'];
    end
    [file_name_save_analysis,path_name_save_analysis] = uiputfile(file_default,'Specify file name to save results');
    cd(current_directory)
    save_file = 1;
else
    save_file = 0;
	path_name_save_analysis = [];
    file_name_save_analysis = [];
end


%% Analyze run
par_analyze.run_summary = run_summary;
par_analyze.path_name_load = path_name_load;
par_analyze.behave_data = behave_data;
par_analyze.save_file = save_file;
par_analyze.path_name_save_analysis = path_name_save_analysis;
par_analyze.file_name_save_analysis = file_name_save_analysis;
par_analyze.file_name = file_name;

run_analyze_loop = CERDYS_analyze_runs_v2(par_analyze);


%=== Get onset and duration 
    
%- Find condition (deviation angle defined in first column)
[val_cond_unique] = unique(run_analyze_loop(:,1));

for ind_cond = 1:length(val_cond_unique)

   %- Get index that corresponds to condition 
   ind_loop = find(run_analyze_loop(:,1) == val_cond_unique(ind_cond));

   %- Get onset and duration
   onsets{ind_cond}     = run_analyze_loop(ind_loop,2);
   durations{ind_cond}  = run_analyze_loop(ind_loop,3);
end

file_onset = fullfile(path_name_load, [file_name '_ONSETS']);
disp(['Onset-file saved as: ', file_onset]);
save(file_onset, 'file_name', 'val_cond_unique', 'onsets', 'durations');