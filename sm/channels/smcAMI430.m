function val = smcAMI430(ic, val, rate)
    %Device driver for magnet controller
    %Written by Yuan, Oct 2015
    % Dec 4 2015: Bug fix by Yuan
    % Sept 12 2016: Bug fix by Valla (no longer exists persistent mode at wrong field)
    % Feb 15 2017: Bug fix by Yuan. Added "ramp" commands and check for HOLD state to prevent the field from changing when entering and exiting persistent mode
    
    global smdata;
    % Get instrument structure from ic(1) 
    inst = smdata.inst(ic(1)).data.inst;
    crlf = char([13, 10]);
    timeout = 30;
    
  %% Function: Set and get  the ramp rate assuming only one segment exists
    function RampRate = getRampRate()
        ret=query(inst, 'RAMP:RATE:FIELD:1?');
        RampRate=str2double(ret(1:10));
        %pause(0.1);
    end
  
   function SetRamprate(RampRate)
        fprintf(inst,sprintf('CONFigure:RAMP:RATE:FIELD 1,%f, 5.0',RampRate));
    end
    
    
    
% %% Function: check if the magnet is in persistent mode.    
%     function status=isInPersistent()
%         ret=query(inst, 'pswitch?');
%         status = strcmp(ret,  ['0' crlf]);
%     end
%% Function: check if the magnet field is at target
%     function attarget=isFieldAtTarget()
%         ret=query(inst, 'state?');
%         attarget = strcmp(ret, ['2' crlf]);
%     end
%% Function: read the field in the coil
    function field=getField()
        ret=query(inst, 'field:magnet?');
        field=str2double(ret);
        %pause(0.1);
    end
%% Function: ramp to a specified field. If field=0, the program will zero the current. If field=NaN, the program will just ramp to previous target
    function status=rampToField(field)
        status=0;
        if field==0
            fprintf(inst, 'configure:field:target 0'); %%<-- this is inappropriate. Need different B=0 "mode". 2/15/2017: this is good now
            fprintf(inst, 'zero');
        elseif ~isnan(field)
            fprintf(inst, ['configure:field:target ' num2str(field)]);
            fprintf(inst, 'ramp');
        else   %%% if field = NaN, for use when exiting persistent mode
            fprintf(inst, 'ramp');
        end
        ret=query(inst, 'state?');
        
 %---------comment to auto quit after setting target B---------       
%         while(strcmp(ret,['2',crlf]) == 0 && strcmp(ret,['8',crlf]) == 0)
%             % Wait until the ramping is finished
%             pause(1);
%             ret=query(inst, 'state?');
%             if strcmp(ret,['7',crlf])
%                 disp('!!!QUENCH!!!');
%                 return;
%             end
%         end       
 %-----------------------------------                
    end

% %% Function: set the status of persistent mode. Note: this will *NOT* check the current in the leads
%     function setPersistent(pers)
%         % Turn on/off persistent switch
%         if pers
%             disp('Turning off the persistent switch, entering persistent mode');
%         else
%             disp('Turning on the persistent switch, exiting persistent mode');
%         end
%         fprintf(inst, ['pswitch ' num2str(~pers)]); % pers=1 => turn off pswitch
%         ret=query(inst, 'state?');
%         t=0;
%         while((strcmp(ret,['9',crlf]) || strcmp(ret,['10',crlf])) && t < timeout)
%             % Wait until the persistent switch is heated up
%             pause(1);
%             ret=query(inst, 'state?');
%             t=t+1;
%         end
%         if t>=timeout
%             error('Error when turning on/off persistent switch: timeout');
%         end
%     end
% 

% %% Function: enter persistent mode
%     function enterPersistent()
%         % Check if we are already in persistent mode.
%         if isInPersistent()
%             return;
%         end
%         % Check if we are in "zero" mode as is
% %         if str2num(query(inst, 'state?'))==8
% %             setPersistent(true);
% %             return;
% %         end
%         % Make sure it holds at the setpoint
%         fprintf(inst, 'ramp');
%         
%         % Wait until it is in HOLD state
%         ret=query(inst, 'state?');
%         while(strcmp(ret,['2',crlf]) == 0)
%             % Wait until the persistent switch is heated up
%             pause(1);
%             ret=query(inst, 'state?');
%             if strcmp(ret,['7',crlf])
%                 disp('!!!QUENCH!!!');
%                 return;
%             end
%         end
%         
%         % Turn off persistent switch
%         setPersistent(true);
%         
%         % Ramp the current to zero
%         fprintf(inst, 'zero');
%         
%         % Wait until it is in ZERO current state
%         ret=query(inst, 'state?');
%         while(strcmp(ret,['6',crlf]))
%             % Wait until the persistent switch is heated up
%             pause(1);
%             ret=query(inst, 'state?');
%             if strcmp(ret,['7',crlf])
%                 disp('!!!QUENCH!!!');
%                 return;
%             end
%         end
%     end
% %% Function: exit persistent mode
%     function exitPersistent()
%         % Check if we are already not in persistent mode.
%         if ~isInPersistent()
%             return;
%         end
%         % Go back to ramp mode, current will go to previous target
%         fprintf(inst, 'ramp');
%         
%         % Wait until it is in HOLD state
%         ret=query(inst, 'state?');
%         while(strcmp(ret,['2',crlf]) == 0)
%             % Wait until the ramping is finished
%             pause(1);
%             ret=query(inst, 'state?');
%             if strcmp(ret,['7',crlf])
%                 disp('!!!QUENCH!!!');
%                 return;
%             end
%         end
%         
%         % Turn on the persistent switch
%         setPersistent(false);
%         
%         % Go back to ramp mode, to make sure the original target is reached
%         fprintf(inst, 'ramp');
%         
%         % Wait until it is in HOLD state
%         ret=query(inst, 'state?');
%         while(strcmp(ret,['2',crlf]) == 0)
%             % Wait until the ramping is finished
%             pause(1);
%             ret=query(inst, 'state?');
%             if strcmp(ret,['7',crlf])
%                 disp('!!!QUENCH!!!');
%                 return;
%             end
%         end
%     end

%% Main state machine
    switch ic(2) %operation
        case 1
            if ic(3) == 0 %get
                val = getField();
            else %set
%                 % Two cases, depending on if in persistent mode or not
%                 % Query persistent switch mode
%                 if isInPersistent()
%                     % Exit persistent mode
%                     exitPersistent();
%                     % Ramp to field
%                     rampToField(val);
%                     %wait until manget voltage is less than 0.05 V
%                         Vm = str2num(query(inst, 'voltage:magnet?'));
%                         while( abs(Vm) >= 0.05)
%                             pause(1);
%                             Vm = str2num(query(inst, 'voltage:magnet?'));
%                             ret=query(inst, 'state?');
%                             if strcmp(ret,['7',crlf])
%                                 disp('!!!QUENCH!!!');
%                                 return;
%                             end
%                         end
%                     
%                     fprintf('Field stable at %f T\n', val);
%                     % Re-enter persistent mode
%                     enterPersistent()
%                 else
                    rampToField(val);
                    fprintf('Field sweeping to %f T\n', val);
%                 end
            end
%         case 2  % Persistent Switch
%             if ic(3) == 0
%                 val = isInPersistent();
%             else
%                 switch(val)
%                     case 0
%                         exitPersistent();
%                     case 1
%                         enterPersistent();
%                     otherwise
%                         error('Persistent mode can be either enter(1) or exit(0).');
%                 end
%             end
        case 3  % Ramp Rate
            
            if ic(3) == 0 %get ramp rate
                val = getRampRate();   
            elseif ic(3) == 1 % set ramprate
                SetRamprate(val);
            end  
    end
end

