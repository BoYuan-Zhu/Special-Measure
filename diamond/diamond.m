function varargout = diamond(varargin)
% DIAMPLUS_V2G M-filename for diamplus_v2g.fig
% Last Modified by GUIDE v2.5 02-Sep-2006 15:49:17
% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @diamond_OpeningFcn, ...
                   'gui_OutputFcn',  @diamond_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin & isstr(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT

function makebutton(fighandle)
copyhandle=uicontrol(gcf,'Style','pushbutton','string','copy',...
    'Position',[5 5 50 20],'Callback',@Copyfigure);
savehandle=uicontrol(gcf,'Style','pushbutton','string','save',...
    'Position',[60 5 50 20],'Callback',@Savefigure);
colormaphandle=uicontrol(gcf,'Style','pushbutton','string','color',...
    'Position',[115 5 50 20],'Callback',@Colormaped);
propshandle=uicontrol(gcf,'Style','pushbutton','string','props',...
    'Position',[170 5 70 20],'Callback',@properties);
colormin=uicontrol(gcf,'Style','edit','string','0',...
    'Position',[0 0 1 1]);
colormax=uicontrol(gcf,'Style','edit','string','1',...
    'Position',[0 0 1 1]);

set(colormin,'visible','off');
set(colormax,'visible','off');
set(gcf,'Toolbar','figure');

function invisible()
copyhandle=findobj(gcf,'String','copy'); %temporarily make buttons invisible
savehandle=findobj(gcf,'String','save');
colorhandle=findobj(gcf,'String','color');
prophandle=findobj(gcf,'String','props');
set(copyhandle,'visible','off');
set(savehandle,'visible','off');
set(colorhandle,'visible','off');
set(prophandle,'visible','off');

function visible()
copyhandle=findobj(gcf,'String','copy'); %temporarily make buttons invisible
savehandle=findobj(gcf,'String','save');
colorhandle=findobj(gcf,'String','color');
prophandle=findobj(gcf,'String','props');
set(copyhandle,'visible','on');
set(savehandle,'visible','on');
set(colorhandle,'visible','on');
set(prophandle,'visible','on');

function Copyfigure(src,eventdata)
invisible
print -dbitmap;                 % copy figure to clipboard
visible

function crossection(src,eventdata)


function Colormaped(src,eventdata)

function Savefigure(src,eventdata)
hObject=findobj('name','diamond');
if isempty(hObject)
    delete(gcbo)
    return
end
handles=guidata(hObject);

%invisiblecolormapeditor
FType={'jpg','fig','bmp','eps','emf','tif'};
Selection=handles.figureformat;

switch gcf
    case handles.ivplot
        filestring=[handles.fileonly '_yplot.' char(FType(Selection))];
        filenum=1;
    case handles.dyplot
         filestring=[handles.fileonly '_dyplot.' char(FType(Selection))];
         filenum=2;
    case handles.lineplotiv
         filestring=[handles.fileonly '_ylineplot.' char(FType(Selection))];
         filenum=3;
    case handles.lineplotdy
         filestring=[handles.fileonly '_dylineplot.' char(FType(Selection))];
         filenum=4;
    otherwise
        test=checkforwrite([handles.fileonly '.' char(Selection)],handles.savedirectory,6);
        if test==1|test==2
            saveas(gcf,[handles.savedirectory '\' handles.fileonly '.' char(Selection)]);
        end
        set(copyhandle,'visible','on');
        set(savehandle,'visible','on');
        return
end
       
test=checkforwrite(filestring,handles.savedirectory,filenum);

if test==1|test==2
    saveas(gcf,[handles.savedirectory '\' filestring]);
end

visible
guidata(hObject,handles);

function properties(src,eventdata)
propedt(gca);

% --- Executes on button press in smooth.
function smooth_Callback(hObject, eventdata, handles)
ymatrix=handles.ymatrix;
Sy=str2num(get(handles.smoothy,'string'));
Sx=str2num(get(handles.smoothx,'string'));   %smoothing x
smooth=ones(Sy,Sx)/(Sy*Sx);
ymatrix_sm=imfilter(ymatrix,smooth,'replicate','conv');
handles.ymatrix_sm=ymatrix_sm;
handles.ymatrixoriginal=ymatrix_sm;

% calculate DY
N1=handles.N1;

sweepstart=str2double(get(handles.sweepmin,'string'));
sweepend=str2double(get(handles.sweepmax,'string'));
sweep=sweepstart-(-sweepend+sweepstart)*((1:N1)-1)/(N1-1);
delta_v=sweep(2)-sweep(1);

dif=[1 -1]';    %180 degrees rotated for derivative.
ymatrix_d=imfilter(ymatrix_sm,dif,'replicate','conv');
ymatrix_d=ymatrix_d/delta_v;
handles.ymatrix_d=ymatrix_d;
handles.ymatrix_doriginal=ymatrix_d;
set(handles.plotiv,'Enable','on'); 
set(handles.plotdy,'Enable','on');
set(handles.pushresety,'enable','on');
set(handles.pushresetdy,'enable','on');
set(handles.pusheqy,'enable','on');
set(handles.pusheqdy,'enable','on');
set(handles.pushconvolute,'enable','on');
set(handles.pushconvoluteDY,'enable','on');
set(handles.Menu_deletelast,'enable','on');
set(handles.info,'string','Press Plot IV to draw colorplot or go to the DY tab for derivative.');

%new 10th October 2005:
resety()
resetdy()

ybutton_Callback(gcbo,[],guidata(gcbo))

guidata(hObject, handles);

% --- Executes on button press in plotiv.
function plotiv_Callback(hObject, eventdata, handles)
%a=findobj('name','Figure')

%close all
N1=handles.N1;
N2=handles.N2;
loopstart=str2double(get(handles.loopmin,'string'));
loopend=str2double(get(handles.loopmax,'string'));
loop1=loopstart-(-loopend+loopstart)*((1:N2)-1)/(N2-1);
sweepstart=str2double(get(handles.sweepmin,'string'));
sweepend=str2double(get(handles.sweepmax,'string'));
sweep=sweepstart-(-sweepend+sweepstart)*((1:N1)-1)/(N1-1);
handles.caxis_iv=[0 1];

handles.ivplot=figure('CloseRequestFcn',{@closey},'KeyPressFcn',{@KeyPress}, ...
    'WindowButtonDownFCN',{@MousePress},'WindowButtonUpFcn',{@MouseUp});
makebutton(handles.ivplot);

ymatrix_sm=handles.ymatrix_sm;
imagesc(loop1,sweep,ymatrix_sm);
%pcolor(loop1,sweep,ymatrix_sm);

figpos=handles.plotpos;
set(gcf,'position',figpos);
colormap(hot(200));
caxis1=caxis;
handles.caxis_iv=caxis1;
handles.sweep=sweep;
handles.loop1=loop1;
shading flat;
cmin=num2str(caxis1(1),'%11.4g');
cmax=num2str(caxis1(2),'%11.4g');
set(handles.ivcmin,'string',cmin);
set(handles.ivcmax,'string',cmax);
set(handles.ivcmin,'enable','on');
set(handles.ivcmax,'enable','on');
set(handles.ivcmap,'enable','on');
set(handles.plotlineiv,'enable','on');
set(handles.ivfiddleman,'enable','on');
set(handles.Fiddleiv,'enable','off');
set(handles.plotdy,'Enable','on');
set(handles.ivmouseline,'value',0);
set(handles.ivmouseline,'enable','off');
set(handles.ivfiddleman,'value',0);
set(handles.ivcol,'value',0);
set(handles.ivcol,'enable','off');
set(handles.text30,'enable','off');
set(handles.ivlocky,'value',0);
set(handles.ivlocky,'enable','off');
set(handles.ivtext1,'enable','off');
set(handles.ivterxt2,'enable','off');
set(handles.ivymin,'value',0);
set(handles.ivymax,'value',0);
set(handles.ivymin,'enable','off');
set(handles.ivymax,'enable','off');
set(handles.ivcol,'string',1);
set(handles.Menu_exportY,'enable','on');
set(handles.info,'String','Press Fiddle to change color with mouse or press Line Graph.');

set(gca,'ydir','normal');

handles.line=-1;

IVtitle=['2D-plot: ' get(handles.title,'string')];
texthandle=text(1,1,IVtitle,'Interpreter','none');
set(gca,'Title',texthandle);
xlabel(get(handles.xtitle,'string'));
ylabel(get(handles.ytitle,'string'));

guidata(hObject, handles);

% ----------------------------------------------------------
function closey(src,eventdata)
hObject=findobj('name','diamond');
if isempty(hObject)
    delete(gcf)
    return
end
handles=guidata(hObject);
test=gcf;
delete(gcf);
if test==handles.ivplot
    resety();
end

% ----------------------------------------------------------
function closeliney(src,eventdata)
hObject=findobj('name','diamond');
if isempty(hObject)
    delete(gcf)
    return
end
handles=guidata(hObject);

if gcf==handles.lineplotiv
    set(handles.ivmouseline,'value',0);
    set(handles.ivmouseline,'enable','off');
    set(handles.ivlocky,'value',0);
    set(handles.ivlocky,'enable','off');
    set(handles.ivcol,'string',1);
    set(handles.ivcol,'enable','off');
    set(handles.ivymin,'string',0);
    set(handles.ivymin,'enable','off');
    set(handles.ivymax,'string',0);
    set(handles.ivymax,'enable','off');
    set(handles.ivtoggle,'enable','off');
    set(handles.ivtoggle,'value',0);
    handles.lineplotiv=-1;
    if handles.line~=-1
        delete(handles.line)
        handles.line=-1;
    end
end

delete(gcf);
guidata(hObject,handles);

% ----------------------------------------------------------
function closedy(src,eventdata)
hObject=findobj('name','diamond');
if isempty(hObject)
    delete(gcf)
    return
end
handles=guidata(hObject);
test=gcf;
delete(gcf);
if test==handles.dyplot
    resetdy();
end

% ----------------------------------------------------------
function closelinedy(src,eventdata)
hObject=findobj('name','diamond');
if isempty(hObject)
    delete(gcf)
    return
end
handles=guidata(hObject);

if gcf==handles.lineplotdy
    set(handles.dymouseline,'value',0);
    set(handles.dymouseline,'enable','off');
    set(handles.dylocky,'value',0);
    set(handles.dylocky,'enable','off');
    set(handles.dycol,'string',1);
    set(handles.dycol,'enable','off');
    set(handles.dyymin,'string',0);
    set(handles.dyymin,'enable','off');
    set(handles.dyymax,'string',0);
    set(handles.dyymax,'enable','off');
    set(handles.dytoggle,'enable','off');
    set(handles.dytoggle,'value',0);
    handles.lineplotdy=-1;
    if handles.linedy~=-1
        delete(handles.linedy);
        handles.linedy=-1;
    end
end

delete(gcf);
guidata(hObject,handles);

% ----------------------------------------------------------
function resety()
hObject=findobj('name','diamond');
handles=guidata(hObject);
set(handles.ivcol,'enable','off');
set(handles.text30,'enable','off');
set(handles.ivlocky,'value',0);
set(handles.ivlocky,'enable','off');
set(handles.ivtext1,'enable','off');
set(handles.ivterxt2,'enable','off');
set(handles.ivymin,'value',0);
set(handles.ivymax,'value',0);
set(handles.ivymin,'enable','off');
set(handles.ivymax,'enable','off');
set(handles.ivcol,'string',1);
set(handles.ivmouseline,'value',0);
set(handles.ivmouseline,'enable','off');
set(handles.ivfiddleman,'value',0);
set(handles.ivfiddleman,'enable','off');
set(handles.plotlineiv,'enable','off');
set(handles.ivcmap,'enable','off');
set(handles.ivcmin,'string',0);
set(handles.ivcmin,'enable','off');
set(handles.ivcmax,'string',0);
set(handles.ivcmax,'enable','off');
set(handles.ivtoggle,'value',0);
set(handles.ivtoggle,'enable','off');
if handles.lineplotiv~=-1
    handles.lineplotiv=-1;
end
handles.line=-1;
handles.ivplot=-1;
guidata(hObject, handles);

% ----------------------------------------------------------
function resetdy()
hObject=findobj('name','diamond');
handles=guidata(hObject);
set(handles.Fiddleiv,'enable','off');
set(handles.dymouseline,'value',0);
set(handles.dymouseline,'enable','off');
set(handles.dyfiddleman,'value',0);
set(handles.dycol,'value',0);
set(handles.dycol,'enable','off');
set(handles.fixed28,'enable','off');
set(handles.dylocky,'value',0);
set(handles.dylocky,'enable','off');
set(handles.dytext1,'enable','off');
set(handles.dytext2,'enable','off');
set(handles.dyymin,'value',0);
set(handles.dyymax,'value',0);
set(handles.dyymin,'enable','off');
set(handles.dyymax,'enable','off');
set(handles.dycol,'string',1);
set(handles.dymouseline,'value',0);
set(handles.dymouseline,'enable','off');
set(handles.dyfiddleman,'value',0);
set(handles.dyfiddleman,'enable','off');
set(handles.plotlinedy,'enable','off');
set(handles.dycmap,'enable','off');
set(handles.dycmin,'string',0);
set(handles.dycmin,'enable','off');
set(handles.dycmax,'string',0);
set(handles.dycmax,'enable','off');
set(handles.dytoggle,'enable','off');
set(handles.dytoggle,'value',0);
set(handles.fixed28,'String','Col:');
handles.linedy=-1;
handles.dyplot=-1;
if handles.lineplotdy~=-1
    handles.lineplotdy=-1;
end
guidata(hObject, handles);

% ----------------------------------------------------------
function KeyPress(src,evetdata)
hObject=findobj('name','diamond');
handles=guidata(hObject);
key=double((get(gcf,'CurrentCharacter')));

if ((gcf==handles.ivplot | gcf==handles.lineplotiv) & get(handles.ivmouseline,'value')==1 )
    col=str2num(get(handles.ivcol,'string'));
    if (get(handles.ivtoggle,'value')==0)
        max=handles.N2;
    else
        max=handles.N1;
    end
    if ((key==28 | key==31)& col>1)
        set(handles.ivcol,'string',col-1);
        updatelineiv();
    end
    if ((key==29 | key==30) & col<max)
        set(handles.ivcol,'string',col+1);
        updatelineiv();
    end
end  

if ((gcf==handles.dyplot | gcf==handles.lineplotdy) & get(handles.dymouseline,'value')==1 )
   col=str2num(get(handles.dycol,'string'));
   if (get(handles.dytoggle,'value')==0)
        max=handles.N2;
    else
        max=handles.N1;
    end
    if ((key==28 | key==31) & col>1)
           set(handles.dycol,'string',col-1);
        updatelinedy();
    end
    if ((key==29 | key==30) & col<max)
           set(handles.dycol,'string',col+1);
        updatelinedy();
    end
end 
guidata(hObject, handles);    

% ----------------------------------------------------------
function MousePress(src,eventdata)
hObject=findobj('name','diamond');
handles=guidata(hObject);
global cminold cmaxold mouseposold

if (handles.ivplot==gcbo & (get(handles.ivfiddleman,'value')==1))
    set(handles.Fiddleiv,'enable','on');%enable fiddle when mouse button is pressed
    pos=get(gcbo,'CurrentPoint');        %get position of current figure
    mouseposold=pos;
    set(gcf,'WindowButtonMotionFcn',{@MouseMotion}); %enable mouse motion routine
    a=caxis;
    cminold=a(1);
    cmaxold=a(2);
    guidata(hObject, handles);          %save handles variable
end

if (handles.dyplot==gcbo & (get(handles.dyfiddleman,'value')==1))
    set(handles.Fiddledy,'enable','on'); %enable fiddle when mouse button is pressed
    pos=get(gcbo,'CurrentPoint');        %get position of current figure
    mouseposold=pos;
    set(gcf,'WindowButtonMotionFcn',{@MouseMotion}); %enable mouse motion routine
    a=caxis;
    cminold=a(1);
    cmaxold=a(2);
    guidata(hObject, handles);          %save handles variable
   
end

mouse=0;
if gcbo==handles.ivplot                      % test if mouse line is enabled
    mouse=get(handles.ivmouseline,'Value');
end

if mouse==1                                         % test for entering mouse line routine
    pos=get(gca,'CurrentPoint');
    if get(handles.ivtoggle,'value')==0
        if handles.loop1(1)<handles.loop1(2)
            col=find((handles.loop1-pos(1,1))>0,1,'first'); % determine current column from mouse pos
        else
            col=find((handles.loop1-pos(1,1))<0,1,'first'); % determine current column from mouse pos
        end
        if (col>=1 & col<=size(handles.loop1,2))
            set(handles.ivcol,'string',col);
            updatelineiv();
        end
    else
        if handles.sweep(1)<handles.sweep(2)
            col=find((handles.sweep-pos(1,2))>0,1,'first');
        else
            col=find((handles.sweep-pos(1,2))<0,1,'first');
        end
        if (col>=1 & col<=size(handles.sweep,2))
             set(handles.ivcol,'string',col);
             updatelineiv();
        end
    end
    drawnow;
    figure(gcbo);
end

mouse=0;
if gcbo==handles.dyplot
    mouse=get(handles.dymouseline,'Value');
end

if mouse==1                                         % test for entering mouse line routine
    pos=get(gca,'CurrentPoint');
    if get(handles.dytoggle,'value')==0
        if handles.loop1(1)<handles.loop1(2)
            col=find((handles.loop1-pos(1,1))>0,1,'first'); % determine current column from mouse pos
        else
            col=find((handles.loop1-pos(1,1))<0,1,'first'); % determine current column from mouse pos
        end
        if (col>=1 & col<=size(handles.loop1,2))
            set(handles.dycol,'string',col);
            updatelinedy();
        end
    else
        if handles.sweep(1)<handles.sweep(2)
            col=find((handles.sweep-pos(1,2))>0,1,'first');
        else
            col=find((handles.sweep-pos(1,2))<0,1,'first');
        end
        if (col>=1 & col<=size(handles.sweep,2))
             set(handles.dycol,'string',col);
             updatelinedy();
        end
    end
    drawnow;
    figure(gcbo);
end

% ----------------------------------------------------------
function MouseUp(src,eventdata)
hObject=findobj('name','diamond');
handles=guidata(hObject);
set(handles.Fiddleiv,'enable','off'); %disable fiddle when mouse button is NOT pressed
set(handles.Fiddledy,'enable','off');
test=0;
if gcf==handles.ivplot
    set(gcf,'WindowButtonMotionFcn',''); 
    if get(handles.ivfiddleman,'value')==1
        test=1;
    end
else
    set(gcf,'WindowButtonMotionFcn',''); 
    if get(handles.dyfiddleman,'value')==1
        test=1;
    end
end

if test==1         % check if  fiddle was enabled
    figure(gcf);
    a=caxis;
    cmin=num2str(a(1),'%11.4g');
    cmax=num2str(a(2),'%11.4g');
    if gcf==handles.ivplot
        set(handles.ivcmin,'string',cmin);
        set(handles.ivcmax,'string',cmax);
    else
        set(handles.dycmin,'string',cmin);
        set(handles.dycmax,'string',cmax);
    end
end
% ----------------------------------------------------------
function MouseMotion(src,eventdata)
hObject=findobj('name','diamond');
handles=guidata(hObject);
global cminold cmaxold mouseposold

average=(cminold+cmaxold)/2;
delta=cmaxold-cminold;
pos=get(gcbo,'CurrentPoint');
sens=get(handles.FiddleSens,'value');
relpos=[pos(1)-mouseposold(1) pos(2)-mouseposold(2)];
contrast=1-relpos(1)/100*sens;
offset=-relpos(2)/100*sens;
if contrast<=0
     contrast=1e-12;
end
caxisnewmin=average-contrast*delta/2+offset*delta/2;
caxisnewmax=average+contrast*delta/2+offset*delta/2;
caxis([caxisnewmin caxisnewmax]);   % define new caxis values

% --- Executes on button press in plotlineiv.
function plotlineiv_Callback(hObject, eventdata, handles)
handles.lineplotiv=figure('CloseRequestFcn',{@closeliney},'KeyPressFcn',{@KeyPress});
makebutton(handles.lineplotiv);

set(handles.ivcol,'Enable','on');
set(gcf,'position',handles.lineplotpos);
set(handles.ivmouseline,'enable','on');
set(handles.ivlocky,'enable','on');
set(handles.ivymin,'enable','on');
set(handles.ivymax,'enable','on');
set(handles.ivtext1,'enable','on');
set(handles.ivterxt2,'enable','on');
set(handles.text30,'enable','on');
set(handles.ivcol,'string',1);   
set(handles.ivtoggle,'enable','on');
set(handles.info,'string','Change column number or enable Active line to use the mouse.');

guidata(hObject, handles);

updatelineiv();
figure(handles.ivplot);
guidata(hObject, handles);

% --- Executes on button press in ivlocky.
function ivlocky_Callback(hObject, eventdata, handles)
figure(handles.lineplotiv);
ylim=get(gca,'ylim');
set(handles.ivymin,'String',num2str(ylim(1)));
set(handles.ivymax,'String',num2str(ylim(2)));
figure(handles.ivplot);
guidata(hObject, handles);

% ----------------------------------------------------------
function updatelineiv()
hObject=findobj('name','diamond');
handles=guidata(hObject);
figure(handles.ivplot);
toggle=get(handles.ivtoggle,'value');
xlim=get(gca,'ylim');
ylim=get(gca,'xlim'); %-
if handles.lineplotiv==-1
    handles.lineplotiv=figure('CloseRequestFcn',{@closeliney},'KeyPressFcn',{@KeyPress});
end
figure(handles.lineplotiv);
ymatrix_sm=handles.ymatrix_sm;
locky=get(handles.ivlocky,'Value');
col=str2num(get(handles.ivcol,'string'));
hold off;

if toggle==0
    plot(handles.sweep,ymatrix_sm(:,col));
    set(gca,'xlim',xlim);
    xt=get(handles.xtitle,'string');
    title([xt,' = ' num2str(handles.loop1(col))]);
    xlabel(get(handles.ytitle,'string'));
    ylabel('Data');
    if locky==1
        set(gca,'YLimMode','manual');
        ymin=str2num(get(handles.ivymin,'String'));
        ymax=str2num(get(handles.ivymax,'String'));
        try
            set(gca,'Ylim',[ymin ymax]);
        catch
            errordlg('Axis values should be increasing!');
        end
    end
else
    plot(handles.loop1,ymatrix_sm(col,:));
    set(gca,'xlim',ylim);
    xt=get(handles.ytitle,'string');
    title([xt,' = ' num2str(handles.sweep(col))]);
    xlabel(get(handles.xtitle,'string'));
    ylabel('Data');
    if locky==1
        set(gca,'YLimMode','manual');
        ymin=str2num(get(handles.ivymin,'String'));
        ymax=str2num(get(handles.ivymax,'String'));
        try
            set(gca,'Ylim',[ymin ymax]);
        catch
            errordlg('Axis values should be increasing!');
        end
    end
end

if handles.line>0
    switch toggle
        case 0
            linepos_x=handles.loop1(col);
            set(handles.line,'xdata',[linepos_x linepos_x]);
            set(handles.line,'ydata',xlim);
            
        case 1
            linepos_y=handles.sweep(col);
            set(handles.line,'xdata',ylim);
            set(handles.line,'ydata',[linepos_y linepos_y]);
    end
    set(handles.line,'LineWidth',handles.linewidth);
    set(handles.line,'Color',handles.linecolor);
    figure(handles.ivplot);
end
guidata(hObject, handles);

function ivymax_Callback(hObject, eventdata, handles)
updatelineiv()

% --- Executes on button press in plotdy.
function plotdy_Callback(hObject, eventdata, handles)
N1=handles.N1;
N2=handles.N2;
loopstart=str2double(get(handles.loopmin,'string'));
loopend=str2double(get(handles.loopmax,'string'));
loop1=loopstart-(-loopend+loopstart)*((1:N2)-1)/(N2-1);
sweepstart=str2double(get(handles.sweepmin,'string'));
sweepend=str2double(get(handles.sweepmax,'string'));
sweep=sweepstart-(-sweepend+sweepstart)*((1:N1)-1)/(N1-1);
delta_v=sweep(2)-sweep(1);
handles.dyplot=figure('CloseRequestFcn',{@closedy}, ...
    'KeyPressFcn',{@KeyPress},'WindowButtonDownFCN',{@MousePress},...
    'WindowButtonUpFcn',{@MouseUp});
makebutton(handles.dyplot);

%ymatrix_sm=handles.ymatrix_sm;
ymatrix_d=handles.ymatrix_d; 
imagesc(loop1,sweep,ymatrix_d);
%pcolor(loop1,sweep,ymatrix_d);
colormap(hot(200));
shading flat;
set(gcf,'position',handles.plotpos);
texthandle=text(1,1,['Diff: ' get(handles.title,'string')],'Interpreter','none'); 
set(gca,'Title',texthandle);
xlabel(get(handles.xtitle,'string'));
ylabel(get(handles.ytitle,'string'));
caxis1=caxis;
cmin=num2str(caxis1(1),'%5.2e');
cmax=num2str(caxis1(2),'%5.2e');
set(handles.dycmin,'string',cmin);
set(handles.dycmax,'string',cmax);
set(handles.dycmin,'enable','on');
set(handles.dycmax,'enable','on');
set(handles.plotlinedy,'enable','on');
set(handles.dycmap,'enable','on');
set(handles.dyfiddleman,'enable','on'); 
set(handles.Fiddleiv,'enable','off');
set(handles.dymouseline,'value',0);
set(handles.dymouseline,'enable','off');
set(handles.dyfiddleman,'value',0);
set(handles.dycol,'value',0);
set(handles.dycol,'enable','off');
set(handles.fixed28,'enable','off');
set(handles.dylocky,'value',0);
set(handles.dylocky,'enable','off');
set(handles.dytext1,'enable','off');
set(handles.dytext2,'enable','off');
set(handles.dyymin,'value',0);
set(handles.dyymax,'value',0);
set(handles.dyymin,'enable','off');
set(handles.dyymax,'enable','off');
set(handles.dycol,'string',1);
set(handles.Menu_exportDY,'enable','on');
set(handles.info,'String','Adjust colormap settings or press fiddle to change color with mouse.');
set(gca,'ydir','normal');
handles.linedy=-1;

handles.caxis_dy=caxis;
handles.sweep=sweep;
handles.loop1=loop1;
guidata(hObject, handles);

% --- Executes on button press in plotlinedy.
function plotlinedy_Callback(hObject, eventdata, handles)
figure(handles.dyplot);
handles.lineplotdy=figure('CloseRequestFcn',{@closelinedy},'KeyPressFcn',{@KeyPress});
makebutton(handles.lineplotdy);

plot(handles.sweep,handles.ymatrix_d(:,1));
title([num2str(get(handles.xtitle,'string')) '= ' num2str(handles.loop1(1))]);
xlabel(get(handles.ytitle,'string'));
ylabel(['Diff. ( ' num2str(get(handles.ytitle,'string')) ' )']);
set(gcf,'position',handles.lineplotpos);
set(handles.dycol,'Enable','on');
set(handles.dylocky,'Enable','on');
set(handles.dyymin,'Enable','on');
set(handles.dyymax,'Enable','on');
set(handles.dymouseline,'Enable','on');
set(handles.dytext1,'enable','on');
set(handles.dytext2,'enable','on');
set(handles.fixed28,'enable','on');
set(handles.dytoggle,'enable','on');
set(handles.info,'string','Change column number or enable Active to use the mouse.');
guidata(hObject, handles);

function ivcmin_Callback(hObject, eventdata, handles)
cmax=str2double(get(handles.ivcmax,'string'));
cmin=str2double(get(handles.ivcmin,'string'));
figure(handles.ivplot);
try
    caxis([cmin cmax]);
catch
    errordlg('Color axis should be increasing!')
end
handles.caxis_IV=[cmin cmax];
guidata(hObject, handles);

function ivcmax_Callback(hObject, eventdata, handles)
cmax=str2double(get(handles.ivcmax,'string'));
cmin=str2double(get(handles.ivcmin,'string'));
figure(handles.ivplot);
try
    caxis([cmin cmax]);
catch
    errordlg('Color axis should be increasing!')
end
handles.caxis_IV=[cmin cmax];
guidata(hObject, handles);

function dycmin_Callback(hObject, eventdata, handles)
cmax=str2double(get(handles.dycmax,'string'));
cmin=str2double(get(handles.dycmin,'string'));
figure(handles.dyplot);
try
    caxis([cmin cmax]);
catch
    errordlg('Color axis should be increasing!')
end

function dycmax_Callback(hObject, eventdata, handles)
cmax=str2double(get(handles.dycmax,'string'));
cmin=str2double(get(handles.dycmin,'string'));
figure(handles.dyplot);
try
    caxis([cmin cmax]);
catch
    errordlg('Color axis should be increasing!')
end

function export_Callback(hObject, eventdata, handles)
data.ymatrix=handles.ymatrix;
data.ymatrix_sm=handles.ymatrix_sm;
data.ymatrix_d=handles.ymatrix_d;
data.N1=handles.N1;
data.N2=handles.N2;
data.sweep=handles.sweep;
data.loop1=handles.loop1;
data.title=get(handles.title,'string');
data.xlabel=get(handles.xtitle,'string');
data.ylabel=get(handles.ytitle,'string');
if handles.ivplot ~= -1
    figure(handles.ivplot);
    data.cmap_iv=colormap;
end; 
if handles.dyplot ~= -1
    figure(handles.dyplot);
    data.cmap_dy=colormap;
end;
assignin('base','data',data);

function dycol_Callback(hObject, eventdata, handles)
col=round(str2num(get(handles.dycol,'string')));
N2=handles.N2;
N1=handles.N1;
if get(handles.dytoggle,'value')==0
    if col>N2
        col=N2;
    end
else
    if col>N1
        col=N1;
    end
end
if col<1
    col=1;
end
set(handles.dycol,'string',col);
updatelinedy()

% ----------------------------------------------------------
function updatelinedy()
hObject=findobj('name','diamond');
handles=guidata(hObject);
figure(handles.dyplot);         %activate dyplot to find ylim
ylim=get(gca,'ylim');
xlim=get(gca,'xlim');
toggle=get(handles.dytoggle,'value');
figure(handles.lineplotdy);
ymatrix_d=handles.ymatrix_d;
locky=get(handles.dylocky,'Value');
col=str2num(get(handles.dycol,'string'));  
hold off;

if toggle==0
    plot(handles.sweep,ymatrix_d(:,col));
    set(gca,'xlim',ylim);
    xt=get(handles.xtitle,'string');
    title([xt,' = ' num2str(handles.loop1(col))]);
    xlabel(get(handles.ytitle,'string'));
    ylabel('Diff. (Data)');
    if locky==1
        set(gca,'YLimMode','manual');
        ymin=str2num(get(handles.dyymin,'String'));
        ymax=str2num(get(handles.dyymax,'String'));
        try
            set(gca,'Ylim',[ymin ymax]);
        catch
            errordlg('Axis values should be increasing!');
        end
    end
else
    plot(handles.loop1,ymatrix_d(col,:));
    set(gca,'xlim',xlim);
    xt=get(handles.ytitle,'string');
    title([xt,' = ' num2str(handles.sweep(col))]);
    xlabel(get(handles.xtitle,'string'));
    ylabel('Diff. (Data)');
    if locky==1
        set(gca,'YLimMode','manual');
        ymin=str2num(get(handles.dyymin,'String'));
        ymax=str2num(get(handles.dyymax,'String'));
        try
            set(gca,'Ylim',[ymin ymax]);
        catch
            errordlg('Axis values should be increasing!');
        end
    end
end
    
if handles.linedy>0
    switch toggle
        case 0
            linepos_x=handles.loop1(col);
            set(handles.linedy,'xdata',[linepos_x linepos_x]);
            set(handles.linedy,'ydata',ylim);
            
        case 1
            linepos_y=handles.sweep(col);
            set(handles.linedy,'xdata',xlim);
            set(handles.linedy,'ydata',[linepos_y linepos_y]);
    end
    set(handles.linedy,'LineWidth',handles.linewidth);
    set(handles.linedy,'Color',handles.linecolor);
    figure(handles.dyplot);
end
guidata(hObject, handles);

function save_Callback(hObject, eventdata, handles)
data.ymatrix=handles.ymatrix;
data.ymatrix_sm=handles.ymatrix_sm;
data.ymatrix_d=handles.ymatrix_d;
data.N1=handles.N1;
data.N2=handles.N2;
data.sweep=handles.sweep;
data.loop1=handles.loop1;
data.title=get(handles.title,'string');
data.xlabel=get(handles.xtitle,'string');
data.ylabel=get(handles.ytitle,'string');
if handles.ivplot ~= -1
    figure(handles.ivplot);
    data.cmap_iv=colormap;
end; 
if handles.dyplot ~= -1
    figure(handles.dyplot);
    data.cmap_dy=colormap;
end;
[filename pathname]=uiputfile('e:\results');
[pathname filename]
save([pathname filename],'data');

function ivcmap_Callback(hObject, eventdata, handles)
figure(handles.ivplot)
cmap=get(handles.ivcmap,'value');
switch cmap
case 1
    colormap(hot(200));
case 2
    colormap(handles.blueredmap);
case 3
    colormap(handles.pinkmap);
case 4
    colormap(copper(200)); 
case 5
    colormap(gray(200));
    case 6
        colormap(hsv(200));
    case 7
        colormap(jet(200));
    case 8
        colormap(bone(200));
end;

function dycmap_Callback(hObject, eventdata, handles)
figure(handles.dyplot);
cmap=get(handles.dycmap,'value');
switch cmap
case 1
    colormap(hot(200));
case 2
    colormap(handles.blueredmap);
case 3
    colormap(handles.pinkmap);
case 4
    colormap(copper(200)); 
case 5
    colormap(gray(200));
    case 6
        colormap(hsv(200));
    case 7
        colormap(jet(200));
    case 8
        colormap(bone(200));
end;

function ivcol_Callback(hObject, eventdata, handles)
col=round(str2num(get(handles.ivcol,'string')));
N1=handles.N1;
N2=handles.N2;
if get(handles.ivtoggle,'value')==0
    if col>N2
        col=N2;
    end
else
    if col>N1
        col=N1;
    end
end
if col<1
    col=1;
end
set(handles.ivcol,'string',col);
updatelineiv()

function Fiddleiv_Callback(hObject, eventdata, handles)
figure(handles.ivplot);

function ivfiddleman_Callback(hObject, eventdata, handles)
figure(handles.ivplot);
if get(handles.ivmouseline,'value')==1;
    delete(handles.line);
    handles.line=-1;
end    
set(handles.ivmouseline,'Value',0);
set(handles.info,'String','Hold left mouse-button in plot and move pointer to change color settings.');
guidata(hObject, handles);

function FiddleSens_Callback(hObject, eventdata, handles)
figure(handles.ivplot)

function ivmouseline_Callback(hObject, eventdata, handles)
figure(handles.lineplotiv);
figure(handles.ivplot);
if get(handles.ivmouseline,'value')==1;
    col=str2num(get(handles.ivcol,'string'));
    handles.line=line([0 0],[1 1]);
    guidata(hObject, handles);
    updatelineiv();
else
    delete(handles.line);
    handles.line=-1;
    set(handles.info,'string','');
end    
set(handles.ivfiddleman,'Value',0);
guidata(hObject, handles);

function checkip()
hObject=findobj('name','diamond');
handles=guidata(hObject);

guidata(hObject, handles);

function diamond_OpeningFcn(hObject, eventdata, handles, varargin)
handles.output = hObject;
warning off all

%IPaddrclass=java.net.InetAddress.getLocalHost();
%IPaddr=char(IPaddrclass.getHostAddress);
%test=1;
handles.testIP=1;   %reset test-handle

%initialize handles
handles.ivplot=-1; 
handles.dyplot=-1;
handles.lineplotiv=-1;
handles.lineplotdy=-1;
handles.line=-1;
handles.linedy=-1;
handles.linewidth=0.5;
handles.linecolor=[0 0 1];
handles.figureformat=1;
handles.savedirectory=cd;
handles.dataformat=2;
handles.startdir=cd;
set(handles.FiddleSens,'value',0.7);

%default figure positions 
set(0,'units','pixels');
screen=get(0,'ScreenSize');
set(hObject,'Units','pixels')
set(hObject,'Position',[20 (screen(4)-370) 400 310])
if screen(3)<1025
    handles.plotpos=[435   36   580   500];
    handles.lineplotpos=[21   36   400   285];
end
if screen(3)>1025
    handles.plotpos=[435   36   580   500];
    handles.lineplotpos=[21   36   400   285];
end

% Extra inits; load colormaps
handles.blueredmap=blueredcmap();
handles.pinkmap=pinkcmap();

% Update handles structure
guidata(hObject, handles);

function varargout = diamond_OutputFcn(hObject, eventdata, handles)
varargout{1} = handles.output;
% check if IP-address and date are ok. If not -> quit program.
if handles.testIP==0
    proghandle=findobj('name','diamond');
    delete(proghandle); 
end

function dyfiddleman_Callback(hObject, eventdata, handles)
figure(handles.dyplot)
if get(handles.dymouseline,'value')==1;
    delete(handles.linedy);
    handles.linedy=-1;
end    
set(handles.dymouseline,'Value',0);
set(handles.info,'String','Hold left mouse-button and move pointer to change color settings.');
guidata(hObject, handles);

function dymouseline_Callback(hObject, eventdata, handles)
figure(handles.lineplotdy);
figure(handles.dyplot);
if get(handles.dymouseline,'value')==1;
    col=str2num(get(handles.dycol,'string'));
    xlim=get(gca,'ylim');
    linepos_x=handles.loop1(col);
    handles.linedy=line([linepos_x linepos_x], xlim);
    set(handles.info,'string','Click in colorplot to define linegraph position or use left and right cursors.'); 
else
    delete(handles.linedy);
    handles.linedy=-1;
    set(handles.info,'string','');
end    
set(handles.dyfiddleman,'Value',0);
guidata(hObject, handles);

function lockdy_Callback(hObject, eventdata, handles)
figure(handles.lineplotdy);
ylim=get(gca,'ylim');
set(handles.dyymin,'String',num2str(ylim(1)));
set(handles.dyymax,'String',num2str(ylim(2)));
figure(handles.dyplot);
guidata(hObject, handles);

function Menu_open_dat_Callback(hObject, eventdata, handles)
% opens datafile
    [filename pathname]=uigetfile('*.*','Select datafile');
    if isequal(filename,0)
        return
    end
    cd(pathname);
    [pathstr,fname,ext]=fileparts(filename);
    handles.file=filename;
    handles.path=pathname;
    handles.fileonly=fname;
    set(handles.info,'string','Wait for file to load...');
    waithandle=msgbox('Please wait for file to load...','Message','warn');
    chldrn=get(waithandle,'children');
    set(chldrn(3),'visible','off');
    %set(chldrn(4),'visible','off');
    drawnow;
    try
        data=dlmread([pathname,filename],'\t',4,1); %read data
    catch
        errordlg('File format not supported','File read error');
        close(waithandle);
        return
    end
    drawnow;
    resety();
    resetdy();
    set(handles.plotiv,'enable','off');
    set(handles.plotdy,'enable','off');
    set(handles.filename,'string',[pathname,filename]);
    
    % New routine to remove headers!     
    % Determine number of rows 
    fid=fopen([pathname,filename]);
    rowtest=0;
    for i=1:4
        fgetl(fid);
    end
    i=1;
    while rowtest==0
        linetest=fgetl(fid);
        if linetest(1)=='0'
            nrows=i-1;
            rowtest=1;
        end
        if linetest==-1
            nrows=i-1;
            rowtest=1;
%            return
        end
        i=i+1;
    end
    fclose(fid);
        
    datasize=size(data);
    numcol=datasize(2);
    numdata=datasize(1);
    firsthead=zeros(4,numcol);
    data2=[firsthead;data];
    %size(data2)
    
    N1=nrows;
    N2=fix((numdata+4)/(N1+4));
    data2=data2(1:(N2*(N1+4)),:);
    %size(data2)
    ymatrix=zeros(N1+4,N2);
    ymatrix(:)=data2(:,2);
    ymatrix=ymatrix(5:N1+4,:);
    
    assignin('base','first',ymatrix); 
    
    if size(data,2)>2                           % If DMM2 has been measured, export to WS
        ymatrix2=zeros(N1+4,N2);
        ymatrix2(:)=data2(:,3);
        ymatrix2=ymatrix2(5:N1+4,:);
        assignin('base','second',ymatrix2);
    end  
    
set(handles.sweepmin,'String',data2(1+4));
set(handles.sweepmax,'String',data2(N1+4));
set(handles.info,'string','Enter user-input and press Smooth to continue.');
close(waithandle);
set(handles.ypoints,'string',N1);
set(handles.xpoints,'string',N2);
set(handles.smooth,'Enable','on');
set(handles.title,'String',[pathname,filename]);
set(handles.FiddleSens,'value',0.2);
handles.ivplot=-1;
handles.dyplot=-1;
handles.lineplotiv=-1;
handles.lineplotdy=-1;
handles.ymatrix=ymatrix;
handles.N1=N1;
handles.N2=N2;
handles.ymatrix_sm=0;
handles.ymatrix_d=0;
handles.sweep=0;
handles.loop1=0;
initbutton_Callback(hObject,[],handles);
guidata(hObject, handles);

function Menu_open_special_Callback(hObject, eventdata, handles)
% opens datafile
%% JDSY 4/5/2011  - altered so that this will open special measure
%% Yuan Cao 10/21/2015 - removed vrs from output argument of fileparts - not compatible in MATLAB R2015a
%% datafiles.
    [filename pathname]=uigetfile('*.*','Select datafile');
    if isequal(filename,0)
        return
    end
    cd(pathname);
    [pathstr,fname,ext]=fileparts(filename);
    handles.file=filename;
    handles.path=pathname;
    handles.fileonly=fname;
    set(handles.info,'string','Wait for file to load...');
    waithandle=msgbox('Please wait for file to load...','Message','warn');
    chldrn=get(waithandle,'children');
    set(chldrn(3),'visible','off');
    %set(chldrn(4),'visible','off');
    drawnow;
    try
        dataStruct=load([pathname,filename]); %read data
        close(waithandle);
    catch
        errordlg('File format not supported','File read error');
        close(waithandle);
        return
    end
    drawnow;
    resety();
    resetdy();
    set(handles.plotiv,'enable','off');
    set(handles.plotdy,'enable','off');
    set(handles.filename,'string',[filename]);
    
    handles.fileonly=fname;
    
    datadim = size(dataStruct.data);
    answer{1} = '1';
    if datadim(2) > 1
        answer = inputdlg('More then one dataset found, Which # do you want?')
    end
    dataI = str2num(answer{1});
    ymatrix = dataStruct.data{dataI};
    [N1,N2]=size(ymatrix);
    set(handles.ypoints,'string',N1);
    set(handles.xpoints,'string',N2);
    
    set(handles.title,'String',fname);
    
    set(handles.smooth,'Enable','on');
    set(handles.FiddleSens,'value',0.2);
    set(handles.xtitle,'string',dataStruct.scan.loops(1).setchan{1});
    set(handles.ytitle,'string',dataStruct.scan.loops(2).setchan{1});
    if isfield(dataStruct.scan.loops,'setchanranges')
        set(handles.loopmin,'string',dataStruct.scan.loops(1).setchanranges{1}(1));
        set(handles.loopmax,'string',dataStruct.scan.loops(1).setchanranges{1}(2));
        set(handles.sweepmin,'string',dataStruct.scan.loops(2).setchanranges{1}(1));
        set(handles.sweepmax,'string',dataStruct.scan.loops(2).setchanranges{1}(2));
    else
        set(handles.loopmin,'string',dataStruct.scan.loops(1).rng(1));
        set(handles.loopmax,'string',dataStruct.scan.loops(1).rng(2));
    	set(handles.sweepmin,'string',dataStruct.scan.loops(2).rng(1));
        set(handles.sweepmax,'string',dataStruct.scan.loops(2).rng(2));
    end
    
    handles.ymatrix=ymatrix;
  
    handles.N1=N1;
    handles.N2=N2;
    handles.ymatrix_sm=0;
    handles.ymatrix_d=0;
    handles.sweep=0;
    handles.loop1=0;
    data.title=get(handles.title,'string');
    data.xlabel=get(handles.xtitle,'string');
    data.ylabel=get(handles.ytitle,'string');
    set(handles.info,'string','Enter user-input and press Smooth to continue.');
    %close(waithandle);
    assignin('base','first',ymatrix); 
    initbutton_Callback(hObject,[],handles);
    guidata(hObject, handles);


function Menu_open_mat_Callback(hObject, eventdata, handles)

switch eventdata
    case 2
        data=uiimport();
        if isempty(data)    % return if import wizard is cancelled
            return
        end
        names=fieldnames(data);
        fname=names{1};
        try
            ymatrix=getfield(data,fname);
        catch
            errordlg('Wrong file type.');
        end
        set(handles.filename,'string',fname);
        set(handles.title,'String',fname);
    case 1
        [filename pathname]=uigetfile('*.*','Select ascii matrixfile');
        if isequal(filename,0)
            return
        end
        cd(pathname);
        [pathstr,fname,ext]=fileparts(filename);
        set(handles.info,'string','Wait for file to load...');
        waithandle=msgbox('Please wait for file to load...','Message','warn');
        chldrn=get(waithandle,'children');
        set(chldrn(3),'visible','off');
        %set(chldrn(4),'visible','off');
        drawnow;
        try
            ymatrix=dlmread([pathname,filename]); %read data
            close(waithandle);
        catch 
            errordlg('File format not supported, please read help file','File read error');
            close(waithandle);
            return
        end
        set(handles.filename,'string',[pathname,filename]);
        set(handles.title,'String',[pathname,filename]);
end
handles.fileonly=fname;
resety();
resetdy();
set(handles.plotiv,'enable','off');
set(handles.plotdy,'enable','off');
[N1,N2]=size(ymatrix);
set(handles.ypoints,'string',N1);
set(handles.xpoints,'string',N2);
set(handles.smooth,'Enable','on');
set(handles.FiddleSens,'value',0.2);

handles.ymatrix=ymatrix;
handles.N1=N1;
handles.N2=N2;
handles.ymatrix_sm=0;
handles.ymatrix_d=0;
handles.sweep=0;
handles.loop1=0;
data.title=get(handles.title,'string');
data.xlabel=get(handles.xtitle,'string');
data.ylabel=get(handles.ytitle,'string');
set(handles.info,'string','Enter user-input and press Smooth to continue.');
%close(waithandle);
assignin('base','first',ymatrix); 
initbutton_Callback(hObject,[],handles);
guidata(hObject, handles);

% --- Executes on button press in Fiddledy.
function Fiddledy_Callback(hObject, eventdata, handles)
% hObject    handle to Fiddledy (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

function initbutton_Callback(hObject, eventdata, handles)
set(handles.initgroup,'visible','on')
set(handles.ivgroup,'visible','off')
set(handles.dygroup,'visible','off')
set(handles.usergroup,'visible','off')
set(handles.initbutton,'FontWeight','bold');
set(handles.ybutton,'FontWeight','normal');
set(handles.dybutton,'FontWeight','normal');
set(handles.userbutton','FontWeight','normal');
set(handles.initbutton,'foregroundcolor',[0 0 1]);
set(handles.ybutton,'foregroundcolor',[0 0 0]);
set(handles.dybutton,'foregroundcolor',[0 0 0]);
set(handles.userbutton,'foregroundcolor',[0 0 0]);

function ybutton_Callback(hObject, eventdata, handles)
hObject=findobj('name','diamond');
handles=guidata(hObject);
set(handles.initgroup,'visible','off')
set(handles.ivgroup,'visible','on')
set(handles.dygroup,'visible','off')
set(handles.usergroup,'visible','off')
set(handles.initbutton,'FontWeight','normal');
set(handles.ybutton,'FontWeight','bold');
set(handles.dybutton,'FontWeight','normal');
set(handles.userbutton,'FontWeight','normal');
set(handles.initbutton,'foregroundcolor',[0 0 0]);
set(handles.ybutton,'foregroundcolor',[0 0 1]);
set(handles.dybutton,'foregroundcolor',[0 0 0]);
set(handles.userbutton,'foregroundcolor',[0 0 0]);
if handles.ivplot~=-1
    figure(handles.ivplot)
end
if handles.lineplotiv~=-1
    figure(handles.lineplotiv)
end

function dybutton_Callback(hObject, eventdata, handles)
set(handles.initgroup,'visible','off')
set(handles.ivgroup,'visible','off')
set(handles.dygroup,'visible','on')
set(handles.usergroup,'visible','off')
set(handles.initbutton,'FontWeight','normal');
set(handles.ybutton,'FontWeight','normal');
set(handles.dybutton,'FontWeight','bold');
set(handles.userbutton,'FontWeight','normal');
set(handles.initbutton,'foregroundcolor',[0 0 0]);
set(handles.ybutton,'foregroundcolor',[0 0 0]);
set(handles.dybutton,'foregroundcolor',[0 0 1]);
set(handles.userbutton,'foregroundcolor',[0 0 0]);
if handles.dyplot~=-1
    figure(handles.dyplot)
end
if handles.lineplotdy~=-1
    figure(handles.lineplotdy)
end

function Menu_exportY_Callback(hObject, eventdata, handles)
data.ymatrix=handles.ymatrix;
data.ymatrix_sm=handles.ymatrix_sm;
data.N1=handles.N1;
data.N2=handles.N2;
data.sweep=handles.sweep;
data.loop1=handles.loop1;
data.title=get(handles.title,'string');
data.xlabel=get(handles.xtitle,'string');
data.ylabel=get(handles.ytitle,'string');
asciidata=data.ymatrix_sm;

if handles.ivplot ~= -1
    data.cmap_iv=colormap;
end; 

Ext={'.mat','.dat','.dat','.mat'};
SaveType={'-mat','-ascii','-ascii, -tabs','-v6'};
Selection=handles.dataformat;
directory_name=handles.savedirectory;

switch Selection
    case {1,4}
        teststring=[handles.fileonly '_ydata' char(Ext(Selection))]
        test=checkforwrite(teststring,directory_name,5);
        if test==1 | test==2
            try
                  save([directory_name '\' handles.fileonly '_ydata' char(Ext(Selection))],'data',char(SaveType(Selection)))
            catch
                errordlg('Error saving file');
                return
            end
            set(handles.info,'String',[handles.fileonly '_ydata.mat saved succesfully.']);
        end
        if test==0
            set(handles.info,'string','Save figures cancelled by user.');
            return
        end
    
    case 2
        teststring=[handles.fileonly '_ydata' char(Ext(Selection))]
        test=checkforwrite(teststring,directory_name,5)
        if test==1 | test==2
            try
                  save([directory_name '\' handles.fileonly '_ydata' char(Ext(Selection))],'asciidata',char(SaveType(Selection)))
            catch
                errordlg('Error saving file');
                return
            end
            set(handles.info,'String',[handles.fileonly '_ydata.dat saved succesfully.']);
        end
        if test==0
            set(handles.info,'string','Save figures cancelled by user.');
            return
        end
        
    case 3
        teststring=[handles.fileonly '_ydata' char(Ext(Selection))];
        test=checkforwrite(teststring,directory_name,5)
        if test==1 | test==2
            try
                  save([directory_name '\' handles.fileonly '_ydata' char(Ext(Selection))],'asciidata', '-ascii', '-tabs')
            catch
                errordlg('Error saving file');
                return
            end
            set(handles.info,'String',[handles.fileonly '_ydata.dat saved succesfully.']);
        end
        if test==0
            set(handles.info,'string','Save figures cancelled by user.');
            return
        end
end

% --------------------------------------------------------------------
function Menu_exportDY_Callback(hObject, eventdata, handles)
data.ymatrix_d=handles.ymatrix_d;
data.N1=handles.N1;
data.N2=handles.N2;
data.sweep=handles.sweep;
data.loop1=handles.loop1;
data.title=get(handles.title,'string');
data.xlabel=get(handles.xtitle,'string');
data.ylabel=get(handles.ytitle,'string');
if handles.dyplot ~= -1
    data.cmap_dy=colormap;
end; 

directory_name=handles.savedirectory;
SaveType={'-mat','-ascii','-ascii, -tabs','-v6'};
Selection=handles.dataformat;

Ext={'.mat','.dat','.dat','.mat'};
asciidata=data.ymatrix_d;

switch Selection
    case {1,4}
        teststring=[handles.fileonly '_dydata' char(Ext(Selection))]
        test=checkforwrite(teststring,directory_name,5);
        if test==1 | test==2
            try
                  save([handles.savedirectory '\' handles.fileonly '_dydata' char(Ext(Selection))],'data',char(SaveType(Selection)))
            catch
               errordlg('Error saving file');
               return
            end
            set(handles.info,'String',[handles.fileonly '_dydata.mat saved succesfully.']);
        end
        if test==0
            set(handles.info,'string','Save figures cancelled by user.');
            return
        end

    case 2
        teststring=[handles.fileonly '_dydata' char(Ext(Selection))]
        test=checkforwrite(teststring,directory_name,5)
        if test==1 | test==2
            try
                    save([handles.savedirectory '\' handles.fileonly '_dydata' char(Ext(Selection))],'asciidata',char(SaveType(Selection)))
            catch
                errordlg('Error saving file');
                return
            end
            set(handles.info,'String',[handles.fileonly '_dydata.dat saved succesfully.']);
        end
        if test==0
            set(handles.info,'string','Save figures cancelled by user.');
            return
        end
        
    case 3
        teststring=[handles.fileonly '_dydata' char(Ext(Selection))];
        test=checkforwrite(teststring,directory_name,5)
        if test==1 | test==2
            try
                  save([handles.savedirectory '\' handles.fileonly '_dydata' char(Ext(Selection))],'asciidata', '-ascii', '-tabs')
            catch
                errordlg('Error saving file');
                return
            end
            set(handles.info,'String',[handles.fileonly '_dydata.dat saved succesfully.']);
        end
        if test==0
            set(handles.info,'string','Save figures cancelled by user.');
            return
        end
end
        
% --------------------------------------------------------------------
function Menu_saveall_Callback(hObject, eventdata, handles)
FType={'jpg','fig','bmp','eps','emf','tif'};
Selection=handles.figureformat;
directory_name=handles.savedirectory;

%turn off all buttons
copyhandle=findobj('String','copy figure');
savehandle=findobj('String','save figure');
set(copyhandle,'visible','off');
set(savehandle,'visible','off');


if handles.ivplot~=-1
    teststring=[handles.fileonly '_yplot.' char(FType(Selection))];
    test=checkforwrite(teststring,directory_name,1);
    switch Selection
        case 4
            figure(handles.ivplot);
            print('-depsc2',[handles.savedirectory '\' teststring]);
        otherwise
        if test==1 | test==2
            saveas(handles.ivplot,[handles.savedirectory '\' teststring]);
            set(handles.info,'string','Figure saved successfully.');
        end
        if test==0
            set(handles.info,'string','Save figures cancelled by user.');
            
        end
    end
end

if handles.dyplot~=-1
    teststring=[handles.fileonly '_dyplot.' char(FType(Selection))];
    if test~=2
        test=checkforwrite(teststring,directory_name,2);
    end
    switch Selection
        case 4
            figure(handles.dyplot);
            print('-depsc2',[handles.savedirectory '\' teststring]);
        otherwise
        if test==1|test==2
            saveas(handles.dyplot,[handles.savedirectory '\' teststring]);
            set(handles.info,'string','Figure saved successfully.');
        end
        if test==0
             set(handles.info,'string','Save figures cancelled by user.');
            
        end
    end
end

if handles.lineplotiv~=-1
    teststring=[handles.fileonly '_ylineplot.' char(FType(Selection))];
    if test~=2
        test=checkforwrite(teststring,directory_name,3);
    end
    switch Selection
        case 4
            figure(handles.lineplotiv);
            print('-depsc2',[handles.savedirectory '\' teststring]);
        otherwise
        if test==1|test==2
            saveas(handles.lineplotiv,[handles.savedirectory '\' teststring]);
            set(handles.info,'string','Figure saved successfully.');
        end
        if test==0
            set(handles.info,'string','Save figures cancelled by user.');
        
        end
    end
end

if handles.lineplotdy~=-1
    teststring=[handles.fileonly '_dylineplot.' char(FType(Selection))];
    if test~=2
        test=checkforwrite(teststring,directory_name,4);
    end
    switch Selection
        case 4
            figure(handles.lineplotdy);
            print('-depsc2',[handles.savedirectory '\' teststring]);
        otherwise
        if test==1 | test==2
            saveas(handles.lineplotdy,[handles.savedirectory '\' teststring]);
            set(handles.info,'string','Figure saved successfully.');
        end
        if test==0
            set(handles.info,'string','Save figures cancelled by user.');
        
        end
    end
end

set(copyhandle,'visible','on'); %turn on all buttons
set(savehandle,'visible','on');

function output=checkforwrite(filename,directory,type)
test=[directory '\' filename];
fid=fopen(test,'r');
if fid==-1
    output=1;
    return
end
fclose(fid);

switch type
    case 1
        filen='_yplot';
    case 2
        filen='_dyplot';
    case 3
        filen='_ylineplot';
    case 4
        filen='_dylineplot';
    case 5
        filen='_ydata';
    case 6
        filen='';
end

ask=questdlg(['Overwrite existing file: ' filename '?'],'Question','Yes','Yes to all','No','Yes');
    switch size(ask,2)
        case 3
            output=1;
        case 10
            output=2;
        case 2
            output=0;
        case 0
            output=0;
    end

function Menu_help_Callback(hObject, eventdata, handles)
function Menu_help_item_Callback(hObject, eventdata, handles)
try
    olddir=cd;
    cd(handles.startdir)
    status=dos('help.chm');
    cd(olddir)
catch
    errordlg('Error opening Help-file');
end

% --------------------------------------------------------------------
function Menu_about_Callback(hObject, eventdata, handles)
message={'Diamond v0.7beta, June 2005' ...
    '' 'Made by:' ...
    'Hubert Heersche, hubert@qt.tn.tudelft.nl' ...
    'Jorden van Dam, jorden@qt.tn.tudelft.nl' ...
    '' 'http://qt.tn.tudelft.nl/~diamond'};
h=msgbox(message,'About Diamond');

% --------------------------------------------------------------------
function Menu_options_Callback(hObject, eventdata, handles)
return

% --------------------------------------------------------------------
function Menu_linegraph_Callback(hObject, eventdata, handles)
S={'Line thickness','Line color'};
[Selection,ok]=listdlg('ListString',S,'SelectionMode','single', ...
            'Name','Select line property','ListSize',[125 75]);
if ok==0
    return 
end
switch Selection
    case 1
        S={'Very thin, 0.2pt','Thin, 0.5pt','Normal, 1pt','Thick, 2pt','Very thick, 5pt'};
        [Selection,ok]=listdlg('ListString',S,'SelectionMode','single', ...
            'Name','Select line property','ListSize',[125 75],'InitialValue',3);
        if ok==0
            return 
        end
        thickness={0.2,0.5,1,2,5};
        handles.linewidth=cell2mat(thickness(Selection));
        if handles.line>0
            set(handles.line,'LineWidth',handles.linewidth);
        end
        if handles.linedy>0
            set(handles.linedy,'LineWidth',handles.linewidth);
        end
    case 2
        try
            handles.linecolor=uisetcolor(handles.linecolor,'Select line color');
        catch
            return
        end
        if handles.line>0
            set(handles.line,'Color',handles.linecolor);
        end
        if handles.linedy>0
            set(handles.linedy,'Color',handles.linecolor);
        end
end
guidata(hObject,handles);

% --------------------------------------------------------------------
function Menu_Homepage_Callback(hObject, eventdata, handles)
web('http://qt.tn.tudelft.nl/~diamond','-browser');

% --------------------------------------------------------------------
function Menu_pagesetup_Callback(hObject, eventdata, handles)
S={};
if handles.ivplot~=-1
    S{size(S,2)+1}='yplot';
    sel=1;
end
if handles.dyplot~=-1
    S{size(S,2)+1}='dyplot';
    sel=2;
end
if handles.lineplotiv~=-1
    S{size(S,2)+1}='ylineplot';
    sel=3;
end
if handles.lineplotdy~=-1
    S{size(S,2)+1}='dylineplot';
    sel=4;
end

switch size(S,2)
    case 0
        errordlg('No active figures available!','Error');
        return
    case 1
        Selection=sel;
    case {2,3,4}
        [Selection,ok]=listdlg('ListString',S,'SelectionMode','single', ...
            'Name','Select window','ListSize',[150 100]);
        if ok==0
            return 
        end
end
selstring={handles.ivplot,handles.dyplot,handles.lineplotiv,handles.lineplotdy};
fighandle=cell2mat(selstring(Selection));
b=pagesetupdlg(fighandle);

% --------------------------------------------------------------------
function Menu_print_Callback(hObject, eventdata, handles)

S={};
if handles.ivplot~=-1
    S{size(S,2)+1}='yplot';
    sel=1;
end
if handles.dyplot~=-1
    S{size(S,2)+1}='dyplot';
    sel=2;
end
if handles.lineplotiv~=-1
    S{size(S,2)+1}='ylineplot';
    sel=3;
end
if handles.lineplotdy~=-1
    S{size(S,2)+1}='dylineplot';
    sel=4;
end

switch size(S,2)
    case 0
        errordlg('No active figures available!','Error');
        return
    case 1
        Selection=sel;
    case {2,3,4}
        [Selection,ok]=listdlg('ListString',S,'SelectionMode','single', ...
            'Name','Select window','ListSize',[150 100]);
        if ok==0
            return 
        end
end
selstring={handles.ivplot,handles.dyplot,handles.lineplotiv,handles.lineplotdy};
fighandle=cell2mat(selstring(Selection));
b=printdlg(fighandle);

function dytoggle_Callback(hObject, eventdata, handles)
N1=handles.N1;
N2=handles.N2;
state=get(handles.dytoggle,'value');
if state==0
    set(handles.dycol,'string',fix(N2/2));
    set(handles.fixed28,'string','Col:');
else
    set(handles.dycol,'string',fix(N1/2));
    set(handles.fixed28,'string','Row:');
end
updatelinedy();

function ivtoggle_Callback(hObject, eventdata, handles)
N1=handles.N1;
N2=handles.N2;
state=get(handles.ivtoggle,'value');
if state==0
    set(handles.ivcol,'string',fix(N2/2));
    set(handles.text30,'string','Col:');
else
    set(handles.ivcol,'string',fix(N1/2));
    set(handles.text30,'string','Row:');
end
updatelineiv();

function userbutton_Callback(hObject, eventdata, handles)
set(handles.initgroup,'visible','off')
set(handles.ivgroup,'visible','off')
set(handles.dygroup,'visible','off')
set(handles.usergroup,'visible','on')
set(handles.initbutton,'FontWeight','normal');
set(handles.ybutton,'FontWeight','normal');
set(handles.dybutton,'FontWeight','normal');
set(handles.userbutton,'FontWeight','bold');
set(handles.initbutton,'foregroundcolor',[0 0 0]);
set(handles.ybutton,'foregroundcolor',[0 0 0]);
set(handles.dybutton,'foregroundcolor',[0 0 0]);
set(handles.userbutton,'foregroundcolor',[0 0 1]);
set(handles.uipanel11,'visible','on');
set(handles.info,'string','Enter convolution matrix or equation and set as Y or DY.');

function pushconvolute_Callback(hObject, eventdata, handles)
try
    filt(1,1)=str2num(get(handles.umatrix11,'string'));
    filt(1,2)=str2num(get(handles.umatrix12,'string'));
    filt(1,3)=str2num(get(handles.umatrix13,'string'));
    filt(2,1)=str2num(get(handles.umatrix21,'string'));
    filt(2,2)=str2num(get(handles.umatrix22,'string'));
    filt(2,3)=str2num(get(handles.umatrix23,'string'));
    filt(3,1)=str2num(get(handles.umatrix31,'string'));
    filt(3,2)=str2num(get(handles.umatrix32,'string'));
    filt(3,3)=str2num(get(handles.umatrix33,'string'));
    filt=rot90(filt,2); % rotate matrix 180 degrees for intuitive convolution !
    ymatrix_new=imfilter(handles.ymatrix_sm,filt,'replicate','conv');

catch 
    errordlg('Error performing convolution.');
    return
end
handles.ymatrix_sm=ymatrix_new;
guidata(hObject,handles);

function pushresety_Callback(hObject, eventdata, handles)
handles.ymatrix_sm=handles.ymatrixoriginal;
guidata(hObject,handles);

function pusheqy_Callback(hObject, eventdata, handles)
Y=handles.ymatrix_sm;
dY=handles.ymatrix_d;
try
    newy=eval(get(handles.edit55,'string'));
catch
    errordlg('Wrong Matlab expression!');
    return
end
handles.ymatrix_sm=newy;
set(handles.ivfiddleman,'value',0);
set(handles.ivfiddleman,'enable','off');
set(handles.ivmouseline,'value',0);
set(handles.plotlineiv,'enable','off');
set(handles.ivmouseline,'enable','off');
set(handles.ivlocky,'value',0);
set(handles.ivlocky,'enable','off');
set(handles.ivcol,'string',1);
set(handles.ivcol,'enable','off');
set(handles.ivymin,'string',0);
set(handles.ivymin,'enable','off');
set(handles.ivymax,'string',0);
set(handles.ivymax,'enable','off');
set(handles.ivtoggle,'enable','off');
set(handles.ivtoggle,'value',0);
handles.lineplotiv=-1;
if handles.line~=-1
    delete(handles.line)
    handles.line=-1;
end
handles.ivplot=-1;
guidata(hObject,handles);

function Menu_fiddle_Callback(hObject, eventdata, handles)
def=num2str(get(handles.FiddleSens,'value'));
try    
    answer=inputdlg('(Default=0.2)','Enter Sensitivity',1,{def});
    if isempty(answer) 
        return
    end
    value=str2num(answer{1});
    if (value>10) | (value<0.01) 
        asd %GENERATE ERROR
    end
        
catch
    errordlg('Enter a value between 0.01 and 10');
    return
end
set(handles.FiddleSens,'value',value);
guidata(hObject,handles);

function pushconvoluteDY_Callback(hObject, eventdata, handles)
try
filt(1,1)=str2num(get(handles.umatrix11,'string'));
filt(1,2)=str2num(get(handles.umatrix12,'string'));
filt(1,3)=str2num(get(handles.umatrix13,'string'));
filt(2,1)=str2num(get(handles.umatrix21,'string'));
filt(2,2)=str2num(get(handles.umatrix22,'string'));
filt(2,3)=str2num(get(handles.umatrix23,'string'));
filt(3,1)=str2num(get(handles.umatrix31,'string'));
filt(3,2)=str2num(get(handles.umatrix32,'string'));
filt(3,3)=str2num(get(handles.umatrix33,'string'));
    ymatrix_new=imfilter(handles.ymatrix_d,filt,'replicate','conv');
catch
    errordlg('Error performing convolution.');
    return
end
handles.ymatrix_d=ymatrix_new;
guidata(hObject,handles);

function pushresetdy_Callback(hObject, eventdata, handles)
handles.ymatrix_d=handles.ymatrix_doriginal;
guidata(hObject,handles);

function pusheqdy_Callback(hObject, eventdata, handles)
Y=handles.ymatrix_sm;
dY=handles.ymatrix_d;
try
    newdy=eval(get(handles.edit55,'string'));
catch
    errordlg('Wrong Matlab expression!');
    return
end
handles.ymatrix_d=newdy;
set(handles.dyfiddleman,'value',0);
set(handles.dyfiddleman,'enable','off');
set(handles.dymouseline,'value',0);
set(handles.plotlinedy,'enable','off');
set(handles.dymouseline,'enable','off');
set(handles.dylocky,'value',0);
set(handles.dylocky,'enable','off');
set(handles.dycol,'string',1);
set(handles.dycol,'enable','off');
set(handles.dyymin,'string',0);
set(handles.dyymin,'enable','off');
set(handles.dyymax,'string',0);
set(handles.dyymax,'enable','off');
set(handles.dytoggle,'enable','off');
set(handles.dytoggle,'value',0);
handles.lineplotdy=-1;
if handles.linedy~=-1
    delete(handles.linedy)
    handles.linedy=-1;
end
handles.dyplot=-1;
guidata(hObject,handles);

function Menu_Exit_Callback(hObject, eventdata, handles)
test=questdlg('Do you really want to exit?','Confirm to exit');
switch size(test,2)
    case 3
        proghandle=findobj('name','diamond');
        delete(proghandle);
    otherwise
        return
end

function edit56_Callback(hObject, eventdata, handles)
function edit56_CreateFcn(hObject, eventdata, handles)
if ispc
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end
function edit57_Callback(hObject, eventdata, handles)
function edit57_CreateFcn(hObject, eventdata, handles)
if ispc
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end
function edit59_Callback(hObject, eventdata, handles)
function edit59_CreateFcn(hObject, eventdata, handles)
if ispc
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end
function edit61_Callback(hObject, eventdata, handles)
function edit61_CreateFcn(hObject, eventdata, handles)
if ispc
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end
function Menu_Open_Tab_Callback(hObject, eventdata, handles)
function Menu_Open_Space_Callback(hObject, eventdata, handles)
function Menu_close_Callback(hObject, eventdata, handles)
function Untitled_1_Callback(hObject, eventdata, handles)
function title_CreateFcn(hObject, eventdata, handles)
if ispc
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end
function title_Callback(hObject, eventdata, handles)
function xtitle_CreateFcn(hObject, eventdata, handles)
if ispc
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end
function xtitle_Callback(hObject, eventdata, handles)
function ytitle_CreateFcn(hObject, eventdata, handles)
if ispc
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end
function ytitle_Callback(hObject, eventdata, handles)
function ivcmin_CreateFcn(hObject, eventdata, handles)
if ispc
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end
function ivcmax_CreateFcn(hObject, eventdata, handles)
if ispc
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end
function dycmax_CreateFcn(hObject, eventdata, handles)
if ispc
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end
function sweepmin_CreateFcn(hObject, eventdata, handles)
if ispc
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end
function sweepmin_Callback(hObject, eventdata, handles)
function loopmin_CreateFcn(hObject, eventdata, handles)
if ispc
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end
function loopmin_Callback(hObject, eventdata, handles)
function sweepmax_CreateFcn(hObject, eventdata, handles)
if ispc
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end
function sweepmax_Callback(hObject, eventdata, handles)
function loopmax_CreateFcn(hObject, eventdata, handles)
if ispc
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end
function loopmax_Callback(hObject, eventdata, handles)
function dycol_CreateFcn(hObject, eventdata, handles)
if ispc
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end
function dycmin_CreateFcn(hObject, eventdata, handles)
if ispc
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end
function ivcmap_CreateFcn(hObject, eventdata, handles)
if ispc
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end
function dycmap_CreateFcn(hObject, eventdata, handles)
if ispc
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end
function ivcol_CreateFcn(hObject, eventdata, handles)
if ispc
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end
function smoothx_CreateFcn(hObject, eventdata, handles)
if ispc
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end
function smoothx_Callback(hObject, eventdata, handles)
function smoothy_CreateFcn(hObject, eventdata, handles)
if ispc
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end
function smoothy_Callback(hObject, eventdata, handles)
function edit55_Callback(hObject, eventdata, handles)
function edit55_CreateFcn(hObject, eventdata, handles)
if ispc
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end

function umatrix11_Callback(hObject, eventdata, handles)
function umatrix11_CreateFcn(hObject, eventdata, handles)
if ispc
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end
function umatrix12_Callback(hObject, eventdata, handles)
function umatrix12_CreateFcn(hObject, eventdata, handles)
if ispc
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end
function umatrix13_Callback(hObject, eventdata, handles)
function umatrix13_CreateFcn(hObject, eventdata, handles)
if ispc
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end
function umatrix21_Callback(hObject, eventdata, handles)
function umatrix21_CreateFcn(hObject, eventdata, handles)
if ispc
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end
function umatrix22_Callback(hObject, eventdata, handles)
function umatrix22_CreateFcn(hObject, eventdata, handles)
if ispc
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end
function umatrix23_Callback(hObject, eventdata, handles)
function umatrix23_CreateFcn(hObject, eventdata, handles)
if ispc
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end
function umatrix31_Callback(hObject, eventdata, handles)
function umatrix31_CreateFcn(hObject, eventdata, handles)
if ispc
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end
function umatrix32_Callback(hObject, eventdata, handles)
function umatrix32_CreateFcn(hObject, eventdata, handles)
if ispc
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end
function umatrix33_Callback(hObject, eventdata, handles)
function umatrix33_CreateFcn(hObject, eventdata, handles)
if ispc
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end
function dyymin_Callback(hObject, eventdata, handles)
updatelinedy()
function dyymin_CreateFcn(hObject, eventdata, handles)
if ispc
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end
function dyymax_Callback(hObject, eventdata, handles)
updatelinedy()
function dyymax_CreateFcn(hObject, eventdata, handles)
if ispc
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end 
function File_Callback(hObject, eventdata, handles)
function mousepos_Callback(hObject, eventdata, handles)
function mousepos_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
function ypos_Callback(hObject, eventdata, handles)
function ypos_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
function ivymin_Callback(hObject, eventdata, handles)
updatelineiv()
function ivymin_CreateFcn(hObject, eventdata, handles)
if ispc
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end
function FiddleSens_CreateFcn(hObject, eventdata, handles)
usewhitebg = 1;
if usewhitebg
    set(hObject,'BackgroundColor',[.9 .9 .9]);
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end
function importmatrix_Callback(hObject, eventdata, handles)
function ivymax_CreateFcn(hObject, eventdata, handles)
if ispc
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end

function Menu_figureformat_Callback(hObject, eventdata, handles)
S={'.jpg, JPEG image','.fig, Matlab figure','.bmp, Windows bitmap, ','.eps, EPS level 2',...
    '.emf, Enhanced metafile','.tif, TIFF image compressed'};
FType={'jpg','fig','bmp','eps','emf','tif'};
[Selection,ok] = listdlg('ListString',S,'Name','Select figure format',...
    'InitialValue',1,'ListSize',[200 100],'SelectionMode','Single');
if ok==0
    return
end
handles.figureformat=Selection;
guidata(hObject,handles);

function Menu_dataformat_Callback(hObject, eventdata, handles)
S={'.mat, Matlab file','.dat, ascii file','.dat, ascii file (tab delimited)',...
    '.mat, Matlab file (old format)'};
SaveType={'-mat','-ascii','-ascii, -tabs','-v6'};
[Selection,ok] = listdlg('ListString',S,'Name','Select file format',...
    'InitialValue',handles.dataformat,'ListSize',[200 100],'SelectionMode','Single');
if ok==0
    return
end
handles.dataformat=Selection;
guidata(hObject,handles);

function Menu_savedirectory_Callback(hObject, eventdata, handles)
hObject=findobj('name','diamond');
if isempty(hObject)
    delete(gcf)
    return
end
handles=guidata(hObject);
directory_name = uigetdir(handles.savedirectory,'Select Directory');
if directory_name==0
    return
end
handles.savedirectory=directory_name;
addpath(handles.savedirectory);
guidata(hObject,handles);

function Menu_closeall_Callback(hObject, eventdata, handles)
try
    b=get(0,'children');
    c=findobj('name','diamond');
    d=find(b(:)==c);
    b(d)='';
    delete(b);
    resety;
    resetdy;
catch
    errordlg('Error while closing figures. Please restart Diamond.');
end
initbutton_Callback(hObject,[],handles);

% --------------------------------------------------------------------
function Menu_deletelast_Callback(hObject, eventdata, handles)
ymatrix=handles.ymatrix;
ymatrix_sm=handles.ymatrix_sm;
ymatrix_d=handles.ymatrix_d;
ymatrixoriginal=handles.ymatrixoriginal;
ymatrix_doriginal=handles.ymatrix_doriginal;

N2=handles.N2;        %number of loop values

ymatrix(:,N2)=[];
ymatrix_sm(:,N2)=[];
ymatrix_d(:,N2)=[];
ymatrixoriginal(:,N2)=[];
ymatrix_doriginal(:,N2)=[];
N2=N2-1;

handles.ymatrix=ymatrix;
handles.ymatrix_sm=ymatrix_sm;
handles.ymatrix_d=ymatrix_d;
handles.ymatrixoriginal=ymatrixoriginal;
handles.ymatrix_doriginal=ymatrix_doriginal;
handles.N2=N2;

set(handles.info,'string','Last loop measurement successfully deleted.');
set(handles.xpoints,'string',N2);
msgbox('Last loop measurement successfully deleted.','Message')

initbutton_Callback(gcbo,[],guidata(gcbo))
guidata(hObject, handles);

% --------------------------------------------------------------------
function Menu_open_test_Callback(hObject, eventdata, handles)

ymatrix=test_mat();
 handles.fileonly='test.dat';
% resety();
% resetdy();
 set(handles.plotiv,'enable','off');
 set(handles.plotdy,'enable','off');
 [N1,N2]=size(ymatrix);
 set(handles.ypoints,'string',N1);
 set(handles.xpoints,'string',N2);
 set(handles.smooth,'Enable','on');
% 
 handles.ymatrix=ymatrix;
 handles.N1=N1;
 handles.N2=N2;
 handles.ymatrix_sm=0;
 handles.ymatrix_d=0;
 handles.sweep=0;
  handles.loop1=0;
 data.title=get(handles.title,'string');
 data.xlabel=get(handles.xtitle,'string');
 data.ylabel=get(handles.ytitle,'string');
 set(handles.info,'string','Enter user-input and press Process Data to continue.');
% %close(waithandle);
 initbutton_Callback(hObject,[],handles);
 set(handles.filename,'string','This is an example file')
 guidata(hObject, handles);



% --------------------------------------------------------------------
function Menu_reopen_dat_Callback(hObject, eventdata, handles)
filename=handles.file;
pathname=handles.path;
waithandle=msgbox('Please wait for file to load...','Message','warn');
chldrn=get(waithandle,'children');
set(chldrn(3),'visible','off');
%set(chldrn(4),'visible','off');
drawnow;
    try
        data=dlmread([pathname,filename],'\t',4,1); %read data
   catch
      errordlg('File format not supported','File read error');
      close(waithandle);
      return
  end
    drawnow;
    resety();
    resetdy();
    set(handles.plotiv,'enable','off');
    set(handles.plotdy,'enable','off');
    set(handles.filename,'string',[pathname,filename]);
    
    % New routine to remove headers!     
    % Determine number of rows 
    fid=fopen([pathname,filename]);
    rowtest=0;
    for i=1:4
        fgetl(fid);
    end
    i=1;
    while rowtest==0
        linetest=fgetl(fid);
        if linetest(1)=='0'
            nrows=i-1;
            rowtest=1;
        end
        if linetest==-1
            nrows=i-1;
            rowtest=1;
%            return
        end
        i=i+1;
    end
    fclose(fid);
        
    datasize=size(data);
    numcol=datasize(2);
    numdata=datasize(1);
    firsthead=zeros(4,numcol);
    data2=[firsthead;data];
    %size(data2)
    
    N1=nrows;
    N2=fix((numdata+4)/(N1+4));
    data2=data2(1:(N2*(N1+4)),:);
    %size(data2)
    ymatrix=zeros(N1+4,N2);
    ymatrix(:)=data2(:,2);
    ymatrix=ymatrix(5:N1+4,:);
    
    assignin('base','first',ymatrix); 
    
    if size(data,2)>2                           % If DMM2 has been measured, export to WS
        ymatrix2=zeros(N1+4,N2);
        ymatrix2(:)=data2(:,3);
        ymatrix2=ymatrix2(5:N1+4,:);
        assignin('base','second',ymatrix2);
    end  
    
set(handles.sweepmin,'String',data2(1+4));
set(handles.sweepmax,'String',data2(N1+4));
set(handles.info,'string','Enter user-input and press Smooth to continue.');
close(waithandle);
set(handles.ypoints,'string',N1);
set(handles.xpoints,'string',N2);
set(handles.smooth,'Enable','on');
set(handles.title,'String',[pathname,filename]);
set(handles.FiddleSens,'value',0.2);
handles.ivplot=-1;
handles.dyplot=-1;
handles.lineplotiv=-1;
handles.lineplotdy=-1;
handles.ymatrix=ymatrix;
handles.N1=N1;
handles.N2=N2;
handles.ymatrix_sm=0;
handles.ymatrix_d=0;
handles.sweep=0;
handles.loop1=0;
guidata(hObject, handles);
initbutton_Callback(hObject,[],handles);

%handles=guidata(hObject);
%smooth_Callback(hObject,[],handles);
%guidata(hObject, handles);
% --------------------------------------------------------------------
function slice_Callback(hObject, eventdata, handles)

% Delete posible previous line in ydata
try
    delete(handles.sectionline)
end

% Input for two points in ydata
figure(handles.ivplot)
set(handles.info,'string','Press first position of cross-section.');
waitforbuttonpress
if gcf~=handles.ivplot % check if button is pressed inside ydata
    set(handles.info,'string','Returned due to mouse press outside graph.');
    return
end
first=get(gca,'CurrentPoint');
set(handles.info,'string','Press second position of cross-section.');
waitforbuttonpress
if gcf~=handles.ivplot % check if button is pressed inside ydata
    set(handles.info,'string','Returned due to mouse press outside graph.');
    return
end
last=get(gca,'CurrentPoint');    

% create linegraph
handles.section=figure;
set(gcf,'position',handles.lineplotpos);
set(gca,'NextPlot','replacechildren');
copyhandle=uicontrol(gcf,'Style','pushbutton','string','copy',...
    'Position',[5 5 50 20],'Callback',@Copyfigure);
title('Linegraph');
xlabel(get(handles.xtitle,'string'));
ylabel('Y data');
sectionaxishandle=gca;

figure(handles.ivplot);

while gcf==handles.ivplot
    last=get(gca,'CurrentPoint');    
    try
        delete(handles.sectionline)
    end 
    res=max(handles.N1,handles.N2);
    xmin=first(1,1);
    xmax=last(1,1); 
    ymin=first(1,2);
    ymax=last(1,2);
    XI=[xmin:(xmax-xmin)/(res-1):xmax]; % define new x-data
    YI=[ymin:(ymax-ymin)/(res-1):ymax]; % define new y-data
    X=handles.loop1; % copy old x-data
    Y=handles.sweep; % copy old y-data
    try
        ZI=interp2(X,Y,handles.ymatrix_sm,XI,YI); % interpolation routine
    catch
        a='interpcatch'
        return
    end

   % figure(handles.section)
    plot(sectionaxishandle,XI,ZI); % plot new section
    set(sectionaxishandle,'XLim',[min(xmin,xmax) max(xmin,xmax)]);
    
   % plot line in ydata
   figure(handles.ivplot)
    handles.sectionline=line([xmin xmax], [ymin ymax]);
    key=waitforbuttonpress;
   %if key==1  % return when key is pressed
   %     set(handles.info,'string','Returned due to key press.');
   %     guidata(hObject, handles);
   %     return 
   % end
end

guidata(hObject, handles);

% --------------------------------------------------------------------
function section_change_Callback(hObject, eventdata, handles)
% hObject    handle to section_change (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


