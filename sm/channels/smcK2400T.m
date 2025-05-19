function val = smcK2400T(ic, val, rate)

%Hard wired Temperature conversion into the control function

global smdata;

strchan = smdata.inst(ic(1)).channels(ic(2));

    if strchan == 'T'
        switch ic(3); %Operation: 0 for read, 1 for write

        case 0 %just read voltage for now
            %'case 0'
            KO = query(smdata.inst(ic(1)).data.inst, 'READ?', '%s\n', '%f,%f,%f,%f,%f');
            V = abs(KO(1));
            val = Tsensor(V);

        case 1 %write operation;  %support only voltage write now
            % do nothing

        otherwise
            error('Operation not supported');
        end
    
end
        
end

