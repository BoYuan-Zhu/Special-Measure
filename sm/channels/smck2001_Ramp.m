function [val, rate] = smck2001_Ramp(ic, val, rate)
% smc for Keithley 2001 DMM
% Channels:
%   ico(2) == 1 : DCV immediate read (ico(3) == 0)
%   ico(2) == 2 : DCI immediate read (ico(3) == 0)
%   ico(2) == 3 : DCV buffered mode   (ico(3) in {5 cfg, 4 arm, 3 trig, 2 *TRG, 0 fetch})
%   ico(2) == 4 : DCI buffered mode   (ico(3) in {5 cfg, 4 arm, 3 trig, 2 *TRG, 0 fetch})
%
% Notes:
% - Buffered acquisition uses TRACe subsystem; data are retrieved via :TRAC:DATA?
% - On configure (ico(3)==5), this sets larger InputBufferSize/Timeout for long reads
% - Only DC modes are implemented here; extend to AC if needed
global smdata;

inst = smdata.inst(ic(1)).data.inst;

switch ic(2)
    %% 1) DCV — immediate read
    case 1
        switch ic(3)
            case 0  % get one reading
                fprintf(inst, ':INIT:CONT OFF;:ABOR');
                fprintf(inst, ':CONF:VOLT:DC');
                % Optional speed/accuracy tuning:
                % fprintf(inst, ':VOLT:NPLC 1');
                fprintf(inst, ':SAMP:COUN 1');
                val = query(inst, ':READ?', '%s\n', '%f');  % numeric reading
            otherwise
                error('Operation not supported for channel 1 (DCV immediate).');
        end

    %% 2) DCI — immediate read
    case 2
        switch ic(3)
            case 0  % get one reading
                fprintf(inst, ':INIT:CONT OFF;:ABOR');
                fprintf(inst, ':CONF:CURR:DC');
                % Optional speed/accuracy tuning:
                % fprintf(inst, ':CURR:NPLC 1');
                fprintf(inst, ':SAMP:COUN 1');
                val = query(inst, ':READ?', '%s\n', '%f');  % numeric reading
            otherwise
                error('Operation not supported for channel 2 (DCI immediate).');
        end

    %% 3) DCV — buffered mode
    case 3
        switch ic(3)
            case 5  % configure buffered acquisition
                % val: total points to acquire
                % rate (optional): sampling rate in Hz. If empty, use BUS triggers (1 point per *TRG)
                if nargin < 3 || isempty(rate), rate = []; end

                % Enlarge I/O buffers and timeout for long data blocks
                try, fclose(inst); end %#ok<TRYNC>
                inst.InputBufferSize = max(1e6, 10*val);  % rough oversizing
                inst.Timeout = 30;
                fopen(inst);

                fprintf(inst, '*RST; :INIT:CONT OFF; :ABORt');

                % Configure DCV and return only numeric readings
                fprintf(inst, ':CONF:VOLT:DC');
                fprintf(inst, ':FORM:ELEM READ');

                % Prepare trace buffer
                fprintf(inst, ':TRAC:CLEAR');
                fprintf(inst, ':TRAC:POIN %d', val);      % total capacity
                fprintf(inst, ':TRAC:FEED SENS');         % feed raw measured values
                fprintf(inst, ':TRAC:FEED:CONT NEXT');    % fill once then stop (NEXT)

        
                    % Software-triggered, one point per *TRG
                    fprintf(inst, ':TRIG:SOUR BUS;:TRIG:COUN %d', val);
               
            smdata.inst(ic(1)).datadim(ic(2)) = val;
            smdata.inst(ic(1)).data.RampPts   = val;
            smdata.inst(ic(1)).data.RampTime  = (val-1)./rate;
        

            case 4  % arm / start measurement run
                fprintf(inst, ':INIT');

            case 3  % trigger alias (kept for compatibility)
                fprintf(inst, ':INIT');

            case 2  % single software trigger (BUS)
                fprintf(inst, '*TRG');

            case 0  % fetch all buffered data
                % Wait until measurement completes (OPC=1)
                done = false;
                while ~done
                    resp = strtrim(query(inst, '*OPC?'));
                    done = strcmp(resp, '1');
                    if ~done, pause(0.05); end
                end
                raw = query(inst, ':TRAC:DATA?');
                val = sscanf(raw, '%f,')';               % row vector of doubles

                % Prepare for next acquisition burst
                fprintf(inst, ':TRAC:FEED:CONT NEXT');

            otherwise
                error('Operation not supported for channel 3 (DCV buffered).');
        end

    %% 4) DCI — buffered mode
    case 4
        switch ic(3)
            case 5  % configure buffered acquisition
                if nargin < 3 || isempty(rate), rate = []; end

                try, fclose(inst); end %#ok<TRYNC>
                inst.InputBufferSize = max(1e6, 10*val);
                inst.Timeout = 30;
                fopen(inst);

               fprintf(inst, '*RST; :INIT:CONT OFF; :ABORt');

                % Configure DCI and return only numeric readings
                fprintf(inst, ':CONF:CURR:DC');
                fprintf(inst, ':FORM:ELEM READ');

               % Prepare trace buffer
                fprintf(inst, ':TRAC:CLEAR');
                fprintf(inst, ':TRAC:POIN %d', val);      % total capacity
                fprintf(inst, ':TRAC:FEED SENS');         % feed raw measured values
                fprintf(inst, ':TRAC:FEED:CONT NEXT');    % fill once then stop (NEXT)


          
                fprintf(inst, ':TRIG:SOUR BUS;:TRIG:COUN %d', val);
               
           

            smdata.inst(ic(1)).datadim(ic(2)) = val;
            smdata.inst(ic(1)).data.RampPts   = val;
            smdata.inst(ic(1)).data.RampTime  = (val-1)./rate;
        

            case 4  % arm / start measurement run
                fprintf(inst, ':INIT');

            case 3  % trigger alias (compatibility)
                fprintf(inst, ':INIT');

            case 2  % single software trigger (BUS)
                fprintf(inst, '*TRG');

            case 0  % fetch all buffered data
                done = false;
                while ~done
                    resp = strtrim(query(inst, '*OPC?'));
                    done = strcmp(resp, '1');
                    if ~done, pause(0.05); end
                end
                raw = query(inst, ':TRAC:DATA?');
                val = sscanf(raw, '%f,')';               % row vector of doubles

                fprintf(inst, ':TRAC:FEED:CONT NEXT');

            otherwise
                error('Operation not supported for channel 4 (DCI buffered).');
        end

    otherwise
        error('Unknown channel ico(2)=%d.', ic(2));
end
end
