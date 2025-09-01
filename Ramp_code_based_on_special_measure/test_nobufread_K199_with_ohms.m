clear all; close all; instrreset;
global smaux smscan smdata;

%% -------------------- Meta & paths --------------------
smscan.comments = ['K199 DMM Resistance & Current measurement @ RT.' newline ...
    'Measuring both resistance and current across sample terminals using K199.'];
smscan.name = 'DualChannelMeasurement';

% === Adjust these paths to your environment ===
smaux.datadir     = 'C:\Users\wanglabadmin\Desktop\Special-Measure-main\test';
smaux.pptsavefile = smaux.datadir;    % folder or a .ppt/.pptx file path
smaux.pptMode     = 'ppt';            % 'ppt' or 'pptx'

%% -------------------- GPIB --------------------
GPIB_BOARD        = 'ni';
BOARD_NUM         = 0;
K2450_GPIB        = 18;  % K2450 GPIB address
K199_GPIB         = 27;
K199_GPIB_OHMS    = 26;   % K199 GPIB address

%% -------------------- Dummy instrument (for outer loop) --------------------
smloadinst('test');
smaddchannel('test','CH1','dummy');
smaddchannel('test','CH2','count');

%% -------------------- Model199 (OHMS) --------------------
try
    ind_199 = smloadinst('K199', [], GPIB_BOARD, BOARD_NUM, K199_GPIB_OHMS);
    smopen(ind_199);
    if size(smdata.inst(ind_199).datadim, 1) < 3 
        smdata.inst(ind_199).datadim = ones(3, 5); 
    end
    smdata.inst(ind_199).name    = 'K199';
    smdata.inst(ind_199).cntrlfn = @smcK199_Ramp;   % your installed driver

    % % Measurement channels for resistance and current
    smaddchannel('K199','OHMS','OHMS_K199',  [0, 1e9, Inf, 1]);          % ohms (0 to 1GOhm range)
    % smaddchannel('K199','V', 'V_K199', [-10, 10, Inf, 1]);               % volts (backup channel)
    % smaddchannel('K199','I', 'I_K199', [-1e-6, 1e-6, Inf, 1e6]);         % amps (current measurement)
catch err
    fprintf(['*ERROR* K199: ' err.identifier ': ' err.message '\n']);
    rethrow(err);
end

%% -------------------- Model199 (DMM) --------------------
try
    ind_199 = smloadinst('K199', [], GPIB_BOARD, BOARD_NUM, K199_GPIB);
    smopen(ind_199);
    if size(smdata.inst(ind_199).datadim, 1) < 3 
        smdata.inst(ind_199).datadim = ones(3, 5); 
    end
    smdata.inst(ind_199).name    = 'K199';
    smdata.inst(ind_199).cntrlfn = @smcK199_Ramp;   % your installed driver

    % % Measurement channels for resistance and current
    % smaddchannel('K199','OHMS','OHMS_K199',  [0, 1e9, Inf, 1]);          % ohms (0 to 1GOhm range)
    smaddchannel('K199','V', 'V_K199', [-10, 10, Inf, 1]);               % volts (backup channel)
    smaddchannel('K199','I', 'I_K199', [-1e-6, 1e-6, Inf, 1e6]);         % amps (current measurement)
catch err
    fprintf(['*ERROR* K199: ' err.identifier ': ' err.message '\n']);
    rethrow(err);
end

%% -------------------- K2450 --------------------
try
    ind_k = smloadinst('k2450_2', [], 'ni', 0, K2450_GPIB);
    smopen(ind_k);
    smdata.inst(ind_k).name    = 'K2450';
    smdata.inst(ind_k).cntrlfn = @smcK2450_Ramp;

    % Source V (Vg) and Read I (Ig) and buffered Ig
    smaddchannel('K2450','Vg',     'Vg',     [-10, 10, Inf, 1]);      % source V
catch err
    fprintf(['*ERROR* problem with connecting to the Source | ' err.identifier ': ' err.message '\n']);
end

%% ==================== Scan definition ====================
innerLoopChannel = 'Vg';      % the dummy channel we step through
InnerLoopwaittime = 0.1;
npointsInnerLoop  = 51;
minInnerLoop      = 0;
maxInnerLoop      = 1;

% MODIFIED: Now measure BOTH channels simultaneously
myChannels = {'OHMS_K199', 'I_K199'};  % Both resistance and current

% Outer loop is a single point wrapper
outerLoopChannel  = 'count';     % VALID channel name (not a device name)
npointsOuterLoop  = 1;
minOuterLoop      = 1;
maxOuterLoop      = 1;

% MODIFIED: Display setup for BOTH channels
smscan.saveloop = 1;
smscan.disp = struct([]);

% Setup display for resistance (channel 1)
smscan.disp(1).loop    = 1;
smscan.disp(1).channel = 1;   % first channel in myChannels (OHMS)
smscan.disp(1).dim     = 1;   % 1D trace

% Setup display for current (channel 2)  
smscan.disp(2).loop    = 1;
smscan.disp(2).channel = 2;   % second channel in myChannels (I)
smscan.disp(2).dim     = 1;   % 1D trace

% ----- Build loops (measure BOTH resistance and current in loop 1) -----
smscan.loops = struct;

% Loop 1: indexer that reads BOTH resistance AND current
smscan.loops(1).npoints  = npointsInnerLoop;
smscan.loops(1).rng      = [minInnerLoop maxInnerLoop];
smscan.loops(1).getchan  = myChannels;           % <-- measure BOTH channels
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

%% ---- Pick next filename ----
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
disp(['Run number set to ' num2str(runNumber) '.']);
disp(['Filename is ' scanFilename '.']);
disp(['The current time is: ' datestr(datetime)]);

% Set K199 to measurement mode before starting
fprintf('Setting K199 to dual measurement mode (resistance and current)...\n');
fprintf('Starting dual channel measurements...\n');

% Run the measurement
smrun(smscan, scanFilename);

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