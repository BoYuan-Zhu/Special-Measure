% function inst = sminstlookup(dev)
% % inst = sminstlookup(dev)
% % Convert instrument name dev to index. Dev can be either the device (must be unique) or
% % name of the instrument.
% 
% global smdata;
% 
% if ~isnumeric(dev)
%     inst = strmatch(dev, strvcat(smdata.inst.name), 'exact');
%     if isempty(inst)
%         inst = strmatch(dev, strvcat(smdata.inst.device), 'exact');
%     end
% else
%     inst = dev;
% end
% 
% if isempty(inst)
%     fprintf('Invalid instrument\n');
%     return;
% end

function inst = sminstlookup(dev)
% inst = sminstlookup(dev)
% Convert instrument name dev to index. Dev can be either the device (must be unique) or
% name of the instrument.
%%JDSY 01-25-2011 Fixed this code, previously if inst did not have a
%%name would not work correctly

global smdata;
inst = [];
if ~isnumeric(dev)
    %%JDSY 01-25-2011 Fixed this code, previously if inst did not have a
    %%name would not work correctly
    %%inst = strmatch(dev, strvcat(smdata.inst.name), 'exact');
    
    for i=1:length(smdata.inst)
        if strcmpi(smdata.inst(i).name,dev)
            inst = i;
        end
    end
    if isempty(inst)
        for i=1:length(smdata.inst)
        if strcmpi(smdata.inst(i).device,dev)
            inst = i;
        end
    end
    end
else
    inst = dev;
end

if isempty(inst)
    fprintf('Invalid instrument\n');
    return;
end
