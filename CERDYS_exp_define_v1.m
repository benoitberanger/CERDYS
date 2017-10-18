function [par_exp] = CERDYS_exp_define_v1

%% Dialog to define all relevant parameters of the experiment 
%  IMPORTANT: angles have to be separated by comma "," and NO comma after
%  last angle.
%
%  === Target angle
%  0 is E, 90 is N, 180 is W, 270 is S
% 
%  === Deviation angles
%  Sequence of angles which will be subtracted from original movement 
%  angle. Note: negative angles will be added to the original movement 
%  angle.
%
%  === flag_seq and N_repeat
%  Determine how sequence of runs will be presented
%  flag_seq = 1 ..... ordered sequence
%                     Sequence is defined by vector of deviation angles.
%                     For each deviation angle the target angles are
%                     randomized and each target angle is shown
%                     N_run_repeat times but in a complete random order.
%
%  flag_seq = 2 ..... random sequence
%                     Random sequence. Each combination of target angle 
%                     deviation angle is shown   

dlg_title  = 'Define experiments';
num_lines  = 1;
prompt     = { 'Enter target angles (separated by comma)', ...
               'Enter deviation angles (separated by comma)',...
               'Sequence of runs: Ordered(1), random(2)',...
               'Number of repeats for each condition',...
               'Maximum time for one trial',...
               'Time spent on target for task to be completed',...
               'Length of pause between runs',...
               'Maximum random time added to pause'};
def_values  = {'0,45,90,135,180','-30,0,25','1','3','5','0.5','0.5','0.3'};

%def_values  = {'0,180','0','1','5','5','1','1','0.3'};
%def_values  = {'0,120,240','0,25,50','2','2','5','1','1','0.3'};


user_values = inputdlg(prompt,dlg_title,num_lines,def_values);

if not(isempty(user_values))
   
    %- Extract target angles
    angle_target_string = user_values{1};
    ind_comma_target = strfind(angle_target_string, ',');
    ind_comma_target = [0,ind_comma_target,length(angle_target_string)+1];    % Add 1 and index after last angle - important for loop
    
    angle_targets = [];
    for i =1:length(ind_comma_target)-1
       ind_start = ind_comma_target(i)+1;
       ind_end   = ind_comma_target(i+1)-1;
       
       angle_target_loop = str2double(angle_target_string(ind_start:ind_end));
       angle_targets     = [angle_targets, angle_target_loop];
    end
    
    %- Extract deviation angles
    angle_deviation_string = user_values{2};
    ind_comma_deviation = strfind(angle_deviation_string, ',');
    ind_comma_deviation = [0,ind_comma_deviation,length(angle_deviation_string)+1];    % Add 1 and index after last angle - important for loop
    
    angle_deviations = [];
    for i =1:length(ind_comma_deviation)-1
       ind_start = ind_comma_deviation(i)+1;
       ind_end   = ind_comma_deviation(i+1)-1;
       
       angle_deviation_loop = str2double(angle_deviation_string(ind_start:ind_end));
       angle_deviations = [angle_deviations, angle_deviation_loop];
    end
    
    %- Flag for runs
    flag_seq     = str2double(user_values{3});
    N_dev_repeat = str2double(user_values{4}); 
    
    %- Timing for each run
    par_exp.time_run_max         = str2double(user_values{5});
    par_exp.time_target_complete = str2double(user_values{6});
    par_exp.time_pause           = str2double(user_values{7});
    par_exp.time_pause_rand      = str2double(user_values{8});
end

 
%===== Define sequence of runs
N_deviations    = length(angle_deviations);
N_targets       = length(angle_targets);
N_deviation_run = N_targets*N_dev_repeat;       % Number of runs for each deviation
N_run_total     = N_deviations*N_deviation_run; % Total number of runs

% Matrix that defines the sequence of runs
%  1 st col .... deviation angle
%  2 nd col .... target angle
run_sequence_def = zeros(N_run_total,2);

%- Generate a vector with the target angles for each deviation
%  For proper functionality of repmat the angle_targets has to be a column vector
if size(angle_targets,1) == 1       % Row vector
    angle_targets_sequence = repmat(angle_targets', N_dev_repeat,1);
else
    angle_targets_sequence = repmat(angle_targets', N_dev_repeat,1);
end


if flag_seq ==1
    for iDev = 1:N_deviations        
        
        ind_def_start = (iDev-1)*N_deviation_run+1;
        ind_def_end   = iDev*N_deviation_run;
        
        %- Randomized the sequence of target-angles
        rand_seq = randperm(N_deviation_run);
       
        run_sequence_def(ind_def_start:ind_def_end,1) = angle_deviations(iDev);
        run_sequence_def(ind_def_start:ind_def_end,2) = angle_targets_sequence(rand_seq);      
    end    
    
elseif flag_seq == 2
    
    % 1. Dummy sequence with ordered appearance of deviation and target
    run_sequence_def_dum = run_sequence_def;
    
    for iDev = 1:N_deviations        
        
        ind_def_start = (iDev-1)*N_deviation_run+1;
        ind_def_end   = iDev*N_deviation_run;       

        run_sequence_def_dum(ind_def_start:ind_def_end,1) = angle_deviations(iDev);
        run_sequence_def_dum(ind_def_start:ind_def_end,2) = angle_targets_sequence;      
    end    
    
    % 2. Randomize sequence
    
    rand_seq = randperm(N_run_total);
    run_sequence_def = run_sequence_def_dum(rand_seq,:);
    
end


%=== Save output parameters
par_exp.N_run_total      = N_run_total;
par_exp.run_sequence_def = run_sequence_def;
par_exp.angle_deviations = angle_deviations;
par_exp.angle_targets    = angle_targets;
