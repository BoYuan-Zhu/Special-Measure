function picoSetDC( device, newvalue )
%Set DC (DTR) output

if newvalue == 1
    device.DataTerminalReady = 'on';
else
    device.DataTerminalReady = 'off';
end

end

