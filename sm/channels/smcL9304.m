function val = smcL9304(ic, val, rate)

%skeletal driver for LeCroy 9304 scope


global smdata;

switch ic(2); %Channels
    case 1 %Read CH1
        switch ic(3); %Operation: 0 for read, 1 for write

             case 0 %just read voltage for now
                fprintf(smdata.inst(ic(1)).data.inst, 'CMD$="SCDP":CALL IBWRT(SCOPE%, CMD$');
               
                  
                
            case 1 %write operation;  
                error('The LeCroy 9304 does not support write operations');
            otherwise
                error('Operation not supported');
        end
    
    otherwise
        error('Operation not supported');
end




