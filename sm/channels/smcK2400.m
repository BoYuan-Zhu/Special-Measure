function val = smcK2400(ic, val, rate)
%Channels
%1 - 'V' voltage
%2 - 'I' Current
%3 - 'Vcompl' voltage compliance
%4 - 'Icompl' current compliance
%JDSY 12/6/2011 - added ramp channel and changed channel checking to be
%based off numbers
%Yuan 10/3/2015 - removed ramp channel (it's not there!). added compliance
%channel, and realized continuous reading from front panel when idle.
    %Driver for Keithley 2400
    %Last update: Hadar 10-13-2010
    %Error Fixed: LeoZ 8-8-2012

    global smdata;
    %strchan = smdata.inst(ic(1)).channels(ic(2),:);
    switch ic(2) % Channels 
        case 1 %V
            switch ic(3); %Operation: 0 for read, 1 for write

                case 0 %read
                    % Stop continuous updating
                    KO = query(smdata.inst(ic(1)).data.inst, ':abort;:arm:count 1;:read?', '%s\n', '%g,%g,%g,%g,%g');
                    val = KO(1);
                    % Resume continuous updating
                    fprintf(smdata.inst(ic(1)).data.inst, ':arm:count infinite;:initiate');

                case 1 %write operation
                    cmd = sprintf(':abort;:source:volt %g;:initiate', val);
                    fprintf(smdata.inst(ic(1)).data.inst, cmd);
                    pause(0.05);

                otherwise
                    error('K2400 driver: Operation not supported');
            end
        case 2 %I
            switch ic(3); %Operation: 0 for read, 1 for write

                case 0 %read measured current
                    % Stop continuous updating
                    KO = query(smdata.inst(ic(1)).data.inst, ':abort;:arm:count 1;:read?', '%s\n', '%g,%g,%g,%g,%g');
                    val = KO(2);
                    % Resume continuous updating
                    fprintf(smdata.inst(ic(1)).data.inst, ':arm:count infinite;:initiate');

                case 1 %write operation;  
                    cmd = sprintf(':abort;:source:curr %g;:initiate', val);
                    fprintf(smdata.inst(ic(1)).data.inst, cmd);
                    pause(0.05);

                otherwise
                    error('K2400 driver: Operation not supported');
            end
        case 3 %Vcompl
            switch ic(3); %Operation: 0 for read, 1 for write

                case 0 %just read voltage for now
                    val = query(smdata.inst(ic(1)).data.inst, ':abort;:sense:voltage:protection?','%s\n','%g');
                    fprintf(smdata.inst(ic(1)).data.inst, ':initiate');

                case 1 %write operation;  
                    cmd = sprintf(':abort;:sense:voltage:protection %g;:initiate', val);
                    fprintf(smdata.inst(ic(1)).data.inst, cmd);

                otherwise
                    error('K2400 driver: Operation not supported');
            end
        case 4 %Icompl
            switch ic(3); %Operation: 0 for read, 1 for write

                case 0 %just read voltage for now
                    val = query(smdata.inst(ic(1)).data.inst, ':abort;:sense:current:protection?','%s\n','%g');
                    fprintf(smdata.inst(ic(1)).data.inst, ':initiate');

                case 1 %write operation;  
                    cmd = sprintf(':abort;:sense:current:protection %g;:initiate', val);
                    fprintf(smdata.inst(ic(1)).data.inst, cmd);

                otherwise
                    error('K2400 driver: Operation not supported');
            end
        otherwise
            error('K2400 driver: Nonvalid Channel specified');
    end

end

