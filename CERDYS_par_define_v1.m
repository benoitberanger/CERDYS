function par_general = CERDYS_define_par_v1

%===  Advanced parameters - will not be changed often
%     In future version can be specified in separate dialog
par_general.instruct_font_size = 16;   % Font size for instructions

%- Parameters related to geometry
par_general.cursor_size   = 15;    % Size of cursor
par_general.radius_center = 0.1; % Radius of circle in center (starting point)
par_general.radius_target = 0.075; % Radius of target(s)
par_general.cross_length  = 0.1;   % Length of arms of the cross which is shown during the pause
par_general.scale_cursor  = 300;   % Scaling factor for display of cursor position (depends on input device)

par_general.dt            = 0.03;  % Delta-t, time the programs pauses between runs
par_general.dt_repos      = 1;
par_general.radius_outer  = 1;     % Radius of outer circle (location of targets)
par_general.axis_limit    = par_general.radius_outer+1.5*par_general.radius_target;
par_general.axis_vector   = [-1*par_general.axis_limit 1*par_general.axis_limit -par_general.axis_limit par_general.axis_limit];
par_general.flag_show_outer = 0;   % Flag to indicate if outer, bounding circle should be displayed
                       % 1 to show it, 0 to not show it