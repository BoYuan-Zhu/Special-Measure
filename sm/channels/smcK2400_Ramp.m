function [val, rate] = smcK2400_Ramp(ic, val, rate)
%Channels
%1 - 'V' voltage
%2 - 'I' current
%3 - 'Vcompl' voltage compliance
%4 - 'Icompl' current compliance
%JDSY 12/6/2011 - added ramp channel and changed channel checking to be
%based on numbers
%Yuan 10/3/2015 - removed ramp channel (it's not there!). added compliance
%channel, and realized continuous reading from front panel when idle.
%Driver for Keithley 2400
%Last update: Hadar 10-13-2010
%Error Fixed: LeoZ 8-8-2012

    global smdata;
    global k2400_ramp;
    switch ic(2) % Channels 
        case 1 % Voltage
            switch ic(3) % Operation: 0 for read, 1 for write
                case 0 % read
                    if k2400_ramp == 1% Stop continuous updating
                            txt = query(smdata.inst(ic(1)).data.inst, ':SOUR:VOLT:LEV:IMM:AMPL?');  % or ':VOLT?'
                            val = str2double(strtrim(txt));                 % -> double scalar
                            % Resume continuous updating
                            % fprintf(smdata.inst(ic(1)).data.inst, ':arm:count infinite;:initiate');
                    else 
                        KO = query(smdata.inst(ic(1)).data.inst, ':abort;:arm:count 1;:read?', '%s\n', '%g,%g,%g,%g,%g');
                        val = KO(1);
                    end
                case 1 % write
                    fprintf(smdata.inst(ic(1)).data.inst,':OUTPut ON');
                    if k2400_ramp == 1
                        cmd = sprintf(':source:volt %g', val);
                        fprintf(smdata.inst(ic(1)).data.inst, cmd);
                        pause(0.05);
                    else
                         cmd = sprintf(':abort;:source:volt %g;:initiate', val);
                         fprintf(smdata.inst(ic(1)).data.inst, cmd);
                         pause(0.05);
                    end
                otherwise
                    error('K2400 driver: Operation not supported');
            end
        case 2 % Current
            switch ic(3) % Operation: 0 for read, 1 for write
                case 0 % read measured current
                    % Stop continuous updating
                    KO = query(smdata.inst(ic(1)).data.inst, ':abort;:arm:count 1;:read?', '%s\n', '%g,%g,%g,%g,%g');
                    val = KO(2);
                   
                    % Resume continuous updating
                    fprintf(smdata.inst(ic(1)).data.inst, ':arm:count infinite;:initiate');
                case 1 % write
                    cmd = sprintf(':abort;:source:curr %g;:initiate', val);
                    fprintf(smdata.inst(ic(1)).data.inst, cmd);
                    pause(0.05);
                otherwise
                    error('K2400 driver: Operation not supported');
            end
        case 3 % Voltage compliance
            switch ic(3) % Operation: 0 for read, 1 for write
                case 0 % read compliance voltage
                    val = query(smdata.inst(ic(1)).data.inst, ':abort;:sense:voltage:protection?','%s\n','%g');
                    fprintf(smdata.inst(ic(1)).data.inst, ':initiate');
                case 1 % write compliance voltage
                    cmd = sprintf(':abort;:sense:voltage:protection %g;:initiate', val);
                    fprintf(smdata.inst(ic(1)).data.inst, cmd);
                otherwise
                    error('K2400 driver: Operation not supported');
            end
        case 4 % Current compliance
            switch ic(3) % Operation: 0 for read, 1 for write
                case 0 % read compliance current
                    val = query(smdata.inst(ic(1)).data.inst, ':abort;:sense:current:protection?','%s\n','%g');
                    fprintf(smdata.inst(ic(1)).data.inst, ':initiate');
                case 1 % write compliance current
                    cmd = sprintf(':abort;:sense:current:protection %g;:initiate', val);
                    fprintf(smdata.inst(ic(1)).data.inst, cmd);
                otherwise
                    error('K2400 driver: Operation not supported');
            end
        case 5 % Ig-buf (K2400 buffered current helper)
            inst = smdata.inst(ic(1)).data.inst;
            switch ic(3)
                case 3  % one-time configure & arm (prepare buffer & measurement path)
                    
                    fprintf(inst, ':TRIG:CLEar');             % Clear trigger subsystem
                    fprintf(inst, ':TRAC:FEED:CONT NEVer');   % Stop feeding buffer (ensure inactive)
                    fprintf(inst, ':TRAC:CLEar');             % Now buffer can be cleared safely
                    fprintf(inst, ':ABOR;:TRIG:CLE;:ARM:COUN 1;:TRIG:COUN 1');
                    fprintf(inst, '*CLS');                    % Clear error/status queue
                    fprintf(inst, ':FORM:ELEM CURR');         % Only keep current element
                    fprintf(inst, ':SOUR:FUNC VOLT');         % Source voltage - measure current
                    fprintf(inst, ':SOUR:VOLT:RANG 20');
                    fprintf(inst, ':SENS:FUNC "CURR"');
                    fprintf(inst, ':SENS:CURR:NPLC 1');
                    fprintf(inst, ':TRAC:POIN 2500');         % Buffer capacity (1..2500)
                    fprintf(inst, ':TRAC:FEED SENS');         % Feed from measurement channel
                    fprintf(inst, ':TRAC:FEED:CONT NEXT');    % Write next buffer element each trigger
                    fprintf(inst, ':TRIG:COUN 1');            % Acquire 1 point per INIT
                    fprintf(inst,':sense:current:range 1e-6');% <-- set current compliance to 1 uA
                    smdata.inst(ic(1)).data.RampPts = 0;
                    val = [];
                case 2  % single-shot: push one reading into buffer
                    fprintf(inst, ':INIT');    % Start; buffer gets one reading due to FEED/NEXT
                    val = [];
                case 0  % read out all available points
                    n = query(inst, ':TRAC:POINts:ACTual?', '%s\n', '%d');
                    if isempty(n) || isnan(n) || n < 1
                        val = [];
                        return;
                    end
                    raw = query(inst, ':TRAC:DATA?');
                    vals = sscanf(raw, '%g,');   % column vector
                    val  = vals.';               % row vector
                    fprintf(inst,':ABORt;:TRIGger:CLEar;:TRACe:FEED:CONTrol NEVer');
                    fprintf(inst,':FORM:ELEM VOLT,CURR,RES,TIME,STAT');
                    fprintf(inst,':arm:count infinite;:initiate');
                    smdata.inst(ic(1)).data.RampPts = 0;
                    k2400_ramp = 0;
                case 4  % planned points from datadim
                    smdata.inst(ic(1)).data.RampPts = smdata.inst(ic(1)).datadim(ic(2));
                    val = smdata.inst(ic(1)).data.RampPts;
                case 5  % set planned points & configure I/O buffer
                    
                    fclose(inst); 
                    inst.InputBufferSize = 1e6; 
                    inst.Timeout = 20;     
                    fopen(inst);  
                    fprintf(inst, ':ABORt');                  % Abort any ongoing SDM/trigger
                    smdata.inst(ic(1)).datadim(ic(2)) = val;
                    smdata.inst(ic(1)).data.RampPts   = val;
                    smdata.inst(ic(1)).data.RampTime = (val-1)./rate;
                    
                    k2400_ramp = 1;
                otherwise
                    error('K2400 driver: Operation not supported for Ig-buf.');
            end
    end
end
