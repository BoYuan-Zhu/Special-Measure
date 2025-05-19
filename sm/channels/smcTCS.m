function val = smcTCS( ic, val, rate)
% Triple Current Source (Leiden Cryogenics) controller instrument
%% Author: Yuan Cao
% Date: 5/29/2017

% Channels:
% SRC1-3
% Current values specified in milliamps (mA)

global smdata;

inst = ic(1);
chan = ic(2);
rw = ic(3);

device = smdata.inst(inst).data.inst;

if rw == 0
    response = str2num(query(device, 'STATUS?'));
    
    range = response(chan*4-1);
    current = response(chan*4);
    on = response(chan*4+1);
    
    if on == 0
        val = 0;
    else
        val = current * 10^(range - 4);
    end
else
    response = str2num(query(device, 'STATUS?'));
    
    % Use autorange
    query(device, sprintf('SETDAC %d %d %d', chan, 0, floor(val*1000)));
    if val > 0 && response(chan*4+1) == 0 || val == 0 && response(chan*4+1) == 1
        % Toggle output
        
        setup = zeros(12,1);
        setup(chan * 4 - 1) = 1; 
        
        setup = sprintf('%d,', setup); setup = setup(1:end-1);

        query(device, sprintf('SETUP %s', setup));
    end
end



end

    