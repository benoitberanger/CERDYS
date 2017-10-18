function varargout = GUI_CERDYS(varargin)
% GUI_CERDYS MATLAB code for GUI_CERDYS.fig
%      GUI_CERDYS, by itself, creates a new GUI_CERDYS or raises the existing
%      singleton*.
%
%      H = GUI_CERDYS returns the handle to a new GUI_CERDYS or the handle to
%      the existing singleton*.
%
%      GUI_CERDYS('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in GUI_CERDYS.M with the given input arguments.
%
%      GUI_CERDYS('Property','Value',...) creates a new GUI_CERDYS or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before GUI_CERDYS_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to GUI_CERDYS_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help GUI_CERDYS

% Last Modified by GUIDE v2.5 11-Jan-2014 00:02:42

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @GUI_CERDYS_OpeningFcn, ...
                   'gui_OutputFcn',  @GUI_CERDYS_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before GUI_CERDYS is made visible.
function GUI_CERDYS_OpeningFcn(hObject, eventdata, handles, varargin)

%- Define with which input-device CERDYS runs
% flag_input_mode = 1;  % Joystick under MAC (psychtoolbox)
% flag_input_mode = 2;  % Mouse
% flag_input_mode = 3;  % SERIAL - MEG
% flag_input_mode = 4;  % Joystick under WIN (joymex2) without MEG
% flag_input_mode = 5;  % Joystick under WIN (joymex2) WITH MEG


if isempty(varargin)
   handles.flag_input_mode = 1; 
end

if length(varargin) == 1

   if strcmpi(varargin{1},'joystick') || varargin{1} == 1
        handles.flag_input_mode = 1; 
   end 
    
   if strcmpi(varargin{1},'mouse') || varargin{1} == 2
        handles.flag_input_mode = 2; 
   end
    
   if strcmpi(varargin{1},'serial') || varargin{1} == 3
        handles.flag_input_mode = 3; 
   end 
   
   if strcmpi(varargin{1},'joystick-win') || varargin{1} == 4
        handles.flag_input_mode = 4; 
   end 
   
    if strcmpi(varargin{1},'joystick-win-meg') || varargin{1} == 5
        handles.flag_input_mode = 5; 
   end   
   
end


%- Check if GUI is already open
global CERDYS_open

if isempty(CERDYS_open) || CERDYS_open == 0
    
    CERDYS_open = 1;
    eyetracker = 1;

    % Choose default command line output for GUI_CERDYS
    handles.output = hObject;

    %- Get default parameters
    handles.par_general = CERDYS_par_define_v1;
    
    handles.ind_run = 1;
       
    %- Status updates
    handles.status_joystick_calibrated = 0;
    handles.status_define_experiment   = 0;
    handles.status_define_file         = 0;
    enable_controls(hObject, eventdata, handles)
    
    % Update handles structure
    guidata(hObject, handles);

    % Open the parallel port (serial port is opened by calibration fonction)
    % OpenParPort;
    % UIWAIT makes GUI_CERDYS wait for user response (see UIRESUME)
    % uiwait(handles.figure1);
else
    disp('CERDYS IS ALREADY RUNNING!')
end

    

% --- Outputs from this function are returned to the command line.
function varargout = GUI_CERDYS_OutputFcn(hObject, eventdata, handles) 
varargout{1} = handles.output;


% --- Executes when user attempts to close figure1.
function figure1_CloseRequestFcn(hObject, eventdata, handles)

global CERDYS_open
CERDYS_open = 0;
    
if sum(handles.flag_input_mode == [ 4  5 ])
    clear joymex2
end

delete(hObject);
% parallel and serial ports
try
    IOPort('Close',handles.gamepadIndices);
catch err
    warning(err.message)
end
% CloseParPort;

%========================================================================== 
%== Enable controls
%========================================================================== 

function enable_controls(hObject, eventdata, handles)

%- Joystick calibrated
if handles.status_joystick_calibrated
    set(handles.button_joystick,'ForegroundColor','g');
else
    set(handles.button_joystick,'ForegroundColor','r');
end

%- Experiment defined
if handles.status_define_experiment
    set(handles.button_define_experiment,'ForegroundColor','g');
else
    set(handles.button_define_experiment,'ForegroundColor','r');
end

%- Output-file defined
if handles.status_define_file
    set(handles.button_define_files,'ForegroundColor','g');
else
    set(handles.button_define_files,'ForegroundColor','r');
end

%- Output-file defined
if handles.status_define_file && handles.status_joystick_calibrated && handles.status_define_experiment
   set(handles.button_start_experiment,'Enable','on');
   set(handles.button_start_block_dev,'Enable','on');
   
else
    set(handles.button_start_experiment,'Enable','off');
    set(handles.button_start_block_dev,'Enable','off');
    
end
    
    

%========================================================================== 
%= Calibrate joystick
%========================================================================== 

function button_joystick_Callback(hObject, eventdata, handles)


%- SELECT CALIBRATION

%== JOYSTICK (USB)
if sum(handles.flag_input_mode == [1  3  4  5 ])
    clear joymex2
    status_center = get(handles.checkbox_joystick_correct_center,'Value');
    [handles.gamepadIndices, handles.prop_axes_joy] = CERDYS_calibrate_joystick_v3(status_center,handles.flag_input_mode);
    handles.status_center = status_center;
    
    handles.status_joystick_calibrated = 1;
    enable_controls(hObject, eventdata, handles)
    guidata(hObject, handles);
    
    
    %== MOUSE
elseif handles.flag_input_mode == 2
    
   %- Some parameters
    instruct_font_size = 16;  % Font size for instructions
    radius_center = 0.075;    % Radius of circle in center (starting point)
    radius_target = 0.075;    % Radius of target(s)
    radius_outer  = 1;        % Radius of outer circle (location of targets)
    cross_length  = 0.1;      % Length of arms of the cross which is shown during the pause
    axis_limit    = radius_outer+1.5*radius_target;
    
    %- Help dialog
    h_help1 = helpdlg('First step is calibration. After pressing OK the cursor will change into a cross. Please move to center of screen and stay there until the next dialog appears. ','Calibration');
    uiwait(h_help1)

    %- Prepare figure and display relevant elements
    h_figure = figure('units','normalized','outerposition',[0 0 1 1]);
    h_ax     = axes;
    set(gcf,'Color',[0.8,0.8,0.8])
    set(gcf,'MenuBar','none')
    set(h_ax,'Position',[0 0 1 1])
    axis equal
    axis off

    hold on
    h_bounding   = rectangle('Position',[-axis_limit,-axis_limit,2*axis_limit,2*axis_limit],'Curvature',[1,1],'FaceColor',[0.8,0.8,0.8],'LineWidth',2,'EdgeColor',[0.8,0.8,0.8]);
    h_outer      = rectangle('Position',[-radius_outer,-radius_outer,2*radius_outer,2*radius_outer],'Curvature',[1,1],'FaceColor',[0.8,0.8,0.8],'LineWidth',2);
    h_center     = rectangle('Position',[-radius_center,-radius_center,2*radius_center,2*radius_center],'Curvature',[1,1],'FaceColor',[0.8,0.8,0.8],'LineWidth',2);
    h_cross_vert = plot ([0,0],[-cross_length,cross_length],'-k','LineWidth',4);
    h_cross_hor  = plot ([-cross_length,cross_length],[0,0],'-k','LineWidth',4);
    hold off

    set(h_outer,'Visible','off') 

    set(h_center,'Visible','on')
    set(h_cross_vert,'Visible','on')
    set(h_cross_hor,'Visible','on')
    h_instruct = text(-1,1,'CALIBRATION: MOVE CURSOR TO CENTER OF CROSS AND CLICK','FontSize',instruct_font_size);

    %-- Calibrate center
    button = 'No';
    while strcmp(button,'No')

        [x_click, y_click] = ginput(1);

        %- New in v1.8: get rid of rescaling: go directly for position in axes
        coords_0 = get(0,'PointerLocation');    % Alternative could be GetMouse (might avoid the odd shifts on Mac)

        %- Plot current position
        hold on
           h_cursor_center = plot(x_click,y_click,'+r','LineWidth',10);
        hold off

        button = questdlg('Satisfied with choice of center?','Calibration of center','Yes','No','No'); 
        delete(h_cursor_center)
    end
    
    %- Close figure
    delete(h_figure)
    handles.status_joystick_calibrated = 1;
    handles.coords_0 = coords_0;
    enable_controls(hObject, eventdata, handles)
    guidata(hObject, handles);
    
end


%========================================================================== 
%= Define output files
%========================================================================== 

function button_define_files_Callback(hObject, eventdata, handles)
file_default                    = [datestr(date, 'yymmdd'),'_behave_data.mat'];
[handles.file_name_save,handles.path_name_save] = uiputfile(file_default,'Specify file name to save results');

handles.status_define_file = 1;
enable_controls(hObject, eventdata, handles)
guidata(hObject, handles)


%========================================================================== 
%= Define experiment
%========================================================================== 

function button_define_experiment_Callback(hObject, eventdata, handles)
% handles.par_exp = CERDYS_exp_define_v1;
handles.par_exp = CERDYS_exp_define_vBenoit;

handles.status_define_experiment = 1;
enable_controls(hObject, eventdata, handles)
guidata(hObject, handles)


%========================================================================== 
%= Run SINGLE experiment
%========================================================================== 

function button_start_experiment_Callback(hObject, eventdata, handles)

%- Experimental parameters
par_exp = handles.par_exp;

%== From joystick/mouse calibration

%- JOYSTICK
if sum(handles.flag_input_mode == [1  3  4  5 ])
    par_exp.gamepadIndices = handles.gamepadIndices; 
    par_exp.prop_axes_joy  = handles.prop_axes_joy;
    par_exp.status_center  = handles.status_center;
    
%- MOUSE    
elseif handles.flag_input_mode == 2
    par_exp.coords_0 = handles.coords_0;
    
end

%- Save output files
par_exp.file_name_save = handles.file_name_save;
par_exp.path_name_save = handles.path_name_save;


par_exp.t_start_EXP = [];

%- Experimental parameters
par_general             = handles.par_general;
par_general.flag_input_mode  = handles.flag_input_mode; 
par_general.ind_run     = handles.ind_run;
par_general.par_screen  = [];

%- Update run index
handles.ind_run = handles.ind_run +1;
guidata(hObject, handles)

%- Run task
par_general.screen_init   = 1;  
par_general.screen_delete = 1; 
par_general.flag_blocks   = 0;
par_general.ind_block     = 0;
CERDYS_run_task_v5(par_exp,par_general);


%========================================================================== 
%= Run BLOCK with same deviation
%========================================================================== 

function button_start_block_dev_Callback(hObject, eventdata, handles)

%- Get properties of block
block_pause     = str2double(get(handles.text_block_dev_pause,'String'));
block_N_trials  = str2double(get(handles.text_block_dev_N_trials,'String'));
block_N_repeats = str2double(get(handles.text_block_dev_N_repeats,'String'));

%- Experimental parameters
par_exp = handles.par_exp;

%== From joystick/mouse calibration

%- JOYSTICK 
if sum(handles.flag_input_mode == [1  3  4  5 ])
    par_exp.gamepadIndices = handles.gamepadIndices; 
    par_exp.prop_axes_joy  = handles.prop_axes_joy;
    par_exp.status_center  = handles.status_center;
    
%- MOUSE    
elseif handles.flag_input_mode == 2
    par_exp.coords_0 = handles.coords_0;
    
end

%- Save output files
par_exp.file_name_save = handles.file_name_save;
par_exp.path_name_save = handles.path_name_save;

%- Experimental parameters & other stuff
par_general             = handles.par_general;
par_general.flag_input_mode  = handles.flag_input_mode; 
par_general.ind_run     = handles.ind_run;
par_general.flag_blocks = 1;
par_general.block_pause = block_pause;

%- Get parameters for blocks
angle_deviations = par_exp.angle_deviations;
angle_targets    = par_exp.angle_targets;

%- Get deviation angles for each block
% angle_dev_all = repmat(angle_deviations,1,block_N_repeats);
angle_dev_all = angle_deviations;
N_blocks      = length(angle_dev_all);
% rand_order    = randperm(N_blocks);
% angle_dev_all = angle_dev_all(rand_order);

%- Define target angles for each block
N_rep_ang        = ceil(block_N_trials/length(angle_targets));
angle_target_all = repmat(angle_targets,1,N_rep_ang);
N_ang_total      = length(angle_target_all);

%- Update run index
handles.ind_run = handles.ind_run +1;
guidata(hObject, handles)

%- Go over blocks
for i_block = 1:N_blocks
   
    %- Display block
    fprintf('\n\n==== BLOCK %g of %g \n', i_block,N_blocks)
    
    
    %- Block index
    par_general.ind_block = i_block;
    
    % EDF file name must be defined here
    EDFname = sprintf(['EL_' num2str(ceil(i_block/2))]);
    par_general.edfFile = [EDFname '.edf'];
    
    %- Deviation angle
    angle_dev_loop      = angle_dev_all(i_block);
    fprintf('Deviation angle: %g \n', angle_dev_loop)
    
    
    %- Sequence of target angles
    rand_order_ang = randperm(N_ang_total);
    rand_order_ang = rand_order_ang(1:block_N_trials);
    angle_tar_loop = angle_target_all(rand_order_ang);
    fprintf('Target angle:'); disp(angle_tar_loop)
    
    
    %- Run-sequence
    run_sequence_def(:,2) =  angle_tar_loop;
    run_sequence_def(:,1) =  angle_dev_loop;
    par_exp.run_sequence_def = run_sequence_def;
    par_exp.N_run_total      = block_N_trials;
    
    %- Run task
    if i_block == 1
        par_general.screen_init   = 1;  
        par_general.screen_delete = 0;   
        par_screen = [];
    else
        par_general.screen_init   = 0;
        par_general.screen_delete = 0;
    end
    
    par_general.par_screen = par_screen;
    
    if i_block == 1
        par_exp.t_start_EXP = [];
    end
    
    [par_screen,par_exp.t_start_EXP] = CERDYS_run_task_v5(par_exp,par_general);
        
    %- Pause commented, pause is now in CERDYS_run_task_v4 (waiting for
    %eyetracker
    % pause(block_pause)
end

%- Delete figure if still exists
h_figure = par_screen.h_figure;
if (exist('h_figure'))
    delete(h_figure)
end

%========================================================================== 
%= Analyze files
%==========================================================================

%= Analyze individual files
function menu_analyze_indiv_Callback(hObject, eventdata, handles)
CERDYS_analyze_indiv_v2;


%= Analyze multiple files
function menu_analyze_multi_Callback(hObject, eventdata, handles)
CERDYS_analyze_multi_v2;


%========================================================================== 
%= Not used
%========================================================================== 

function checkbox_joystick_correct_center_Callback(hObject, eventdata, handles)

function text_block_dev_pause_Callback(hObject, eventdata, handles)

function text_block_dev_pause_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function text_block_dev_N_trials_Callback(hObject, eventdata, handles)

function text_block_dev_N_trials_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function text_block_dev_N_repeats_Callback(hObject, eventdata, handles)

function text_block_dev_N_repeats_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function Untitled_1_Callback(hObject, eventdata, handles)
