function val = smcCryoMag(ic, val, rate)
    %Device driver for magnet controller
    %Written by Yuan, Oct 2015
    % Dec 4 2015: Bug fix by Yuan
    
    global smdata;
    % Get instrument structure from ic(1) 
    inst = smdata.inst(ic(1)).data.inst;
    crlf = char([13, 10]);
    timeout = 30;
%% Function: check if the magnet is in persistent mode.    
    function status=isInPersistent()
        ret=query(inst, 'pswitch?');
        status = strcmp(ret,  ['0' crlf]);
    end
%% Function: check if the magnet field is at target
%     function attarget=isFieldAtTarget()
%         ret=query(inst, 'state?');
%         attarget = strcmp(ret, ['2' crlf]);
%     end
%% Function: read the field in the coil
    function field=getField()
        ret=query(inst, 'field:magnet?');
        field=str2double(ret);
    end
%% Function: set the status of persistent mode. Note: this will *NOT* check the current in the leads
    function setPersistent(pers)
        % Turn on/off persistent switch
        if pers
            disp('Turning off the persistent switch, entering persistent mode');
        else
            disp('Turning on the persistent switch, exiting persistent mode');
        end
        fprintf(inst, ['pswitch ' num2str(~pers)]); % pers=1 => turn off pswitch
        ret=query(inst, 'state?');
        t=0;
        while((strcmp(ret,['9',crlf]) || strcmp(ret,['10',crlf])) && t < timeout)
            % Wait until the persistent switch is heated up
            pause(1);
            ret=query(inst, 'state?');
            t=t+1;
        end
        if t>=timeout
            error('Error when turning on/off persistent switch: timeout');
        end
    end
%% Function: ramp to a specified field. If field=0, the program will zero the current. If field=NaN, the program will just ramp to previous target
    function status=rampToField(field)
        status=0;
        if field==0
            fprintf(inst, 'configure:field:target 0'); %%<-- this is inappropriate. Need different B=0 "mode"
            fprintf(inst, 'zero');
        elseif ~isnan(field)
            fprintf(inst, ['configure:field:target ' num2str(field)]);
            fprintf(inst, 'ramp');
        else   %%% if field = NaN, for use when exiting persistent mode
            fprintf(inst, 'ramp');
        end
        ret=query(inst, 'state?');
        while((strcmp(ret,['1',crlf]) || strcmp(ret,['6',crlf])))
            % Wait until the persistent switch is heated up
            pause(1);
            ret=query(inst, 'state?');
            if strcmp(ret,['7',crlf])
                disp('!!!QUENCH!!!');
                return;
            end
        end
    end

%% Function: enter persistent mode
    function enterPersistent()
        % Check if we are already in persistent mode.
        if isInPersistent()
            return;
        end
        % Turn off persistent switch
        setPersistent(true);
        % Ramp the field to zero
        rampToField(0);
    end
%% Function: exit persistent mode
    function exitPersistent()
        if ~isInPersistent()
            return;
        end
        % Attempt to ramp to previous magnet target
        rampToField(NaN); 
        % Turn on the persistent switch
        setPersistent(false);
    end
%% Main state machine
    switch ic(2) %operation
        case 1
            if ic(3) == 0 %get
                val = getField();
            else %set
                % Query persistent switch mode
                if isInPersistent()
                    answer = input('Magnet is in persistent mode. Exit persistent mode? (yes/no)','s');
                    if strcmp(answer,'yes')
                        % Exit persistent mode
                        exitPersistent();
                    else
                        return;
                    end
                end
                rampToField(val);
                fprintf('Field at %f T\n', val);
            end
        case 2
            if ic(3) == 0
                val = isInPersistent();
            else
                switch(val)
                    case 0
                        exitPersistent();
                    case 1
                        enterPersistent();
                    otherwise
                        error('Persistent mode can be either enter(1) or exit(0).');
                end
            end
    end
end

