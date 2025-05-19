
device = instrfind('Type', 'serial', 'Port', 'COM7', 'Tag', '');

% Create the serial port object if it does not exist
% otherwise use the object that was found.
if isempty(device)
    device = serial('COM7');
else
    fclose(device);
    device = device(1);
end

% Connect to instrument object, obj1.
fopen(device);

addr = 1;

config.dref = 0;
config.remote = 1;
config.channel = 2;
config.range = 5; 
config.excitation = 3; % 30uV excitation
config.display = 0; % Display R
config.input = 1; % 0: Zero, 1: Measure
config.disableal = 1;

avs47Configure(device, addr, config);

pause(10);

result = avs47Read(device, addr, config)

fclose(device);
