function val = smcLS372(ic, val, rate)
%Channels
%1 - '50K' Temperature 50K flange
%2 - 'Still' Temperature Still
%3 - '4K' Temperature 4K Flange
%5 - 'Magnet' Temperature Magnet
%6 - 'MC' Temperature Mixing Chmber

%7 - 'SPnt' Set Point temperature

%8 - 'PRng' set output and range input [Output, Sample range]
%   output = 0,1,2 : sample heater, warm-up, heater, still; 
%   Sample range = 0,1,2,3,4,5,6,7,8: off,31.6uA,100uA,316uA,1mA,3.16mA,10mA,31.6mA,100mA
%   warm-up heater, still range: 0,1: off,on

%9 - 'Ramp' Set Point temperature:input [output,off/on,rate]
%   Output  0 = sample heater; 1 = warm-up heater
%   off/om  0 = off, 1 = on 
%   rate            K/min


%10 - 'excI' Set Point temperature

%Driver for LakeShore 370 Temp Controller

global smdata;
inst = smdata.inst(ic(1)).data.inst;
switch ic(2) % Channels 
%     case 1 %Read Temperature 50K
%         val = query(smdata.inst(ic(1)).data.inst, 'KRDG?1', '%s\n', '%f');
%     case 2 %Read Temperature Still
%         val = query(smdata.inst(ic(1)).data.inst, 'KRDG?2', '%s\n', '%f');
%     case 3 %Read Temperature 4K
%         val = query(smdata.inst(ic(1)).data.inst, 'KRDG?3', '%s\n', '%f');
%     case 5 %Read Temperature Magnet
%         val = query(smdata.inst(ic(1)).data.inst, 'KRDG?5', '%s\n', '%f');    
   
    case 6 %Read Temperature Mixing Chamber
        val = query(smdata.inst(ic(1)).data.inst, 'KRDG?6', '%s\n', '%f');    
  
%     case 7 %Temperature Setpoint
%         switch ic(3)
%             case 0 %Get
%                 val = query(smdata.inst(ic(1)).data.inst, 'SETP? 0', '%s\n', '%f');
%             case 1 %Set
%                 fprintf(inst, sprintf('SETP 0, %f', val));
%             otherwise
%                 error('LS372 driver: Operation not supported');
%         end
%     case 8 %Output and Range
%         switch ic(3)
%             case 0 %Get Output
%                 val = query(smdata.inst(ic(1)).data.inst, 'RANGE?', '%s\n', '%f');
%             case 1 %Set 
%                 if val < 0 || val > 2
%                     error('LS372 driver: Unsupported Heater Power Setting');
%                 end
%                 fprintf(inst, sprintf('RANGE 0,%d', val));
%             otherwise
%                 error('LS372 driver: Operation not supported');
%         end
%     case 9 %Ramp
%         switch ic(3)
%             case 0 %Get On/Off Status of Output ? and its Rate
%                 val = query(smdata.inst(ic(1)).data.inst, sprintf('RAMP? 0'), '%s\n', '%f, %f');
%                 val = val(2); % return the rate
%             case 1 %Set the output status on/off and rate
%                 if val == 0
%                     fprintf(inst, sprintf('RAMP 0, 0, %f,', val));
%                 else
%                     fprintf(inst, sprintf('RAMP 0, 1, %f,', val));
%                 end                
%             otherwise
%                 error('LS372 driver: Operation not supported');
%         end
%     case 10
%         switch ic(3)
%             case 0 %Get
%                 val = query(smdata.inst(ic(1)).data.inst, 'INTYPE? C', '%s\n','%s');
%             case 1 %Set
%                 if val < 0 || val >11 
%                     error('LS372 driver: Unsupported Heater Power Setting');
%                 end
%                 fprintf(inst, sprintf('INTYPE C, 0, 2, 1, %1.0f, 4', val));                
%             otherwise
%                 error('LS372 driver: Operation not supported');
%         end
    otherwise
            error('LS372 driver: Nonvalid Channel specified');
end

end

