function val = smcLakeShore(ic, val, rate)

%Device driver for Lakeshore T controller
%Written by Hadar, May 2010

global smdata;

strchan = smdata.inst(ic(1)).channels(ic(2));
switch strchan
    case 'A'
        T = query(smdata.inst(ic(1)).data.inst,'KRDG? A');
    case 'B'
        T = query(smdata.inst(ic(1)).data.inst,'KRDG? B');
    case 'C'
        T = query(smdata.inst(ic(1)).data.inst,'KRDG? C');
  
end
val = str2num(T);

end

