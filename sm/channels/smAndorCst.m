function inst=smAndorCst(~, varargin)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here

libname = varargin;
success = [20002, 20202];

% Load necessary libraries
for i=1:length(libname)
    lib=libname{i};
    if ~libisloaded(lib)
        fprintf('Loading library %s...', lib);
        loadlibrary(lib,[lib '.h']);
        fprintf('done\n');
    end
end

inst=serial('COM99');

%% Camera initialization

ret=calllib(libname{1}, 'Initialize', '');
check(ret);

pause(2);

ret=calllib(libname{1}, 'CoolerON');
check(ret);

ret=calllib(libname{1}, 'SetAcquisitionMode', 1);
check(ret);

ret=calllib(libname{1}, 'SetReadMode', 0);
check(ret);

ret=calllib(libname{1}, 'SetGateMode', 1);
%check(ret);

ret=calllib(libname{1}, 'SetImage', 1, 1, 1, 512, 1, 1);
check(ret);

ret=calllib(libname{1}, 'SetTriggerMode', 0);
check(ret);

ret = calllib(libname{1}, 'SetExposureTime', 0);
check(ret);

fprintf('Camera Initialization success\n');

%% Spectrometer Initialization

ret=calllib(libname{2}, 'ShamrockInitialize','');
checkspec(ret);

ret=calllib(libname{2}, 'ShamrockSetPixelWidth', 0, 25);
checkspec(ret);

ret=calllib(libname{2}, 'ShamrockSetNumberPixels', 0, 512);
checkspec(ret);

fprintf('Spectrometer Initialization success\n');

%% Check return value
    function check(ret)
        if ~any(ret == success)
            throw(MException('Inst:CommandFailed', ['Command failed. Error code: ', num2str(ret)]));
        end
    end

    function checkspec(ret)
        if ~any(ret == success)
            [a, str] = calllib(libname{2}, 'ShamrockGetFunctionReturnDescription', ret, '', 64);
            throw(MException('Inst:CommandFailed', ['Command failed. Error code: ', num2str(ret), '. Explaination: ', str]));
        end
    end

end

