function [val, rate] = smcK2450_Ramp(ic, val, rate)
% Jiawei: MAKE SURE K2450 IS SOURCE VOLTAGE AND MEASURE CURRENT MODE.
%Channels
%1 - 'Vg' voltage
%2 - 'Ig' Current
%3 - 'VgRange' voltage range, 0-5 for auto, 20 mV, 200 mV, 2 V, 20 V, 200 V
%4 - 'VgRead' voltage readback
%5 - 'Iglimit' current limit
%6 - 'Vg-ramp' sample rate 65.345 Hz to 5.5 Hz
%7 - 'Ig-buf'

%Jiawei 10/02/2024 - SCPI command of 2450. Only support 1 uA measurement
%range ramp as voltage source.

global smdata;
% %  MAKE SURE SOURCE VOLTAGE AND MEASURE CURRENT
% fprintf(smdata.inst(ic(1)).data.inst,':ABORt;:SOURce:FUNCtion:MODE VOLT;:SENSe:FUNCtion "CURRent"');
setupcmd = '*RST;:ABORt;:SOURce:FUNCtion:MODE VOLT;:SENSe:FUNCtion "CURRent";:SENSe:CURRent:RANGe 1E-3;:SENSe:CURRent:NPLCycles 1.000;';
continuesupdatingcmd = ':SOURce:VOLTage:READ:BACK 1;:SENSe:CURRent:NPLCycles 1.000;:TRIGger:LOAD "LoopUntilEvent", DISP, 50;:INIT';
switch ic(2) % Channels
    case 1 %Vg
        switch ic(3); %Operation: 0 for read, 1 for write
            case 0 %read
                % Stop continuous updating, measure the current and read the voltage readback
                %fprintf(smdata.inst(ic(1)).data.inst,setupcmd);
                val = query(smdata.inst(ic(1)).data.inst,':SOURce:VOLTage:AMPLitude?','%s\n','%g');
                % continuous updating.
                %fprintf(smdata.inst(ic(1)).data.inst, continuesupdatingcmd);
            case 1 %write operation
                %fprintf(smdata.inst(ic(1)).data.inst,setupcmd);
                fprintf(smdata.inst(ic(1)).data.inst,':OUTPut:STATe ON ');
                cmd = sprintf(':SOURce:VOLTage %g', val);
                fprintf(smdata.inst(ic(1)).data.inst, cmd);
                % continuous updating.
                % query(smdata.inst(ic(1)).data.inst,':SENSe:COUNt 1;:MEASure?');
                %fprintf(smdata.inst(ic(1)).data.inst, continuesupdatingcmd);
            otherwise
                error('K2450 driver: Operation not supported');
        end
    case 2 %Ig
        switch ic(3); %Operation: 0 for read, 1 for write
            case 0 %read measured current
                % Stop continuous updating, measure the current and read the voltage readback
                %fprintf(smdata.inst(ic(1)).data.inst,setupcmd);
                val = query(smdata.inst(ic(1)).data.inst,':SENSe:COUNt 1;:MEASure:CURRent? "defbuffer1", READ','%s\n','%g');
                % continuous updating.
                fprintf(smdata.inst(ic(1)).data.inst, continuesupdatingcmd);
            case 1 %write operation; Do not use current source mode for now.
                error('K2450 driver: Do not use current source mode for now');
                % cmd = sprintf(':ABORt;:SOURce:FUNCtion:MODE CURR;:SOURce:CURRent %g', val);
                % fprintf(smdata.inst(ic(1)).data.inst, cmd);
                % pause(0.05);
                % fprintf(smdata.inst(ic(1)).data.inst, ':TRIGger:LOAD "LoopUntilEvent", DISP, 50;:INIT');
            otherwise
                error('K2450 driver: Operation not supported');
        end
    case 3 %VgRange
        switch ic(3); %Operation: 0 for read, 1 for write
            % 0 for auto range, 1 for 20 mV, 2 for 200 mV, 3 for 2 V, 4
            % for 20 V, and 5 for 200 V
            case 0 %Read V range
                % Stop continuous updating, read the voltage output range
                fprintf(smdata.inst(ic(1)).data.inst,setupcmd);
                auto = query(smdata.inst(ic(1)).data.inst,':SOUR:VOLT:RANG:AUTO?','%s\n','%g');
                if auto == 0
                    val = query(smdata.inst(ic(1)).data.inst,':SOUR:VOLT:RANG?','%s\n','%g');
                    val = log10(val./2e-3);
                elseif auto == 1
                    val = 0;
                end
                % continuous updating.
                fprintf(smdata.inst(ic(1)).data.inst, continuesupdatingcmd);
            case 1 %write operation; Do not use current source mode for now.
                fprintf(smdata.inst(ic(1)).data.inst,setupcmd);
                if val == 0
                    cmd = sprintf(':SOUR:VOLT:RANG:AUTO %g', 1);
                elseif val>0 && val<=5
                    currentVal = query(smdata.inst(ic(1)).data.inst,':SOURce:VOLTage:AMPLitude?','%s\n','%g');
                    if abs(currentVal) <= (10.^val)*2e-3
                        cmd = sprintf(':SOUR:VOLT:RANG:AUTO %g;:SOUR:VOLT:RANG %g',0, (10.^val)*2e-3);
                    else
                        error('Current output value is larger than this range. Please change the output value then modify the output range')
                    end
                end
                fprintf(smdata.inst(ic(1)).data.inst, cmd);
                pause(0.05);
                % continuous updating.
                fprintf(smdata.inst(ic(1)).data.inst, continuesupdatingcmd);
            otherwise
                error('K2450 driver: Operation not supported');
        end

    case 4 %VgRead
        switch ic(3); %Operation: 0 for read, 1 for write
            case 0 %Read the voltage readback for voltage source
                fprintf(smdata.inst(ic(1)).data.inst,setupcmd);
                % Stop continuous updating, measure the current and read the voltage readback
                val = query(smdata.inst(ic(1)).data.inst,':SOURce:VOLTage:READ:BACK 1;:SENSe:COUNt 1;:MEASure:CURRent? "defbuffer1", SOUR','%s\n','%g');
                % continuous updating.
                fprintf(smdata.inst(ic(1)).data.inst, continuesupdatingcmd);
            otherwise
                error('K2450 driver: Operation not supported');
        end
    case 5 %Ilimit
        switch ic(3); %Operation: 0 for read, 1 for write
            case 0 %Read the I limit for voltage source
                fprintf(smdata.inst(ic(1)).data.inst,setupcmd);
                val = query(smdata.inst(ic(1)).data.inst,':SOURce:VOLTage:ILIMit?;','%s\n','%g');
                % continuous updating.
                fprintf(smdata.inst(ic(1)).data.inst, continuesupdatingcmd);
            case 1 %write operation;
                fprintf(smdata.inst(ic(1)).data.inst,setupcmd);

                if abs(val)<100e-9
                    error('Too small current limit for 1 uA range')
                elseif abs(val)> 1.05e-6
                    error('Too large current limit for 1 uA range')
                else
                    cmd = sprintf(':SOURce:VOLTage:ILIMit %g;', val);
                    fprintf(smdata.inst(ic(1)).data.inst, cmd);
                    % continuous updating.
                    fprintf(smdata.inst(ic(1)).data.inst, continuesupdatingcmd);
                end
            otherwise
                error('K2450 driver: Operation not supported');
        end
    case 6
        switch ic(3)
            case 1
                % Sample time can be changed continuously from 15.303
                % ms (0.01 NPLCs) to 181.824 ms (10 NPLCs) Configure
                % instrument: source voltage and measure current with
                % read back. Source delay is 0 and source auto range is
                % off. Sense current and turn off current auto zero and
                % current average filter.
                fprintf(smdata.inst(ic(1)).data.inst,setupcmd);
                fprintf(smdata.inst(ic(1)).data.inst, [':DISPlay:CURRent:DIGits 5;:DISPlay:LIGHt:STATe OFF;:DISPlay:LIGHt:STATe ON75;' ...
                    ':SOURce:VOLTage:READ:BACK 0;:SOUR:VOLT:DElay 0;:SOUR:VOLT:RANG:AUTO 0;' ...
                    ':SENSe:CURRent:AZERo 0;:SENSe:CURRent:AVERage 0;' ...
                    ':SENSe:CURRent:DELay:USER1 0;:SENSe:CURRent:RELative:STATe 0;' ...
                    ':TRACe:POINts 100000, "defbuffer1"; :TRACe:FILL:MODE CONTinuous, "defbuffer1"']);
                % Ask start output value
                startValue = query(smdata.inst(ic(1)).data.inst,':SOURce:VOLTage:AMPLitude?','%s\n','%g');
                outputRange = query(smdata.inst(ic(1)).data.inst,':SOUR:VOLT:RANG?','%s\n','%g');

                if val == startValue
                    val = 0;
                    return
                elseif abs(val) > outputRange
                    error('Change output range to match')
                end

                totTime = abs((val-startValue)./rate);
                delayTime = 0;

                if rate < 0 && smdata.inst(ic(1)).data.RampPts ~= 0
                    totPoints = smdata.inst(ic(1)).data.RampPts;
                    mySampleTime = totTime./(totPoints-1);
                    % Using calibrated sample time to nplcs formula to get new nplcs.
                    % nplcs = 30.02827235*mySampleTime-0.56378305;
                    % mySampleTime = (33.301949*nplcs+18.77507449)./1000;

                    nplcs = 1000./16.6705*mySampleTime-15.1493./16.6705;
                    % mySampleTime = (16.6688*nplcs+15.1367)./1000;

                    if nplcs < 0.01
                        error('Sampling rate maximum is 65.345 Hz (15.303 ms).Try to reduce sampling points.');
                    end
                    if abs((val-startValue)./totPoints) < outputRange/4e4
                        error('The minimul voltage step for this range is %g, while voltage step now is %g', outputRange/4e4,abs((val-startValue)./totPoints));
                    end
                else
                    % At least we should have 2 pts
                    % totPoints = max(fix(totTime./19.10809e-3),1)+1;
                    % Default nplcs is 5.1
                    totPoints = max(fix(totTime./50e-3),1)+1;
                    mySampleTime = totTime./(totPoints-1);
                    % nplcs = max(1000./16.6688*mySampleTime-15.1367./16.6688,5.1);
                    nplcs = 1000./16.6705*mySampleTime-15.1493./16.6705;
                    if nplcs < 0.01
                        nplcs = 0.01;
                        mySampleTime = (16.6705*nplcs+15.1493)./1000;
                        totTime = mySampleTime.*(totPoints-1);
                        fprintf('Total time is changed to %g s\n', totTime);
                    end
                end
                % If ramping too slow, adding delay time.
                if nplcs > 10
                    delayTime = mySampleTime - 0.18185430;
                    if delayTime < 50e-6
                        delayTime = 50e-6;
                        mySampleTime =  0.18182470 - delayTime;
                        nplcs = 1000./16.6705*mySampleTime-15.1493./16.6705;
                    else
                        nplcs = 10;
                    end
                    % warning('Sampling time maximum is 181.8247 ms. Adding delay time.')
                end

                % Delay time must between 50 us and 1e4 s
                % :SOURce[1]:SWEep:<function>:LINear <start>, <stop>, <points>, <delay>, <count>, <rangeType>, <failAbort>, <dual>, "<bufferName>"
                % Configure current NPLC.
                fprintf(smdata.inst(ic(1)).data.inst, ':SENSe:CURRent:NPLCycles %.5g;',nplcs);
                % Setup sweep trigger
                % Turn off abort on limit
                % fprintf(smdata.inst(ic(1)).data.inst, ...
                %     sprintf(':SOURce:SWEep:VOLTage:LINear %g, %g, %g, %g, 1, FIXed, ON, OFF, "defbuffer1"', ...
                %     startValue,val,totPoints,delayTime));
                % fprintf(smdata.inst(ic(1)).data.inst, ':TRIGger:BLOCk:SOURce:STATe 9, 1');
                % fprintf(smdata.inst(ic(1)).data.inst, ':TRIGger:BLOCk:SOURce:STATe 11, 1');
                fprintf(smdata.inst(ic(1)).data.inst, ...
                    sprintf(':SOURce:SWEep:VOLTage:LINear %g, %g, %g, %g, 1, FIXed, OFF, OFF, "defbuffer1"', ...
                    startValue,val,totPoints,delayTime));
                % Don't turn off source output when finish.
                % Run query(K2450_obj,':TRIG:BLOCk:LIST?') to check trig
                % block ist
                if delayTime > 0
                    fprintf(smdata.inst(ic(1)).data.inst, ':TRIGger:BLOCk:SOURce:STATe 9, 1');
                else
                    fprintf(smdata.inst(ic(1)).data.inst, ':TRIGger:BLOCk:SOURce:STATe 8, 1');
                end

                % Check trigger blocks
                % query(smdata.inst(ic(1)).data.inst,':TRIG:BLOCk:LIST?');
                if rate > 0
                    fprintf(smdata.inst(ic(1)).data.inst, 'INIT');
                end
                pause(0.5);
                val = totTime;
                smdata.inst(ic(1)).data.RampTime = totTime;
            case 0
                % Stop continuous updating, measure the current and read the voltage readback
                fprintf(smdata.inst(ic(1)).data.inst,setupcmd);
                val = query(smdata.inst(ic(1)).data.inst,':SOURce:VOLTage:AMPLitude?','%s\n','%g');
                % continuous updating.
                fprintf(smdata.inst(ic(1)).data.inst, continuesupdatingcmd);
            case 3
                fprintf(smdata.inst(ic(1)).data.inst, 'INIT');

        end

case 7 % Ig-buf  —— Buffered current on 2450
    inst = smdata.inst(ic(1)).data.inst;

    switch ic(3)
        case 3  % one-time configure & arm
            
            
                        % Abort any previous action and prepare the buffer
            fprintf(inst, ':ABORt;:TRIG:LOAD "Empty"');
            fprintf(inst, ':TRACe:CLEar "defbuffer1"');
            fprintf(inst, ':TRACe:POINts 100000,"defbuffer1"');
            % Feed current readings into defbuffer1; NEXT => one reading per trigger
            fprintf(inst, ':TRACe:FILL:MODE ONCE, "defbuffer1"');
            

            % Keep your sense/source basics but DO NOT load a trigger model here
            % (No TRIGger:LOAD "LoopUntilEvent", to avoid lockout)
            fprintf(inst, ':SENSe:CURRent:NPLCycles 1.000');   % keep your NPLC
          
            

            smdata.inst(ic(1)).data.RampPts = 0;  % reset planned points (optional)
            val = [];  % nothing to return

        case 2  % single-shot: push one reading into buffer (and wait until it arrives)
            % Trigger ONE sample into defbuffer1
            fprintf(inst, ':TRACe:TRIGger "defbuffer1"');

         
            val = [];  % no data returned here

        case 0  % read out all available points (do NOT query if none)
            % How many points available?
            stopindex = str2double(query(inst, ':TRACe:ACTual:END? "defbuffer1"'));
            if isempty(stopindex) || isnan(stopindex) || stopindex < 1
                % Nothing to read; return empty and DO NOT issue TRACe:DATA?
                val = [];
                return;
            end

            % Read [1 .. stopindex] as current (READ)
            % NOTE: for long buffers, consider chunking; here small scans are fine
            raw = query(inst, sprintf(':TRACe:DATA? %u,%u,"defbuffer1",READ', 1, stopindex));
            % Parse CSV to double row vector
            vals = sscanf(raw, '%g,');  % column vector
            val  = vals.';              % row vector as MATLAB cell return expects later
            fprintf(inst,':ABORt;:TRIG:LOAD "Empty";:TRACe:CLEar "defbuffer1";:count 1;:trig:cont REST');
            % Optional: clear or keep buffer depending on your workflow
            % fprintf(inst, ':TRACe:CLEar "defbuffer1"');

            % Reset "planned" points tracking, if you use it
            smdata.inst(ic(1)).data.RampPts = 0;
           

        case 4
            % keep your existing behavior (planned points comes from datadim)
            smdata.inst(ic(1)).data.RampPts = smdata.inst(ic(1)).datadim(ic(2));

        case 5
            % set planned points & derived ramp time if you need it
            fclose(inst);                 % 
            inst.InputBufferSize = 1e6;   % Buffersize 1 MB
            inst.Timeout = 20;            % 
            fopen(inst);                  % 
            smdata.inst(ic(1)).datadim(ic(2)) = val;
            smdata.inst(ic(1)).data.RampPts   = val;
            smdata.inst(ic(1)).data.RampTime  = (val-1)./rate;
        

        otherwise
            error('K2450 driver: Operation not supported for case 7');
    end






end















