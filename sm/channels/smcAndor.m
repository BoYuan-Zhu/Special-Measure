function val = smcAndor(ic, val, rate)
% Channels:
% 1: Spectrum  (get only)
% 2: Cooling   (set and get)
% 3: Exposure  (set and get)
% 4: Temp      (set and get)
% 5: AcqMode   (set and get)
% 6: Shutdown  (set only)
% 7: Grating     Grating 1 or 2
% 8: Wavelen   centerwavelength
% 9: Calib       AndorCalibration

% Last update: Yuan Cao 7/1/2015

global smdata;

success=[20002 20034 20036 20037 20072 20202]; % you can check this in the Andor SDK pdf instruction for info
device=0; % Device number of Shamrock spectrometer  % this is got from the labview program of the Shamrock

% Get this instrument
libcamera = smdata.inst(ic(1)).data.libname{1};  % ic(1) stores the instrument number
libspec = smdata.inst(ic(1)).data.libname{2};

switch ic(2)
    case 1  
        %% Spectrum
        if ic(3) == 0 % Read
            
            calllib('ShamrockCIF', 'ShamrockSetShutter', device, 0); % Open shutter
            % No check
            
            data=getSpectrum() - smdata.inst(ic(1)).data.background; % Remove background
            
            calllib('ShamrockCIF', 'ShamrockSetShutter', device, 1); % Close shutter
            % No check
            
            val=data(:);
        else
            fprintf('Error: Operation not supported\n');
            val = NaN;
        end
    case 2
        %% Cooling
        if ic(3) == 0 % Read
            val = smdata.inst(ic(1)).data.isCoolerOn;
        else %Write
            if val == 1 % Cooler On
                smdata.inst(ic(1)).data.isCoolerOn=1;
                ret=calllib(libcamera,'CoolerON');
                check(ret);
            else % Cooler Off
                smdata.inst(ic(1)).data.isCoolerOn=0;
                ret=calllib(libcamera,'CoolerOFF');
                check(ret);
            end
        end
    case 3
        %% Exposure
        if ic(3) == 0
            [ret, exposure, accumulate, kinetic] = calllib(libcamera, 'GetAcquisitionTimings', 0, 0, 0);
            check(ret);
            fprintf('Exposure: %f\nAccumulate: %f\nKinetic %f\n', exposure, accumulate, kinetic);
            val = [exposure, accumulate, kinetic];
        else
            ret = calllib(libcamera, 'SetExposureTime', val);
            check(ret);
            
            smdata.inst(ic(1)).data.background = zeros(512,1); % Clear background
        end
    case 4
        %% Temp
        if ic(3) == 0
            [ret, temp] = calllib(libcamera, 'GetTemperature', 0);
            check(ret);
            val = temp;
        else
            ret = calllib(libcamera, 'SetTemperature', val);
            check(ret);
        end
    case 5
        %% AcqMode
        if ic(3) == 0
            val = smdata.inst(ic(1)).data.acquisitionMode;
        else
            smdata.inst(ic(1)).data.acquisitionMode=val;
            ret = calllib(libcamera, 'SetAcquisitionMode', val);
            check(ret);
            
            smdata.inst(ic(1)).data.background = zeros(512,1); % Clear background
        end
    case 6
        %% Shutdown
        if ic(3) == 0
            fprintf('Error: Please use set instead.\n');
        else
            ret = calllib(libcamera, 'ShutDown');
            check(ret);
            ret = calllib(libspec, 'ShamrockClose');
            checkspec(ret);
            
            smdata.inst(ic(1)).data.background = zeros(512,1); % Clear background
        end
    case 7
        %% Grating
        if ic(3) == 0
            [ret, grating]=calllib(libspec, 'ShamrockGetGrating', device, 0);
            checkspec(ret);
            val = grating;
            [ret, turret]=calllib(libspec, 'ShamrockGetTurret', device, 0);
            checkspec(ret);
            [ret, line, blaze, home, offset]=calllib(libspec, 'ShamrockGetGratingInfo', device, grating, 0, '', 0, 0);
            checkspec(ret);
            fprintf('Grating %d: %f lines, blaze %s, home=%d, offset=%d\n', grating, line, blaze, home, offset);
        else
            ret=calllib(libspec, 'ShamrockSetGrating', device, val);%  choose grating cause the turret has two sides. we need to choose one
            checkspec(ret);
            
            smdata.inst(ic(1)).data.background = zeros(512,1); % Clear background
        end
    case 8
        %% Wavelength
        if ic(3) == 0
            [ret, wavelength]=calllib(libspec, 'ShamrockGetWavelength', device, 0);
            checkspec(ret);
            val = wavelength;
        else
            ret=calllib(libspec, 'ShamrockSetWavelength', device, val);
            checkspec(ret);
            
            smdata.inst(ic(1)).data.background = zeros(512,1); % Clear background
        end
    case 9
        %% Calibration
        if ic(3) == 0
            [ret, calib]=calllib(libspec, 'ShamrockGetCalibration', device, zeros(512,1), 512);
            val = calib;
            checkspec(ret);
        else
            fprintf('Error: Set not supported');
        end
    case 10
        %% Background
        if ic(3) == 0
            val = smdata.inst(ic(1)).data.background;
        else
            if length(val)==512
                % Set to val that is passed into this function
                smdata.inst(ic(1)).data.background = val(:);
            elseif val==0
                % Set to zero
                smdata.inst(ic(1)).data.background = zeros(512,1);    
            elseif val==-1
                % Set to a newly captured spectrum
                smdata.inst(ic(1)).data.background = getSpectrum();
            else
                fprintf('Error: background must be the same size as the spectrum\n');
            end
        end
end
    function check(ret)
        if ~any(ret == success)
            throw(MException('Inst:CommandFailed', ['Command failed. Error code: ', num2str(ret)]));
        end
    end
% case 10
%     %% shutter
%        [getshutter,shutter]=calllib('ShamrockCIF', 'ShamrockGetShutter', 0,0);
%         [getshutter,shutter]=calllib('ShamrockCIF', 'ShamrockShutterIsPresent', 0,0);
%         [getshutter,shutter]=calllib('ShamrockCIF', 'ShamrockIsModePossible', 0,0,0);
%        
    function checkspec(ret)
        if ~any(ret == success)
            [a, str] = calllib(libspec, 'ShamrockGetFunctionReturnDescription', ret, '', 64);
            throw(MException('Inst:CommandFailed', ['Command failed. Error code: ', num2str(ret), '. Explaination: ', str]));
        end
    end
    
    function sp=getSpectrum()
        r=calllib(libcamera,'StartAcquisition');
        check(r);

        while 1
            [r,status]=calllib(libcamera,'GetStatus',0);
            check(r);
            if status ~= 20072
                % Acquisition finished
                break;
            end
            pause(0.1);
        end

        [r, sp] = calllib(libcamera, 'GetAcquiredData', zeros(512,1), 512);
        check(r);
        
        sp=flipud(double(sp));
    end
end

