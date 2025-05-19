function val = smcCryoLtd(ic, val, rate)
%Test driver for Cryogenic Ltd Superconducting Magnet Controller
%6/28/2010, Haofei Wei
%9/2/2010, Hadar
%11/8/2011 JDSY got rid of unfulfilled fprintfs
%2/27/2018 Yuan conform to normal SM driver format
% 1: I (output current)
% 2: M (max current)
global smdata;

switch ic(2) % channel
    case 1 % I (output current)
        switch ic(3) %Operation. 0 for read, 1 for write
            case 0
                %Sometimes get matchin error because of residual data.
                %clear buffer in this case

                [output count error] = query(smdata.inst(ic(1)).data.inst,'Get Output','%s\n','%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%f%c%c%c%c%c%c%c%c%c%f%c%c%c%c%c%c');
                if ~isempty(error)
                    fprintf('Error encountered, flushing Cryo Controller Buffer');
                    while smdata.inst(ic(1)).data.inst.BytesAvailable > 0
                        fscanf(smdata.inst(ic(1)).data.inst);
                    end
                    [output count error] = query(smdata.inst(ic(1)).data.inst,'Get Output','%s\n','%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%f%c%c%c%c%c%c%c%c%c%f%c%c%c%c%c%c');
                end
                val = output(18);

            case 1
                %Will change the MID value and ramp to it. Ramping to MAX is
                %forbidden.

                %Gets MAX current and compares it to the mid setting. Will
                %throw error if MID is greater than MAX.
                % THIS IS OLD ****************
    %             output = query(smdata.inst(ic(1)).data.inst,'Get Max','%s\n','%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%f%c%c%c%c%c');
    %             maxfield=output(32);
    %             output = query(smdata.inst(ic(1)).data.inst,'Get Max','%s\n');
    %             maxfield_str = num2str(output(17:23));
    %             if val>maxfield
    %                error('Current setting must be less than MAX')
    %             end
                % THIS IS NEW *****
                output = query(smdata.inst(ic(1)).data.inst,'Get Max','%s\n','%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%f%c%c%c%c%c');
                maxfield = output(32);
                if abs(val)>maxfield
                   fprintf('Current setting must be less than MAX')
                end


                %sets the rate according to the final destination of the ramp

                %output = query(smdata.inst(ic(1)).data.inst,'Get Output','%s\n','%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%f%c%c%c%c%c%c%c%c%c%f%c%c%c%c%c%c');
                %fieldnow = output(18);
                %output = query(smdata.inst(ic(1)).data.inst,'Get Output','%s\n','%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%f%c%c%c%c%c%c%c%c%c%f%c%c%c%c%c%c');
                output = query(smdata.inst(ic(1)).data.inst,'Get Output','%s\n','%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%f%c%c%c%c%c%c%c%c%c%f%c%c%c%c%c%c');
                fieldnow = output(18);


                if abs(val) < 51 && abs(fieldnow) < 51
                    rate = 0.02;
                elseif abs(val) < 81.5 && abs(fieldnow) < 81.5
                    rate = 0.01;
                else
                    rate = 0.005;
                end



                if val*fieldnow < 0
                    fprintf('Must ramp to zero before switching polarity')
                elseif fieldnow == 0
                    if val >= 0
                        fprintf(smdata.inst(ic(1)).data.inst,'Direction +');
                    else %Have to set direction if less than zero
                        fprintf(smdata.inst(ic(1)).data.inst,'Direction -');
                    end
                end


                query(smdata.inst(ic(1)).data.inst,['Set Mid ' num2str(val)],'%s\n'); %previously was set to query
                query(smdata.inst(ic(1)).data.inst,['Set Ramp ' num2str(rate),'%s\n']);
                fprintf(smdata.inst(ic(1)).data.inst,'Ramp Mid');

                while smdata.inst(ic(1)).data.inst.BytesAvailable > 0
                        fscanf(smdata.inst(ic(1)).data.inst);
                end
                %else %Ramp down
                %    query(smdata.inst(ic(1)).data.inst,['Set Mid ' num2str(setpoint)],'%s\n');
                %    query(smdata.inst(ic(1)).data.inst,['Set Ramp ' num2str(rate)],'%s\n');
                %    query(smdata.inst(ic(1)).data.inst,'Ramp Mid','%s\n');
                %end
        end
    case 2 % M (max current)
        switch(ic(3))
            case 0
                output = query(smdata.inst(ic(1)).data.inst,'Get Max','%s\n','%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%f%c%c%c%c%c');
                val    = output(32);
            case 1
                if val > 90
                    fprintf('Max current must be less than 90 Amps')
                end
                query(smdata.inst(ic(1)).data.inst,['Set Max ' num2str(val)],'%s\n');
        end
end