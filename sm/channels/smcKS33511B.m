function [val, rate] = smcKS33511B(ico, val, rate)
% driver for Agilent DMMs with support for buffered readout. 
% Some instrument and mode dependent parameters hardcoded!
global smdata;


fprintf(smdata.inst(ico(1)).data.inst, 'abort');


switch ico(2) % channel
    case 1 %Vac
        switch ico(3)
            case 0 %get
                val = query(smdata.inst(ico(1)).data.inst,  'SOUR:VOLT?', '%s\n', '%f');
            case 1 %set
                cmd = sprintf('SOUR:VOLT %g;', val);
                fprintf(smdata.inst(ico(1)).data.inst, cmd);
                pause(0.01);
            otherwise
                error('Operation not supported');
        end
        
    case 2 %Vdc
        switch ico(3)
            case 0 %get
                val = query(smdata.inst(ico(1)).data.inst,  'SOUR:VOLT:OFFS?', '%s\n', '%f');
            case 1 %set
                cmd = sprintf('SOUR:VOLT:OFFS %g;', val);
                fprintf(smdata.inst(ico(1)).data.inst, cmd);
                pause(0.01);
            otherwise
                error('Operation not supported');  
            
        end
        
    case 3 %Frequency
        switch ico(3)
            case 0 %get
                val = query(smdata.inst(ico(1)).data.inst,  'SOUR:FREQ?', '%s\n', '%f');
            case 1 %set
                cmd = sprintf('SOUR:FREQ %g;', val);
                fprintf(smdata.inst(ico(1)).data.inst, cmd);
                pause(0.01);
            otherwise
                error('Operation not supported');  
            
        end
end
