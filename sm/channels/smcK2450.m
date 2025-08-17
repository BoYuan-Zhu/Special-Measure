function val = smcK2450(ic, val, rate)
% Channels:
% 1 - 'V'        Source Voltage (read: set value; write: set source voltage)
% 2 - 'I'        Measure Current (read: one-shot MEAS:CURR?; write: set source current)
% 3 - 'Vcompl'   Voltage limit while sourcing current (CURR mode)
% 4 - 'Icompl'   Current limit while sourcing voltage (VOLT mode)
%
% Robust driver for Keithley 2450 with retries and safe parsing.
% All comments are in English per project requirement.

    %#ok<*NASGU>
    global smdata;

    % Fetch instrument object
    inst = smdata.inst(ic(1)).data.inst;

    % --- Ensure basic VISA/GPIB settings are sane (do not error if property absent)
    safe_setprop(inst, 'Timeout', 15);          % seconds
    safe_setprop(inst, 'InputBufferSize', 1e6);
    safe_setprop(inst, 'OutputBufferSize', 1e6);
    safe_setprop(inst, 'EOSMode', 'read&write');  % for gpib objects (if applicable)
    safe_setprop(inst, 'EOSCharCode', 'LF');
    safe_setprop(inst, 'Terminator', 'LF');       % for visa objects

    % Simple retry policy
    MAX_RETRY = 2;        % total attempts = MAX_RETRY + 1
    SLEEP_S   = 0.05;

    switch ic(2) % Channels
        case 1 % --- V (source voltage) ---
            switch ic(3) % 0=read, 1=write
                case 0 % read set voltage (not measurement)
                    % SCPI: :SOUR:VOLT?
                    val = qnum(inst, ':SOUR:VOLT?', 1, MAX_RETRY, SLEEP_S, NaN);
                    % No continuous trigger juggling; keep state simple/stable
                case 1 % write source voltage
                    % SCPI: :SOUR:FUNC VOLT; :SOUR:VOLT <val>
                    ok = cmd_with_opc(inst, sprintf(':SOUR:FUNC VOLT;:SOUR:VOLT %g', val), MAX_RETRY, SLEEP_S);
                    if ~ok, warning('K2450: failed to set source voltage'); end
                otherwise
                    error('K2450 driver: Operation not supported');
            end

        case 2 % --- I (measure current or set source current) ---
            switch ic(3)
                case 0 % read measured current (one-shot)
                    % Configure sensible sense function and read once.
                    % MEAS:CURR? will internally configure and trigger a reading.
                    val = qnum(inst, ':MEAS:CURR?', 1, MAX_RETRY, SLEEP_S, NaN);
                case 1 % write source current (source in current mode)
                    % SCPI: :SOUR:FUNC CURR; :SOUR:CURR <val>
                    ok = cmd_with_opc(inst, sprintf(':SOUR:FUNC CURR;:SOUR:CURR %g', val), MAX_RETRY, SLEEP_S);
                    if ~ok, warning('K2450: failed to set source current'); end
                otherwise
                    error('K2450 driver: Operation not supported');
            end

        case 3 % --- Vcompl (voltage limit when sourcing current) ---
            switch ic(3)
                case 0 % read
                    % SCPI: :SOUR:CURR:VLIM?
                    val = qnum(inst, ':SOUR:CURR:VLIM?', 1, MAX_RETRY, SLEEP_S, NaN);
                case 1 % write
                    % SCPI: :SOUR:CURR:VLIM <val>
                    ok = cmd_with_opc(inst, sprintf(':SOUR:CURR:VLIM %g', val), MAX_RETRY, SLEEP_S);
                    if ~ok, warning('K2450: failed to set voltage limit in CURR mode'); end
                otherwise
                    error('K2450 driver: Operation not supported');
            end

        case 4 % --- Icompl (current limit when sourcing voltage) ---
            switch ic(3)
                case 0 % read
                    % SCPI: :SOUR:VOLT:ILIM?
                    val = qnum(inst, ':SOUR:VOLT:ILIM?', 1, MAX_RETRY, SLEEP_S, NaN);
                case 1 % write
                    % SCPI: :SOUR:VOLT:ILIM <val>
                    ok = cmd_with_opc(inst, sprintf(':SOUR:VOLT:ILIM %g', val), MAX_RETRY, SLEEP_S);
                    if ~ok, warning('K2450: failed to set current limit in VOLT mode'); end
                otherwise
                    error('K2450 driver: Operation not supported');
            end

        otherwise
            error('K2450 driver: Nonvalid Channel specified');
    end

end

% ===== Helper functions (local) =========================================

function safe_setprop(obj, prop, value)
% RME:
% - Requirement: Attempt to set a property if it exists.
% - Modify: Set property; ignore if not applicable to the object class.
% - Effect: Improves robustness across visa/gpib objects.
    try
        if isprop(obj, prop)
            obj.(prop) = value;
        end
    catch
        % Ignore silently; some transports won't have these props
    end
end

function ok = cmd_with_opc(inst, scpi, max_retry, sleep_s)
% RME:
% - Requirement: Send SCPI command(s) and wait for completion using *OPC?.
% - Modify: fprintf, then query *OPC?; retry on failure/timeouts.
% - Effect: Synchronizes with instrument to avoid race conditions.
    ok = false;
    for t = 1:(max_retry+1)
        try
            % Flush any stale input to avoid mixing old replies
            safe_flush(inst);
            fprintf(inst, scpi);
            % Wait for operation complete: *OPC? returns "1"
            r = strtrim(query(inst, '*OPC?'));
            if strcmp(r, '1')
                ok = true;
                return;
            end
        catch ME
            % swallow and retry
            pause(sleep_s);
            if t == (max_retry+1)
                try
                    er = strtrim(query(inst, ':SYST:ERR?'));
                    warning('cmd_with_opc failed: %s | SYST:ERR=%s', ME.message, er);
                catch
                    warning('cmd_with_opc failed: %s | cannot fetch SYST:ERR', ME.message);
                end
            end
        end
        pause(sleep_s);
    end
end

function val = qnum(inst, scpi, wantN, max_retry, sleep_s, defaultVal)
% RME:
% - Requirement: Query numeric response, parse up to wantN numbers.
% - Modify: Use query(); robustly parse comma/space-separated numeric list.
% - Effect: Returns scalar if wantN==1; vector otherwise; default on failure.
    if nargin < 6, defaultVal = NaN; end
    val = defaultVal;

    for t = 1:(max_retry+1)
        try
            safe_flush(inst);
            raw = query(inst, scpi);           % e.g., "1.234E-3" or "0.1, 1.23E-3"
            if isempty(raw)
                pause(sleep_s); continue;
            end
            toks = regexp(strtrim(raw), '[,\s]+', 'split');
            nums = str2double(toks(~cellfun(@isempty, toks)));
            nums = nums(~isnan(nums));

            if isempty(nums)
                pause(sleep_s); continue;
            end

            if wantN == 1
                val = nums(1);
            else
                if numel(nums) >= wantN
                    val = nums(1:wantN);
                else
                    % Not enough numbers; keep trying
                    pause(sleep_s); 
                    continue;
                end
            end
            return; % success
        catch ME
            % retry; on last attempt, emit warning
            pause(sleep_s);
            if t == (max_retry+1)
                try
                    er = strtrim(query(inst, ':SYST:ERR?'));
                    warning('qnum("%s") failed: %s | SYST:ERR=%s', scpi, ME.message, er);
                catch
                    warning('qnum("%s") failed: %s | cannot fetch SYST:ERR', scpi, ME.message);
                end
            end
        end
    end
end

function safe_flush(inst)
% RME:
% - Requirement: Clear stale input/output buffers before a fresh transaction.
% - Modify: Use flush() when available, else fallback to fscanf loop best-effort.
% - Effect: Reduces risk of parsing previous replies.
    try
        % Newer MATLAB: flush supports 'input','output','all'
        flush(inst);
    catch
        % Fallback: try to drain input side by non-blocking reads
        try
            while inst.BytesAvailable > 0 %#ok<*PROP>
                fread(inst, inst.BytesAvailable);
            end
        catch
            % ignore
        end
    end
end
