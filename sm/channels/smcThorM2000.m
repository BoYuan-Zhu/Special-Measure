function val = smcThorM2000(ic, val, rate)
%Channels
%ic(1) = instrument index,  ic(2) = channel index, ic(3) = read/write (0/1)
%1 - 'freq' frequency
%2 - 'phase' phase
%3 - 'enable' enable

global smdata;

switch ic(2) % switch channels
    
    case 1 %freq
        
        switch ic(3); %switch read (0) or write (1)

            case 0 %read
                while smdata.inst(ic(1)).data.inst.bytesavailable > 2
                    fscanf(smdata.inst(ic(1)).data.inst);
                end
                query(smdata.inst(ic(1)).data.inst, 'freq?');
                val = fscanf(smdata.inst(ic(1)).data.inst,'%f');

            case 1 %write 
                cmd = 'freq=';
                query(smdata.inst(ic(1)).data.inst, sprintf('%s%0.0f', cmd, val));

            otherwise
                error('Optical Chopper driver: Operation not supported');
        end
        
    case 2 %phase
        
        switch ic(3); %switch read (0) or write (1)

            case 0 %read
                while smdata.inst(ic(1)).data.inst.bytesavailable > 2
                    fscanf(smdata.inst(ic(1)).data.inst);
                end
                query(smdata.inst(ic(1)).data.inst, 'phase?');
                val = fscanf(smdata.inst(ic(1)).data.inst,'%f');

            case 1 %write 
                cmd = 'phase=';
                query(smdata.inst(ic(1)).data.inst, sprintf('%s %0.0f', cmd, val));

            otherwise
                error('Optical Chopper driver: Operation not supported');
        end
        
    case 3 %enable
        
        switch ic(3); %switch read (0) or write (1)

            case 0 %read
                while smdata.inst(ic(1)).data.inst.bytesavailable > 2
                    fscanf(smdata.inst(ic(1)).data.inst);
                end
                query(smdata.inst(ic(1)).data.inst, 'enable?');
                val = fscanf(smdata.inst(ic(1)).data.inst,'%f');

            case 1 %write 
                cmd = 'enable=';
                query(smdata.inst(ic(1)).data.inst, sprintf('%s %0.0f', cmd, val));

            otherwise
                error('Optical Chopper driver: Operation not supported');
        end
                    
    otherwise
        error('Optical Chopper driver: Nonvalid Channel specified');
end

end

