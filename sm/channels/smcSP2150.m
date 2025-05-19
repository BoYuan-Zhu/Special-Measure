function val = smcSP2150(ic, val, rate)

global smdata;
fprintf(smdata.inst(ic(1)).data.inst, 'NO-ECHO');
switch ic(2) % channel
    case 1
        switch ic(3); %switch read (0) or write (1)

            case 0 %read
                while smdata.inst(ic(1)).data.inst.bytesavailable > 0
                    fscanf(smdata.inst(ic(1)).data.inst);
                end
                val=query(smdata.inst(ic(1)).data.inst, '?NM');
                val = val(1:end-5);

            case 1 %write 
                cmd = ' GOTO';
                fprintf(smdata.inst(ic(1)).data.inst, sprintf('%s%0.0f', val, cmd));

            otherwise
                error('Monochromator driver: Operation not supported');
        end
end