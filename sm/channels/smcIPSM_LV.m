function val = smcSCM1_MAG(ico, val, rate)
%channel 1 = Field
%channel 2 = rate
global smdata;
global viSETB;
global viGETB;

status = 0;

switch ico(2) % channel
    case 1 % Field B
        switch ico(3) %operation
            case 1 %set
                viSETB.SetControlValue('ico',ico(2));
                viSETB.SetControlValue('Setpoint [T]',val);
                viSETB.Run(0);
            case 0 %get
                val = viGETB.GetControlValue('Field [T]');          
            otherwise
                error('Operation not supported');
        end
    case 2 % Field Rate
        switch ico(3) %operation
            case 1 %set
                viSETB.SetControlValue('ico',ico(2));
                viSETB.SetControlValue('Slew Rate',val);
                viSETB.Run(0);             
            case 0 %get             
                val = viGETB.GetControlValue('Slew Rate');     
            otherwise
                error('Operation not supported');
        end
    otherwise
        error('Channel not supported');
end