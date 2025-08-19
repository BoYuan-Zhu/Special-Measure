function [val, rate] = smcSR830_spm(ic, val, rate, ctrl)
% smcSR830_spm  - Stanford SR830 controller (with buffered trace support)
% [val, rate] = smcSR830_spm(ic, val, rate, ctrl)
%
% ic: [inst_index, channel, op]
%   channel:
%     1: X, 2: Y, 3: R, 4: Theta, 5: FREQ, 6: SLVL (ref amplitude)
%     7..10: OAUX 1..4 (Aux output), 11..14: AUXV 1..4 (Aux input)
%     15,16: stored data trace (DATA1/DATA2) - length determined by datadim
%     17: SENS (sensitivity), 18: OFLT (time constant)
% op:
%   0: get, 1: set
%
% ctrl (optional):
%   - contains 'sync' => use triggered sample rate (SRAT 14)
%
% The binary trace format is SR830's 32-bit packed big-endian words:
%   [0, exponent, mantissa_hi, mantissa_lo]
% Value = int16([mantissa_hi, mantissa_lo]) * 2^(exponent - 124)
%
% Key fix:
%   Instrument fread does NOT support '=>uint32'. Read 'uint32' (returns double)
%   then cast to uint32 before bit operations.

global smdata;

% Command templates per channel index (for simple get/set)
cmds = {'OUTP 1', 'OUTP 2', 'OUTP 3', 'OUTP 4', 'FREQ', 'SLVL', ...
        'OAUX 1', 'OAUX 2', 'OAUX 3', 'OAUX 4', ...
        'AUXV 1', 'AUXV 2', 'AUXV 3', 'AUXV 4', ...
        '', '', 'SENS', 'OFLT', 'SYNC'};

switch ic(2)
    case {15, 16}  % ===== Stored data buffers (DATA1/DATA2) =====
        switch ic(3)
            case 0  % ------- GET: return exactly npts points -------
                npts = smdata.inst(ic(1)).datadim(ic(2), 1);
                if ~isfinite(npts) || npts <= 0
                    error('SR830: buffer length (datadim) is 0. Configure via op=5 first.');
                end

                % Instrument handle and basic I/O settings
                inst = smdata.inst(ic(1)).data.inst;

                % Ensure big enough input buffer
                try
                    ibs  = get(inst, 'InputBufferSize');
                    need = npts*4 + 256;   % 4 bytes/sample + margin
                    if ibs < need
                        set(inst, 'InputBufferSize', need);
                    end
                catch
                    % ignore if property not supported
                end

                % Ensure big-endian byte order for SR830 binary output
                try
                    if isprop(inst, 'ByteOrder'), set(inst, 'ByteOrder', 'bigEndian'); end
                catch
                end

                % Wait until display buffer has enough points
                curr0    = smdata.inst(ic(1)).data.currsamp;
                sampint  = smdata.inst(ic(1)).data.sampint;
                if ~isfinite(sampint) || sampint <= 0, sampint = 0.01; end
                timeout_s = max(5, 2.0 * npts * sampint);
                tStart = tic;
                while true
                    navail = query(inst, 'SPTS?', '%s\n', '%d');
                    if navail >= curr0 + npts
                        break;
                    end
                    if toc(tStart) > timeout_s
                        error('SR830 timeout: have %d, need %d (curr=%d).', navail, curr0+npts, curr0);
                    end
                    pause(0.1);
                end

                % Request the block from display buffer using TRCL? (binary 4 bytes/value)
                % ic(2)-14 maps 15->1 (DATA1), 16->2 (DATA2)
                fprintf(inst, 'TRCL? %d, %d, %d', [ic(2)-14, curr0, curr0+npts]);
                pause(0.05);

                % --- Read as uint32 words; returns DOUBLE; convert to UINT32 right away ---
                [output_dbl, count] = fread(inst, npts, 'uint32');  % respects ByteOrder
                if count ~= npts
                    error('SR830 TRCL short read: %d/%d values.', count, npts);
                end
                output_u32 = uint32(output_dbl);  % force to uint32 for bit operations

                % Unpack 32-bit words:
                % bytes (big-endian): [0, exponent, mantissa_hi, mantissa_lo]
                % - Extract exponent (2nd byte) and 16-bit signed mantissa
                exp8 = uint32(bitand(bitshift(output_u32, -16), uint32(255)));    % 2nd byte
                lo16 = uint16(bitand(output_u32, uint32(65535)));                 % low 16 bits
                mant = typecast(lo16, 'int16');                                    % signed mantissa

                % Convert to double values
                val = double(mant) .* (2 .^ (double(exp8) - 124));

                % Advance read pointer
                smdata.inst(ic(1)).data.currsamp = curr0 + npts;

            case 3  % ------- START (trigger acquisition) -------
                if ~strcmp(smdata.inst(ic(1)).data.state, 'triggered')
                    fprintf(smdata.inst(ic(1)).data.inst, 'STRT');
                    smdata.inst(ic(1)).data.state = 'triggered';
                end

            case 4  % ------- ARM (reset buffers, keep npts) -------
                if ~strcmp(smdata.inst(ic(1)).data.state, 'armed')
                    fprintf(smdata.inst(ic(1)).data.inst, 'REST');  % reset display buffers
                    smdata.inst(ic(1)).data.currsamp = 0;
                    % keep datadim(15:16,1) as configured
                    smdata.inst(ic(1)).data.state = 'armed';
                    pause(0.1);
                end

            case 5  % ------- CONFIG (set npts & rate, set SRAT) -------
                % Decide SRAT code
                if exist('ctrl', 'var') && ~isempty(strfind(ctrl, 'sync'))
                    % Triggered-sample-rate mode per SR830 manual
                    n = 14;          % SRAT 14 => triggered
                    % Do not change 'rate' in sync mode (caller may track its own)
                else
                    % Map target 'rate' (Hz) to discrete SR830 SRAT code (0..13)
                    % SR830 supports rates: 2^(-4) .. 2^(9) Hz = [0.0625 .. 512]
                    % n = round(log2(rate)) + 4  (round to nearest supported)
                    n = round(log2(max(rate, eps))) + 4;
                    n = max(0, min(13, n));
                    rate = 2^(n - 4);   % effective rate after quantization
                end

                % Configure: reset buffers, one-shot send, trigger starts acq, set SRAT
                fprintf(smdata.inst(ic(1)).data.inst, 'REST; SEND 0; TSTR 1; SRAT %i', n);
                pause(0.1);

                % Book-keeping
                smdata.inst(ic(1)).data.currsamp      = 0;
                smdata.inst(ic(1)).data.sampint       = 1 / max(rate, eps);
                smdata.inst(ic(1)).datadim(15:16, 1)  = val;  % npts for both data channels
                smdata.inst(ic(1)).data.state         = 'reset';

            otherwise
                error('SR830: Operation not supported for stored data channel.');
        end

    otherwise  % ===== Live parameters: set/get via simple SCPI =====
        switch ic(3)
            case 1  % ------- SET -------
                if ic(2) == 17
                    val = SR830sensindex(val);   % map sensitivity value -> index code
                elseif ic(2) == 18
                    val = SR830tauindex(val);    % map tau value -> index code
                end
                % Form like "FREQ 1000", "OUTP 1 0.3", etc.
                fprintf(smdata.inst(ic(1)).data.inst, sprintf('%s %f', cmds{ic(2)}, val));

            case 0  % ------- GET -------
                % Build query like "OUTP? 1", "FREQ?", "SENS?", ...
                q = sprintf('%s? %s', cmds{ic(2)}(1:4), cmds{ic(2)}(5:end));
                q = strtrim(q);
                val = query(smdata.inst(ic(1)).data.inst, q, '%s\n', '%f');

                % Post-map index -> value for sensitivity / tau
                if ic(2) == 17
                    val = SR830sensvalue(val);
                elseif ic(2) == 18
                    val = SR830tauvalue(val);
                end

            otherwise
                error('SR830: Operation not supported.');
        end
end

% ===== Helpers: SR830 sensitivity / time-constant maps =====
function v = SR830sensvalue(idx)
% Convert sensitivity index -> physical value (A/V or V)
x = [2e-9 5e-9 10e-9];
sensvals = [x 1e1*x 1e2*x 1e3*x 1e4*x 1e5*x 1e6*x 1e7*x 1e8*x 1e9*x];
v = sensvals(idx+1);

function idx = SR830sensindex(v)
% Convert sensitivity value -> nearest index code
x = [2e-9 5e-9 10e-9];
sensvals = [x 1e1*x 1e2*x 1e3*x 1e4*x 1e5*x 1e6*x 1e7*x 1e8*x 1e9*x];
idx = find(sensvals >= v, 1) - 1;

function v = SR830tauvalue(idx)
% Convert time-constant index -> seconds
x = [10e-6 30e-6];
tauvals = [x 1e1*x 1e2*x 1e3*x 1e4*x 1e5*x 1e6*x 1e7*x 1e8*x 1e9*x];
v = tauvals(idx+1);

function idx = SR830tauindex(v)
% Convert tau value -> nearest index code
x = [10e-6 30e-6];
tauvals = [x 1e1*x 1e2*x 1e3*x 1e4*x 1e5*x 1e6*x 1e7*x 1e8*x 1e9*x];
idx = find(tauvals >= v, 1) - 1;
