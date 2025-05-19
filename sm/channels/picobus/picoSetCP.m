function picoSetCP( device, newvalue )
%Set CP (RTS) output

if newvalue == 1
    device.RequestToSend = 'on';
else
    device.RequestToSend = 'off';
end
end

