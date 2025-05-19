function val = smcFianiumSC1060(ic, val, rate)
%Channels
%ic(1) = instrument index,  ic(2) = channel index, ic(3) = read/write (0/1)
%1 - 'Q' DAC bit
%2 - 'P700' Power through 700nm filter

global smdata;

switch ic(2) % switch channels
    
    case 1 %Q
        
        switch ic(3); %switch read (0) or write (1)

            case 0 %read
                while smdata.inst(ic(1)).data.inst.bytesavailable > 0
                    fscanf(smdata.inst(ic(1)).data.inst);
                end
                query(smdata.inst(ic(1)).data.inst, 'Q?');
                KO = fscanf(smdata.inst(ic(1)).data.inst);
                fscanf(smdata.inst(ic(1)).data.inst);
                val = str2double(KO(strfind(KO,'=')+1:end));

            case 1 %write 
                cmd = 'Q=';
                query(smdata.inst(ic(1)).data.inst, sprintf('%s %f', cmd, val));

            otherwise
                error('Super Continuum driver: Operation not supported');
        end
        
    case 2 %P700
        
        Pcal = load('sm_SCPowerCal_700nm.mat');
        Pcal = Pcal.Pcal;
        Pcal = Pcal/2.25;%HC 7/23/2013 for new calibration...
        
        switch ic(3); %switch read (0) or write (1)
            
            case 0 %read
                while smdata.inst(ic(1)).data.inst.bytesavailable > 0
                    fscanf(smdata.inst(ic(1)).data.inst);
                end
                query(smdata.inst(ic(1)).data.inst, 'Q?');
                KO = fscanf(smdata.inst(ic(1)).data.inst);
                fscanf(smdata.inst(ic(1)).data.inst);
                val = str2double(KO(strfind(KO,'=')+1:end));
                val = Pcal(val+1);

            case 1 %write
                cmd = 'Q=';
                [~,q]=min(abs(Pcal-val));
                query(smdata.inst(ic(1)).data.inst, sprintf('%s %f', cmd, q));

            otherwise
                error('Super Continuum driver: Operation not supported');
        end
                    
    otherwise
        error('Super Continuum driver: Nonvalid Channel specified');
end

end

