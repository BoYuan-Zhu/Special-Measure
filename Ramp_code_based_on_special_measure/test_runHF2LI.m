clear; clc;

% ---- Connect to LabOne Data Server (you already have a tcpclient) ----
global smdata
ind = smloadinst('HF2LI', [], 'tcpclient', '127.0.0.1:8005');
t   = smdata.inst(ind).data.inst;
configureTerminator(t, "LF");
t.Timeout = 5;
pause(0.1);

ziAddPath;                                      % add LabOne MATLAB API to path
ziDAQ('connect', t.Address, t.Port);            % connect to Data Server

devs = ziDevices();  assert(~isempty(devs));
dev  = upper(char(devs{1}));                    % e.g. 'DEV1401'
clk  = ziDAQ('getDouble', ['/' dev '/clockbase']);
fprintf('连接成功：%s  clockbase = %.0f Hz\n', dev, clk);

%% ---- Configure HF2 scope device nodes (instrument nodes) ----
base = ['/' dev '/scopes/0'];

% 1) disable while configuring
ziDAQ('setInt', [base '/enable'], 0);

% 2) basic scope settings (HF2 uses /scopes/0/channel, /time, /trigchannel)
ziDAQ('setInt', [base '/channel'], 0);          % 0: SigIn1, 1: SigIn2, 2: SigOut1, 3: SigOut2
ziDAQ('setInt', [base '/time'], 10);            % decimation: fs = 210e6 / 2^time
ziDAQ('setInt', [base '/trigchannel'], -2);     % -2 = continuous (no trigger)

% Optional: set a moderate record length (supported across instruments)
% If your HF2 firmware exposes /length, set it; otherwise you can comment it.
try
    ziDAQ('setInt', [base '/length'], 4096);    % 4096 samples per record (if available)
catch
    % If node doesn't exist on your HF2 build, it's fine; Scope Module still works.
end

% Make sure device-side changes are processed before starting module.
ziDAQ('sync');

% ---- Scope Module configuration (module parameters) ----
h = ziDAQ('scopeModule');

% Subscribe picks the device & scope
ziDAQ('subscribe', h, [base '/wave']);

% Return FFT; enable PSD; enable averaging per the manual
ziDAQ('set', h, 'mode', int64(3));                    % 3 = FFT mode
ziDAQ('set', h, 'fft/spectraldensity', int64(1));     % PSD on
ziDAQ('set', h, 'averager/enable', int64(1));
ziDAQ('set', h, 'averager/method', int64(1));         % 1 = uniform average
N = 100;                                               % keep N records in history
ziDAQ('set', h, 'historylength', int64(N));





% 设置 Input 1 的量程为 1 mV
ziDAQ('setDouble', ['/' dev '/sigins/0/range'], 0.001);
 
% （可选）确认是否设置成功
val = ziDAQ('getDouble', ['/' dev '/sigins/0/range']);
fprintf('Input 1 range = %.6f V\n', val);

% 设置 Input 1 的输入阻抗为 50 ohm
ziDAQ('setInt', ['/' dev '/sigins/0/imp50'], 1);

% （可选）读取确认
val = ziDAQ('getInt', ['/' dev '/sigins/0/imp50']);
if val == 1
    disp('Input 1 impedance set to 50 Ω');
else
    disp('Input 1 impedance set to High-Z');
end




% HF2-only: externalscaling must match the RANGE of the chosen scope source
ch = ziDAQ('getInt', [base '/channel']);           % 0..3 (SigIn1, SigIn2, SigOut1, SigOut2)
ranges = [ ...
    ziDAQ('getDouble', ['/' dev '/sigins/0/range']), ...
    ziDAQ('getDouble', ['/' dev '/sigins/1/range']), ...
    ziDAQ('getDouble', ['/' dev '/sigouts/0/range']), ...
    ziDAQ('getDouble', ['/' dev '/sigouts/1/range']) ...
];
ziDAQ('set', h, 'externalscaling', ranges(ch+1));  % per manual for HF2

% ---- Acquire ----
ziDAQ('execute', h);                                  % start module processing
ziDAQ('setInt', [base '/enable'], 1);                 % then start the HF2 scope

% Wait for the module to process at least N records.
% (Either poll 'records' or use 'progress'; both are per manual.)
tic;
timeout_s = 5;                                        % extend if your rate/length is long
while true
    recs = ziDAQ('getInt', h, 'records');             % processed records since execute()
    if recs >= N, break; end
    if toc > timeout_s, break; end
    pause(0.05);
end

% ---- Read & stop (unchanged) ----
d = ziDAQ('read', h);
ziDAQ('finish', h);
ziDAQ('clear', h);
ziDAQ('setInt', [base '/enable'], 0);

% ---- Find the device field case-insensitively ----
fn = fieldnames(d);
match = '';
for k = 1:numel(fn)
    if strcmpi(fn{k}, dev)
        match = fn{k};
        break;
    end
end
assert(~isempty(match), 'Device field not found in returned data. Fields: %s', strjoin(fn, ', '));

% ---- Get the first scope container (struct OR cell) ----
scopes_node = d.(match).scopes;
if iscell(scopes_node)
    scopes1 = scopes_node{1};
else
    scopes1 = scopes_node(1);
end

% ---- Get the records array (struct array OR cell array) ----
waves = scopes1.wave;
if iscell(waves)
    rec = waves{end};   % use {} for cell
else
    rec = waves(end);   % () is fine for struct array
end

% ---- Pick the spectrum vector from the record ----
if isstruct(rec)
    if isfield(rec, 'spectrum') && ~isempty(rec.spectrum)
        S = double(rec.spectrum(:));
    elseif isfield(rec, 'wave') && ~isempty(rec.wave)
        S = double(rec.wave(:));
    elseif isfield(rec, 'value') && ~isempty(rec.value)
        S = double(rec.value(:));
    else
        error('Unknown record fields. Available: %s', strjoin(fieldnames(rec), ', '));
    end
else
    error('Record is type %s (expected struct). Use {} when indexing cells.', class(rec));
end

% ---- Frequency axis: prefer record-provided x, otherwise compute ----
if isfield(rec, 'x') && ~isempty(rec.x)
    f = double(rec.x(:));
else
    scope_time = ziDAQ('getInt', [base '/time']);
    fs   = double(clk) / (2^double(scope_time));
    f    = linspace(0, fs/2, numel(S)).';
end

% ---- Axis labels if present ----
xlab = 'Frequency (Hz)';
ylab = 'Amplitude';
if isfield(rec,'xunit') && ~isempty(rec.xunit), xlab = char(rec.xunit); end
if isfield(rec,'yunit') && ~isempty(rec.yunit), ylab = char(rec.yunit); end

% ---- Plot ----
figure('Color','w');
semilogx(f, S, 'LineWidth', 1.2); grid on;
xlabel(xlab);
ylabel(ylab);    % for PSD you should already have V/sqrt(Hz)
title(sprintf('%s Scope FFT (records=%d)', match, numel(waves)));
