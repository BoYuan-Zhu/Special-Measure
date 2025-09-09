function [val, rate] = smcSR860_Ramp_TTLbuf(ic, val, rate, ctrl)
%==========================================================================
% SR860 LOCK-IN DRIVER — PER-TRIGGER ONLY (BUF_X/Y/R/T on channels 23–26)
%--------------------------------------------------------------------------
% ic(1): instrument index
% ic(2): channel (23..26 => BUF_X/BUF_Y/BUF_R/BUF_T)
% ic(3): op code (0=read, 2=trigger, 3=arm, 5=configure)
% val:   case 5 input planned point count; case 0 returns data
% rate:  case 5 input target rate (Hz);   case 5 returns actual rate
% ctrl:  unused here (always per-trigger)
%==========================================================================

global smdata;

cmds = {'X    ','Y    ','R    ','THETA', ...
        'FREQ ','VREF ', ...
        'IN1  ','IN2  ','IN3  ','IN4  ', ...
        'OUT1 ','OUT2 ','OUT3 ','OUT4 ', ...
        '','', ...          % 15,16
        'SENS ','TAU  ', ...% 17,18
        '','','', ...       % 19,20,21
        '', ...             % 22 not used
        'BUF_X','BUF_Y','BUF_R','BUF_T'}; % 23..26

switch ic(2)

    %==================================================================
    % 23–26: XYRT BUFFER (PER-TRIGGER ONLY)
    %==================================================================
    case {23,24,25,26}

        auxCh = 0; vHigh = 5.0; vLow = 0.0;  % Aux0 for TTL

        switch ic(3)

            %----------------------------------------------------------
            case 0  % READ: stop+read buffer, then return exactly datadim points
            %----------------------------------------------------------
                cache = [];
                if isfield(smdata.inst(ic(1)).data,'buf_cache')
                    cache = smdata.inst(ic(1)).data.buf_cache;
                end
                need_read = isempty(cache) || ~isfield(cache,'x') || isempty(cache.x) ...
                                         || ~isfield(cache,'y') || isempty(cache.y) ...
                                         || ~isfield(cache,'r') || isempty(cache.r) ...
                                         || ~isfield(cache,'theta') || isempty(cache.theta);
                if need_read
                    data = stopAndReadBuffer(ic(1));
                    if isstruct(data)
                        smdata.inst(ic(1)).data.buf_cache = data;
                        cache = data;
                    else
                        x = data(:,1); y = data(:,2); r = data(:,3); theta = data(:,4);
                        cache = struct('x',x,'y',y,'r',r,'theta',theta);
                        smdata.inst(ic(1)).data.buf_cache = cache;
                    end
                end

                % expected length from datadim
                pts = 1;
                try
                    if isfield(smdata.inst(ic(1)),'datadim') && ...
                       size(smdata.inst(ic(1)).datadim,1) >= ic(2) && ...
                       smdata.inst(ic(1)).datadim(ic(2),1) > 0
                        pts = smdata.inst(ic(1)).datadim(ic(2),1);
                    end
                catch
                    pts = 1;
                end

                switch ic(2)
                    case 23, vec = cache.x;
                    case 24, vec = cache.y;
                    case 25, vec = cache.r;
                    case 26, vec = cache.theta;
                end
                vec = vec(:).'; % row
                if numel(vec) >= pts
                    val = vec(1:pts);
                else
                    val = [vec, nan(1, pts-numel(vec))];
                end

            %----------------------------------------------------------
            case 2  % TRIGGER: one TTL pulse on Aux0
            %----------------------------------------------------------
                inst = smdata.inst(ic(1)).data.inst;
                sr860_aux_set(inst, auxCh, vLow);  pause(0.005);
                sr860_aux_set(inst, auxCh, vHigh); pause(0.005);
                sr860_aux_set(inst, auxCh, vLow);
                val = [];

            %----------------------------------------------------------
            case 3  % ARM: XYRT + per-trigger (one sample per trigger)
            %----------------------------------------------------------
                try
                    inst = smdata.inst(ic(1)).data.inst;
                    fprintf(inst, '*CLS');          pause(0.02);

                    % buffer length (kB)
                    if isfield(smdata.inst(ic(1)).data,'CAPLEN_kB') && ~isempty(smdata.inst(ic(1)).data.CAPLEN_kB)
                        kb = smdata.inst(ic(1)).data.CAPLEN_kB;
                    else
                        kb = 256;
                    end
                    fprintf(inst, 'CAPTURELEN %u', kb); pause(0.02);

                    % XYRT mode
                    fprintf(inst, 'CAPTURECFG 3');  pause(0.02);

                    % per-trigger only
                    fprintf(inst, 'CAPTURESTART ONE, SAMPpertrig');

                    % optional: set AUX high to indicate "ready"
                    sr860_aux_set(inst, auxCh, vHigh);

                    smdata.inst(ic(1)).data.buf_cache = struct('x',[],'y',[],'r',[],'theta',[]);
                    val = [];
                catch err
                    error('SR860: Buffer arm failed - %s', err.message);
                end

            %----------------------------------------------------------
            case 5  % CONFIGURE: set internal rate & buffer size (no start)
            %----------------------------------------------------------
                try
                    inst = smdata.inst(ic(1)).data.inst;
                    smdata.inst(ic(1)).data.currsamp = 0;

                    % internal max rate (decimated)
                    maxrate = query(inst, 'CAPTURERATEMAX?', '%s\n', '%g');
                    if isempty(maxrate) || isnan(maxrate), maxrate = 1000; end

                    target_rate = abs(rate);
                    if isempty(target_rate) || isnan(target_rate) || target_rate <= 0
                        target_rate = maxrate;
                    end
                    target_rate = min(target_rate, maxrate);

                    n = ceil(log2(maxrate / max(1e-9, target_rate)));
                    n = max(0, min(20, n));
                    actual_rate = maxrate / (2^n);
                    fprintf(inst, 'CAPTURERATE %d', n);
                    smdata.inst(ic(1)).data.sampint = 1 / actual_rate;

                    % buffer size from planned points (16 bytes/sample)
                    if isempty(val), val = 0; end
                    planned_pts = max(0, double(val));
                    if ~isscalar(planned_pts), cap_pts = max(planned_pts(:)); else, cap_pts = planned_pts; end
                    bytes_needed = 16 * cap_pts;
                    kb = 2 * ceil((bytes_needed/1024)/2); % even kB
                    kb = min(max(kb, 2), 4096);
                    smdata.inst(ic(1)).data.CAPLEN_kB = kb;

                    % expected return length for 23–26
                    if ~isfield(smdata.inst(ic(1)),'datadim') || size(smdata.inst(ic(1)).datadim,1) < 26
                        rows = max(26, size(smdata.inst(ic(1)).datadim,1));
                        cols = max(1,  size(smdata.inst(ic(1)).datadim,2));
                        tmp = zeros(rows, cols);
                        if isfield(smdata.inst(ic(1)),'datadim') && ~isempty(smdata.inst(ic(1)).datadim)
                            tmp(1:size(smdata.inst(ic(1)).datadim,1), 1:size(smdata.inst(ic(1)).datadim,2)) = smdata.inst(ic(1)).datadim;
                        end
                        smdata.inst(ic(1)).datadim = tmp;
                    end
                    smdata.inst(ic(1)).datadim(23:26,1) = cap_pts;

                    % outputs
                    rate = actual_rate;
                    if isscalar(val)
                        val = double(cap_pts);
                    else
                        val = repmat(double(cap_pts), size(val));
                    end

                catch err
                    error('SR860: Buffer configuration failed - %s', err.message);
                end

            otherwise
                error('SR860: Unsupported op %d for buffer channels 23–26', ic(3));
        end

    %==================================================================
    % Other standard (non-buffer) channels
    %==================================================================
    otherwise
        switch ic(3)
            case 1  % SET
                if ic(2) == 17
                    val = SR860sensindex(val);
                elseif ic(2) == 18
                    val = SR860tauindex(val);
                end
                if any(ic(2) == [11 12 13 14])
                    fprintf(smdata.inst(ic(1)).data.inst, sprintf('%s, %f', cmds{ic(2)}, val));
                else
                    fprintf(smdata.inst(ic(1)).data.inst, sprintf('%s %f', cmds{ic(2)}, val));
                end

            case 0  % GET
                val = query(smdata.inst(ic(1)).data.inst, ...
                           sprintf('%s? %s', cmds{ic(2)}(1:4), cmds{ic(2)}(5:end)), ...
                           '%s\n', '%f');
                if ic(2) == 17
                    val = SR860sensvalue(val);
                elseif ic(2) == 18
                    val = SR860tauvalue(val);
                end

            otherwise
                error('SR860: Unsupported op %d for ch %d', ic(3), ic(2));
        end
end

%==========================================================================
% CORE BUFFER I/O
%==========================================================================
function buffer_data = stopAndReadBuffer(inst_idx)
% Stop capture and read all XYRT samples (case 0 will clip/pad to datadim)
try
    inst = smdata.inst(inst_idx).data.inst;
    fprintf(inst, 'CAPTURESTOP');
    pause(0.05);
    bytes = query(inst, 'CAPTUREBYTES?', '%s\n', '%d');
    if isempty(bytes) || isnan(bytes) || bytes < 16
        buffer_data = struct('x',[],'y',[],'r',[],'theta',[]);
        smdata.inst(inst_idx).data.buf_cache = buffer_data;
        return;
    end
    nsamp = floor(bytes/16);
    x = zeros(1,nsamp); y = x; r = x; theta = x;
    for k = 0:nsamp-1
        fprintf(inst, 'CAPTUREVAL? %d', k);
        ln = fgetl(inst);
        if ischar(ln) && ~isempty(ln)
            vals = str2num(ln); %#ok<ST2NM>
            if numel(vals) >= 4
                x(k+1)=vals(1); y(k+1)=vals(2); r(k+1)=vals(3); theta(k+1)=vals(4);
            else
                x(k+1)=NaN; y(k+1)=NaN; r(k+1)=NaN; theta(k+1)=NaN;
            end
        else
            x(k+1)=NaN; y(k+1)=NaN; r(k+1)=NaN; theta(k+1)=NaN;
        end
    end
    buffer_data = struct('x',x,'y',y,'r',r,'theta',theta);
    smdata.inst(inst_idx).data.buf_cache = buffer_data;
catch err
    fprintf('*ERROR* Reading buffer: %s\n', err.message);
    buffer_data = struct('x',[],'y',[],'r',[],'theta',[]);
    smdata.inst(inst_idx).data.buf_cache = buffer_data;
end
end

function cache = getBufferCache(inst_idx)
if isfield(smdata.inst(inst_idx).data,'buf_cache')
    cache = smdata.inst(inst_idx).data.buf_cache;
else
    cache = struct('x',[],'y',[],'r',[],'theta',[]);
end
end

%==========================================================================
% UTILITIES
%==========================================================================
function sr860_aux_set(inst, j, v)
v = max(min(v, 10.5), -10.5);
try, fprintf(inst, sprintf('AUXV %d, %g', j, v));
catch, fprintf(inst, sprintf('AUXO %d, %g', j, v)); end
end

function val = SR860sensvalue(sensindex)
base_values = [2e-9, 5e-9, 10e-9]; multipliers = 10.^(0:9);
sensvals = []; for mult = multipliers, sensvals = [sensvals, base_values*mult]; end %#ok<AGROW>
val = sensvals(sensindex + 1);
end

function sensindex = SR860sensindex(sensval)
base_values = [2e-9, 5e-9, 10e-9]; multipliers = 10.^(0:9);
sensvals = []; for mult = multipliers, sensvals = [sensvals, base_values*mult]; end %#ok<AGROW>
sensindex = find(sensvals >= sensval, 1) - 1;
end

function val = SR860tauvalue(tauindex)
base_values = [10e-6, 30e-6]; multipliers = 10.^(0:9);
tauvals = []; for mult = multipliers, tauvals = [tauvals, base_values*mult]; end %#ok<AGROW>
val = tauvals(tauindex + 1);
end

function tauindex = SR860tauindex(tauval)
base_values = [10e-6, 30e-6]; multipliers = 10.^(0:9);
tauvals = []; for mult = multipliers, tauvals = [tauvals, base_values*mult]; end %#ok<AGROW>
tauindex = find(tauvals >= tauval, 1) - 1;
end
end
