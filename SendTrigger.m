function trig = SendTrigger( trigger )
%SendTrigger outputs 8 bit value to parallel port
%   Port is reset to zero after 5 milliseconds
trig = trigger;
WriteParPort(trigger);
WaitSecs(.005);
WriteParPort(0);
end

