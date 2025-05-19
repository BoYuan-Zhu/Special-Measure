function val = smcCryoMag(ic, val, rate)

%Device driver for magnet controller
%Written by Hadar, May 2010
%rate is always 0.02, so parameter ignored
global smdata;


    switch ic(3) %operation
        case(0)%read field
            [Bout] = query(smdata.inst(ic(1)).data.inst,'IOUT?');
            val = str2num(Bout(1:7));
        case(1) %set field by ramp
            
            if abs(val) > 9
                error('Field must be < 9T');
            else
                %get existing field value
                [Bout] = query(smdata.inst(ic(1)).data.inst,'IOUT?');
                Bcurr = str2num(Bout(1:7));
                if Bcurr < val %have to ramp up
                    cmd = 'ULIM ';
                    fprintf(smdata.inst(ic(1)).data.inst, sprintf('%s %f', cmd, val));
                    fprintf(smdata.inst(ic(1)).data.inst, 'SWEEP UP');
                else %ramp down
                    cmd = 'LLIM ';
                    fprintf(smdata.inst(ic(1)).data.inst, sprintf('%s %f', cmd, val));
                    fprintf(smdata.inst(ic(1)).data.inst, 'SWEEP DOWN');
                end
            end
    end
end

