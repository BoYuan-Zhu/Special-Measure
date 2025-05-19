function val = smcK2700ac(ic, val, rate)

%skeletal driver for Keithley 2700 and 2000
% To make the measurement as fast as possible:
% 1. NPLC =0.01 CHECK
% 2. Disable Autorange (select one range). CHECK
% 3. Trigger delay = 0.0 CHECK
% 4. Disable Autozero CHECK
% 5. Disable the display. CHECK
%

global smdata;

switch ic(2); %Channels
    case 1 %Read Voltage
        switch ic(3); %Operation: 0 for read, 1 for write

             case 0 %just read voltage for now
                fprintf(smdata.inst(ic(1)).data.inst, sprintf('SENS:FUNC "VOLT:AC"'));
                val_char=query(smdata.inst(ic(1)).data.inst,'data?');
                val_str=char(val_char(1:15));
                val=str2num(val_str);
                  
                
            case 1 %write operation;  
                error('The DMM does not support write operations');
            otherwise
                error('Operation not supported');
        end
    case 2 %OPALL
        switch ic(3); %Operation: 0 for read, 1 for write

             case 0 %just read voltage for now
                error('The DMM does not support write operations');
                  
            case 1 %write operation;  
                fprintf(smdata.inst(ic(1)).data.inst, 'ROUT:OPEN:ALL');
            otherwise
                error('Operation not supported');
        end
    case 3 %OP
        switch ic(3); %Operation: 0 for read, 1 for write

             case 0 %just read voltage for now
                error('The DMM does not support write operations');
                  
            case 1 %write operation;  
                fprintf(smdata.inst(ic(1)).data.inst, 'ROUT:MULT:OPEN (@%f)',val);
            otherwise
                error('Operation not supported');
        end
    case 4 %I
        switch ic(3); %Operation: 0 for read, 1 for write

            case 0 %read current
                fprintf(smdata.inst(ic(1)).data.inst, sprintf('FUNC "CURR"'));
                val_char=query(smdata.inst(ic(1)).data.inst,'data?');
                val_str=char(val_char(1:15));
                val=str2num(val_str);

            case 1 %write operation;  
                fprintf(smdata.inst(ic(1)).data.inst, sprintf('FUNC "CURR"'));
            otherwise
                error('Operation not supported');
        end
    case 5 %MultiV
        switch ic(3); %Operation: 0 for read, 1 for write

            case 0 %read buffer
                pts=2000;
                tic
                fprintf(smdata.inst(ic(1)).data.inst, sprintf('ABORT;*RST'));
                fprintf(smdata.inst(ic(1)).data.inst, sprintf('FORMAT:DATA ASCII'));
                fprintf(smdata.inst(ic(1)).data.inst, sprintf('FORMAT:ELEM READ'));
                fprintf(smdata.inst(ic(1)).data.inst, sprintf('SYSTem:AZERo:STATe OFF'));%set up conditions for maximum measurement speed
                fprintf(smdata.inst(ic(1)).data.inst, sprintf('VOLTage:AC:NPLCycles 0.01'));
                fprintf(smdata.inst(ic(1)).data.inst, sprintf('VOLTage:AC:RANGe:AUTO OFF'));
                fprintf(smdata.inst(ic(1)).data.inst, sprintf('VOLTage:AC:AVER:STAT OFF'));
                fprintf(smdata.inst(ic(1)).data.inst, sprintf('CALCulate3:LIMit1:STATe OFF'));
                fprintf(smdata.inst(ic(1)).data.inst, sprintf('CALCulate3:LIMit2:STATe OFF'));
                fprintf(smdata.inst(ic(1)).data.inst, sprintf('DISPlay:ENABle OFF'));
                fprintf(smdata.inst(ic(1)).data.inst, sprintf('SENS:FUNC "VOLT:AC"'));
                fprintf(smdata.inst(ic(1)).data.inst, sprintf('SENS:VOLT:AC:DIGits 5'));
                fprintf(smdata.inst(ic(1)).data.inst, sprintf('*SRE 1'));
                fprintf(smdata.inst(ic(1)).data.inst, sprintf('stat:meas:enab 518'));
                set(smdata.inst(ic(1)).data.inst, 'TIMEOUT',5);
                fprintf(smdata.inst(ic(1)).data.inst, sprintf('TRAC:CLE:AUTO ON')); %set up buffer
                fprintf(smdata.inst(ic(1)).data.inst, sprintf('TRAC:POIN %f',pts));
                fprintf(smdata.inst(ic(1)).data.inst, sprintf('TRIG:DEL 0.0'));
                fprintf(smdata.inst(ic(1)).data.inst, sprintf('TRAC:FEED SENS'));
%                 fprintf(smdata.inst(ic(1)).data.inst, sprintf('stat:pres'));
%                 fprintf(smdata.inst(ic(1)).data.inst, sprintf('stat:meas:enab 13120'));
                fprintf(smdata.inst(ic(1)).data.inst, sprintf('TRAC:FEED:CONT NEXT'));
                fprintf(smdata.inst(ic(1)).data.inst, sprintf('TRAC:NOTify %f', pts-1));
                fprintf(smdata.inst(ic(1)).data.inst, sprintf('SAMP:COUN %f',pts));
                fprintf(smdata.inst(ic(1)).data.inst, sprintf('TRIG:COUN 1'));
                fprintf(smdata.inst(ic(1)).data.inst, sprintf('init'));
                [out,statusByte]=spoll(smdata.inst(ic(1)).data.inst,1)
%                 fprintf(smdata.inst(ic(1)).data.inst, sprintf('stat:meas?'));
%                 fprintf(smdata.inst(ic(1)).data.inst, sprintf('FORMAT:ELEM READ'));
                fprintf(smdata.inst(ic(1)).data.inst, sprintf('trace:data?'))
%                 dmm_data = fread(smdata.inst(ic(1)).data.inst, pts, 'single');
                dmm_data2=scanstr(smdata.inst(ic(1)).data.inst,',','%f');  %parse the dmm data
%                 voltage=bin2dec(dmm_data2);
                fprintf(smdata.inst(ic(1)).data.inst, sprintf('ABORT'));
                fprintf(smdata.inst(ic(1)).data.inst, sprintf('*CLS'));
                fprintf(smdata.inst(ic(1)).data.inst, sprintf('*SRE 0'));
%                 v_size = size(strfind(dmm_data,'VAC'),2);
%                 vstart = [[1],(strfind(dmm_data,'#,')+2)];
%                 vend = strfind(dmm_data,'VAC')-1;
%                 tstart=strfind(dmm_data,'VAC,')+5;
%                 tend = strfind(dmm_data,'SECS')-1;
%                 voltage=zeros(1,v_size);
%                 time = zeros(1,v_size);
%                 for i=1:1:v_size;
%                     voltage(i)=str2num(dmm_data(vstart(i):vend(i)));
%                     time(i)=str2num(dmm_data(tstart(i):tend(i)));
%                 end;
%                 timestamp=time
                toc
                val = dmm_data2
%                 x=time
%                 y=[1]
%                 z=voltage
%                 figure
%                 [X,Y]=meshgrid(time,1:2)
%                 imagesc(x,y,z)
%                 colormap(jet(5))
%                 view(2)
%                 xlim([min(time) max(time)]);ylim([min(voltage) max(voltage)])
%                 fprintf(smdata.inst(ic(1)).data.inst, sprintf('stat:meas:enab 512'));
%                 fprintf(smdata.inst(ic(1)).data.inst, sprintf('*sre 1'));
%                 fprintf(smdata.inst(ic(1)).data.inst, sprintf('TRAC:CLE:AUTO ON'));
%                 fprintf(smdata.inst(ic(1)).data.inst, sprintf('TRIG:DEL 0.0'));
%                 fprintf(smdata.inst(ic(1)).data.inst, sprintf('TRAC:POIN %f',10));
%                 fprintf(smdata.inst(ic(1)).data.inst, sprintf('TRAC:FEED SENS'));
%                 fprintf(smdata.inst(ic(1)).data.inst, sprintf('TRAC:FEED:CONT NEXT'));
% %                 fprintf(smdata.inst(ic(1)).data.inst, sprintf('FORMAT:ELEM READ'));
%                 fprintf(smdata.inst(ic(1)).data.inst, sprintf('SENSE:FUNC"VOLT",(@101:104)'));
%                 fprintf(smdata.inst(ic(1)).data.inst, sprintf('ROUT:SCAN(@101:104)'));
%                 fprintf(smdata.inst(ic(1)).data.inst, sprintf('ROUT:SCAN:TSO IMM'));
%                 fprintf(smdata.inst(ic(1)).data.inst, sprintf('ROUTE:SCAN:LSEL INT'));
            case 1 %write operation;  
                fprintf(smdata.inst(ic(1)).data.inst, sprintf('TRAC:CLE:AUTO ON'));
                fprintf(smdata.inst(ic(1)).data.inst, sprintf('FORMAT:DATA SREAL'));
                fprintf(smdata.inst(ic(1)).data.inst, sprintf('TRIG:DEL 1'));
                fprintf(smdata.inst(ic(1)).data.inst, sprintf('TRAC:POIN %f',val));
                fprintf(smdata.inst(ic(1)).data.inst, sprintf('TRAC:FEED SENS'));
                fprintf(smdata.inst(ic(1)).data.inst, sprintf('TRAC:NOTify %f', 9));
                fprintf(smdata.inst(ic(1)).data.inst, sprintf('TRAC:FEED:CONT NEXT'));
                fprintf(smdata.inst(ic(1)).data.inst, sprintf('stat:pres'));
                fprintf(smdata.inst(ic(1)).data.inst, sprintf('*cls'));
                fprintf(smdata.inst(ic(1)).data.inst, sprintf('stat:meas:enab 512'));
                fprintf(smdata.inst(ic(1)).data.inst, sprintf('*ese 0'));
                fprintf(smdata.inst(ic(1)).data.inst, sprintf('*sre 1'));
                fprintf(smdata.inst(ic(1)).data.inst, sprintf('init'));

            otherwise
                error('Operation not supported');
        end
    case 6 %Test
        switch ic(3); %Operation: 0 for read, 1 for write

            case 0 %
                val=query(smdata.inst(ic(1)).data.inst,'*STB?')
            case 1 %write operation;  
                fprintf(smdata.inst(ic(1)).data.inst, sprintf('TRAC:CLE:AUTO ON'));
                fprintf(smdata.inst(ic(1)).data.inst, sprintf('TRIG:DEL 0.5'));
                fprintf(smdata.inst(ic(1)).data.inst, sprintf('SAMP: COUN %f',val));
            otherwise
                error('Operation not supported');
        end
    case 7 %NoBuff.  Read rather than Trace
         switch ic(3); %Operation: 0 for read, 1 for write

            case 0 %read at max speed?
                pts=20;
                tic
                fprintf(smdata.inst(ic(1)).data.inst, sprintf('ABORT;*RST'));
                set(smdata.inst(ic(1)).data.inst, 'TIMEOUT',10);
                fprintf(smdata.inst(ic(1)).data.inst, sprintf('SENSE:FUNCTION "VOLT:AC"'));
                fprintf(smdata.inst(ic(1)).data.inst, sprintf('FORMAT:DATA SREAL'));
                 fprintf(smdata.inst(ic(1)).data.inst, sprintf('FORMAT:BORDER NORMAL'));
                fprintf(smdata.inst(ic(1)).data.inst, sprintf('FORMAT:ELEM READ'));%format statement for readings only
                fprintf(smdata.inst(ic(1)).data.inst, sprintf('SYSTEM:AZERO:STATE OFF'));%set up conditions for maximum measurement speed
                fprintf(smdata.inst(ic(1)).data.inst, sprintf('SENSE:VOLT:AC:AVERAGE:STATE OFF')); %turn off the filter for ACV
                %fprintf(smdata.inst(ic(1)).data.inst, sprintf('SENSE:VOLT:DC:NPLC 0.01'));
                fprintf(smdata.inst(ic(1)).data.inst, sprintf('SENSE:VOLT:AC:RANGE 10'));
                fprintf(smdata.inst(ic(1)).data.inst, sprintf('SENSE:VOLT:AC:DIGITS 4'));
                fprintf(smdata.inst(ic(1)).data.inst, sprintf('TRIGGER:COUNT 1'));
                fprintf(smdata.inst(ic(1)).data.inst, sprintf('INIT:CONT OFF'));
                fprintf(smdata.inst(ic(1)).data.inst, sprintf('SAMPLE:COUNT %f',pts));
                fprintf(smdata.inst(ic(1)).data.inst, sprintf('TRIGGER:DELAY 0.0'));
                fprintf(smdata.inst(1,6).data.inst,'trace:clear')
                fprintf(smdata.inst(1,6).data.inst,'trace:clear:auto on')
                fprintf(smdata.inst(ic(1)).data.inst, sprintf(':DISPLAY:ENABLE OFF'));
                
              %  dmm_data=query(smdata.inst(ic(1)).data.inst, sprintf('READ?'));
                fprintf(smdata.inst(ic(1)).data.inst, sprintf('READ?'));
                pause(2)
                dmm_data = fread(smdata.inst(ic(1)).data.inst,pts,'float32');
%                 fclose(smdata.inst(ic(1)).data.inst);
%                 set(smdata.inst(ic(1)).data.inst,'InputBufferSize', pts*4);
%                 fopen(smdata.inst(ic(1)).data.inst);
%                 set(smdata.inst(ic(1)).data.inst, 'EOSMode', 'read&write');
%                 set(smdata.inst(ic(1)).data.inst, 'EOSCharCode', double('o'));
%                 dmm_data = fread(smdata.inst(ic(1)).data.inst, pts, 'float32');

%                 v_size = size(strfind(dmm_data,'VAC'),2);
%                 vstart = [[1],(strfind(dmm_data,'#,')+2)];
%                 vend = strfind(dmm_data,'VAC')-1;
%                 voltage=zeros(1,pts);
%                 for i=1:1:v_size;
%                     voltage(i)=str2num(dmm_data(vstart(i):vend(i)));
%                 end;
                val=dmm_data
                toc
%                 figure; plot(voltage);
            otherwise
                error('Operation not supported');
        end
        
    otherwise
        error('Operation not supported');
end

