function [val, rate] = smcK2450_Ramp(ic, val, rate)
% Make sure K2450 is in SOURCE VOLTAGE / MEASURE CURRENT mode.
% Channels:
%   1 - 'Vg'       voltage setpoint
%   2 - 'Ig'       measured current
%   3 - 'VgRange'  voltage range control (0:auto; 1:20 mV; 2:200 mV; 3:2 V; 4:20 V; 5:200 V)
%   4 - 'VgRead'   voltage readback (measurement source reading)
%   5 - 'Iglimit'  current compliance limit for voltage source
%   6 - 'Vg-ramp'  ramp configuration / timing
%   7 - 'Ig-buf'   buffered current readout
%
% NOTE (2025-08-19): Configured for 1 mA current measurement range.
%   - :SENSe:CURRent:RANGe 1E-3
%   - I-limit checks updated to ~1 mA scale.

global smdata;

% --- Initialization command string ---
setupcmd = [...
    ':ABORt;' ...
    ':SOURce:FUNCtion:MODE VOLT;' ...
    ':SENSe:FUNCtion "CURRent";' ...
    ':SENSe:CURRent:RANGe 1E-3;' ...
    ':SENSe:CURRent:NPLCycles 5.000;' ...
];

% Resume continuous updating
continuesupdatingcmd = [...
    ':SOURce:VOLTage:READ:BACK 1;' ...
    ':SENSe:CURRent:NPLCycles 5.000;' ...
    ':TRIGger:LOAD "LoopUntilEvent", DISP, 50;' ...
    ':INIT' ...
];

switch ic(2)
    % ---------------- Vg ----------------
    case 1
        switch ic(3)
            case 0
                fprintf(smdata.inst(ic(1)).data.inst, setupcmd);
                val = query(smdata.inst(ic(1)).data.inst, ...
                    ':SOURce:VOLTage:AMPLitude?', '%s\n', '%g');
                fprintf(smdata.inst(ic(1)).data.inst, continuesupdatingcmd);
            case 1
                fprintf(smdata.inst(ic(1)).data.inst, setupcmd);
                cmd = sprintf(':SOURce:VOLTage %g', val);
                fprintf(smdata.inst(ic(1)).data.inst, cmd);
                fprintf(smdata.inst(ic(1)).data.inst, continuesupdatingcmd);
            otherwise
                val = [];
        end

    % ---------------- Ig ----------------
    case 2
        switch ic(3)
            case 0
                fprintf(smdata.inst(ic(1)).data.inst, setupcmd);
                val = query(smdata.inst(ic(1)).data.inst, ...
                    ':SENSe:COUNt 1;:MEASure:CURRent? "defbuffer1", READ', ...
                    '%s\n', '%g');
                fprintf(smdata.inst(ic(1)).data.inst, continuesupdatingcmd);
            otherwise
                error('K2450 driver: Operation not supported for Ig');
        end

    % ---------------- VgRange ----------------
    case 3
        switch ic(3)
            case 0
                fprintf(smdata.inst(ic(1)).data.inst, setupcmd);
                auto = query(smdata.inst(ic(1)).data.inst, ...
                    ':SOUR:VOLT:RANG:AUTO?', '%s\n', '%g');
                if auto == 0
                    rng = query(smdata.inst(ic(1)).data.inst, ...
                        ':SOUR:VOLT:RANG?', '%s\n', '%g');
                    val = log10(rng / 2e-3);
                else
                    val = 0;
                end
                fprintf(smdata.inst(ic(1)).data.inst, continuesupdatingcmd);
            case 1
                fprintf(smdata.inst(ic(1)).data.inst, setupcmd);
                if val == 0
                    cmd = ':SOUR:VOLT:RANG:AUTO 1';
                elseif val > 0 && val <= 5
                    currentVal = query(smdata.inst(ic(1)).data.inst, ...
                        ':SOURce:VOLTage:AMPLitude?', '%s\n', '%g');
                    targetRange = (10.^val) * 2e-3;
                    if abs(currentVal) <= targetRange
                        cmd = sprintf(...
                            ':SOUR:VOLT:RANG:AUTO 0;:SOUR:VOLT:RANG %g', ...
                            targetRange);
                    else
                        error('Output exceeds range. Reduce output first.');
                    end
                else
                    error('Invalid VgRange index. Use 0..5.');
                end
                fprintf(smdata.inst(ic(1)).data.inst, cmd);
                pause(0.05);
                fprintf(smdata.inst(ic(1)).data.inst, continuesupdatingcmd);
        end

    % ---------------- VgRead ----------------
    case 4
        if ic(3) == 0
            fprintf(smdata.inst(ic(1)).data.inst, setupcmd);
            val = query(smdata.inst(ic(1)).data.inst, ...
                ':SOURce:VOLTage:READ:BACK 1;:SENSe:COUNt 1;:MEASure:CURRent? "defbuffer1", SOUR', ...
                '%s\n', '%g');
            fprintf(smdata.inst(ic(1)).data.inst, continuesupdatingcmd);
        end

    % ---------------- Iglimit ----------------
    case 5
        switch ic(3)
            case 0
                fprintf(smdata.inst(ic(1)).data.inst, setupcmd);
                val = query(smdata.inst(ic(1)).data.inst, ...
                    ':SOURce:VOLTage:ILIMit?;', '%s\n', '%g');
                fprintf(smdata.inst(ic(1)).data.inst, continuesupdatingcmd);
            case 1
                fprintf(smdata.inst(ic(1)).data.inst, setupcmd);
                if abs(val) < 100e-6
                    error('Too small current limit (<100 uA).');
                elseif abs(val) > 1.05e-3
                    error('Too large current limit (>1.05 mA).');
                else
                    cmd = sprintf(':SOURce:VOLTage:ILIMit %g;', val);
                    fprintf(smdata.inst(ic(1)).data.inst, cmd);
                    fprintf(smdata.inst(ic(1)).data.inst, continuesupdatingcmd);
                end
        end

    % ---------------- Vg-ramp ----------------
    case 6
        if ic(3) == 1
            fprintf(smdata.inst(ic(1)).data.inst, setupcmd);
            fprintf(smdata.inst(ic(1)).data.inst, [...
                ':SOURce:VOLTage:READ:BACK 0;' ...
                ':TRACe:FILL:MODE ONCE, "defbuffer1"' ...
            ]);

            startValue  = query(smdata.inst(ic(1)).data.inst, ...
                ':SOURce:VOLTage:AMPLitude?', '%s\n', '%g');
            outputRange = query(smdata.inst(ic(1)).data.inst, ...
                ':SOUR:VOLT:RANG?', '%s\n', '%g');

            if abs(val) > outputRange
                error('Target exceeds voltage range.');
            end

            totTime   = abs((val - startValue) ./ rate);
            delayTime = 0;

            % --- Minimal modification: honor RampPts if set ---
            if isfield(smdata.inst(ic(1)).data,'RampPts') && ...
                    smdata.inst(ic(1)).data.RampPts > 0
                totPoints    = smdata.inst(ic(1)).data.RampPts;
                mySampleTime = totTime / max(totPoints-1,1);
                nplcs = 1000./16.6705*mySampleTime - 15.1493./16.6705;
                if nplcs < 0.01, nplcs=0.01; end
                if nplcs > 10,  nplcs=10;  end
                delayTime = 0;
            else
                totPoints    = max(fix(totTime ./ 50e-3), 1) + 1;
                mySampleTime = totTime ./ (totPoints - 1);
                nplcs = 1000./16.6705*mySampleTime - 15.1493./16.6705;
            end

            % Apply NPLC & buffer
            fprintf(smdata.inst(ic(1)).data.inst, ...
                sprintf(':SENSe:CURRent:NPLCycles %.5g;', nplcs));
            fprintf(smdata.inst(ic(1)).data.inst, ...
                ':TRACe:CLEar "defbuffer1"');
            fprintf(smdata.inst(ic(1)).data.inst, ...
                sprintf(':TRACe:POINts %u, "defbuffer1"', uint32(totPoints)));

            % Program sweep
            fprintf(smdata.inst(ic(1)).data.inst, sprintf( ...
                ':SOURce:SWEep:VOLTage:LINear %g, %g, %g, %g, 1, FIXed, OFF, OFF, "defbuffer1"', ...
                startValue, val, totPoints, delayTime));

            if rate > 0
                fprintf(smdata.inst(ic(1)).data.inst, 'INIT');
            end
            pause(0.5);
            val = totTime;
            smdata.inst(ic(1)).data.RampTime = totTime;
        elseif ic(3) == 0
            fprintf(smdata.inst(ic(1)).data.inst, setupcmd);
            val = query(smdata.inst(ic(1)).data.inst, ...
                ':SOURce:VOLTage:AMPLitude?', '%s\n', '%g');
            fprintf(smdata.inst(ic(1)).data.inst, continuesupdatingcmd);
        elseif ic(3) == 3
            fprintf(smdata.inst(ic(1)).data.inst, 'INIT');
        end

    % ---------------- Ig-buf ----------------
    case 7
        switch ic(3)
            case 0
                expectedPts = smdata.inst(ic(1)).data.RampPts;
                if ~isfinite(expectedPts) || expectedPts <= 0
                    error('K2450 Ig-buf: RampPts not set.');
                end
                rampTime = smdata.inst(ic(1)).data.RampTime;
                if ~isfinite(rampTime) || rampTime <= 0, rampTime=5; end
                timeout_s = max(5,1.5*rampTime);
                tStart = tic;

                stopindex=0;
                while stopindex < expectedPts
                    stopindex = query(smdata.inst(ic(1)).data.inst, ...
                        ':TRACe:ACTual:END? "defbuffer1"', '%s\n','%g');
                    if toc(tStart) > timeout_s
                        error('Timeout: only %d/%d pts.', stopindex, expectedPts);
                    end
                    pause(0.05);
                end

                raw = query(smdata.inst(ic(1)).data.inst, ...
                    sprintf(':TRACe:DATA? 1,%u,"defbuffer1",READ', expectedPts), ...
                    '%s\n');
                val = sscanf(raw, '%g,', [1 expectedPts]);

                smdata.inst(ic(1)).data.RampPts=0;
                fprintf(smdata.inst(ic(1)).data.inst, setupcmd);
                fprintf(smdata.inst(ic(1)).data.inst, continuesupdatingcmd);

            case 4
                smdata.inst(ic(1)).data.RampPts = smdata.inst(ic(1)).datadim(ic(2));
            case 5
                smdata.inst(ic(1)).datadim(ic(2)) = val;
                smdata.inst(ic(1)).data.RampPts   = val;
                smdata.inst(ic(1)).data.RampTime  = (val - 1)./rate;
        end

    otherwise
        error('K2450 driver: Invalid channel.');
end
end
