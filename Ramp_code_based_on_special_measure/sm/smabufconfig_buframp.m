function scan = smabufconfig_buframp(scan, ctrl, getrng, setrng, loop)
% scan = smabufconfig2(scan, cntrl, getrng, setrng, loop)
% Configure buffered acquisition for fastest loop using drivers. 
% Supersedes smarampconfig/smabufconfig if driver provides this
% functionality.
%
% cntrl: trig : use smatrigfn for triggering
%         arm : use smatrigfn to arm insts in loops(2).prefn(1)
%         fast: change behavior to not use rate and time of first loop.
%               Instead, setrng = [npts, rate, nrec(optional)], loop = loop to be used (default = 1)     
% getrng: indices to loops(2).getchan to be programmed (and armed/triggered).
%   
% Possible extensions (not implemented): 
% - configure decimation (see smarampconfig for code)

global smdata;


if nargin < 2 
    ctrl = '';
end
if strfind(ctrl, 'fast') %#ok<*STRIFCND> % Set which loop is used for readout
    if ~exist('loop','var') || isempty(loop)
        loop = 1;
    end
else
    if ~exist('loop','var') || isempty(loop)
        loop = 2;
    end
    if loop == 1
        error('Need to use fast control if you want readout in first loop')
    end
    setic = smchaninst(scan.loops(loop-1).setchan);
    if exist('config','var') && ~isempty(config)
        setic = setic(config, :);
    end
end


getic = smchaninst(scan.loops(loop).getchan);
readic = smchaninst(scan.loops(loop).readchan);

if nargin >= 3 && getrng ~= 0 
   getic = getic(getrng, :);
end

if strfind(ctrl, 'fast')
    for i = 1:size(getic, 1)
        args = num2cell(setrng);
        [setrng(1), setrng(2)] = smdata.inst(getic(i, 1)).cntrlfn([getic(i, :), 5], args{:});
        %[setrng(1), setrng(2)] = smdata.inst(getic(i, 1)).cntrlfn([getic(i, :), 5], setrng(1), setrng(2));
    end
else
    for i = 1:size(getic, 1)
        [scan.loops(1).npoints, rate] = smdata.inst(getic(i, 1)).cntrlfn([getic(i, :), 5], scan.loops(1).npoints, ...
            1/abs(scan.loops(1).ramptime));
        scan.loops(1).ramptime = sign(scan.loops(1).ramptime)/abs(rate);
    end
    
    if strfind(ctrl, 'trig')
        scan.loops(loop-1).trigfn.fn = @smatrigfn;
        scan.loops(loop-1).trigfn.args = {[readic; getic]};
    end
end

if strfind(ctrl, 'arm')
    scan.loops(loop).prefn(1).fn = @smatrigfn;
    scan.loops(loop).prefn(1).args = {getic, 4};
end
