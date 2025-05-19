function picoStrobe( device )
% Performs strobe

% DC Must be cycled three times when CP is low

picoSetCP(device, 0);

for i=1:3
    picoSetDC(device, 0);

%     pause(0.01);

    picoSetDC(device, 1);

%     pause(0.01);
end

picoSetDC(device, 0);

end

