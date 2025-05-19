function val = smcAVS47B_GPIB( ic, val, rate)
% AVS47B controller instrument
%% Author: Yuan Cao
% Date: 8/7/2017

% Channels:
% CH1-8: corresponding to actual channels 0-7 on the front panel

global smdata;

inst = ic(1);
chan = ic(2);
rw = ic(3);
if rw ~= 0
    error('You cannot write temperature');
end

device = smdata.inst(inst).data.inst;
excitation = smdata.inst(inst).data.excitation(chan);
range = smdata.inst(inst).data.range(chan);
calibration = smdata.inst(inst).data.calibration{chan};

if ~strcmp(calibration, 'none')
    thispath = mfilename('fullpath');
    [path,a,b] = fileparts(thispath);
    C = load(sprintf('%s/Calibrations/%s.txt', path, calibration), '-ascii');
end


% addr = 1;
%config.remote = 1;
fprintf(device, 'REM 1'); % Set to remote mode first
pause(0.5);
%config.display = 0; % Display R
fprintf(device, 'DIS %d', 0);
% pause(0.1);
%config.input = 1; % 0: Zero, 1: Measure
fprintf(device, 'INP %d', 1);
% pause(0.1);
fprintf(device, 'ARN 0');

%config.dref = 0;
fprintf(device, 'REF 0;');
% pause(1);
%config.channel = chan-1; % CH1 is actually channel 0, etc.

pause(5);

s=sprintf('MUX %d', chan-1);
fprintf(device, s);
% pause(1);
%config.excitation = excitation; % 30uV excitation
fprintf(device, sprintf('EXC %d', excitation));
% pause(1);
%config.disableal = 1;

datavalid = 0;

timeout = 30;
tol = 0.005; % tolerance
tic;

oldval = 0;
change_range = 0;

while ~datavalid && toc < timeout
    
    %config.range = range; % Set range
    fprintf(device, 'RAN %d', range);
    pause(0.1);

%    avs47Configure(device, addr, config);

    if change_range
        % Add 5s after 
        pause(5);
    end
    
%   result = avs47Read(device, addr, config);
%   r = result.res;
    pause(0.5);
    r = sscanf(query(device, 'ADC; RES?'), '%f');
    
    if r==[]
        pause(5);
        continue;
    end
    overrange = sscanf(query(device, 'OVL?'), '%d');

    if strcmp(calibration, 'none')
        val = r;
    else
        t = interp1(C(:,1), C(:,2), r, 'pchip');
        val = t;
    end
    
    if (range == 7 || ~overrange) && (range == 1 || r >= 0.02*10^range) % Appropriate range (>10% max range), or minimum range already reached
        if abs(oldval - val) < tol * oldval
            datavalid = 1;
        end
        oldval = val;
        change_range = 0;
    elseif overrange
        % Range up
        range = range + 1;
        smdata.inst(inst).data.range(chan) = range;
        change_range = 1;
    else
        % Range down
        range = range - 1;
        smdata.inst(inst).data.range(chan) = range;
        change_range = 1;
    end
    
end

% If timed out, return whatever is last time read into val

% fprintf(device, 'REM 0'); % Set to local mode

end

    