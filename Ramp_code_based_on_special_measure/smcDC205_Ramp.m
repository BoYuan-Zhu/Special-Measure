function [val, rate] = smcDC205(ico, val, rate)
%Driver for DC 205
%ico=[inst,channel,operation] 
%1:Vout,
%2:Vout_range
%--------------------------CHANNEL LIST-----------------------------------
%2:output isolation, 
%3:remote sensing, 
%4:output, 
%5:DC voltage,
%6:scan range, 
%7:scan beginning voltage,
%8: scan edning voltage,
%9: scan time,
%10:scan shape,
%11: scan cycle,
%12: scan display,
%13: scan-arm 
%14:remote trigger
%Other commands are not quite necessary for remote control, you can just press
%the physical buttons on the machine box
%------------------------INPUT DATA TYPE----------------------------------
%1,2,3,4,6,10,11,12,13: integer whose range depends on the specific
%command. Listed below in INTEGER COMMAND
%5,7,8,9: floating-point value
%14: No input
%------------------------INTEGER COMMAND-----------------------------------
%1-range:               0:0-1V  1:0-10V 2:0-100V
%2-output isolation:    0:ground    1:float
%3-remote sensing       0:two-wire  1:four-wire
%4-output               0:off   1:on
%6:scan range           0:0-1V   1:0-10V    2:0-20V
%10:scan shape          0:one-direction 1:bidirection
%11:scan cycle          0:once  1:repeat
%12:scan display        0:off   1:on
%13:scan arm            0:idle  1:on  2: running

global smdata;

% cmds={"RNGE","ISOL","SENS","SOUT","VOLT","SCAR","SCAB","SCAE",...
%     "SCAT","SCAS","SCAC","SCAD","SCAA","*TRG"};


% inst = smdata.inst(ico(1)).data.inst;
if smdata.inst(ico(1)).data.inst.BytesAvailable > 0
    fprintf(fscanf(smdata.inst(ico(1)).data.inst));
    % fscanf(inst);
end


isoutput=query(smdata.inst(ico(1)).data.inst, sprintf('%s?', 'SOUT'), '%s\n', '%d');
if ~isoutput
    error("Output is off");
end



switch ico(2)
    case 1 % Vout
        switch ico(3)
            case 1
                % Stop scanning
                fprintf(smdata.inst(ico(1)).data.inst,sprintf('%s%d','SCAA',0));

                startValue = query(smdata.inst(ico(1)).data.inst, sprintf('%s?', 'VOLT'), '%s\n', '%f');
                range=query(smdata.inst(ico(1)).data.inst, sprintf('%s?', 'RNGE'), '%s\n', '%d');

                if val == startValue
                    val = 0;
                    return
                elseif abs(val) > 10^range
                    error('Change output range to match')
                end

                totTime = round(10 * min(abs((val-startValue)./rate), 99999))/10;
                if totTime<0.1
                    totTime = 0.1;
                end

                % Change scan range to match
                fprintf(smdata.inst(ico(1)).data.inst,sprintf('%s%d','SCAR',range));
                % Start value
                fprintf(smdata.inst(ico(1)).data.inst,sprintf('%s%f','SCAB',startValue));
                % End value
                fprintf(smdata.inst(ico(1)).data.inst,sprintf('%s%f','SCAE',val));
                % Scan time
                fprintf(smdata.inst(ico(1)).data.inst,sprintf('%s%f','SCAT',totTime));
                % Scan shape: one direction
                fprintf(smdata.inst(ico(1)).data.inst,sprintf('%s%d','SCAS',0));
                % Scan cycle: once
                fprintf(smdata.inst(ico(1)).data.inst,sprintf('%s%d','SCAC',0));
                % Scan display: on
                fprintf(smdata.inst(ico(1)).data.inst,sprintf('%s%d','SCAD',1));
                
                % Set scan to arm state
                fprintf(smdata.inst(ico(1)).data.inst,sprintf('%s%d','SCAA',1));

                if rate > 0
                    fprintf(smdata.inst(ico(1)).data.inst,'*TRG');
                end
                val = totTime;
            case 3
                 fprintf(smdata.inst(ico(1)).data.inst,'*TRG');
            case 0
                % Stop scanning
                fprintf(smdata.inst(ico(1)).data.inst,sprintf('%s%d','SCAA',0));
                val = query(smdata.inst(ico(1)).data.inst, sprintf('%s?', 'VOLT'), '%s\n', '%f');
        end
    case 2 % Vout_range
        switch ico(3)
            case 1
                 % Stop scanning
                 fprintf(smdata.inst(ico(1)).data.inst,sprintf('%s%d','SCAA',0));
                 if val~=0 && val~=1 && val~=2
                     fprintf('val=%d',val);
                     error('Out of range 0,1,2');
                 end
                fprintf(smdata.inst(ico(1)).data.inst,sprintf('%s%f','RNGE',val));
            case 0
                % Stop scanning
                fprintf(smdata.inst(ico(1)).data.inst,sprintf('%s%d','SCAA',0));
                val = query(smdata.inst(ico(1)).data.inst, sprintf('%s?', 'RNGE'), '%s\n', '%d');
        end
end



% switch ico(3)
%     case 1 %set
%         if ico(2)==14 %trigger
%             isarmed=query(smdata.inst(ico(1)).data.inst, sprintf('%s?', 'SCAA'), '%s\n', '%d'); %judge whether it's armed
%             fprintf("isarmed=%d",isarmed);
%             if isarmed
% 
%                 fprintf(smdata.inst(ico(1)).data.inst,sprintf('%s', cmds{ico(2)}));
%                 fprintf("Go on and print %s",cmds{ico(2)});
%             else
%                 error('Scan is not armed')
%             end
%         elseif ico(2)==5 || ico(2)==7 ||ico(2)==8 || ico(2)==9 %input floating number
%             fprintf(smdata.inst(ico(1)).data.inst,sprintf('%s%f',cmds{ico(2)},val));
%         else %input integer
%             if ico(2)==1 || ico(2)==6 %range is {0,1,2}
%                 if val~=0 && val~=1 && val~=2
%                     fprintf('val=%d',val);
%                     error('Out of range 0,1,2'); 
%                 end
%             elseif ico(2)==13 % extra judgement for scan arm
%                 %1. judge whether output is on
%                 isoutput=query(smdata.inst(ico(1)).data.inst, sprintf('%s?', 'SOUT'), '%s\n', '%d'); 
%                 if ~isoutput
%                     error("Output is off");
%                 end
%                 %2. judge whether DC range and scan range is the same
%                 range=query(smdata.inst(ico(1)).data.inst, sprintf('%s?', 'RNGE'), '%s\n', '%d');
%                 sRange=query(smdata.inst(ico(1)).data.inst, sprintf('%s?', 'SCAR'), '%s\n', '%d');
%                 if range~=sRange
%                     error('Range setting does not match the scan range');
%                 end
%                 %3. judge whether beginning/ending voltage are different
%                 beginning=query(smdata.inst(ico(1)).data.inst, sprintf('%s?', 'SCAB'), '%s\n', '%f');
%                 ending=query(smdata.inst(ico(1)).data.inst, sprintf('%s?', 'SCAE'), '%s\n', '%f');
%                 if beginning==ending
%                     error('Beginning and ending voltages are equal');
%                 end
%             else    %judge the input range
%                 if val~=0 && val~=1 %range is {0,1}
%                     error('Out of range 0,1');
%                 end
%             end
%             fprintf(smdata.inst(ico(1)).data.inst,sprintf('%s%d',cmds{ico(2)},val));
%         end
%     case 0 %read
%         if ico(2)==14 %trigger
%             error('Trigger is not availale for reading'); 
%         elseif ico(2)==5 || ico(2)==7 ||ico(2)==8 || ico(2)==9 %read floating number
%             val = query(smdata.inst(ico(1)).data.inst, sprintf('%s?', cmds{ico(2)}), '%s\n', '%f');
%         else %read integer number
%             val = query(smdata.inst(ico(1)).data.inst, sprintf('%s?', cmds{ico(2)}), '%s\n', '%d');
%         end %read floating number
%             fprintf(smdata.inst(ico(1)).data.inst,sprintf('%s %f', cmds{ico(2)},val));  
%     otherwise
%         error('Operation not supported');
end
    
