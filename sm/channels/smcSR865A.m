function [val, rate] = smcSR865A(ic, val, rate, ctrl)
% [val, rate] = smcSR865A(ic, val, rate, ctrl)
% ctrl: sync (each sample triggered)
%       trig external trigger starts acq.
% 0: X, 1: Y, 2: R, 3: Theta, 4-7: AUX In1-4, 8: Xnoise, 9: Ynoise
% 10-11: AUX output 1-2, 12: Reference Phase, 13: Sine Out Amplitude
% 14: DC Level, 15: Int. Ref. Frequency, 16: Ext. Ref. Frequency



global smdata;

cmds = {'OUTP 0', 'OUTP 1', 'OUTP 2', 'OUTP 3', 'FREQ', 'SLVL', ...
    'OAUX 0', 'OAUX 1', 'OAUX 2', 'OAUX 3', 'AUXV 0', 'AUXV 1', 'AUXV 2', 'AUXV 3' ...
    ,'','','SCAL', 'OFLT', 'SYNC','SOFF'};

switch ic(2) % Channel
    case 21 %Auto phase Range and sensitivity
        fprintf(smdata.inst(ic(1)).data.inst,'APHS');
        fprintf(smdata.inst(ic(1)).data.inst,'ARNG');
        fprintf(smdata.inst(ic(1)).data.inst,'ASCL');
        val = 1;
    case {15, 16} % stored data, length determined by datadim
        switch ic(3)
            case 0  % get              
                npts = smdata.inst(ic(1)).datadim(ic(2), 1);
                while 1
                    navail = query(smdata.inst(ic(1)).data.inst, 'SPTS?', '%s\n', '%d');
                    if navail >= npts + smdata.inst(ic(1)).data.currsamp
                        break;
                    else
                        pause(0.8 * (npts + smdata.inst(ic(1)).data.currsamp - navail) ...
                            * smdata.inst(ic(1)).data.sampint);
                    end
                end
                
                fprintf(smdata.inst(ic(1)).data.inst, 'TRCB? %d, %d, %d', ...
                    [ic(2)-14, smdata.inst(ic(1)).data.currsamp+[0, npts]]);
                val = fread(smdata.inst(ic(1)).data.inst, npts, 'single');
                smdata.inst(ic(1)).data.currsamp =  smdata.inst(ic(1)).data.currsamp + npts;
                
            case 3
                fprintf(smdata.inst(ic(1)).data.inst, 'STRT');

            case 4
                fprintf(smdata.inst(ic(1)).data.inst, 'REST');
                smdata.inst(ic(1)).data.currsamp = 0;
                pause(.1); %needed to give instrument time before next trigger.
                % anything much shorter leads to delays.
                
            case 5
                if nargin > 4 && strfind(ctrl, 'sync')
                    n = 14;
                else
                    n = round(log2(rate)) + 4;
                    rate = 2^-(4-n);
                    % allow ext trig?
                    if n < 0 || n > 13
                        error('Samplerate not supported by SR865A');
                    end
                end
                %if strfind(ctrl, 'trig')
                fprintf(smdata.inst(ic(1)).data.inst, 'REST; SEND 1; TSTR 1; SRAT %i', n);
                %else
                %    fprintf(smdata.inst(ic(1)).data.inst, 'REST; SEND 1; TSTR 0; SRAT %i', n);
                %end
                pause(.1);
                smdata.inst(ic(1)).data.currsamp = 0;

                smdata.inst(ic(1)).data.sampint = 1/rate;
                smdata.inst(ic(1)).datadim(15:16, 1) = val;

            otherwise
                error('Operation not supported');
                
        end
        
    otherwise
        switch ic(3) % action
            case 1 % set
                if ic(2)==17
                    val = SR865Asensindex(val);
                elseif ic(2)==18
                    val = SR865Atauindex(val);
                end
                % for Aux outputs have to put a comma
                if any(ic(2)==[11 12 13 14])
                    fprintf(smdata.inst(ic(1)).data.inst, sprintf('%s, %f', cmds{ic(2)}, val));
                else
                    fprintf(smdata.inst(ic(1)).data.inst, sprintf('%s %f', cmds{ic(2)}, val));
                end
            case 0 % get
                val = query(smdata.inst(ic(1)).data.inst, sprintf('%s? %s',...
                    cmds{ic(2)}(1:4), cmds{ic(2)}(5:end)), '%s\n', '%f');
                if ic(2)==17
                    val = SR865Asensvalue(val);
                elseif ic(2)==18
                    val = SR865Atauvalue(val);
                end

            otherwise
                error('Operation not supported');
        end
end

function val = SR865Asensvalue(sensindex)
% converts an index to the corresponding sensitivity value for the SR865A
% lockin.
x = [2e-9 5e-9 10e-9];
sensvals = [x 1e1*x 1e2*x 1e3*x 1e4*x 1e5*x 1e6*x 1e7*x 1e8*x 1e9*x];
val = sensvals(sensindex+1);

function sensindex = SR865Asensindex(sensval)
% converts a sensitivity to a corresponding index that can be sent to the
% SR865A lockin.  rounds up (sens = 240 will become 500)
x = [2e-9 5e-9 10e-9];
sensvals = [x 1e1*x 1e2*x 1e3*x 1e4*x 1e5*x 1e6*x 1e7*x 1e8*x 1e9*x];
sensindex = find(sensvals >= sensval,1)-1;

function val = SR865Atauvalue(tauindex)
% converts an index to the corresponding sensitivity value for the SR865A
% lockin.
x = [10e-6 30e-6];
tauvals = [x 1e1*x 1e2*x 1e3*x 1e4*x 1e5*x 1e6*x 1e7*x 1e8*x 1e9*x];
val = tauvals(tauindex+1);

function tauindex = SR865Atauindex(tauval)
% converts a time constant to a corresponding index that can be sent to the
% SR865A lockin.  rounds up (tau = 240 will become 300)
x = [10e-6 30e-6];
tauvals = [x 1e1*x 1e2*x 1e3*x 1e4*x 1e5*x 1e6*x 1e7*x 1e8*x 1e9*x];
tauindex = find(tauvals >= tauval,1)-1;
        
