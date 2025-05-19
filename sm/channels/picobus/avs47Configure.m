function ret = avs47Configure( device,  address, config)
% Send configuration to AVS47

% Data vector
data = zeros(1,48);

data(1:16) = de2bi( floor(config.dref / 5), 16, 'left-msb');
data(17:24) = [0,0,0,0,0,0,1,1]; % Ref ADDR = 3
data(25:26) = [0,0];
data(27:28) = de2bi(config.input, 2, 'left-msb');
data(29:31) = de2bi(config.channel, 3, 'left-msb');
data(32:34) = de2bi(config.display, 3, 'left-msb');
data(35:37) = de2bi(config.excitation, 3, 'left-msb');
data(38:40) = de2bi(config.range, 3, 'left-msb');
data(41) = 0;
data(42) = config.remote;
data(43) = 0;
data(44) = config.disableal;
data(45:48) = [0,0,0,0];

% Send address
picoSendAddress(device, address);

% Write data
ret = picoWriteRead(device, data);


end

