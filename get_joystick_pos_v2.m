function [coords_disp coords_joy] = get_joystick_pos_v2(gamepadIndices,prop_axes_joy,prop_axes_disp,ax_offset,status_center,flag_input_mode)


% %- GET COORDINATES FROM JOYSTICK
% val_ax1 = PsychHID('RawState',gamepadIndices,1);
% val_ax2 = PsychHID('RawState',gamepadIndices,2);

%- JOYSTICK (USB)
if flag_input_mode == 1
    val_ax1 = PsychHID('RawState',gamepadIndices,1);
    val_ax2 = PsychHID('RawState',gamepadIndices,2);
    
    %- Not sure why but the joystick sometimes return values that are
    %too large
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





switch status_center
    
    %=== OLD VERSION WITHOUT ANY CENTER CORRECTION    
    case 0
        val_ax1_norm  = (val_ax1-prop_axes_joy.ax1_min) / prop_axes_joy.ax1_diff;
        val_ax2_norm  = (val_ax2-prop_axes_joy.ax2_min) / prop_axes_joy.ax2_diff;

        %- Invert ax2
        val_ax2_norm = 1-val_ax2_norm;

        %val_ax1_rescale = val_ax1_norm*x_diff + x_min;
        val_ax1_rescale = val_ax1_norm*prop_axes_disp.y_diff + prop_axes_disp.y_min; %- For some movement-range in x as in y
        val_ax2_rescale = val_ax2_norm*prop_axes_disp.y_diff + prop_axes_disp.y_min;  
    
    %==== Different rescaling for positive and negative range
    case 1
        
        %- JOYSTICK (USB)
        if flag_input_mode == 1 || flag_input_mode == 4 || flag_input_mode == 5
        
            if val_ax1 >= prop_axes_joy.ax1_center
                val_ax1_norm  = (val_ax1-prop_axes_joy.ax1_center) / prop_axes_joy.ax1_diff_pos;
                val_ax1_rescale = val_ax1_norm*prop_axes_disp.y_diff/2 ; %- For some movement-range in x as in y
            end

            if val_ax1 < prop_axes_joy.ax1_center
                val_ax1_norm  = (val_ax1-prop_axes_joy.ax1_center) / prop_axes_joy.ax1_diff_neg;
                val_ax1_rescale = val_ax1_norm*prop_axes_disp.y_diff/2 ; %- For some movement-range in x as in y
            end

            if val_ax2 >= prop_axes_joy.ax2_center
                val_ax2_norm = (val_ax2-prop_axes_joy.ax2_center) / prop_axes_joy.ax2_diff_pos;
                val_ax2_norm = -val_ax2_norm;
                val_ax2_rescale = val_ax2_norm*prop_axes_disp.y_diff/2 ; %- For some movement-range in x as in y
            end

            if val_ax2 < prop_axes_joy.ax2_center
                val_ax2_norm  = (val_ax2-prop_axes_joy.ax2_center) / prop_axes_joy.ax2_diff_neg;
                val_ax2_norm = -val_ax2_norm;
                val_ax2_rescale = val_ax2_norm*prop_axes_disp.y_diff/2 ; %- For some movement-range in x as in y
            end 
            
        %- JOYSTICK (SERIAL)    
        elseif flag_input_mode == 3 
            if val_ax1 >= prop_axes_joy.ax1_center
                val_ax1_norm  = (val_ax1-prop_axes_joy.ax1_center) / prop_axes_joy.ax1_diff_pos;
                val_ax1_norm = -val_ax1_norm;
                val_ax1_rescale = val_ax1_norm*prop_axes_disp.y_diff/2 ; %- For some movement-range in x as in y
            end

            if val_ax1 < prop_axes_joy.ax1_center
                val_ax1_norm  = (val_ax1-prop_axes_joy.ax1_center) / prop_axes_joy.ax1_diff_neg;
                val_ax1_norm = -val_ax1_norm;
                val_ax1_rescale = val_ax1_norm*prop_axes_disp.y_diff/2 ; %- For some movement-range in x as in y
            end

            if val_ax2 >= prop_axes_joy.ax2_center
                val_ax2_norm = (val_ax2-prop_axes_joy.ax2_center) / prop_axes_joy.ax2_diff_pos;
                val_ax2_norm = -val_ax2_norm;
                val_ax2_rescale = val_ax2_norm*prop_axes_disp.y_diff/2 ; %- For some movement-range in x as in y
            end

            if val_ax2 < prop_axes_joy.ax2_center
                val_ax2_norm  = (val_ax2-prop_axes_joy.ax2_center) / prop_axes_joy.ax2_diff_neg;
                val_ax2_norm = -val_ax2_norm;
                val_ax2_rescale = val_ax2_norm*prop_axes_disp.y_diff/2 ; %- For some movement-range in x as in y
            end        
           
        end
        
    %== Simple subtraction of offset - limits mobility of cursor
    case 2
        val_ax1_norm  = (val_ax1-prop_axes_joy.ax1_min) / prop_axes_joy.ax1_diff;
        val_ax2_norm  = (val_ax2-prop_axes_joy.ax2_min) / prop_axes_joy.ax2_diff;

        %- Invert ax2
        val_ax2_norm = 1-val_ax2_norm;

        val_ax1_rescale = val_ax1_norm*prop_axes_disp.y_diff + prop_axes_disp.y_min; %- For some movement-range in x as in y
        val_ax2_rescale = val_ax2_norm*prop_axes_disp.y_diff + prop_axes_disp.y_min;  
    
        val_ax1_rescale = val_ax1_rescale - ax_offset.ax1;  %- Correct for offset ;  %- Correct for offset
        val_ax2_rescale = val_ax2_rescale - ax_offset.ax2; 
end

coords_disp(1) = double(val_ax1_rescale);  %- Correct for offset
coords_disp(2) = double(val_ax2_rescale); 

coords_joy(1) = double(val_ax1);
coords_joy(2) = double(val_ax2);
