function [val, rate] = smcSR860_Ramp_1(ic, val, rate, ctrl)
% [val, rate] = smcSR860(ic, val, rate, ctrl)
% ctrl: 'sync' (each sample triggered)
%       'trig' external trigger starts acq.
% 21: Auto Scale
%-------------------channel command-------------------------
% 1:OUTP 0=X  2:OUTP 1=Y  3:OUTP 2=R  4:OUTP 3=theta  5:FREQ=frequency
% 6:SLVL=sine out amplitude  7:OAUX 0=aux input 1 voltage
% 8:OAUX 1=aux input 2 voltage  9:OAUX 2=aux input 3 voltage
% 10:OAUX 3=aux input 4 voltage  11:AUXV 0=set aux 1
% 12:AUXV 1=set aux 2  13:AUXV 2=set aux 3  14:AUXV 3=set aux 4
% 15,16: store data  17:SCAL=set sensitivity  18:OFLT=set time constant
% 19:'SYNC'  20:SOFF=dc level  21: Auto phase/range/sens
% 22:OUTP 8=Xnoise  23:OUTP 9=Ynoise  24:IVMD voltage/current  25:HARM
% 30: Capture Buffer mode (continuous or per-trigger via AUX->TRIG)
%------------------------Notice-----------------------------
% While in voltage mode (IVMD 0), OUTP 0,1,2,3 are voltage params.
% While in current mode (IVMD 1), OUTP 0,1,2,3 are current params.

global smdata;

cmds = {'OUTP 0', 'OUTP 1', 'OUTP 2', 'OUTP 3', 'FREQ', 'SLVL', ...
    'OAUX 0', 'OAUX 1', 'OAUX 2', 'OAUX 3', 'AUXV 0', 'AUXV 1', 'AUXV 2', 'AUXV 3' ...
    ,'','','SCAL', 'OFLT', 'SYNC','SOFF','','OUTP 8','OUTP 9','IVMD','HARM'};

switch ic(2) % Channel
    % -------------------------- Utility / auto functions --------------------
    case 21 %Auto phase Range and sensitivity
        fprintf(smdata.inst(ic(1)).data.inst,'APHS');
        fprintf(smdata.inst(ic(1)).data.inst,'ARNG');
        fprintf(smdata.inst(ic(1)).data.inst,'ASCL');
        val = 1;

    % -------------------------- Stored data (your style) --------------------
    case {15, 16} % stored data, length determined by datadim
        switch ic(3)
            case 0  % get
                npts = smdata.inst(ic(1)).datadim(ic(2), 1);

                while 1
                    navail = query(smdata.inst(ic(1)).data.inst, 'CAPTUREBYTES?', '%s\n', '%d')./8;

                    if ic(2) == 15
                        currsamp = smdata.inst(ic(1)).data.currsamp_real;
                    elseif ic(2) == 16
                        currsamp = smdata.inst(ic(1)).data.currsamp_phase;
                    end

                    if navail >= npts + currsamp
                        break;
                    else
                        pause(0.8 * (npts + currsamp - navail) ...
                            * smdata.inst(ic(1)).data.sampint);
                    end
                end

                fprintf(smdata.inst(ic(1)).data.inst, 'CAPTURESTOP;CAPTUREGET? 0, %g',ceil(npts*2/256));
                rawdata = readbinblock(smdata.inst(ic(1)).data.inst,'single');

                if ic(2) == 15
                    % In-phase X from (R,theta)
                    val = rawdata(1:2:npts*2-1).*cosd(rawdata(2:2:npts*2));
                    smdata.inst(ic(1)).data.currsamp_real = smdata.inst(ic(1)).data.currsamp_real + npts;
                elseif ic(2) == 16
                    % Theta
                    val = rawdata(2:2:npts*2);
                    smdata.inst(ic(1)).data.currsamp_phase = smdata.inst(ic(1)).data.currsamp_phase + npts;
                end

            case 3
                fprintf(smdata.inst(ic(1)).data.inst, 'CAPTURESTART 0, 0;'); % ONE, IMM

            case 4
                pause(.1);
                if ic(2) == 15
                    smdata.inst(ic(1)).data.currsamp_real = 0;
                elseif  ic(2) == 16
                    smdata.inst(ic(1)).data.currsamp_phase = 0;
                end

            case 5
                if val > 8192
                    error('Max sample points for SR860 is 8192');
                end

                maxrate = query(smdata.inst(ic(1)).data.inst,'CAPTURERATEMAX?','%s\n','%g');

                if abs(rate) > maxrate
                    error('Change time constant to get faster sampling rate')
                else
                    n = ceil(log2(maxrate./abs(rate)));
                    rate = maxrate./(2^(n));
                    if n > 20
                        error('Samplerate not supported (min rate = %g Hz)', maxrate./2^20);
                    elseif  n < 0
                        error('Samplerate not supported (max rate = %g Hz)', maxrate);
                    end
                end

                fprintf(smdata.inst(ic(1)).data.inst, ['CAPTURESTOP;' ...
                    'CAPTURECFG 2;CAPTURERATE %i;CAPTURELEN 4096'],n); % (R,theta), max len
                pause(.1);
                if ic(2) == 15
                    smdata.inst(ic(1)).data.currsamp_real = 0;
                elseif  ic(2) == 16
                    smdata.inst(ic(1)).data.currsamp_phase = 0;
                end
                smdata.inst(ic(1)).data.sampint = 1/rate;
                smdata.inst(ic(1)).datadim(15:16, 1) = val;

            otherwise
                error('Operation not supported');
        end

    % ------------------- NEW: Capture Buffer Mode (channel 30) --------------
    % ctrl string selects variant:
    %  - contains 'pertrig' => OneShot + SAMPpertrig (one sample per falling-edge trigger)
    %  - otherwise          => Continuous capture at CAPTURERATE
    case 30
        inst = smdata.inst(ic(1)).data.inst;

        % Aux-based TTL (AUX OUT 1 -> TRIG IN) for per-trigger mode
        auxCh   = 0;        % Aux Out 1 => j=0
        vHigh   = 3.3;      % TTL-high-ish
        vLow    = 0.0;      % TTL-low
        dwell_s = 0.005;    % 5 ms dwell for robust edge

        pertrig = (nargin >= 4) && ~isempty(ctrl) && contains(lower(ctrl),'pertrig');

        switch ic(3)
            case 3  % configure & arm
                fprintf(inst, '*CLS');

                % Choose capture config & length (R,theta here; change to XY/XYRT as needed)
                fprintf(inst, 'CAPTURECFG 2');          % 2 = R,theta
                fprintf(inst, 'CAPTURELEN 4096');       % even, up to 4096 kB

                if pertrig
                    % OneShot + one-sample-per-trigger (falling-edge on TRIG IN)
                    fprintf(inst, 'CAPTURESTART ONE, SAMPpertrig');
                    % Prime AUX HIGH so the next LOW creates a falling edge
                    sr860_aux_set(inst, auxCh, vHigh);
                else
                    % Continuous capture; rate must be set (case 5 can set exact rate)
                    if ~isfield(smdata.inst(ic(1)).data,'sampint') || isempty(smdata.inst(ic(1)).data.sampint)
                        % Default to a conservative divider n=10 if not set elsewhere
                        fprintf(inst, 'CAPTURERATE 10');
                        smdata.inst(ic(1)).data.sampint = 1/1000; % ~1 kHz example
                    end
                    fprintf(inst, 'CAPTURESTART CONT, IMM');
                end

                smdata.inst(ic(1)).data.currsamp_real  = 0;
                smdata.inst(ic(1)).data.currsamp_phase = 0;
                smdata.inst(ic(1)).data.RampPts = 0;
                val = [];

            case 2  % push one sample (only meaningful for pertrig)
                if ~pertrig
                    % In continuous mode, pushing one sample doesn't apply; just wait sampint
                    pause(max(0.001, smdata.inst(ic(1)).data.sampint));
                else
                    % Generate one falling edge on TRIG IN via AUX: HIGH->LOW->HIGH
                    sr860_aux_set(inst, auxCh, vLow);  pause(dwell_s);
                    sr860_aux_set(inst, auxCh, vHigh); pause(dwell_s);
                end
                val = [];

            case 6  % start (continuous helper)
                if pertrig
                    fprintf(inst, 'CAPTURESTART ONE, SAMPpertrig');
                    sr860_aux_set(inst, auxCh, vHigh);
                else
                    fprintf(inst, 'CAPTURESTART CONT, IMM');
                end
                val = [];

            case 0  % stop & read everything available (binary, fast)
                fprintf(inst, 'CAPTURESTOP');
                navail_bytes = query(inst, 'CAPTUREBYTES?', '%s\n', '%d');
                if isempty(navail_bytes) || isnan(navail_bytes) || navail_bytes < 8
                    val = [];
                    return;
                end
                % For (R,theta): 8 bytes/sample (2 * float32)
                npts_to_read = floor(navail_bytes / 8);

                % Read ceil((npts_to_read * 8) / 1024 / 256) kB => ceil(npts*2/256)
                fprintf(inst, 'CAPTUREGET? 0, %g', ceil(npts_to_read*2/256));
                raw = readbinblock(inst,'single');

                if numel(raw) >= 2*npts_to_read
                    R  = raw(1:2:2*npts_to_read-1);
                    th = raw(2:2:2*npts_to_read);
                    val.magnitude = R.';                     % row vectors
                    val.phase     = th.';
                    val.x         = (R.*cosd(th)).';
                    val.y         = (R.*sind(th)).';
                else
                    val = [];
                end

                smdata.inst(ic(1)).data.currsamp_real  = smdata.inst(ic(1)).data.currsamp_real  + npts_to_read;
                smdata.inst(ic(1)).data.currsamp_phase = smdata.inst(ic(1)).data.currsamp_phase + npts_to_read;
                smdata.inst(ic(1)).data.RampPts = 0;

            case 4  % set planned points (like K2450 style)
                smdata.inst(ic(1)).data.RampPts = smdata.inst(ic(1)).datadim(ic(2));
                val = [];

            case 5  % set planned points AND configure sample rate/length
                % (Reopen only if you really need buffer changes to take effect on some drivers)
                fclose(inst);
                inst.InputBufferSize = 1e6;   % 1 MB
                inst.Timeout = 20;
                fopen(inst);

                smdata.inst(ic(1)).datadim(ic(2)) = val;   % planned points
                smdata.inst(ic(1)).data.RampPts   = val;

                % CAPTURERATE based on requested 'rate' (Hz), respecting CAPTURERATEMAX?
                maxrate = query(inst, 'CAPTURERATEMAX?', '%s\n', '%g');
                if isempty(maxrate) || isnan(maxrate)
                    error('CAPTURERATEMAX? failed');
                end
                if abs(rate) > maxrate
                    warning('Requested rate > max; using maxrate.');
                    rate = maxrate;
                end
                n = ceil(log2(maxrate/abs(rate)));
                n = max(0, min(20, n));
                actual_rate = maxrate/(2^n);
                fprintf(inst, 'CAPTURERATE %i', n);
                smdata.inst(ic(1)).data.sampint = 1/actual_rate;
                smdata.inst(ic(1)).data.RampTime = (val - 1) / actual_rate;

                % Size the buffer (kB, even). For (R,theta): 8 B/pt => bytes = 8*val
                kb = 2 * ceil( (8*val)/1024 / 2 );  % round up to even kB
                kb = min(max(kb, 2), 4096);         % clamp to [2,4096], even
                fprintf(inst, 'CAPTURELEN %u', kb);

            otherwise
                error('SR860 buffer mode: Operation not supported (case %d)', ic(3));
        end

    % ----------------------------- Generic set/get ---------------------------
    otherwise
        switch ic(3) % action
            case 1 % set
                if ic(2)==17
                    val = SR860sensindex(val);
                elseif ic(2)==18
                    val = SR860tauindex(val);
                elseif ic(2)==24
                    if val~=0 && val~=1
                        val=0;
                    end
                end
                % Aux outputs need comma form
                if any(ic(2)==[11 12 13 14])
                    fprintf(smdata.inst(ic(1)).data.inst, sprintf('%s, %f', cmds{ic(2)}, val));
                else
                    fprintf(smdata.inst(ic(1)).data.inst, sprintf('%s %f', cmds{ic(2)}, val));
                end
            case 0 % get
                val = query(smdata.inst(ic(1)).data.inst, sprintf('%s? %s',...
                    cmds{ic(2)}(1:4), cmds{ic(2)}(5:end)), '%s\n', '%f');
                if ic(2)==17
                    val = SR860sensvalue(val);
                elseif ic(2)==18
                    val = SR860tauvalue(val);
                end
            otherwise
                error('Operation not supported');
        end
end

% =========================== Local helpers (end) =============================
function sr860_aux_set(inst, j, v)
% Robust AUX setter (tries AUXV/AUXO)
v = max(min(v, 10.5), -10.5);
ok = true;
try
    fprintf(inst, sprintf('AUXV %d, %g', j, v));
catch
    ok = false;
end
if ~ok
    fprintf(inst, sprintf('AUXO %d, %g', j, v));
end

function val = SR860sensvalue(sensindex)
x = [2e-9 5e-9 10e-9];
sensvals = [x 1e1*x 1e2*x 1e3*x 1e4*x 1e5*x 1e6*x 1e7*x 1e8*x 1e9*x];
val = sensvals(sensindex+1);

function sensindex = SR860sensindex(sensval)
x = [2e-9 5e-9 10e-9];
sensvals = [x 1e1*x 1e2*x 1e3*x 1e4*x 1e5*x 1e6*x 1e7*x 1e8*x 1e9*x];
sensindex = find(sensvals >= sensval,1)-1;

function val = SR860tauvalue(tauindex)
x = [10e-6 30e-6];
tauvals = [x 1e1*x 1e2*x 1e3*x 1e4*x 1e5*x 1e6*x 1e7*x 1e8*x 1e9*x];
val = tauvals(tauindex+1);

function tauindex = SR860tauindex(tauval)
x = [10e-6 30e-6];
tauvals = [x 1e1*x 1e2*x 1e3*x 1e4*x 1e5*x 1e6*x 1e7*x 1e8*x 1e9*x];
tauindex = find(tauvals >= tauval,1)-1;
