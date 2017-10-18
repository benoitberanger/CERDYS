function [x,y,trigger] = SerialJoyStick(hport)
    t = tic;
    x = -1;
    y = -1;
    while(toc(t) < 1)   % 1 second timeout
        dat = [];
        while isempty(dat)
            dat = IOPort('Read',hport);
        end
        IOPort('Purge',hport);
%         datresp(i) = dat(1);
        if (size(dat,2) >= 4)
%            fprintf('%d %d %d %d\n',dat(1),dat(2),dat(3),dat(4));
            x = (dat(2) + 128 * dat(4));
            y = (dat(3) + 128 * bitand(dat(1), 15));
            trigger = bitand(dat(1), 32);
            return;
        end
    end
    fprintf ('Time out waiting for joystick input\n');
end