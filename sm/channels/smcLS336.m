function val = smcLS336(ic, val, rate)
%Channels
%1 - 'A' Temperature A
%2 - 'B' Temperature B
%3 - 'C' Temperature C
%4 - 'D' Temperature D
%5 - '1' Set Point temperature of output 1
%6 - '2' Set Point temperature of output 2
%7 - 'PWR1' Heater 1 Power, 0=Off, 1=Low, 2=Medium, 3=High
%8 - 'PWR2' Heater 2 Power, 0=Off, 1=Low, 2=Medium, 3=High
% Pengjie Wang 08/02/2021

%Driver for LakeShore 336 Temp Controller

global smdata;
inst = smdata.inst(ic(1)).data.inst;
switch ic(2) % Channels 
    case 1 %Read Temperature A
        switch ic(3)
            case 0 %Get
                val = query(smdata.inst(ic(1)).data.inst, 'KRDG? A', '%s\n', '%f');
            case 1 %Set
                output = 2 - mod(ic(2),2);
                fprintf(inst, sprintf('SETP %1.0f,%f', output, val));
            otherwise
                error('LS336 driver: Operation not supported');
        end
    case 2 %Read Temperature B
        switch ic(3)
            case 0 %Get
                val = query(smdata.inst(ic(1)).data.inst, 'KRDG? B', '%s\n', '%f');
            case 1 %Set
                output = 2 - mod(ic(2),2);
                fprintf(inst, sprintf('SETP %1.0f,%f', output, val));
            otherwise
                error('LS336 driver: Operation not supported');
        end
    case 3 %Read Temperature C
        val = query(smdata.inst(ic(1)).data.inst, 'KRDG? C', '%s\n', '%f');
    case 4 %Read Temperature D
        val = query(smdata.inst(ic(1)).data.inst, 'KRDG? D', '%s\n', '%f');
    case {5, 6} %Setpoint 1 temperature
        output = 2 - mod(ic(2),2);
        switch ic(3)
            case 0 %Get
                val = query(inst, sprintf('SETP? %1.0f', output), '%s\n', '%f');
            case 1 %Set
                fprintf(inst, sprintf('SETP %1.0f,%f', output, val));
            otherwise
                error('LS336 driver: Operation not supported');
        end
    case {7, 8}
        output = 2 - mod(ic(2),2);
        switch ic(3)
            case 0 %Get
                val = query(inst,sprintf('RANGE? %1.0f', output), '%s\n', '%f');
            case 1 %Set
                if val < 0 || val > 3
                    error('LS336 driver: Unsupported Heater Power Setting');
                end
                fprintf(inst, sprintf('RANGE %1.0f,%1.0f,', output, val));
            otherwise
                error('LS336 driver: Operation not supported');
        end
    otherwise
            error('LS336 driver: Nonvalid Channel specified');
end

end