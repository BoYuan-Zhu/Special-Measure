function [val, rate] = smcSR860_Ramp(ic, val, rate, ctrl)
% [val, rate] = smcSR860(ic, val, rate, ctrl)
% ctrl: sync (each sample triggered)
%       trig external trigger starts acq.
% 21: Auto Scale
%-------------------channel command-------------------------
% 1:OUTP 0=X  2:OUTP 1=Y  3:OUTP 2=R  4:OUTP 3=theta  5:FREQ=frequency
% 6:SLVL=sine out amplitude  7:OAUX 0=aux input 1 voltage  
% 8:OAUX 1=aux input 2 voltage  9:OAUX 2=aux input 3 voltage 
% 10:OAUX 3=aux input 4 voltage  11: AUXV 0=set aux 1
% 12: AUXV 1=set aux 2  13:AUXV 2=set aux 3  14: AUXV 3=set aux 4
% 15, 16: store data  17:SCAL=set the sensitivity(see manual)
% 18:OFLT=set time constant (see manual) 19:'SYNC'=
% 20:SOFF=set the sine out dc level  21: Auto phase range and sensitivity
% 22:OUTP 8=Xnoise  23:OUTP 9=Ynoise  24:IVMD=set input to voltage/current
%------------------------Notice-----------------------------
% While in voltage mode (IVMD 0), OUTP 0,1,2,3 are all parameters of
% voltage. While in current mode (IVMD 1), OUTP 0,1,2,3 are all
% parameters of current

global smdata;

cmds = {'OUTP 0', 'OUTP 1', 'OUTP 2', 'OUTP 3', 'FREQ', 'SLVL', ...
    'OAUX 0', 'OAUX 1', 'OAUX 2', 'OAUX 3', 'AUXV 0', 'AUXV 1', 'AUXV 2', 'AUXV 3' ...
    ,'','','SCAL', 'OFLT', 'SYNC','SOFF','','OUTP 8','OUTP 9','IVMD','HARM'};

switch ic(2) % Channel
    case 21 %Auto phase Range and sensitivity
        fprintf(smdata.inst(ic(1)).data.inst,'APHS');
        fprintf(smdata.inst(ic(1)).data.inst,'ARNG');
        fprintf(smdata.inst(ic(1)).data.inst,'ASCL');
        val = 1;
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
                % If npts larger than 4000, need to extract raw data twice
                % rawdata = [];
                % if npts/2048 > 1
                %     fprintf(smdata.inst(ic(1)).data.inst, 'CAPTURESTOP');
                %     for ii = 1:ceil(npts/2048)
                %         if ii == ceil(npts/2048)
                %             fprintf(smdata.inst(ic(1)).data.inst, 'CAPTUREGET? %g, %g',2048*(ii-1)*4/256,ceil(npts*4/256));
                %             rawdata = [rawdata;readbinblock(smdata.inst(ic(1)).data.inst,'single')];
                %         else
                %             fprintf(smdata.inst(ic(1)).data.inst, 'CAPTUREGET? %g, %g',2048*(ii-1)*4/256,31+2048*(ii-1)*4/256);
                %             rawdata = [rawdata;readbinblock(smdata.inst(ic(1)).data.inst,'single')];
                %         end
                %     end
                % else
                % Stop capture
                fprintf(smdata.inst(ic(1)).data.inst, 'CAPTURESTOP;CAPTUREGET? 0, %g',ceil(npts*2/256));
                rawdata = readbinblock(smdata.inst(ic(1)).data.inst,'single');
                % end

                if ic(2) == 15
                    % For in-phase X
                    val = rawdata(1:2:npts*2-1).*cosd(rawdata(2:2:npts*2));
                    smdata.inst(ic(1)).data.currsamp_real = smdata.inst(ic(1)).data.currsamp_real + npts;
                elseif ic(2) == 16
                    % For theta
                    val = rawdata(2:2:npts*2);
                    smdata.inst(ic(1)).data.currsamp_phase = smdata.inst(ic(1)).data.currsamp_phase +npts;
                end
                
        %%
        % Add this case to the SR860 driver switch statement, after case 16

       case 17 % Buffer mode
        inst = smdata.inst(ic(1)).data.inst;
        
        switch ic(3)
            case 3  % one-time configure & arm buffer
                % Stop any ongoing capture
                fprintf(inst, 'CAPTURESTOP');
                
                % Configure for continuous buffering
                % Set buffer size to maximum (4096 kb)
                % Capture both R and theta (mode 2)
                fprintf(inst, 'CAPTURECFG 2;CAPTURELEN 4096');
                
                % Set a reasonable default sample rate if not already configured
                if ~isfield(smdata.inst(ic(1)).data, 'sampint') || isempty(smdata.inst(ic(1)).data.sampint)
                    % Use a moderate sample rate (rate index 10 = ~1kHz for most time constants)
                    fprintf(inst, 'CAPTURERATE 10');
                    smdata.inst(ic(1)).data.sampint = 1/1000; % approximate
                end
                
                % Reset buffer tracking
                smdata.inst(ic(1)).data.currsamp_real = 0;
                smdata.inst(ic(1)).data.currsamp_phase = 0;
                smdata.inst(ic(1)).data.RampPts = 0;
                
                val = []; % nothing to return
                
            case 2  % single-shot: trigger one sample into buffer
                % For SR860, we start capture for a brief moment to get one sample
                fprintf(inst, 'CAPTURESTART 0, 0');
                
                % Wait for at least one sample
                pause(smdata.inst(ic(1)).data.sampint * 1.5);
                
                val = []; % no data returned here
                
            case 0  % read out all available points
                % Check how many bytes are available
                navail_bytes = query(inst, 'CAPTUREBYTES?', '%s\n', '%d');
                navail_points = navail_bytes / 8; % 8 bytes per complex sample (R+theta)
                
                if navail_points < 1
                    % Nothing to read
                    val = [];
                    return;
                end
                
                % Stop capture to read data
                fprintf(inst, 'CAPTURESTOP');
                
                % Read available data
                npts_to_read = floor(navail_points);
                fprintf(inst, 'CAPTUREGET? 0, %g', ceil(npts_to_read * 2 / 256));
                rawdata = readbinblock(inst, 'single');
                
                % Parse the data - rawdata contains interleaved R and theta values
                if length(rawdata) >= 2 * npts_to_read
                    % Extract R values (odd indices) and theta values (even indices)
                    R_vals = rawdata(1:2:2*npts_to_read-1);
                    theta_vals = rawdata(2:2:2*npts_to_read);
                    
                    % Return as structure similar to K2450 format
                    val.magnitude = R_vals.';  % row vector
                    val.phase = theta_vals.';  % row vector
                    val.x = R_vals.' .* cos(theta_vals.' * pi/180);  % convert to X
                    val.y = R_vals.' .* sin(theta_vals.' * pi/180);  % convert to Y
                else
                    val = [];
                end
                
                % Update sample counters
                smdata.inst(ic(1)).data.currsamp_real = smdata.inst(ic(1)).data.currsamp_real + npts_to_read;
                smdata.inst(ic(1)).data.currsamp_phase = smdata.inst(ic(1)).data.currsamp_phase + npts_to_read;
                
                % Reset buffer tracking
                smdata.inst(ic(1)).data.RampPts = 0;
                
            case 4  % set planned points (similar to K2450 case 4)
                smdata.inst(ic(1)).data.RampPts = smdata.inst(ic(1)).datadim(ic(2));
                val = [];
                
            case 5  % set planned points and configure sample rate
                % Set buffer size and timeout like K2450
                fclose(inst);
                inst.InputBufferSize = 1e6;   % 1 MB buffer
                inst.Timeout = 20;            % 20 second timeout
                fopen(inst);
                
                % Configure planned points
                smdata.inst(ic(1)).datadim(ic(2)) = val;
                smdata.inst(ic(1)).data.RampPts = val;
                
                % Calculate and set appropriate sample rate
                if nargin > 2 && ~isempty(rate)
                    maxrate = query(inst, 'CAPTURERATEMAX?', '%s\n', '%g');
                    
                    if abs(rate) > maxrate
                        warning('Requested rate too high, using maximum rate');
                        rate = maxrate;
                    end
                    
                    % Find appropriate rate index
                    n = ceil(log2(maxrate / abs(rate)));
                    n = max(0, min(20, n)); % clamp to valid range
                    actual_rate = maxrate / (2^n);
                    
                    fprintf(inst, 'CAPTURERATE %i', n);
                    smdata.inst(ic(1)).data.sampint = 1 / actual_rate;
                    smdata.inst(ic(1)).data.RampTime = (val - 1) / actual_rate;
                else
                    % Use existing sample interval
                    if isfield(smdata.inst(ic(1)).data, 'sampint')
                        smdata.inst(ic(1)).data.RampTime = (val - 1) * smdata.inst(ic(1)).data.sampint;
                    end
                end
                
            case 6  % start continuous capture
                fprintf(inst, 'CAPTURESTART 0, 0');
                val = [];
                
            otherwise
                error('SR860 driver: Operation not supported for buffer mode (case 17)');
        end
        

        %%

                
            case 3
                fprintf(smdata.inst(ic(1)).data.inst, 'CAPTURESTART 0, 0;');

            case 4
                % fprintf(smdata.inst(ic(1)).data.inst, 'REST');
                pause(.1); %needed to give instrument time before next trigger.
                if ic(2) == 15
                    smdata.inst(ic(1)).data.currsamp_real = 0;
                elseif  ic(2) == 16
                    smdata.inst(ic(1)).data.currsamp_phase = 0;
                end
                % anything much shorter leads to delays.
                
            case 5
                % maxrate depends on time constant
                % 1 µs to 10 µs 1.25 MHz 
                % 30 µs 625 kHz 
                % 100 µs 325 kHz
                % 300 µs 156.25 kHz
                % 1 ms 78.125 kHz
                % 3 ms to 10 ms 39.0625 kHz
                % 30 ms 9765.62 Hz
                % 100 ms 2441.41 Hz
                % 300 ms 1220.7 Hz
                % 1 s 305.18 Hz
                % 3 s to 30 ks 152.59 Hz
                if val > 8192
                    error('Max sample points for SR860 is 8192');
                end

                maxrate = query(smdata.inst(ic(1)).data.inst,'CAPTURERATEMAX?','%s\n','%g');

                % if nargin > 4 && strfind(ctrl, 'sync')
                %     n = 14;
                % else
                if abs(rate) > maxrate
                    error('Change time constant to get faster sampling rate')
                else
                    n = ceil(log2(maxrate./abs(rate)));
                    rate = maxrate./(2^(n));
                    if n > 20
                        error('Samplerate not supported by SR860, the minimum rate in the time constant is %g', maxrate./2^20);
                    elseif  n < 0
                        error('Samplerate not supported by SR860, the maximum rate in the time constant is %g', maxrate);
                    end
                end
                
                % fprintf(smdata.inst(ic(1)).data.inst, 'REST; SEND 1; TSTR 1; SRAT %i', n);
                % Set the buffer size to 4096 kb, meaning the maximum data
                % point for each channel is 256 k.
                % fprintf(smdata.inst(ic(1)).data.inst, ['CAPTURESTOP;' ...
                %     'CAPTURECFG 3;CAPTURERATE %i;CAPTURELEN 1000'],n);
                % Capture R and theta
                fprintf(smdata.inst(ic(1)).data.inst, ['CAPTURESTOP;' ...
                    'CAPTURECFG 2;CAPTURERATE %i;CAPTURELEN 4096'],n);
                %else
                %    fprintf(smdata.inst(ic(1)).data.inst, 'REST; SEND 1; TSTR 0; SRAT %i', n);
                %end
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
                % for Aux outputs have to put a comma
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

function val = SR860sensvalue(sensindex)
% converts an index to the corresponding sensitivity value for the SR860
% lockin.
x = [2e-9 5e-9 10e-9];
sensvals = [x 1e1*x 1e2*x 1e3*x 1e4*x 1e5*x 1e6*x 1e7*x 1e8*x 1e9*x];
val = sensvals(sensindex+1);

function sensindex = SR860sensindex(sensval)
% converts a sensitivity to a corresponding index that can be sent to the
% SR860 lockin.  rounds up (sens = 240 will become 500)
x = [2e-9 5e-9 10e-9];
sensvals = [x 1e1*x 1e2*x 1e3*x 1e4*x 1e5*x 1e6*x 1e7*x 1e8*x 1e9*x];
sensindex = find(sensvals >= sensval,1)-1;

function val = SR860tauvalue(tauindex)
% converts an index to the corresponding sensitivity value for the SR860
% lockin.
x = [10e-6 30e-6];
tauvals = [x 1e1*x 1e2*x 1e3*x 1e4*x 1e5*x 1e6*x 1e7*x 1e8*x 1e9*x];
val = tauvals(tauindex+1);

function tauindex = SR860tauindex(tauval)
% converts a time constant to a corresponding index that can be sent to the
% SR860 lockin.  rounds up (tau = 240 will become 300)
x = [10e-6 30e-6];
tauvals = [x 1e1*x 1e2*x 1e3*x 1e4*x 1e5*x 1e6*x 1e7*x 1e8*x 1e9*x];
tauindex = find(tauvals >= tauval,1)-1;


        
