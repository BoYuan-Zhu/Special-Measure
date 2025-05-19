function varargout = Temperature_Control_Vector_Magnet(varargin)
% TEMPERATURE_CONTROL_VECTOR_MAGNET MATLAB code for Temperature_Control_Vector_Magnet.fig
%      TEMPERATURE_CONTROL_VECTOR_MAGNET, by itself, creates a new TEMPERATURE_CONTROL_VECTOR_MAGNET or raises the existing
%      singleton*.
%
%      H = TEMPERATURE_CONTROL_VECTOR_MAGNET returns the handle to a new TEMPERATURE_CONTROL_VECTOR_MAGNET or the handle to
%      the existing singleton*.
%
%      TEMPERATURE_CONTROL_VECTOR_MAGNET('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in TEMPERATURE_CONTROL_VECTOR_MAGNET.M with the given input arguments.
%
%      TEMPERATURE_CONTROL_VECTOR_MAGNET('Property','Value',...) creates a new TEMPERATURE_CONTROL_VECTOR_MAGNET or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before Temperature_Control_Vector_Magnet_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to Temperature_Control_Vector_Magnet_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help Temperature_Control_Vector_Magnet

% Last Modified by GUIDE v2.5 20-Jun-2017 20:18:21

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @Temperature_Control_Vector_Magnet_OpeningFcn, ...
                   'gui_OutputFcn',  @Temperature_Control_Vector_Magnet_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT

% --- Executes just before Temperature_Control_Vector_Magnet is made visible.
function Temperature_Control_Vector_Magnet_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to Temperature_Control_Vector_Magnet (see VARARGIN)

% Choose default command line output for Temperature_Control_Vector_Magnet
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% This sets up the initial plot - only do when we are invisible
% so window can get raised using Temperature_Control_Vector_Magnet.
if strcmp(get(hObject,'Visible'),'off')
    xlabel(handles.axes1, 'Time');
    ylabel(handles.axes1, 'Temperature (K)');
end

% UIWAIT makes Temperature_Control_Vector_Magnet wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = Temperature_Control_Vector_Magnet_OutputFcn(hObject, eventdata, handles)
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;

% --- Executes on button press in pushbutton1.
function pushbutton1_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
axes(handles.axes1);
cla;

popup_sel_index = get(handles.popupmenu1, 'Value');
switch popup_sel_index
    case 1
        plot(rand(5));
    case 2
        plot(sin(1:0.01:25.99));
    case 3
        bar(1:.5:10);
    case 4
        plot(membrane);
    case 5
        surf(peaks);
end


% --------------------------------------------------------------------
function FileMenu_Callback(hObject, eventdata, handles)
% hObject    handle to FileMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function OpenMenuItem_Callback(hObject, eventdata, handles)
% hObject    handle to OpenMenuItem (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
file = uigetfile('*.fig');
if ~isequal(file, 0)
    open(file);
end

% --------------------------------------------------------------------
function PrintMenuItem_Callback(hObject, eventdata, handles)
% hObject    handle to PrintMenuItem (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
printdlg(handles.figure1)

% --------------------------------------------------------------------
function CloseMenuItem_Callback(hObject, eventdata, handles)
% hObject    handle to CloseMenuItem (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
selection = questdlg(['Close ' get(handles.figure1,'Name') '?'],...
                     ['Close ' get(handles.figure1,'Name') '...'],...
                     'Yes','No','Yes');
if strcmp(selection,'No')
    return;
end

delete(handles.figure1)


% --- Executes on selection change in popupmenu1.
function popupmenu1_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenu1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = get(hObject,'String') returns popupmenu1 contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenu1


% --- Executes during object creation, after setting all properties.
function popupmenu1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenu1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
     set(hObject,'BackgroundColor','white');
end

set(hObject, 'String', {'plot(rand(5))', 'plot(sin(1:0.01:25))', 'bar(1:.5:10)', 'plot(membrane)', 'surf(peaks)'});

function figure1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)



function edit1_Callback(hObject, eventdata, handles)
% hObject    handle to edit1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit1 as text
%        str2double(get(hObject,'String')) returns contents of edit1 as a double


% --- Executes during object creation, after setting all properties.
function edit1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in popupmenu2.
function popupmenu2_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenu2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupmenu2 contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenu2


% --- Executes during object creation, after setting all properties.
function popupmenu2_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenu2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in popupmenu3.
function popupmenu3_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenu3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupmenu3 contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenu3


% --- Executes during object creation, after setting all properties.
function popupmenu3_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenu3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in TCS_COM.
function TCS_COM_Callback(hObject, eventdata, handles)
% hObject    handle to TCS_COM (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns TCS_COM contents as cell array
%        contents{get(hObject,'Value')} returns selected item from TCS_COM


% --- Executes during object creation, after setting all properties.
function TCS_COM_CreateFcn(hObject, eventdata, handles)
% hObject    handle to TCS_COM (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in popupmenu6.
function popupmenu6_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenu6 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupmenu6 contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenu6


% --- Executes during object creation, after setting all properties.
function popupmenu6_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenu6 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in AVS47B_COM.
function AVS47B_COM_Callback(hObject, eventdata, handles)
% hObject    handle to AVS47B_COM (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns AVS47B_COM contents as cell array
%        contents{get(hObject,'Value')} returns selected item from AVS47B_COM


% --- Executes during object creation, after setting all properties.
function AVS47B_COM_CreateFcn(hObject, eventdata, handles)
% hObject    handle to AVS47B_COM (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function name_Callback(hObject, eventdata, handles)
% hObject    handle to name (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of name as text
%        str2double(get(hObject,'String')) returns contents of name as a double


% --- Executes during object creation, after setting all properties.
function name_CreateFcn(hObject, eventdata, handles)
% hObject    handle to name (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in excitation.
function popupmenu8_Callback(hObject, eventdata, handles)
% hObject    handle to excitation (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns excitation contents as cell array
%        contents{get(hObject,'Value')} returns selected item from excitation


% --- Executes during object creation, after setting all properties.
function popupmenu8_CreateFcn(hObject, eventdata, handles)
% hObject    handle to excitation (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in range.
function popupmenu9_Callback(hObject, eventdata, handles)
% hObject    handle to range (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns range contents as cell array
%        contents{get(hObject,'Value')} returns selected item from range


% --- Executes during object creation, after setting all properties.
function popupmenu9_CreateFcn(hObject, eventdata, handles)
% hObject    handle to range (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function calibration_Callback(hObject, eventdata, handles)
% hObject    handle to calibration (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of calibration as text
%        str2double(get(hObject,'String')) returns contents of calibration as a double


% --- Executes during object creation, after setting all properties.
function calibration_CreateFcn(hObject, eventdata, handles)
% hObject    handle to calibration (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes when user attempts to close figure1.
function figure1_CloseRequestFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: delete(hObject) closes the figure

h = get(hObject, 'UserData');

if ishandle(h.timer)
    stop(h.timer);
    delete(h.timer);
end

delete(hObject);


function tcs_update(handles, read)

contents = get(handles.TCS_COM, 'String');
tcs_com = contents{get(handles.TCS_COM, 'Value')};

device = instrfind('Type', 'serial', 'Port', tcs_com, 'Tag', '');

% Create the serial port object if it does not exist
% otherwise use the object that was found.
if isempty(device)
    device = serial(tcs_com);
else
    device = device(1);
end

% Connect to instrument object, obj1.
if ~strcmp(device.Status, 'open')
    fopen(device);
end

% read current status from the TCS
response = str2num(query(device, 'STATUS?'));
    
val = zeros(3,1);
if read == 1
    for chan = 1:3
        range = response(chan*4-1);
        current = response(chan*4);
        on = response(chan*4+1);

        if on == 0
            val(chan) = 0;
        else
            val(chan) = current * 10^(range - 4);
        end    
    end

    % store in GUI fields
    set(handles.current1, 'String', num2str(val(1)));
    set(handles.current2, 'String', num2str(val(2)));
    set(handles.current3, 'String', num2str(val(3)));
else
    % Update the TCS with values in the GUI fields
    % Here we assume the strings are all valid doubles
    val(1) = str2num(get(handles.current1, 'String'));
    val(2) = str2num(get(handles.current2, 'String'));
    val(3) = str2num(get(handles.current3, 'String'));
    
    % Calculate which output(s) to toggle
    setup = zeros(12,1);
    for chan = 1:3
        % Use autorange
        query(device, sprintf('SETDAC %d %d %d', chan, 0, floor(val(chan)*1000)));
        if val(chan) > 0 && response(chan*4+1) == 0 || val(chan) == 0 && response(chan*4+1) == 1
            % Toggle output
            setup(chan * 4 - 1) = 1; 
        end
    end

    % Toggle the output(s)
    setup = sprintf('%d,', setup); setup = setup(1:end-1);
    query(device, sprintf('SETUP %s', setup));
end



% Timer call back for periodic query of the temperature
function avs47b_read_fcn(obj, eventdata)

% fprintf('Fire\n');
hObject = get(obj, 'UserData');

h = get(hObject, 'UserData');
if isfield(h, 'tempData')
    tempData = h.tempData;
else
    tempData = [];
end
if isfield(h, 'timeData')
    timeData = h.timeData;
else
    timeData = [];
end
tn = size(tempData, 1); % Length of existing data

avs47b = findobj(hObject, 'Tag', 'AVS47B_COM');
contents = get(avs47b,'String'); 
avs47b_com = contents{get(avs47b,'Value')};

axes1 = findobj(hObject, 'Type', 'axes');

device = instrfind('Type', 'serial', 'Port', avs47b_com, 'Tag', '');

% Create the serial port object if it does not exist
% otherwise use the object that was found.
if isempty(device)
    device = serial(avs47b_com);
else
    device = device(1);
end

% Connect to instrument object, obj1.
if ~strcmp(device.Status, 'open')
    fopen(device);
end

channel_max = 4;

names = cell(1,4);

for channel = 1:channel_max
    % Read channel resistance
    
    
    % Panel associated with the channel
    panel = findobj(hObject, 'Tag', sprintf('panel%d', channel));
    
    % Get excitation from GUI
    exc = findobj(panel, 'Tag', 'excitation');
    excitation = get(exc, 'Value') - 1;
    
    % Get range from GUI
    rge = findobj(panel, 'Tag', 'range');
    range = get(rge, 'Value') - 1;
    
    % Get calibration from GUI
    calib = findobj(panel, 'Tag', 'calibration');
    calibration = get(calib, 'String');
    
    
    % Get calibration from GUI
    nm = findobj(panel, 'Tag', 'name');
    name = get(nm, 'String');
    names{channel} = name;

    addr = 1;

    config.dref = 0;
    config.remote = 1;
    config.channel = channel-1; % CH1 is actually channel 0, etc.
    config.excitation = excitation; % 30uV excitation
    config.display = 0; % Display R
    config.input = 1; % 0: Zero, 1: Measure
    config.disableal = 1;
    
    
    if ~strcmp(calibration, 'none')
        thispath = mfilename('fullpath');
        [path,~,~] = fileparts(thispath);
        C = load(sprintf('%s/sm/channels/Calibrations/%s.txt', path, calibration), '-ascii');
    end


    datavalid = 0;

    timeout = 30;
    tol = 0.01; % tolerance
    tic;

    oldval = 0;
    change_range = 0;

    while ~datavalid && toc < timeout

        config.range = range; % Set range

        avs47Configure(device, addr, config);

        if change_range
            % Add 5s after 
            set(rge, 'Value', range + 1);
            pause(5);
        end

        result = avs47Read(device, addr, config);

        val = result.res;


        if (range == 7 || ~result.overrange) && (range == 1 || val >= 0.02*10^range) % Appropriate range (>10% max range), or minimum range already reached
            if abs(oldval - val) < tol * oldval
                datavalid = 1;
            end
            oldval = val;
            change_range = 0;
        elseif result.overrange
            % Range up
            range = range + 1;
            change_range = 1;
        else
            % Range down
            range = range - 1;
            change_range = 1;
        end

    end
    
    
    if ~strcmp(calibration, 'none')
        val = interp1(C(:,1), C(:,2), val, 'pchip');
    end
    
    tempData(tn+1, channel) = val;
end

time = datetime;
timeData = [timeData; time];

% Truncate tempData
if size(tempData, 1) > 100000
    tempData = tempData(end-100000+1:end, :);
    timeData = timeData(end-100000+1:end, :);
end

% Plot temperature
t = datenum(timeData);
semilogy(axes1, t(:), tempData/1000, '-o');
datetick(axes1, 'x', 'mm/dd HH:MM:SS');
legend(axes1,names);
ylabel(axes1, 'Temperature (K)');

% Save data back
h.tempData = tempData;
h.timeData = timeData;
set(hObject, 'UserData', h);


% --- Executes on button press in startbutton.
function startbutton_Callback(hObject, eventdata, handles)
% hObject    handle to startbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


t = timer('Name', 'Temperature_Control_Timer', 'Period', 1, ...
    'ExecutionMode', 'fixedSpacing', 'TimerFcn', @avs47b_read_fcn, 'UserData', handles.figure1);

% startat(t, now+2/60^2*24);

h.timer = t;
h.timeData = [];
h.tempData = [];

set(hObject, 'UserData', h);

set(hObject, 'Enable', 'off');

tcs_update(handles, 1);


start(t);



function edit6_Callback(hObject, eventdata, handles)
% hObject    handle to edit6 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit6 as text
%        str2double(get(hObject,'String')) returns contents of edit6 as a double


% --- Executes during object creation, after setting all properties.
function edit6_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit6 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in excitation.
function excitation_Callback(hObject, eventdata, handles)
% hObject    handle to excitation (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns excitation contents as cell array
%        contents{get(hObject,'Value')} returns selected item from excitation


% --- Executes during object creation, after setting all properties.
function excitation_CreateFcn(hObject, eventdata, handles)
% hObject    handle to excitation (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in range.
function range_Callback(hObject, eventdata, handles)
% hObject    handle to range (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns range contents as cell array
%        contents{get(hObject,'Value')} returns selected item from range


% --- Executes during object creation, after setting all properties.
function range_CreateFcn(hObject, eventdata, handles)
% hObject    handle to range (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit7_Callback(hObject, eventdata, handles)
% hObject    handle to edit7 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit7 as text
%        str2double(get(hObject,'String')) returns contents of edit7 as a double


% --- Executes during object creation, after setting all properties.
function edit7_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit7 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit12_Callback(hObject, eventdata, handles)
% hObject    handle to name (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of name as text
%        str2double(get(hObject,'String')) returns contents of name as a double


% --- Executes during object creation, after setting all properties.
function edit12_CreateFcn(hObject, eventdata, handles)
% hObject    handle to name (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit10_Callback(hObject, eventdata, handles)
% hObject    handle to name (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of name as text
%        str2double(get(hObject,'String')) returns contents of name as a double


% --- Executes during object creation, after setting all properties.
function edit10_CreateFcn(hObject, eventdata, handles)
% hObject    handle to name (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit8_Callback(hObject, eventdata, handles)
% hObject    handle to name (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of name as text
%        str2double(get(hObject,'String')) returns contents of name as a double


% --- Executes during object creation, after setting all properties.
function edit8_CreateFcn(hObject, eventdata, handles)
% hObject    handle to name (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function current1_Callback(hObject, eventdata, handles)
% hObject    handle to current1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of current1 as text
%        str2double(get(hObject,'String')) returns contents of current1 as a double
[x, status] = str2num(get(hObject, 'String'));

if status == 0 || numel(x) ~= 1
    % Invalid input
    x = 0;
end

set(hObject, 'String', num2str(x));

% Update the TCS
tcs_update(handles, 0);


% --- Executes during object creation, after setting all properties.
function current1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to current1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function current2_Callback(hObject, eventdata, handles)
% hObject    handle to current2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of current2 as text
%        str2double(get(hObject,'String')) returns contents of current2 as a double
[x, status] = str2num(get(hObject, 'String'));

if status == 0 || numel(x) ~= 1
    % Invalid input
    x = 0;
end

set(hObject, 'String', num2str(x));

% Update the TCS
tcs_update(handles, 0);

% --- Executes during object creation, after setting all properties.
function current2_CreateFcn(hObject, eventdata, handles)
% hObject    handle to current2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function current3_Callback(hObject, eventdata, handles)
% hObject    handle to current3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of current3 as text
%        str2double(get(hObject,'String')) returns contents of current3 as a double
[x, status] = str2num(get(hObject, 'String'));

if status == 0 || numel(x) ~= 1
    % Invalid input
    x = 0;
end

set(hObject, 'String', num2str(x));

% Update the TCS
tcs_update(handles, 0);

% --- Executes during object creation, after setting all properties.
function current3_CreateFcn(hObject, eventdata, handles)
% hObject    handle to current3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
