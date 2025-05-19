function val = smcSCM2_LS336_vi(ico, val, rate)
%Driver for the PPMS Temperature and Field control
%channel 1 = Field
%channel 2 = rate
global smdata;
global viGETT;

status = 0;

switch ico(2) % channel
    case 1 % SORB
        switch ico(3) %operation
            case 1 %set
%                 viSETB.SetControlValue('ico',ico(2));
%                 viSETB.SetControlValue('Setpoint [T]',val);
%                 viSETB.Run(0);
            case 0 %get
                val = viGETT.GetControlValue('SORB (K)');          
            otherwise
                error('Operation not supported');
        end
    case 2 % Field Rate
        switch ico(3) %operation
            case 1 %set
%                 viSETB.SetControlValue('ico',ico(2));
%                 viSETB.SetControlValue('Slew Rate',val);
%                 viSETB.Run(0);             
            case 0 %get             
                val = viGETT.GetControlValue('1K POT (K)');     
            otherwise
                error('Operation not supported');
        end
    case 3 % 3HE POT
        switch ico(3) %operation
            case 1 %set
%                 viSETB.SetControlValue('ico',ico(2));
%                 viSETB.SetControlValue('Slew Rate',val);
%                 viSETB.Run(0);             
            case 0 %get             
                val = viGETT.GetControlValue('3HE POT (K)');     
            otherwise
                error('Operation not supported');
        end
    case 4 % PROBE
        switch ico(3) %operation
            case 1 %set
%                 viSETB.SetControlValue('ico',ico(2));
%                 viSETB.SetControlValue('Slew Rate',val);
%                 viSETB.Run(0);             
            case 0 %get             
                val = viGETT.GetControlValue('PROBE (K)');     
            otherwise
                error('Operation not supported');
        end
    otherwise
        error('Channel not supported');
end