function value = picoGetAL( device )
% Get status of AL (DSR) 

value = strcmp(device.PinStatus.DataSetReady, 'on');

end
