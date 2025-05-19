function val = smcOITriton(ic, val, rate)
%Driver for OITriton Controller

% Channels
%  1 - 'PT2Head '  Temperature PT2 Head
%  2 - 'PT2Plate'  Temperature PT2 Plate
%  3 - 'Still   '  Temperature Still Plate
%  4 - 'ColdPlat'  Temperature Cold Plate
%  5 - 'MC_CX   '  Temperature MC Cernox
%  6 - 'PT1Head '  Temperature PT1 Head
%  7 - 'PT1Plate'  Temperature PT1 Plate
%  8 - 'MC_RuO  '  Temperature MC RuO₂
%  9 - 'Magnet  '  Temperature Magnet
% 10 - 'ChnCtrl '  ChnCtrl
% 11 - 'SetPnt  '  Set Point temperature
% 12 - 'Ramp    '  Temperature Ramp Rate: input [output, off/on, rate]
%       Output  0 = sample heater; 1 = warm-up heater
%       off/on  0 = off, 1 = on 
%       rate    unit: K/min
% 13 - 'Range   '  Set output and range input [Output, Sample range]
%       Output = 0,1,2 : sample heater, warm-up heater, still; 
%       Sample range = 0–8:
%                      off, 100nW, 1uW, 10uW, 100uW, 1mW, 10mW, 100mW, 1W
%       Warm-up heater, still range: 0,1 = off, on
% 14 - 'MMCHTR  '  MC Heater
% 15 - 'MStilHTR'  Manual Still Heater 
% 16 - 'LoopMode'  Loop Mode
% 17 - 'T       '  Combined T
% 18 - 'Reserve1'
% 19 - 'Reserve2'
% 20 - 'Reserve3'
% 21 - 'V1      '  V1
% 22 - 'V2      '  V2
% 23 - 'V3      '  V3
% 24 - 'V4      '  V4
% 25 - 'V5      '  V5
% 26 - 'V6      '  V6
% 27 - 'V7      '  V7
% 28 - 'V8      '  V8
% 29 - 'V9      '  V9
% 30 - 'Reserve4'  
% 31 - 'P1      '  P1
% 32 - 'P2      '  P2
% 33 - 'P3      '  P3
% 34 - 'P4      '  P4
% 35 - 'P5      '  P5
% 36 - 'POVC    '  Povc
% 37 - 'Turbo1  '  Turbo
% 38 - 'ForePump'  ForePump
% 39 - 'CompMix '  Mix Compressor

% 

    global smdata;
    inst = smdata.inst(ic(1)).data.inst;
    
    function DTnow=DTnow()
        DTnow = datetime('now', 'Format', 'MM/dd/yyyy HH:mm:ss');
    end
    

    function val=OI_getT(TName)
        fret = query(inst, sprintf('READ:DEV:%s:TEMP:SIG:TEMP',TName), '%s\n', [sprintf('STAT:DEV:%s:TEMP:SIG:TEMP:',TName) '%s\n']);
        val = sscanf(fret, '%f');
        unit = regexp(fret, '[a-zA-Z]+', 'match');
        if isempty(unit)
            error('No unit found.');
        end
    end
    
    function OI_setT(val)
        if val > 2  % for T > 2K, use Channel 5, Cernox
            fret = query(inst, sprintf('SET:DEV:T5:TEMP:LOOP:TSET:%f',val), '%s\n', '%s');
            if contains(fret,'NOT_FOUND')
                if OI_getT('T5') < 1.5
                    fret = query(inst, sprintf('SET:DEV:T8:TEMP:LOOP:TSET:%f',val), '%s\n', '%s\n')
                    fret = query(inst, 'SET:DEV:T8:TEMP:LOOP:RANGE:31.6', '%s\n','%s');
                end
                while OI_getT('T5') < 1.5
                    fprintf('%s: Waiting for T_CX in range. T_CX: %f K, T_RuO: %f K\n',DTnow(),OI_getT('T5'),OI_getT('T8'));
                    pause(10);
                end
                fret = query(inst, 'SET:DEV:T5:TEMP:LOOP:HTR:H1', '%s\n','%s');
                fret = query(inst, sprintf('SET:DEV:T5:TEMP:LOOP:TSET:%f',val), '%s\n', '%s\n');
            end
            if val > 10
                fret = query(inst, 'SET:DEV:T5:TEMP:LOOP:RANGE:100', '%s\n','%s');
            else
                fret = query(inst, 'SET:DEV:T5:TEMP:LOOP:RANGE:31.6', '%s\n','%s');
            end
        elseif val > 1
            fret = query(inst, sprintf('SET:DEV:T8:TEMP:LOOP:TSET:%f',val), '%s\n', '%s\n');
            if contains(fret,'NOT_FOUND')
                fret = query(inst, 'SET:DEV:T8:TEMP:LOOP:HTR:H1', '%s\n','%s\n');
                fret = query(inst, sprintf('SET:DEV:T8:TEMP:LOOP:TSET:%f',val), '%s\n', '%s\n');
            end
            fret = query(inst, 'SET:DEV:T8:TEMP:LOOP:RANGE:31.6', '%s\n','%s');
        else      % for temperature <= 1K, use Channel 8, RuO2
            fret = query(inst, sprintf('SET:DEV:T8:TEMP:LOOP:TSET:%f',val), '%s\n', '%s\n');
            if contains(fret,'NOT_FOUND')
                fret = query(inst, 'SET:DEV:T8:TEMP:LOOP:HTR:H1', '%s\n','%s\n');
                fret = query(inst, sprintf('SET:DEV:T8:TEMP:LOOP:TSET:%f',val), '%s\n', '%s\n');
            end
            fret = query(inst, 'SET:DEV:T8:TEMP:LOOP:RANGE:10', '%s\n','%s');
        end
    end
    
    switch ic(2) % Channels 
    
        case {1,2,3,4,5,6,7,8,9}
            
            if ic(2) ==9
                TIndex = 13;    % 9→13: Magnet
            else
                TIndex = ic(2);  % 1→1, 2→2, ..., 8→8
            end
            TName = sprintf('T%d', TIndex);
            val = OI_getT(TName);    
            
        
        case 10 % 'ChnCtrl ' - Control Channel #
            switch ic(3)    
                case 0 %Get
                    ret = query(inst, strcat('READ:DEV:T1:TEMP:LOOP:CHAN'), '%s\n','%s')
                    %NB the <TEMP UID> in the above command is required for compatibility with other Oxford Instruments hardware but has no function in this instance
                case 1 %Set
                    ret = query(inst, strcat('SET:DEV:T',string(val),':TEMP:LOOP:HTR:H1'), '%s\n','%s')
                    if strcmp(ret,':VALID')
                        fprintf('');
                    else
                    end
                otherwise
                    error('OI_LS372 PID Control Channel Setup failed.')
            end
        
        case 11 % 11 - 'SetPnt  '  Set Point temperature
            switch ic(3)
                case 0 %Get
                    val = query(inst, strcat('READ:DEV:T8:TEMP:LOOP:TSET'), '%s\n', 'STAT:DEV:T8:TEMP:LOOP:TSET:%fK\n');
                    if contains(ret,':NOT_FOUND')
                        ret = query(inst, strcat('READ:DEV:T5:TEMP:LOOP:TSET'), '%s\n', 'STAT:DEV:T8:TEMP:LOOP:TSET:%fK\n');
                    end
                case 1 %Set
                    setT(val);
            otherwise
                    error('OI_LS372 driver: Operation not supported');
            end
    
    % 12 - 'Ramp    '  Temperature Ramp Rate: input [output, off/on, rate]
    %       Output  0 = sample heater; 1 = warm-up heater
    %       off/on  0 = off, 1 = on 
    %       rate    unit: K/min
          
    
        case 12 %Ramp
            switch ic(3)
                case 0 %Get On/Off Status of Output ? and its Rate
                    ret = query(inst, 'READ:DEV:T8:TEMP:LOOP:RAMP', '%s\n', '%s');
                    if contains(ret,'NOT_FOUND')
                        ret = query(inst, 'READ:DEV:T5:TEMP:LOOP:RAMP', '%s\n', '%s');
                    end
                    if contains(ret,'ENAB:OFF')
                        val = 0
                    end
                    val = val(2); % return the rate
                case 1 %Set the output status on/off and rate
                    if val == 0
                        fprintf(inst, sprintf('RAMP 0, 0, %f,', val));
                    else
                        fprintf(inst, sprintf('RAMP 0, 1, %f,', val));
                    end                
                otherwise
                    error('OI_LS372 driver: Operation not supported');
            end
        case 13 %Output and Range; unit: mA
            switch ic(3)
                case 0 %Get Output
                    val = query(inst, 'READ:DEV:T8:TEMP:LOOP:RANGE', '%s\n', 'STAT:DEV:T8:TEMP:LOOP:RANGE:%fmA\n');
                case 1 %Set 
                    if val < 0 || val > 100
                        error('OI_LS372 driver: Unsupported Heater Power Setting');
                    end
                    ret = query(inst, sprintf('SET:DEV:T8:TEMP:LOOP:RANGE:%f', val),'%s\n','%s\n');
                otherwise
                    error('OI_LS372 driver: Operation not supported');
            end        
        case 14 % manual Mixing Chamber output 
            switch ic(3)
                case 0 %Get Output
                    val = query(inst, 'READ:DEV:H1:HTR:SIG:POWR', '%s\n', 'STAT:DEV:H1:HTR:SIG:POWR:%fuW\n');               
                case 1 %Set 
                    ret=query(inst, sprintf('SET:DEV:H1:HTR:SIG:POWR:%f', val),'%s\n', '%s'); %unit: uW
                    if contains(ret,'INVALID')
                       error('Manual heater output not supported');
                    end
                otherwise
                    error('OI_LS372 driver: Operation not supported');
            end
        case 15 % Manual Still heater
            switch ic(3)
                case 0 %Get Output
                    val = query(inst, 'READ:DEV:H2:HTR:SIG:POWR', '%s\n', 'STAT:DEV:H2:HTR:SIG:POWR:%fuW\n');               
                case 1 %Set 
                    ret=query(inst, sprintf('SET:DEV:H2:HTR:SIG:POWR:%f', val),'%s\n', '%s'); %unit: uW
                    if contains(ret,'INVALID')
                       error('Manual heater output not supported');
                    end
                otherwise
                    error('OI_LS372 driver: Operation not supported');
            end
        case 16 % Loop Mode  0:Manual ; 1: Closed Loop PID
             switch ic(3)
                case 0 %Get Output
                    ret = query(inst, 'READ:DEV:T8:TEMP:LOOP:MODE','%s\n','%s');
                    if contains(ret,'NOT_FOUND')
                        ret = query(inst, 'READ:DEV:T5:TEMP:LOOP:MODE','%s\n','%s');
                    end
                    if contains(ret,'ON')
                        val = 1;
                    else
                        val = 0;
                    end
                case 1 %Set 
                    switch val
                        case 0
                            ret = query(inst, 'SET:DEV:T8:TEMP:LOOP:MODE:OFF','%s\n','%s');
                            if contains(ret,'NOT_FOUND')
                                ret = query(inst, 'SET:DEV:T5:TEMP:LOOP:MODE:OFF','%s\n','%s');
                            end
                        case 1
                            ret = query(inst, 'SET:DEV:T8:TEMP:LOOP:MODE:ON','%s\n','%s');
                            if contains(ret,'NOT_FOUND')
                                ret = query(inst, 'SET:DEV:T5:TEMP:LOOP:MODE:ON','%s\n','%s');
                            end
                    end
                otherwise
                    error('OI_LS372 driver: Operation not supported');
            end
        
        
        case 17 % Combined T
            switch ic(3)
                case 0 % Get T
                    T_CX = OI_getT('T5');
                    T_RuO = OI_getT('T8');
                    if T_RuO > 2.0
                        val = T_CX;
                    else
                        val = T_RuO;
                    end
                case 1 % Set T
                    OI_setT(val);
                otherwise
                    error('OI_LS372 driver: Operation not supported');
    
            end
    
        case {21, 22, 23, 24, 25, 26, 27, 28, 29}  % V1 to V9
            valveIndex = ic(2) - 20;  % 21→1, 22→2, ..., 29→9
            valveName = sprintf('V%d', valveIndex);
            switch ic(3)
                case 0  % Get
                    ret = query(inst, sprintf('READ:DEV:%s:VALV:SIG:STATE', valveName), '%s\n')
                    if contains(ret, 'OPEN')
                        val = 1;
                    else
                        val = 0;
                    end
                case 1  % Set
                    switch val
                        case 0
                            ret = query(inst, sprintf('SET:DEV:%s:VALV:SIG:STATE:CLOSE', valveName), '%s\n')
                        case 1
                            ret = query(inst, sprintf('SET:DEV:%s:VALV:SIG:STATE:OPEN', valveName), '%s\n')
                        otherwise
                            error('Invalid value for valve control');
                    end
                    if contains(ret, 'INVALID')
                        error('%s: Valve Driver: Operation not supported\n', DTnow());
                    else
                        state = {'OFF', 'ON'};
                        fprintf('%s: Turn %s %s successfully.\n', DTnow(), state{val+1}, valveName);
                    end
                otherwise
                    error('%s: OI_Valve Driver: Operation not supported', DTnow());
            end
    
        case {31, 32, 33, 34, 35, 36}  % P1 to P6 (Pressure sensors)
            pIndex = ic(2) - 30;  % 31→1, ..., 36→6
            pName = sprintf('P%d', pIndex);
            switch ic(3)
                case 0  % Get pressure value
                    ret = query(inst, sprintf('READ:DEV:%s:PRES:SIG:PRES', pName), '%s\n', [sprintf('STAT:DEV:%s:PRES:SIG:PRES:',pName) '%s\n']);
                    num = sscanf(ret, '%f');
                    unit = regexp(ret, '[a-zA-Z]+', 'match');
                    if isempty(unit)
                        error('No unit found.');
                    end
                    switch unit{1}
                        case 'B'
                            val = num;  % in bar
                        case 'mB'
                            val = num * 1e-3;  % convert to bar
                        otherwise
                            error('Unknown unit: %s', unit{1});
                    end
            otherwise
                error('OI_Pressure Driver: Operation not supported');
            end
    
        case 37 %turbo1
            switch ic(3)
                case 0 % Get
                    ret=query(inst, 'READ:DEV:TURB1:PUMP:SIG:STATE', '%s\n');
                    if contains(ret,'ON')
                        val=1;
                    else
                        val=0;
                    end
                case 1 % Set
                    switch val
                        case 0
                            ret=query(inst, 'SET:DEV:TURB1:PUMP:SIG:STATE:OFF', '%s\n');
                        case 1
                            ret=query(inst, 'SET:DEV:TURB1:PUMP:SIG:STATE:ON', '%s\n');
                    end
                    if contains(ret,'VALID')
                        state = {'OFF', 'ON'};
                        fprintf('%s: Turn %s Turbo1 successfully.\n', DTnow(), state{val+1});
                    else
                        error('%s: Turbo1 Driver: Operation not supported\n',DTnow());
                    end
                otherwise
                    error('OI_Turbo1 Driver: Operation not supported');
            end
    
        case 38 %FP
            switch ic(3)
                case 0 % Get
                    ret=query(inst, 'READ:DEV:FP:PUMP:SIG:STATE', '%s\n');
                    if contains(ret,'ON')
                        val=1;
                    else
                        val=0;
                    end
                case 1 % Set
                    switch val
                        case 0
                            ret=query(inst, 'SET:DEV:FP:PUMP:SIG:STATE:OFF', '%s\n');
                        case 1
                            ret=query(inst, 'SET:DEV:FP:PUMP:SIG:STATE:ON', '%s\n');
                    end
                    if contains(ret,'VALID')
                        state = {'OFF', 'ON'};
                        fprintf('%s: Turn %s Forepump successfully.\n', DTnow(), state{val+1});
                    else
                        error('%s: OI_ForePump Driver: Operation not supported\n',DTnow());
                    end
                otherwise
                    error('OI_ForePump Driver: Operation not supported');
            end
    
        case 39 %Mix Compressor
            switch ic(3)
                case 0 % Get
                    ret=query(inst, 'READ:DEV:COMP:PUMP:SIG:STATE', '%s\n');
                    if contains(ret,'ON')
                        val=1;
                    else
                        val=0;
                    end
                case 1 % Set
                    switch val
                        case 0
                            ret=query(inst, 'SET:DEV:COMP:PUMP:SIG:STATE:OFF', '%s\n');
                        case 1
                            ret=query(inst, 'SET:DEV:COMP:PUMP:SIG:STATE:ON', '%s\n');
                    end
                    if contains(ret,'VALID')
                        state = {'OFF', 'ON'};
                        fprintf('%s: Turn %s Mix Compressor successfully.\n', DTnow(), state{val+1});
                    else
                        error('%s: Mix Compressor Driver: Operation not supported\n',DTnow());
                    end
                otherwise
                    error('%s: OI_He-3_Compressor Driver: Operation not supported', DTnow());
            end
    
            
        otherwise
                error('OI Triton driver: Nonvalid Channel specified');


    end

end

