function val = smcVertex80V(ic, val, rate)

%time driver

global smdata;

switch ic(3) %Operation: 0 for read, 1 for write

    case 0 %0 is idle, 1 is busy
        connection = tcpclient(smdata.inst(ic(1)).data.IPaddress,smdata.inst(ic(1)).data.Port);
        writeline(connection,'http://10.10.0.1/stat.htm');
        for i = 1:7
            response = readline(connection);
        end
        val = double(~contains(response, 'IDL'));

    case 1 %write operation;
        RemoteScan(ic);
    otherwise
        error('Operation not supported');
end
end

function RemoteScan(ic)
global smdata;

Resolution = smdata.inst(ic(1)).data.resolution;
Upper_Freq = smdata.inst(ic(1)).data.HFW;
trig = smdata.inst(ic(1)).data.trig;
num_Points = smdata.inst(ic(1)).data.NPT;
source = smdata.inst(ic(1)).data.source;
ip = smdata.inst(ic(1)).data.IPaddress;
port = smdata.inst(ic(1)).data.Port;

% Default Values, Rarely Changed
DTC = '0x4061'; % Ch1 = '0x4060', Ch2 = '0x4061', RLaTGS = '0x4020'
LPF = 80; % LPF = 5.0 is open
PHR = Resolution*2; % Phase Resolution
CHN = 5; %5 = Right Exit, %1 = Sample Compartment
WAS = 1; %Number of timeslices
WPD = 50; %Wait time per data point
GI0 = trig; % GI0 = 1 internal trig, =2 external rising trig
APT = 4.0; %Aperture Size, make sure size actually exists
%APT = 0.25; %Aperture Size, make sure size actually exists


% Need to convert inst.data.source into correct format
if contains('FIR Mercury Hg Arc Lamp',source,'ignorecase',true) 
    SRC = 201; % Mercury Arc Lamp for Far-IR
else
    SRC = 103; % Globar Lamp
end

% Format numbers to expected formats (DO NOT CHANGE)
RES = sprintf('%.17f',Resolution);
LPF = sprintf('%.1f',LPF);
APT = strcat('0x',dec2hex(APT*1000,4));
PHR = sprintf('%.17f',PHR);
HFW = sprintf('%.17f',Upper_Freq);
CHN = sprintf('%d', CHN);
WAS = sprintf('%d', WAS);
WPD = sprintf('%d', WPD);
GI0 = sprintf('%d', GI0);
NPT = sprintf('%d', num_Points);
SRC = sprintf('%d', SRC);


payload = 'http://10.10.0.1/cmd.htm?WRK=1&AMD=23&UWN=1&ITC=0&CNM=Admin&SNM=Default&SFM=Default&DLY=0&DEL=0&RES=%s&SRC=%s&LPF=%s&HPF=0&BMS=1&APT=%s&DTC=%s&AQM=DN&HFW=%s&LFW=0.00000000000000000&PHR=%s&SON=0&PGN=3&OPF=1&COR=0&CHN=%s&NSS=1&RDX=0&TSR=0&GNS=-1&DDM=0&REP=1&DLR=0&AMA=0&AMF=0&SMA=0&SMF=0&WAS=%s&WPD=%s&WXD=0&WTR=1000000&WTD=0&GI0=%s&GI1=1&STM=SLO=%s|MSL=1|NPT=1|ELO=-7';

payload = sprintf(payload,RES,SRC,LPF,APT,DTC,HFW,PHR,CHN,WAS,WPD,GI0,NPT);

%% Send Request
connection = tcpclient(ip,port);
writeline(connection,payload);

end