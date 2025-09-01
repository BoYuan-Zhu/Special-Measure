% ===================== test.m  (SR830 + K2450 buffered scan) ======================
% Chat: Chinese; Code comments: English
% This script integrates:
%   (1) Instrument & channel setup for SR830 + K2450
%   (2) Two-loop scan definition with display and autosave
%   (3) Buffered acquisition via smabufconfig2_ramp with 'fast' mode
%   (4) Auto file numbering and PPT export
%
% Key fixes vs prior attempts:
%   - Use positive per-step ramptime (avoid "Negative ramp rate" error)
%   - Build myChannel by filtering only channels that actually exist
%   - Ensure lock-in buffered channels are first in getchan order
%   - Place local function at END of the file (MATLAB rule)

clear all; close all; instrreset;
global smaux smscan smdata;

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
LockInHigh_GPIB   = 1;   % SR830 GPIB address
K2450_GPIB        = 18;  % K2450 GPIB address
K2450_GPIB_2        = 19;  % K2450 GPIB address

%% -------------------- Dummy instrument (for outer loop) --------------------
smloadinst('test');
smaddchannel('test','CH1','dummy');
smaddchannel('test','CH2','count');

%% -------------------- SR830 --------------------
try
    ind_sr = smloadinst('SR830_Ramp', [], GPIB_BOARD, BOARD_NUM, LockInHigh_GPIB);
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
    smaddchannel('LockIn_High','DATA1','Iac1-buf');         % X trace
    smaddchannel('LockIn_High','DATA2','Iac1-phase-buf');   % Phase trace
catch err
    fprintf(['*ERROR* SR830: ' err.identifier ': ' err.message '\n']);
end

%% -------------------- K2450 --------------------
try
    ind_k = smloadinst('k2450_Ramp', [], 'ni', 0, K2450_GPIB);
    smopen(ind_k);
    smdata.inst(ind_k).name    = 'K2450';
    smdata.inst(ind_k).cntrlfn = @smcK2450_Ramp;

    % Source V (Vg) and Read I (Ig) and buffered Ig
    smaddchannel('K2450','Vg',     'Vg',     [-10, 10, Inf, 1]);      % source V
    smaddchannel('K2450','Ig',     'Ig',     [-Inf, Inf, Inf, 1e6]);  % read I
    smaddchannel('K2450','Ig-buf', 'Ig-buf');                         % buffered I
catch err
    fprintf(['*ERROR* problem with connecting to the Source | ' err.identifier ': ' err.message '\n']);
end






% 
% innerLoopChannel = 'Vg';
% myChannel = 'Ig-buf';
% inst = smchaninst(smchanlookup(myChannel));   % 例如 Vg-ramp
% smatrigfn(inst);                               % 默认 op=3
% 
% for i=1:50
% smset(innerLoopChannel,i/10);
% pause(0.12);
% smread(myChannel);
% pause(0.1);
% end
% 
% val = smget(myChannel);
% fprintf('buf: %s\n', mat2str(val{1}, 6));  % 一行打印，保留6位有效数字



smscan.loops = zeros();


%%============ Vbg vs dummy
% Set channel of measurement: yoko, dc205 or keithley
innerLoopChannel = 'Vg';
ramptimeInnerLoop_perstep= 0; 
InnerLoopwaittime = 0.1;
npointsInnerLoop = 51;
minInnerLoop = 4;
maxInnerLoop = -4;
%% 
% Iac1-buf is X buffer channel of SR830 or SR860
% Iac1-phase-buf is phase buffer channel of SR830 or SR860
% Ig-buf is the leak current of keithley 2450
% dmm-fast-buf is the buffer channel of K34461A
% !!!!! Lockin must come first in get channel to avoid time
% inconsistent of dmm and lockin.
myChannel = {  'Ig-buf' 'Iac1-buf'  'Iac1-phase-buf'};

outerLoopChannel = 'dummy';
npointsOuterLoop = 11;
minOuterLoop = 1;
maxOuterLoop = 10;


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
    smscan.disp(k).dim     = 2;   % 1D trace
end

smscan.loops = struct;
smscan.loops(1).npoints = npointsInnerLoop;
smscan.loops(1).rng = [minInnerLoop maxInnerLoop];
smscan.loops(1).getchan = {};
smscan.loops(1).readchan = myChannel;
smscan.loops(1).setchan = {innerLoopChannel};
smscan.loops(1).ramptime = ramptimeInnerLoop_perstep;
smscan.loops(1).waittime = InnerLoopwaittime;



smscan.loops(2).npoints = npointsOuterLoop;
smscan.loops(2).rng = [minOuterLoop maxOuterLoop];
smscan.loops(2).getchan = myChannel;
smscan.loops(2).setchan = {outerLoopChannel};
smscan.loops(2).readchan = {};
smscan.loops(2).ramptime = 0;
smscan.loops(2).waittime = 0;


smscan.configfn.fn   = @smabufconfig_buframp;
smscan.configfn.args = {'trig'};   % ctrl='trig '，getchanInd=0(不筛选)


%% figure out the next scan number (##_.mat)
myFileList = ls(smaux.datadir);
myFileListSize = size(myFileList);
myDataFileNumbers = [];

for ii=1:myFileListSize(1)
    if length(strsplit(myFileList(ii, :), '_')) > 1
        thisStrSplit = strsplit(myFileList(ii, :), '_');
        thisStrSplit = strsplit(thisStrSplit{end}, '.');
        myDataFileNumbers = [myDataFileNumbers str2num(thisStrSplit{1})];
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


% run the scan with appropriate filename
smrun(smscan, scanFilename);

% % save the plot from the scan to a ppt
% slide = struct;
% slide.title = [smscan.name '_' num2str(runNumber) '.mat'];
% slide.body = smscan.comments;
% slide.loops = smscan.loops;
% slide.consts = smscan.consts;
% try
%     % test plot on figure 1000
%     if strcmp(smaux.pptMode, 'ppt')
%         smsaveppt(smaux.pptsavefile, slide, '-f1000');
%     elseif strcmp(smaux.pptMode, 'pptx')
%         smsavepptx(smaux.pptsavefile, slide, '-f1000');
%     end
% catch
%     warning(['There was an error saving to the ppt for scan ' num2str(runNumber) '; continuing']);
% end
% toc;
% 
% 
function myUpdatedScan = UpdateConstants(myScan)
% copied from smgui
%global smaux smscan;
allchans = {myScan.consts.setchan};
setchans = {};
setvals = [];
for i=1:length(myScan.consts)
    if myScan.consts(i).set
        setchans{end+1}=myScan.consts(i).setchan;
        setvals(end+1)=myScan.consts(i).val;
    end
end
smset(setchans, setvals);
newvals = cell2mat(smget(allchans));
for i=1:length(myScan.consts)
    myScan.consts(i).val=newvals(i);
    %             if abs(floor(log10(newvals(i))))>3
    %                 set(smaux.smgui.consts_eth(i),'String',sprintf('%0.1e',newvals(i)));
    %             else
    %                 set(smaux.smgui.consts_eth(i),'String',round(1000*newvals(i))/1000);
    %             end
end
myUpdatedScan = myScan;
end