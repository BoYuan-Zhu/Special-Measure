function val = smcK2450(ic, val, rate)
%Channels
%1 - 'V' voltage
%2 - 'I' Current
%3 - 'Vcompl' voltage compliance
%4 - 'Icompl' current compliance

    %Driver for Keithley 2450
    %Last update: Pengjie Wang

    global smdata; 
    %strchan = smdata.inst(ic(1)).channels(ic(2),:);
    switch ic(2) % Channels 
        case 1 %V
            switch ic(3); %Operation: 0 for read, 1 for write

                case 0 %read
                    % Stop continuous updating
%                     KO = query(smdata.inst(ic(1)).data.inst, 'count 2;:READ? "defbuffer1", SOUR, READ', '%s\n', '%g,%g');
                    KO = query(smdata.inst(ic(1)).data.inst, ':abort;:sour:volt?', '%s\n', '%g');
                    val = KO(1);
                    % Resume continuous updating
                    fprintf(smdata.inst(ic(1)).data.inst, 'count 1;:trig:cont REST');
                    pause(0.01);
                case 1 %write operation
%                     cmd = sprintf(':abort;:sour:volt %g;', val);
                    cmd = sprintf(':sour:volt %g;:trig:cont REST', val);
                    fprintf(smdata.inst(ic(1)).data.inst, cmd);
                    pause(0.05);
                otherwise
                    error('K2400 driver: Operation not supported');
            end
%             fprintf(smdata.inst(ic(1)).data.inst, 'count 1;:trig:cont REST');
        case 2 %I
            switch ic(3); %Operation: 0 for read, 1 for write

                case 0 %read measured current
                    % Stop continuous updating
                    KO = query(smdata.inst(ic(1)).data.inst, 'count 2;:READ? "defbuffer1", SOUR, READ', '%s\n', '%g,%g');
                    val = KO(2);
                    % Resume continuous updating
                    fprintf(smdata.inst(ic(1)).data.inst, 'count 1;:trig:cont REST');
                    pause(0.01);
                case 1 %write operation;  
                    cmd = sprintf(':sour:curr %g;:trig:cont REST', val);
                    fprintf(smdata.inst(ic(1)).data.inst, cmd);
                    pause(0.05);
%                     fprintf(smdata.inst(ic(1)).data.inst, 'count 1;:trig:cont REST');

                otherwise
                    error('K2450 driver: Operation not supported');
            end
        case 3 %Vcompl
            switch ic(3); %Operation: 0 for read, 1 for write

                case 0 %just read voltage for now
                    val = query(smdata.inst(ic(1)).data.inst, ':sour:curr:Vlim?','%s\n','%g');
                    fprintf(smdata.inst(ic(1)).data.inst, 'count 1;:trig:cont REST');
                    pause(0.007);
                case 1 %write operation;  
                    cmd = sprintf(':sour:curr:vlim %g;:trig:cont REST', val);
                    fprintf(smdata.inst(ic(1)).data.inst, cmd);


                otherwise
                    error('K2450 driver: Operation not supported');
            end
        case 4 %Icompl
            switch ic(3); %Operation: 0 for read, 1 for write

                case 0 %just read voltage for now
                    val = query(smdata.inst(ic(1)).data.inst, ':sour:volt:Ilim?','%s\n','%g');
                    fprintf(smdata.inst(ic(1)).data.inst, 'count 1;:trig:cont REST');

                case 1 %write operation;  
                    cmd = sprintf(':sour:volt:Ilim %g;:trig:cont REST', val);
                    fprintf(smdata.inst(ic(1)).data.inst, cmd);

                otherwise
                    error('K2450 driver: Operation not supported');
            end
        otherwise
            error('K2450 driver: Nonvalid Channel specified');
    end

end

