% ===================== test_SR860_smrun_buffer.m ======================
% SR860 自测量：XYRT 缓冲采集 + Aux0 自触发（strictly via smrun）
% - 内层 loop: 仅用于按节拍触发（由 prefn 在 Aux0 打脉冲）
% - 外层 loop: 一次性读取 XYRT 缓冲数据

clear all; close all; instrreset;
global smaux smscan smdata;

%% -------------------- User Configuration --------------------
AUX_CH      = 0;         % Aux Out 0 -> TRIG IN  (wire BNC from Aux Out 0 to TRIG IN)
AUX_VHIGH   = 5;         % High level for TTL-like (safe)
AUX_VLOW    = 0.0;       % Low level
AUX_DWELL   = 0.005;     % sec between edges

% SR860 measurement parameters
SINE_AMPLITUDE  = 0.01;    % Sine output amplitude (V)
TIME_CONSTANT   = 0.01;   % Lock-in time constant (s)

%% -------------------- Meta & paths --------------------
smscan.comments = 'SR860 self-measurement: XYRT buffer capture with Aux0 self-trigger via smrun.';
smscan.name = 'SR860_XYRT_smrun';

% === Adjust these paths ===
smaux.datadir     = 'C:\Users\wanglabadmin\Desktop\Special-Measure-main\test';
smaux.pptsavefile = smaux.datadir;
smaux.pptMode     = 'ppt';

%% -------------------- GPIB --------------------
GPIB_BOARD      = 'ni';
BOARD_NUM       = 0;
SR860_GPIB      = 5;

%% -------------------- Dummy instrument (for triggering loop) --------------------
smloadinst('test');
smaddchannel('test','CH1','dummy');
smaddchannel('test','CH2','count');

%% -------------------- SR860 --------------------
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
    smset('SineAmp', SINE_AMPLITUDE);
    smset('TimeConst', TIME_CONSTANT);
    
    % Set input configuration
    inst = smdata.inst(ind_sr).data.inst;
    fprintf(inst, 'ISRC 0');          % A input (single-ended)
    fprintf(inst, 'IGND 0');          % Float input ground
    fprintf(inst, 'ICPL 0');          % AC coupling
    fprintf(inst, 'ILIN 0');          % No line notch filter
    
    % Set sensitivity appropriately
    if SINE_AMPLITUDE >= 1.0
        fprintf(inst, 'SCAL 16');     % 1 V full scale
    elseif SINE_AMPLITUDE >= 0.5
        fprintf(inst, 'SCAL 15');     % 500 mV full scale  
    else
        fprintf(inst, 'SCAL 14');     % 200 mV full scale
    end
    
    fprintf('SR860 configured for self-measurement.\n');
    
catch err
    fprintf(['*ERROR* SR860 setup: ' err.identifier ': ' err.message '\n']);
end

%% -------------------- Buffer Configuration --------------------
BUFFER_SAMPLES   = 100;
TARGET_RATE      = 1000;
TRIGGER_INTERVAL = 0.01;

%% -------------------- File numbering ----------
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
scanFilename = [smaux.datadir '\' smscan.name '_' num2str(runNumber)];

%% -------------------- smrun Scan Definition --------------------
% Constants for the scan
if ~isfield(smscan, 'consts'); smscan.consts = struct('set', {}, 'setchan', {}, 'val', {}); end
smscan = UpdateConstants(smscan);

% Display configuration
smscan.saveloop = 2;
smscan.disp = struct([]);
myChannel = { 'SR860_Xbuf', 'SR860_Ybuf', 'SR860_Rbuf', 'SR860_Thbuf' };

for k = 1:numel(myChannel)
    smscan.disp(k).loop    = 2;     % data are acquired in loop 2
    smscan.disp(k).channel = k;     % index within getchan of loop 2
    smscan.disp(k).dim     = 1;     % 1D trace
end

% Loop definitions
smscan.loops = struct;

% Inner loop: trigger generation (fast loop)
smscan.loops(1).npoints  = BUFFER_SAMPLES;
smscan.loops(1).rng      = [0 BUFFER_SAMPLES-1];
smscan.loops(1).getchan  = {};                    % No data acquisition in inner loop
smscan.loops(1).setchan  = {'dummy'};             % Use dummy channel
smscan.loops(1).ramptime = TRIGGER_INTERVAL;      % Time between triggers
smscan.loops(1).waittime = 0.001;                 % Minimal wait

% prefn: executed at each point of inner loop to generate trigger pulses
% Create function handle with parameters bound
triggerFn = @(x) auxTriggerPulse(AUX_CH, AUX_VHIGH, AUX_VLOW, AUX_DWELL);
smscan.loops(1).prefn = struct();
smscan.loops(1).prefn.fn = triggerFn;
smscan.loops(1).prefn.args = {};

% Outer loop: measurement cycles
smscan.loops(2).npoints  = 1;                     % Single measurement cycle
smscan.loops(2).rng      = [1 1];
smscan.loops(2).getchan  = myChannel;             % XYRT buffer channels
smscan.loops(2).setchan  = {'count'};
smscan.loops(2).ramptime = 0;
smscan.loops(2).waittime = 0.1;

% prefn for outer loop: configure and arm buffer before starting inner loop
configFn = @(x) bufferConfigArm(BUFFER_SAMPLES, TARGET_RATE, 'pertrig');
smscan.loops(2).prefn = struct();
smscan.loops(2).prefn.fn = configFn;
smscan.loops(2).prefn.args = {};

% postfn for outer loop: stop and read buffer after inner loop completes
smscan.loops(2).postfn = struct();
smscan.loops(2).postfn.fn = @(~) stopAndReadBuffer();
smscan.loops(2).postfn.args = {};

%% -------------------- Execute Measurement via smrun --------------------
%(optional)
fprintf('\n=== Starting SR860 XYRT Buffer Measurement via smrun ===\n');
fprintf('Buffer samples: %d, Trigger interval: %.3f s\n', BUFFER_SAMPLES, TRIGGER_INTERVAL);
fprintf('Expected measurement time: %.1f s\n', BUFFER_SAMPLES * TRIGGER_INTERVAL);

% Run the measurement
data = smrun(smscan, scanFilename);

fprintf('\nMeasurement completed via smrun.\n');
fprintf('Data saved to: %s.mat\n', scanFilename);
%% -------------------- Cleanup --------------------
try
    % Stop any remaining capture
    fprintf(smdata.inst(ind_sr).data.inst, 'CAPTURESTOP');
    % Reset AUX0 to low
    fprintf(smdata.inst(ind_sr).data.inst, 'AUXV 0, 0.0');
catch
end

%% -------------------- Save to PPT --------------------
slide = struct;
slide.title  = [smscan.name '_' num2str(runNumber) '.mat'];
slide.body   = [smscan.comments sprintf('\nXYRT Buffer: %d samples, %.3fs interval', ...
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
    warning(['Error saving to ppt for scan ' num2str(runNumber)]);
end

%% ===================== Local Functions =====================
function myUpdatedScan = UpdateConstants(myScan)
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

% Function to configure and arm buffer
function bufferConfigArm(buffer_samples, target_rate, cap_mode)
    global smdata;
    try
        % Find SR860 instrument
        sr_idx = [];
        for i = 1:length(smdata.inst)
            if strcmp(smdata.inst(i).name, 'SR860')
                sr_idx = i;
                break;
            end
        end
        if isempty(sr_idx)
            error('SR860 instrument not found');
        end
        
        % Configure buffer (ic(3) = 5)
        [~, actual_rate] = smdata.inst(sr_idx).cntrlfn([sr_idx, 22, 5], buffer_samples, target_rate, cap_mode);
        fprintf('Buffer configured. Actual rate: %.2f Hz\n', actual_rate);
        
        % ARM buffer capture (ic(3) = 3)
        smdata.inst(sr_idx).cntrlfn([sr_idx, 22, 3], [], [], cap_mode);
        fprintf('Buffer capture armed\n');
        
    catch err
        fprintf('*ERROR* Buffer config/arm: %s\n', err.message);
    end
end

% Function to generate Aux0 trigger pulse
function auxTriggerPulse(aux_ch, v_high, v_low, dwell_time)
    global smdata;
    try
        % Find SR860 instrument
        sr_idx = [];
        for i = 1:length(smdata.inst)
            if strcmp(smdata.inst(i).name, 'SR860')
                sr_idx = i;
                break;
            end
        end
        if isempty(sr_idx)
            return;
        end
        
        inst = smdata.inst(sr_idx).data.inst;
        
        % Generate trigger pulse: LOW -> HIGH -> LOW
        fprintf(inst, sprintf('AUXV %d, %.3f', aux_ch, v_low));
        pause(dwell_time/2);
        fprintf(inst, sprintf('AUXV %d, %.3f', aux_ch, v_high));
        pause(dwell_time/2);
        fprintf(inst, sprintf('AUXV %d, %.3f', aux_ch, v_low));
        
        % Also send trigger command to instrument (ic(3) = 2)
        smdata.inst(sr_idx).cntrlfn([sr_idx, 22, 2], [], [], 'pertrig');
        
    catch err
        fprintf('*ERROR* Trigger pulse: %s\n', err.message);
    end
end

% Function to stop and read buffer data
function stopAndReadBuffer()
    global smdata;
    try
        % Find SR860 instrument
        sr_idx = [];
        for i = 1:length(smdata.inst)
            if strcmp(smdata.inst(i).name, 'SR860')
                sr_idx = i;
                break;
            end
        end
        if isempty(sr_idx)
            return;
        end
        
        % Stop and read buffer data (ic(3) = 0)
        buffer_data = smdata.inst(sr_idx).cntrlfn([sr_idx, 22, 0], [], [], 'pertrig');
        
        if isstruct(buffer_data) && isfield(buffer_data, 'x')
            actual_samples = length(buffer_data.x);
            fprintf('Retrieved %d XYRT samples from buffer\n', actual_samples);
        else
            fprintf('*WARNING* No valid buffer data retrieved\n');
        end
        
    catch err
        fprintf('*ERROR* Reading buffer: %s\n', err.message);
    end
end