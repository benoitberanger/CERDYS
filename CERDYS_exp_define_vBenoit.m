function [par_exp] = CERDYS_exp_define_vBenoit
%% Dialog to define all relevant parameters of the experiment

dlg_title  = 'Define experiments';
num_lines  = 1;
prompt     = {
    'Starting sign : + or -',...
    'Maximum time for one trial',...
    'Time spent on target for task to be completed',...
    'Length of pause between runs',...
    'Maximum random time added to pause'};
def_values  = {'','5','0.5','0.5','0.5'};

user_values = inputdlg(prompt,dlg_title,num_lines,def_values);

if not(isempty(user_values))
    
    %- Extract target angles
    angle_target_string = '0,45,90,135,180';
    ind_comma_target = strfind(angle_target_string, ',');
    ind_comma_target = [0,ind_comma_target,length(angle_target_string)+1];    % Add 1 and index after last angle - important for loop
    
    angle_targets = [];
    for i =1:length(ind_comma_target)-1
        ind_start = ind_comma_target(i)+1;
        ind_end   = ind_comma_target(i+1)-1;
        
        angle_target_loop = str2double(angle_target_string(ind_start:ind_end));
        angle_targets     = [angle_targets, angle_target_loop]; %#ok<AGROW>
    end
    
    startingSign = user_values{1};
    if strcmp(startingSign,'+') || strcmp(startingSign,'-')
        startingSign = str2double([startingSign '1']);
    else
        error('Sign tunning : only use + or -')
    end
    
    par_exp.time_run_max         = str2double(user_values{2});
    par_exp.time_target_complete = str2double(user_values{3});
    par_exp.time_pause           = str2double(user_values{4});
    par_exp.time_pause_rand      = str2double(user_values{5});
    
end

%% Modifs for AMEDYST, Benoît Béranger, octobre 2017
% The idea is to keep the dialog box to tune most of parameters,
% but the order and difficulty is designe by the code below :

% Generate a random sign.
% startingSign = ( rand > 0.5 )*2 - 1;

baseAngle = 35; % in degrees (°)


%% Block order

%--------------------------------------------------------------------------
% Define block order bellow
%--------------------------------------------------------------------------
% % NrTrials must be be a multiple of 5 (i.e. 5 angles)
% % NrTrials // Deviation (in degrees °)
% paradigm = [
%     
% % Direct, baseline : before adaptation
% 60 0
% 
% % 8 blocks, adaptation, start with random +/- 35°, then alternate
% 
% 15 baseAngle*startingSign
% 15 baseAngle*startingSign*(-1)
% 
% 15 baseAngle*startingSign
% 15 baseAngle*startingSign*(-1)
% 
% 15 baseAngle*startingSign
% 15 baseAngle*startingSign*(-1)
% 
% 15 baseAngle*startingSign
% 15 baseAngle*startingSign*(-1)
% 
% % Direct, mesure after adapataion
% 30 0
% 
% ];

paradigm = [
30 0
60 baseAngle*startingSign
30 0
];

% paradigm = [ 
% 5 0
% 10 baseAngle*startingSign
% 5 0
% ];

%--------------------------------------------------------------------------
%
%--------------------------------------------------------------------------

nTimesAngles = paradigm(:,1)/5;
if ~all(nTimesAngles == round(nTimesAngles) )
    error('Number of Trials must be a multiple of 5 (5 angles).')
end

angle_deviations = paradigm(:,2);


%% Generate sequence of trials

%===== Define sequence of runs
N_deviations    = length(angle_deviations); % == N_blocks
N_deviation_run = paradigm(:,1);
N_run_total     = sum(N_deviation_run);

% Matrix that defines the sequence of runs
%  1 st col .... deviation angle
%  2 nd col .... target angle
run_sequence_def = zeros(N_run_total,2);


for iDev = 1:N_deviations
    
    % Fetch the endexes of start and end for each deviation angle
    if iDev == 1
        ind_def_start = 1;
    else
        ind_def_start = sum(N_deviation_run(1:(iDev-1)))+1;
    end
    ind_def_end   = sum(N_deviation_run(1:iDev));
    
    %- Randomized the sequence of target-angles : no more than 2 times in a row the same angle
    %  Here we shuffle angles (5 in our current case), then we concatenate all 5-packs shuffled angles.
    
    angle_target_nonRandom = repmat(angle_targets, [ N_deviation_run(iDev)/length(angle_targets) 1 ]); % Generate the 5-packs of angles
    angle_target_random = zeros(size(angle_target_nonRandom));               % preallocation
    
    for line = 1 : size(angle_target_nonRandom,1)                            % for each 5-packs of angle
        rand_seq = randperm( size(angle_target_nonRandom,2) );               % shuffle the 5 angles
        angle_target_random(line,:) = angle_target_nonRandom(line,rand_seq); % store them
    end
    reshaped_angle_target_random = reshape(angle_target_random',[],1); % reshape==concatenante each 5-packs shuffled
    
    run_sequence_def(ind_def_start:ind_def_end,1) = angle_deviations(iDev); % save final sequence of (deviation,angle)
    run_sequence_def(ind_def_start:ind_def_end,2) = reshaped_angle_target_random;
end

%=== Save output parameters
par_exp.N_run_total      = N_run_total;
par_exp.run_sequence_def = run_sequence_def;
par_exp.angle_deviations = angle_deviations;
par_exp.angle_targets    = angle_targets;


end % function
