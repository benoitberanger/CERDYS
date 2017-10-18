function [gamepadIndices, prop_axes] = CERDYS_calibrate_joystick_v3(status_center,flag_input_mode)
%-- Function to calibrate the fORP-Tethyx joystick to be used for the
%CERDYS task
% 
% IMPORTANT settings of controller: set to HID JOY compt



%% Find gamepads index, hopefully only a single index:

% JOYSTICK (USB)
if flag_input_mode == 1
    gamepadIndices = GetGamepadIndices;

% JOYSTICK (SERIAL)
elseif flag_input_mode == 3
    
    gamepadIndices  = IOPort('OpenSerialPort','COM1');
    IOPort('ConfigureSerialPort',gamepadIndices,'BaudRate=57600');
    IOPort('Purge',gamepadIndices);
    WaitSecs(1.000);
    
    
 % JOYSTICK (WIN)
elseif flag_input_mode == 4   ||  flag_input_mode == 5
    
    %- Initialize joystick
    joymex2('open',0);
    gamepadIndices  = 0;
end
    
%% Calibration of Joystick - minimum and maximum values

t_test = 10;

button = 'No';
while strcmp(button,'No')

    prop_axes.ax1_min = +inf;
    prop_axes.ax1_max  = -inf;

    prop_axes.ax2_min = +inf;
    prop_axes.ax2_max  = -inf;

    h_help2 = helpdlg('For the next 10s move joystick to all extreme positions. Press ok when ready to start. ','Calibrate joystick range.');
    uiwait(h_help2)

    t_start = tic;

    h_fig=figure;
    clf
    set(h_fig,'Color','w')
    box on
    hold on
    
    while toc(t_start) < t_test
        
        %- JOYSTICK (USB)
        if flag_input_mode == 1
            val_ax1 = PsychHID('RawState',gamepadIndices,1);
            val_ax2 = PsychHID('RawState',gamepadIndices,2);
         
            %- Not sure why but the joystick sometimes return values that are too large
            if val_ax2 > 10000; val_ax2 = val_ax2 - 2^16; end
            if val_ax1 > 10000; val_ax1 = val_ax1 - 2^16; end
            
        %- JOYSTICK (SERIAL)    
        elseif flag_input_mode == 3
             [ val_ax1, val_ax2] = SerialJoyStick(gamepadIndices);
             
        %- JOYSTICK (WIN)    
        elseif flag_input_mode == 4 || flag_input_mode == 5
             joy_prop = joymex2('query',0);
             val_ax1 = double(joy_prop.axes(1)); val_ax2 = double(joy_prop.axes(2));          
        end
        
        if val_ax1 < prop_axes.ax1_min ; prop_axes.ax1_min  = val_ax1; end
        if val_ax1 > prop_axes.ax1_max; prop_axes.ax1_max = val_ax1; end

        if val_ax2 < prop_axes.ax2_min; prop_axes.ax2_min = val_ax2; end
        if val_ax2 > prop_axes.ax2_max; prop_axes.ax2_max = val_ax2; end
        
        %- Shows spot in figure and also in command line
        %disp([val_ax1 val_ax2])
        plot(val_ax1,val_ax2,'o','MarkerEdgeColor','b',...
                                 'MarkerFaceColor','b',...
                                 'MarkerSize',10)
        

        pause(0.2)
    end

    hold off
    
    disp(['Axis 1 (X) minimum: ', num2str(prop_axes.ax1_min )])
    disp(['Axis 1 (X) maximum: ', num2str(prop_axes.ax1_max)])

    disp(['Axis 2 (Y) minimum: ', num2str(prop_axes.ax2_min)])
    disp(['Axis 2 (Y) maximum: ', num2str(prop_axes.ax2_max)])

    button = questdlg('Satisfied with movement?','Calibration of joystick','Yes','No','Yes'); 
end
    

%% Get center position

if status_center


    N_center = 5;
    i_center =1;


    while i_center < N_center

        text_wait = ['Determine center position of joystick trial ', num2str(i_center), ' of ', num2str(N_center),'. Move joystick and let it relax to central positon. NO cursor will be displayed. Press ok when ready. ','Calibrate joystick center'];
        h_help2 = helpdlg(text_wait);
        uiwait(h_help2)

        %- JOYSTICK (USB)
        if flag_input_mode == 1
            val_ax1 = PsychHID('RawState',gamepadIndices,1);
            val_ax2 = PsychHID('RawState',gamepadIndices,2);
            
            %- Not sure why but the joystick sometimes return values that are too large
            if val_ax2 > 10000; val_ax2 = val_ax2 - 2^16; end
            if val_ax1 > 10000; val_ax1 = val_ax1 - 2^16; end
            
        %- JOYSTICK (SERIAL)    
        elseif flag_input_mode == 3
             [ val_ax1, val_ax2] = SerialJoyStick(gamepadIndices);
             
        elseif flag_input_mode == 4 || flag_input_mode == 5
             joy_prop = joymex2('query',0);
             val_ax1 = double(joy_prop.axes(1)); val_ax2 = double(joy_prop.axes(2));           
        end
        
        hold on
            h_center = plot(val_ax1,val_ax2,'o','MarkerEdgeColor','r',...
                                 'MarkerFaceColor','r',...
                                 'MarkerSize',15);
        hold off
        
        disp(['Axis 1 (X) center: ', num2str(val_ax1 )])
        disp(['Axis 1 (X) center: ', num2str(val_ax2)])

        button = 'No';
        button = questdlg('Satisfied with center?','Calibration of joystick','Yes','No','Yes'); 

        delete(h_center)
        switch button
            case 'No'

            case 'Yes'
                center_ax1_all(i_center,1) = val_ax1;
                center_ax2_all(i_center,1) = val_ax2;

                hold on
                    h_center = plot(val_ax1,val_ax2,'+','MarkerEdgeColor','r',...
                                 'MarkerFaceColor','r',...
                                 'MarkerSize',15);
                hold off
                
                i_center = i_center+1;

        end

    end


    %- Average center
    center_ax1 = round(median(center_ax1_all));
    center_ax2 = round(median(center_ax2_all));
    hold on
    h_center = plot(center_ax1,center_ax2,'o','MarkerEdgeColor','r',...
                                 'MarkerFaceColor','r',...
                                 'MarkerSize',10);
    hold off
    
    %- Calculate distance between extremes and from center
    prop_axes.ax1_center = center_ax1;
    prop_axes.ax2_center = center_ax2;
    
    prop_axes.ax1_diff_pos = (prop_axes.ax1_max - center_ax1);
    prop_axes.ax1_diff_neg = (center_ax1 - prop_axes.ax1_min);
    
    prop_axes.ax2_diff_pos = (prop_axes.ax2_max - center_ax2); 
    prop_axes.ax2_diff_neg = (center_ax2 - prop_axes.ax2_min);
    
else
    
    %- Calculate distance between extremes and from center
    prop_axes.ax1_center = (prop_axes.ax1_max + prop_axes.ax1_min)/2;
    prop_axes.ax2_center = (prop_axes.ax2_max + prop_axes.ax2_min)/2;

end

%- Calculate distance between extremes and from center
prop_axes.ax1_diff = (prop_axes.ax1_max - prop_axes.ax1_min);
prop_axes.ax2_diff = (prop_axes.ax2_max - prop_axes.ax2_min);

prop_axes.ax1_diff_pos = (prop_axes.ax1_max - prop_axes.ax1_center);
prop_axes.ax1_diff_neg = (prop_axes.ax1_center - prop_axes.ax1_min);

prop_axes.ax2_diff_pos = (prop_axes.ax2_max - prop_axes.ax2_center); 
prop_axes.ax2_diff_neg = (prop_axes.ax2_center - prop_axes.ax2_min);
