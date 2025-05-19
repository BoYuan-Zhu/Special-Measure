function status = OI_PartRec(val)
    smset('Turbo1',0);
    smset('V9',0);
    smset('V4',1);
    smset('V1',0);
    smset('HStill',50000);
    P1 = cell2mat(smget('P1'));
    while P1 <= val
        pause(10);
        P1 = cell2mat(smget('P1'));
        fprintf('%s: Collecting Mixture...P1 = %f bar\n',DTnow(),P1);
    end
    smset('HStill',0);
    smset('V4',0);
    smset('V1',1);
    fprintf('%s: Partial Recovery succeed...P1 = %f bar\n',DTnow(),P1);
    status = 1;
end

function DTnow=DTnow()
        DTnow = datetime('now', 'Format', 'MM/dd/yyyy HH:mm:ss');
end


