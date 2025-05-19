function val = smcPCI6259(ic, val, rate)

global smdata DAC%maybe add some global variables here for amplitude and frequency of ramp
switch ic(2) % channel
    case 1  %set up sawtooth, trigger and acquire single ramp
        outputSingleScan(DAC,(val));
%         rate =50000;
%         DAC.Rate=rate;   % AD is structure of Digilent DAQ session
%         f=25;
%         duration = 1/f; %acquire one period
%         t = (1:(duration*rate))/rate;
%         output = 2*(sawtooth(2*pi*f*t)'+1);
%         DAC.queueOutputData(output);        
%         %[data, timestamps, triggerTime] = s.startForeground;
%         data = DAC.startForeground;
%         data = decimate(data(:,1),10);
%         val = data';
        
   case 2  %set up sawtooth, trigger and acquire single ramp
        
        rate =50000;
        DAC.Rate=rate;   % AD is structure of Digilent DAQ session
        f=25;
        duration = 1/f; %acquire one period
        t = (1:(duration*rate))/rate;
        output = 2*(sawtooth(2*pi*f*t)'+1);
        DAC.queueOutputData(output);        
        %[data, timestamps, triggerTime] = s.startForeground;
        data = DAC.startForeground;
        data = decimate(data(:,1),10);
        val = data';
        
end