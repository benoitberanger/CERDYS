function [datresp] = TestJoyStick()

catresp = {'R','G','B'}; % colors of response buttons
datresp = zeros(1,100); % codes of response buttons

KbName('UnifyKeyNames');
keyquit = KbName('ESCAPE'); % abort test

try
    
    % listen to key events
    FlushEvents;
    ListenChar(2);
    
    % open response port
    hport = IOPort('OpenSerialPort','COM1');
    IOPort('ConfigureSerialPort',hport,'BaudRate=57600');
    IOPort('Purge',hport);
    
    % wait 1 s
    WaitSecs(1.000);
    
    % test response buttons
    fprintf('\n\n\n');
    aborted = false;
%     for i = 1:100
    fprintf('WAITING FOR INPUT... \n');
    while (aborted == false)
%         fprintf('WAITING FOR [%s] BUTTON... ',catresp{i});
%         fprintf('WAITING FOR INPUT... ');
        lx = 0;
        ly = 0;
        while 1
            if CheckKeyPress(keyquit)
                fprintf('ABORTED!\n');
                aborted = true;
                break
            end
            [x,y] = SerialJoyStick(hport);
            if ((x ~= lx)||(y ~= ly))
                fprintf('%g %g\n',x, y);
                lx = x;
             ly = y;
            end
        end
    end
    fprintf('\n\n\n');
    
    % close response port
    IOPort('Close',hport);
    
    % stop listening to key events
    FlushEvents;
    ListenChar(0);
    
    if aborted
        datresp = [];
    end
    
catch
    
    % close response port
    IOPort('Close',hport);
    
    % stop listening to key events
    FlushEvents;
    ListenChar(0);
    
    rethrow(lasterror);
    
end

end