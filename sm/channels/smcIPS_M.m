function val = smcIPS_M(ic, val, rate)
    % Device driver for Oxford Mercury IPS-M magnet controller
    % Written by Pengjie, May 2025
    % Elsa: UID GRPZ
    global smdata;
    % Get instrument structure from ic(1) 
    inst = smdata.inst(ic(1)).data.inst;
    timeout = 30;
    waitforset = 0;
    AtoB = 21.8788; %Elsa
    

%% Function: read the field in the coil
    function field=getField()
        pcurr = query(inst,'READ:DEV:GRPZ:PSU:SIG:PCUR','%s\n','STAT:DEV:GRPZ:PSU:SIG:PCUR:%fA\n');       
        field = pcurr/AtoB; %unit: T
        % field = pcurr/getAtoB(); %unit: T
        % The following method has less accuracy
        % pcurr = query(inst,'READ:DEV:GRPZ:PSU:SIG:PFLD','%s\n','STAT:DEV:GRPZ:PSU:SIG:PFLD:%fT\n');
    end
%% Function: get Ratio
    function AtoB = getAtoB()
        AtoB = query(inst, 'READ:DEV:GRPZ:PSU:ATOB','%s\n','STAT:DEV:GRPZ:PSU:ATOB:%f\n'); %unit: A/T
    end
%% Function: Set and get the ramp rate assuming only one segment exists
    function RampRate = getRampRate()
        RampRate = query(inst, 'READ:DEV:GRPZ:PSU:SIG:RFST','%s\n','STAT:DEV:GRPZ:PSU:SIG:RFST:%fT/m\n');
    end
    
    function SetRamprate(RampRate)
        ret = query(inst,sprintf('SET:DEV:GRPZ:PSU:SIG:RFST:%fT/m',RampRate),'%s\n');
    end 
    
%% Function: check if the magnet is in persistent mode.    
    function status=isInPersistent()
        ret=query(inst, 'READ:DEV:GRPZ:PSU:SIG:SWHT','%s\n');
        status = contains(ret, 'OFF');    %SWHT OFF means the isInPersistent = 1
    end
%% Function: check if the magnet field is at target
%     function attarget=isFieldAtTarget()
%         ret = query(inst,'READ:DEV:GRPZ:PSU:ACTN?');
%         attarget = contains(ret, ':HOLD');
%     end

%% Function: ramp to a specified field. If field=0, the program will zero the current. If field=NaN, the program will just ramp to previous target
    function status=rampToField(field)
        status=0;
        if field==0
            ret = query(inst, sprintf('SET:DEV:GRPZ:PSU:SIG:FSET:%f\n',field)); 
            query(inst, 'SET:DEV:GRPZ:PSU:ACTN:RTOZ');
        elseif ~isnan(field)
            query(inst, 'SET:DEV:GRPZ:PSU:ACTN:HOLD','%s\n');
            ret = query(inst, sprintf('SET:DEV:GRPZ:PSU:SIG:FSET:%f\n',field));
            query(inst, 'SET:DEV:GRPZ:PSU:ACTN:RTOS','%s\n');
        else   %%% if field = NaN, for use when exiting persistent mode
            query(inst, 'SET:DEV:GRPZ:PSU:ACTN:RTOS','%s\n');
        end
        if waitforset == 1
            ret=query(inst, 'READ:DEV:GRPZ:PSU:ACTN','%s\n');
            while ~contains(ret,'HOLD')
    %             % Wait until the ramping is finished
                pause(1);
                ret=query(inst, 'READ:DEV:GRPZ:PSU:ACTN','%s\n');
    %             if strcmp(ret,['7',crlf])
    %                 disp('!!!QUENCH!!!');
    %                 return;
    %             end
            end
        end
    end

%% Function: set the status of persistent mode. Note: this will *NOT* check the current in the leads
    function setPersistent(pers)
        % Turn on/off persistent switch
        if pers
            ret = query(inst,'SET:DEV:GRPZ:PSU:SIG:SWHT:OFF','%s\n');
            disp('Turning OFF the persistent switch heater, entering persistent mode');
        else
            ret = query(inst,'SET:DEV:GRPZ:PSU:SIG:SWHT:ON','%s\n');
            disp('Turning ON the persistent switch heater, exiting persistent mode');
        end
        
        t=0;
        ret=query(inst, 'READ:DEV:GRPZ:PSU:SIG:SWHT','%s\n');
        while(((contains(ret,'ON') && pers) || (contains(ret,'OFF') && pers)) && t < timeout)
            % Wait until the persistent switch is heated up
            pause(1);
            ret=query(inst, 'READ:DEV:GRPZ:PSU:SIG:SWHT','%s\n');
            t=t+1;
        end
        if t>=timeout
            error('Error when turning on/off persistent switch: timeout');
        end
    end


%% Function: enter persistent mode
    function enterPersistent()
        % Check if we are already in persistent mode.
        if isInPersistent()
            return;
        end

        % Make sure it holds at the setpoint
        query(inst, 'SET:DEV:GRPZ:PSU:ACTN:RTOS','%s\n');
        
        % Wait until it is in HOLD state
        ret = query(inst,'READ:DEV:GRPZ:PSU:ACTN?','%s\n');
        while (contains(ret,':HOLD') == 0)
            % Wait until the persistent switch is heated up
            pause(1);
            ret = query(inst,'READ:DEV:GRPZ:PSU:SIG:SWHT','%s\n');
            if contains(ret,'ON')
                return;
            end
        end
        
        % Turn OFF the heater of the persistent switch
        setPersistent(true);
        
        % Ramp the current to zero
        ret=query(inst, 'SET:DEV:GRPZ:PSU:ACTN:RTOZ','%s\n');
        
        % Wait until it is in ZERO current state
        ret = query(inst, 'READ:DEV:GRPZ:PSU:ACTN','%s\n');
        ret2 = query(inst, 'READ:DEV:GRPZ:PSU:SIG:CURR','%s\n');
        curr = str2double(regexp(ret2, '([-+]?\d*\.\d+)', 'match'));
        while(contains(ret,'HOLD') && curr == 0)
            % Wait until the persistent switch is heated up
            pause(1);
            ret=query(inst, 'state?');
            if contains(ret,['7',crlf])
                disp('!!!QUENCH!!!');
                return;
            end
        end
    end
%% Function: exit persistent mode
    function exitPersistent()
        % Check if we are already not in persistent mode.
        if ~isInPersistent()
            return;
        end
        % Go back to ramp mode, current will go to previous target
        query(inst, 'SET:DEV:GRPZ:PSU:ACTN:RTOS','%s\n');
        
        % Wait until it is in HOLD state
        ret=query(inst, 'SET:DEV:GRPZ:PSU:ACTN','%s\n');
        while(contains(ret,'HOLD') == 0)
            % Wait until the ramping is finished
            pause(1);
            ret=query(inst, 'state?');
            if contains(ret,['7',crlf])
                disp('!!!QUENCH!!!');
                return;
            end
        end
        
        % Turn on the persistent switch
        setPersistent(false);
        
        % Go back to ramp mode, to make sure the original target is reached
        query(inst, 'SET:DEV:GRPZ:PSU:ACTN:RTOS','%s\n');
        
        % Wait until it is in HOLD state
        ret=query(inst, 'state?');
        while(contains(ret,['2',crlf]) == 0)
            % Wait until the ramping is finished
            pause(1);
            ret=query(inst, 'state?');
            if contains(ret,['7',crlf])
                disp('!!!QUENCH!!!');
                return;
            end
        end
    end

%% Main state machine
    switch ic(2) %operation
        case 1
            if ic(3) == 0 %get
                val = getField();
            else %set
                % Two cases, depending on if in persistent mode or not
                % Query persistent switch mode
                if isInPersistent()
                    % Exit persistent mode
                    exitPersistent();
                    % Ramp to field
                    rampToField(val);
                    %wait until manget voltage is less than 0.05 V
                    Vm = query(inst,'READ:DEV:GRPZ:PSU:SIG:VOLT','%s\n','STAT:DEV:GRPZ:PSU:SIG:VOLT:%fV\n');
                    while( abs(Vm) >= 0.05)
                        pause(1);
                        Vm = query(inst,'READ:DEV:GRPZ:PSU:SIG:VOLT','%s\n','STAT:DEV:GRPZ:PSU:SIG:VOLT:%fV\n');                            
                    end
                    fprintf('Field stable at %f T\n', val);
                    % Re-enter persistent mode
                    enterPersistent()
                else
                    rampToField(val);
                    fprintf('Field at %f T\n', val);
                end
            end
        case 2  % Persistent Switch
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
        case 3  % Ramp Rate
            
            if ic(3) == 0 %get ramp rate
                val = getRampRate();   
            elseif ic(3) == 1 % set ramprate
                SetRamprate(val);
            end  
    end
end

