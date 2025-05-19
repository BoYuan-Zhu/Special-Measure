function pos = smaddchannel(inst, channel, name, rangeramp, pos)
% smaddchannel(dev, channel, channame, rangeramp, pos)
% 
% Add channel channel from instrument dev with name channame.
% rangeramp defaults to [-Inf, Inf, Inf, 1];
% The first two elements are the range limits,
% the last two elements the ramp rate (1/2) and the conversion factor.


global smdata;

if nargin < 4 || isempty(rangeramp)
    rangeramp = [-Inf, Inf];
end

if length(rangeramp) < 3
    rangeramp(3) = Inf;
end

if length(rangeramp) < 4
    rangeramp(4) = 1;
end

inst = sminstlookup(inst);

if ~isnumeric(channel)  
    channel = strmatch(channel, strvcat(smdata.inst(inst).channels), 'exact');  %strmatch(str, strarray) to see if is already exist in smdata
end

if isempty(channel)
    fprintf('Invalid channel.\n');
    return;
end

if nargin < 5
    if isfield(smdata, 'channels')  % check if this the first channel in smdata
        pos = length(smdata.channels)+1;
    else
        pos = 1;
    end
end
smdata.channels(pos).name = name;
smdata.channels(pos).instchan = [inst, channel];
smdata.channels(pos).rangeramp = rangeramp;

smprintchannels(pos);
