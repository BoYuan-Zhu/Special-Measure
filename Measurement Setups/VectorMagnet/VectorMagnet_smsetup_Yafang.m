% 1K Setup Instrument Initialization
%---------------------

%Clear out Matlab
clear all;
close all;
instrreset;

%GPIB addresses
GPIB_BOARD='ni';
BOARD_NUM=0;
LockInA_GPIB=8;
LockInB_GPIB=11;
LockInC_GPIB=13;
K2400_GPIB=24;
K2400_2_GPIB=15;
K2700_A_GPIB=16;
K2700_B_GPIB=9;
HP34401A_GPIB=7;
DAC_COM='COM1';
Magnet_COM='COM2';

%Use or not (1:use, 0:not)
LockInA_Use=1;
LockInB_Use=1;
LockInC_Use=1;
K2400_Use=1;
K2400_2_Use=1;  %front or rear need change
K2700_A_Use=1;
K2700_B_Use=1;
HP34401A_Use=0;
DAC_Use=1;
Magnet_Use=1;

%Instrument mode selection
K2400_Mode='Voltage';
K2400_2_Mode='Voltage';
K2700_Mode='Voltage';

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
% add LockInA
if LockInA_Use == 1
    try
        ind = smloadinst('SR830', [], GPIB_BOARD, BOARD_NUM, LockInA_GPIB);

        %setup GPIB communication parameters
        set(smdata.inst(ind).data.inst,'inputbuffersize',2^16); %assigns 65kb to the read buffer to enable it to take a full buffer of data with one request
        set(smdata.inst(ind).data.inst,'outputbuffersize',2^10);  %assigns 1kb to the write buffer
        set(smdata.inst(ind).data.inst,'timeout',40);    %increases timeout time to allow for large data transfers

        %open GPIB communication
        smopen(ind); 

        smdata.inst(ind).name = 'LockIn_A';

        %add channels
        smaddchannel('LockIn_A', 'X', 'Vxx', [-Inf, Inf, Inf, 1]);
        smaddchannel('LockIn_A', 'THETA', 'Vxx_{theta}', [-Inf, Inf, Inf, 1]);
        smaddchannel('LockIn_A', 'OUT1', 'Vs_A', [-10, 10, .5, 1]);
    %     smaddchannel('LockIn_A', 'IN1', 'In1_A', [-Inf, Inf, Inf, 1]);
    %     smaddchannel('LockIn_A', 'IN2', 'In2_A', [-Inf, Inf, Inf, 1]);
    %     smaddchannel('LockIn_A', 'IN3', 'In3_A', [-Inf, Inf, Inf, 1]);
    %     smaddchannel('LockIn_A', 'IN4', 'In4_A', [-Inf, Inf, Inf, 1]);
        %smaddchannel('LockIn_A', 'FREQ', 'Freq_A', [0, 102000, 10, 1]);
        smaddchannel('LockIn_A', 'VREF', 'Vli_A', [0, 5, 0.5, 1]);

        %set instrument parameters
        %fprintf(smdata.inst(ind).data.inst,'*rst'); %resets the lockin

        fprintf(smdata.inst(ind).data.inst,'slvl 1'); %sets the output amplitude to the lockin's lowest value (4mV)
        fprintf(smdata.inst(ind).data.inst,'freq 5.2');    %sets the lockin source frequency
        fprintf(smdata.inst(ind).data.inst,'ilin 0');   %turns both line filters off
        fprintf(smdata.inst(ind).data.inst,'isrc 1');   %sets the input to A-B
        fprintf(smdata.inst(ind).data.inst,'icpl 0');   %sets the input coupling to AC
        fprintf(smdata.inst(ind).data.inst,'ignd 0');   %sets the ground to float
        fprintf(smdata.inst(ind).data.inst,'oflt 9');   %sets the time constant to 300ms
        fprintf(smdata.inst(ind).data.inst,'ofsl 3');   %sets roll off to 24dB
        fprintf(smdata.inst(ind).data.inst,'sens 23');   %sets the sensitivity to 100mV

        %fprintf(smdata.inst(ind).data.inst,'srat 9');   %sets the sample rate to 32Hz
        %fprintf(smdata.inst(ind).data.inst,'send 0');   %sets the scan end to 1 shot instead of loop
        %fprintf(smdata.inst(ind).data.inst,'rest');     %resets the buffer 
        %fprintf(smdata.inst(ind).data.inst,'tstr 1');   %turns on the trigger

    
    catch err
        fprintf(['*ERROR* problem with connecting to LockIn_A\n' err.identifier ': ' err.message '\n'])
    end
end

% add LockInB
if LockInB_Use == 1
    try
        ind = smloadinst('SR830', [], GPIB_BOARD, BOARD_NUM, LockInB_GPIB);

        %setup GPIB communication parameters
        set(smdata.inst(ind).data.inst,'inputbuffersize',2^16); %assigns 65kb to the read buffer to enable it to take a full buffer of data with one request
        set(smdata.inst(ind).data.inst,'outputbuffersize',2^10);  %assigns 1kb to the write buffer
        set(smdata.inst(ind).data.inst,'timeout',40);    %increases timeout time to allow for large data transfers

        %open GPIB communication
        smopen(ind); 

        smdata.inst(ind).name = 'LockIn_B';

        %add channels
        smaddchannel('LockIn_B', 'X', 'Vxy', [-Inf, Inf, Inf, 1]);
        smaddchannel('LockIn_B', 'THETA', 'Vxy_{theta}', [-Inf, Inf, Inf, 1]);
    %     smaddchannel('LockIn_B', 'OUT1', 'Vs_B', [-10, 10, .5, 1]);
        %smaddchannel('LockIn_B', 'IN1', 'Isd_B', [-Inf, Inf, Inf, -1e6]);
        %smaddchannel('LockIn_B', 'IN3', 'Vab_B', [-Inf, Inf, Inf, 1]);
        %smaddchannel('LockIn_B', 'FREQ', 'Freq_B', [0, 102000, 10, 1]);
        %smaddchannel('LockIn_B', 'VREF', 'Vli_B', [0, 5, 0.5, 1]);

        %set instrument parameters
        %fprintf(smdata.inst(ind).data.inst,'*rst'); %resets the lockin

        fprintf(smdata.inst(ind).data.inst,'slvl .004'); %sets the output amplitude to the lockin's lowest value (4mV)
        fprintf(smdata.inst(ind).data.inst,'freq 17.777');    %sets the lockin source frequency
        fprintf(smdata.inst(ind).data.inst,'ilin 0');   %turns both line filters off
        fprintf(smdata.inst(ind).data.inst,'isrc 1');   %sets the input to A-B
        fprintf(smdata.inst(ind).data.inst,'icpl 0');   %sets the input coupling to AC
        fprintf(smdata.inst(ind).data.inst,'ignd 0');   %sets the ground to float
        fprintf(smdata.inst(ind).data.inst,'oflt 9');   %sets the time constant to 300ms
        fprintf(smdata.inst(ind).data.inst,'ofsl 3');   %sets roll off to 24dB
        fprintf(smdata.inst(ind).data.inst,'sens 23');   %sets the sensitivity to 100mV

        %fprintf(smdata.inst(ind).data.inst,'srat 9');   %sets the sample rate to 32Hz
        %fprintf(smdata.inst(ind).data.inst,'send 0');   %sets the scan end to 1 shot instead of loop
        %fprintf(smdata.inst(ind).data.inst,'rest');     %resets the buffer 
        %fprintf(smdata.inst(ind).data.inst,'tstr 1');   %turns on the trigger
    
    catch err
        fprintf(['*ERROR* problem with connecting to LockIn_B\n' err.identifier ': ' err.message '\n'])
    end
end

% add LockInC
if LockInC_Use == 1
    try
        ind = smloadinst('SR830', [], GPIB_BOARD, BOARD_NUM, LockInC_GPIB);

        %setup GPIB communication parameters
        set(smdata.inst(ind).data.inst,'inputbuffersize',2^16); %assigns 65kb to the read buffer to enable it to take a full buffer of data with one request
        set(smdata.inst(ind).data.inst,'outputbuffersize',2^10);  %assigns 1kb to the write buffer
        set(smdata.inst(ind).data.inst,'timeout',40);    %increases timeout time to allow for large data transfers

        %open GPIB communication
        smopen(ind); 

        smdata.inst(ind).name = 'LockIn_C';

        %add channels
        smaddchannel('LockIn_C', 'X', 'Iac', [-Inf, Inf, Inf, 10000]);
        smaddchannel('LockIn_C', 'Y', 'Iac_{theta}', [-Inf, Inf, Inf, 1]);
    %     smaddchannel('LockIn_A', 'OUT1', 'Vs_A', [-10, 10, .5, 1]);
    %     smaddchannel('LockIn_A', 'IN1', 'In1_A', [-Inf, Inf, Inf, 1]);
    %     smaddchannel('LockIn_A', 'IN2', 'In2_A', [-Inf, Inf, Inf, 1]);
    %     smaddchannel('LockIn_A', 'IN3', 'In3_A', [-Inf, Inf, Inf, 1]);
    %     smaddchannel('LockIn_A', 'IN4', 'In4_A', [-Inf, Inf, Inf, 1]);
        %smaddchannel('LockIn_A', 'FREQ', 'Freq_A', [0, 102000, 10, 1]);
        %smaddchannel('LockIn_A', 'VREF', 'Vli_A', [0, 5, 0.5, 1]);

        %set instrument parameters
        %fprintf(smdata.inst(ind).data.inst,'*rst'); %resets the lockin

        fprintf(smdata.inst(ind).data.inst,'slvl 1'); %sets the output amplitude to the lockin's lowest value (4mV)
        fprintf(smdata.inst(ind).data.inst,'freq 1');    %sets the lockin source frequency
        fprintf(smdata.inst(ind).data.inst,'ilin 0');   %turns both line filters off
        fprintf(smdata.inst(ind).data.inst,'isrc 1');   %sets the input to A-B
        fprintf(smdata.inst(ind).data.inst,'icpl 0');   %sets the input coupling to AC
        fprintf(smdata.inst(ind).data.inst,'ignd 0');   %sets the ground to float
        fprintf(smdata.inst(ind).data.inst,'oflt 9');   %sets the time constant to 300ms
        fprintf(smdata.inst(ind).data.inst,'ofsl 3');   %sets roll off to 24dB
        fprintf(smdata.inst(ind).data.inst,'sens 23');   %sets the sensitivity to 100mV

        %fprintf(smdata.inst(ind).data.inst,'srat 9');   %sets the sample rate to 32Hz
        %fprintf(smdata.inst(ind).data.inst,'send 0');   %sets the scan end to 1 shot instead of loop
        %fprintf(smdata.inst(ind).data.inst,'rest');     %resets the buffer 
        %fprintf(smdata.inst(ind).data.inst,'tstr 1');   %turns on the trigger


    catch err
        fprintf(['*ERROR* problem with connecting to LockIn_C\n' err.identifier ': ' err.message '\n'])
    end
end

%% add Keithley 2400
if K2400_Use==1

    try
        ind  = smloadinst('K2400', [], GPIB_BOARD, BOARD_NUM, K2400_GPIB);
        %setup GPIB communication parameters
        set(smdata.inst(ind).data.inst,'inputbuffersize',2^18); %assigns 262kb to the read buffer to enable it to take a full buffer of data with one request
        set(smdata.inst(ind).data.inst,'outputbuffersize',2^10);  %assigns 1kb to the write buffer
        set(smdata.inst(ind).data.inst,'eosmode','read&write');  %end of string character is used in both read and write operations
        set(smdata.inst(ind).data.inst,'timeout',5);

        %open GPIB communication
        smopen(ind);

        smdata.inst(ind).name = 'K2400';

        %add channels
        smaddchannel('K2400','I','Ibg',[-Inf Inf 0.1 1]);
        smaddchannel('K2400','V','Vbg',[-210 210 4 1]);
        smaddchannel('K2400','Icompl','Ic',[0 1 Inf 1]);
        smaddchannel('K2400','Vcompl','Vc',[0 210 Inf 1]);

        %set instrument parameters       
        fprintf(smdata.inst(ind).data.inst,'*rst'); %resets the Keithley
        fprintf(smdata.inst(ind).data.inst,':source:delay 0.0'); %sets delay to 0
        if(strcmp(K2400_Mode,'Voltage'))
            fprintf(smdata.inst(ind).data.inst,':sense:current:protection 1e-6'); %sets initial current compliance to 1uA
            fprintf(smdata.inst(ind).data.inst,':sense:current:range:range 1e-6');     %sets the sense current limit to 1uA
            fprintf(smdata.inst(ind).data.inst,':source:voltage:range 100');  %sets the voltage range to 100V
        elseif(strcmp(K2400_Mode, 'Current'))
        %%% parameters for sourcing current
            fprintf(smdata.inst(ind).data.inst,':source:function current');  %choose to source current
            fprintf(smdata.inst(ind).data.inst,':sense:function:concurrent off');  %choose to measure voltage
            fprintf(smdata.inst(ind).data.inst,':sense:voltage:protection 1');  %sets initial voltage compliance
            fprintf(smdata.inst(ind).data.inst,':sense:voltage:range:auto 1');  %sets limit on voltage sensing
        else
            error('No such mode for K2400: %s', K2400_Mode);
        end
        % Turn on output
        fprintf(smdata.inst(ind).data.inst,':output on');
        % Start continuous measurement
        fprintf(smdata.inst(ind).data.inst,':arm:count infinite');
        fprintf(smdata.inst(ind).data.inst,':initiate');
    catch err
        fprintf(['*ERROR* problem with connecting to the Source\n' err.identifier ': ' err.message '\n'])
    end

end
%% add Keithley 2400 (2)
if K2400_2_Use==1

    try
        ind  = smloadinst('K2400', [], GPIB_BOARD, BOARD_NUM, K2400_2_GPIB);
        %setup GPIB communication parameters
        set(smdata.inst(ind).data.inst,'inputbuffersize',2^18); %assigns 262kb to the read buffer to enable it to take a full buffer of data with one request
        set(smdata.inst(ind).data.inst,'outputbuffersize',2^10);  %assigns 1kb to the write buffer
        set(smdata.inst(ind).data.inst,'eosmode','read&write');  %end of string character is used in both read and write operations

        %open GPIB communication
        smopen(ind);

        smdata.inst(ind).name = 'K2400_2';

        
        %add channels
        smaddchannel('K2400_2','I','Itg',[-Inf Inf 0.1 1]);
        smaddchannel('K2400_2','V','Vtg',[-10 10 1 1]);
        smaddchannel('K2400_2','Icompl','Ic2',[0 1 Inf 1]);
        smaddchannel('K2400_2','Vcompl','Vc2',[0 210 Inf 1]);

        %set instrument parameters

        fprintf(smdata.inst(ind).data.inst,'*rst'); %resets the Keithley
        fprintf(smdata.inst(ind).data.inst,':source:delay 0.0'); %sets delay to 0
                fprintf(smdata.inst(ind).data.inst,'*rst'); %resets the Keithley
        fprintf(smdata.inst(ind).data.inst,':source:delay 0.0'); %sets delay to 0
        if(strcmp(K2400_Mode,'Voltage'))
            fprintf(smdata.inst(ind).data.inst,':sense:current:protection 1e-6'); %sets initial current compliance to 1uA
            fprintf(smdata.inst(ind).data.inst,':sense:current:range:range 1e-6');     %sets the sense current limit to 1uA
            fprintf(smdata.inst(ind).data.inst,':source:voltage:range 100');  %sets the voltage range to 100V
        elseif(strcmp(K2400_2_Mode, 'Current'))
        %%% parameters for sourcing current
            fprintf(smdata.inst(ind).data.inst,':source:function current');  %choose to source current
            fprintf(smdata.inst(ind).data.inst,':sense:function:concurrent off');  %choose to measure voltage
            fprintf(smdata.inst(ind).data.inst,':sense:voltage:protection 2');  %sets initial voltage compliance
            fprintf(smdata.inst(ind).data.inst,':sense:voltage:range:auto 1');  %sets limit on voltage sensing
        else
            error('No such mode for K2400_2: %s', K2400_2_Mode);
        end
        % Turn on output
        fprintf(smdata.inst(ind).data.inst,':output on');
        % Start continuous measurement
        fprintf(smdata.inst(ind).data.inst,':arm:count infinite');
        fprintf(smdata.inst(ind).data.inst,':initiate');
    catch err
        fprintf(['*ERROR* problem with connecting to the Source\n' err.identifier ': ' err.message '\n'])
    end

end

%% add Keithley 2700
if K2700_A_Use==1
    try
        ind  = smloadinst('K2700', [], GPIB_BOARD, BOARD_NUM, K2700_A_GPIB);

        %setup GPIB communication parameters
        set(smdata.inst(ind).data.inst,'inputbuffersize',2^18); %assigns 262kb to the read buffer to enable it to take a full buffer of data with one request
        set(smdata.inst(ind).data.inst,'outputbuffersize',2^10);  %assigns 1kb to the write buffer
        set(smdata.inst(ind).data.inst,'eosmode','read&write');
    %     set(smdata.inst(ind).data.inst,'eoscharcode',double('E'));
        set(smdata.inst(ind).data.inst,'timeout',10);    %increases timeout time to allow for large data transfers

        %open GPIB communication
        smopen(ind);

        smdata.inst(ind).name = 'K2700';

        %add channels
        smaddchannel('K2700','V','Isd',[-Inf Inf Inf -1e6]);

        %set instrument parameters
         fprintf(smdata.inst(ind).data.inst, sprintf('ABORT;*RST'));
                    fprintf(smdata.inst(ind).data.inst, sprintf('SENSE:FUNCTION "VOLT:DC"'));
      %              fprintf(smdata.inst(ind).data.inst, sprintf('FORMAT:ELEMENT READ')); %format statement for readings only
                    fprintf(smdata.inst(ind).data.inst, sprintf('SYSTEM:AZERO:STATE ON'));%set up conditions for maximum measurement speed
                    fprintf(smdata.inst(ind).data.inst, sprintf('SENSE:VOLT:DC:AVERAGE:STATE ON')); %turn off the filter for DCV
                    fprintf(smdata.inst(ind).data.inst, sprintf('SENSE:VOLT:DC:NPLC 1'));
                    fprintf(smdata.inst(ind).data.inst, sprintf('SENSE:VOLT:DC:RANGE:AUTO ON'));
                    fprintf(smdata.inst(ind).data.inst, sprintf('SENSE:VOLT:DC:DIGITS 6'));
        %            fprintf(smdata.inst(ind).data.inst, sprintf('TRIGGER:COUNT 1'));
        %            fprintf(smdata.inst(ind).data.inst, sprintf('INIT:CONT OFF'));
       %             fprintf(smdata.inst(ind).data.inst, sprintf('SAMPLE:COUNT 200'));
       %             fprintf(smdata.inst(ind).data.inst, sprintf('TRIGGER:DELAY 0.0'));
      %              fprintf(smdata.inst(ind).data.inst,'trace:clear');
     %               fprintf(smdata.inst(ind).data.inst,'trace:clear:auto on');
     %               fprintf(smdata.inst(ind).data.inst, sprintf(':DISPLAY:ENABLE OFF'));

    catch err
        fprintf(['*ERROR* problem with connecting to the DMM\n' err.identifier ': ' err.message '\n'])
    end
end


% add Keithley 2700 B
if K2700_B_Use == 1
    try
        ind  = smloadinst('K2700', [], GPIB_BOARD, BOARD_NUM, K2700_B_GPIB);

        %setup GPIB communication parameters
        set(smdata.inst(ind).data.inst,'inputbuffersize',2^18); %assigns 262kb to the read buffer to enable it to take a full buffer of data with one request
        set(smdata.inst(ind).data.inst,'outputbuffersize',2^10);  %assigns 1kb to the write buffer
        set(smdata.inst(ind).data.inst,'eosmode','read&write');
        set(smdata.inst(ind).data.inst,'timeout',10);    %increases timeout time to allow for large data transfers

        %open GPIB communication
        smopen(ind);

        smdata.inst(ind).name = 'DMMB';

        %add channels
        %add channels
        smaddchannel('DMMB','V','VdmmB',[-Inf Inf Inf 1]);
        %smaddchannel('DMMA','V','Isd',[-Inf Inf Inf -1e6]);

        %set instrument parameters
        if(strcmp(K2700_Mode,'Voltage'))
            fprintf(smdata.inst(ind).data.inst,'*rst'); %resets the Keithley
            fprintf(smdata.inst(ind).data.inst,'initiate:continuous on;:abort'); %turns on continuous readings
            fprintf(smdata.inst(ind).data.inst,'voltage:nplcycles 1'); %sets the cycle time to the Keithley's medium (1s)
            fprintf(smdata.inst(ind).data.inst,'sense:voltage:dc:average:state off'); %turns off averaging
            fprintf(smdata.inst(ind).data.inst,'sense:voltage:range:auto 1');    %sets the voltage range to auto
            %fprintf(smdata.inst(ind).data.inst,':sense:voltage:dc:range .1');    %sets the voltage range 100mV (the min)
                     fprintf(smdata.inst(ind).data.inst, sprintf('ABORT;*RST'));
                    fprintf(smdata.inst(ind).data.inst, sprintf('SENSE:FUNCTION "VOLT:DC"'));
      %              fprintf(smdata.inst(ind).data.inst, sprintf('FORMAT:ELEMENT READ')); %format statement for readings only
                    fprintf(smdata.inst(ind).data.inst, sprintf('SYSTEM:AZERO:STATE ON'));%set up conditions for maximum measurement speed
                    fprintf(smdata.inst(ind).data.inst, sprintf('SENSE:VOLT:DC:NPLC 1'));
         %           fprintf(smdata.inst(ind).data.inst, sprintf('SENSE:VOLT:DC:RANGE 10'));
                    fprintf(smdata.inst(ind).data.inst, sprintf('SENSE:VOLT:DC:DIGITS 6'));
        elseif(strcmp(K2700_Mode,'Current'))
            %%% TODO
        end
    catch err
        fprintf(['*ERROR* problem with connecting to the DMM\n' err.identifier ': ' err.message '\n'])
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
        smaddchannel('DAC', 'CH0', 'Vsd', [-2 2 .5 1]);
        smaddchannel('DAC', 'CH1', 'DAC1', [-5 5 .1 1]);
        smaddchannel('DAC', 'CH2', 'DAC2', [-10 10 .1 1]);
        %smaddchannel('DAC', 'CH3', 'DAC3', [-10 10 .1 1]);
        %smaddchannel('DAC', 'CH1', 'Vion', [-2 2 0.2 1]);
        
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

if Magnet_Use == 1
    try
        ind = smloadinst('AMI430', [], 'serial', Magnet_COM);
        
        smopen(ind);
        smdata.inst(ind).name = 'Magnet';
        
        smaddchannel('Magnet','B','B',[-10,10,Inf,1]); % Ramping is controlled automatically
        smaddchannel('Magnet','Persistent','Persistent',[0,1,Inf,1]); % Set to 1 to enter persistent mode, 0 to exit
        
    catch err
        fprintf(['*ERROR* problem with connecting to the MagnetController\n' err.identifier ': ' err.message '\n'])
    end
end
smprintinst
smprintchannels

cd('Z:\group\Dichalcogenides\WSe2\WSe2-BN-23\Measurement');

smgui_small

%set up save loop
smscan.saveloop = 2;
%escape fns
%smscan.escapefn.fn = @(x) smset({'Vbg','Vtg'},[0 0])
smscan.escapefn.args = {};
