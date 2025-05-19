function val = smctemplate(ic, val, rate)
%Device driver for Agilent E5071C Network Analyzer
%Written by leozhou, 8/10/2012

global smdata;

inst = smdata.inst(ic(1)).data.inst;
switch ic(2) % channel
    case 1 % source1 power
        switch ic(3) % operation type
            case 0 % get
                val = query(inst, ':SOUR1:POW?', '%s\n', '%f');
            case 1 % set
                fprintf(inst, ':SOUR1:POW %f', val);
            otherwise
                error('E5071C driver: Operation not supported');
        end
    case 2 % source power start value
        switch ic(3)
            case 0
                val = query(inst, ':SOUR1:POW:STAR?', '%s\n', '%f');
            case 1
                fprintf(inst, sprintf(':SENS:POW:STAR %f', val));
            otherwise
                error('E5071C driver: Operation not supported');
        end
    case 3 % source power stop value
        switch ic(3)
            case 0
                val = query(inst, ':SOUR1:POW:STOP?', '%s\n', '%f');
            case 1
                fprintf(inst, sprintf(':SOUR1:POW:STOP %f', val));
            otherwise
                error('E5071C driver: Operation not supported');
        end
    case 4 % sensor frequency
        switch ic(3)
            case 0
                val = query(inst, ':SENS1:FREQ?', '%s\n', '%f');
            case 1
                fprintf(inst, sprintf(':SENS1:FREQ %f', val));
            otherwise
                error('E5071C driver: Operation not supported');
        end
    case 5 % sweep freq start value
        switch ic(3)
            case 0
                val = query(inst, ':SENS1:FREQ:STAR?', '%s\n', '%f');
            case 1
                fprintf(inst, sprintf(':SENS1:FREQ:STAR %f', val));
            otherwise
                error('E5071C driver: Operation not supported');
        end
    case 6 % sweep freq stop value
        switch ic(3)
            case 0
                val = query(inst, ':SENS1:FREQ:STOP?', '%s\n', '%f');
            case 1
                fprintf(inst, sprintf(':SENS1:FREQ:STOP %f', val));
            otherwise
                error('E5071C driver: Operation not supported');
        end
    otherwise
            error('LS335 driver: Nonvalid Channel specified');
end

end
