function inrange = smfunc_checkinrange(ind, values)
    global smdata
    inrange = 1;
    newval = zeros(1,length(smdata.inst(ind).data.formula));
    for i=1:length(smdata.inst(ind).data.dependences)
        func=smdata.inst(ind).data.formula{i};
        switch(nargin(func))
            case 1
                newval(i) = func(values(1));
            case 2
                newval(i) = func(values(1),values(2));
            case 3
                newval(i) = func(values(1),values(2),values(3));
            case 4
                newval(i) = func(values(1),values(2),values(3),values(4));
            case 5
                newval(i) = func(values(1),values(2),values(3),values(4),values(5));
            case 6
                newval(i) = func(values(1),values(2),values(3),values(4),values(5),values(6));
            case 7
                newval(i) = func(values(1),values(2),values(3),values(4),values(5),values(6),values(7));
            otherwise
                newval(i) = func(values(1),values(2),values(3),values(4),values(5),values(6),values(7),values(8));
        end
        channel=smchanlookup(smdata.inst(ind).data.dependences{i});
        if newval(i)<smdata.channels(channel).rangeramp(1) || newval(i)>smdata.channels(channel).rangeramp(2)
            inrange = 0;
            return;
        end
    end
end

