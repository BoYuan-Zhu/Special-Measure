function val = smcAVS47B( ic, val, rate)
% AVS47B controller instrument
%% Author: Yuan Cao
% Date: 5/29/2017

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
    [path,~,~] = fileparts(thispath);
    C = load(sprintf('%s/Calibrations/%s.txt', path, calibration), '-ascii');
end


addr = 1;

config.dref = 0;
config.remote = 1;
config.channel = chan-1; % CH1 is actually channel 0, etc.
config.excitation = excitation; % 30uV excitation
config.display = 0; % Display R
config.input = 1; % 0: Zero, 1: Measure
config.disableal = 1;

datavalid = 0;

timeout = 30;
tol = 0.005; % tolerance
tic;

oldval = 0;
change_range = 0;

while ~datavalid && toc < timeout
    
    config.range = range; % Set range

    avs47Configure(device, addr, config);

    if change_range
        % Add 5s after 
        pause(5);
    end
    
    result = avs47Read(device, addr, config);

    r = result.res;

    if strcmp(calibration, 'none')
        val = r;
        return;
    end

    t = interp1(C(:,1), C(:,2), r, 'pchip');
    val = t;
    
    if (range == 7 || ~result.overrange) && (range == 1 || r >= 0.02*10^range) % Appropriate range (>10% max range), or minimum range already reached
        if abs(oldval - val) < tol * oldval
            datavalid = 1;
        end
        oldval = val;
        change_range = 0;
    elseif result.overrange
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


end

    