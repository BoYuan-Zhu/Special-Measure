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
% NOTE (2025-08-19): This version is configured for 1 mA current measurement range.
%   - :SENSe:CURRent:RANGe 1E-3
%   - I-limit checks updated to ~1 mA scale.
%
% SCPI usage is organized to:
%   - enter a known state for each op
%   - perform one-shot queries when reading
%   - resume continuous updating afterward when needed

global smdata;

% --- Initialization command string ---
% Set source VOLT mode, measure CURR; fix current measurement range to 1 mA;
% default NPLC to 5 for a good balance of speed/noise.
setupcmd = [...
    ':ABORt;' ...
    ':SOURce:FUNCtion:MODE VOLT;' ...
    ':SENSe:FUNCtion "CURRent";' ...
    ':SENSe:CURRent:RANGe 1E-3;' ...      % <<< 1 mA range
    ':SENSe:CURRent:NPLCycles 5.000;' ...
];

% Resume continuous updating: enable V readback, set NPLC (idempotent),
% install a simple trigger model for display responsiveness, and INIT.
continuesupdatingcmd = [...
    ':SOURce:VOLTage:READ:BACK 1;' ...
    ':SENSe:CURRent:NPLCycles 5.000;' ...
    ':TRIGger:LOAD "LoopUntilEvent", DISP, 50;' ...
    ':INIT' ...
];

switch ic(2) % Channel selector
    case 1 % 'Vg'
        switch ic(3) % 0: read, 1: write
            case 0 % read setpoint voltage
                fprintf(smdata.inst(ic(1)).data.inst, setupcmd);
                val = query(smdata.inst(ic(1)).data.inst, ':SOURce:VOLTage:AMPLitude?', '%s\n', '%g');
                fprintf(smdata.inst(ic(1)).data.inst, continuesupdatingcmd);
            case 1 % write setpoint voltage
                fprintf(smdata.inst(ic(1)).data.inst, setupcmd);
                cmd = sprintf(':SOURce:VOLTage %g', val);
                fprintf(smdata.inst(ic(1)).data.inst, cmd);
                fprintf(smdata.inst(ic(1)).data.inst, continuesupdatingcmd);
            case {3,4,5}
                val = [];
            otherwise
                error('K2450 driver: Operation not supported for Vg');
        end

    case 2 % 'Ig'
        switch ic(3)
            case 0 % read measured current once
                fprintf(smdata.inst(ic(1)).data.inst, setupcmd);
                val = query(smdata.inst(ic(1)).data.inst, ':SENSe:COUNt 1;:MEASure:CURRent? "defbuffer1", READ', '%s\n', '%g');
                fprintf(smdata.inst(ic(1)).data.inst, continuesupdatingcmd);
            case 1
                error('K2450 driver: Current source mode not supported here.');
            otherwise
                error('K2450 driver: Operation not supported for Ig');
        end

    case 3 % 'VgRange' (output voltage range)
        switch ic(3)
            case 0 % read voltage output range
                fprintf(smdata.inst(ic(1)).data.inst, setupcmd);
                auto = query(smdata.inst(ic(1)).data.inst, ':SOUR:VOLT:RANG:AUTO?', '%s\n', '%g');
                if auto == 0
                    rng = query(smdata.inst(ic(1)).data.inst, ':SOUR:VOLT:RANG?', '%s\n', '%g');
                    val = log10(rng / 2e-3); % map to 1..5 index (legacy encoding)
                else
                    val = 0; % auto
                end
                fprintf(smdata.inst(ic(1)).data.inst, continuesupdatingcmd);
            case 1 % write voltage output range by index convention
                fprintf(smdata.inst(ic(1)).data.inst, setupcmd);
                if val == 0
                    cmd = ':SOUR:VOLT:RANG:AUTO 1';
                elseif val > 0 && val <= 5
                    currentVal = query(smdata.inst(ic(1)).data.inst, ':SOURce:VOLTage:AMPLitude?', '%s\n', '%g');
                    targetRange = (10.^val) * 2e-3; % 20 mV, 200 mV, 2 V, 20 V, 200 V
                    if abs(currentVal) <= targetRange
                        cmd = sprintf(':SOUR:VOLT:RANG:AUTO 0;:SOUR:VOLT:RANG %g', targetRange);
                    else
                        error('Current output value exceeds the target range. Reduce output first, then change range.');
                    end
                else
                    error('Invalid VgRange index. Use 0..5.');
                end
                fprintf(smdata.inst(ic(1)).data.inst, cmd);
                pause(0.05);
                fprintf(smdata.inst(ic(1)).data.inst, continuesupdatingcmd);
            otherwise
                error('K2450 driver: Operation not supported for VgRange');
        end

    case 4 % 'VgRead' (voltage readback via measure source)
        switch ic(3)
            case 0
                fprintf(smdata.inst(ic(1)).data.inst, setupcmd);
                val = query(smdata.inst(ic(1)).data.inst, ':SOURce:VOLTage:READ:BACK 1;:SENSe:COUNt 1;:MEASure:CURRent? "defbuffer1", SOUR', '%s\n', '%g');
                fprintf(smdata.inst(ic(1)).data.inst, continuesupdatingcmd);
            otherwise
                error('K2450 driver: Operation not supported for VgRead');
        end

    case 5 % 'Iglimit' (compliance current for voltage source)
        switch ic(3)
            case 0 % read I-limit
                fprintf(smdata.inst(ic(1)).data.inst, setupcmd);
                val = query(smdata.inst(ic(1)).data.inst, ':SOURce:VOLTage:ILIMit?;', '%s\n', '%g');
                fprintf(smdata.inst(ic(1)).data.inst, continuesupdatingcmd);
            case 1 % set I-limit (validate against ~1 mA range)
                fprintf(smdata.inst(ic(1)).data.inst, setupcmd);
                % For 1 mA range, use sane guard rails:
                if abs(val) < 100e-6
                    error('Too small current limit for 1 mA range (min ~100 uA).');
                elseif abs(val) > 1.05e-3
                    error('Too large current limit for 1 mA range (max ~1.05 mA).');
                else
                    cmd = sprintf(':SOURce:VOLTage:ILIMit %g;', val);
                    fprintf(smdata.inst(ic(1)).data.inst, cmd);
                    fprintf(smdata.inst(ic(1)).data.inst, continuesupdatingcmd);
                end
            otherwise
                error('K2450 driver: Operation not supported for Iglimit');
        end

    case 6 % 'Vg-ramp' configuration / timing
        switch ic(3)
            case 1 % configure ramp to target 'val' with rate 'rate' (V/s)
                fprintf(smdata.inst(ic(1)).data.inst, setupcmd);
                fprintf(smdata.inst(ic(1)).data.inst, [...
                    ':DISPlay:CURRent:DIGits 5;' ...
                    ':DISPlay:LIGHt:STATe OFF;' ...
                    ':DISPlay:LIGHt:STATe ON75;' ...
                    ':SOURce:VOLTage:READ:BACK 0;' ...
                    ':SOUR:VOLT:DElay 0;' ...
                    ':SOUR:VOLT:RANG:AUTO 0;' ...
                    ':SENSe:CURRent:AZERo 0;' ...
                    ':SENSe:CURRent:AVERage 0;' ...
                    ':SENSe:CURRent:DELay:USER1 0;' ...
                    ':SENSe:CURRent:RELative:STATe 0;' ...
                    ':TRACe:FILL:MODE ONCE, "defbuffer1"' ...   % <<< use ONCE (standard path)
                ]);

                startValue  = query(smdata.inst(ic(1)).data.inst, ':SOURce:VOLTage:AMPLitude?', '%s\n', '%g');
                outputRange = query(smdata.inst(ic(1)).data.inst, ':SOUR:VOLT:RANG?', '%s\n', '%g');

                if val == startValue
                    val = 0; % no-op
                    return
                elseif abs(val) > outputRange
                    error('Requested target exceeds current voltage range. Adjust V range or target.');
                end

                totTime   = abs((val - startValue) ./ rate);
                delayTime = 0;

                if rate < 0 && smdata.inst(ic(1)).data.RampPts ~= 0
                    totPoints    = smdata.inst(ic(1)).data.RampPts;
                    mySampleTime = totTime ./ (totPoints - 1);
                    nplcs = 1000./16.6705 * mySampleTime - 15.1493./16.6705;

                    if nplcs < 0.01
                        error('Sampling rate max is ~65.345 Hz (15.303 ms). Reduce number of points.');
                    end
                    if abs((val - startValue) ./ totPoints) < outputRange / 4e4
                        error('Minimum DAC step for this range is %g, current step is %g', ...
                              outputRange/4e4, abs((val - startValue) ./ totPoints));
                    end
                else
                    totPoints    = max(fix(totTime ./ 50e-3), 1) + 1; % default ~20 Hz planning
                    mySampleTime = totTime ./ (totPoints - 1);
                    nplcs = 1000./16.6705 * mySampleTime - 15.1493./16.6705;
                    if nplcs < 0.01
                        nplcs = 0.01;
                        mySampleTime = (16.6705*nplcs + 15.1493) ./ 1000;
                        totTime = mySampleTime * (totPoints - 1);
                        fprintf('Total time adjusted to %g s (NPLC floor).\n', totTime);
                    end
                end

                if nplcs > 10
                    delayTime = mySampleTime - 0.18182470; % ~10 NPLC base time
                    if delayTime < 50e-6
                        delayTime   = 50e-6;
                        mySampleTime = 0.18182470 - delayTime;
                        nplcs        = 1000./16.6705 * mySampleTime - 15.1493./16.6705;
                    else
                        nplcs = 10;
                    end
                end

                % Apply NPLC decided above
                fprintf(smdata.inst(ic(1)).data.inst, sprintf(':SENSe:CURRent:NPLCycles %.5g;', nplcs));
                % Set points for defbuffer1 (standard path uses exact number of points)
                fprintf(smdata.inst(ic(1)).data.inst, sprintf(':TRACe:CLEar "defbuffer1";:TRACe:POINts %u, "defbuffer1"', uint32(totPoints)));
                % Program sweep to write into defbuffer1
                fprintf(smdata.inst(ic(1)).data.inst, sprintf( ...
                    ':SOURce:SWEep:VOLTage:LINear %g, %g, %g, %g, 1, FIXed, OFF, OFF, "defbuffer1"', ...
                    startValue, val, totPoints, delayTime));

                % Use a simple trigger model; INIT starts the sweep immediately for positive rate
                if rate > 0
                    fprintf(smdata.inst(ic(1)).data.inst, 'INIT');
                end
                pause(0.5);
                val = totTime;
                smdata.inst(ic(1)).data.RampTime = totTime;

            case 0 % read current setpoint voltage
                fprintf(smdata.inst(ic(1)).data.inst, setupcmd);
                val = query(smdata.inst(ic(1)).data.inst, ':SOURce:VOLTage:AMPLitude?', '%s\n', '%g');
                fprintf(smdata.inst(ic(1)).data.inst, continuesupdatingcmd);

            case 3 % re-trigger/init
                fprintf(smdata.inst(ic(1)).data.inst, 'INIT');
        end

    case 7 % 'Ig-buf' buffered current readout
        switch ic(3)
            case 0
                % --- Standard buffered read: wait until buffer has N points, then TRAC:DATA? 1,N,READ ---
                % RME:
                % - Requirement: Read exactly RampPts samples after sweep.
                % - Modify: Poll :TRACe:ACTual:END? until >= RampPts with timeout, then one-shot TRAC:DATA?
                % - Effect: Robust, no dependency on :TRIGger:STATe?
                expectedPts = smdata.inst(ic(1)).data.RampPts;
                if ~isfinite(expectedPts) || expectedPts <= 0
                    error('K2450 Ig-buf: RampPts not set (<=0). Configure via op=5 before reading.');
                end
                rampTime = smdata.inst(ic(1)).data.RampTime;
                if ~isfinite(rampTime) || rampTime <= 0
                    rampTime = 5; % fallback
                end
                timeout_s = max(5, 1.5 * rampTime);
                tStart    = tic;

                % Wait until END? reports at least expectedPts
                stopindex = 0;
                while stopindex < expectedPts
                    stopindex = query(smdata.inst(ic(1)).data.inst, ':TRACe:ACTual:END? "defbuffer1"', '%s\n', '%g');
                    if stopindex >= expectedPts
                        break;
                    end
                    if toc(tStart) > timeout_s
                        warning('K2450 Ig-buf: timeout after %.2fs (have %d/%d points). Reading available points.', ...
                                toc(tStart), stopindex, expectedPts);
                        break;
                    end
                    pause(0.05);
                end

                nread = min(stopindex, expectedPts);
                if nread <= 0
                    error('K2450 Ig-buf: no points available in defbuffer1 (stopindex=%d).', stopindex);
                end

                raw = query(smdata.inst(ic(1)).data.inst, ...
                    sprintf(':TRACe:DATA? %u,%u,"defbuffer1",READ', 1, nread), '%s\n');
                val = sscanf(raw, '%g,', [1 nread]);

                % bookkeeping + resume
                smdata.inst(ic(1)).data.RampPts = 0;
                fprintf(smdata.inst(ic(1)).data.inst, setupcmd);
                fprintf(smdata.inst(ic(1)).data.inst, continuesupdatingcmd);

            case 4
                smdata.inst(ic(1)).data.RampPts = smdata.inst(ic(1)).datadim(ic(2));
            case 5
                smdata.inst(ic(1)).datadim(ic(2)) = val;
                smdata.inst(ic(1)).data.RampPts   = val;
                smdata.inst(ic(1)).data.RampTime  = (val - 1) ./ rate;
        end

    otherwise
        error('K2450 driver: Invalid channel.');
end

end
