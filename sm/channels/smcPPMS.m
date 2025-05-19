function val = smcPPMS(ico, val, rate)
%Driver for the PPMS Temperature and Field control
%channel 1 = Temperature
%channel 2 = Field
global smdata;
global PPMS;

% % Assembly File generation from DLL
% AssemblyFile = NET.addAssembly('C:\Users\Administrator\Dropbox (Princeton)\Wu Lab\Instruments Recipe and Test\Dynacool\Matlab\SpecialMeasure\Dynacool Test\QDInstrument.dll');
% 
% %Creation and Initialization of Instance for Instrument Type
% HandleInstrumentType = AssemblyFile.AssemblyHandle.GetType('QuantumDesign.QDInstrument.QDInstrumentBase+QDInstrumentType');
% InstrumentType = System.Activator.CreateInstance(HandleInstrumentType);
% InstrumentType = QuantumDesign.QDInstrument.QDInstrumentType.PPMS;
% 
% % Creation of Instance to communicate with the PPMS
% Instrument = QuantumDesign.QDInstrument.QDInstrumentFactory.GetQDInstrument(QuantumDesign.QDInstrument.QDInstrumentType.PPMS, false, '127.0.0.1');
% 
% %Creating Instance to store temperature status
% handleTemperatureStatus = AssemblyFile.AssemblyHandle.GetType('QuantumDesign.QDInstrument.QDInstrumentBase+TemperatureStatus');
% TemperatureStatus = System.Activator.CreateInstance(handleTemperatureStatus);
% 
% %Creating Instance to store Field status
% handleFieldStatus = AssemblyFile.AssemblyHandle.GetType('QuantumDesign.QDInstrument.QDInstrumentBase+FieldStatus');
% FieldStatus = System.Activator.CreateInstance(handleFieldStatus);
% 
% %Creating Instance to store FieldApproach
% handleFieldApproach = AssemblyFile.AssemblyHandle.GetType('QuantumDesign.QDInstrument.QDInstrumentBase+FieldApproach');
% FieldApproach = System.Activator.CreateInstance(handleFieldApproach);
% 
% %Creating Instance to store TemperatureApproach
% handleTemperatureApproach = AssemblyFile.AssemblyHandle.GetType('QuantumDesign.QDInstrument.QDInstrumentBase+TemperatureApproach');
% TemperatureApproach = System.Activator.CreateInstance(handleTemperatureApproach);
% 
% %Creating Instance to store FieldMode
% handleFieldMode = AssemblyFile.AssemblyHandle.GetType('QuantumDesign.QDInstrument.QDInstrumentBase+FieldMode');
% FieldMode = System.Activator.CreateInstance(handleFieldMode);

status = 0;

switch ico(2) % channel
    case 1 %Temperature
        switch ico(3) %operation
            case 1 %set
                rate=20;
                PPMS.Instrument.SetTemperature(val,rate,PPMS.TemperatureApproach);
           
            case 0 %get
                val = 0.0;
                [status,val,PPMS.TemperatureStatus] = PPMS.Instrument.GetTemperature(val,PPMS.TemperatureStatus);
                
            otherwise
                error('Operation not supported');
        end
    case 2 %Field
        switch ico(3) %operation
            case 1 %set
                rate = 150;
                PPMS.Instrument.SetField(val,rate,PPMS.FieldApproach,PPMS.FieldMode);
                % pause(30); %line added by onder gul 01.2019. Purpose: wait until the setfield is reached. argument = stepsize/ramprate + 5 seconds
                
            case 0 %get
                val = 0.0;
                [status,val,PPMS.FieldStatus] = PPMS.Instrument.GetField(val,PPMS.FieldStatus);
                
            otherwise
                error('Operation not supported');
        end
    otherwise
        error('Channel not supported');
end