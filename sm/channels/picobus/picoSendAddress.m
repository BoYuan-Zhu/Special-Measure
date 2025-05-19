function picoSendAddress( device, address )
%Send Picobus address

% Convert to 8-bit binary. This array starts with MSB
ba = de2bi(address, 8, 'left-msb');

for b=ba
    % Send bits one by one
    
    picoSetCP(device, 0);
    picoSetDC(device, b);
    
%     pause(0.01);
    
    % Clock in
    picoSetCP(device, 1);
    
%     pause(0.01);
    
    % Reset
    picoSetCP(device, 0);
    picoSetDC(device, 0);
    
%     pause(0.01);
end

picoStrobe(device);

end

