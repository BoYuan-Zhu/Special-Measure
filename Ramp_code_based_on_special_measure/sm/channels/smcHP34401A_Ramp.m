function [val, rate] = smcHP34401A_Ramp(ico, val, rate)
% driver for Agilent DMMs with support for buffered readout. 
% Some instrument and mode dependent parameters hardcoded!
global smdata;


% fprintf(smdata.inst(ico(1)).data.inst, 'abort');
% fprintf(smdata.inst(ico(1)).data.inst, 'trig:count 1');
cmd = sprintf(':TRIG:SOUR IMM;:TRIG:COUN INF;:INIT');
inst = smdata.inst(ico(1)).data.inst;
switch ico(2) % channel
    case 1
        fprintf(smdata.inst(ico(1)).data.inst, 'abort');
         fprintf(smdata.inst(ico(1)).data.inst, 'trig:count 1');
        switch ico(3)
            case 0 %get
                val = query(inst,  'read?', '%s\n', '%f');
                fprintf(smdata.inst(ico(1)).data.inst, 'trig:count inf');
                fprintf(smdata.inst(ico(1)).data.inst, 'initiate');
            otherwise
                error('Operation not supported');
        end
        
    case 2
        switch ico(3)
            case 0
                
                done = false;
                while ~done
                    resp = strtrim(query(inst, '*OPC?'));  % 
                    if strcmp(resp, '1')
                        done = true;
                    else
                        pause(0.05);  % 
                    end
                end
                % this blocks until all values are available
                val = sscanf(query(inst,  'FETCH?'), '%f,')';
                fprintf(inst,cmd);
            case 2 % % single-shot: push one reading into buffer
                 
                 fprintf(inst, '*TRG');
                 
            case 3 %trigger
                
                fprintf(inst, 'INIT'); 
                              

            case 4 % arm instrument
                fprintf(smdata.inst(ico(1)).data.inst, 'INIT'); 
                
            case 5 % configure instrument                    
%                 % minumum time per sample for dmm - heuristic and mode dependent
%                 %samptime = .04225; %34465A 20 ms integration time
%                 %samptime = .035; % %34465A 16.7 ms integration time
%                 samptime = .4025; %34465A 200 ms
%                  
%                 if 1/rate < samptime
%                     trigdel = 0;
%                     rate = 1/samptime;
%                 else
%                     trigdel = 1/rate - samptime;
%                 end
% 
%                 if val > 512 % 50000 for newer model
%                     error('More than allowed number of samples requested. Correct and try again!\n');
%                 end
%                 fprintf(smdata.inst(ico(1)).data.inst, 'TRIG:SOUR BUS');
%                 %fprintf(smdata.inst(ind).data.inst, 'VOLT:NPLC 1'); %integrate 1 power line cycle
%                 fprintf(smdata.inst(ico(1)).data.inst, 'SAMP:COUN %d', val);
%                 fprintf(smdata.inst(ico(1)).data.inst, 'TRIG:DEL %f', trigdel);
                    fclose(inst); 
                    inst.InputBufferSize = 1e6; 
                    inst.Timeout = 20;     
                    fopen(inst);  
               
                fprintf(inst,'*RST;:SYST:REM;:ABOR');% reset
            
                fprintf(inst,':CONF:VOLT:DC 10;:SENS:VOLT:DC:NPLC 1;:FORM:DATA ASC;');% set voltage range and data format
                
                fprintf(inst,':TRIG:SOUR BUS;:SAMP:COUN 1;:TRIG:COUN %d', val');
               
             
   
                smdata.inst(ico(1)).datadim(2, 1) = val;
                                
            otherwise
                error('Operation not supported');
        end
end
% fprintf(smdata.inst(ico(1)).data.inst, 'trig:count inf');
% fprintf(smdata.inst(ico(1)).data.inst, 'initiate');

