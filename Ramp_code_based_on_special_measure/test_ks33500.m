clear all; close all; instrreset;
global smaux smscan smdata;

%% -------------------- GPIB --------------------
GPIB_BOARD        = 'ni';
BOARD_NUM         = 0;
KS33511B_GPIB       = 12;

ind  = smloadinst('KS33511B', [], GPIB_BOARD, BOARD_NUM, KS33511B_GPIB);

        %setup GPIB communication parameters
        set(smdata.inst(ind).data.inst,'inputbuffersize',2^18); %assigns 262kb to the read buffer to enable it to take a full buffer of data with one request
        set(smdata.inst(ind).data.inst,'outputbuffersize',2^10);  %assigns 1kb to the write buffer
        set(smdata.inst(ind).data.inst,'eosmode','read&write');  %end of string character is used in both read and write operations

        %open GPIB communication
        smopen(ind);

       smdata.inst(ind).name = 'FunGen';

        %add channels
        smaddchannel('FunGen','Vac','Vac',[-10 10 1 1]);
        smaddchannel('FunGen','Vdc','Vdc',[-10 10 1 1]);
        smaddchannel('FunGen','Freq','Freq',[0 2e7 Inf 1]);

        %set instrument parameters
        fprintf(smdata.inst(ind).data.inst,'*rst'); %resets the Keysight
        fprintf(smdata.inst(ind).data.inst,'*cls'); %clear interface
        
        fprintf(smdata.inst(ind).data.inst,'OUTP:LOAD INF');
        fprintf(smdata.inst(ind).data.inst,'SOUR:FUNC SIN');
        fprintf(smdata.inst(ind).data.inst,'SOUR:VOLT:UNIT VRMS');
        fprintf(smdata.inst(ind).data.inst,'SOUR:VOLT 1E-3');
        fprintf(smdata.inst(ind).data.inst,'SOUR:FREQ 23.33');
        
        
        %Turn on the source
        fprintf(smdata.inst(ind).data.inst,'OUTP ON');