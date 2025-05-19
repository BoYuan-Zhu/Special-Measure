function onturbo
    % Configuration and connection
    t = tcpip('127.0.0.1',12345);

    % Open socket and wait before sending data
    fopen(t);
    pause(0.2);

    % Send data every 500ms

        query(t,'remote')
        pause(0.5);
        query(t,'remote 1')
        pause(0.5);
        query(t,'control 1')
        pause(0.5);
        query(t,'remote 1')
        pause(0.5);
        DataToSend='on turbo1';
        query(t,DataToSend)
        pause(0.5);
        query(t,'remote 0')
        pause(0.5);
        query(t,'exit')
        pause(0.5);

    % Close and delete connection
    fclose(t);
    delete(t);
end