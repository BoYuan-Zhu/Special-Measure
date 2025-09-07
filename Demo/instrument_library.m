%% Instrument Library

%% Add Quantum Design Dynacool (PPMS)
if isfield(CFG,'PPMS') && isfield(CFG.PPMS,'enable') && ~isempty(CFG.PPMS.enable) && CFG.PPMS.enable
    try
        PPMS_Initial
        ind = smloadinst('PPMS', [], 'None');
        smdata.inst(ind).name = 'PPMS';
        smaddchannel('PPMS','Temp','T',[1.6,300,Inf,1]); 
        smaddchannel('PPMS','TRate','TRate',[0,100,Inf,1]); 
        smaddchannel('PPMS','Field','B',[-9,9,Inf,1E4]); 
        smaddchannel('PPMS','BRate','BRate',[0,0.5,Inf,1E4]);
    catch err
        fprintf(['*ERROR* problem with connecting to Quantum Design Dynacool\n' err.identifier ': ' err.message '\n'])
    end
end

%% Add OI_Triton_Elsa_Control (TCP)
if isfield(CFG,'OITriton') && isfield(CFG.OITriton,'tcp') && ~isempty(CFG.OITriton.tcp)
    try
        % ind = smloadinst('OITriton', [], 'ni',CFG.tcp.OITriton); not supported by NI-VISA
        ind = smloadinst('OITriton', [], 'tcpclient', CFG.OITriton.tcp);

        smdata.inst(ind).name = 'ELSA';
        smopen(ind);
        smaddchannel('ELSA','Magnet','Magnet',[0,500,Inf,1]);
        smaddchannel('ELSA','RampRate','Tramp',[0,10,Inf,1]); 
        smaddchannel('ELSA','SetPnt','Tset',[0,500,Inf,1]); 
        smaddchannel('ELSA','T','T',[0,500,Inf,1]); 

        smaddchannel('ELSA','Range','HRange',[0,10000,Inf,1]);
        smaddchannel('ELSA','MStilHTR','HStill',[0,100000,Inf,1]);
        smaddchannel('ELSA','Turbo1','Turbo1',[0,1,Inf,1]);
    catch err
        fprintf(['*ERROR* problem with connecting to OITriton\n' err.identifier ': ' err.message '\n'])
    end
end

%% Add IPS_Mercury Magnet Control (serial)
if isfield(CFG,'IPS_Mercury') && isfield(CFG.IPS_Mercury,'serial') && ~isempty(CFG.IPS_Mercury.serial)
    try
        ind = smloadinst('IPSM', [], 'serial', CFG.IPS_Mercury.serial);
        smopen(ind);
        smdata.inst(ind).name = 'IPSM';
        smaddchannel('IPSM','B','B',[-5,5,Inf,1]); 
        smaddchannel('IPSM','Persistent','Persistent',[0,1,Inf,1]);
        smaddchannel('IPSM','RampRate','BRate',[0,0.15,Inf,1]);
    catch err
        fprintf(['*ERROR* problem with connecting to OITriton\n' err.identifier ': ' err.message '\n'])
    end
end

%% Add iPS Magnet LabVIEW Control
if isfield(CFG,'IPSM_LV') && isfield(CFG.IPSM_LV,'enable') && ~isempty(CFG.IPSM_LV.enable) && CFG.IPSM_LV.enable
    try
        global viSETB;
        global viGETB;
        mag = actxserver('LabVIEW.Application');
        

        baseDir = strtrim(userpath); % remove trailing semicolon if exists
        viSETBpath = fullfile(baseDir, 'sm\channels\vi\Triton_Elsa_Signaling.vi');
        viSETB = invoke(mag, 'GetVIReference', viSETBpath);
        % Add SetB reference
        viSETBpath = fullfile(baseDir, 'sm\channels\vi\OI_IPSM_Signaling.vi');
        viSETB=invoke(mag,'GetVIReference',viSETBpath);
        !sm\channels\vi\OI_IPSM_Signaling.vi; 
        % Add ReadB reference
        viSETBpath = fullfile(baseDir, 'sm\channels\vi\OI_IPSM_Control_Remote.vi');
        viGETB = invoke(mag,'GetVIReference',viGETBpath);
        !sm\channels\vi\OI_IPSM_Signaling.vi;

        ind = smloadinst('IPSM_LV', [], 'None');
        smdata.inst(ind).name = 'IPSM_LV';
        smaddchannel('IPSM_LV','Field','B',[-5,5,Inf,1]); 
        smaddchannel('IPSM_LV','Brate','Brate',[0,0.15,Inf,1]);
    catch err
        fprintf(['*ERROR* problem with connecting to IPSM Magnet (LV)\n' err.identifier ': ' err.message '\n'])
    end
end

%% Add Cell6 Magnet Control (LabVIEW)
if isfield(CFG,'Cell6_MAG_Use') && isfield(CFG.Cell6_MAG_Use,'enable') ...
        && ~isempty(CFG.Cell6_MAG_Use.enable) && CFG.enable.Cell6_MAG_Use ...
    try
        global viSETB;
        global viGETB;
        mag = actxserver('LabVIEW.Application');

       % Add SetB reference using relative path based on userpath
        baseDir = strtrim(userpath); % remove trailing semicolon if exists
        viSETBpath = fullfile(baseDir, 'sm\channels\vi\Cell6_MAG_Signaling.vi');
        viSETB = invoke(mag, 'GetVIReference', viSETBpath);
        
        % Open VI file via system command
        !sm\channels\vi\Cell6_MAG_Signaling.vi
        
        % Add ReadB reference using relative path based on userpath
        viGETBpath = fullfile(baseDir, 'sm\channels\vi\Cell6_PS_Control_Remote.vi');
        viGETB = invoke(mag, 'GetVIReference', viGETBpath);
        
        % Open VI file via system command (same as above)
        !sm\channels\vi\Cell16_MAG_Signaling.vi
        
        ind = smloadinst('Cell6_MAG', [], 'None');
        smdata.inst(ind).name = 'Cell6_MAG';
        
        % Channels
        smaddchannel('Cell6_MAG','Field','B',[-35,35,Inf,1]);
        smaddchannel('Cell6_MAG','Brate','Brate',[0,7,Inf,1]);
        smaddchannel('Cell6_MAG','T','T',[0,20,Inf,1]);
        smaddchannel('Cell6_MAG','Trate','Trate',[0,1,Inf,1]);
 
    catch err
        fprintf(['*ERROR* problem with connecting to Cell6 Magnet\n' err.identifier ': ' err.message '\n'])
    end
end

%% Add Cell9 Magnet Control (LabVIEW)
if isfield(CFG,'Cell9_MAG_Use') && isfield(CFG.Cell9_MAG_Use,'enable') ...
        && ~isempty(CFG.Cell9_MAG_Use.enable) && CFG.enable.Cell9_MAG_Use ...
    try
        global viSETB;
        global viGETB;
        mag = actxserver('LabVIEW.Application');

       % Add SetB reference using relative path based on userpath
        baseDir = strtrim(userpath); % remove trailing semicolon if exists
        viSETBpath = fullfile(baseDir, 'sm\channels\vi\Cell9_MAG_Signaling.vi');
        viSETB = invoke(mag, 'GetVIReference', viSETBpath);
        
        % Open VI file via system command
        !sm\channels\vi\Cell9_MAG_Signaling.vi
        
        % Add ReadB reference using relative path based on userpath
        viGETBpath = fullfile(baseDir, 'sm\channels\vi\Cell9_PS_Control_Remote.vi');
        viGETB = invoke(mag, 'GetVIReference', viGETBpath);
        
        % Open VI file via system command (same as above)
        !sm\channels\vi\Cell16_MAG_Signaling.vi
        
        ind = smloadinst('Cell9_MAG', [], 'None');
        smdata.inst(ind).name = 'Cell9_MAG';
        
        % Channels
        smaddchannel('Cell9_MAG','Field','B',[-35,35,Inf,1]);
        smaddchannel('Cell9_MAG','Brate','Brate',[0,7,Inf,1]);
        smaddchannel('Cell9_MAG','T','T',[0,20,Inf,1]);
        smaddchannel('Cell9_MAG','Trate','Trate',[0,1,Inf,1]);
 
    catch err
        fprintf(['*ERROR* problem with connecting to Cell9 Magnet\n' err.identifier ': ' err.message '\n'])
    end
end

%% Add Cell12 Magnet Control (LabVIEW)
if isfield(CFG,'Cell12_MAG_Use') && isfield(CFG.Cell12_MAG_Use,'enable') ...
        && ~isempty(CFG.Cell12_MAG_Use.enable) && CFG.enable.Cell12_MAG_Use ...
    try
        global viSETB;
        global viGETB;
        mag = actxserver('LabVIEW.Application');

       % Add SetB reference using relative path based on userpath
        baseDir = strtrim(userpath); % remove trailing semicolon if exists
        viSETBpath = fullfile(baseDir, 'sm\channels\vi\Cell12_MAG_Signaling.vi');
        viSETB = invoke(mag, 'GetVIReference', viSETBpath);
        
        % Open VI file via system command
        !sm\channels\vi\Cell12_MAG_Signaling.vi
        
        % Add ReadB reference using relative path based on userpath
        viGETBpath = fullfile(baseDir, 'sm\channels\vi\Cell12_PS_Control_Remote.vi');
        viGETB = invoke(mag, 'GetVIReference', viGETBpath);
        
        % Open VI file via system command (same as above)
        !sm\channels\vi\Cell16_MAG_Signaling.vi
        
        ind = smloadinst('Cell12_MAG', [], 'None');
        smdata.inst(ind).name = 'Cell12_MAG';
        
        % Channels
        smaddchannel('Cell12_MAG','Field','B',[-35,35,Inf,1]);
        smaddchannel('Cell12_MAG','Brate','Brate',[0,7,Inf,1]);
        smaddchannel('Cell12_MAG','T','T',[0,20,Inf,1]);
        smaddchannel('Cell12_MAG','Trate','Trate',[0,1,Inf,1]);
 
    catch err
        fprintf(['*ERROR* problem with connecting to Cell12 Magnet\n' err.identifier ': ' err.message '\n'])
    end
end

%% Add Cell15 Magnet Control (LabVIEW)
if isfield(CFG,'Cell15_MAG_Use') && isfield(CFG.Cell15_MAG_Use,'enable') ...
        && ~isempty(CFG.Cell15_MAG_Use.enable) && CFG.enable.Cell15_MAG_Use ...
    try
        global viSETB;
        global viGETB;
        mag = actxserver('LabVIEW.Application');

       % Add SetB reference using relative path based on userpath
        baseDir = strtrim(userpath); % remove trailing semicolon if exists
        viSETBpath = fullfile(baseDir, 'sm\channels\vi\Cell15_MAG_Signaling.vi');
        viSETB = invoke(mag, 'GetVIReference', viSETBpath);
        
        % Open VI file via system command
        !sm\channels\vi\Cell15_MAG_Signaling.vi
        
        % Add ReadB reference using relative path based on userpath
        viGETBpath = fullfile(baseDir, 'sm\channels\vi\Cell15_PS_Control_Remote.vi');
        viGETB = invoke(mag, 'GetVIReference', viGETBpath);
        
        % Open VI file via system command (same as above)
        !sm\channels\vi\Cell15_MAG_Signaling.vi
        
        ind = smloadinst('Cell15_MAG', [], 'None');
        smdata.inst(ind).name = 'Cell15_MAG';
        
        % Channels
        smaddchannel('Cell15_MAG','Field','B',[-35,35,Inf,1]);
        smaddchannel('Cell15_MAG','Brate','Brate',[0,7,Inf,1]);
        smaddchannel('Cell15_MAG','T','T',[0,20,Inf,1]);
        smaddchannel('Cell15_MAG','Trate','Trate',[0,1,Inf,1]);
 
    catch err
        fprintf(['*ERROR* problem with connecting to Cell15 Magnet\n' err.identifier ': ' err.message '\n'])
    end
end

%% SCM1 Magnet Control
if isfield(CFG,'SCM1_MAG_Use') && isfield(CFG.SCM1_MAG_Use,'enable') ...
        && ~isempty(CFG.SCM1_MAG_Use.enable) && CFG.enable.SCM1_MAG_Use ...
    try
        global viSETB;
        global viGETB;
        mag = actxserver('LabVIEW.Application');

       % Add SetB reference using relative path based on userpath
        baseDir = strtrim(userpath); % remove trailing semicolon if exists
        viSETBpath = fullfile(baseDir, 'sm\channels\vi\SCM1_MAG_Signaling.vi');
        viSETB = invoke(mag, 'GetVIReference', viSETBpath);
        
        % Open VI file via system command
        !sm\channels\vi\SCM1_MAG_Signaling.vi
        
        % Add ReadB reference using relative path based on userpath
        viGETBpath = fullfile(baseDir, 'sm\channels\vi\SCM1_PS_Control_Remote.vi');
        viGETB = invoke(mag, 'GetVIReference', viGETBpath);
        
        % Open VI file via system command (same as above)
        !sm\channels\vi\SCM1_MAG_MAG_Signaling.vi
        
        ind = smloadinst('SCM1_MAG', [], 'None');
        smdata.inst(ind).name = 'SCM1_MAG';
        
        % Channels
        smaddchannel('SCM1_MAG','Field','B',[-35,35,Inf,1]);
        smaddchannel('SCM1_MAG','Brate','Brate',[0,7,Inf,1]);
        smaddchannel('SCM1_MAG','T','T',[0,20,Inf,1]);
        smaddchannel('SCM1_MAG','Trate','Trate',[0,1,Inf,1]);
 
    catch err
        fprintf(['*ERROR* problem with connecting to Cell15 Magnet\n' err.identifier ': ' err.message '\n'])
    end
end


%% SCM2 Magnet Control (LabVIEW)
if isfield(CFG,'SCM2_MAG_Use') && isfield(CFG.SCM2_MAG_Use,'enable') ...
        && ~isempty(CFG.SCM2_MAG_Use.enable) && CFG.enable.SCM2_MAG_Use ...
    try
        global viSETB;
        global viGETB;
        mag = actxserver('LabVIEW.Application');

       % Add SetB reference using relative path based on userpath
        baseDir = strtrim(userpath); % remove trailing semicolon if exists
        viSETBpath = fullfile(baseDir, 'sm\channels\vi\SCM2_MAG_Signaling.vi');
        viSETB = invoke(mag, 'GetVIReference', viSETBpath);
        
        % Open VI file via system command
        !vi\SCM2_MAG_Signaling.vi
        
        % Add ReadB reference using relative path based on userpath
        viGETBpath = fullfile(baseDir, 'sm\channels\vi\SCM2_PS_Control_Remote.vi');
        viGETB = invoke(mag, 'GetVIReference', viGETBpath);
        
        % Open VI file via system command (same as above)
        !vi\SCM2_MAG_MAG_Signaling.vi
        
        ind = smloadinst('SCM2_MAG', [], 'None');
        smdata.inst(ind).name = 'SCM2_MAG';
        
        % Channels
        smaddchannel('SCM2_MAG','Field','B',[-35,35,Inf,1]);
        smaddchannel('SCM2_MAG','Brate','Brate',[0,7,Inf,1]);
        smaddchannel('SCM2_MAG','T','T',[0,20,Inf,1]);
        smaddchannel('SCM2_MAG','Trate','Trate',[0,1,Inf,1]);
 
    catch err
        fprintf(['*ERROR* problem with connecting to Cell15 Magnet\n' err.identifier ': ' err.message '\n'])
    end
end


%% SCM3_MAG
if isfield(CFG,'SCM3_MAG_Use') && isfield(CFG.SCM3_MAG_Use,'enable') ...
        && ~isempty(CFG.SCM3_MAG_Use.enable) && CFG.enable.SCM3_MAG_Use ...
    try
        global viSETB;
        global viGETB;
        mag = actxserver('LabVIEW.Application');

       % Add SetB reference using relative path based on userpath
        baseDir = strtrim(userpath); % remove trailing semicolon if exists
        viSETBpath = fullfile(baseDir, 'vi\SCM3_MAG_Signaling.vi');
        viSETB = invoke(mag, 'GetVIReference', viSETBpath);
        
        % Open VI file via system command
        !vi\SCM3_MAG_Signaling.vi
        
        % Add ReadB reference using relative path based on userpath
        viGETBpath = fullfile(baseDir, 'vi\SCM3_PS_Control_Remote.vi');
        viGETB = invoke(mag, 'GetVIReference', viGETBpath);
        
        % Open VI file via system command (same as above)
        !vi\SCM3_MAG_MAG_Signaling.vi
        
        ind = smloadinst('SCM3_MAG', [], 'None');
        smdata.inst(ind).name = 'SCM3_MAG';
        
        % Channels
        smaddchannel('SCM3_MAG','Field','B',[-35,35,Inf,1]);
        smaddchannel('SCM3_MAG','Brate','Brate',[0,7,Inf,1]);
        smaddchannel('SCM3_MAG','T','T',[0,20,Inf,1]);
        smaddchannel('SCM3_MAG','Trate','Trate',[0,1,Inf,1]);
 
    catch err
        fprintf(['*ERROR* problem with connecting to Cell15 Magnet\n' err.identifier ': ' err.message '\n'])
    end
end


%% SCM4 Magnet Control (LabVIEW)
if isfield(CFG,'SCM4_MAG_Use') && isfield(CFG.SCM4_MAG_Use,'enable') ...
        && ~isempty(CFG.SCM4_MAG_Use.enable) && CFG.enable.SCM4_MAG_Use ...
    try
        global viSETB;
        global viGETB;
        mag = actxserver('LabVIEW.Application');

       % Add SetB reference using relative path based on userpath
        baseDir = strtrim(userpath); % remove trailing semicolon if exists
        viSETBpath = fullfile(baseDir, 'sm\channels\vi\SCM4_MAG_Signaling.vi');
        viSETB = invoke(mag, 'GetVIReference', viSETBpath);
        
        % Open VI file via system command
        !sm\channels\vi\SCM4_MAG_Signaling.vi
        
        % Add ReadB reference using relative path based on userpath
        viGETBpath = fullfile(baseDir, 'vi\SCM4_PS_Control_Remote.vi');
        viGETB = invoke(mag, 'GetVIReference', viGETBpath);
        
        % Open VI file via system command (same as above)
        !vi\SCM4_MAG_MAG_Signaling.vi
        
        ind = smloadinst('SCM4_MAG', [], 'None');
        smdata.inst(ind).name = 'SCM4_MAG';
        
        % Channels
        smaddchannel('SCM4_MAG','Field','B',[-35,35,Inf,1]);
        smaddchannel('SCM4_MAG','Brate','Brate',[0,7,Inf,1]);
        smaddchannel('SCM4_MAG','T','T',[0,20,Inf,1]);
        smaddchannel('SCM4_MAG','Trate','Trate',[0,1,Inf,1]);
 
    catch err
        fprintf(['*ERROR* problem with connecting to Cell15 Magnet\n' err.identifier ': ' err.message '\n'])
    end
end


%% LockIn SR830
if isfield(CFG,'SR830_1') && isfield(CFG.SR830_1,'gpib_addr') && ~isempty(CFG.SR830_1.gpib_addr)
    try
        smloadind = smloadinst('SR830_Ramp', [], CFG.GPIB.board, CFG.GPIB.index, CFG.SR830_1.gpib_addr);
        smopen(smloadind);

        smdata.inst(smloadind).name = 'SR830_1';
        smdata.inst(smloadind).cntrlfn = @smcSR830_Ramp;

        % ===================== SR830 channel registry =====================
        smaddchannel('SR830_1','X',     'X',        [-Inf, Inf, Inf, 1e6]);  % In-phase (→ µV)
        smaddchannel('SR830_1','Y',     'Y',        [-Inf, Inf, Inf, 1e6]);  % Quadrature (→ µV)
        smaddchannel('SR830_1','R',     'R',        [-Inf, Inf, Inf, 1e6]);  % Magnitude (→ µV)
        smaddchannel('SR830_1','THETA', 'Theta',    [-180, 180, 1,   1]);    % Degree
        
        smaddchannel('SR830_1','FREQ',  'Freq',     [0, 102000, 10,  1]);    % Frequency (Hz)
        smaddchannel('SR830_1','VREF',  'Vref',     [0.004, 5,  0.001, 1]);  % Reference amplitude (V)
        
        smaddchannel('SR830_1','IN1',   'AUX_IN1',  [-10, 10, 0.001, 1]);    % V
        smaddchannel('SR830_1','IN2',   'AUX_IN2',  [-10, 10, 0.001, 1]);    % V
        smaddchannel('SR830_1','IN3',   'AUX_IN3',  [-10, 10, 0.001, 1]);    % V
        smaddchannel('SR830_1','IN4',   'AUX_IN4',  [-10, 10, 0.001, 1]);    % V
        
        smaddchannel('SR830_1','OUT1',  'AUX_OUT1', [-10, 10, 0.001, 1]);    % V
        smaddchannel('SR830_1','OUT2',  'AUX_OUT2', [-10, 10, 0.001, 1]);    % V
        smaddchannel('SR830_1','OUT3',  'AUX_OUT3', [-10, 10, 0.001, 1]);    % V
        smaddchannel('SR830_1','OUT4',  'AUX_OUT4', [-10, 10, 0.001, 1]);    % V
        
        smaddchannel('SR830_1','SENS',  'Sensitivity', [2e-9, 1,    Inf, 1]); % V_rms
        smaddchannel('SR830_1','TAU',   'TimeConst',   [10e-6, 3e4, Inf, 1]); % s
        smaddchannel('SR830_1','SYNC',  'Sync',        [0, 1,   1,   1]);     % 0/1
        
        smaddchannel('SR830_1','DATA1', 'X-buf');        % Left trace
        smaddchannel('SR830_1','DATA2', 'Phase-buf');    % Right trace
        
    catch err
        fprintf(['*ERROR* SR830: ' err.identifier ': ' err.message '\n']);
    end
end


%% SR860
if SR860_1==1

    try
        ind = smloadinst('SR860_1', [], GPIB_BOARD, BOARD_NUM, LockIn860_L2_GPIB);
        
        smdata.inst(ind).name = 'SR860_1';
        smdata.inst(ind).cntrlfn = @smcSR860;
        smdata.inst(ind).device = 'SR860_1';

        %open GPIB communication
        smopen(ind);

        %add channels
        smaddchannel('LockIn860_1', 'X', 'Vxx1', [-Inf, Inf, Inf, 100]);
        smaddchannel('LockIn860_1', 'Y', 'Vxx1_y', [-Inf, Inf, Inf, 100]);
        %smaddchannel('LockIn860_1', 'THETA', 'Theta_Middle', [-Inf, Inf, Inf, 1]);
      % smaddchannel('LockIn860_1', 'FREQ', 'Freq_Middle', [0, 102000, Inf, 1]);
%         smaddchannel('LockIn860_1', 'Vac', 'Vref_Middle', [0, 5, Inf, 1]);
%          smaddchannel('LockIn860_1', 'Vdc', 'Vdc_Middle', [-4, 4, Inf, 1]);
       %  smaddchannel('LockIn860_1', 'Auto', 'Auto_Middle', [-Inf, Inf, Inf, 1]);
%          smaddchannel('LockIn860_1', 'OUT1', 'Vdc', [-5, 5, 0.5, 1]);
%         smaddchannel('LockIn860_1', 'OUT2', 'OUT2_A', [-4, 4, 0.5, 1]);
%         smaddchannel('LockIn860_1', 'OUT3', 'OUT3_A', [-4, 4, 0.5, 1]);
        
    catch err
        fprintf(['*ERROR* problem with connecting to LockIn_860\n' err.identifier ': ' err.message '\n'])
    end

end

%% SR865A_NB
if SR865A_Use==1

    try
        ind = smloadinst('SR865A', [], GPIB_BOARD, BOARD_NUM, LockIn865A_1_GPIB);
        
        smdata.inst(ind).name = 'SR865A_1';
        smdata.inst(ind).cntrlfn = @smcSR865A;
        smdata.inst(ind).device = 'SR865A';

        %open GPIB communication
        smopen(ind);

        %add channels
        smaddchannel('LockIn865A_NB', 'X', 'Vxx', [-Inf, Inf, Inf, 100]);
        smaddchannel('LockIn865A_NB', 'Y', 'Vxy', [-Inf, Inf, Inf, 100]);
        %smaddchannel('LockIn865A_NB', 'THETA', 'Theta_RT', [-Inf, Inf, Inf, 1]);
%        smaddchannel('LockIn865A_NB', 'FREQ', 'Freq', [0, 102000, Inf, 1]);
%         smaddchannel('LockIn865A_NB', 'Vac', 'Vref', [0, 5, Inf, 1]);
         %smaddchannel('LockIn865A_NB', 'Vdc', 'Vdc_High', [-4, 4, Inf, 1]);
         %smaddchannel('LockIn865A_NB', 'Auto', 'Auto_High', [-Inf, Inf, Inf, 1]);
        % smaddchannel('LockIn865A_NB', 'OUT1', 'Vdc', [-5, 5, 0.5, 1]);
%         smaddchannel('LockIn865A_NB', 'OUT2', 'OUT2_A', [-4, 4, 0.5, 1]);
%         smaddchannel('LockIn865A_NB', 'OUT3', 'OUT3_A', [-4, 4, 0.5, 1]);

        
    catch err
        fprintf(['*ERROR* problem with connecting to LockIn_860\n' err.identifier ': ' err.message '\n'])
    end

end


%% Harvard BabyDAC (BabyDAC)
if isfield(CFG,'DAC') && isfield(CFG.DAC,'serial') && ~isempty(CFG.DAC.serial)
    try
        ind = smloadinst('BabyDAC', [], 'serial', CFG.DAC.serial);
        set(smdata.inst(ind).data.inst,'BaudRate',9600);
        set(smdata.inst(ind).data.inst,'timeout',20);
        smopen(ind);

        smdata.inst(ind).name = 'DAC';

        smaddchannel('DAC', 'CH0', 'bg', [-10 10 10 1]);
        smaddchannel('DAC', 'CH1', 'tg', [-3 3 10 1]);
        
        while smdata.inst(ind).data.inst.BytesAvailable > 0
            fscanf(smdata.inst(ind).data.inst);
            pause(0.3);
        end
        for i=0:3
            stri = num2str(i);
            query(smdata.inst(ind).data.inst,['B0;M2;C' stri ';S0;']);
            query(smdata.inst(ind).data.inst,['B0;M2;C' stri ';U65535;']);
            query(smdata.inst(ind).data.inst,['B0;M2;C' stri ';L0;']);
            dac_zero=32768; % measured bit where DAC is zero
            bit_str=sprintf(['B0;M2;C' stri ';D%.0f;'],dac_zero);
            query(smdata.inst(ind).data.inst,bit_str);
        end
        smdata.inst(ind).data.rng = repmat([-10 10],12,1);
    catch err
        fprintf(['*ERROR* problem with connecting to the DAC\n' err.identifier ': ' err.message '\n'])
    end
end

%% Keithley 2001 (DMM)
if isfield(CFG,'K2001') && isfield(CFG.K2001,'gpib_addr') && ~isempty(CFG.K2001.gpib_addr)
    try
        ind_sr = smloadinst('sminst_k2001', [], CFG.GPIB.board, CFG.GPIB.index, CFG.K2001.gpib_addr);
        smopen(ind_sr);
        smdata.inst(ind_sr).name    = 'k2001';
        smdata.inst(ind_sr).cntrlfn = @smck2001_Ramp;
        
        smaddchannel('k2001','V','V');
        smaddchannel('k2001','I','I');
        smaddchannel('k2001','V-buf','V-buf');
        smaddchannel('k2001','I-buf','I-buf');
    catch err
        fprintf(['*ERROR* k2001: ' err.identifier ': ' err.message '\n']);
    end
end

%% Keithley 2400
if isfield(CFG,'K2400') && isfield(CFG.K2400,'gpib_addr') && ~isempty(CFG.K2400.gpib_addr)
    try
        ind  = smloadinst('K2400_Ramp', [], CFG.GPIB.board, CFG.GPIB.index, CFG.K2400.gpib_addr);
        smdata.inst(ind).cntrlfn = @smcK2400_Ramp;
        set(smdata.inst(ind).data.inst,'inputbuffersize',2^18);
        set(smdata.inst(ind).data.inst,'outputbuffersize',2^10);
        set(smdata.inst(ind).data.inst,'eosmode','read&write');
        smopen(ind);

        smdata.inst(ind).name = 'Source1';

        smaddchannel('K2400','V',       'K2400_V',        [-20, 20, 1e-3, 1]);   % Source voltage (V)
        smaddchannel('K2400','I',       'K2400_I',        [-1,   1,  1e-6, 1]);  % Measured current (A)
        smaddchannel('K2400','Vcompl',  'K2400_Vcomp',    [0,   100, 1e-2, 1]);  % Voltage compliance (V)
        smaddchannel('K2400','Icompl',  'K2400_Icomp',    [0,     1,  1e-6, 1]); % Current compliance (A)
        smaddchannel('K2400','I-buf',   'Ig-buf');                                % Buffered current trace

        fprintf(smdata.inst(ind).data.inst,'*rst');
        if isfield(CFG,'K2400') && isfield(CFG.K2400,'mode') && strcmp(CFG.K2400.mode,'Voltage')
            fprintf(smdata.inst(ind).data.inst,':source:func:mode volt');
            fprintf(smdata.inst(ind).data.inst,':sense:current:range 1e-6');
            fprintf(smdata.inst(ind).data.inst,':sense:current:protection 1e-6');
            fprintf(smdata.inst(ind).data.inst,':source:voltage:delay 0.0');
            fprintf(smdata.inst(ind).data.inst,':source:voltage:range:auto 1');
        elseif isfield(CFG,'K2400') && isfield(CFG.K2400,'mode') && strcmp(CFG.K2400.mode,'Current')
            fprintf(smdata.inst(ind).data.inst,':source:func:mode curr');
            fprintf(smdata.inst(ind).data.inst,':sense:voltage:protection 1');
            fprintf(smdata.inst(ind).data.inst,':sense:voltage:range 10');
            fprintf(smdata.inst(ind).data.inst,':source:current:delay 0.0');
            fprintf(smdata.inst(ind).data.inst,':source:current:range:auto 1');
        end
        fprintf(smdata.inst(ind).data.inst,':output on');
    catch err
        fprintf(['*ERROR* problem with connecting to the Source\n' err.identifier ': ' err.message '\n'])
    end
end

%% add Keithley 2450
if isfield(CFG,'K2450') && isfield(CFG.K2450,'gpib_addr') && ~isempty(CFG.K2450.gpib_addr)
    try
        ind_k = smloadinst('k2450_Ramp', [], CFG.GPIB.board, CFG.GPIB.index, CFG.K2450.gpib_addr);
        smopen(ind_k);
        smdata.inst(ind_k).name    = 'K2450';
        smdata.inst(ind_k).cntrlfn = @smcK2450_Ramp;

        smaddchannel('K2450','Vg',       'Vg',            [-200, 200, 1e-3, 1]);
        smaddchannel('K2450','Ig',       'Ig',            [-1,     1,  1e-6, 1]);
        smaddchannel('K2450','VgRange',  'VgRange',       [0,       5,      1, 1]);
        smaddchannel('K2450','VgRead',   'Vg_readback',   [-200, 200, 1e-3, 1]);
        smaddchannel('K2450','IgLimit',  'Ig_limit',      [1e-10, 1e-3, 1e-9, 1]);
        smaddchannel('K2450','Vg-ramp',  'Vg_ramp_rate',  [5.5, 65.345, 0.1, 1]);
        smaddchannel('K2450','Ig-buf',   'Ig-buf');

        fprintf(smdata.inst(ind_k).data.inst,'*rst');
        fprintf(smdata.inst(ind_k).data.inst,'*cls');
    catch err
        fprintf(['*ERROR* problem with connecting to the Source | ' err.identifier ': ' err.message '\n']);
    end
end

%% Keithley 2700
if isfield(CFG,'K2700') && isfield(CFG.K2700,'gpib_addr') && ~isempty(CFG.K2700.gpib_addr)
    try
        ind  = smloadinst('K2700', [], CFG.GPIB.board, CFG.GPIB.index, CFG.K2700.gpib_addr);
        set(smdata.inst(ind).data.inst,'inputbuffersize',2^18);
        set(smdata.inst(ind).data.inst,'outputbuffersize',2^10);
        set(smdata.inst(ind).data.inst,'eosmode','read&write');
        set(smdata.inst(ind).data.inst,'timeout',30);
        smopen(ind);

        smdata.inst(ind).name = 'DMM';

        smaddchannel('DMM','V','Vdc',[-Inf Inf Inf 100]);
        smaddchannel('DMM','V','Idc_m',[-Inf Inf Inf -1e6]);

        fprintf(smdata.inst(ind).data.inst,'*rst');
        fprintf(smdata.inst(ind).data.inst,'initiate:continuous on;:abort');
        fprintf(smdata.inst(ind).data.inst,':voltage:nplcycles 1');
        fprintf(smdata.inst(ind).data.inst,'sense:voltage:dc:average:state off');
        fprintf(smdata.inst(ind).data.inst,':sense:voltage:range:auto 1');
    catch err
        fprintf(['*ERROR* problem with connecting to the DMM\n' err.identifier ': ' err.message '\n'])
    end
end

%% Keysight 33511B (Function Gen) - if used in your lab
if isfield(CFG,'KS33511B') && isfield(CFG.KS33511B,'gpib_addr') && ~isempty(CFG.KS33511B.gpib_addr)
    try
        ind  = smloadinst('KS33511B', [], CFG.GPIB.board, CFG.GPIB.index, CFG.KS33511B.gpib_addr);
        set(smdata.inst(ind).data.inst,'inputbuffersize',2^18);
        set(smdata.inst(ind).data.inst,'outputbuffersize',2^10);
        set(smdata.inst(ind).data.inst,'eosmode','read&write');
        smopen(ind);

        smdata.inst(ind).name = 'FunGen';

        smaddchannel('FunGen','Vac','Vac',[-10 10 1 1]);
        smaddchannel('FunGen','Vdc','Vdc',[-10 10 1 1]);
        smaddchannel('FunGen','Freq','Freq',[0 2e7 Inf 1]);

        fprintf(smdata.inst(ind).data.inst,'*rst');
        fprintf(smdata.inst(ind).data.inst,'*cls');
        fprintf(smdata.inst(ind).data.inst,'OUTP:LOAD INF');
        fprintf(smdata.inst(ind).data.inst,'SOUR:FUNC SIN');
        fprintf(smdata.inst(ind).data.inst,'SOUR:VOLT:UNIT VRMS');
        fprintf(smdata.inst(ind).data.inst,'SOUR:VOLT 1E-3');
        fprintf(smdata.inst(ind).data.inst,'SOUR:FREQ 23.33');
        fprintf(smdata.inst(ind).data.inst,'OUTP ON');
    catch err
        fprintf(['*ERROR* problem with connecting to the Source\n' err.identifier ': ' err.message '\n'])
    end
end

%% Keysight 34401A (Aglient/HP) USB
% Use CFG.KS34465A_1.usb as VISA resource string (e.g., 'USB0::...::INSTR')
if isfield(CFG,'KS34465A_1') && isfield(CFG.KS34465A_1,'usb') && ~isempty(CFG.KS34465A_1.usb)
    try
        
        ind  = smloadinst('KS34465A', [], CFG.GPIB.board, CFG.KS34465A_1.usb);
        set(smdata.inst(ind).data.inst,'inputbuffersize',2^18);
        set(smdata.inst(ind).data.inst,'outputbuffersize',2^10);
        set(smdata.inst(ind).data.inst,'eosmode','read&write');
        set(smdata.inst(ind).data.inst,'timeout',10);
        smopen(ind);

        smdata.inst(ind).name = 'DMM';

        smaddchannel('DMM1','VAL','Vdc_Read',[-Inf Inf Inf 1]);

        fprintf(smdata.inst(ind).data.inst,'*rst');
        fprintf(smdata.inst(ind).data.inst,'*cls');
        
        if isfield(CFG,'KS34465A_1') && isfield(CFG.KS34465A_1,'mode') && strcmp(CFG.KS34465A_1.mode,'Voltage')
            fprintf(smdata.inst(ind).data.inst,'configure:volt:dc');
            fprintf(smdata.inst(ind).data.inst,'sense:voltage:nplc 1');
        elseif isfield(CFG,'KS34465A_1') && isfield(CFG.KS34465A_1,'mode') && strcmp(CFG.KS34465A_1.mode,'Current')
            fprintf(smdata.inst(ind).data.inst,'configure:curr:dc');
            fprintf(smdata.inst(ind).data.inst,'sense:curr:nplc 1');
        end
        fprintf(smdata.inst(ind).data.inst,'trig:count inf');
        fprintf(smdata.inst(ind).data.inst,'init');
    catch err
        fprintf(['*ERROR* problem with connecting to the Keysight DMM\n' err.identifier ': ' err.message '\n'])
    end
end

%% KS34465A_1 (DMM, USB VISA)
% Use CFG.KS34465A_1.usb as VISA resource string (e.g., 'USB0::...::INSTR')
if isfield(CFG,'KS34465A_1') && isfield(CFG.KS34465A_1,'usb') && ~isempty(CFG.KS34465A_1.usb)
    try
        ind  = smloadinst('KS34465A', [], CFG.GPIB.board, CFG.KS34465A_1.usb);
        set(smdata.inst(ind).data.inst,'inputbuffersize',2^18);
        set(smdata.inst(ind).data.inst,'outputbuffersize',2^10);
        set(smdata.inst(ind).data.inst,'eosmode','read&write');
        set(smdata.inst(ind).data.inst,'timeout',10);
        smopen(ind);

        smdata.inst(ind).name = 'DMM';

        smaddchannel('DMM1','VAL','Vdc_Read',[-Inf Inf Inf 1]);

        fprintf(smdata.inst(ind).data.inst,'*rst');
        fprintf(smdata.inst(ind).data.inst,'*cls');
        
        if isfield(CFG,'KS34465A_1') && isfield(CFG.KS34465A_1,'mode') && strcmp(CFG.KS34465A_1.mode,'Voltage')
            fprintf(smdata.inst(ind).data.inst,'configure:volt:dc');
            fprintf(smdata.inst(ind).data.inst,'sense:voltage:nplc 1');
        elseif isfield(CFG,'KS34465A_1') && isfield(CFG.KS34465A_1,'mode') && strcmp(CFG.KS34465A_1.mode,'Current')
            fprintf(smdata.inst(ind).data.inst,'configure:curr:dc');
            fprintf(smdata.inst(ind).data.inst,'sense:curr:nplc 1');
        end
        fprintf(smdata.inst(ind).data.inst,'trig:count inf');
        fprintf(smdata.inst(ind).data.inst,'init');
    catch err
        fprintf(['*ERROR* problem with connecting to the Keysight DMM\n' err.identifier ': ' err.message '\n'])
    end
end

%% add Keysight B2902A (Aglient/HP)
if isfield(CFG,'SourceMeter') && isfield(CFG.SourceMeter,'gpib_addr') && ~isempty(CFG.SourceMeter.gpib_addr)
    try
        ind  = smloadinst('B2902A', [], CFG.GPIB.board, CFG.GPIB.index, CFG.SourceMeter.gpib_addr);
        set(smdata.inst(ind).data.inst,'inputbuffersize',2^18);
        set(smdata.inst(ind).data.inst,'outputbuffersize',2^10);
        set(smdata.inst(ind).data.inst,'eosmode','read&write');
        set(smdata.inst(ind).data.inst,'timeout',5);
        smopen(ind);

        smdata.inst(ind).name = 'SourceMeter';

        smaddchannel('SourceMeter','V1','Vg',[-10 12 20 1]);
        smaddchannel('SourceMeter','V2','Ib',[-1e-7 1e-7 20 1e8]);
        smaddchannel('SourceMeter','V2','Vbias2',[-10e-3 10e-3 20 1000]);
        smaddchannel('SourceMeter','I1','Ig',[-1 1 Inf 1]); 
        smaddchannel('SourceMeter','I2','Ibias2',[-1 1 Inf 1]);
        smaddchannel('SourceMeter','Icompl1','Ic1',[0 1 Inf 1]);
        smaddchannel('SourceMeter','Icompl2','Ic2',[0 1 Inf 1]);

        fprintf(smdata.inst(ind).data.inst,'*rst');
        if(strcmp(CFG.mode.SourceMeter_CH1,'Voltage'))
            fprintf(smdata.inst(ind).data.inst,':sense1:current:protection 1e-8');
            fprintf(smdata.inst(ind).data.inst,':sense1:current:range:auto 1');
        elseif(strcmp(CFG.mode.SourceMeter_CH1, 'Current'))
            fprintf(smdata.inst(ind).data.inst,':source1:function:mode current');
            fprintf(smdata.inst(ind).data.inst,':sense1:voltage:protection 1');
            fprintf(smdata.inst(ind).data.inst,':sense1:voltage:range:auto 1');
        else
            error('No such mode for SourceMeter CH1: %s', CFG.mode.SourceMeter_CH1);
        end
        fprintf(smdata.inst(ind).data.inst,':output1 on');
        fprintf(smdata.inst(ind).data.inst,':arm1:acq:count infinity');
        fprintf(smdata.inst(ind).data.inst,':init:acq (@1)');
        
        if(strcmp(CFG.mode.SourceMeter_CH2,'Voltage'))
            fprintf(smdata.inst(ind).data.inst,':sense2:current:protection 1e-8');
            fprintf(smdata.inst(ind).data.inst,':sense2:current:range:auto 1');
        elseif(strcmp(CFG.mode.SourceMeter_CH2, 'Current'))
            fprintf(smdata.inst(ind).data.inst,':source2:function:mode current');
            fprintf(smdata.inst(ind).data.inst,':sense2:voltage:protection 1');
            fprintf(smdata.inst(ind).data.inst,':sense2:voltage:range:auto 1');
        else
            error('No such mode for SourceMeter CH2: %s', CFG.mode.SourceMeter_CH2);
        end
        fprintf(smdata.inst(ind).data.inst,':output2 on');
        fprintf(smdata.inst(ind).data.inst,':arm2:acq:count infinity');
        fprintf(smdata.inst(ind).data.inst,':init:acq (@2)');
    catch err
        fprintf(['*ERROR* problem with connecting to the Source\n' err.identifier ': ' err.message '\n'])
    end
end

%% Add Z Magnet (CryoLtd serial)
if isfield(CFG,'Magnet') && isfield(CFG.Magnet,'serial') && ~isempty(CFG.Magnet.serial)
    try
        ind = smloadinst('CryoLtd', [], 'serial', CFG.Magnet.serial);
        smopen(ind);
        smdata.inst(ind).name = 'Magnet';
        
        smaddchannel('Magnet','I','B',[-9,9,Inf,10.167]); % Ramping auto
        smaddchannel('Magnet','M','Bmax',[0,1,Inf,10.167]); % Max field
    catch err
        fprintf(['*ERROR* problem with connecting to the Magnet\n' err.identifier ': ' err.message '\n'])
    end
end

%% Add Current source MagnetK2400 for small B field
if isfield(CFG,'MagnetK2400') && isfield(CFG.MagnetK2400,'gpib_addr') && ~isempty(CFG.MagnetK2400.gpib_addr)
    try
        ind  = smloadinst('K2400', [], CFG.GPIB.board, CFG.GPIB.index, CFG.MagnetK2400.gpib_addr);
        set(smdata.inst(ind).data.inst,'inputbuffersize',2^18);
        set(smdata.inst(ind).data.inst,'outputbuffersize',2^10);
        set(smdata.inst(ind).data.inst,'eosmode','read&write');
        smopen(ind);

        smdata.inst(ind).name = 'MagnetSource';
  
        fprintf(smdata.inst(ind).data.inst,'*RST');
        fprintf(smdata.inst(ind).data.inst,':sour:func curr');
        fprintf(smdata.inst(ind).data.inst,':sens:func "volt"');
        fprintf(smdata.inst(ind).data.inst,':outp on');
    
        smaddchannel('MagnetSource','V','VB',[-Inf Inf Inf 1]); % read-only
        smaddchannel('MagnetSource','I','Bi',[-0.1032,0.1032, 0.0005, 9.6899]);
        smget('VB')
    catch err
        fprintf(['*ERROR* problem with connecting to the MagnetSource\n' err.identifier ': ' err.message '\n'])
    end   
end

%% Add Current source (B2902A as magnet source)
if isfield(CFG,'MagnetSource') && isfield(CFG.MagnetSource,'gpib_addr') && ~isempty(CFG.MagnetSource.gpib_addr)
    try
        ind = smloadinst('B2902A', [], CFG.GPIB.board, CFG.GPIB.index, CFG.MagnetSource.gpib_addr);
        smopen(ind);
        smdata.inst(ind).name = 'MagnetSource';
        smdata.inst(ind).cntrlfn = @smcB2902A_Alt;
        
        smaddchannel('MagnetSource','V1','VB',[-Inf Inf Inf 1]); % read-only
        smaddchannel('MagnetSource','I1','Bi',[-0.4,0.4, 0.002, 1/0.1336]);

        fprintf(smdata.inst(ind).data.inst,'*rst');
        fprintf(smdata.inst(ind).data.inst,':source1:function:mode current');
        fprintf(smdata.inst(ind).data.inst,':sense1:voltage:protection 2');
        fprintf(smdata.inst(ind).data.inst,':sense1:voltage:range:auto 2');
        fprintf(smdata.inst(ind).data.inst,':output1 on');
        smget('VB')
    catch err
        fprintf(['*ERROR* problem with connecting to the MagnetSource\n' err.identifier ': ' err.message '\n'])
    end
end

%% Add AVS47B AC resistance bridge for thermometry
if isfield(CFG,'AVS47B') && isfield(CFG.AVS47B,'gpib_addr') && ~isempty(CFG.AVS47B.gpib_addr)
    try
        ind = smloadinst('AVS47B_GPIB', [], CFG.GPIB.board, CFG.GPIB.index, CFG.AVS47B.gpib_addr);
        smdata.inst(ind).name = 'AVS47B';
        smopen(ind);
        
        smdata.inst(ind).data.calibration{1} = 'RuO2 10k';
        smdata.inst(ind).data.calibration{2} = 'RuO2 10k';
        smdata.inst(ind).data.calibration{3} = 'TT-1306';
        smdata.inst(ind).data.calibration{4} = 'RuO2 1k5';
        smdata.inst(ind).data.calibration{5} = 'RuO2 10k';
        smdata.inst(ind).data.calibration{6} = 'PT1000';
        
        smdata.inst(ind).data.excitation(1) = 4;
        smdata.inst(ind).data.excitation(2) = 4;
        smdata.inst(ind).data.excitation(3) = 3;
        smdata.inst(ind).data.excitation(4) = 3;
        smdata.inst(ind).data.excitation(5) = 3;
        smdata.inst(ind).data.excitation(6) = 3;
                
        smaddchannel('AVS47B', 'CH1', 'T_sorp',   [-Inf, Inf, Inf, 1e3]);
        smaddchannel('AVS47B', 'CH2', 'T_still',  [-Inf, Inf, Inf, 1e3]);
        smaddchannel('AVS47B', 'CH3', 'T_MCLow',  [-Inf, Inf, Inf, 1e3]);
        smaddchannel('AVS47B', 'CH4', 'T_50mK',   [-Inf, Inf, Inf, 1e3]);
        smaddchannel('AVS47B', 'CH5', 'T_Magnet', [-Inf, Inf, Inf, 1e3]);
        smaddchannel('AVS47B', 'CH6', 'T_MCHigh', [-Inf, Inf, Inf, 1]);
    catch err
        fprintf(['*ERROR* problem with connecting to AVS47B\n' err.identifier ': ' err.message '\n'])
    end
end

%% Add Triple Current Source for heating (TCS)
if isfield(CFG,'TCS') && isfield(CFG.TCS,'serial') && ~isempty(CFG.TCS.serial)
    try
        ind = smloadinst('TCS', [], 'serial', CFG.TCS.serial);
        smdata.inst(ind).name = 'TCS';
        smopen(ind);
        
        smaddchannel('TCS', 'SRC1', 'I_sorp',   [-Inf, Inf, Inf, 1]);
        smaddchannel('TCS', 'SRC1', 'I_switch', [-Inf, Inf, Inf, 1]);
        smaddchannel('TCS', 'SRC2', 'I_still',  [-Inf, Inf, Inf, 1]);
        smaddchannel('TCS', 'SRC3', 'I_mc',     [-Inf, Inf, Inf, 1]);
    catch err
        fprintf(['*ERROR* problem with connecting to TCS\n' err.identifier ': ' err.message '\n'])
    end
end
