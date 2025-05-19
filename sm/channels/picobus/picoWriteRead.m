function ret = picoWriteRead( device, data )
% Write and read data from previously specified address
% Both input and output are 48-element bit array

% Output has the same size as input
ret = zeros(size(data));

for i=1:length(data)
    picoSetCP(device, 0);
    ret(i) = picoGetDI(device); % Read bit
    picoSetDC(device, data(i)); % Write bit
    
%     pause(0.01);
    
    % Clock in
    picoSetCP(device, 1);
    
%     pause(0.01);
    
    picoSetCP(device, 0);
    picoSetDC(device, 0);
    
%     pause(0.01);
end

picoStrobe(device);

end

