% ===================== test.m  (SR830 + K2450 buffered scan; SR830 only readout) ======================
% Chat: Chinese; Code comments: English
% This script integrates:
%   (1) Instrument & channel setup for SR830 + K2450
%   (2) Two-loop scan definition with display and autosave
%   (3) Buffered acquisition for SR830 via smabufconfig2_ramp with 'fast' mode
%   (4) Auto file numbering and PPT export
%
% Notes:
%   - SR830 buffered channels only (Iac1-buf/phase-buf)
%   - K2450 only sources Vg (no Ig / Ig-buf channels)

clear all; close all; instrreset;
global smaux smscan smdata;

%% -------------------- Meta & paths --------------------
smscan.comments = ['Graphene @ RT Gr Vg test on Gr gate pin 18, Si gate gnd.' newline ...
    'iac1 5 nA 17.7777 Hz with 100 Mohm on 17-14, iac2 measures voltage drop 17-14.' newline ...
    'SR830 buffered only; K2450 used only for Vg ramp (no Ig).'];
smscan.name = 'Graphene';

% === Adjust these paths to your environment ===
smaux.datadir     = 'C:\Users\86155\Desktop\sjtu_3\summer intern\special measure\test';
smaux.pptsavefile = smaux.datadir;    % folder or a .ppt/.pptx file path
smaux.pptMode     = 'ppt';            % 'ppt' or 'pptx'

%% -------------------- GPIB --------------------
GPIB_BOARD        = 'ni';
BOARD_NUM         = 0;
LockInHigh_GPIB   = 1;   % SR830 GPIB address
K2450_GPIB        = 18;  % K2450 GPIB address

%% -------------------- Dummy instrument (for outer loop) --------------------
smloadinst('test');
smaddchannel('test','CH1','dummy');
smaddchannel('test','CH2','count');

%% -------------------- SR830 --------------------
try
    ind_sr = smloadinst('SR830_1', [], GPIB_BOARD, BOARD_NUM, LockInHigh_GPIB);
    smopen(ind_sr);
    smdata.inst(ind_sr).name    = 'LockIn_High';
    smdata.inst(ind_sr).cntrlfn = @smcSR830_spm;

    % Live channels (scaled ranges are examples; adjust as needed)
    smaddchannel('LockIn_High','X',    'Isd',     [-Inf, Inf, Inf, 1e6]);
    smaddchannel('LockIn_High','Y',    'Isd_Y',   [-Inf, Inf, Inf, 1e6]);
    smaddchannel('LockIn_High','FREQ', 'Freq_A',  [0, 102000, 10, 1]);
    smaddchannel('LockIn_High','VREF', 'Vref_A',  [0.004, 5, 0.5, 1]);
    smaddchannel('LockIn_High','OUT1', 'OUT1_A',  [-2, 2, 0.5, 1]);

    % Buffered channels (Lock-in first in getchan to avoid time skew)
    smaddchannel('LockIn_High','DATA1','Iac1-buf');         % X trace (buffered)
    smaddchannel('LockIn_High','DATA2','Iac1-phase-buf');   % Phase trace (buffered)
catch err
    fprintf(['*ERROR* SR830: ' err.identifier ': ' err.message '\n']);
end

%% -------------------- K2450 --------------------
% Use your ramp-capable control fn; only add Vg (no Ig / Ig-buf).
try
    ind_k = smloadinst('k2450_2', [], 'ni', 0, K2450_GPIB);
    smopen(ind_k);
    smdata.inst(ind_k).name    = 'K2450';
    smdata.inst(ind_k).cntrlfn = @smcK2450_Ramp;  % must support Vg ramp (case 6)

    % Only source Vg (no current channels)
    smaddchannel('K2450','Vg', 'Vg', [-10, 10, Inf, 1]);  % source V
catch err
    fprintf(['*ERROR* problem with connecting to the Source | ' err.identifier ': ' err.message '\n']);
end

%%============ Vbg vs dummy (SR830 buffered only)
innerLoopChannel  = 'Vg';
ramptimeInnerLoop = 12;        % total ramp time (s) for the whole sweep
npointsInnerLoop  = 81;
minInnerLoop      = 4;
maxInnerLoop      = -4;

% SR830 buffered channels only (lock-in must come first)
myChannel = { 'Iac1-buf'  'Iac1-phase-buf' };

outerLoopChannel = 'dummy';
npointsOuterLoop = 1;
minOuterLoop     = 0;
maxOuterLoop     = 1;

tic;
if ~isfield(smscan, 'consts')
    smscan.consts = struct('set', {}, 'setchan', {}, 'val', {});
end

smscan = UpdateConstants(smscan);

% === build disp to match getchan exactly ===
smscan.saveloop = 2;

smscan.disp = struct([]);
for k = 1:numel(myChannel)
    smscan.disp(k).loop    = 2;   % data are acquired in loop 2
    smscan.disp(k).channel = k;   % channel index within getchan of loop 2
    smscan.disp(k).dim     = 1;   % 1D trace
end

% === loops ===
smscan.loops = struct;
smscan.loops(1).npoints  = npointsInnerLoop;
smscan.loops(1).rng      = [minInnerLoop maxInnerLoop];
smscan.loops(1).getchan  = {};                        % fast mode: no get in inner loop
smscan.loops(1).setchan  = {innerLoopChannel};
smscan.loops(1).ramptime = abs(ramptimeInnerLoop/(smscan.loops(1).npoints-1));  % POSITIVE per-step time
smscan.loops(1).waittime = 0;

smscan.loops(2).npoints  = npointsOuterLoop;
smscan.loops(2).rng      = [minOuterLoop maxOuterLoop];
smscan.loops(2).getchan  = myChannel;                 % SR830 buffered channels only
smscan.loops(2).setchan  = {outerLoopChannel};
smscan.loops(2).ramptime = 0;
smscan.loops(2).waittime = 0;

% keep the buffered fast-mode config for SR830 + ramp on K2450
smscan.configfn.fn   = @smabufconfig2_ramp;
smscan.configfn.args = {'trig arm'};

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

%% ---------- Run the scan ----------
smrun(smscan, scanFilename);

%% ---------- Save plot(s) to PPT ----------
slide = struct;
slide.title  = [smscan.name '_' num2str(runNumber) '.mat'];
slide.body   = smscan.comments;
slide.loops  = smscan.loops;
slide.consts = smscan.consts;
try
    if strcmpi(smaux.pptMode, 'ppt')
        smsaveppt(smaux.pptsavefile, slide, '-f1000');
    elseif strcmpi(smaux.pptMode, 'pptx')
        smsavepptx(smaux.pptsavefile, slide, '-f1000');
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
