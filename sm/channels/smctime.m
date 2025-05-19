function val = smctime(ic, val, rate)

%time driver

global smdata;

switch ic(3); %Operation: 0 for read, 1 for write

    case 0 %just read time
        val=toc;
                  
    case 1 %write operation;  
        error('Unfortunately, this program cannot control Time... yet');
        
    otherwise
        error('Operation not supported');
end

