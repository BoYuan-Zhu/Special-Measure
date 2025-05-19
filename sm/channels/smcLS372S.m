function val = smcLS372(ic, val, rate)
%Channels
%1 - '50K' Temperature 50K flange
%5 - 'Still' Temperature Still
%2 - '4K' Temperature 4K Flange
%3 - 'Magnet' Temperature Magnet
%6 - 'MC' Temperature Mixing Chmber

%7 - 'SPnt' Set Point temperature

%8 - 'Range' set output and range input [Output, Sample range]
%   output = 0,1,2 : sample heater, warm-up, heater, still; 
%   Sample range = 0,1,2,3,4,5,6,7,8:
%   off,100nW,1uW,10uW,100uW,1mW,10mW,100mW,1W

%   warm-up heater, still range: 0,1: off,on

%9 - 'Ramp' Set Point temperature:input [output,off/on,rate]
%   Output  0 = sample heater; 1 = warm-up heater
%   off/om  0 = off, 1 = on 
%   rate            K/min


%10 - 'ExAuRe' Set Excitation current and resistance range 
% Current range : 1:1pA    Auto,0:off/1 on  resistance Range  1: 2mOhm
%                   2:3.16pA                            2: 6.32mOhm
%                   3:10pA                              3: 20mOhm
%                   4:31.6pA                            4: 63.2mOhm
%                   5:100pA                             5: 200mOhm
%                   6:316pA                             6: 632mOhm
%                   7:1nA                               7: 2Ohm
%                   8:3.16nA                            8: 6.32Ohm
%                   9:10nA                              9: 20Ohm
%                   10:31.6nA                           10: 63.2Ohm
%                   11:100nA                            11: 200Ohm
%                   12:316nA                            12: 632Ohm
%                   13:1uA                              13: 2KOhm
%                   14:3.16uA                           14: 6.32KOhm
%                   15:10uA                             15: 20KOhm
%                   16:31.6uA                           16: 63.2KOhm 
%                   17:100uA                            17: 200KOhm
%                   18:316uA                            18: 632KOhm
%                   19:1mA                              19: 2MOhm
%                   20:3.16mA                           20: 6.32MOhm
%                   21:10mA                             21: 20MOhm
%                   22:31.6mA                           22: 63.2MOhm

%11  'MOut' Set Manual Output

%12 - 'OutMode' Set OutMode  to either manual or PID
%Driver for LakeShore 372 Temp Controller

global smdata;
inst = smdata.inst(ic(1)).data.inst;
switch ic(2) % Channels 
    case 1 %Read Temperature 50K
        val = query(smdata.inst(ic(1)).data.inst, 'KRDG?1', '%s\n', '%f');
    case 2 %Read Temperature Still
        val = query(smdata.inst(ic(1)).data.inst, 'KRDG?2', '%s\n', '%f');
    case 3 %Read Temperature 4K
        val = query(smdata.inst(ic(1)).data.inst, 'KRDG?3', '%s\n', '%f');
    case 5 %Read Temperature Magnet
        val = query(smdata.inst(ic(1)).data.inst, 'KRDG?5', '%s\n', '%f');    
    case 6 %Read Temperature Mixing Chamber
        val = query(smdata.inst(ic(1)).data.inst, 'KRDG?6', '%s\n', '%f');    
  
    case 7 %Temperature Setpoint
        switch ic(3)
            case 0 %Get
                val = query(smdata.inst(ic(1)).data.inst, 'SETP? 0', '%s\n', '%f');
            case 1 %Set
                fprintf(inst, sprintf('SETP 0, %f', val));
            otherwise
                error('LS372 driver: Operation not supported');
        end
    case 8 %Output and Range
        switch ic(3)
            case 0 %Get Output
                val = query(smdata.inst(ic(1)).data.inst, 'RANGE?', '%s\n', '%f');
            case 1 %Set 
                if val < 0 || val > 8
                    error('LS372 driver: Unsupported Heater Power Setting');
                end
                fprintf(inst, sprintf('RANGE 0,%d', val));
            otherwise
                error('LS372 driver: Operation not supported');
        end
    case 9 %Ramp
        switch ic(3)
            case 0 %Get On/Off Status of Output ? and its Rate
                val = query(smdata.inst(ic(1)).data.inst, sprintf('RAMP? 6'), '%s\n', '%f, %f');
                val = val(2); % return the rate
            case 1 %Set the output status on/off and rate
                if val == 0
                    fprintf(inst, sprintf('RAMP 0, 0, %f,', val));
                else
                    fprintf(inst, sprintf('RAMP 0, 1, %f,', val));
                end                
            otherwise
                error('LS372 driver: Operation not supported');
        end
    case 10  %Excitation   Auto Resistance
        switch ic(3)
            case 0 %Get
                
                val = query(smdata.inst(ic(1)).data.inst, 'INTYPE? 6', '%s\n','%1d,%2d,%1d,%2d,%1d,%1d');
                val = val(2)+val(3)/10+ val(4)/1000; 

            case 1 %Set
                if val < 0 || val >22 
                    error('LS372 driver: Unsupported Heater Power Setting');
                end
                Ex = fix(val);Auto = fix(mod(val*10,10));Re = fix(mod(val*1000,100));
                fprintf(inst, sprintf('INTYPE 6, 1, %d, %d, %d, 0, 1',Ex,Auto,Re));     
                
                        
            otherwise
                error('LS372 driver: Operation not supported');
        end
        
    case 11 % manual sample output 
        switch ic(3)
            case 0 %Get Output
                val = query(smdata.inst(ic(1)).data.inst, 'MOUT?''%s\n','%s');
                val = str2double(val(1:12));
                %val = val()
            case 1 %Set 
                fprintf(inst, sprintf('Mout 0,%u', val));
            otherwise
                error('LS372 driver: Operation not supported');
        end
    case 12% OutMode   0:Off ; 2: Manual ; 5:Closed Loop PID
         switch ic(3)
         case 0 %Get Output
                val = query(smdata.inst(ic(1)).data.inst, 'OUTMODE? 0''%s\n','%s');
                val = str2double(val(1));
                %val = val()
            case 1 %Set 
                fprintf(inst, sprintf('OUTMODE 0,%d,6,1,0,0,1', val));
            otherwise
                error('LS372 driver: Operation not supported');
        end
       otherwise
            error('LS372 driver: Nonvalid Channel specified');
end

end

