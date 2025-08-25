function [val, rate] = smcSR830_spm(ic, val, rate, ctrl)
% [val, rate] = smcSR830(ic, val, rate, ctrl)
% ctrl: sync (each sample triggered)
%       trig external trigger starts acq.
% 1: X, 2: Y, 3: R, 4: Theta, 5: freq, 6: ref amplitude
% 7:10: AUX input 1-4, 11:14: Aux output 1:4
% 15,16: stored data, length determined by datadim
% 17: sensitivity 
% 18: overload 

global smdata;
        
cmds = {'OUTP 1', 'OUTP 2', 'OUTP 3', 'OUTP 4', 'FREQ', 'SLVL', 'OAUX 1', 'OAUX 2',...
'OAUX 3','OAUX 4', 'AUXV 1', 'AUXV 2', 'AUXV 3', 'AUXV 4','','','SENS', 'OFLT', 'SYNC'};

switch ic(2) % Channel
    case {15, 16} % Stored data, length determined by datadim
        inst = smdata.inst(ic(1)).data.inst;
        switch ic(3)
            case 0  % get              
                npts = smdata.inst(ic(1)).datadim(ic(2), 1);
                while 1
                    % Query the number of points stored in Display buffer
                    navail = query(smdata.inst(ic(1)).data.inst, 'SPTS?', '%s\n', '%d');
                    if navail >= npts + smdata.inst(ic(1)).data.currsamp
                        break;
                    else
                        pause(0.8 * (npts + smdata.inst(ic(1)).data.currsamp - navail) ...
                            * smdata.inst(ic(1)).data.sampint);
                    end
                end                
%                 fprintf(smdata.inst(ic(1)).data.inst, 'TRCB? %d, %d, %d', ...
%                     [ic(2)-14, smdata.inst(ic(1)).data.currsamp+[0, npts]]);
                fprintf(smdata.inst(ic(1)).data.inst, 'TRCL? %d, %d, %d', ...
                    [ic(2)-14, smdata.inst(ic(1)).data.currsamp+[0, npts]]);
                pause(0.1);
%                 val = fread(smdata.inst(ic(1)).data.inst, npts, 'single');
                % TRCL returns 32 bit integer.
                % First byte is zero. Second byte is exponent. Final two
                % bytes are mantissa
                % Formula to recover numerical value is:
                % value = mantissa*2^(exp-124).
                % SR830 gives the mantissa in 16 bit twos complement
                output_int = fread(smdata.inst(ic(1)).data.inst, npts, 'uint32');
                output = dec2bin(output_int,32);
                % Calculate the mantissa with two's complement
                val = twoscomp16(output(:,17:32)).*2.^(bin2dec(output(:,1:16))-124);
                pause(0.1);
%                 smdata.inst(ic(1)).data.currsamp =  smdata.inst(ic(1)).data.currsamp + npts;         
            case 2
                fprintf(smdata.inst(ic(1)).data.inst, 'TRIG');
            case 3
                fclose(inst);                 % 
                inst.InputBufferSize = 1e6;   % Buffersize 1 MB
                inst.Timeout = 20;            % 
                fopen(inst);                  % 
               fprintf(smdata.inst(ic(1)).data.inst, 'REST');
            case 4
                if ~strcmp(smdata.inst(ic(1)).data.state,'armed')
                    fprintf(smdata.inst(ic(1)).data.inst, 'REST');
                    smdata.inst(ic(1)).data.currsamp = 0;
                    smdata.inst(ic(1)).data.state = 'armed';
                    pause(.1); %needed to give instrument time before next trigger, anything much shorter leads to delays.                
                end
            case 5
%                 if exist('ctrl','var') && strfind(ctrl, 'sync')
                    n = 14;
%                 else
%                     % n = round(log2(rate)) + 4;
%                     n = floor(log2(rate)) + 4;
%                     rate = 2^-(4-n);
%                     if n < 0 || n > 13
%                         error('Samplerate not supported by SR830');
%                     end
%                 end
                % REST: reset the data buffers.This will erase the data
                % buffer.
                % SEND: sets the end of buffer mode. 0 is 1 shot and 1 is
                % loop.
                % TSTR: sets the trigger start mode. 1 is trigger stats the
                % scan and 0 turns the trigger start feature off.
                % SRAT: sets the data sample rate. 0 for 62.5 mHz, 1 for
                % 125 mHz, 2 for 250 mHz, 3 for 500 mHz, 4 for 1 Hz, 5 for
                % 2 Hz, 6 for 4 Hz, 7 for 8 Hz, 8 for 16 Hz, 9 for 32 Hz,
                % 10 for 64 Hz, 11 for 128 Hz, 12 for 256 Hz, 13 for 512
                % Hz, and 14 for Trigger.
                fprintf(smdata.inst(ic(1)).data.inst, 'REST; SEND 0; TSTR 1; SRAT %i', n);
                pause(.1);
                smdata.inst(ic(1)).data.currsamp = 0;
                smdata.inst(ic(1)).data.sampint = 1/rate;
                smdata.inst(ic(1)).datadim(15:16, 1) = val;
                smdata.inst(ic(1)).data.state = 'reset';
            otherwise
                error('Operation not supported');                
        end
    otherwise
        switch ic(3) % action
            case 1 % set
                if ic(2)==17
                    val = SR830sensindex(val);
                elseif ic(2)==18
                    val = SR830tauindex(val);
                end
                fprintf(smdata.inst(ic(1)).data.inst, sprintf('%s %f', cmds{ic(2)}, val));
            case 0 % get
                val = query(smdata.inst(ic(1)).data.inst, sprintf('%s? %s',cmds{ic(2)}(1:4), cmds{ic(2)}(5:end)), '%s\n', '%f');
                if ic(2)==17
                    val = SR830sensvalue(val);
                elseif ic(2)==18
                    val = SR830tauvalue(val);
                end
            otherwise
                error('Operation not supported');
        end
end

function val = SR830sensvalue(sensindex)
% converts an index to the corresponding sensitivity value for the SR830 lockin.
x = [2e-9 5e-9 10e-9];
sensvals = [x 1e1*x 1e2*x 1e3*x 1e4*x 1e5*x 1e6*x 1e7*x 1e8*x 1e9*x];
val = sensvals(sensindex+1);

function sensindex = SR830sensindex(sensval)
% converts a sensitivity to a corresponding index that can be sent to the
% SR830 lockin.  rounds up (sens = 240 will become 500)
x = [2e-9 5e-9 10e-9];
sensvals = [x 1e1*x 1e2*x 1e3*x 1e4*x 1e5*x 1e6*x 1e7*x 1e8*x 1e9*x];
sensindex = find(sensvals >= sensval,1)-1;

function val = SR830tauvalue(tauindex)
% converts an index to the corresponding sensitivity value for the SR830 lockin.
x = [10e-6 30e-6];
tauvals = [x 1e1*x 1e2*x 1e3*x 1e4*x 1e5*x 1e6*x 1e7*x 1e8*x 1e9*x];
val = tauvals(tauindex+1);

function tauindex = SR830tauindex(tauval)
% converts a time constant to a corresponding index that can be sent to the
% SR830 lockin.  rounds up (tau = 240 will become 300)
x = [10e-6 30e-6];
tauvals = [x 1e1*x 1e2*x 1e3*x 1e4*x 1e5*x 1e6*x 1e7*x 1e8*x 1e9*x];
tauindex = find(tauvals >= tauval,1)-1;

function output = twoscomp16(input16)
% Convert 16-bit two's-complement binary (as chars) to signed numbers.
% INPUT:
%   input16 : N×16 char array, each row is a 16-bit '0'/'1' string
% OUTPUT:
%   output  : N×1 double in the range [-32768, 32767]
%
% Rationale:
%   SR830 TRCL returns mantissa as 16-bit two's-complement. We:
%     1) convert each 16-bit row to uint16 (bin2dec),
%     2) reinterpret bits as int16 (typecast),
%     3) return as double.

    % Accept numeric/logical 0/1 as well, convert to char '0'/'1'
    if ~ischar(input16)
        if (isnumeric(input16) || islogical(input16)) && size(input16,2) == 16
            input16 = char('0' + (input16 ~= 0));  % N×16 char array
        else
            error('twoscomp16: expect N×16 char array or numeric/logical 0/1 matrix.');
        end
    end

    % Validate shape
    if size(input16,2) ~= 16
        error('twoscomp16: input must be N×16 bits.');
    end

    % Row-wise convert to unsigned, then reinterpret as signed
    u = uint16(bin2dec(input16));       % N×1, 0..65535
    output = double(typecast(u, 'int16'));  % N×1, -32768..32767