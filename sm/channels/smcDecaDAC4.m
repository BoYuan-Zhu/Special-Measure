function val = smcDecaDAC4(ic, val, rate)
% With ramp support and new trigger scheme. Odd channels are ramped.
% Improved error treatment compared to smcdecaDAC3.m
%% Added 'M2;' command to queries to see if it helps with inconsistentices
%% in DAC operation 3/28/2011 JDSY
%% Note on Buffer flushing 3/11/2011 JDSY
%       can get unpredictable results if buffer is filled when reading
%       I think it would be better to always check for bytes available and
%       flush before query.  
% Change 3/11/2011 -> changed dacread function to always empty buffer
% before reading if anything is stored there.
%% Bug with ramping 3/11/2011 JDSY
%       Ramping sets and Upper and Lower Limit (U L) and a ramp rate (S)
%       Once a ramp is run, trying to set the value of the DAC using the
%       'D#####;' command will just rerun the ramp
%       The ramp can be stopped by sending the 'S0;' command
%       This does not get rid of the limits though and you will not be able
%       to set the DAC beyond the limits.  
%       --> Suggested fix.  Always reset limits in beginning to match range
%       
%% Ex of another bug 3/28/2011
%was reading and writing fine from Chan A0
%now i switch to Chan A1 and cannot write or read.   when i read it thinks
%it is at the correct value, but is not ouputing correct voltage on
%voltmeter.
global smdata;


if smdata.inst(ic(1)).channels(ic(2), 1) == 'S'
    switch ic(3)
        case 1
            query(smdata.inst(ic(1)).data.inst, 'X0;'); % clear buffer to avoid overflows
            if val > 0
                pause(.02); % seems to help avoiding early triggers.           
                fprintf(smdata.inst(ic(1)).data.inst, '%s', sprintf('X%d;', val));
            end
            % suppress terminator which would stop the script
            smdata.inst(ic(1)).data.scriptaddr = val;
            %if val==0
            %    query(smdata.inst(ic(1)).data.inst, ''); % send terminator and read response
            %    %smflush(ic(1));
            %end
            val = 0;

        case 0
            val = smdata.inst(ic(1)).data.scriptaddr;
    end
    return;
end

%% Slot and Channel number
sloti = floor((ic(2)-1)/8);
chani = floor(mod(ic(2)-1, 8)/2);

rng = smdata.inst(ic(1)).data.rng(floor((ic(2)-1)/2)+1, :);
%Reset any ramps
%resetRamp(smdata.inst(ic(1)).data.inst,sloti,chani);
switch ic(3)
    case 1

        %convert value to 0-65535 range
        val = round((val - rng(1))/ diff(rng) * 65535);
        val = max(min(val, 65535), 0);
                
        if mod(ic(2)-1, 2) % ramp
            rate2 = int32(abs(rate / diff(rng)) * 2^32 * 1e-6 * smdata.inst(ic(1)).data.update(floor((ic(2)+1)/2)));
                
            curr = dacread(smdata.inst(ic(1)).data.inst, sprintf('B%1d;M2;C%1d;d;', sloti, chani), '%*10c%d');

            if curr < val
                if rate > 0
                    dacwrite(smdata.inst(ic(1)).data.inst, sprintf('G8;U%05d;S%011d;G0;', val, rate2));
                else
                    dacwrite(smdata.inst(ic(1)).data.inst, sprintf('G%02d;U%05d;S%011d;', ...
                        smdata.inst(ic(1)).data.trigmode, val, rate2));
                end
            else
                if rate > 0
                    dacwrite(smdata.inst(ic(1)).data.inst, sprintf('G8;L%05d;S%011d;G0;', val, -rate2));
                else
                    dacwrite(smdata.inst(ic(1)).data.inst, sprintf('G%02d;L%05d;S%011d;', ...
                        smdata.inst(ic(1)).data.trigmode, val, -rate2));
                end
            end
            val = abs(val-curr) * 2^16 * 1e-6 * smdata.inst(ic(1)).data.update(floor((ic(2)+1)/2)) / double(rate2);
            
        else
            dacwrite(smdata.inst(ic(1)).data.inst, sprintf('B%1d;M2;C%1d;D%05d;', sloti, chani, val));
            val = 0;
        end


    case 0      
        val = dacread(smdata.inst(ic(1)).data.inst, ...
            sprintf('B%1d;M2;C%1d;d;', sloti, chani), '%*10c%d');
        val = val*diff(rng)/65535 + rng(1);
        if length(val) > 1
            error(['Apparent DAC comm error. MATLAB sucks.\n',...
                'Consider closing and opening the instrument with smclose and smopen \n']);
        end
        
    case 3        
        dacwrite(smdata.inst(ic(1)).data.inst, sprintf('B%1d;M2;C%1d;G0;', sloti, chani));
        
    otherwise
        error('Operation not supported');

end
end
 
function resetRamp(inst,slot,chan)
    %% Reset ramp and range limits for DAC jdsy 3/11/2011
    dacwrite(inst, sprintf('B%1d;M2;C%1d;S0;', slot,chan)); 
    dacwrite(inst, sprintf('B%1d;M2;C%1d;U65535;', slot,chan));
    dacwrite(inst, sprintf('B%1d;M2;C%1d;L0;', slot,chan));
end

function dacwrite(inst, str)
try
    query(inst, str);
catch
    fprintf('WARNING: error in DAC (%s) communication. Flushing buffer.\n',inst.Port);
    while inst.BytesAvailable > 0
        fprintf(fscanf(inst));pause(0.3)
    end
end
end

function val = dacread(inst, str, format)
if nargin < 3
    format = '%s';
end

i = 1;
while i < 10
    try
        %Flush buffer if necessary before reading.  Otherwise we will read
        %an outdated response.
        while inst.BytesAvailable > 0
            fscanf(inst);pause(0.3)
        end
        
        val = query(inst, str, '%s\n', format);
        i = 10;
    catch
        fprintf('WARNING: error in DAC (%s) communication. Flushing buffer and repeating.\n',inst.Port);
        while inst.BytesAvailable > 0
            fscanf(inst)
        end

        i = i+1;
        if i == 10
            error('Failed 10 times reading from DAC');pause(0.3)
        end
    end
end
end