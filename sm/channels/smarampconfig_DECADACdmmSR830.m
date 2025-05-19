function scan = smarampconfig_DECADACdmmSR830(scan, cntrl, ovsmpl)
%takes in a scan and configures buffered acquisition.  The scan should have
%a setchannel in loop 1 that can be ramped (should be a DecaDAC channel).
%The getchannels in loop 2 should be vector inputs on SR830s and 1 dmm.
%The dmm will provide a hardware trigger to the SR830s.
%cntrl: sync: SR830  triggered samplewise
%       trig: SR830 external trigger enabled
%ovsmpl: oversampling factor

global smdata;
ic = smchaninst(scan.loops(2).getchan);

if nargin < 2 
    cntrl = '';
end

for i=1:length(scan.disp)
    if scan.disp(i).loop>2
        scan.disp(i).loop=2;
    end
end

lockins=[];
dmms=[];
for i=1:size(ic,1)
    ind=ic(i,1);
    % Look through current instruments
    switch smdata.inst(ind).device
        case 'SR830'
            lockins=[lockins ind];
            fclose(smdata.inst(ind).data.inst);
            set(smdata.inst(ind).data.inst,'InputBufferSize',2^13);
            set(smdata.inst(ind).data.inst,'OutputBufferSize',2^13);
            fopen(smdata.inst(ind).data.inst);

        case 'HP34401A'
            dmms=[dmms ind];
            fclose(smdata.inst(ind).data.inst);
            set(smdata.inst(ind).data.inst,'InputBufferSize',2^13);
            set(smdata.inst(ind).data.inst,'OutputBufferSize',2^13);
            fopen(smdata.inst(ind).data.inst);
            fprintf(smdata.inst(ind).data.inst,'VOLT:NPLC 1'); % set DMM to average 1 power line cycle
    end
end

if nargin >=3 && ovsmpl ~= 1
    lenrate = smabufconfig(ic(:, 1)', scan.loops(1).npoints*ovsmpl, ...
        ovsmpl/abs(scan.loops(1).ramptime), cntrl);
    scan.loops(1).npoints = ceil(lenrate(1)/ovsmpl);
    scan.loops(1).ramptime = -ovsmpl/lenrate(2); 
    pf.dim = scan.loops(1).npoints;
    pf.fn.fn = @decimate;
    pf.fn.args = {ovsmpl};
    scan.loops(2).procfn(1:length(scan.loops(2).getchan)) = pf;
else
    lenrate = smabufconfig(ic(:, 1)', scan.loops(1).npoints, 1/abs(scan.loops(1).ramptime), cntrl);
    scan.loops(1).npoints = lenrate(1);
    scan.loops(1).ramptime = -1/lenrate(2);
    if isfield(scan.loops, 'procfn')
        scan.loops = rmfield(scan.loops, 'procfn');
    end
end


scan.loops(1).trigfn=[];
scan.loops(1).trigfn.fn = @smatrigDecaDACSR830dmm;
scan.loops(1).trigfn.args = {smchaninst(smchanlookup(scan.loops(1).setchan)),...
    lockins,dmms,1};

