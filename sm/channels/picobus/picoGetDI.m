function value = picoGetDI( device )
% Get status of DI (CTS) 

value = strcmp(device.PinStatus.ClearToSend, 'on');

end

