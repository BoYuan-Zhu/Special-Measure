% 1K Setup Instrument Initialization
%---------------------

%Clear out Matlab
clear all;
close all;
instrreset;

%GPIB addresses
GPIB_BOARD='ni';
BOARD_NUM=0;
LockInUpper_GPIB   = 5;
LockInMiddle_GPIB   = 6;
LockInLower_GPIB   = 7;
SourceMeter_GPIB   = 23;
DMM1_GPIB=22;
DMM2_GPIB=24;
DAC_COM='COM2';
Magnet_COM='COM1';

%Use or not (1:use, 0:not)
LockInUpper_Use=1;
LockInMiddle_Use=1;
LockInLower_Use=1;
SourceMeter_Use=1;
DMM1_Use=0;
DMM2_Use=0;
DAC_Use=0;
Magnet_Use=1;

%Instrument mode selection
SourceMeter_CH1_Mode='Voltage';
SourceMeter_CH2_Mode='Voltage';
DMM1_Mode='Current';

% load empty smdata shell (where all instruments and channels go)
global smdata;
global smscan;
load smdata_empty;


%% Add instruments to rack

% load dummy instrument
smloadinst('test');
smloadinst('time');

% add dummy channels
%smaddchannel('test', 'CH1', 'dummy');
smaddchannel('test', 'CH2', 'count');

smaddchannel('time','time','time');
%------------


%% add LockInUpper

if LockInUpper_Use==1

    try
        ind = smloadinst('SR830', [], GPIB_BOARD, BOARD_NUM, LockInUpper_GPIB);
        %open GPIB communication
        smopen(ind);

        smdata.inst(ind).name = 'LockIn_Upper';

        %add channels
        smaddchannel('LockIn_Upper', 'X', 'X_A', [-Inf, Inf, Inf, 1]);
        smaddchannel('LockIn_Upper', 'Y', 'Y_A', [-Inf, Inf, Inf, 1]);
        smaddchannel('LockIn_Upper', 'FREQ', 'Freq_A', [0, 102000, 10, 1]);
        smaddchannel('LockIn_Upper', 'VREF', 'Vref_A', [0.004, 5, 0.5, 1]);

    catch err
        fprintf(['*ERROR* problem with connecting to LockIn_Upper\n' err.identifier ': ' err.message '\n'])
    end

end

%% add LockInMiddle
if LockInMiddle_Use==1

    try
        ind = smloadinst('SR830', [], GPIB_BOARD, BOARD_NUM, LockInMiddle_GPIB);
        %open GPIB communication
        smopen(ind);
        smdata.inst(ind).name = 'LockIn_Middle';

        %add channels
        smaddchannel('LockIn_Middle', 'X', 'X_B', [-Inf, Inf, Inf, 1]);
        smaddchannel('LockIn_Middle', 'Y', 'Y_B', [-Inf, Inf, Inf, 1]);
        smaddchannel('LockIn_Middle', 'FREQ', 'Freq_B', [0, 102000, 10, 1]);
        smaddchannel('LockIn_Middle', 'VREF', 'Vref_B', [0.004, 5, 0.5, 1]);

    catch err
        fprintf(['*ERROR* problem with connecting to LockIn_Middle\n' err.identifier ': ' err.message '\n'])
    end

end
%% add LockInLower
if LockInLower_Use==1

    try
        ind = smloadinst('SR830', [], GPIB_BOARD, BOARD_NUM, LockInLower_GPIB);
        %open GPIB communication
        smopen(ind);
        smdata.inst(ind).name = 'LockIn_Lower';

        %add channels
        smaddchannel('LockIn_Lower', 'X', 'X_C', [-Inf, Inf, Inf, 1]);
        smaddchannel('LockIn_Lower', 'Y', 'Y_C', [-Inf, Inf, Inf, 1]);
        smaddchannel('LockIn_Lower', 'FREQ', 'Freq_C', [0, 102000, 10, 1]);
        smaddchannel('LockIn_Lower', 'VREF', 'Vref_C', [0.004, 5, 0.5, 1]);

    catch err
        fprintf(['*ERROR* problem with connecting to LockIn_Lower\n' err.identifier ': ' err.message '\n'])
    end

end
%% add Source meter B2902A
if SourceMeter_Use==1

    try
        ind  = smloadinst('B2902A', [], GPIB_BOARD, BOARD_NUM, SourceMeter_GPIB);
        %setup GPIB communication parameters
        set(smdata.inst(ind).data.inst,'inputbuffersize',2^18); %assigns 262kb to the read buffer to enable it to take a full buffer of data with one request
        set(smdata.inst(ind).data.inst,'outputbuffersize',2^10);  %assigns 1kb to the write buffer
        set(smdata.inst(ind).data.inst,'eosmode','read&write');  %end of string character is used in both read and write operations
        set(smdata.inst(ind).data.inst,'timeout',5);

        %open GPIB communication
        smopen(ind);

        smdata.inst(ind).name = 'SourceMeter';

        %add channels
        smaddchannel('SourceMeter','V1','Vbg',[-15 17 20 1]);
        smaddchannel('SourceMeter','V2','Vtg',[-5 5 20 1]);
        smaddchannel('SourceMeter','I1','Ibg',[-10 10 Inf 1]);
        smaddchannel('SourceMeter','I2','Itg',[-10 10 Inf 1]);
        smaddchannel('SourceMeter','Icompl1','Ic1',[0 1 Inf 1]);
        smaddchannel('SourceMeter','Icompl2','Ic2',[0 1 Inf 1]);

        %set instrument parameters

        fprintf(smdata.inst(ind).data.inst,'*rst'); %resets the Keithley
        if(strcmp(SourceMeter_CH1_Mode,'Voltage'))
            fprintf(smdata.inst(ind).data.inst,':sense1:current:protection 1e-6'); %sets initial current compliance to 1uA
            fprintf(smdata.inst(ind).data.inst,':sense1:current:range:auto 1');    %sets the sense current limit to auto
        elseif(strcmp(SourceMeter_CH1_Mode, 'Current'))
            fprintf(smdata.inst(ind).data.inst,':source1:function:mode current');  %choose to source current
            %fprintf(smdata.inst(ind).data.inst,':sense1:function:concurrent off');  %choose to measure voltage
            fprintf(smdata.inst(ind).data.inst,':sense1:voltage:protection 1');  %sets initial voltage compliance
            fprintf(smdata.inst(ind).data.inst,':sense1:voltage:range:auto 1');  %sets limit on voltage sensing
        else
            error('No such mode for SourceMeter CH1: %s', SourceMeter_CH1_Mode);
        end
        % Turn on output, start continuous measurement
        fprintf(smdata.inst(ind).data.inst,':output1 on');
        fprintf(smdata.inst(ind).data.inst,':arm1:acq:count infinity');
        fprintf(smdata.inst(ind).data.inst,':init:acq (@1)');
        
        if(strcmp(SourceMeter_CH2_Mode,'Voltage'))
            fprintf(smdata.inst(ind).data.inst,':sense2:current:protection 1e-6'); %sets initial current compliance to 1uA
            fprintf(smdata.inst(ind).data.inst,':sense2:current:range:auto 1');    %sets the sense current limit to auto
        elseif(strcmp(SourceMeter_CH2_Mode, 'Current'))
            fprintf(smdata.inst(ind).data.inst,':source2:function:mode current');  %choose to source current
            %fprintf(smdata.inst(ind).data.inst,':sense2:function:concurrent off');  %choose to measure voltage
            fprintf(smdata.inst(ind).data.inst,':sense2:voltage:protection 1');  %sets initial voltage compliance
            fprintf(smdata.inst(ind).data.inst,':sense2:voltage:range:auto 1');  %sets limit on voltage sensing
        else
            error('No such mode for SourceMeter CH2: %s', SourceMeter_CH2_Mode);
        end
        % Turn on output, start continuous measurement
        fprintf(smdata.inst(ind).data.inst,':output2 on');
        fprintf(smdata.inst(ind).data.inst,':arm2:acq:count infinity');
        fprintf(smdata.inst(ind).data.inst,':init:acq (@2)');
    catch err
        fprintf(['*ERROR* problem with connecting to the Source\n' err.identifier ': ' err.message '\n'])
    end

end

%% add DMM1
if DMM1_Use==1
    try
        ind  = smloadinst('HP34401A', [], GPIB_BOARD, BOARD_NUM, DMM1_GPIB);

        %setup GPIB communication parameters
        set(smdata.inst(ind).data.inst,'inputbuffersize',2^18); %assigns 262kb to the read buffer to enable it to take a full buffer of data with one request
        set(smdata.inst(ind).data.inst,'outputbuffersize',2^10);  %assigns 1kb to the write buffer
        set(smdata.inst(ind).data.inst,'eosmode','read&write');
        set(smdata.inst(ind).data.inst,'timeout',10);    %increases timeout time to allow for large data transfers

        %open GPIB communication
        smopen(ind);

        smdata.inst(ind).name = 'DMM1';

        %add channels
        %add channels
        smaddchannel('DMM1','VAL','V1',[-Inf Inf Inf 1]);

        fprintf(smdata.inst(ind).data.inst,'*rst'); %resets the instrument
        %set instrument parameters
        if(strcmp(DMM1_Mode,'Voltage'))
            fprintf(smdata.inst(ind).data.inst,'configure:volt:dc');
            fprintf(smdata.inst(ind).data.inst,'sense:voltage:nplc 1'); % Select NPLC=1 for faster acquisition
        elseif(strcmp(DMM1_Mode,'Current'))
            fprintf(smdata.inst(ind).data.inst,'configure:curr:dc'); 
            fprintf(smdata.inst(ind).data.inst,'sense:curr:nplc 1'); % Select NPLC=1 for faster acquisition
        end
        fprintf(smdata.inst(ind).data.inst,'trig:count inf'); %turns on continuous readings
        fprintf(smdata.inst(ind).data.inst,'init'); %turns on continuous readings
    catch err
        fprintf(['*ERROR* problem with connecting to the Keysight DMM\n' err.identifier ': ' err.message '\n'])
    end

end

%% add DAC
if DAC_Use==1

    try
        ind = smloadinst('BabyDAC', [], 'serial', DAC_COM);
        
        %setup serial communication parameters
        set(smdata.inst(ind).data.inst,'BaudRate',9600);
        set(smdata.inst(ind).data.inst,'timeout',20);  %increases timeout time

        %open communication
        smopen(ind);

        smdata.inst(ind).name = 'DAC';

        %add channels

        smaddchannel('DAC', 'CH0', 'bg', [-10 10 10 1]);
        smaddchannel('DAC', 'CH1', 'tg', [-3 3 10 1]);
        
        %initialize the DAC
        %clear the buffer
        while smdata.inst(ind).data.inst.BytesAvailable > 0
            fscanf(smdata.inst(ind).data.inst);
            pause(0.3);
        end
        %reset any ramps
        for i=0:3
            stri = num2str(i);
            query(smdata.inst(ind).data.inst,['B0;M2;C' stri ';S0;']);
            query(smdata.inst(ind).data.inst,['B0;M2;C' stri ';U65535;']);
            query(smdata.inst(ind).data.inst,['B0;M2;C' stri ';L0;']);
            dac_zero=32768; %measured bit where DAC is zero
            bit_str=sprintf(['B0;M2;C' stri ';D%.0f;'],dac_zero);
            query(smdata.inst(ind).data.inst,bit_str); %sets the DAC to zero
        end

        %setup ranges to match switches on DAC - ALWAYS UPDATE IF SWITCHES ARE
        %CHANGED
        smdata.inst(ind).data.rng = [-10 10;-10 10;-10 10;-10 10;-10 10;-10 10;-10 10;-10 10;-10 10;-10 10;-10 10;-10 10];

    catch err
        fprintf(['*ERROR* problem with connecting to the DAC\n' err.identifier ': ' err.message '\n'])
    end

end

%% Add Magnet
if Magnet_Use == 1
    try
        ind = smloadinst('AMI430', [], 'serial', Magnet_COM);
        
        smopen(ind);
        smdata.inst(ind).name = 'Magnet';
        
        smaddchannel('Magnet','B','B',[-11,11,Inf,1]); % Ramping is controlled automatically
        smaddchannel('Magnet','Persistent','Persistent',[0,1,Inf,1]); % 1 = in persistent mode, 0 = not
        
    catch err
        fprintf(['*ERROR* problem with connecting to the MagnetController\n' err.identifier ': ' err.message '\n'])
    end
end

%% Custom Channels
%smaddchannel('LockIn_Upper', 'X', 'R2', [-Inf, Inf, Inf, 1e-7]);
smaddchannel('LockIn_Upper', 'X', 'I2', [-Inf, Inf, Inf, 1e7]);
smaddchannel('LockIn_Middle', 'X', 'V4xx', [-Inf, Inf, Inf, 1]);
smaddchannel('LockIn_Lower', 'X', 'V4xy', [-Inf, Inf, Inf, 1]);

%% Add Function channels

ind = smloadinst('Function');

smdata.inst(ind).data.dependences={'Vbg','Vtg'};
smdata.inst(ind).data.formula={...
    @(n,E) 1.18*n - 8.4*E + 2.4,...
    @(n,E) 0.95*n + 7.6*E + 2.6...
    };
smaddchannel('Function', 'VAR1', 'n'); % Density (10^12 cm^-2)
smaddchannel('Function', 'VAR2', 'E'); % Electric field (arb.unit)


%% 
smprintinst
smprintchannels


smgui_small

%set up save loop
smscan.saveloop = 2;
%escape fns
smscan.escapefn.fn = @(x) smset(['Vtg';'Vbg'],[0,0]);
smscan.escapefn.args = {};

%cd 'Z:\valla\WTe2\cava_exfols\exfol_cava_1E\B_OM\E-B-flake7\Measure_Bonehead'
cd 'Z:\group\Group-Users\Twistedbilayers\Measurements\20151214-LowTwist\Scans'