function val = smcLeCroy(ico, val, rate)

global smdata;


switch ico(3)                
    case 0
     
        %fprintf(smdata.inst(ico(1)).data.inst, 'COMM_FORMAT ON');
        fprintf(smdata.inst(ico(1)).data.inst, 'C%i:WF? ALL', ico(2));
        %fprintf(smdata.inst(ico(1)).data.inst, 'C2:WF? ALL');
       
        %ndig = fscanf(smdata.inst(ico(1)).data.inst, '%*11c%d', 12);
        nbyte = fscanf(smdata.inst(ico(1)).data.inst, '%*12c%d', 21);
        data = int8(fread(smdata.inst(ico(1)).data.inst, nbyte, 'int8'))


        offset = typecast(data(37:40), 'int32');
        scale = typecast(data(157:164), 'single')  % GAIN, Offset

        %val = double(data(offset+1:end)) * scale(1) - scale(2);
        %val = double(typecast(data(offset+1:end), 'int16')) * scale(1) - scale(2);
        if typecast(data(33:34), 'int16')
            val = double(typecast(data(offset+1:end), 'int16')) * scale(1) - scale(2);
            figure;plot(val)
        else
            val = double(data(offset+1:end)) * scale(1) - scale(2);
            figure;plot(val)
        end
    
%     case 4
%         val=query(smdata.inst(ic(1)).data.inst,'C3:INSPECT?')
%         
    otherwise
        error('Operation not supported');
end
