function smread(channels)

% smread(channels)
% 
% Read a value into the buffer
% channels can be a cell or char array with channel names, or a vector
% with channel numbers.
global smdata;

if(isempty(channels))
    return
end

if ~isnumeric(channels)
    channels = smchanlookup(channels);
end


nchan = length(channels);
instchan = vertcat(smdata.channels(channels).instchan);



for k = 1:nchan
    smdata.inst(instchan(k, 1)).cntrlfn([instchan(k, :),2]); %% case nmber 2 should be set as read a data into the buffer
end




end
