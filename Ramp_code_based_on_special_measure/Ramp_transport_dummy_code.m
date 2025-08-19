global smaux smscan smdata;

%%============ Vbg vs dummy
% Set channel of measurement: yoko, dc205 or keithley
innerLoopChannel = 'Vg';
ramptimeInnerLoop = 120; 
npointsInnerLoop = 800;
minInnerLoop = 4;
maxInnerLoop = -4;
%% 
% Iac1-buf is X buffer channel of SR830 or SR860
% Iac1-phase-buf is phase buffer channel of SR830 or SR860
% Ig-buf is the leak current of keithley 2450
% dmm-fast-buf is the buffer channel of K34461A
% !!!!! Lockin must come first in get channel to avoid time
% inconsistent of dmm and lockin.
myChannel = { 'Iac1-buf' 'Iac2-buf' 'Iac3-buf' 'Iac1-phase-buf' 'Iac2-phase-buf'  'Iac3-phase-buf' 'dmm-fast-buf' 'Ig-buf'};

outerLoopChannel = 'dummy';
npointsOuterLoop = 1;
minOuterLoop = 1;
maxOuterLoop = 1;

%============
% Your comments on current measurement
smscan.comments = ['Graphene @ RT Gr Vg test on Gr gate pin 18, Si gate gnd.\n' ...
    'iac1 5 nA 17.7777 Hz with 100 Mohm on 17-14, iac2 measures voltage drop 17-14.\n'];

smscan.name = 'Graphene';
smaux.datadir = 'C:\Users\Xiela\Desktop\Jiawei\Data'; %dataPath
smaux.pptsavefile = 'C:\Users\Xiela\Desktop\Jiawei\20250201.pptx';
smaux.pptMode = 'ppt';
%============

tic;
smscan = UpdateConstants(smscan);
smscan.saveloop = 2;
smscan.disp = struct;

smscan.disp(1).loop = 2;
smscan.disp(1).channel = 1;
smscan.disp(1).dim = 1;

smscan.disp(2).loop = 2;
smscan.disp(2).channel = 2;
smscan.disp(2).dim = 1;

smscan.disp(3).loop = 2;
smscan.disp(3).channel = 3;
smscan.disp(3).dim = 1;

smscan.disp(4).loop = 2;
smscan.disp(4).channel = 4;
smscan.disp(4).dim = 1;

smscan.disp(5).loop = 2;
smscan.disp(5).channel = 5;
smscan.disp(5).dim = 1;

smscan.disp(6).loop = 2;
smscan.disp(6).channel = 6;
smscan.disp(6).dim = 1;

smscan.disp(7).loop = 2;
smscan.disp(7).channel = 7;
smscan.disp(7).dim = 1;

smscan.loops = struct;
smscan.loops(1).npoints = npointsInnerLoop;
smscan.loops(1).rng = [minInnerLoop maxInnerLoop];
smscan.loops(1).getchan = {};
smscan.loops(1).setchan = {innerLoopChannel};
smscan.loops(1).ramptime = -1 * abs(ramptimeInnerLoop/(smscan.loops(1).npoints-1));
smscan.loops(1).waittime = 0;

smscan.loops(2).npoints = npointsOuterLoop;
smscan.loops(2).rng = [minOuterLoop maxOuterLoop];
smscan.loops(2).getchan = myChannel;
smscan.loops(2).setchan = {outerLoopChannel};
smscan.loops(2).ramptime = 0;
smscan.loops(2).waittime = 0;

smscan.configfn.fn = @smabufconfig2;
smscan.configfn.args = {'trig arm'};


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

% save the plot from the scan to a ppt
slide = struct;
slide.title = [smscan.name '_' num2str(runNumber) '.mat'];
slide.body = smscan.comments;
slide.loops = smscan.loops;
slide.consts = smscan.consts;
try
    % test plot on figure 1000
    if strcmp(smaux.pptMode, 'ppt')
        smsaveppt(smaux.pptsavefile, slide, '-f1000');
    elseif strcmp(smaux.pptMode, 'pptx')
        smsavepptx(smaux.pptsavefile, slide, '-f1000');
    end
catch
    warning(['There was an error saving to the ppt for scan ' num2str(runNumber) '; continuing']);
end
toc;


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