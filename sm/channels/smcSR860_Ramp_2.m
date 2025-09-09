function [val, rate] = smcSR860_Ramp_2(ic, val, rate, ctrl)
%==========================================================================
% SR860 LOCK-IN AMPLIFIER DRIVER
%==========================================================================
% SYNTAX: [val, rate] = smcSR860_Ramp_1(ic, val, rate, ctrl)
%
% DESCRIPTION:
%   Comprehensive driver for Stanford Research SR860 Lock-in Amplifier
%   Supports all measurement channels, data acquisition modes, and 
%   instrument configuration parameters
%
% INPUTS:
%   ic(1)  - Instrument index in smdata global structure
%   ic(2)  - Channel number (see channel map below)  
%   ic(3)  - Operation code (0=get, 1=set, 2-6=special operations)
%   val    - Value to set (for set operations) or max points (for config)
%   rate   - Sample rate in Hz (for data acquisition setup)
%   ctrl   - Control string: 'pertrig' for per-trigger mode
%
% OUTPUTS:
%   val    - Retrieved value or acquired data
%   rate   - Actual sample rate achieved
%
% CHANNEL MAP:
%   Core Outputs:     1-4   (X, Y, R, θ components)
%   Signal Source:    5-6   (Frequency, Amplitude)
%   Aux Inputs:       7-10  (Read auxiliary voltages)
%   Aux Outputs:      11-14 (Set auxiliary voltages)  
%   Data Storage:     15-16 (Legacy high-speed acquisition)
%   Configuration:    17-25 (Sensitivity, time constant, etc.)
%   Advanced Buffer:  30    (High-performance capture mode)
%
% MODES:
%   Voltage/Current mode controlled by channel 24 (IVMD):
%   - IVMD=0: Channels 1-4 return voltage parameters
%   - IVMD=1: Channels 1-4 return current parameters
%
%==========================================================================

global smdata;

%--------------------------------------------------------------------------
% COMMAND LOOKUP TABLE
%--------------------------------------------------------------------------
% Maps channel numbers to SCPI commands for the SR860
cmds = {
    'OUTP 0',   'OUTP 1',   'OUTP 2',   'OUTP 3',   'FREQ',     'SLVL', ...     % 1-6
    'OAUX 0',   'OAUX 1',   'OAUX 2',   'OAUX 3',   'AUXV 0',   'AUXV 1', ...   % 7-12
    'AUXV 2',   'AUXV 3',   '',         '',         'SCAL',     'OFLT', ...     % 13-18
    'SYNC',     'SOFF',     '',         'OUTP 8',   'OUTP 9',   'IVMD', ...     % 19-24
    'HARM'                                                                       % 25
};

%--------------------------------------------------------------------------
% MAIN CHANNEL DISPATCHER
%--------------------------------------------------------------------------
switch ic(2) % Channel selection

    %======================================================================
    % CHANNEL 21: AUTO ADJUSTMENT FUNCTIONS
    %======================================================================
    case 21  % Auto phase, range, and sensitivity optimization
        fprintf(smdata.inst(ic(1)).data.inst, 'APHS');  % Auto phase
        fprintf(smdata.inst(ic(1)).data.inst, 'ARNG');  % Auto range  
        fprintf(smdata.inst(ic(1)).data.inst, 'ASCL');  % Auto sensitivity
        val = 1;  % Success indicator

    %======================================================================
    % CHANNELS 15-16: LEGACY DATA STORAGE MODE
    %======================================================================  
    case {15, 16}  % High-speed data acquisition (legacy implementation)
        
        switch ic(3)  % Operation type
            
            %----------------------------------------------------------
            case 0  % READ: Get stored data from buffer
            %----------------------------------------------------------
                npts = smdata.inst(ic(1)).datadim(ic(2), 1);  % Points to read
                
                % Wait for sufficient data to be available
                while true
                    navail = query(smdata.inst(ic(1)).data.inst, ...
                                 'CAPTUREBYTES?', '%s\n', '%d') / 8;  % 8 bytes per (R,θ) pair
                    
                    % Track current sample position for each channel
                    if ic(2) == 15
                        currsamp = smdata.inst(ic(1)).data.currsamp_real;
                    elseif ic(2) == 16  
                        currsamp = smdata.inst(ic(1)).data.currsamp_phase;
                    end
                    
                    % Check if enough data is available
                    if navail >= npts + currsamp
                        break;
                    else
                        % Wait based on sample interval and missing points
                        pause_time = 0.8 * (npts + currsamp - navail) * ...
                                   smdata.inst(ic(1)).data.sampint;
                        pause(pause_time);
                    end
                end
                
                % Stop capture and read binary data
                fprintf(smdata.inst(ic(1)).data.inst, ...
                       'CAPTURESTOP;CAPTUREGET? 0, %g', ceil(npts*2/256));
                rawdata = readbinblock(smdata.inst(ic(1)).data.inst, 'single');
                
                % Extract requested component
                if ic(2) == 15
                    % Channel 15: X component = R * cos(θ)
                    R_vals = rawdata(1:2:npts*2-1);  % R values (odd indices)
                    theta_vals = rawdata(2:2:npts*2); % θ values (even indices)
                    val = R_vals .* cosd(theta_vals);  % Convert to X component
                    smdata.inst(ic(1)).data.currsamp_real = ...
                        smdata.inst(ic(1)).data.currsamp_real + npts;
                        
                elseif ic(2) == 16
                    % Channel 16: Phase component (θ)
                    val = rawdata(2:2:npts*2);  % Extract θ values
                    smdata.inst(ic(1)).data.currsamp_phase = ...
                        smdata.inst(ic(1)).data.currsamp_phase + npts;
                end
                
            %----------------------------------------------------------
            case 3  % START: Begin data acquisition
            %----------------------------------------------------------
                fprintf(smdata.inst(ic(1)).data.inst, ...
                       'CAPTURESTART 0, 0;');  % OneShot, Immediate
                       
            %----------------------------------------------------------
            case 4  % RESET: Clear sample counters
            %----------------------------------------------------------
                pause(0.1);  % Allow settling time
                if ic(2) == 15
                    smdata.inst(ic(1)).data.currsamp_real = 0;
                elseif ic(2) == 16
                    smdata.inst(ic(1)).data.currsamp_phase = 0;
                end
                
            %----------------------------------------------------------
            case 5  % CONFIGURE: Set sample points and rate
            %----------------------------------------------------------
                % Validate sample count
                if val > 8192
                    error('SR860: Maximum sample points is 8192');
                end
                
                % Query maximum available sample rate
                maxrate = query(smdata.inst(ic(1)).data.inst, ...
                              'CAPTURERATEMAX?', '%s\n', '%g');
                              
                % Calculate optimal divider for requested rate
                if abs(rate) > maxrate
                    error('SR860: Requested rate exceeds maximum. Adjust time constant.');
                else
                    n = ceil(log2(maxrate / abs(rate)));  % Divider exponent
                    rate = maxrate / (2^n);               % Actual achievable rate
                    
                    % Validate divider range
                    if n > 20
                        error('SR860: Sample rate too low (min = %g Hz)', maxrate/2^20);
                    elseif n < 0
                        error('SR860: Sample rate too high (max = %g Hz)', maxrate);
                    end
                end
                
                % Configure capture parameters
                fprintf(smdata.inst(ic(1)).data.inst, ...
                       ['CAPTURESTOP;' ...
                        'CAPTURECFG 2;' ...           % Capture R,θ format
                        'CAPTURERATE %i;' ...         % Set sample rate divider
                        'CAPTURELEN 4096'], n);       % Maximum buffer length
                        
                pause(0.1);  % Allow configuration to settle
                
                % Reset sample counters and store configuration
                if ic(2) == 15
                    smdata.inst(ic(1)).data.currsamp_real = 0;
                elseif ic(2) == 16
                    smdata.inst(ic(1)).data.currsamp_phase = 0;
                end
                
                smdata.inst(ic(1)).data.sampint = 1/rate;  % Store sample interval
                smdata.inst(ic(1)).datadim(15:16, 1) = val; % Store point count
                
            %----------------------------------------------------------
            otherwise
                error('SR860: Unsupported operation for data storage channels');
        end









        
    %======================================================================
    % CHANNEL 30: ADVANCED BUFFER CAPTURE MODE  
    %======================================================================
    case 30  % High-performance data acquisition with flexible triggering
        
        inst = smdata.inst(ic(1)).data.inst;  % Instrument handle
        
        % TTL trigger configuration via auxiliary outputs
        auxCh = 0;        % AUX OUT 1 channel (0-indexed)
        vHigh = 3.3;      % TTL high level (V)
        vLow = 0.0;       % TTL low level (V)  
        dwell_s = 0.005;  % Edge timing (5ms for robust detection)
        
        % Parse control mode
        pertrig = (nargin >= 4) && ~isempty(ctrl) && ...
                  contains(lower(ctrl), 'pertrig');
        
        switch ic(3)  % Operation type
            
            %----------------------------------------------------------
            case 3  % CONFIGURE & ARM: Setup and start acquisition
            %----------------------------------------------------------
                fprintf(inst, '*CLS');  % Clear instrument status
                
                % Configure capture format and buffer size
                fprintf(inst, 'CAPTURECFG 2');      % R,θ format (2 floats/sample)
                fprintf(inst, 'CAPTURELEN 4096');   % Maximum buffer (4096 kB)
                
                if pertrig
                    % Per-trigger mode: One sample per falling edge
                    fprintf(inst, 'CAPTURESTART ONE, SAMPpertrig');
                    sr860_aux_set(inst, auxCh, vHigh);  % Prime trigger high
                else
                    % Continuous mode: Sample at fixed rate
                    if ~isfield(smdata.inst(ic(1)).data, 'sampint') || ...
                       isempty(smdata.inst(ic(1)).data.sampint)
                        % Use default rate if not configured
                        fprintf(inst, 'CAPTURERATE 10');  % Conservative divider
                        smdata.inst(ic(1)).data.sampint = 1/1000;  % ~1 kHz
                    end
                    fprintf(inst, 'CAPTURESTART CONT, IMM');  % Start immediately
                end
                
                % Initialize tracking variables
                smdata.inst(ic(1)).data.currsamp_real = 0;
                smdata.inst(ic(1)).data.currsamp_phase = 0;
                smdata.inst(ic(1)).data.RampPts = 0;
                val = [];  % No return value for configuration
                
            %----------------------------------------------------------
            case 2  % PUSH SAMPLE: Generate one trigger pulse
            %----------------------------------------------------------
                if ~pertrig
                    % Continuous mode: Just wait one sample interval
                    pause(max(0.001, smdata.inst(ic(1)).data.sampint));
                else
                    % Per-trigger mode: Generate falling edge sequence
                    sr860_aux_set(inst, auxCh, vLow);   % Trigger low
                    pause(dwell_s);
                    sr860_aux_set(inst, auxCh, vHigh);  % Return high
                    pause(dwell_s);
                end
                val = [];
                
            %----------------------------------------------------------
            case 6  % START: Begin acquisition (helper function)
            %----------------------------------------------------------
                if pertrig
                    fprintf(inst, 'CAPTURESTART ONE, SAMPpertrig');
                    sr860_aux_set(inst, auxCh, vHigh);  % Prime trigger
                else
                    fprintf(inst, 'CAPTURESTART CONT, IMM');
                end
                val = [];
                
            %----------------------------------------------------------
            case 0  % STOP & READ: Retrieve all available data
            %----------------------------------------------------------
                fprintf(inst, 'CAPTURESTOP');  % Stop data acquisition
                
                % Query available data
                navail_bytes = query(inst, 'CAPTUREBYTES?', '%s\n', '%d');
                
                % Validate data availability
                if isempty(navail_bytes) || isnan(navail_bytes) || navail_bytes < 8
                    val = [];
                    return;
                end
                
                % Calculate number of complete (R,θ) pairs
                npts_to_read = floor(navail_bytes / 8);  % 8 bytes per sample pair
                
                % Read binary data from instrument  
                fprintf(inst, 'CAPTUREGET? 0, %g', ceil(npts_to_read*2/256));
                raw = readbinblock(inst, 'single');
                
                % Parse and organize data
                if numel(raw) >= 2*npts_to_read
                    R_vals = raw(1:2:2*npts_to_read-1);   % R components (magnitude)
                    theta_vals = raw(2:2:2*npts_to_read); % θ components (phase)
                    
                    % Return structured data (row vectors for consistency)
                    val.magnitude = R_vals.';                        % Magnitude
                    val.phase = theta_vals.';                        % Phase  
                    val.x = (R_vals .* cosd(theta_vals)).';         % X = R*cos(θ)
                    val.y = (R_vals .* sind(theta_vals)).';         % Y = R*sin(θ)
                else
                    val = [];  % Insufficient data received
                end
                
                % Update sample counters
                smdata.inst(ic(1)).data.currsamp_real = ...
                    smdata.inst(ic(1)).data.currsamp_real + npts_to_read;
                smdata.inst(ic(1)).data.currsamp_phase = ...
                    smdata.inst(ic(1)).data.currsamp_phase + npts_to_read;
                smdata.inst(ic(1)).data.RampPts = 0;
                
            %----------------------------------------------------------
            case 4  % SET POINTS: Configure planned acquisition length
            %----------------------------------------------------------
                smdata.inst(ic(1)).data.RampPts = smdata.inst(ic(1)).datadim(ic(2));
                val = [];
                
            %----------------------------------------------------------
            case 5  % CONFIGURE RATE: Set points and sample rate
            %----------------------------------------------------------
                % Optimize communication buffer for high-speed transfer
                fclose(inst);
                inst.InputBufferSize = 1e6;  % 1 MB input buffer
                inst.Timeout = 20;           % 20 second timeout
                fopen(inst);
                
                % Store configuration parameters
                smdata.inst(ic(1)).datadim(ic(2)) = val;  % Planned points
                smdata.inst(ic(1)).data.RampPts = val;
                
                % Configure sample rate with hardware constraints
                maxrate = query(inst, 'CAPTURERATEMAX?', '%s\n', '%g');
                if isempty(maxrate) || isnan(maxrate)
                    error('SR860: Failed to query maximum capture rate');
                end
                
                if abs(rate) > maxrate
                    warning('SR860: Requested rate exceeds maximum, using max rate');
                    rate = maxrate;
                end
                
                % Calculate optimal rate divider
                n = ceil(log2(maxrate / abs(rate)));
                n = max(0, min(20, n));  % Clamp to valid range
                actual_rate = maxrate / (2^n);
                
                % Apply rate configuration
                fprintf(inst, 'CAPTURERATE %i', n);
                smdata.inst(ic(1)).data.sampint = 1/actual_rate;
                smdata.inst(ic(1)).data.RampTime = (val - 1) / actual_rate;
                
                % Calculate and set buffer size (must be even kB)
                bytes_needed = 8 * val;  % 8 bytes per (R,θ) sample
                kb = 2 * ceil(bytes_needed / 1024 / 2);  % Round up to even kB
                kb = min(max(kb, 2), 4096);              % Clamp to [2, 4096] kB
                fprintf(inst, 'CAPTURELEN %u', kb);
                
            %----------------------------------------------------------
            otherwise
                error('SR860: Unsupported buffer mode operation (case %d)', ic(3));
        end






    %======================================================================
    % STANDARD CHANNELS: Generic set/get operations
    %======================================================================
    otherwise  % Channels 1-14, 17-25 (excluding handled cases above)
        
        switch ic(3)  % Operation type
            
            %----------------------------------------------------------
            case 1  % SET: Write parameter to instrument
            %----------------------------------------------------------
                % Apply channel-specific value transformations
                if ic(2) == 17
                    val = SR860sensindex(val);      % Sensitivity: value → index
                elseif ic(2) == 18  
                    val = SR860tauindex(val);       % Time constant: value → index
                elseif ic(2) == 24
                    if val ~= 0 && val ~= 1
                            val = 0;  % force invalid values to 0
                    end
                end
                
                % Format command based on channel requirements
                if any(ic(2) == [11 12 13 14])  % Auxiliary output channels
                    fprintf(smdata.inst(ic(1)).data.inst, ...
                           sprintf('%s, %f', cmds{ic(2)}, val));  % Comma format
                else
                    fprintf(smdata.inst(ic(1)).data.inst, ...
                           sprintf('%s %f', cmds{ic(2)}, val));   % Space format
                end
                
            %----------------------------------------------------------
            case 0  % GET: Read parameter from instrument  
            %----------------------------------------------------------
                % Query instrument parameter
                val = query(smdata.inst(ic(1)).data.inst, ...
                           sprintf('%s? %s', cmds{ic(2)}(1:4), cmds{ic(2)}(5:end)), ...
                           '%s\n', '%f');
                
                % Apply channel-specific value transformations
                if ic(2) == 17
                    val = SR860sensvalue(val);      % Sensitivity: index → value
                elseif ic(2) == 18
                    val = SR860tauvalue(val);       % Time constant: index → value
                end
                
            %----------------------------------------------------------
            otherwise
                error('SR860: Unsupported operation for channel %d', ic(2));
        end
end

%==========================================================================
% LOCAL HELPER FUNCTIONS
%==========================================================================

%--------------------------------------------------------------------------
function sr860_aux_set(inst, j, v)
% Robust auxiliary output setter with fallback command support
%
% INPUTS:
%   inst - Instrument communication object
%   j    - Auxiliary channel number (0-3)  
%   v    - Output voltage (-10.5 to +10.5 V)
%--------------------------------------------------------------------------
    v = max(min(v, 10.5), -10.5);  % Clamp voltage to safe range
    
    % Try primary command (AUXV)
    try
        fprintf(inst, sprintf('AUXV %d, %g', j, v));
        return;  % Success
    catch
        % Fallback to alternative command (AUXO)
        fprintf(inst, sprintf('AUXO %d, %g', j, v));
    end
end

%--------------------------------------------------------------------------
function val = SR860sensvalue(sensindex)  
% Convert sensitivity index to actual voltage value
%
% INPUT:  sensindex - Hardware sensitivity index (0-29)
% OUTPUT: val - Sensitivity in volts (full scale)
%--------------------------------------------------------------------------
    base_values = [2e-9, 5e-9, 10e-9];  % Base sensitivity values
    multipliers = 10.^(0:9);              % Decade multipliers
    
    % Generate complete sensitivity table
    sensvals = [];
    for mult = multipliers
        sensvals = [sensvals, base_values * mult];
    end
    
    val = sensvals(sensindex + 1);  % Convert from 0-based to 1-based indexing
end

%--------------------------------------------------------------------------
function sensindex = SR860sensindex(sensval)
% Convert sensitivity value to hardware index
%
% INPUT:  sensval - Desired sensitivity in volts
% OUTPUT: sensindex - Hardware sensitivity index (0-29)
%--------------------------------------------------------------------------
    base_values = [2e-9, 5e-9, 10e-9];
    multipliers = 10.^(0:9);
    
    % Generate complete sensitivity table
    sensvals = [];
    for mult = multipliers
        sensvals = [sensvals, base_values * mult];
    end
    
    % Find first sensitivity >= requested value
    sensindex = find(sensvals >= sensval, 1) - 1;  % Convert to 0-based indexing
end

%--------------------------------------------------------------------------
function val = SR860tauvalue(tauindex)
% Convert time constant index to actual time value  
%
% INPUT:  tauindex - Hardware time constant index (0-19)
% OUTPUT: val - Time constant in seconds
%--------------------------------------------------------------------------
    base_values = [10e-6, 30e-6];        % Base time constants
    multipliers = 10.^(0:9);              % Decade multipliers
    
    % Generate complete time constant table
    tauvals = [];
    for mult = multipliers
        tauvals = [tauvals, base_values * mult];
    end
    
    val = tauvals(tauindex + 1);  % Convert from 0-based to 1-based indexing
end

%--------------------------------------------------------------------------
function tauindex = SR860tauindex(tauval)
% Convert time constant value to hardware index
%
% INPUT:  tauval - Desired time constant in seconds  
% OUTPUT: tauindex - Hardware time constant index (0-19)
%--------------------------------------------------------------------------
    base_values = [10e-6, 30e-6];
    multipliers = 10.^(0:9);
    
    % Generate complete time constant table
    tauvals = [];
    for mult = multipliers
        tauvals = [tauvals, base_values * mult];
    end
    
    % Find first time constant >= requested value
    tauindex = find(tauvals >= tauval, 1) - 1;  % Convert to 0-based indexin
end

%==========================================================================
% END OF FILE
%==========================================================================
end