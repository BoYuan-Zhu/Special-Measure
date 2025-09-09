% ===================== test_SR860_self_measure.m  (SR860 self-measurement with buffered capture) ======================
% This script uses SR860's own sine output as the signal to be measured
% Modified for: XYRT buffer + Aux0  mode
% Uses GPIB communication and self-triggering via AUX out -> TRIG in
% Implements buffered data acquisition with per-trigger sampling

clear all; close all; instrreset;
global smaux smscan smdata;

%% -------------------- User Configuration --------------------
USE_PERTRIG = true;      % true = AUX->TRIG (one-sample-per-trigger), false = continuous CAPTURERATE
AUX_CH      = 0;         % Aux Out 0 -> TRIG IN  (wire BNC from Aux Out 0 to TRIG IN)
AUX_VHIGH   = 5;         % High level for TTL-like (safe)
AUX_VLOW    = 0.0;       % Low level
AUX_DWELL   = 0.005;     % sec between edges

% SR860 measurement parameters
SINE_FREQ_START = 100;    % Starting frequency (Hz)
SINE_FREQ_STOP  = 120;    % Ending frequency (Hz) - smaller range for testing
SINE_AMPLITUDE  = 0.01;    % Sine output amplitude (V)
TIME_CONSTANT   = 0.01;   % Lock-in time constant (s)

%% -------------------- Meta & paths --------------------
smscan.comments = 'SR860 self-measurement: XYRT buffer capture with Aux0 self-trigger, per-sample readback.';
smscan.name = 'SR860_XYRT_buffer_trigger';

% === Adjust these paths ===
smaux.datadir     = 'C:\Users\wanglabadmin\Desktop\Special-Measure-main\test';
smaux.pptsavefile = smaux.datadir;    % folder or a .ppt/.pptx path
smaux.pptMode     = 'ppt';            % 'ppt' or 'pptx'

%% -------------------- GPIB --------------------
GPIB_BOARD      = 'ni';
BOARD_NUM       = 0;
SR860_GPIB      = 5;    % SR860 GPIB address

%% -------------------- Dummy instrument (for outer loop) --------------------
smloadinst('test');
smaddchannel('test','CH1','dummy');
smaddchannel('test','CH2','count');

%% -------------------- SR860 --------------------
% Your SR860 control function must be @smcSR860_Ramp_TTLbuf with XYRT buffer channels
try
    ind_sr = smloadinst('SR860', [], GPIB_BOARD, BOARD_NUM, SR860_GPIB);
    smopen(ind_sr);
    smdata.inst(ind_sr).name    = 'SR860';
    smdata.inst(ind_sr).cntrlfn = @smcSR860_Ramp_TTLbuf;

    % Live channels for setup and monitoring
    smaddchannel('SR860','X    ',      'X_live',    [-Inf, Inf, Inf, 1]);
    smaddchannel('SR860','Y    ',      'Y_live',    [-Inf, Inf, Inf, 1]);
    smaddchannel('SR860','FREQ ',      'Freq',      [1, 1e6, 1, 1]);
    smaddchannel('SR860','VREF ',      'SineAmp',   [0.004, 5, 0.5, 1]);  
    smaddchannel('SR860','TAU  ',      'TimeConst', [1e-6, 30e3, 1, 1]);
    smaddchannel('SR860','OUT1 ',      'Aux1_Set',  [-10, 10, 0.5, 1]); 

    % ===== XYRT Buffered channels (SR860 capture readback) =====
    smaddchannel('SR860', 'BUF  ',  'SR860_BUF');      % Main buffer control channel
    smaddchannel('SR860', 'BUF_X',  'SR860_Xbuf');     % buffered X
    smaddchannel('SR860', 'BUF_Y',  'SR860_Ybuf');     % buffered Y
    smaddchannel('SR860', 'BUF_R',  'SR860_Rbuf');     % buffered R magnitude    
    smaddchannel('SR860', 'BUF_T',  'SR860_Thbuf');    % buffered theta
catch err
    fprintf(['*ERROR* SR860: ' err.identifier ': ' err.message '\n']);
end

%% -------------------- Initial SR860 Setup --------------------
try
    % Set up SR860 for self-measurement
    smset('SineAmp', SINE_AMPLITUDE);    % Set sine output amplitude
    smset('TimeConst', TIME_CONSTANT);   % Set time constant
    smset('Freq', SINE_FREQ_START);      % Set initial frequency
    
    % Set input configuration (adjust as needed for your setup)
    inst = smdata.inst(ind_sr).data.inst;
    fprintf(inst, 'ISRC 0');          % A input (single-ended)
    fprintf(inst, 'IGND 0');          % Float input ground
    fprintf(inst, 'ICPL 0');          % AC coupling
    fprintf(inst, 'ILIN 0');          % No line notch filter
    
    % Set sensitivity appropriately for the sine amplitude
    if SINE_AMPLITUDE >= 1.0
        fprintf(inst, 'SCAL 16');     % 1 V full scale
    elseif SINE_AMPLITUDE >= 0.5
        fprintf(inst, 'SCAL 15');     % 500 mV full scale  
    else
        fprintf(inst, 'SCAL 14');     % 200 mV full scale
    end
    
    fprintf('SR860 configured for self-measurement.\n');
    fprintf('Sine amplitude: %.3f V, Time constant: %.3f s\n', SINE_AMPLITUDE, TIME_CONSTANT);
    
catch err
    fprintf(['*ERROR* SR860 setup: ' err.identifier ': ' err.message '\n']);
end

%% -------------------- XYRT Buffer Trigger Configuration --------------------
% Modified scan definition for XYRT buffer capture mode
BUFFER_SAMPLES   = 11;                 % Number of buffer samples per measurement cycle
TRIGGER_INTERVAL = 0.01;                % Time between triggers (s)
TARGET_RATE      = 1000;               % Target capture rate (Hz)

% Modified inner loop - now for buffer trigger control instead of frequency sweep
innerLoopChannel  = 'dummy';           % Use dummy channel (no actual sweep)
ramptimeInnerLoop = BUFFER_SAMPLES * TRIGGER_INTERVAL;  % Total time for buffer acquisition
npointsInnerLoop  = BUFFER_SAMPLES;    % Number of buffer samples
minInnerLoop      = 0;                 % Dummy range
maxInnerLoop      = BUFFER_SAMPLES-1;  % Dummy range

% SR860 XYRT buffered channels - will be read in outer loop after buffer capture
myChannel = { 'SR860_Xbuf', 'SR860_Ybuf', 'SR860_Rbuf', 'SR860_Thbuf' };

outerLoopChannel = 'count';            % Use counter for measurement cycles
npointsOuterLoop = 1;                  % Number of measurement cycles
minOuterLoop     = 1;
maxOuterLoop     = npointsOuterLoop;

% --- bookkeeping
tic;
if ~isfield(smscan, 'consts'); smscan.consts = struct('set', {}, 'setchan', {}, 'val', {}); end
smscan = UpdateConstants(smscan);

% === build disp to match getchan ===
smscan.saveloop = 2;
smscan.disp = struct([]);
for k = 1:numel(myChannel)
    smscan.disp(k).loop    = 2;     % data are acquired in loop 2
    smscan.disp(k).channel = k;     % index within getchan of loop 2
    smscan.disp(k).dim     = 1;     % 1D trace
end

% === loops ===
smscan.loops = struct;
smscan.loops(1).npoints  = npointsInnerLoop;
smscan.loops(1).rng      = [minInnerLoop maxInnerLoop];
smscan.loops(1).getchan  = {};                        % fast mode: no get in inner loop
smscan.loops(1).setchan  = {innerLoopChannel};
smscan.loops(1).ramptime = TRIGGER_INTERVAL;          % Time per trigger
smscan.loops(1).waittime = 0.001;                     % Minimal wait

smscan.loops(2).npoints  = npointsOuterLoop;
smscan.loops(2).rng      = [minOuterLoop maxOuterLoop];
smscan.loops(2).getchan  = myChannel;                 % XYRT buffer channels
smscan.loops(2).setchan  = {outerLoopChannel};
smscan.loops(2).ramptime = 0;
smscan.loops(2).waittime = 0.1;                       % Wait between cycles

%% -------------------- SR860 XYRT buffer config/arming --------------------
% Configure SR860 for XYRT buffer capture with self-trigger
if USE_PERTRIG
    cap_mode = 'pertrig';
else
    cap_mode = 'cont';
end

fprintf('Configuring SR860 XYRT buffer capture...\n');
fprintf('Mode: %s, Samples: %d, Target rate: %d Hz\n', cap_mode, BUFFER_SAMPLES, TARGET_RATE);

% Configure buffer using the driver's CONFIG operation (ic(3) = 5)
try
    [~, actual_rate] = smdata.inst(ind_sr).cntrlfn([ind_sr, 22, 5], BUFFER_SAMPLES, TARGET_RATE, cap_mode);
    fprintf('Buffer configured. Actual rate: %.2f Hz\n', actual_rate);
catch err
    fprintf('*ERROR* Buffer config: %s\n', err.message);
end

%% ---------- File numbering ----------
myFileList = ls(smaux.datadir);
myFileListSize = size(myFileList);
myDataFileNumbers = [];
for ii=1:myFileListSize(1)
    if length(strsplit(myFileList(ii, :), '_')) > 1
        thisStrSplit = strsplit(myFileList(ii, :), '_');
        thisStrSplit = strsplit(thisStrSplit{end}, '.');
        myDataFileNumbers = [myDataFileNumbers str2num(thisStrSplit{1})]; %#ok<ST2NM>
    end
end
if length(myDataFileNumbers) >= 1
    runNumber = max(myDataFileNumbers) + 1;
else
    runNumber = 1001;
end
disp(['Run number set to ' num2str(runNumber) '.']);
scanFilename = [smaux.datadir '\' smscan.name '_' num2str(runNumber) '.mat'];
disp(['Filename is ' scanFilename '.']);
disp(['The current time is: ' datestr(datetime)]);

%% ---------- Custom scan execution for XYRT buffer mode ----------
fprintf('Starting XYRT buffer self-trigger measurement...\n');

% Modified smrun behavior for buffer trigger mode
data = zeros(length(myChannel), npointsInnerLoop, npointsOuterLoop);
for cycle = 1:npointsOuterLoop
    fprintf('\n--- Measurement Cycle %d/%d ---\n', cycle, npointsOuterLoop);
    
    % Set outer loop channel
    smset(outerLoopChannel, minOuterLoop + (cycle-1) * (maxOuterLoop-minOuterLoop)/(npointsOuterLoop-1));
    
    % ARM buffer capture (ic(3) = 3)
    try
        smdata.inst(ind_sr).cntrlfn([ind_sr, 22, 3], [], [], cap_mode);
        fprintf('Buffer capture armed for cycle %d\n', cycle);
    catch err
        fprintf('*ERROR* Arming buffer: %s\n', err.message);
        continue;
    end
    
    % Execute trigger sequence for inner loop
    fprintf('Triggering %d samples: ', BUFFER_SAMPLES);
    for sample = 1:npointsInnerLoop
        % Set inner loop dummy value
        smset(innerLoopChannel, minInnerLoop + (sample-1) * (maxInnerLoop-minInnerLoop)/(npointsInnerLoop-1));
        
        % Execute one trigger (ic(3) = 2)
        try
            smdata.inst(ind_sr).cntrlfn([ind_sr, 22, 2], [], [], cap_mode);
        catch err
            fprintf('T%d:ERR ', sample);
        end
        
        % Wait for trigger interval
        pause(TRIGGER_INTERVAL);
        
        % Progress indicator
        if mod(sample, max(1, floor(BUFFER_SAMPLES/10))) == 0 || sample == BUFFER_SAMPLES
            fprintf('%.0f%% ', (sample/BUFFER_SAMPLES)*100);
        end
    end
    fprintf('\n');
    
    % Stop and read buffer data (ic(3) = 0)
    try
        buffer_data = smdata.inst(ind_sr).cntrlfn([ind_sr, 22, 0], [], [], cap_mode);
        
        % Extract XYRT data from buffer
        if isstruct(buffer_data) && isfield(buffer_data, 'x')
            actual_samples = length(buffer_data.x);
            fprintf('Retrieved %d XYRT samples from buffer\n', actual_samples);
            
            % Store data in scan format (pad or truncate to match expected size)
            for ch = 1:length(myChannel)
                switch ch
                    case 1  % X data
                        temp_data = buffer_data.x;
                    case 2  % Y data
                        temp_data = buffer_data.y;
                    case 3  % R data
                        temp_data = buffer_data.r;
                    case 4  % Theta data
                        temp_data = buffer_data.theta;
                    otherwise
                        temp_data = zeros(1, npointsInnerLoop);
                end
                
                % Pad or truncate to match expected inner loop size
                if length(temp_data) >= npointsInnerLoop
                    data(ch, :, cycle) = temp_data(1:npointsInnerLoop);
                else
                    data(ch, 1:length(temp_data), cycle) = temp_data;
                    data(ch, length(temp_data)+1:end, cycle) = NaN;
                end
            end
        end
    end
    pause(smscan.loops(2).waittime);
end

% Save data in standard format
scan = smscan;  % Store scan parameters
save(scanFilename, 'data', 'scan');
fprintf('\nData saved to: %s\n', scanFilename);

%% ---------- Post-measurement analysis and display ----------
try
    fprintf('\n=== XYRT Buffer Self-Trigger Measurement Summary ===\n');
    fprintf('Total cycles: %d\n', npointsOuterLoop);
    fprintf('Samples per cycle: %d\n', BUFFER_SAMPLES);
    fprintf('Trigger interval: %.3f s\n', TRIGGER_INTERVAL);
    fprintf('Total measurement time: %.1f s\n', npointsOuterLoop * BUFFER_SAMPLES * TRIGGER_INTERVAL);
    
    % Basic plots if data exists
    if exist('data', 'var') && size(data, 1) >= 4
        figure(1001); clf;
        
        % Plot XYRT time series for each cycle
        for cycle = 1:min(3, npointsOuterLoop)  % Show up to 3 cycles
            subplot(2,2,1);
            plot(1:npointsInnerLoop, squeeze(data(1, :, cycle)), 'o-', ...
                 'DisplayName', sprintf('Cycle %d', cycle));
            hold on; xlabel('Sample #'); ylabel('X (V)'); title('X Component');
            legend; grid on;
            
            subplot(2,2,2);
            plot(1:npointsInnerLoop, squeeze(data(2, :, cycle)), 's-', ...
                 'DisplayName', sprintf('Cycle %d', cycle));
            hold on; xlabel('Sample #'); ylabel('Y (V)'); title('Y Component');
            legend; grid on;
            
            subplot(2,2,3);
            plot(1:npointsInnerLoop, squeeze(data(3, :, cycle)), '^-', ...
                 'DisplayName', sprintf('Cycle %d', cycle));
            hold on; xlabel('Sample #'); ylabel('R (V)'); title('Magnitude');
            legend; grid on;
            
            subplot(2,2,4);
            plot(1:npointsInnerLoop, squeeze(data(4, :, cycle)) * 180/pi, 'd-', ...
                 'DisplayName', sprintf('Cycle %d', cycle));
            hold on; xlabel('Sample #'); ylabel('θ (degrees)'); title('Phase');
            legend; grid on;
        end
        sgtitle('SR860 XYRT Buffer Self-Trigger Results');
    end
    
catch err
    fprintf('Error in post-analysis: %s\n', err.message);
end

%% ---------- Cleanup ----------
try
    % Stop any remaining capture
    fprintf(smdata.inst(ind_sr).data.inst, 'CAPTURESTOP');
    % Reset AUX0 to low
    fprintf(smdata.inst(ind_sr).data.inst, 'AUXV 0, 0.0');
catch
end

%% ---------- Save plot(s) to PPT ----------
slide = struct;
slide.title  = [smscan.name '_' num2str(runNumber) '.mat'];
slide.body   = [smscan.comments sprintf('\nXYRT Buffer: %d samples/cycle, %.3fs interval', ...
                BUFFER_SAMPLES, TRIGGER_INTERVAL)];
slide.loops  = smscan.loops;
slide.consts = smscan.consts;
try
    if strcmpi(smaux.pptMode, 'ppt')
        smsaveppt(smaux.pptsavefile, slide, '-f1001');
    elseif strcmpi(smaux.pptMode, 'pptx')
        smsavepptx(smaux.pptsavefile, slide, '-f1001');
    end
catch
    warning(['There was an error saving to the ppt for scan ' num2str(runNumber) '; continuing']);
end
toc;

%% ===================== Local functions =====================
function myUpdatedScan = UpdateConstants(myScan)
% copied from smgui
allchans = {myScan.consts.setchan};
setchans = {};
setvals = [];
for i=1:length(myScan.consts)
    if myScan.consts(i).set
        setchans{end+1}=myScan.consts(i).setchan; %#ok<AGROW>
        setvals(end+1)=myScan.consts(i).val;      %#ok<AGROW>
    end
end
if ~isempty(setchans)
    smset(setchans, setvals);
    newvals = cell2mat(smget(allchans));
    for i=1:length(myScan.consts)
        myScan.consts(i).val=newvals(i);
    end
end
myUpdatedScan = myScan;
end