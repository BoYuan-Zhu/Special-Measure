function val = smcLS325(ic, val, rate)
%Channels
%1 - 'A' Temperature A
%2 - 'B' Temperature B
%3 - '1' Set Point temperature of output 1
%4 - '2' Set Point temperature of output 2
%5 - 'PWR1' Heater 1 Power, 0=Off, 1=Low, 2=Medium, 3=High
%6 - 'PWR2' Heater 2 Power, 0=Off, 1=Low, 2=Medium, 3=High
%leozhou 8/10/2012

%Driver for LakeShore 325 Temp Controller

global smdata;
inst = smdata.inst(ic(1)).data.inst;
switch ic(2) % Channels 
    case 1 %Read Temperature A
        val = query(smdata.inst(ic(1)).data.inst, 'KRDG? A', '%s\n', '%f');
    case 2 %Read Temperature B
        val = query(smdata.inst(ic(1)).data.inst, 'KRDG? B', '%s\n', '%f');
    case {3, 4} %Setpoint 1 temperature
        output = 2 - mod(ic(2),2);
        switch ic(3)
            case 0 %Get
                val = query(inst, sprintf('SETP? %1.0f', output), '%s\n', '%f');
            case 1 %Set
                fprintf(inst, sprintf('SETP %1.0f,%f', output, val));
            otherwise
                error('LS335 driver: Operation not supported');
        end
    case {5, 6}
        output = 2 - mod(ic(2),2);
        switch ic(3)
            case 0 %Get
                val = query(inst,sprintf('RANGE? %1.0f', output), '%s\n', '%f');
            case 1 %Set
                if val < 0 || val > 3
                    error('LS335 driver: Unsupported Heater Power Setting');
                end
                fprintf(inst, sprintf('RANGE %1.0f,%1.0f,', output, val));
            otherwise
                error('LS335 driver: Operation not supported');
        end
    otherwise
            error('LS335 driver: Nonvalid Channel specified');
end

end