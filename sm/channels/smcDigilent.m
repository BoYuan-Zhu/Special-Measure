function val = smcDigilent(ic, val, rate)

global smdata AD%maybe add some global variables here for amplitude and frequency of ramp
switch ic(2) % channel
    case 1  %set up sawtooth, trigger and acquire single ramp
        
        rate =50000;
        AD.Rate=rate;   % AD is structure of Digilent DAQ session
        f=25;
        duration = 1/f; %acquire one period
        t = (1:(duration*rate))/rate;
        output = 2*(sawtooth(2*pi*f*t)'+1);
        AD.queueOutputData([output,output*0]);
        %[data, timestamps, triggerTime] = s.startForeground;
        data = AD.startForeground;
        data = decimate(data(:,1),10);
        val = data';
end