function val = smcLS340(ic, val, rate)
%Channels
%1 - 'A' Temperature A
%2 - 'B' Temperature B
%3 - 'C' Temperature C
%4 - 'SPnt' Set Point temperature
%5 - 'PRng' Heater Power, 0=Off, tiny, small, medium, high, huge

%Driver for LakeShore 340 Temp Controller

global smdata;
inst = smdata.inst(ic(1)).data.inst;
switch ic(2) % Channels 
    case 1 %Read Temperature A
        val = query(smdata.inst(ic(1)).data.inst, 'KRDG?1', '%s\n', '%f');
    case 2 %Read Temperature B
        val = query(smdata.inst(ic(1)).data.inst, 'KRDG?2', '%s\n', '%f');
    case 3 %Read Temperature C
        val = query(smdata.inst(ic(1)).data.inst, 'KRDG?3', '%s\n', '%f');
    case 4 %Temperature Setpoint
        switch ic(3)
            case 0 %Get
                val = query(smdata.inst(ic(1)).data.inst, 'SETP? 1', '%s\n', '%f');
            case 1 %Set
                fprintf(inst, sprintf('SETP 1, %f', val));
            otherwise
                error('LS340 driver: Operation not supported');
        end
    case 5 %ramp
        switch ic(3)
            case 0 %Get
                val = query(smdata.inst(ic(1)).data.inst, 'RANGE?', '%s\n', '%f');
            case 1 %Set
                if val < 0 || val > 5
                    error('LS340 driver: Unsupported Heater Power Setting');
                end
                fprintf(inst, sprintf('RANGE %1.0f,', val));
            otherwise
                error('LS340 driver: Operation not supported');
        end
    case 6 %
        switch ic(3)
            case 0 %Get
                val = query(smdata.inst(ic(1)).data.inst, 'RAMP? 1', '%s\n', '%f, %f');
            case 1 %Set
                if val == 0
                    fprintf(inst, sprintf('RAMP 1, 0, %f,', val));
                elseif val < 0 || val >10 
                    error('LS340 driver: Unsupported Heater Power Setting');
                else
                    fprintf(inst, sprintf('RAMP 1, 1, %f,', val));
                end                
            otherwise
                error('LS340 driver: Operation not supported');
        end
    case 7
        switch ic(3)
            case 0 %Get
                val = query(smdata.inst(ic(1)).data.inst, 'INTYPE? C', '%s\n','%s');
            case 1 %Set
                if val < 0 || val >11 
                    error('LS340 driver: Unsupported Heater Power Setting');
                end
                fprintf(inst, sprintf('INTYPE C, 0, 2, 1, %1.0f, 4', val));                
            otherwise
                error('LS340 driver: Operation not supported');
        end
    otherwise
            error('LS340 driver: Nonvalid Channel specified');
end

end

