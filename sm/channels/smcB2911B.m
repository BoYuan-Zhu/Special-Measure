function val = smcB2911B(ic, val, rate)
%Channels
%1 - 'V1' source voltage CH1
%2 - 'I1' source current CH1
%3 - 'Vcompl1' voltage compliance CH1
%4 - 'Icompl1' current compliance CH1

    global smdata;
    ch = 1; 
    fprintf(smdata.inst(ic(1)).data.inst, ':abort:acq (@%d)', ch);
    fprintf(smdata.inst(ic(1)).data.inst, ':arm%d:acq:count 1', ch);
    switch ic(2)% Channels 
        case 1 %V
            switch ic(3); %Operation: 0 for read, 1 for write

                case 0 %read
                    KO = query(smdata.inst(ic(1)).data.inst, sprintf(':measure? (@%d)',ch), '%s\n', '%g,%g,%g,%g,%g,%g');
                    val = KO(1);

                case 1 %write operation
                    cmd = sprintf(':source%d:volt %g', ch, val);
                    fprintf(smdata.inst(ic(1)).data.inst, cmd);

                otherwise
                    error('B2911B driver: Operation not supported');
            end
        case 2 %I
            switch ic(3); %Operation: 0 for read, 1 for write

                case 0 %read measured current
                    KO = query(smdata.inst(ic(1)).data.inst, sprintf(':measure? (@%d)',ch), '%s\n', '%g,%g,%g,%g,%g,%g');
                    val = KO(2);

                case 1 %write operation;  
                    cmd = sprintf(':source%d:curr %g', ch, val);
                    fprintf(smdata.inst(ic(1)).data.inst, cmd);

                otherwise
                    error('B2911B driver: Operation not supported');
            end
        case 3 %Vcompl
            switch ic(3); %Operation: 0 for read, 1 for write

                case 0 %just read voltage for now
                    val = query(smdata.inst(ic(1)).data.inst, sprintf(':sense%d:voltage:protection?',ch),'%s\n','%g');

                case 1 %write operation;  
                    cmd = sprintf(':sense%d:voltage:protection %g;', ch, val);
                    fprintf(smdata.inst(ic(1)).data.inst, cmd);

                otherwise
                    error('B2911B driver: Operation not supported');
            end
        case 4 %Icompl
            switch ic(3); %Operation: 0 for read, 1 for write

                case 0 %just read voltage for now
                    val = query(smdata.inst(ic(1)).data.inst, sprintf(':sense%d:current:protection?',ch),'%s\n','%g');

                case 1 %write operation;  
                    cmd = sprintf(':sense%d:current:protection %g', ch, val);
                    fprintf(smdata.inst(ic(1)).data.inst, cmd);

                otherwise
                    error('B2911B driver: Operation not supported');
            end
        otherwise
            error('B2911B driver: Nonvalid Channel specified');
    end
    % Put it back to auto triggering
    fprintf(smdata.inst(ic(1)).data.inst, ':arm%d:acq:count infinity', ch);
    fprintf(smdata.inst(ic(1)).data.inst, ':init:acq (@%d)', ch);
end

