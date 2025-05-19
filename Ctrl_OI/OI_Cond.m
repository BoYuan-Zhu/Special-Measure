function status = OI_Cond(inst)
    fret = query(inst, 'SET:SYS:DR:ACTN:COND', '%s\n', '%s\n');
    status = fret;
    if contains(fret,':VALID')
        fprintf('%s: Start Full Condense.\n',DTnow());
    else
        error('%s: Mix Compressor Driver: Operation not supported\n',DTnow());
    end
    fret = query(inst, 'READ:SYS:DR:ACTN', '%s\n', '%s\n');
    while ~contains(fret,'NONE')
        pause(10);
        fret = query(inst, 'READ:SYS:DR:ACTN', '%s\n', '%s\n');
        P1 = query(inst,'READ:DEV:P1:PRES:SIG:PRES', '%s\n', 'STAT:DEV:P1:PRES:SIG:PRES:%fmB\n')/1000;
        fprintf('%s: Condensing in progress...P1 = %f bar\n',DTnow(),P1);
    end
    fprintf('%s: Condensing Done...P1 = %f bar\n',DTnow(),P1);
end

function DTnow=DTnow()
        DTnow = datetime('now', 'Format', 'MM/dd/yyyy HH:mm:ss');
end