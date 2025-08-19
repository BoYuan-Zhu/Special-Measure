function [val, rate] = smcK2450_Ramp(ic, val, rate)
% smcK2450_Ramp  -- Keithley 2450 controller for SOURCE VOLTAGE / MEASURE CURRENT (with buffered read)
%
% Channels (ic(2)):
%   1 - 'Vg'        : source voltage setpoint (read/write)
%   2 - 'Ig'        : single-shot measured current (read only)
%   3 - 'VgRange'   : voltage range (read/write; 0=AUTO)
%   4 - 'VgRead'    : voltage readback (read only)
%   5 - 'Iglimit'   : current compliance limit for voltage source (read/write)
%   6 - 'Vg-ramp'   : ramp/sweep configuration & timing (vector [start, stop, npts, holdTime])
%   7 - 'Ig-buf'    : buffered current readout of the configured ramp (read)
%
% Ops (ic(3)):
%   0 : read (or configure for channel 6)
%   1 : write (where supported)
%   4 : report configured npts to internal state (compat helper)
%   5 : set datadim / npts from upper layer and update internal timing (compat helper)

    % ---------- guard missing inputs ----------
    if nargin < 1
        error('smcK2450_Ramp: ic is required');
    end
    if nargin < 2
        % val might be absent for read ops; create a placeholder
        val = [];
    end
    if nargin < 3
        % rate might be absent for most ops; create a placeholder
        rate = [];
    end

    % ====== shared state ======
    global smdata;
    io = smdata.inst(ic(1)).data.inst;     % VISA/GPIB object
    DEF_BUFFER = 'defbuffer1';

    % Create internal storage fields if missing
    if ~isfield(smdata.inst(ic(1)).data, 'RampPts');   smdata.inst(ic(1)).data.RampPts  = 0;  end
    if ~isfield(smdata.inst(ic(1)).data, 'RampTime');  smdata.inst(ic(1)).data.RampTime = 0;  end

    % Ensure a sane I/O timeout (seconds)
    ensure_timeout(io, 30);

    % ====== main switch on channel ======
    switch ic(2)
        % -----------------------------------------------------------------
        % 1) Vg: source voltage setpoint
        % -----------------------------------------------------------------
        case 1
            switch ic(3)
                case 0  % read setpoint
                    send(io, ':SOUR:FUNC VOLT');
                    val = qnum(io, ':SOUR:VOLT?');
                case 1  % write setpoint
                    assert(~isempty(val), 'K2450/Vg write expects a numeric value.');
                    send(io, ':SOUR:FUNC VOLT');
                    send(io, sprintf(':SOUR:VOLT %g', val));
                case {3,4,5}
                    val = [];
                otherwise
                    error('K2450/Vg: unsupported op %d', ic(3));
            end

        % -----------------------------------------------------------------
        % 2) Ig: single-shot current read
        % -----------------------------------------------------------------
        case 2
            switch ic(3)
                case 0
                    send(io, ':SENS:FUNC "CURR"');
                    val = qnum(io, ':MEAS:CURR?');
                otherwise
                    error('K2450/Ig: write not supported');
            end

        % -----------------------------------------------------------------
        % 3) VgRange: 0=AUTO; otherwise fixed range
        % -----------------------------------------------------------------
        case 3
            switch ic(3)
                case 0  % read
                    auto = qnum(io, ':SOUR:VOLT:RANG:AUTO?');
                    if auto == 1
                        val = 0; % AUTO
                    else
                        val = qnum(io, ':SOUR:VOLT:RANG?');
                    end
                case 1  % write
                    assert(~isempty(val), 'K2450/VgRange write expects a value (0=AUTO or numeric range).');
                    if val == 0
                        send(io, ':SOUR:VOLT:RANG:AUTO 1');
                    else
                        send(io, ':SOUR:VOLT:RANG:AUTO 0');
                        send(io, sprintf(':SOUR:VOLT:RANG %g', val));
                    end
                otherwise
                    error('K2450/VgRange: unsupported op %d', ic(3));
            end

        % -----------------------------------------------------------------
        % 4) VgRead: measurement-path readback
        % -----------------------------------------------------------------
        case 4
            switch ic(3)
                case 0
                    val = qnum(io, ':SOUR:VOLT?');
                otherwise
                    error('K2450/VgRead: unsupported op %d', ic(3));
            end

        % -----------------------------------------------------------------
        % 5) Iglimit: compliance current
        % -----------------------------------------------------------------
        case 5
            switch ic(3)
                case 0
                    val = qnum(io, ':SOUR:VOLT:ILIM?');
                case 1
                    assert(~isempty(val), 'K2450/Iglimit write expects a numeric limit.');
                    send(io, sprintf(':SOUR:VOLT:ILIM %g', val));
                otherwise
                    error('K2450/Iglimit: unsupported op %d', ic(3));
            end

        % -----------------------------------------------------------------
        % 6) Vg-ramp: configure linear sweep into defbuffer1
        %     val = [startV, stopV, npts, holdTime]
        % -----------------------------------------------------------------
        case 6
            switch ic(3)
                case 0
                    assert(isvector(val) && numel(val)>=4, ...
                        'K2450/Vg-ramp: val must be [start, stop, npts, holdTime]');
                    startV   = val(1);
                    stopV    = val(2);
                    npts     = round(val(3));
                    holdTime = val(4);

                    assert(npts>=2, 'K2450/Vg-ramp: npts must be >=2');
                    assert(holdTime>=0, 'K2450/Vg-ramp: holdTime must be >=0');

                    send(io, ':ABOR');
                    send(io, ':OUTP ON');
                    send(io, ':SOUR:FUNC VOLT');
                    send(io, ':SENS:FUNC "CURR"');
                    send(io, ':SENS:CURR:RANG 1E-3');  % adjust as needed
                    send(io, ':SENS:CURR:NPLC 0.5');   % adjust as needed
                    send(io, ':FORM:ELEM READ');

                    send(io, sprintf(':TRAC:CLE "%s"', DEF_BUFFER));
                    send(io, sprintf(':TRAC:POIN %d,"%s"', npts, DEF_BUFFER));

                    cmd = sprintf(':SOUR:SWE:VOLT:LIN %g,%g,%d,%g,1,FIX,OFF,OFF,"%s"', ...
                                   startV, stopV, npts, holdTime, DEF_BUFFER);
                    send(io, cmd);

                    smdata.inst(ic(1)).data.RampPts  = npts;
                    smdata.inst(ic(1)).data.RampTime = (npts-1) * holdTime;

                case 4
                    smdata.inst(ic(1)).data.RampPts = smdata.inst(ic(1)).datadim(ic(2));

                case 5
                    if isempty(val);  error('K2450/Vg-ramp op=5 expects val=npts'); end
                    if isempty(rate); rate = 1; end   % safe default if caller omitted
                    smdata.inst(ic(1)).datadim(ic(2)) = val;
                    smdata.inst(ic(1)).data.RampPts   = val;
                    smdata.inst(ic(1)).data.RampTime  = (val-1) / rate;

                otherwise
                    error('K2450/Vg-ramp: unsupported op %d', ic(3));
            end

        % -----------------------------------------------------------------
        % 7) Ig-buf: run sweep and return buffered current
        % -----------------------------------------------------------------
        case 7
            switch ic(3)
                case 0
                    npts = smdata.inst(ic(1)).data.RampPts;
                    assert(~isempty(npts) && npts>0, 'K2450/Ig-buf: RampPts not configured.');

                    send(io, ':ABOR');
                    send(io, ':INIT');
                    opc = qnum(io, '*OPC?'); %#ok<NASGU> % block until complete

                    actual = qnum(io, sprintf(':TRAC:ACTUAL? "%s"', DEF_BUFFER));
                    t0 = tic;
                    while actual < npts
                        pause(0.05);
                        actual = qnum(io, sprintf(':TRAC:ACTUAL? "%s"', DEF_BUFFER));
                        if toc(t0) > max(5, 3 * smdata.inst(ic(1)).data.RampTime)
                            error('K2450/Ig-buf: timeout waiting buffer fill (%d/%d).', actual, npts);
                        end
                    end

                    raw  = qstr(io, sprintf(':TRAC:DATA? 1,%d,"%s",READ', npts, DEF_BUFFER));
                    nums = parse_csv_doubles(raw);
                    if numel(nums) ~= npts
                        send(io, ':ABOR'); send(io, ':TRIG:LOAD "EMPTY"');
                        error('K2450/Ig-buf: short read %d/%d', numel(nums), npts);
                    end

                    val = nums(:).';

                    send(io, ':ABOR');
                    send(io, ':TRIG:LOAD "EMPTY"');
                case 3
                    val = [];
                case 4
                    smdata.inst(ic(1)).data.RampPts = smdata.inst(ic(1)).datadim(ic(2));

                case 5
                    if isempty(val);  error('K2450/Ig-buf op=5 expects val=npts'); end
                    if isempty(rate); rate = 1; end
                    smdata.inst(ic(1)).datadim(ic(2)) = val;
                    smdata.inst(ic(1)).data.RampPts   = val;
                    smdata.inst(ic(1)).data.RampTime  = (val-1) / rate;

                otherwise
                    error('K2450/Ig-buf: unsupported op %d', ic(3));
            end

        % -----------------------------------------------------------------
        otherwise
            error('K2450: unknown channel %d', ic(2));
    end
end


% ====================== Local utility functions ======================

function ensure_timeout(io, minTimeout)
    try
        if isprop(io, 'Timeout')
            t = get(io, 'Timeout');
            if isempty(t) || ~isscalar(t) || ~isfinite(t) || t < minTimeout
                set(io, 'Timeout', minTimeout);
            end
        end
    catch
        % Best-effort only
    end
end

function send(io, cmd)
    fprintf(io, '%s\n', cmd);
end

function out = qstr(io, cmd)
    out = strtrim(query(io, sprintf('%s\n', cmd)));
end

function out = qnum(io, cmd)
    s = qstr(io, cmd);
    out = str2double(s);
end

function nums = parse_csv_doubles(raw)
    if isempty(raw)
        nums = [];
        return;
    end
    raw = strrep(raw, ',', ' ');
    raw = strrep(raw, ';', ' ');
    nums = sscanf(raw, '%f').';
end
