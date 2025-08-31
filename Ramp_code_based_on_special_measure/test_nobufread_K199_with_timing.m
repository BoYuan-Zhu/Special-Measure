clear all; close all; instrreset;
global smaux smscan smdata;

%% -------------------- Timing Setup --------------------
% Initialize timing structure
timing = struct();
timing.total_start = tic;
timing.setup_start = tic;

%% -------------------- Meta & paths --------------------
smscan.comments = ['Graphene @ RT Gr Vg test on Gr gate pin 18, Si gate gnd.' newline ...
    'iac1 5 nA 17.7777 Hz with 100 Mohm on 17-14, iac2 measures voltage drop 17-14.'];
smscan.name = 'Graphene';

% === Adjust these paths to your environment ===
smaux.datadir     = 'C:\Users\wanglabadmin\Desktop\Special-Measure-main\test';
smaux.pptsavefile = smaux.datadir;    % folder or a .ppt/.pptx file path
smaux.pptMode     = 'ppt';            % 'ppt' or 'pptx'

%% -------------------- GPIB --------------------
GPIB_BOARD        = 'ni';
BOARD_NUM         = 0;
K2450_GPIB        = 18;  % K2450 GPIB address
K199_GPIB         = 26;   % K199 GPIB address

%% -------------------- Dummy instrument (for outer loop) --------------------
timing.dummy_setup_start = tic;
smloadinst('test');
smaddchannel('test','CH1','dummy');
smaddchannel('test','CH2','count');
timing.dummy_setup_time = toc(timing.dummy_setup_start);
fprintf('Dummy instrument setup time: %.3f seconds\n', timing.dummy_setup_time);

%% -------------------- Model199 (DMM) --------------------
timing.k199_setup_start = tic;
try
    ind_199 = smloadinst('K199', [], GPIB_BOARD, BOARD_NUM, K199_GPIB);
    smopen(ind_199);
    smdata.inst(ind_199).name    = 'K199';
    smdata.inst(ind_199).cntrlfn = @smcK199_Ramp;   % your installed driver

    % Measurement channels (adjust ranges to taste)
    smaddchannel('K199','V', 'V_K199', [-10, 10, Inf, 1]);          % volts
    smaddchannel('K199','I', 'I_K199', [-1e-6, 1e-6, Inf, 1e6]);    % amps
    
    timing.k199_setup_time = toc(timing.k199_setup_start);
    fprintf('K199 setup time: %.3f seconds\n', timing.k199_setup_time);
catch err
    timing.k199_setup_time = toc(timing.k199_setup_start);
    fprintf('K199 setup failed after %.3f seconds\n', timing.k199_setup_time);
    fprintf(['*ERROR* K199: ' err.identifier ': ' err.message '\n']);
    rethrow(err);
end

%% -------------------- K2450 --------------------
timing.k2450_setup_start = tic;
try
    ind_k = smloadinst('k2450_2', [], 'ni', 0, K2450_GPIB);
    smopen(ind_k);
    smdata.inst(ind_k).name    = 'K2450';
    smdata.inst(ind_k).cntrlfn = @smcK2450_Ramp;

    % Source V (Vg) and Read I (Ig) and buffered Ig
    smaddchannel('K2450','Vg',     'Vg',     [-10, 10, Inf, 1]);      % source V
    % smaddchannel('K2450','Ig',     'Ig',     [-Inf, Inf, Inf, 1e6]);  % read I
    % smaddchannel('K2450','Ig-buf', 'Ig-buf');                         % buffered I
    
    timing.k2450_setup_time = toc(timing.k2450_setup_start);
    fprintf('K2450 setup time: %.3f seconds\n', timing.k2450_setup_time);
catch err
    timing.k2450_setup_time = toc(timing.k2450_setup_start);
    fprintf('K2450 setup failed after %.3f seconds\n', timing.k2450_setup_time);
    fprintf(['*ERROR* problem with connecting to the Source | ' err.identifier ': ' err.message '\n']);
end

% Total setup time
timing.setup_time = toc(timing.setup_start);
fprintf('Total setup time: %.3f seconds\n', timing.setup_time);

%% ==================== Scan definition ====================
timing.scan_config_start = tic;

innerLoopChannel = 'Vg';      % the dummy channel we step through
InnerLoopwaittime = 0;
npointsInnerLoop  = 51;
minInnerLoop      = 0;
maxInnerLoop      = 1;

myChannel = {'V_K199'};           % what we read each inner step

% Outer loop is a single point wrapper
outerLoopChannel  = 'count';     % VALID channel name (not a device name)
npointsOuterLoop  = 1;
minOuterLoop      = 1;
maxOuterLoop      = 1;

% Display: the data are produced by loop 1
smscan.saveloop = 1;
smscan.disp = struct([]);
for k = 1:numel(myChannel)
    smscan.disp(k).loop    = 1;
    smscan.disp(k).channel = k;   % index within getchan of loop 1
    smscan.disp(k).dim     = 1;   % 1D trace
end

% ----- Build loops (put V/I in GETCHAN of loop 1) -----
smscan.loops = struct;

% Loop 1: indexer that reads V/I
smscan.loops(1).npoints  = npointsInnerLoop;
smscan.loops(1).rng      = [minInnerLoop maxInnerLoop];
smscan.loops(1).getchan  = myChannel;           % <-- critical fix
smscan.loops(1).setchan  = {innerLoopChannel};  % dummy index
smscan.loops(1).ramptime = 0;
smscan.loops(1).waittime = InnerLoopwaittime;

% Loop 2: single-point wrapper; no data acquisition here
smscan.loops(2).npoints  = npointsOuterLoop;
smscan.loops(2).rng      = [minOuterLoop maxOuterLoop];
smscan.loops(2).getchan  = {};                  % nothing to read here
smscan.loops(2).setchan  = {outerLoopChannel};  % valid dummy channel
smscan.loops(2).ramptime = 0;
smscan.loops(2).waittime = 0;

% Constants updater (safe if none)
if ~isfield(smscan, 'consts')
    smscan.consts = struct('set', {}, 'setchan', {}, 'val', {});
end
smscan = UpdateConstants(smscan);

timing.scan_config_time = toc(timing.scan_config_start);
fprintf('Scan configuration time: %.3f seconds\n', timing.scan_config_time);

%% ---- Pick next filename ----
timing.filename_start = tic;

myFileList = ls(smaux.datadir);
myFileListSize = size(myFileList);
myDataFileNumbers = [];
for ii=1:myFileListSize(1)
    if length(strsplit(strtrim(myFileList(ii, :)), '_')) > 1
        thisStrSplit = strsplit(strtrim(myFileList(ii, :)), '_');
        thisStrSplit = strsplit(thisStrSplit{end}, '.');
        tmp = str2double(thisStrSplit{1});
        if ~isnan(tmp), myDataFileNumbers = [myDataFileNumbers tmp]; end
    end
end
if ~isempty(myDataFileNumbers), runNumber = max(myDataFileNumbers) + 1; else, runNumber = 1001; end
scanFilename = [smaux.datadir filesep smscan.name '_' num2str(runNumber) '.mat'];

timing.filename_time = toc(timing.filename_start);
fprintf('Filename generation time: %.3f seconds\n', timing.filename_time);

disp(['Run number set to ' num2str(runNumber) '.']);
disp(['Filename is ' scanFilename '.']);
disp(['The current time is: ' datestr(datetime)]);

%% ---- Run the measurement ----
timing.measurement_start = tic;
fprintf('Starting measurement...\n');
fprintf('Trying alternative smrun syntax...\n');

smrun(smscan, scanFilename);

timing.measurement_time = toc(timing.measurement_start);
timing.total_time = toc(timing.total_start);

%% ---- Display timing results ----
fprintf('\n=== TIMING SUMMARY ===\n');
fprintf('Dummy instrument setup: %.3f s\n', timing.dummy_setup_time);
if isfield(timing, 'k199_setup_time')
    fprintf('K199 setup:             %.3f s\n', timing.k199_setup_time);
end
if isfield(timing, 'k2450_setup_time')
    fprintf('K2450 setup:            %.3f s\n', timing.k2450_setup_time);
end
fprintf('Total setup:            %.3f s\n', timing.setup_time);
fprintf('Scan configuration:     %.3f s\n', timing.scan_config_time);
fprintf('Filename generation:    %.3f s\n', timing.filename_time);
fprintf('Measurement execution:  %.3f s\n', timing.measurement_time);
fprintf('TOTAL EXECUTION TIME:   %.3f s\n', timing.total_time);

% Calculate measurement efficiency
overhead_time = timing.total_time - timing.measurement_time;
efficiency = timing.measurement_time / timing.total_time * 100;
fprintf('Overhead time:          %.3f s\n', overhead_time);
fprintf('Measurement efficiency: %.1f%%\n', efficiency);

% Save timing data with the scan
timing_filename = [smaux.datadir filesep 'timing_' smscan.name '_' num2str(runNumber) '.mat'];
save(timing_filename, 'timing');
fprintf('Timing data saved to: %s\n', timing_filename);

%% -------------------- Local helper: UpdateConstants --------------------
function myUpdatedScan = UpdateConstants(myScan)
allchans = {myScan.consts.setchan};
setchans = {}; setvals = [];
for i=1:length(myScan.consts)
    if myScan.consts(i).set
        setchans{end+1}=myScan.consts(i).setchan;
        setvals(end+1)=myScan.consts(i).val;
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