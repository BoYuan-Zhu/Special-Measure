global smdata; 
global smscan;
global PPMS;


% Assembly File generation from DLL
AssemblyFile = NET.addAssembly('C:\Users\WangLabAdmin\Documents\QDInstrument_LabVIEW\QDInstrument.dll');


%Creation and Initialization of Instance for Instrument Type
PPMS.HandleInstrumentType = AssemblyFile.AssemblyHandle.GetType('QuantumDesign.QDInstrument.QDInstrumentBase+QDInstrumentType');
%PPMS.InstrumentType = System.Activator.CreateInstance(PPMS.HandleInstrumentType);

PPMS.InstrumentType = PPMS.HandleInstrumentType.GetEnumValues().Get(2); 

%PPMS.InstrumentType = QuantumDesign.QDInstrument.QDInstrumentType.DynaCool;

% Creation of Instance to communicate with the PPMS
PPMS.Instrument = QuantumDesign.QDInstrument.QDInstrumentFactory.GetQDInstrument(PPMS.InstrumentType, true, '128.174.164.13');

% %Creating Instance to store temperature status
PPMS.handleTemperatureStatus = AssemblyFile.AssemblyHandle.GetType('QuantumDesign.QDInstrument.QDInstrumentBase+TemperatureStatus');
PPMS.TemperatureStatus = System.Activator.CreateInstance(PPMS.handleTemperatureStatus);

%Creating Instance to store Field status
PPMS.handleFieldStatus = AssemblyFile.AssemblyHandle.GetType('QuantumDesign.QDInstrument.QDInstrumentBase+FieldStatus');
PPMS.FieldStatus = System.Activator.CreateInstance(PPMS.handleFieldStatus);

%Creating Instance to store FieldApproach
PPMS.handleFieldApproach = AssemblyFile.AssemblyHandle.GetType('QuantumDesign.QDInstrument.QDInstrumentBase+FieldApproach');
PPMS.FieldApproach = System.Activator.CreateInstance(PPMS.handleFieldApproach);
% PPMS.FieldApproach = QuantumDesign.QDInstrument.FieldApproach.Linear;

%Creating Instance to store TemperatureApproach
PPMS.handleTemperatureApproach = AssemblyFile.AssemblyHandle.GetType('QuantumDesign.QDInstrument.QDInstrumentBase+TemperatureApproach');
PPMS.TemperatureApproach = System.Activator.CreateInstance(PPMS.handleTemperatureApproach);
% PPMS.TemperatureApproach = QuantumDesign.QDInstrument.TemperatureApproach.FastSettle;

%Creating Instance to store FieldApproach
PPMS.handleFieldMode = AssemblyFile.AssemblyHandle.GetType('QuantumDesign.QDInstrument.QDInstrumentBase+FieldMode');
PPMS.FieldMode = System.Activator.CreateInstance(PPMS.handleFieldMode);
% PPMS.FieldMode = QuantumDesign.QDInstrument.FieldMode.Driven;
%PPMS.FieldMode = QuantumDesign.QDInstrument.FieldMode.Persistent;