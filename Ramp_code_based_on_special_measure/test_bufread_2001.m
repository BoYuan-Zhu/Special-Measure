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
smaux.datadir     = 'C:\Users\86155\Desktop\sjtu_3\summer intern\special measure\test';
smaux.pptsavefile = smaux.datadir;    % folder or a .ppt/.pptx file path
smaux.pptMode     = 'ppt';            % 'ppt' or 'pptx'

%% -------------------- GPIB --------------------
GPIB_BOARD        = 'ni';
BOARD_NUM         = 0;
k2001_GPIB   = 11;   % SR830 GPIB address
K2450_GPIB        = 18;  % K2450 GPIB address

%% -------------------- Dummy instrument (for outer loop) --------------------
smloadinst('test');
smaddchannel('test','CH1','dummy');
smaddchannel('test','CH2','count');

%% -------------------- HP34401A --------------------
try
    ind_sr = smloadinst('sminst_k2001', [], GPIB_BOARD, BOARD_NUM, k2001_GPIB);
    smopen(ind_sr);
    smdata.inst(ind_sr).name    = 'k2001';
    smdata.inst(ind_sr).cntrlfn = @smck2001_Ramp;

    % Buffered channels (Lock-in first in getchan to avoid time skew)
   
    smaddchannel('k2001','V-buf','V-buf');   % Phase trace
    smaddchannel('k2001','I-buf','I-buf');

catch err
    fprintf(['*ERROR* k2001: ' err.identifier ': ' err.message '\n']);
end

%% -------------------- K2450 --------------------
try
    ind_k = smloadinst('k2450_2', [], 'ni', 0, K2450_GPIB);
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



%%============ Vbg vs dummy
% Set channel of measurement: yoko, dc205 or keithley
innerLoopChannel = 'Vg';
ramptimeInnerLoop_perstep= 0.02; 
InnerLoopwaittime = 0.15;
npointsInnerLoop = 21;
minInnerLoop = 4e-3;
maxInnerLoop = -4e-3;
%% 
% Iac1-buf is X buffer channel of SR830 or SR860
% Iac1-phase-buf is phase buffer channel of SR830 or SR860
% Ig-buf is the leak current of keithley 2450
% dmm-fast-buf is the buffer channel of K34461A
% !!!!! Lockin must come first in get channel to avoid time
% inconsistent of dmm and lockin.
myChannel = { 'V-buf'   'Ig-buf'};

outerLoopChannel = 'dummy';
npointsOuterLoop = 1;
minOuterLoop = 1;
maxOuterLoop = 1;


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
smrun_buf(smscan, scanFilename);

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