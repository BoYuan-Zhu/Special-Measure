function result = avs47Read( device, address, config)
% Performs a read on a specified channel. It waits until the next ADC finishes

config.disableal = 0;
avs47Configure(device, address, config);

timeout = 30; % Timeout: 30s
tic;

while (toc < timeout)
    if picoGetAL(device) == 1
        break;
    end
    pause(0.01);
end

if(toc >= timeout)
    error('AVS-47 Read operation timeout: No response from device.');
end

% Now read the result
config.disableal = 1;
ret = avs47Configure(device, address, config);

result = avs47Decode(ret);

end
