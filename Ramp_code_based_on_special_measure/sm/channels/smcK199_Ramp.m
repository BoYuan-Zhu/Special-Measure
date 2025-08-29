function [val, rate] = smcK199_Ramp(ic, val, rate)
% smcK199_Ramp  -- Driver for Keithley Model 199 (lightweight)
% Interface style matches sm framework used in your project:
%   ic(1) : instrument index into smdata.inst
%   ic(2) : logical channel index (1=V, 2=I, 3=Vcompl, 4=Icompl, others optional)
%   ic(3) : operation code (0 = read, 1 = write, other codes supported below)
%
% Supported logical channels (default mapping):
%   1 - 'V'        -- measured voltage (DC)
%   2 - 'I'        -- measured current (DC)
%   3 - 'Vcompl'   -- voltage compliance / protection 
%   4 - 'Icompl'   -- current compliance / protection 
% Notes:
% - smdata.inst(ic(1)).data.inst should be a valid VISA/GPIB object already open.
% - This driver tries standard SCPI queries first, then falls back to GET/BOX style
%   reads that older Model199 variants require. Adjust to your actual firmware if needed.
% - For buffered reading (data-store, B2X, etc.) a separate handler is recommended.
 
global smdata;
 
% Basic validation / fetch instrument object
if ~isfield(smdata, 'inst') || numel(smdata.inst) < ic(1) ...
        || ~isfield(smdata.inst(ic(1)).data, 'inst')
    error('smcK199_Ramp: instrument handle not found in smdata.inst(%d).data.inst', ic(1));
end
inst = smdata.inst(ic(1)).data.inst;   % the VISA / GPIB object
 
% default return
% Keep rate untouched (caller may use it)
if nargin < 3
    rate = [];
end
 
switch ic(2)
    case 1  % Voltage 'V'
        switch ic(3)
            case 0  % read measured voltage
                % Try standard SCPI DC volt measurement
                try
                    txt = query(inst, ':MEASure:VOLTage:DC?');
                    
                    numstr = regexp(txt, '[-+]?\d+(\.\d+)?([eE][-+]?\d+)?', 'match');
                    if ~isempty(numstr)
                        val = str2double(numstr{1});
                    else
                        val = NaN;
                    end
                    
                    if isnan(val)
                        % fallback to GET style
                        error('NaN from SCPI read; fallback');
                    end
                catch
                    % Fallback: older 199 style BOX/GET read
                    try
                        fprintf(inst, 'BOX');   % set box/read mode (harmless if unsupported)
                        fprintf(inst, 'GET');   % trigger a single conversion
                        raw = fgetl(inst);      % read returned line
                        valNum = sscanf(raw, '%g');
                        if isempty(valNum)
                            val = NaN;
                        else
                            val = valNum(1);
                        end
                    catch ME
                        warning('smcK199_Ramp (V read) fallback failed: %s', ME.message);
                        val = NaN;
                    end
                end
            case 1  % write (set some front-panel/register? Model199 is typically DMM only)
                % Model 199 is a DMM (no source). If user attempts write, raise error.
                error('smcK199_Ramp: Model199 does not support writing voltage (it is a DMM).');
            case {2,3,4,5}
                val = [];
                return
            otherwise
                error('smcK199_Ramp: Operation not supported for channel V.');
        end
 
    case 2  % Current 'I'
        switch ic(3)
            case 0  % read measured current (DC)
                try
                    txt = query(inst, ':MEASure:CURRent:DC?');
                    
                    numstr = regexp(txt, '[-+]?\d+(\.\d+)?([eE][-+]?\d+)?', 'match');
                    if ~isempty(numstr)
                        val = str2double(numstr{1});
                    else
                        val = NaN;
                    end
                    if isnan(val)
                        error('NaN from SCPI read; fallback');
                    end
                catch
                    % Fallback to GET style
                    try
                        fprintf(inst, 'BOX');
                        fprintf(inst, 'GET');
                        raw = fgetl(inst);
                        valNum = sscanf(raw, '%g');
                        if isempty(valNum)
                            val = NaN;
                        else
                            val = valNum(1);
                        end
                    catch ME
                        warning('smcK199_Ramp (I read) fallback failed: %s', ME.message);
                        val = NaN;
                    end
                end
            case 1  % write (not supported)
                error('smcK199_Ramp: Model199 does not support writing current (it is a DMM).');
            otherwise
                error('smcK199_Ramp: Operation not supported for channel I.');
        end
 
    case 3  % Voltage compliance (Vcompl) - read/write protection if supported
        switch ic(3)
            case 0  % read compliance voltage (protection)
                % Try SCPI style protection query
                try
                    txt = query(inst, ':SENSe:VOLTage:PROTection?');
                    val = str2double(strtrim(txt));
                catch
                    % If unsupported, return NaN but don't error
                    warning('smcK199_Ramp: V compliance query failed (command may not be supported on K199).');
                    val = NaN;
                end
            case 1  % write compliance voltage (set protection)
                try
                    cmd = sprintf(':SENSe:VOLTage:PROTection %g', val);
                    fprintf(inst, cmd);
                catch ME
                    error('smcK199_Ramp: failed to set V protection: %s', ME.message);
                end
            otherwise
                error('smcK199_Ramp: Operation not supported for Vcompl.');
        end
 
    case 4  % Current compliance (Icompl) - read/write protection
        switch ic(3)
            case 0
                try
                    txt = query(inst, ':SENSe:CURRent:PROTection?');
                    val = str2double(strtrim(txt));
                catch
                    warning('smcK199_Ramp: I compliance query failed (command may not be supported on K199).');
                    val = NaN;
                end
            case 1
                try
                    cmd = sprintf(':SENSe:CURRent:PROTection %g', val);
                    fprintf(inst, cmd);
                catch ME
                    error('smcK199_Ramp: failed to set I protection: %s', ME.message);
                end
            otherwise
                error('smcK199_Ramp: Operation not supported for Icompl.');
        end
 
    otherwise
        error('smcK199_Ramp: Unknown logical channel index %d', ic(2));
end
 



end