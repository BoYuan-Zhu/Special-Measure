function [val, rate] = smcK34465A_buf(ico, val, rate)

global smdata;

switch ico(2) % channel
    case 1
        switch ico(3)
            case 0
                % Set trigger mode to immediate and only trigger once when
                % reading.
                fprintf(smdata.inst(ico(1)).data.inst, 'ABORt');
                fprintf(smdata.inst(ico(1)).data.inst, ':TRIG:SOURce IMM;:TRIG:COUNt 1');
                % Set sampling time to immediate (using NPLC), and sampel
                % count to 1.
                fprintf(smdata.inst(ico(1)).data.inst, ':SAMP:SOURce IMM;:SAMP:COUNt 1');
                val = query(smdata.inst(ico(1)).data.inst,  'READ?', '%s\n', '%f');
            otherwise
                error('Operation not supported');
        end
    case 2
        switch ico(3)
            case 0
                % this blocks until all values are available
                val = sscanf(query(smdata.inst(ico(1)).data.inst,  'FETCH?'), '%f,')';
            case 3
                % trigger(smdata.inst(ico(1)).data.inst);
                fprintf(smdata.inst(ico(1)).data.inst,'*TRG');
            otherwise
                error('Operation not supported');
        end
    case {3, 4, 5, 6, 7, 8, 9, 10, 11}
        switch ico(3)
            case 0
                % this blocks until all values are available
                val = sscanf(query(smdata.inst(ico(1)).data.inst,  'FETCH?'), '%f,')';
            case 3
                % trigger DMM
                % trigger(smdata.inst(ico(1)).data.inst);
                fprintf(smdata.inst(ico(1)).data.inst,'*TRG');

            case 4
                % put DMM in wait-for-trigger state
                fprintf(smdata.inst(ico(1)).data.inst, 'INIT');
            case 5
                fprintf(smdata.inst(ico(1)).data.inst, 'ABORt');

                % set up for software triggering:
                fprintf(smdata.inst(ico(1)).data.inst, 'TRIG:SOUR BUS');
                % Turn off auto-zeroing (referencing), which also has a
                % dramatic effect on the sampling rate.
                fprintf(smdata.inst(ico(1)).data.inst, 'SENS:ZERO:AUTO OFF');
                % Turn off auto-ranging. This has a dramatic effect on
                % sampling rate when going fast
                fprintf(smdata.inst(ico(1)).data.inst, 'VOLT:DC:RANG:AUTO OFF');
                % Turn off display (improves acquisition rate)
                fprintf(smdata.inst(ico(1)).data.inst, 'DISP OFF');
                % Use sample timer to set interval between measurements.
                % When the sample timer is enabled, the time between the trigger
                % and the first measurement is set by TRIG:DEL. Then, the time
                % between measurements is set by SAMP:TIM. Note that this
                % functionality is not available on the original HP34401A DMM--in
                % that case you have to use TRIG:DEL.
                fprintf(smdata.inst(ico(1)).data.inst, 'SAMP:SOUR TIM');
                fprintf(smdata.inst(ico(1)).data.inst, 'TRIG:DEL 0');
                tottime = (val-1)/rate;

                % set NPLC
                switch ico(2)
                    case 3 %Buffered acquisition with 100 NPLC
                        % This is not really recommend. 100 NPLC is really slow and
                        % seems to have timing issues
                        % Maximum sample rate at 100 NPLC is 0.6 Hz
                        maxRate = 0.6;
                        fprintf(smdata.inst(ico(1)).data.inst, 'VOLT:DC:NPLC 100');
                    case 4 %Buffered acquisition with 10 NPLC
                        % Maximum sample rate at 10 NPLC is 6 Hz
                        maxRate = 6;
                        fprintf(smdata.inst(ico(1)).data.inst, 'VOLT:DC:NPLC 10');
                    case 5 % Buffered acquisition with 1 NPLC
                        % Maximum sample rate at 1 NPLC is 60 Hz
                        maxRate = 60;
                        fprintf(smdata.inst(ico(1)).data.inst, 'VOLT:DC:NPLC 1');
                    case 6 % Buffered acquisition with 0.2 NPLC
                        % Maximum sample rate at .2 NPLC is 1000/3 ~ 333 Hz
                        % This is found empirically. The manual says 300 Hz max...
                        maxRate = 1000/3;
                        fprintf(smdata.inst(ico(1)).data.inst, 'VOLT:DC:NPLC .2');
                    case 7 % Buffered acquisition with 0.06 NPLC
                        % Maximum sample rate at .06 NPLC is 1 kHz
                        maxRate = 1000;
                        fprintf(smdata.inst(ico(1)).data.inst, 'VOLT:DC:NPLC .06');
                    case 8 % Buffered acquisition with 0.02 NPLC
                        % Maximum sample rate at .02 NPLC is 10000/3 ~ 3.33 kHz
                        % This is found empirically. The manual says 3 kHz max...
                        maxRate = 10000/3;
                        fprintf(smdata.inst(ico(1)).data.inst, 'VOLT:DC:NPLC .02');
                    case 9 % Buffered acquisition with 0.006 NPLC
                        % Maximum sample rate at 0.006 NPLC is 10 kHz
                        maxRate = 10000;
                        fprintf(smdata.inst(ico(1)).data.inst, 'VOLT:DC:NPLC .006');
                    case 10 % Buffered acquisition with 0.002 NPLC
                        % Maximum sample rate at 0.002 NPLC is 25 kHz
                        maxRate = 25000;
                        fprintf(smdata.inst(ico(1)).data.inst, 'VOLT:DC:NPLC .002');
                    case 11 % Buffered acquisition with 0.001 NPLC
                        % Maximum sample rate at 0.001 NPLC is 25 kHz
                        maxRate = 25000;
                        fprintf(smdata.inst(ico(1)).data.inst, 'VOLT:DC:NPLC .001');
                end


                % Set number of points to sample
                if (tottime/(val-1) - 1/maxRate) >= 0
                    fprintf(smdata.inst(ico(1)).data.inst, ['SAMP:COUN ' num2str(val)]);
                    fprintf(smdata.inst(ico(1)).data.inst, sprintf('SAMP:TIM %2.6f', tottime/(val-1)));
                else
                    % Don't change the points and rate. Just report error.
                    error('Npoints is changed to max rate of dmm');
                    % fprintf(smdata.inst(ico(1)).data.inst, sprintf('SAMP:COUNT %05i', tottime*maxRate+1));
                    % fprintf(smdata.inst(ico(1)).data.inst, 'SAMP:TIM MIN');
                    % rate = maxRate;
                    % val = round(tottime*maxRate+1);
                end
                % Set datadim to current number (number of points per
                % sweep)
                smdata.inst(ico(1)).datadim(ico(2)) = val;

            otherwise
                error('Operation not supported');
        end

    case 12 % voltage measurement range (needed when autorange turned off)
        switch ico(3)
            case 0
                % this blocks until all values are available
                val = sscanf(query(smdata.inst(ico(1)).data.inst,  'VOLT:DC:RANG?'), '%f')';

            case 1 % set
                if (val~=0.1) && (val~=1) && (val~=10) && (val~=100) && (val~=1000)
                    error('Invalid range provided: must be 0.1, 1, 10, 100 or 1000.');
                end
                fprintf(smdata.inst(ico(1)).data.inst, sprintf('VOLT:DC:RANG %4.1f', val));

            otherwise
                error('Operation not supported');
        end
end