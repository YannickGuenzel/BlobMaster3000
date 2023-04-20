%--------------------------------------------------------------------------
%                             Initialization Code
%--------------------------------------------------------------------------

function varargout = BlobMaster3000(varargin)
% BLOBMASTER3000 MATLAB code for BlobMaster3000.fig
%      BLOBMASTER3000, by itself, creates a new BLOBMASTER3000 or raises the existing
%      singleton*.
%
%      H = BLOBMASTER3000 returns the handle to a new BLOBMASTER3000 or the handle to
%      the existing singleton*.
%
%      BLOBMASTER3000('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in BLOBMASTER3000.M with the given input arguments.
%
%      BLOBMASTER3000('Property','Value',...) creates a new BLOBMASTER3000 or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before BlobMaster3000_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to BlobMaster3000_OpeningFcn via
%      varargin. 
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help BlobMaster3000

% Last Modified by GUIDE v2.5 23-Jun-2021 14:35:45

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
    'gui_Singleton',  gui_Singleton, ...
    'gui_OpeningFcn', @BlobMaster3000_OpeningFcn, ...
    'gui_OutputFcn',  @BlobMaster3000_OutputFcn, ...
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








%--------------------------------------------------------------------------
%                           Special Functions
%--------------------------------------------------------------------------

% --- Executes just before BlobMaster3000 is made visible.
function BlobMaster3000_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to BlobMaster3000 (see VARARGIN)
clc

% Choose default command line output for BlobMaster3000
handles.output = hObject;

% UIWAIT makes BlobMaster3000 wait for user response (see UIRESUME)
% uiwait(handles.figure1);

% Disable options
handles = UnlockOptions(handles, 'Init');

% Display welcome image
if isfile('welcome.png')
    welcomeIMG = imread('welcome.png');
    axes(handles.ax_main)
    imshow(welcomeIMG);
    %     set(handles.ax_main, 'Visible', 'on');
    clear welcomeIMG
end

% Listen to slider to immediately update display of currently selected frame
addlistener(handles.sl_main,...
    'Value','PreSet',...
    @(~,~)set(handles.ed_currentFrame, 'String', num2str(round(get(handles.sl_main, 'Value'), 0))));

% Listen to stop button
addlistener(handles.pb_stop,...
    'Value','PostSet',...
    @(~,~)set(handles.pb_play, 'UserData', 1));

% Set inital prudence
handles.cautious = 1;

% Set initial number of animal clusters
handles.n_ani_clust = 1;

% Update handles structure
guidata(hObject, handles);

% --- Outputs from this function are returned to the command line.
function varargout = BlobMaster3000_OutputFcn(hObject, eventdata, handles)
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;

% --- Only place to update the main axis
function handles = updateFigure(handles)

% Update info which frame is displayed
set(handles.sl_main, 'Value', handles.CurrFrame)
set(handles.ed_currentFrame, 'String', num2str(handles.CurrFrame))

% Prepare frame (thresholding etc)
frame = prepareFrame(handles, handles.CurrFrame);

% Display frame
axes(handles.ax_main); cla
imshow(frame);
hold on

% Depict Centroids
mkr = scatter(handles.Tracking.X(handles.CurrFrame,:), handles.Tracking.Y(handles.CurrFrame,:),...
    [],handles.Tracking.Color,'filled'); mkr.MarkerEdgeColor = [0 0 0]; clear mkr;

% Indicate tracked animals
if get(handles.tg_indicateBlobs, 'Value') && sum(~isnan(handles.Tracking.X(handles.CurrFrame,:)))>0
    % Iterate over IDs and indicate them
    aniList = get(handles.pop_aniList, 'String');
    % Get center of IDs
    %     ID_center = [nanmedian(handles.Tracking.X(handles.CurrFrame,:)); nanmedian(handles.Tracking.Y(handles.CurrFrame,:))];
    
    if handles.Tracking.nAnimals == 1
        C = [handles.Tracking.X(handles.CurrFrame,1)-1, handles.Tracking.Y(handles.CurrFrame,1)+1];
        idx=1;
    else
        if handles.n_ani_clust > 1
            [idx,C] = kmedoids([handles.Tracking.X(handles.CurrFrame,:)', handles.Tracking.Y(handles.CurrFrame,:)'], handles.n_ani_clust);
        else
            C = [median(handles.Tracking.X(handles.CurrFrame,:)), median(handles.Tracking.Y(handles.CurrFrame,:))];
            idx=1;
        end        
    end
    
    ID_maxDist = mean(size(handles.medianBG))*0.05;
    for iAni = 1:handles.Tracking.nAnimals
       try
        if handles.n_ani_clust > 1 || handles.Tracking.nAnimals == 1
            ID_center = C(idx(iAni),:)';
        else
           ID_center = [nanmedian(handles.Tracking.X(handles.CurrFrame,:)); nanmedian(handles.Tracking.Y(handles.CurrFrame,:))];
        end
       catch
           ID_center = [0; 0];
       end
       
        % Get angle to ID center
        ID_dir = [handles.Tracking.X(handles.CurrFrame, iAni); handles.Tracking.Y(handles.CurrFrame, iAni)]- ID_center;
        if ID_dir(1)==0 && ID_dir(2)==0
            ID_dir = [handles.Tracking.X(handles.CurrFrame, iAni); handles.Tracking.Y(handles.CurrFrame, iAni)] - [handles.Tracking.X(handles.CurrFrame, iAni)-1; handles.Tracking.Y(handles.CurrFrame, iAni)+1];
        end
        % Get vec length to depict. Max length is 10percent of  max dist
        %         ID_len = (ID_maxDist*0.075) + (ID_maxDist*0.001) * (norm(ID_dir)/ID_maxDist);
        ID_len = ID_maxDist;
        % Get position of anootation
        ID_dir = (ID_dir/norm(ID_dir))*ID_len;
        ID_pos_text = ID_dir + [handles.Tracking.X(handles.CurrFrame, iAni); handles.Tracking.Y(handles.CurrFrame, iAni)];
        ID_pos_line = ID_dir*0.85 + [handles.Tracking.X(handles.CurrFrame, iAni); handles.Tracking.Y(handles.CurrFrame, iAni)];
        if atan2d(ID_dir(2), ID_dir(1)) >= -45 && atan2d(ID_dir(2), ID_dir(1)) <= 45
            ID_align = 'left';
        elseif atan2d(ID_dir(2), ID_dir(1)) <= -135 || atan2d(ID_dir(2), ID_dir(1)) >= 135
            ID_align = 'right';
        else
            ID_align = 'center';
        end
        text(ID_pos_text(1), ID_pos_text(2), aniList(iAni,:), 'Color', handles.Tracking.Color(iAni,:), 'Interpreter', 'none', 'HorizontalAlignment', ID_align)
        plot([handles.Tracking.X(handles.CurrFrame,iAni), ID_pos_line(1)],[handles.Tracking.Y(handles.CurrFrame,iAni), ID_pos_line(2)], 'Color', handles.Tracking.Color(iAni,:), 'LineWidth', 0.5)
    end%iAni
    
end% if indicate tracked animals


% Depict everything
drawnow;
hold off

clear frame





%--------------------------------------------------------------------------
%                              CreateFcn
%--------------------------------------------------------------------------
% Executes during object creation, after setting all properties.

% Style: EDIT
% --- addID
function ed_addID_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
% --- currentFrame
function ed_currentFrame_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
% --- endTrack
function ed_endTrack_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
% --- ErodeDilateErode
function ed_ErodeDilateErode_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
% --- flatfield_sigma
function ed_flatfield_sigma_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
% --- fraction_for_BG
function ed_fraction_for_BG_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
% --- genBlob_region
function ed_genBlob_region_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
% --- nAnimals
function ed_nAnimals_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
% --- playSteps
function ed_playSteps_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
% --- startDel
function ed_startDel_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
% --- startFillMissing
function ed_startFillMissing_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
% --- startTrack
function ed_startTrack_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
% --- stopDel
function ed_stopDel_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
% --- stopFillMissing
function ed_stopFillMissing_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
% --- threshold
function ed_threshold_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
% --- track_steps
function ed_track_steps_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% Style: POPUPMENU
% --- aniList
function pop_aniList_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
% --- cautious
function pop_cautious_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
% --- cm
function pop_cm_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
% --- fillMissingMethod
function pop_fillMissingMethod_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



% Style: SLIDER
% --- main
function sl_main_CreateFcn(hObject, eventdata, handles)
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end



%--------------------------------------------------------------------------
%                                Menu
%--------------------------------------------------------------------------
%
% hObject    -   handle to FCN (see GCBO)
% eventdata  -   reserved - to be defined in a future version of MATLAB
% handles    -   structure with handles and user data (see GUIDATA)

% --------------------------------------------------------------------
function mn_n_ani_clust_Callback(hObject, eventdata, handles)
% Nothing is happening here

function mn_n_ani_clust_1_Callback(hObject, eventdata, handles)
handles.n_ani_clust = 1;
% Update figure
handles = updateFigure(handles);
% Update handles structure
guidata(hObject, handles);

function mn_n_ani_clust_2_Callback(hObject, eventdata, handles)
handles.n_ani_clust = 2;
% Update figure
handles = updateFigure(handles);
% Update handles structure
guidata(hObject, handles);

function mn_n_ani_clust_3_Callback(hObject, eventdata, handles)
handles.n_ani_clust = 3;
% Update figure
handles = updateFigure(handles);
% Update handles structure
guidata(hObject, handles);

function mn_n_ani_clust_4_Callback(hObject, eventdata, handles)
handles.n_ani_clust = 4;
% Update figure
handles = updateFigure(handles);
% Update handles structure
guidata(hObject, handles);



% --------------------------------------------------------------------
function mn_tracking_prudence_Callback(hObject, eventdata, handles)
% Nothing is happeing here

function mn_tracking_prudence_0_Callback(hObject, eventdata, handles)
handles.cautious = 1;
% Update handles structure
guidata(hObject, handles);

function mn_tracking_prudence_1_Callback(hObject, eventdata, handles)
handles.cautious = 2;
% Update handles structure
guidata(hObject, handles);

function mn_tracking_prudence_2_Callback(hObject, eventdata, handles)
handles.cautious = 3;
% Update handles structure
guidata(hObject, handles);

function mn_tracking_prudence_3_Callback(hObject, eventdata, handles)
handles.cautious = 4;
% Update handles structure
guidata(hObject, handles);



function mn_openVideo_Callback(hObject, eventdata, handles)

% Ask the user to specify a video file
[handles.CurrFile, handles.CurrFilePath] = uigetfile({'*.mp4'; '*.avi'}, 'Select a video file');

f = waitbar(0, {'Please wait while we create a video object to'; 'read video data from the file specified...'});

% Extract the basename
handles.CurrTrial = handles.CurrFile(1:end-4);

% Import video object
handles.Video.Obj = VideoReader([handles.CurrFilePath, handles.CurrFile]);
handles.Video.NrFrames = get(handles.Video.Obj, 'numberOfFrames')-1;
set(handles.ed_genBlob_region, 'String', ['[1:1:', num2str(handles.Video.NrFrames),']'])

% Already create background variable
handles.medianBG = zeros(handles.Video.Obj.Width, handles.Video.Obj.Height);

% Indicate that something is happening
waitbar(0.5, f); pause(0.1)

% Update display of current file
set(handles.tx_static_title, 'String', handles.CurrTrial)

% Update slider
set(handles.sl_main,...
    'Min', 1,...
    'Max', handles.Video.NrFrames,...
    'SliderStep', [1/(handles.Video.NrFrames-1) , 10/(handles.Video.NrFrames-1)])

% Check whether blobs are already pre-generated
if isfile([handles.CurrFilePath, handles.CurrTrial, '_blobs.txt'])
    handles.Tracking.PrecompBlobs.Logical = 1;
    handles.fid = fopen( [handles.CurrFilePath, handles.CurrTrial, '_blobs.txt']);
    % Get line numbers
    handles.Tracking.PrecompBlobs.Lines = nan(handles.Video.NrFrames,1);
    handles.Tracking.PrecompBlobs.Lines(1) = 0;
    for iFrame = 2:handles.Video.NrFrames
        fgetl(handles.fid);
        handles.Tracking.PrecompBlobs.Lines(iFrame) = ftell(handles.fid);
    end
    
    set(handles.cb_use_gen_blobs, 'Enable', 'on');
    
else
    handles.Tracking.PrecompBlobs.Logical = 0;
    set(handles.cb_use_gen_blobs, 'Enable', 'off');
end

% Check whether mask-video has already been pre-generated
if isfile([handles.CurrFilePath, handles.CurrTrial, '_mask.mp4'])
    handles.Tracking.PrecompMasks.Logical = 1;
    set(handles.cb_use_gen_mask, 'Enable', 'on');
else
    handles.Tracking.PrecompMasks.Logical = 0;
    set(handles.cb_use_gen_mask, 'Enable', 'off');
end

% Check whether there is an calibration
if isfile([handles.CurrFilePath, handles.CurrTrial, '_CamCalib.mat'])
    cameraParams = load([handles.CurrFilePath, handles.CurrTrial, '_CamCalib.mat'], 'cameraParams');
    handles.cameraParams = cameraParams.cameraParams;
else
    handles.cameraParams = cameraParameters;
end

% Create dummy variable for ID pos
handles.Tracking.X = nan(handles.Video.NrFrames, 1);
handles.Tracking.Y = nan(handles.Video.NrFrames, 1);

% Color
cm_pos = get(handles.pop_cm, 'Value');
cm_string = get(handles.pop_cm, 'String');
handles.Tracking.Color = eval([cm_string{cm_pos},'(1)']);

% Update figure
handles.CurrFrame = 1;
handles = updateFigure(handles);

% Indicate that we are done loading
waitbar(1, f); pause(0.1)
close(f)
clear f

% Enable options
handles = UnlockOptions(handles, 'VideoLoaded');

% Update handles structure
guidata(hObject, handles);



% -------------------------------------------------------------------------
function mn_masks_main_Callback(hObject, eventdata, handles)
% Nothing is happening here


% -------------------------------------------------------------------------
function mn_masks_rectangles_Callback(hObject, eventdata, handles)
% Nothing is happeing here

function mn_masks_4_rectangles_Callback(hObject, eventdata, handles)
handles = RectangularMasks(handles, 4);
% Update handles structure
guidata(hObject, handles);

function mn_masks_3_rectangles_Callback(hObject, eventdata, handles)
handles = RectangularMasks(handles, 3);
% Update handles structure
guidata(hObject, handles);

function mn_masks_2_rectangles_Callback(hObject, eventdata, handles)
handles = RectangularMasks(handles, 2);
% Update handles structure
guidata(hObject, handles);

function mn_masks_1_rectangles_Callback(hObject, eventdata, handles)
handles = RectangularMasks(handles, 1);
% Update handles structure
guidata(hObject, handles);


% -------------------------------------------------------------------------
function mn_masks_circles_Callback(hObject, eventdata, handles)
% Nothing is happeing here

function mn_masks_4_circles_Callback(hObject, eventdata, handles)
handles = CircularMasks(handles, 4);
% Update handles structure
guidata(hObject, handles);

function mn_masks_3_circles_Callback(hObject, eventdata, handles)
handles = CircularMasks(handles, 3);
% Update handles structure
guidata(hObject, handles);

function mn_masks_2_circles_Callback(hObject, eventdata, handles)
handles = CircularMasks(handles, 2);
% Update handles structure
guidata(hObject, handles);

function mn_masks_1_circles_Callback(hObject, eventdata, handles)
handles = CircularMasks(handles, 1);
% Update handles structure
guidata(hObject, handles);






function mn_openTracks_Callback(hObject, eventdata, handles)

% Ask the user to specify a file
[CurrFile, CurrFilePath] = uigetfile({'*.csv';}, 'Select a csv file');

f = waitbar(0, 'Please wait while we load your file...');

% Load file
Tracks = readtable([CurrFilePath,CurrFile]);

% Get unique IDs
IDs = unique(Tracks.id);
try
    IDs = str2double(IDs);
    if sum(isnan(IDs)) == length(IDs)
        IDs = unique(Tracks.id);
    end
end
handles.Tracking.nAnimals = length(IDs);

% Set color for each animal
cm_pos = get(handles.pop_cm, 'Value');
cm_string = get(handles.pop_cm, 'String');
handles.Tracking.Color = eval([cm_string{cm_pos},'(handles.Tracking.nAnimals)']);

% Preallocation
handles.Tracking.X = nan(handles.Video.NrFrames, handles.Tracking.nAnimals);
handles.Tracking.Y = nan(handles.Video.NrFrames, handles.Tracking.nAnimals);


for iAni = 1:handles.Tracking.nAnimals
    
    if iscell(IDs)
        idx = find(strcmp(Tracks.id, IDs{iAni}));
    else
        idx = find(Tracks.id == IDs(iAni));
    end
    handles.Tracking.X(1:length(idx), iAni) = Tracks.pos_x(idx);
    handles.Tracking.Y(1:length(idx), iAni) = Tracks.pos_y(idx);
    
    % Indicate progress
    waitbar(iAni/handles.Tracking.nAnimals, f)
    
end%iAni

handles.Tracking.X = handles.Tracking.X(1:handles.Video.NrFrames,:);
handles.Tracking.Y = handles.Tracking.Y(1:handles.Video.NrFrames,:);

% Treat everything as manual annotation
handles.Tracking.Manual = zeros(handles.Video.NrFrames, handles.Tracking.nAnimals);
idx = find(~isnan(handles.Tracking.X));
handles.Tracking.Manual(idx) = 1;

% Update GUI
set(handles.ed_nAnimals, 'String', num2str(length(IDs)))
if iscell(IDs)
    set(handles.pop_aniList, 'String', IDs)
else
    set(handles.pop_aniList, 'String', num2str(IDs))
end
set(handles.pop_aniList, 'Value', 1)
% Enable options
handles = UnlockOptions(handles, 'NumOfAniSet');

% Update figure
handles.CurrFrame = 1;
handles = updateFigure(handles);

close(f)

% Update handles structure
guidata(hObject, handles);

function mn_save_Callback(hObject, eventdata, handles)

% Determine final number of rows
try
nRows = handles.Video.NrFrames * handles.Tracking.nAnimals;
% Get list of IDs
aniList = get(handles.pop_aniList, 'String');
% Preallocation
cnt = nan(nRows,1);
frame = nan(nRows,1);
pos_x = nan(nRows,1);
pos_y = nan(nRows,1);
id = cell(nRows,1);

% Check whether to scale back tracking
if isfield(handles.Tracking, 'Adjustments')
    answer = questdlg('Would you like to re-center and re-normalize the tracking?', ...
        'Re-scale data',...
        'Yes', 'No', 'Yes');
    switch answer2
        case 'Yes'
            DoRescale = 1;
        case 'No'
            DoRescale = 0;
    end
else
    DoRescale = 0;
end

% Iterate over all frames and create a table with the results in the same
% format as Tracktor
cnt_helper = 1;
f = waitbar(0, 'Please wait while we save your tracking...');
for iFrame = 1:handles.Video.NrFrames
    for iAni = 1:handles.Tracking.nAnimals
        
        cnt(cnt_helper) = cnt_helper-1;
        frame(cnt_helper) = iFrame;
        if DoRescale
            pos_x(cnt_helper) = (handles.Tracking.X(iFrame, iAni)-handles.Tracking.Adjustments(1))/handles.Tracking.Adjustments(3);
            pos_y(cnt_helper) = (handles.Tracking.Y(iFrame, iAni)-handles.Tracking.Adjustments(2))/handles.Tracking.Adjustments(3);
        else
            pos_x(cnt_helper) = handles.Tracking.X(iFrame, iAni);
            pos_y(cnt_helper) = handles.Tracking.Y(iFrame, iAni);
        end
        id{cnt_helper} = aniList(iAni,:);
        
        cnt_helper = cnt_helper+1;
        
    end%iAni
    
    waitbar(iFrame/handles.Video.NrFrames, f)
end%iFrame

finalTable = table(cnt, frame, pos_x, pos_y, id);
writetable(finalTable,[handles.CurrFilePath, handles.CurrTrial, '_tracked.csv'])

close(f)

end

if isfield(handles, 'Annotation')
    Annotation = handles.Annotation;
    save([handles.CurrFilePath, handles.CurrTrial, '_annotation.mat'], 'Annotation')
end
% writetable(table(handles.Annotation.Masks.Circular(:,1),handles.Annotation.Masks.Circular(:,2),handles.Annotation.Masks.Circular(:,3), 'VariableNames', {'x', 'y', 'r'}), [handles.CurrFilePath, handles.CurrTrial, '_MasksAnnotation.csv'])



% Update handles structure
guidata(hObject, handles);








%--------------------------------------------------------------------------
%                              Callbacks
%--------------------------------------------------------------------------
% Executes on button press:
% checkbox (cb), pushbutton (pb), radiobutton(rb), togglebutton (tg)
%
% hObject    -   handle to FCN (see GCBO)
% eventdata  -   reserved - to be defined in a future version of MATLAB
% handles    -   structure with handles and user data (see GUIDATA)


% Style: CHECKBOX ---------------------------------------------------------
function cb_adjust_contrast_Callback(hObject, eventdata, handles)
% Update figure
handles = updateFigure(handles);
% Update handles structure
guidata(hObject, handles);

function cb_deleteAll_Callback(hObject, eventdata, handles)
% Update handles structure
guidata(hObject, handles);

function cb_flatfield_Callback(hObject, eventdata, handles)
% Update figure
handles = updateFigure(handles);
% Update handles structure
guidata(hObject, handles);

function cb_interpolateAll_Callback(hObject, eventdata, handles)
% Update handles structure
guidata(hObject, handles);

function cb_nextFrame_Callback(hObject, eventdata, handles)
% Update handles structure
guidata(hObject, handles);

function cb_reduce_haze_Callback(hObject, eventdata, handles)
% Update figure
handles = updateFigure(handles);
% Update handles structure
guidata(hObject, handles);

function cb_sharpen_Callback(hObject, eventdata, handles)
% Update figure
handles = updateFigure(handles);
% Update handles structure
guidata(hObject, handles);

function cb_trackAll_Callback(hObject, eventdata, handles)
% Update handles structure
guidata(hObject, handles);

function cb_use_gen_blobs_Callback(hObject, eventdata, handles)

if hObject.Value
    handles.fid=fopen([handles.CurrFilePath, handles.CurrTrial, '_blobs.txt']);
    handles = UnlockOptions(handles, 'BackgroundSubtracted');
else
    fclose(handles.fid);
    handles = UnlockOptions(handles, 'BackgroundNotSubtracted');
end

handles = updateFigure(handles);

% Update handles structure
guidata(hObject, handles);

function cb_use_gen_mask_Callback(hObject, eventdata, handles)
if hObject.Value
    if isfile([handles.CurrFilePath, handles.CurrFile(1:end-4), '_mask.mp4'])
        handles.Video.Obj = VideoReader([handles.CurrFilePath, handles.CurrFile(1:end-4), '_mask.mp4']);
    else
        beep
        warning('no *mask.mp4 file found')
        hObject.Value = 0;
    end
    handles = UnlockOptions(handles, 'BackgroundSubtracted');
else    
    handles.Video.Obj = VideoReader([handles.CurrFilePath, handles.CurrFile]);
    handles = UnlockOptions(handles, 'BackgroundNotSubtracted');
end
updateFigure(handles)
% Update handles structure
guidata(hObject, handles);


% Style: EDIT -------------------------------------------------------------
function ed_addID_Callback(hObject, eventdata, handles)

% Get the new animal's ID
newAni = get(hObject, 'String');

% Get the current list of IDs
AniList = get(handles.pop_aniList, 'String');

% Check whether ID is unique
if sum(strcmp(AniList, newAni)) > 0
    
    % Error: new ID is already given
    beep
    msgbox('IDs must be unique', 'Invalid ID', 'error');
    
else
    
    % Concatenate lists
    AniList{end+1,1} = newAni;
    
    % Add columns in tracking structure
    handles.Tracking.X = [handles.Tracking.X, nan(handles.Video.NrFrames, 1)];
    handles.Tracking.Y = [handles.Tracking.Y, nan(handles.Video.NrFrames, 1)];
    handles.Tracking.Manual = [handles.Tracking.Manual, zeros(handles.Video.NrFrames, 1)];
    handles.Tracking.nAnimals = length(AniList);
    
    % Update popmenu
    set(handles.pop_aniList, 'String', AniList);
    set(handles.pop_aniList, 'Value', length(AniList));
    
    % Update settings about number of animals
    set(handles.ed_nAnimals, 'String', num2str(length(AniList)))
    
    % Update colors
    handles.Tracking.Color = jet(length(AniList));
    
end

% Update th edit field
set(hObject, 'String', '')

% Update handles structure
guidata(hObject, handles);

function ed_currentFrame_Callback(hObject, eventdata, handles)

% Update figure
handles.CurrFrame = str2double(get(hObject, 'String'));
handles = updateFigure(handles);

% Update handles structure
guidata(hObject, handles);

function ed_endTrack_Callback(hObject, eventdata, handles)

% Update handles structure
guidata(hObject, handles);

function ed_ErodeDilateErode_Callback(hObject, eventdata, handles)

% Update figure
handles = updateFigure(handles);

% Update handles structure
guidata(hObject, handles);

function ed_flatfield_sigma_Callback(hObject, eventdata, handles)
handles = updateFigure(handles);

% Update handles structure
guidata(hObject, handles);

function ed_fraction_for_BG_Callback(hObject, eventdata, handles)

% Update handles structure
guidata(hObject, handles);

function ed_genBlob_region_Callback(hObject, eventdata, handles)

% Update handles structure
guidata(hObject, handles);

function ed_nAnimals_Callback(hObject, eventdata, handles)

% Get the number of animals set by the user
nAni = round(str2double(get(hObject, 'String')), 0);
% Check whether it is a number. If not, beep
if isnan(nAni) || nAni<1
    beep
    msgbox('Number of animals has to be an integer number greater than zero', 'Invalid input', 'error');
else
    % Create a list of IDs for pop_aniList
    list_string = cell(nAni,1);
    for iAni = 1:nAni
        list_string{iAni,1} = ['A', sprintf('%02d', iAni)];
    end%iAni
    
    % Update pop_aniList
    set(handles.pop_aniList, 'Value', 1)
    set(handles.pop_aniList, 'String', list_string)
    
    % Create structure to save tracking to
    handles.Tracking.X = nan(handles.Video.NrFrames, nAni);
    handles.Tracking.Y = nan(handles.Video.NrFrames, nAni);
    
    % Keep track of manual annotations
    handles.Tracking.Manual = zeros(handles.Video.NrFrames, nAni);
    
    % Save number of animals, too
    handles.Tracking.nAnimals = nAni;
    
    % Set color for each animal
    handles.Tracking.Color = jet(nAni);
    
    
end%if number

% Enable options
handles = UnlockOptions(handles, 'NumOfAniSet');

% Update handles structure
guidata(hObject, handles);

function ed_playSteps_Callback(hObject, eventdata, handles)

% Update handles structure
guidata(hObject, handles);

function ed_startDel_Callback(hObject, eventdata, handles)

% Update handles structure
guidata(hObject, handles);

function ed_startFillMissing_Callback(hObject, eventdata, handles)

% Update handles structure
guidata(hObject, handles);

function ed_startTrack_Callback(hObject, eventdata, handles)

% Update handles structure
guidata(hObject, handles);

function ed_stopDel_Callback(hObject, eventdata, handles)

% Update handles structure
guidata(hObject, handles);

function ed_stopFillMissing_Callback(hObject, eventdata, handles)

% Update handles structure
guidata(hObject, handles);

function ed_threshold_Callback(hObject, eventdata, handles)

% Update figure
handles = updateFigure(handles);

% Update handles structure
guidata(hObject, handles);

function ed_track_steps_Callback(hObject, eventdata, handles)

% Update handles structure
guidata(hObject, handles);


% Style: RADIOBUTTON ------------------------------------------------------
function rd_help_addID_Callback(hObject, eventdata, handles)

% String to display
str = {'{\bfHelp: Add ID}';...
    ['To add the ID of an individual or an object that should be tracked,',...
    ' simply write the name of it in the edit box and press Enter. This will',...
    ' add the name to the ', '{\itList of Animals}', ' in the popup menu above',...
    ' and update the ', '{\itNumber of Animals}.']};

% Display help
createmode.WindowStyle = 'modal';
createmode.Interpreter = 'tex';
msgbox(str, 'Add ID', 'help', createmode);

% Set back button's value
set(hObject, 'Value', 0)

% Update handles structure
guidata(hObject, handles);

function rd_help_assign_ID_Callback(hObject, eventdata, handles)

% String to display
str = {'{\bfHelp: Assign ID to Location}';...
    ['Assign currently selected ID to a specific location. By enabling the',...
    ' checkbox on the right, multiple consecutive frames can be labeled. For this,',...
    ' follow instructions on the top of the window.']};

% Display help
createmode.WindowStyle = 'modal';
createmode.Interpreter = 'tex';
msgbox(str, 'Add ID', 'help', createmode);

% Set back button's value
set(hObject, 'Value', 0)

% Update handles structure
guidata(hObject, handles);

function rd_help_autoassign_Callback(hObject, eventdata, handles)

% String to display
str = {'{\bfHelp: Auto-Assign IDs to Blobs}';...
    ['For N animals, this assigns the correspondnig IDs to the',...
    ' biggest N blobs.']};

% Display help
createmode.WindowStyle = 'modal';
createmode.Interpreter = 'tex';
msgbox(str, 'Add ID', 'help', createmode);

% Set back button's value
set(hObject, 'Value', 0)

% Update handles structure
guidata(hObject, handles);

function rd_help_del_Callback(hObject, eventdata, handles)

% String to display
str={'{\bfHelp: Delete Position of Current ID}';...
    ['Sometimes, tracking error occur that require to delete detections from',...
    ' one frame or several. To specify from which ID the tracking should be',...
    ' deleted, select it in the {\itList of Animals}. Next, specify the range',...
    ' of frames from which the tracking should be deleted by entering the',...
    'frame numbers in the edit boxes next to the push button.'];
    ['If not only the tracking for one animal but for all is incorrect and',...
    ' has to be removed, it can be tedious to repeat the procedure of ID',...
    ' selection, range specification, and button pressing N times.'...
    ' To accelerate things, activate the checkbox',...
    ' {\itdelete all possible animals}. This will remove tracking from all',...
    ' animals for the set range of frames.'];...
    ['Note, once deleted, there is no way to retrieve the lost information!',...
    ' Therefore, make sure all entries are correct!']};

% Display help
createmode.WindowStyle = 'modal';
createmode.Interpreter = 'tex';
msgbox(str, 'Delete Position of Current ID', 'help', createmode);

% Set back button's value
set(hObject, 'Value', 0)

% Update handles structure
guidata(hObject, handles);

function rd_help_ErodeDilateErode_Callback(hObject, eventdata, handles)

% String to display
str={'{\bfHelp: Erode-Dilate-Erode Blobs}';...
    [' After applying a threshold, the binary image might be noisy, and blobs'...
    ' can appear frayed. To get smooth, clearly separable blobs that make', ...
    ' tracking easier, we use a cascade of image manipulations that',...
    ' erode, dilate and again erode the binary image. For this, disk-shaped',...
    ' structuring elements are used. The three number the user must enter',...
    ' specify the radii of these elements. It is possible to enter [0 0 0]',...
    ' to avoid the image manipulations.']};

% Display help
createmode.WindowStyle = 'modal';
createmode.Interpreter = 'tex';
msgbox(str, 'Erode-Dilate-Erode Blobs', 'help', createmode);

% Set back button's value
set(hObject, 'Value', 0)

% Update handles structure
guidata(hObject, handles);

function rd_help_generate_blobs_Callback(hObject, eventdata, handles)

% String to display
str={'{\bfHelp: 2.6 Generate Blobs}';...
    ['All previous steps, i.e. image processing, background subtraction,',...
    ' image inversion, binarization, erosion-dilation-erosion, take time.',...
    ' If only a single animals should be tracked, this has to be done only',...
    ' once per frame. However, with multiple animals and the resulting need',...
    ' for correction, it is likely to come back to specific frames multiple',...
    ' times. Thus, it is advisable to generate blobs for all specified frames',...
    ' ones at the beginning to improve your BlobMaster3000 tracking experience.'];...
    ['Range of frames can be denoted in standard Matlab syntax,',...
    ' e.g. [1:end] for all possible frames, or [1:25:2000] for frames ',...
    ' starting at frame 1 in steps of 25 until frame 2000.']};

% Display help
createmode.WindowStyle = 'modal';
createmode.Interpreter = 'tex';
msgbox(str, 'Erode-Dilate-Erode Blobs', 'help', createmode);

% Set back button's value
set(hObject, 'Value', 0)

% Update handles structure
guidata(hObject, handles);

function rd_help_IDlist_Callback(hObject, eventdata, handles)

% String to display
str={'{\bfHelp: List of IDs}';...
    ['List of all possible IDs. To delete a specific ID from the list, select',...
    '  it and press >>Remove ID<<']};

% Display help
createmode.WindowStyle = 'modal';
createmode.Interpreter = 'tex';
msgbox(str, 'Erode-Dilate-Erode Blobs', 'help', createmode);

% Set back button's value
set(hObject, 'Value', 0)

% Update handles structure
guidata(hObject, handles);

function rd_help_image_processing_Callback(hObject, eventdata, handles)

% String to display
str={'{\bfHelp: 1. Trial Settings  &  Image Processing  &  Background}';...
    ['Trial setting:'];...
    [' Upon video selection, the file name of the current trial will be',...
    ' depicted. Next, set the number of animals. This initializes all sorts',...
    ' of variables. Since re-initialization would overwrite all of your',...
    ' current tracking, the corresponding edit field will be disabled',...
    ' afterwards. To change the number of IDs see',...
    ' 3. Track Identities >> Remove ID / Add ID.'];...
    [' '];...
    ['Image processing:'];...
    ['Optimizing the video image is the first step for a successful tracking',...
    ' experience. Until now, BlobMaster3000 offers four different processing',...
    ' steps that will be applied to the frame in the following order:'];...
    ['1. Flat-field correction. If the image has severe shading distortion,',...
    ' e.g. caused by a not uniform lighting, this will yield a corrected',...
    ' image with a more uniform brightness.'];...
    ['2. Haze reduction. Images can be highly degraded due to poor lighting',...
    ' conditions. This will use a low-light image enhancement to improve the',...
    ' visibility of an image.'];...
    ['3. Contrast enhancement. This adjusts image intensity values by',...
    ' saturating the bottom 1 percent and the top 1 percent of all pixel',...
    ' values. This operation increases the contrast of the image.'];...
    ['4. Sharpen image. As a final step, the image can be sharpen using',...
    ' unsharp masking.'];...
    [' '];...
    ['Background:'];...
    ['The tracking approach of BlobMaster3000 relies on a simple background',...
    ' subtraction. For this, set the fraction of all possible frames that',...
    ' should be used to calculate the median image, i.e. the background.']};

% Display help
createmode.WindowStyle = 'modal';
createmode.Interpreter = 'tex';
msgbox(str, 'Erode-Dilate-Erode Blobs', 'help', createmode);

% Set back button's value
set(hObject, 'Value', 0)

% Update handles structure
guidata(hObject, handles);

function rd_help_interpolate_Callback(hObject, eventdata, handles)

% String to display
str={'{\bfHelp: Interpolate}';...
    ['Sometime, an animal cannot be tracked for a few frames resulting in a',...
    ' gap of NaNs. But since gaps can be filled by either manual annotation', ...
    ', (enable {\itmultiple frame} + {\itAssign ID to Location}, next/previous frame by arrow buttons)',...
    ' or by interpolation, this is no problem. To fill a gap for one specific',...
    ' animal, make sure it is selected via the {\itList of Animals} popup', ...
    ' menu. To fill gaps for all animals, enable the checkbox',...
    ' {\itinterpolate all possible animals}. By specifying an interpolation',...
    ' method (popup menu next to pushbutton) and a range of frames via the two',...
    ' edit boxes, BlobMaster 3000 will use the inbuilt function {\itfillmissing()}',...
    ' to fill the gaps.']};

% Display help
createmode.WindowStyle = 'modal';
createmode.Interpreter = 'tex';
msgbox(str, 'Interpolate', 'help', createmode);

% Set back button's value
set(hObject, 'Value', 0)

% Update handles structure
guidata(hObject, handles);

function rd_help_threshold_Callback(hObject, eventdata, handles)

% String to display
str={'{\bfHelp: 2.3 Threshold}';...
    ['Tracking is based on a nearest-neighbor principle that tracks the',...
    ' centroids of white blobs with an assigned identity. To get the',...
    ' black-and-white image, we apply a threshold to it resulting in a logical',...
    ' map of ones (white) and zeros (black). Therefore, applying a reasonable',...
    ' threshold is crucial to get well-tracked individuals.', ...
    ' Consequently, it enables following operations. As the video image is',...
    ' converted to grayscale, threhshold values should be between',...
    ' 0 (= no threshold is applied), and 1 (only maximally bright pixels are detected).']};

% Display help
createmode.WindowStyle = 'modal';
createmode.Interpreter = 'tex';
msgbox(str, 'Add ID', 'help', createmode);

% Set back button's value
set(hObject, 'Value', 0)

% Update handles structure
guidata(hObject, handles);

function rb_help_track_Callback(hObject, eventdata, handles)

% String to display
str={'{\bfHelp: Track!}';...
    ['This is where the magic happens! Give a range of frames for which the',...
    ' currently selected animal (selected via the popup menu {\itList of Animals})',...
    ' should be tracked. To track all possible animals, simply enable the',...
    ' checkbox {\ittrack all possible animals}. An ID can be tracked starting',...
    ' with an assigned location.'];...
    ' An example:';...
    ['The location for ID {\itAni_01} has been assigned for the frames 5 to',...
    ' 50 and 65 to 100. The user gives as a range for tracking: from=1 and',...
    ' to=200. If no errors (see below) occur, these settings result in a',...
    ' complete tracking for {\itAni_01} between frames 5 and 200. As the',...
    ' location in frame=1 has not been assigned, {\itBlobMaster3000} has no',...
    ' point of origin from which it can start tracking the blob. However,',...
    ' starting from frame=50, the program can follow the blob until frame=64.',...
    ' It will not overwrite already existing assignments but will just',...
    ' continue after frame=100.'];...
    ['If multiple animals are to be tracked, it might be that their blobs are',...
    ' merged as the animals get too close to each other. This results in a',...
    ' so-called {\itcrossing} with the individual IDs sharing the same centroid',...
    ' (= center of the blob). This can be detected by the program and stops the',...
    ' tracking automatically if the crossing cannot be resolved. Now the',... 
    ' user can fast-forward the video until the blobs are separated again,',...
    ' re-assign their identities, go back to the point the tracking stopped,',...
    ' and set a new range for tracking (usually start at the frame the',...
    ' tracking stopped +1). The frame to start with will be filled into the',...
    ' edit box automatically.']};

% Display help
createmode.WindowStyle = 'modal';
createmode.Interpreter = 'tex';
msgbox(str, 'Track!', 'help', createmode);

% Set back button's value
set(hObject, 'Value', 0)

% Update handles structure
guidata(hObject, handles);

function rd_help_watershed_Callback(hObject, eventdata, handles)

% String to display
str={'{\bfHelp: 2.5(a)  Simple Blobs}';...
    ['The simplest way to generate blobs is to binarize a grayscale image by',...
    ' applying a threshold. Values smaller than the value are set to 0, while',...
    ' values greater are set to 1.'];...
    ' ';
    '{\bfHelp: 2.5(b) Watershed Transform}';...
    ['For experiments with animals that like to aggregate, resulting blobs',...
    ' are likely to overlap. This significantly reduces tracking performance.',...
    ' Thus, it is advisable to use the watershed transform instead of simple',...
    ' thresholding to separate blobs.'];...
    ['The watershed transform finds >>catchment basins<< or >>watershed ',...
    ' ridge lines<< in an image by treating it as a surface where light pixels',...
    ' represent high elevations and dark pixels represent low elevations.',...
    ' The watershed transform can be used to segment contiguous regions of',...
    ' interest into distinct objects.']};

% Display help
createmode.WindowStyle = 'modal';
createmode.Interpreter = 'tex';
msgbox(str, 'Add ID', 'help', createmode);

% Set back button's value
set(hObject, 'Value', 0)

% Update handles structure
guidata(hObject, handles);

% Style: PUSHBUTTON -------------------------------------------------------
function pb_auto_assign_Callback(hObject, eventdata, handles)

% Indicate that the function is active
set(hObject, 'BackgroundColor', [1 0.65 0.4])

% Get current frame. This assumes a binary image.
frame = prepareFrame(handles, handles.CurrFrame);

% Get centroids and sort them by size
labels = bwlabel(frame);
props_centroids = cell2mat( struct2cell( regionprops(labels,'centroid') ));
props_centroids = [props_centroids(1:2:end)', props_centroids(2:2:end)'];
props_area = cell2mat( struct2cell( regionprops(labels,'area') ));
[~, props_sorted] = sort(props_area,'descend');

% Assign IDs to the N biggest blobs
for iAni = 1:handles.Tracking.nAnimals
    handles.Tracking.X(handles.CurrFrame,iAni) = props_centroids(props_sorted(iAni),1);
    handles.Tracking.Y(handles.CurrFrame,iAni) = props_centroids(props_sorted(iAni),2);
end%iAni

% Update figure
handles = updateFigure(handles);

% Indicate that operations are over
set(hObject, 'BackgroundColor', [0.8 0.93 0.98])

% Update handles structure
guidata(hObject, handles);

function pb_delete_ID_Callback(hObject, eventdata, handles)
% Get current animal
currAni_idx = get(handles.pop_aniList, 'Value');
% Remove tracking
handles.Tracking.X = handles.Tracking.X(:,[1:handles.Tracking.nAnimals]~=currAni_idx);
handles.Tracking.Y = handles.Tracking.Y(:,[1:handles.Tracking.nAnimals]~=currAni_idx);
% Remove color
handles.Tracking.Color = handles.Tracking.Color([1:handles.Tracking.nAnimals]~=currAni_idx,:);
% Remove manual tracking
handles.Tracking.Manual = handles.Tracking.Manual(:,[1:handles.Tracking.nAnimals]~=currAni_idx);
% Reduce animal count by one
handles.Tracking.nAnimals = handles.Tracking.nAnimals-1;
% Remove entry from popup menu
list = get(handles.pop_aniList, 'String');
list = list(find([1:handles.Tracking.nAnimals]~=currAni_idx));
set(handles.pop_aniList, 'Value', handles.Tracking.nAnimals);
set(handles.pop_aniList, 'String', list)
% Change number 
set(handles.ed_nAnimals , 'String', handles.Tracking.nAnimals);
% Update figure
handles = updateFigure(handles);



function pb_generate_blobs_Callback(hObject, eventdata, handles)

% Indicate that the function is active
set(hObject, 'BackgroundColor', [1 0.65 0.4])

handles.Tracking.PrecompBlobs.Logical = 0;

% Clear txt file
fid = fopen([handles.CurrFilePath, handles.CurrTrial, '_blobs.txt'], 'wt' );
fclose(fid);
%Enable appending
fid = fopen([handles.CurrFilePath, handles.CurrTrial, '_blobs.txt'], 'a' );
% Get range for which frames
range = eval(get(handles.ed_genBlob_region, 'String'));
% Iterate over frames
f = waitbar(0,'Please wait...');

for iFrame = 1:handles.Video.NrFrames
    addColon = 0;
    if sum(range==iFrame) == 0 || isempty(find(prepareFrame(handles, iFrame)))
        coord = 'NaN';
    else
        coordinates = find(prepareFrame(handles, iFrame))';
        
        % Further compression
        coord = num2str(coordinates(1));
        % Iterate over all coordinates
        for iCoord = 2:length(coordinates)-1
            % If diff=1, use :-notaion
            if coordinates(iCoord) == coordinates(iCoord-1)+1
                addColon = 1;
            else
                if addColon
                    coord = [coord, ':', num2str(coordinates(iCoord-1)), ',', num2str(coordinates(iCoord))];
                    addColon = 0;
                else
                    coord = [coord, ',', num2str(coordinates(iCoord))];
                    addColon = 0;
                end
            end
        end% iCoord
        % Add last pixel
        if coordinates(length(coordinates)) == coordinates(length(coordinates)-1)+1
            coord = [coord, ':', num2str(coordinates(length(coordinates)))];
        else
            coord = [coord, ',', num2str(coordinates(length(coordinates)))];
        end
    end%if
    
    % Write to file
    fprintf(fid, '%s\n%s\n%s', coord);
    waitbar(iFrame/handles.Video.NrFrames,f, ['Please wait... Current frame: ', num2str(iFrame)])
end

close(f)
fclose(fid);
handles.Tracking.PrecompBlobs.Logical = 1;

% Get line numbers
fid = fopen( [handles.CurrFilePath, handles.CurrTrial, '_blobs.txt']);
handles.Tracking.PrecompBlobs.Lines = nan(handles.Video.NrFrames,1);
handles.Tracking.PrecompBlobs.Lines(1) = 0;
for iFrame = 2:handles.Video.NrFrames
    fgetl(fid);
    handles.Tracking.PrecompBlobs.Lines(iFrame) = ftell(fid);
end
fclose(fid);

% Set to use those pre-computed blobs
set(handles.cb_use_gen_blobs, 'Value', 1)

% Indicate that operations are over
set(hObject, 'BackgroundColor', [0.8 0.93 0.98])

% Update handles structure
guidata(hObject, handles);

function pb_assignID_Callback(hObject, eventdata, handles)

% Indicate that the function is active
set(hObject, 'BackgroundColor', [1 0.65 0.4])

% Get currently selected animal
currAni = get(handles.pop_aniList, 'Value');

% Check whether to annotate only this frame or multiple in a row
if get(handles.cb_nextFrame, 'Value')
    
    % Variable to check whether to continue
    DoContinue = 1;
    
    % Tell the user what can be done
    set(handles.tx_static_title, 'String',...
        'Click on Animal. Then, use L-/R-arrow to change frame and any other key to quit')
    
    steps = abs(str2double(get(handles.ed_track_steps, 'String')));
    
    while DoContinue
        
        % Get the animal's current position
        currPos = ginputBM(1, handles.Tracking.Color(currAni,:));
        
        % Save position to tracking structure
        handles.Tracking.X(handles.CurrFrame, currAni) = currPos(1);
        handles.Tracking.Y(handles.CurrFrame, currAni) = currPos(2);
        
        % Keep track of manual annotation
        handles.Tracking.Manual(handles.CurrFrame, currAni) = 1;
        
        k = waitforbuttonpress;% 28 leftarrow | 29 rightarrow
        value = double(get(gcf,'CurrentCharacter'));
        switch value
            case 28
                % Update figure
                handles.CurrFrame = handles.CurrFrame - steps;
            case 29
                % Update figure
                handles.CurrFrame = handles.CurrFrame + steps;
            otherwise
                DoContinue = 0;
        end
        % Update plot
        handles = updateFigure(handles);
        
    end% while
    
else%if one or more frames
    
    % Tell the user what can be done
    set(handles.tx_static_title, 'String',...
        'Click on Animal')
    
    % Get the animal's current position
    currPos = ginputBM(1, handles.Tracking.Color(currAni,:));
    
    % Save position to tracking structure
    handles.Tracking.X(handles.CurrFrame, currAni) = currPos(1);
    handles.Tracking.Y(handles.CurrFrame, currAni) = currPos(2);
    
    % Keep track of manual annotation
    handles.Tracking.Manual(handles.CurrFrame, currAni) = 1;
    
    % Update figure
    handles = updateFigure(handles);
    
end%if one or more frames

% Indicate that operations are over
set(hObject, 'BackgroundColor', [0.8 0.93 0.98])

% Get title back
set(handles.tx_static_title, 'String', handles.CurrTrial)

% Update handles structure
guidata(hObject, handles);

function pb_delAssignment_Callback(hObject, eventdata, handles)

% Indicate that the function is active
set(hObject, 'BackgroundColor', [1 0.65 0.4])

% Get range from where to delete
startDel = str2double(get(handles.ed_startDel, 'String'));
stopDel = str2double(get(handles.ed_stopDel, 'String'));

if ~isnan(startDel) && ~isnan(stopDel) && startDel<=stopDel
    
    if get(handles.cb_deleteAll, 'Value')
        % Overwrite position in tracking structure with NaNs
        handles.Tracking.X(startDel:stopDel, :) = NaN;
        handles.Tracking.Y(startDel:stopDel, :) = NaN;
        % Reset record of manual annotation
        handles.Tracking.Manual(startDel:stopDel, :) = 0;
    else
        % Get currently selected animal
        currAni = get(handles.pop_aniList, 'Value');
        % Overwrite position in tracking structure with NaNs
        handles.Tracking.X(startDel:stopDel, currAni) = NaN;
        handles.Tracking.Y(startDel:stopDel, currAni) = NaN;
        % Reset record of manual annotation
        handles.Tracking.Manual(startDel:stopDel, currAni) = 0;
    end
    
    % Update plot
    handles = updateFigure(handles);
    
else
    beep
    msgbox({'Start and stop frame must be integer numbers'; 'and the start frame has to be smaller or equal than the stop frame'}, 'Invalid input', 'error');
    set(handles.ed_startDel, 'String', 'from')
    set(handles.ed_stopDel, 'String', 'to')
end

% Indicate that operations are over
set(hObject, 'BackgroundColor', [0.8 0.93 0.98])
set(handles.ed_startDel, 'String', 'from')
set(handles.ed_stopDel, 'String', 'to')

% Update handles structure
guidata(hObject, handles);

function pb_fillMissing_Callback(hObject, eventdata, handles)

% Indicate that the function is active
set(hObject, 'BackgroundColor', [1 0.65 0.4])

% Get range from where to track
startFill = str2double(get(handles.ed_startFillMissing, 'String'));
stopFill = str2double(get(handles.ed_stopFillMissing, 'String'));

if ~isnan(startFill) && ~isnan(stopFill) && startFill < stopFill
    
    idx = get(handles.pop_fillMissingMethod, 'Value');
    MethodList = get(handles.pop_fillMissingMethod, 'String');
    FillMethod = MethodList{idx};
    
    % To keep track of manual corrections, detect which frames for
    % which animals have been changed
    gap_before = (isnan(handles.Tracking.X));
    
    if get(handles.cb_interpolateAll , 'Value')
        
        % Fill NaNs
        handles.Tracking.X(startFill:stopFill, :) = fillmissing(handles.Tracking.X(startFill:stopFill, :), FillMethod);
        handles.Tracking.Y(startFill:stopFill, :) = fillmissing(handles.Tracking.Y(startFill:stopFill, :), FillMethod);
        
        % Get remaining gaps
        gap_after = (isnan(handles.Tracking.X));
        
    else
        % Get currently selected animal
        currAni = get(handles.pop_aniList, 'Value');
        
        % Fill NaNs
        handles.Tracking.X(startFill:stopFill, currAni) = fillmissing(handles.Tracking.X(startFill:stopFill, currAni), FillMethod);
        handles.Tracking.Y(startFill:stopFill, currAni) = fillmissing(handles.Tracking.Y(startFill:stopFill, currAni), FillMethod);
        
        % Get remaining gaps
        gap_after = (isnan(handles.Tracking.X));
        
    end
    
    % Keep track of manual annotation by ompareing states before and
    % after filling gaps.
    handles.Tracking.Manual(find(gap_before~=gap_after)) = 1;
    
    % Update figure
    handles.CurrFrame = stopFill;
    handles = updateFigure(handles);
    
else
    beep
    msgbox({'Start and stop frame must be integer numbers'; 'and the start frame has to be smaller than the stop frame'}, 'Invalid input', 'error');
    set(handles.ed_startFillMissing, 'String', 'from')
    set(handles.ed_stopFillMissing, 'String', 'to')
end

% Indicate that operations are over
set(hObject, 'BackgroundColor', [0.8 0.93 0.98])
set(handles.ed_startFillMissing, 'String', 'from')
set(handles.ed_stopFillMissing, 'String', 'to')

% Update handles structure
guidata(hObject, handles);

function pb_CalcBG_Callback(hObject, eventdata, handles)

% So far, the field Annotation in handles corresponds to the BG and
% potential masks. Clear this each time we create a new BG
if isfield(handles, 'Annotation')
    handles = rmfield(handles, 'Annotation');
end

% Indicate that the function is active
set(hObject, 'BackgroundColor', [1 0.65 0.4])

% If the BG for the current trial has been calculated before, ask user to
% import it
if isfile([handles.CurrFilePath, handles.CurrTrial, '_BG.mat'])
    
    % Create question dialog box
    answer = questdlg({'A previously calculated BG has been found.'; 'Do you want to load it?'}, ...
        'Load Back Ground', ...
        'Yes','No','Yes');
    LoadBG = strcmp(answer,'Yes');
    
else
    LoadBG = 0;
end% if load old BG
% Depending on what the user has said, either lod BG or calculate it
if LoadBG
    % Load BG
    load([handles.CurrFilePath, handles.CurrTrial, '_BG'])
else
    
    
    % Get settings set by user (e.g. invert image, subtract background, etc)
    SET.FlatField = get(handles.cb_flatfield, 'Value');
    SET.FlatField_sigma = str2double(get(handles.ed_flatfield_sigma, 'String'));
    SET.Haze = get(handles.cb_reduce_haze, 'Value');
    SET.Contrast = get(handles.cb_adjust_contrast, 'Value');
    SET.Sharpen = get(handles.cb_sharpen, 'Value');
    
    % Get step size
    if contains(get(handles.ed_fraction_for_BG, 'String'), ':')
        Steps = eval(get(handles.ed_fraction_for_BG, 'String'));
        BG_Frames = Steps;
    else
        Steps = str2double(get(handles.ed_fraction_for_BG, 'String'));
        BG_Frames = 1:Steps:handles.Video.NrFrames;
    end
    
    % Preallocation
    BG = zeros(...
        handles.Video.Obj.Height,...
        handles.Video.Obj.Width);
    
    % Indicate that something is happening
    f = waitbar(0,'Please wait...');
    
    
    cnt_frame = 0;
    for iFrame = BG_Frames
        
        
        %         % Read current frame
        %         frame = read(handles.Video.Obj, iFrame);
        %         % Comprise RGB layers into one
        %         if size(frame, 3) > 1
        %             frame = rgb2gray(frame);
        %         end
        %
        %         % Image processing
        %         if SET.FlatField
        %             frame = imflatfield(frame,SET.FlatField_sigma);
        %         end
        %         if SET.Haze
        %             frame = imreducehaze(frame);
        %         end
        %         if SET.Contrast
        %             frame = imcomplement(imreducehaze(imcomplement(frame)));
        %             frame = imadjust(frame);
        %         end
        %         if SET.Sharpen
        %             frame = imsharpen(frame);
        %         end
        
        frame = prepareFrame(handles, iFrame);
        
        BG = BG + double(frame);
        
        % Counter
        cnt_frame = cnt_frame+1;
        waitbar(cnt_frame/length(BG_Frames), f)
        
    end%iFrame
    
    % Calculate the grand median BG
    medianBG = BG/cnt_frame;
    
    close(f)
    clear f
    
end

% Maybe we need a ROI
% Create question dialog box
answer = questdlg('Do you want to apply a ROI?', ...
    'ROI',...
    'No', 'Circle', 'Rectangle', 'Cirle');

switch answer
    case 'Circle'
        
        % Get indices of pixels
        [idx(:,1), idx(:,2)] = find(medianBG>=0);
        % Display BG
        axes(handles.ax_main)
        imshow(uint8(medianBG))
        % Give instructions
        set(handles.tx_static_title, 'String', 'Click on 8 points of the cirlce')
        % Get circle
        Par = CircleFit(fliplr(ginputBM(8, [0.25 0.25 0.25])));
        % Get old title back
        set(handles.tx_static_title, 'String', handles.CurrTrial)
        % Get outlying pixels
        helper = idx-Par(1:2);
        dist = sqrt(sum(helper'.*helper'))';
        idx_dist = find(dist>Par(3));
        % Set all outlying pixels to zero
        medianBG(idx_dist) = zeros(1,length(idx_dist));
        % Show new BG
        imshow(uint8(medianBG))
        
        handles.Annotation.ROI.Type = 'Circle';
        handles.Annotation.ROI.Par = [Par(2), Par(1), Par(3)];
        
        
    case 'Rectangle'
        
        % Get indices of pixels
        [idx(:,1), idx(:,2)] = find(medianBG>=0);
        % Display BG
        axes(handles.ax_main)
        imshow(uint8(medianBG))
        % Give instructions
        set(handles.tx_static_title, 'String', 'Click on the 2 diag. points of the rectangle')
        % Get points
        XY = ginputBM(2, [0.25 0.25 0.25]);
        % Get old title back
        set(handles.tx_static_title, 'String', handles.CurrTrial)
        % Get outlying pixels
        min_x = min(XY(:,2));
        max_x = max(XY(:,2));
        min_y = min(XY(:,1));
        max_y = max(XY(:,1));
        idx_dist = unique([find(idx(:,1) < min_x); find(idx(:,1) > max_x); find(idx(:,2) < min_y); find(idx(:,2) > max_y)]);
        % Set all outlying pixels to zero
        medianBG(idx_dist) = zeros(1,length(idx_dist));
        % Show new BG
        imshow(uint8(medianBG))
        
        handles.Annotation.ROI.Type = 'Rectangle';
        handles.Annotation.ROI.Par = [min_x, min_y, max_x-min_x, max_y-min_y];
        
end%switch

% Add BG to handles
handles.medianBG = uint8(medianBG);

% Indicate that operations are over
set(hObject, 'BackgroundColor', [0.8 0.93 0.98])

% Enable options
handles = UnlockOptions(handles, 'BackgroundLoaded');

% Update handles structure
guidata(hObject, handles);

function pb_play_Callback(hObject, eventdata, handles)

% Make sure we can stop the display after some time via pb_stop_Callback()
hObject.UserData = 0;

% Start looping over frames in specified steps
% for iFrame = handles.CurrFrame : str2double(get(handles.ed_playSteps, 'String')) : handles.Video.NrFrames
steps = str2double(get(handles.ed_playSteps, 'String'));
if steps < 0
    endFrame = 1;
else
    endFrame = handles.Video.NrFrames;
end

for iFrame = handles.CurrFrame : steps : endFrame
    % Check for stop sign
    if hObject.UserData
        break
    end% if stop
    % Update figure
    handles.CurrFrame = iFrame;
    handles = updateFigure(handles);
end%iFrame

% Update handles structure
guidata(hObject, handles);

function pb_stop_Callback(hObject, eventdata, handles)

% Update handles structure
guidata(hObject, handles);

function pb_switch_ids_Callback(hObject, eventdata, handles)

% Indicate that the function is active
set(hObject, 'BackgroundColor', [1 0.65 0.4])

% Give instructions
set(handles.tx_static_title, 'String', 'Click on the 2 IDs that should be switched')

% Get positions
IDs.loc = ginputBM(2, [0.25 0.25 0.25]);

% Get old title back
set(handles.tx_static_title, 'String', handles.CurrTrial)

% Get current positions
curr.Frame = handles.CurrFrame;
curr.X = handles.Tracking.X;
curr.Y = handles.Tracking.Y;
curr.Manual = handles.Tracking.Manual;

% Get first ID 
helper = [curr.X(curr.Frame,:); curr.Y(curr.Frame,:)]' - IDs.loc(1,:);
dist = sqrt(sum(helper'.*helper'))';
[~, IDs.ID_1] = min(dist);

% Get second ID 
helper = [curr.X(curr.Frame,:); curr.Y(curr.Frame,:)]' - IDs.loc(2,:);
dist = sqrt(sum(helper'.*helper'))';
[~, IDs.ID_2] = min(dist);

% Switch entries
% --- 1st
handles.Tracking.X(curr.Frame:end, IDs.ID_1) = curr.X(curr.Frame:end, IDs.ID_2);
handles.Tracking.Y(curr.Frame:end, IDs.ID_1) = curr.Y(curr.Frame:end, IDs.ID_2);
handles.Tracking.Manual(curr.Frame:end, IDs.ID_1) = curr.Manual(curr.Frame:end, IDs.ID_2);
% --- 2nd
handles.Tracking.X(curr.Frame:end, IDs.ID_2) = curr.X(curr.Frame:end, IDs.ID_1);
handles.Tracking.Y(curr.Frame:end, IDs.ID_2) = curr.Y(curr.Frame:end, IDs.ID_1);
handles.Tracking.Manual(curr.Frame:end, IDs.ID_2) = curr.Manual(curr.Frame:end, IDs.ID_1);

% Update figure
handles = updateFigure(handles);

% Indicate that operations are over
set(hObject, 'BackgroundColor', [0.8 0.93 0.98])

% Update handles structure
guidata(hObject, handles);

function pb_track_Callback(hObject, eventdata, handles)

% Indicate that the function is active
set(hObject, 'BackgroundColor', [1 0.65 0.4])


updatePlotWhenDone = 1 ;


% Make sure we can stop the display after some time via pb_stop_Callback()
handles.pb_play.UserData=0;

% Get range from where to track
startTrack = str2double(get(handles.ed_startTrack, 'String'));
stopTrack = str2double(get(handles.ed_endTrack, 'String'));
steps = str2double(get(handles.ed_track_steps, 'String'));

% Iterate over all frames that should be tracked, determine blobs,
% assign new location for each animal based on a
% nearest-neighbor-principle. In short, the new location in the
% next frame is the centroid closest to the current centroid.
if ~isnan(startTrack) && ~isnan(stopTrack)    
    
    % Correct entries
    if stopTrack > handles.Video.NrFrames; stopTrack = handles.Video.NrFrames; end
    if startTrack > handles.Video.NrFrames; startTrack = handles.Video.NrFrames; end
    if stopTrack < 0 stopTrack = 1; end
    if startTrack < 0 startTrack = 1; end    
    
    % Be able to track both ways!
    if startTrack > stopTrack
        steps = -steps;
    end
    
    % Iterate over selected range of frames. Use a while-loop in order to
    % be able to step back in case something didn't work out
    iFrame = startTrack;
    while (iFrame >= min([startTrack stopTrack])) && (iFrame <= max([startTrack stopTrack])-steps)
        
        
        % Check for stop sign
        if handles.pb_play.UserData
            break
        end% if stop
        
        % Indicate tracked animals
        handles.CurrFrame = iFrame;
        handles = updateFigure(handles);
        
        
        % If all trackable animals should be tracked, update list of
        % current animals - It might be that some are now trackable
        % again or some are not anymore
        if get(handles.cb_trackAll, 'Value')
            % Trackable animals are those, with valid locations
            currAni = find(~isnan(handles.Tracking.X(iFrame, :)) & ~isnan(handles.Tracking.Y(iFrame, :)) & ~handles.Tracking.Manual(iFrame+steps,:) & isnan(handles.Tracking.Y(iFrame+steps, :)));
        else
            % Check whether animal has been annotated manully in the
            % next frame.
            % Get the currently selected animal
            currAni = get(handles.pop_aniList, 'Value');
            if handles.Tracking.Manual(iFrame+steps, currAni)
                currAni = [];
            end
        end
        
        
        % Check whethe there is anything to track in the first place
        if ~isempty(currAni)
            
            SET.DoWatershed = 0;
            % Try tracking animals in the next step
            [handles, failed] = trackFcn(handles,iFrame, steps, SET, currAni);
            if ~failed
                % Next frame
                iFrame = iFrame+steps;
                set(handles.tx_static_title, 'BackgroundColor', [0.15 0.15 0.15])
            else
                set(handles.tx_static_title, 'BackgroundColor', [1 0 0])
                % try reducing step size
                steps = steps-1;
                while steps>1 && failed
                    % If all trackable animals should be tracked, update list of
                    % current animals - It might be that some are now trackable
                    % again or some are not anymore
                    if get(handles.cb_trackAll, 'Value')
                        % Trackable animals are those, with valid locations
                        currAni = find(~isnan(handles.Tracking.X(iFrame, :)) & ~isnan(handles.Tracking.Y(iFrame, :)) & ~handles.Tracking.Manual(iFrame+steps,:) & isnan(handles.Tracking.Y(iFrame+steps, :)));
                    else
                        % Check whether animal has been annotated manully in the
                        % next frame.
                        % Get the currently selected animal
                        currAni = get(handles.pop_aniList, 'Value');
                        if handles.Tracking.Manual(iFrame+steps, currAni)
                            currAni = [];
                        end
                    end
                    [handles, failed] = trackFcn(handles,iFrame, steps, SET,currAni);
                    if ~failed
                        % Next frame
                        iFrame = iFrame+steps;
                    end
                    steps = steps-1;
                end
                % Get back normal step size
                steps = str2double(get(handles.ed_track_steps, 'String'));
            end
            % If things are still broken, try watershed
            if failed
                SET.DoWatershed = handles.cautious;
                while SET.DoWatershed>0 && failed
                    [handles, failed] = trackFcn(handles,iFrame-SET.DoWatershed+1, steps, SET,currAni);
                    if ~failed
                        % Next frame
                        iFrame = iFrame+steps;
                        SET.DoWatershed = 0;
                    else
                        SET.DoWatershed = SET.DoWatershed-1;
                    end
                end
            end
            if failed
                beep
                break
            end
        else
            iFrame = iFrame+steps;
        end
        

        % Correct entries
        if iFrame > handles.Video.NrFrames
            iFrame = handles.Video.NrFrames;
        end
        if iFrame > handles.Video.NrFrames
            iFrame = handles.Video.NrFrames;
        end
        if iFrame < 0
            iFrame = 1;
        end
        if iFrame < 0
            iFrame = 1;
        end
        
        
        % Update handles structure
        guidata(hObject, handles);
        
        
    end%iFrame
    
    
else % Wrong entries
    beep
    msgbox({'Start and stop frame must be integer numbers'; 'and the start frame has to be smaller than the stop frame'}, 'Invalid input', 'error');
    set(handles.ed_startTrack, 'String', 'from')
    set(handles.ed_endTrack, 'String', 'to')
end


% Indicate that operations are over
set(hObject, 'BackgroundColor', [0.8 0.93 0.98])
set(handles.ed_startTrack, 'String', num2str(iFrame))
set(handles.ed_endTrack, 'String', 'to')


% Update figure
if updatePlotWhenDone
    handles.CurrFrame = iFrame;
    handles = updateFigure(handles);
end


% Update handles structure
guidata(hObject, handles);

function [handles, failed] = trackFcn(handles,iFrame, steps, SET, currAni)

failed = 0;

% Get the next frame
[nextFrame, nextFrame_original] = prepareFrame(handles, iFrame+steps);

smoothAni = find(~isnan(handles.Tracking.X(iFrame, :)) & ~isnan(handles.Tracking.Y(iFrame, :)));
if ~isempty(smoothAni) && SET.DoWatershed <= 0
    % Get labels and centroids of non-watershed blobs
    original_label = bwlabel(nextFrame_original);
    original_centroid = cell2mat( struct2cell(regionprops(original_label, 'centroid')));
    original_centroid = [original_centroid(1:2:end)', original_centroid(2:2:end)'];
    % Get blob label for each ID
    cnt_label = 1;
    ani_label = nan(length(smoothAni),2);
    for iAni = 1:length(smoothAni)
        ani_label(cnt_label, 2) = original_label(round(handles.Tracking.Y(iFrame, smoothAni(iAni))), round(handles.Tracking.X(iFrame, smoothAni(iAni))));
        ani_label(cnt_label, 1) = smoothAni(iAni);
        cnt_label = cnt_label+1;
    end%iAni    
    for iAni = 1:length(smoothAni)        
        if ~handles.Tracking.Manual(iFrame, smoothAni(iAni)) && sum(ani_label(:,2) == ani_label(iAni, 2))==1 && ani_label(iAni, 2) ~= 0
            handles.Tracking.X(iFrame, iAni) = original_centroid(ani_label(iAni, 2),1);
            handles.Tracking.Y(iFrame, iAni) = original_centroid(ani_label(iAni, 2),2);
        end        
    end%iAni
    clear smoothAni ani_label cnt_label original_label original_centroid
end

% If needed:
% Apply the watershed to the whole frame - more costly but
% easier
if SET.DoWatershed>0 
    set(handles.tx_static_title, 'BackgroundColor', [1 0 0])
    % --- Watershed
    D = nextFrame;
    D = bwdist(~D);
    D = -D;
    L = watershed(D);
    L(~nextFrame) = 0;
    nextFrame = L>0;
    clear D L
    nextFrame = uint8(nextFrame*255);
else
    set(handles.tx_static_title, 'BackgroundColor', [0.15 0.15 0.15])
end

% Get blob labels
nextFrame_Labels = bwlabel(nextFrame);
nextFrame_LabelsProps_area = cell2mat( struct2cell( regionprops(nextFrame_Labels, 'area') ));
% Kick out small blobs that remained from the erosion
Small = find(nextFrame_LabelsProps_area <= 9);
for iSmall = 1:length(Small)
    nextFrame(find(nextFrame_Labels==Small(iSmall))) = 0;
end
nextFrame_Labels = bwlabel(nextFrame);
% Label
nextFrame_LabelsProps = cell2mat( struct2cell( regionprops(nextFrame_Labels, 'centroid') ));
% Get detected blobs
nextFrame_BlobIDs = unique(nextFrame_Labels);
nextFrame_Centroids = [nextFrame_LabelsProps(1:2:end)', nextFrame_LabelsProps(2:2:end)'];


% Check whether the next frame has any centroids. If not, go to
% next frame.
if ~isempty(nextFrame_Centroids)    
    AssignmentOverview = zeros(length(nextFrame_BlobIDs)-1, length(currAni));
    % Iterate over all animals and determine next position
    for iAni = currAni        
        % The the animal's current position
        currPos = ([handles.Tracking.X(iFrame, iAni), handles.Tracking.Y(iFrame, iAni)]);        
        % Calculate the distances to all the centroids
        helper = nextFrame_Centroids-currPos;
        dist = sqrt(sum(helper'.*helper'))';
        dist_norm = dist/norm(dist);        
        % Get animal's walking direction
        try
            % Get the estimated heading direction based on the
            % last 3s
            s3 = iFrame:-sign(steps):iFrame-abs((handles.Video.Obj.FrameRate*sign(steps)*3));
            temp = [handles.Tracking.X(s3,iAni), handles.Tracking.Y(s3,iAni)];
            if sum(sum(~isnan(temp))) > 4
                temp(~any(~isnan(temp), 2),:)=[];
                currDir = nanmean(diff(temp));
                % Calculate the angles to all centroids
                allDir_diff = ones(size(helper,1),1);
                for iCentroid = 1:size(helper,1)
                    allDir_diff(iCentroid,1) = 1+acosd(dot(currDir / (1+norm(currDir)), helper(iCentroid,:) / (1+norm(helper(iCentroid,:)))))/180;
                end%iCentroid
            else
                allDir_diff = ones(size(helper,1),1);
                currDir = [0 0];
            end
        catch
            allDir_diff = ones(size(helper,1),1);
            currDir = [0 0];
        end        
        % Get the closest centroid, scaled by direction
        [~, idx] = min(dist_norm + dist_norm./allDir_diff + (dist>norm(currDir)*5));        
        % Use this centroid as new location, if the next frame is
        % not tracked
        if isnan(handles.Tracking.X(iFrame+steps, iAni)) || isnan(handles.Tracking.Y(iFrame+steps, iAni))
            handles.Tracking.X(iFrame+steps, iAni) = (nextFrame_Centroids(idx, 1));
            handles.Tracking.Y(iFrame+steps, iAni) = (nextFrame_Centroids(idx, 2));
        end        
        % Keep track which ID belongs to which blob to determine
        % crossings
        AssignmentOverview(idx, iAni) = 1;        
        clear dist allDir_diff idx helper currDir temp s3
    end%iAni
    
    % Detect crossing
    if ~isempty(find(sum(AssignmentOverview,2)==2))        
        % Identify which IDs are crossing
        Crossing = find(sum(AssignmentOverview,2)>=2);
        CrossingIDs = [];
        for iCross = 1:length(Crossing)
            CrossingIDs = [CrossingIDs,...
                find(AssignmentOverview(Crossing(iCross),:))];
        end%iCross        
        % Reset tracking
        handles.Tracking.X(iFrame+steps, CrossingIDs) = NaN;
        handles.Tracking.Y(iFrame+steps, CrossingIDs) = NaN;        
        % Indicate things have failed
        failed = 1;        
    end%if crossing
else
    for iAni = 1:length(currAni)
        handles.Tracking.X(iFrame+steps, currAni) = handles.Tracking.X(iFrame, currAni);
        handles.Tracking.Y(iFrame+steps, currAni) = handles.Tracking.Y(iFrame, currAni);
    end
end% if has centroids

% Style: POPUPMENU --------------------------------------------------------
function pop_aniList_Callback(hObject, eventdata, handles)

% Update handles structure
guidata(hObject, handles);

function pop_cautious_Callback(hObject, eventdata, handles)

% Update handles structure
guidata(hObject, handles);

function pop_cm_Callback(hObject, eventdata, handles)

% Update colormap
cm_pos = get(hObject, 'Value');
cm_string = get(hObject, 'String');
handles.Tracking.Color = eval([cm_string{cm_pos},'(handles.Tracking.nAnimals)']);

% Update figure
handles = updateFigure(handles);

% Update handles structure
guidata(hObject, handles);


function pop_fillMissingMethod_Callback(hObject, eventdata, handles)

% Update handles structure
guidata(hObject, handles);


% Style: SLIDER -----------------------------------------------------------
function sl_main_Callback(hObject, eventdata, handles)

% Update figure
handles.CurrFrame = round(get(hObject, 'Value'), 0);
handles = updateFigure(handles);

% Update handles structure
guidata(hObject, handles);


% Style: TOGGLEBUTTON -----------------------------------------------------
function tg_indicateBlobs_Callback(hObject, eventdata, handles)

if get(hObject, 'Value') == 1
    % Indicate that the function is active
    set(hObject, 'BackgroundColor', [1 0.65 0.4])
else
    % Indicate that operations are over
    set(hObject, 'BackgroundColor', [0.8 0.93 0.98])
end

handles = updateFigure(handles);

% Update handles structure
guidata(hObject, handles);

function tg_invertIMG_Callback(hObject, eventdata, handles)
if get(hObject, 'Value') == 1
    % Indicate that the function is active
    set(hObject, 'BackgroundColor', [1 0.65 0.4])
    % Enable options
else
    % Indicate that operations are over
    set(hObject, 'BackgroundColor', [0.8 0.93 0.98])
    % Enable options
end

handles = updateFigure(handles);

% Update handles structure
guidata(hObject, handles);

function tg_simple_threshold_Callback(hObject, eventdata, handles)
if get(hObject, 'Value') == 1
    % Indicate that the function is active
    set(hObject, 'BackgroundColor', [1 0.65 0.4])
    set(hObject, 'Enable', 'off')
    set(handles.tg_watershed, 'Value', 0)
    set(handles.tg_watershed, 'BackgroundColor', [0.8 0.93 0.98])
    set(handles.tg_watershed, 'Enable', 'on')
else
    % Indicate that operations are over
    set(hObject, 'BackgroundColor', [0.8 0.93 0.98])
end

handles = updateFigure(handles);

% Update handles structure
guidata(hObject, handles);

function tg_subtractBG_Callback(hObject, eventdata, handles)

if get(hObject, 'Value') == 1
    % Indicate that the function is active
    set(hObject, 'BackgroundColor', [1 0.65 0.4])
    % Enable options
    handles = UnlockOptions(handles, 'BackgroundSubtracted');
else
    % Indicate that operations are over
    set(hObject, 'BackgroundColor', [0.8 0.93 0.98])
    % Enable options
    handles = UnlockOptions(handles, 'BackgroundNotSubtracted');
end

handles = updateFigure(handles);

% Update handles structure
guidata(hObject, handles);

function tg_watershed_Callback(hObject, eventdata, handles)
if get(hObject, 'Value') == 1
    % Indicate that the function is active
    set(hObject, 'BackgroundColor', [1 0.65 0.4])
    set(hObject, 'Enable', 'off')
    set(handles.tg_simple_threshold, 'Value', 0)
    set(handles.tg_simple_threshold, 'BackgroundColor', [0.8 0.93 0.98])
    set(handles.tg_simple_threshold, 'Enable', 'on')
else
    % Indicate that operations are over
    set(hObject, 'BackgroundColor', [0.8 0.93 0.98])
end

handles = updateFigure(handles);

% Update handles structure
guidata(hObject, handles);









%--------------------------------------------------------------------------
%                             Other functions
%--------------------------------------------------------------------------

function Par = CircleFit(XY)
% Written by:
% Nikolai Chernov (2020). Circle Fit (Pratt method)
% https://www.mathworks.com/matlabcentral/fileexchange/22643-circle-fit-pratt-method
% MATLAB Central File Exchange. Retrieved March 30, 2020.

% Input:
%   XY(n,2) is the array of coordinates of n points x(i)=XY(i,1), y(i)=XY(i,2)
%
% Output
%   Par = [a b R] = center (a,b) and radius R

n = size(XY,1);      % number of data points
centroid = mean(XY);   % the centroid of the data set
%     computing moments (note: all moments will be normed, i.e. divided by n)
Mxx=0; Myy=0; Mxy=0; Mxz=0; Myz=0; Mzz=0;
for i=1:n
    Xi = XY(i,1) - centroid(1);  %  centering data
    Yi = XY(i,2) - centroid(2);  %  centering data
    Zi = Xi*Xi + Yi*Yi;
    Mxy = Mxy + Xi*Yi;
    Mxx = Mxx + Xi*Xi;
    Myy = Myy + Yi*Yi;
    Mxz = Mxz + Xi*Zi;
    Myz = Myz + Yi*Zi;
    Mzz = Mzz + Zi*Zi;
end

Mxx = Mxx/n;
Myy = Myy/n;
Mxy = Mxy/n;
Mxz = Mxz/n;
Myz = Myz/n;
Mzz = Mzz/n;
%    computing the coefficients of the characteristic polynomial
Mz = Mxx + Myy;
Cov_xy = Mxx*Myy - Mxy*Mxy;
Mxz2 = Mxz*Mxz;
Myz2 = Myz*Myz;
A2 = 4*Cov_xy - 3*Mz*Mz - Mzz;
A1 = Mzz*Mz + 4*Cov_xy*Mz - Mxz2 - Myz2 - Mz*Mz*Mz;
A0 = Mxz2*Myy + Myz2*Mxx - Mzz*Cov_xy - 2*Mxz*Myz*Mxy + Mz*Mz*Cov_xy;
A22 = A2 + A2;
epsilon=1e-12;
ynew=1e+20;
IterMax=20;
xnew = 0;
%    Newton's method starting at x=0
for iter=1:IterMax
    yold = ynew;
    ynew = A0 + xnew*(A1 + xnew*(A2 + 4.*xnew*xnew));
    if (abs(ynew)>abs(yold))
        disp('Newton-Pratt goes wrong direction: |ynew| > |yold|');
        xnew = 0;
        break;
    end
    Dy = A1 + xnew*(A22 + 16*xnew*xnew);
    xold = xnew;
    xnew = xold - ynew/Dy;
    if (abs((xnew-xold)/xnew) < epsilon), break, end
    if (iter >= IterMax)
        disp('Newton-Pratt will not converge');
        xnew = 0;
    end
    if (xnew<0.)
        fprintf(1,'Newton-Pratt negative root:  x=%f\n',xnew);
        xnew = 0;
    end
end
%    computing the circle parameters
DET = xnew*xnew - xnew*Mz + Cov_xy;
Center = [Mxz*(Myy-xnew)-Myz*Mxy , Myz*(Mxx-xnew)-Mxz*Mxy]/DET/2;
Par = [Center+centroid , sqrt(Center*Center'+Mz+2*xnew)];



function handles = CircularMasks(handles, N)
% Display BG
axes(handles.ax_main)
imshow(uint8(handles.medianBG))
for iMask = 1:N
    % Get indices of pixels
    [idx(:,1), idx(:,2)] = find(~isnan(handles.medianBG));
    % Give instructions
    set(handles.tx_static_title, 'String', ['Click on 4 points of a cirlce for mask number ', num2str(iMask)])
    % Get circle
    Par = CircleFit(fliplr(ginputBM(4, [0.25 0.25 0.25])));
    
    % Get inlying pixels
    helper = idx-[Par(1), Par(2)];
    dist = sqrt(sum(helper'.*helper'))';
    idx_dist = find(dist<Par(3));
    % Set all outlying pixels to zero
    handles.medianBG(idx_dist) = zeros(1,length(idx_dist));
    % Show new BG
    imshow(uint8(handles.medianBG))
    
    % Save mask parameters
    if ~isfield(handles, 'Annotation')
        handles.Annotation.Masks.Circular = [];
    elseif ~isfield(handles.Annotation, 'Masks')
        handles.Annotation.Masks.Circular = [];
    elseif ~isfield(handles.Annotation.Masks, 'Circular')
        handles.Annotation.Masks.Circular = [];
    end
    handles.Annotation.Masks.Circular = [handles.Annotation.Masks.Circular; [Par(2),Par(1),Par(3)]];
    
    clear idx* Par
end

% Get old title back
set(handles.tx_static_title, 'String', handles.CurrTrial)


function handles = RectangularMasks(handles, N)
% Display BG
axes(handles.ax_main)
imshow(uint8(handles.medianBG))
for iMask = 1:N
    % Get indices of pixels
    [idx(:,1), idx(:,2)] = find(~isnan(handles.medianBG));
    % Give instructions
    set(handles.tx_static_title, 'String', ['Click on the 2 diag. points of rectangle number ', num2str(iMask)])
    % Get points
    XY = ginputBM(2, [0.25 0.25 0.25]);
    % Get outlying pixels
    min_x = min(XY(:,2));
    max_x = max(XY(:,2));
    min_y = min(XY(:,1));
    max_y = max(XY(:,1));
    idx_dist = intersect(find((idx(:,1) > min_x) & (idx(:,1) < max_x)), find((idx(:,2) > min_y) & (idx(:,2) < max_y)));
    % Set all outlying pixels to zero
    handles.medianBG(idx_dist) = zeros(1,length(idx_dist));
    % Show new BG
    imshow(uint8(handles.medianBG))
    
    % Save mask parameters
    if ~isfield(handles, 'Annotation')
        handles.Annotation.Masks.Rectangular = [];
    elseif ~isfield(handles.Annotation, 'Masks')
        handles.Annotation.Masks.Rectangular = [];
    elseif ~isfield(handles.Annotation.Masks, 'Rectangular')
        handles.Annotation.Masks.Rectangular = [];
    end
    handles.Annotation.Masks.Rectangular = [handles.Annotation.Masks.Rectangular; min_x, min_y, max_x-min_x, max_y-min_y];
    
    clear idx* min*
end

% Get old title back
set(handles.tx_static_title, 'String', handles.CurrTrial)



function [frame, originalFrame] = prepareFrame(handles, CurrFrame)


if handles.Tracking.PrecompBlobs.Logical && get(handles.cb_use_gen_blobs, 'Value')
    

    try        
        fseek(handles.fid, handles.Tracking.PrecompBlobs.Lines(CurrFrame), 'bof');
        C = fgetl(handles.fid);
        C = eval(['[',C,']']);
        frame = zeros(handles.Video.Obj.Height, handles.Video.Obj.Width);
        frame(C) = 255;
        fail=0;
        %         fclose(fid);
        
        % Enable watershed   
        originalFrame = frame;
        if get(handles.tg_watershed, 'Value')
            D = frame;
            D = bwdist(~D);
            D = -D;
            L = watershed(D);
            L(~frame) = 0;
            frame = L>0;
            clear D L
        end
        
        return
    catch
        fail=1;
    end
    
end

if ~get(handles.cb_use_gen_blobs, 'Value') || (~handles.Tracking.PrecompBlobs.Logical || fail)
    % Load frame
    frame = uint8(rgb2gray(undistortImage(read(handles.Video.Obj, CurrFrame), handles.cameraParams)));
    originalFrame = frame;
end

% Get settings set by user (e.g. invert image, subtract background, etc)
SET.FlatField = get(handles.cb_flatfield, 'Value');
SET.Haze = get(handles.cb_reduce_haze, 'Value');
SET.Contrast = get(handles.cb_adjust_contrast, 'Value');
SET.Sharpen = get(handles.cb_sharpen, 'Value');
SET.InvertIMG = get(handles.tg_invertIMG, 'Value');
SET.SubtractBG = get(handles.tg_subtractBG, 'Value');
SET.Threshold = str2double(get(handles.ed_threshold, 'String'));
SET.IndicateBlobs = get(handles.tg_indicateBlobs, 'Value');
% Get sigma for flat-field correction
SET.FlatField_sigma = str2double(get(handles.ed_flatfield_sigma, 'String'));
if SET.FlatField_sigma<0
    % Indicate that something went wrong
    beep
    set(handles.ed_flatfield_sigma, 'String', '0');
    SET.FlatField_sigma = 0;
end

% Get BG (either dummy variable or calculated) ... if needed
if SET.SubtractBG
    % Get either dummy variable or calculated
    BG = handles.medianBG;
end% If BG is needed


% Get Parameters for erosion and dilation
try
    par = eval(get(handles.ed_ErodeDilateErode, 'String'));
catch
    % Indicate that something went wrong
    beep
    set(handles.ed_ErodeDilateErode, 'String', '[0, 0, 0]');
    par = [0 0 0];
end
if length(par) == 3 && sum(isnan(par)) == 0
    % Create a strel objects that represent flat morphological
    % structuring elements, which are essential parts of morphological
    % dilation and erosion operations.
    SET.Erode1 = strel('disk', par(1));
    SET.Erode2 = strel('disk', par(3));
    SET.Dilate = strel('disk', par(2));
else
    % Indicate that something went wrong
    beep
    set(handles.ed_ErodeDilateErode, 'String', '[0, 0, 0]');
    par = [0 0 0];
    % Create a strel objects that represent flat morphological
    % structuring elements, which are essential parts of morphological
    % dilation and erosion operations.
    SET.Erode1 = strel('disk', par(1));
    SET.Erode2 = strel('disk', par(3));
    SET.Dilate = strel('disk', par(2));
end
clear par


% Apply image processing
if SET.FlatField
    frame = imflatfield(frame,SET.FlatField_sigma);
end
if SET.Haze
    frame = imreducehaze(frame);
end
if SET.Contrast
    frame = imcomplement(imreducehaze(imcomplement(frame)));
    frame = imadjust(frame);
end
if SET.Sharpen
    frame = imsharpen(frame);
end

if SET.InvertIMG
    % Invert frame
    frame = uint8(abs(double(frame)-255));
end

if SET.SubtractBG
    
    % Invert BG
    if SET.InvertIMG
        BG = uint8(abs(double(BG)-255));
    end
    
    % Subtract BG from frame
    frame = double(frame)-double(BG);
    % Check whether to apply a threshold
    if ~isnan(SET.Threshold) && SET.Threshold > 0
        
        frame = frame > (SET.Threshold*255);
        
        frame = imfill(frame,'holes');
        
        % Applay erosion and dilation
        frame = imerode(frame, SET.Erode1);
        frame = imdilate(frame, SET.Dilate);
        frame = imerode(frame, SET.Erode2);
        
        if get(handles.tg_watershed, 'Value')
            D = frame;
            D = bwdist(~D);
            D = -D;
            L = watershed(D);
            L(~frame) = 0;
            frame = L>0;
            clear D L
        end
        
        frame = frame*255;
    end%if threshold
    frame = uint8(frame);
    
    if ~get(handles.tg_watershed, 'Value')
        originalFrame = frame;
    end
end



function handles = UnlockOptions(handles, Commmad)
% Enables and disables options/buttons/etc of the gui depending on the
% current state.
% Different inputs for 'Command':
%   > 'Init'
%   > 'VideoLoaded'
%   > 'NumOfAniSet'
%   > 'BackgroundLoaded'
%   > 'BackgroundSubtracted'
%   > 'BackgroundNotSubtracted'

switch Commmad
    case 'Init'
        % --- ON
        % /
        % --- OFF
        set(handles.cb_deleteAll,           'Enable', 'off')
        set(handles.cb_interpolateAll,      'Enable', 'off')
        set(handles.tg_invertIMG,           'Enable', 'off')
        set(handles.cb_nextFrame,           'Enable', 'off')
        set(handles.cb_trackAll,            'Enable', 'off')
        set(handles.ed_addID,               'Enable', 'off')
        set(handles.ed_currentFrame,        'Enable', 'off')
        set(handles.ed_ErodeDilateErode,    'Enable', 'off')
        set(handles.ed_nAnimals,            'Enable', 'off')
        set(handles.ed_playSteps,           'Enable', 'off')
        set(handles.ed_startDel,            'Enable', 'off')
        set(handles.ed_startFillMissing,    'Enable', 'off')
        set(handles.ed_startTrack,          'Enable', 'off')
        set(handles.ed_track_steps,         'Enable', 'off')
        set(handles.ed_stopDel,             'Enable', 'off')
        set(handles.ed_stopFillMissing,     'Enable', 'off')
        set(handles.ed_endTrack,            'Enable', 'off')
        set(handles.ed_threshold,           'Enable', 'off')
        set(handles.mn_openTracks,          'Enable', 'off')
        set(handles.mn_masks_main,          'Enable', 'off')
        set(handles.mn_masks_circles,       'Enable', 'off')
        set(handles.mn_masks_rectangles,    'Enable', 'off')
        set(handles.mn_save,                'Enable', 'off')
        set(handles.pb_assignID,            'Enable', 'off')
        set(handles.pb_CalcBG,              'Enable', 'off')
        set(handles.pb_delAssignment,       'Enable', 'off')
        set(handles.pb_fillMissing,         'Enable', 'off')
        set(handles.pb_play,                'Enable', 'off')
        set(handles.pb_stop,                'Enable', 'off')
        set(handles.pb_track,               'Enable', 'off')
        set(handles.pop_fillMissingMethod,  'Enable', 'off')
        set(handles.sl_main,                'Enable', 'off')
        set(handles.tg_indicateBlobs,       'Enable', 'off')
        set(handles.tg_subtractBG,          'Enable', 'off')
        set(handles.cb_flatfield,           'Enable', 'off')
        set(handles.ed_flatfield_sigma,     'Enable', 'off')
        set(handles.cb_reduce_haze,         'Enable', 'off')
        set(handles.cb_adjust_contrast,     'Enable', 'off')
        set(handles.cb_sharpen,             'Enable', 'off')
        set(handles.ed_fraction_for_BG,     'Enable', 'off')
        set(handles.tg_watershed,           'Enable', 'off')
        set(handles.pb_generate_blobs,      'Enable', 'off')
        set(handles.pb_auto_assign,         'Enable', 'off')
        set(handles.pop_aniList,            'Enable', 'off')
        set(handles.pb_delete_ID,           'Enable', 'off')
        
    case 'VideoLoaded'
        % --- ONpb_
        set(handles.tg_invertIMG,           'Enable', 'on')
        set(handles.ed_addID,               'Enable', 'on')
        set(handles.ed_currentFrame,        'Enable', 'on')
        set(handles.ed_nAnimals,            'Enable', 'on')
        set(handles.ed_playSteps,           'Enable', 'on')
        set(handles.mn_openTracks,          'Enable', 'on')
        set(handles.pb_CalcBG,              'Enable', 'on')
        set(handles.pb_play,                'Enable', 'on')
        set(handles.pb_stop,                'Enable', 'on')
        set(handles.sl_main,                'Enable', 'on')
        set(handles.cb_flatfield,           'Enable', 'on')
        set(handles.ed_flatfield_sigma,     'Enable', 'on')
        set(handles.cb_reduce_haze,         'Enable', 'on')
        set(handles.cb_adjust_contrast,     'Enable', 'on')
        set(handles.cb_sharpen,             'Enable', 'on')
        set(handles.ed_fraction_for_BG,     'Enable', 'on')
        set(handles.pop_aniList,            'Enable', 'on')
        set(handles.pb_delete_ID,           'Enable', 'on')
        % --- OFF
        set(handles.cb_deleteAll,           'Enable', 'off')
        set(handles.cb_interpolateAll,      'Enable', 'off')
        set(handles.cb_nextFrame,           'Enable', 'off')
        set(handles.cb_trackAll,            'Enable', 'off')
        set(handles.ed_ErodeDilateErode,    'Enable', 'off')
        set(handles.ed_startDel,            'Enable', 'off')
        set(handles.ed_startFillMissing,    'Enable', 'off')
        set(handles.ed_startTrack,          'Enable', 'off')
        set(handles.ed_track_steps,         'Enable', 'off')
        set(handles.ed_stopDel,             'Enable', 'off')
        set(handles.ed_stopFillMissing,     'Enable', 'off')
        set(handles.ed_endTrack,            'Enable', 'off')
        set(handles.ed_threshold,           'Enable', 'off')
        set(handles.mn_save,                'Enable', 'off')
        set(handles.mn_masks_main,          'Enable', 'off')
        set(handles.mn_masks_circles,       'Enable', 'off')
        set(handles.mn_masks_rectangles,    'Enable', 'off')
        set(handles.pb_assignID,            'Enable', 'off')
        set(handles.pb_delAssignment,       'Enable', 'off')
        set(handles.pb_fillMissing,         'Enable', 'off')
        set(handles.pb_track,               'Enable', 'off')
        set(handles.pop_fillMissingMethod,  'Enable', 'off')
        set(handles.tg_indicateBlobs,       'Enable', 'off')
        set(handles.tg_subtractBG,          'Enable', 'off')
        set(handles.tg_watershed,           'Enable', 'off')
        set(handles.pb_generate_blobs,      'Enable', 'off')
        set(handles.pb_auto_assign,         'Enable', 'off')
        
    case 'NumOfAniSet'
        set(handles.cb_deleteAll,           'Enable', 'on')
        set(handles.cb_interpolateAll,      'Enable', 'on')
        set(handles.tg_invertIMG,           'Enable', 'on')
        set(handles.cb_nextFrame,           'Enable', 'on')
        set(handles.ed_addID,               'Enable', 'on')
        set(handles.ed_currentFrame,        'Enable', 'on')
        set(handles.ed_nAnimals,            'Enable', 'on')
        set(handles.ed_playSteps,           'Enable', 'on')
        set(handles.ed_startDel,            'Enable', 'on')
        set(handles.ed_startFillMissing,    'Enable', 'on')
        set(handles.ed_stopDel,             'Enable', 'on')
        set(handles.ed_stopFillMissing,     'Enable', 'on')
        set(handles.mn_openTracks,          'Enable', 'on')
        set(handles.mn_save,                'Enable', 'on')
        set(handles.pb_assignID,            'Enable', 'on')
        set(handles.pb_CalcBG,              'Enable', 'on')
        set(handles.pb_delAssignment,       'Enable', 'on')
        set(handles.pb_fillMissing,         'Enable', 'on')
        set(handles.pb_play,                'Enable', 'on')
        set(handles.pb_stop,                'Enable', 'on')
        set(handles.pop_fillMissingMethod,  'Enable', 'on')
        set(handles.sl_main,                'Enable', 'on')
        set(handles.tg_indicateBlobs,       'Enable', 'on')
        set(handles.cb_flatfield,           'Enable', 'on')
        set(handles.ed_flatfield_sigma,     'Enable', 'on')
        set(handles.cb_reduce_haze,         'Enable', 'on')
        set(handles.cb_adjust_contrast,     'Enable', 'on')
        set(handles.cb_sharpen,             'Enable', 'on')
        set(handles.ed_fraction_for_BG,     'Enable', 'on')
        set(handles.pop_aniList,            'Enable', 'on')
        set(handles.pb_delete_ID,            'Enable', 'on')
        % --- OFF
        set(handles.cb_trackAll,            'Enable', 'off')
        set(handles.ed_ErodeDilateErode,    'Enable', 'off')
        set(handles.ed_nAnimals,            'Enable', 'off')
        set(handles.ed_startTrack,          'Enable', 'off')
        set(handles.ed_track_steps,         'Enable', 'off')
        set(handles.ed_endTrack,            'Enable', 'off')
        set(handles.ed_threshold,           'Enable', 'off')
        set(handles.pb_track,               'Enable', 'off')
        set(handles.tg_subtractBG,          'Enable', 'off')
        set(handles.tg_watershed,           'Enable', 'off')
        set(handles.pb_generate_blobs,      'Enable', 'off')
        set(handles.pb_auto_assign,         'Enable', 'off')
        
    case 'BackgroundLoaded'
        % --- ON
        set(handles.cb_deleteAll,           'Enable', 'on')
        set(handles.cb_interpolateAll,      'Enable', 'on')
        set(handles.tg_invertIMG,           'Enable', 'on')
        set(handles.cb_nextFrame,           'Enable', 'on')
        set(handles.ed_addID,               'Enable', 'on')
        set(handles.ed_currentFrame,        'Enable', 'on')
        set(handles.ed_nAnimals,            'Enable', 'on')
        set(handles.ed_playSteps,           'Enable', 'on')
        set(handles.ed_startDel,            'Enable', 'on')
        set(handles.ed_startFillMissing,    'Enable', 'on')
        set(handles.ed_stopDel,             'Enable', 'on')
        set(handles.ed_stopFillMissing,     'Enable', 'on')
        set(handles.mn_openTracks,          'Enable', 'on')
        set(handles.mn_save,                'Enable', 'on')
        set(handles.mn_masks_main,          'Enable', 'on')
        set(handles.mn_masks_circles,       'Enable', 'on')
        set(handles.mn_masks_rectangles,    'Enable', 'on')
        set(handles.pb_assignID,            'Enable', 'on')
        set(handles.pb_CalcBG,              'Enable', 'on')
        set(handles.pb_delAssignment,       'Enable', 'on')
        set(handles.pb_fillMissing,         'Enable', 'on')
        set(handles.pb_play,                'Enable', 'on')
        set(handles.pb_stop,                'Enable', 'on')
        set(handles.pop_fillMissingMethod,  'Enable', 'on')
        set(handles.sl_main,                'Enable', 'on')
        set(handles.tg_indicateBlobs,       'Enable', 'on')
        set(handles.tg_subtractBG,          'Enable', 'on')
        set(handles.cb_flatfield,           'Enable', 'on')
        set(handles.ed_flatfield_sigma,     'Enable', 'on')
        set(handles.cb_reduce_haze,         'Enable', 'on')
        set(handles.cb_adjust_contrast,     'Enable', 'on')
        set(handles.cb_sharpen,             'Enable', 'on')
        set(handles.ed_fraction_for_BG,     'Enable', 'on')
        set(handles.tg_watershed,           'Enable', 'on')
        set(handles.pb_generate_blobs,      'Enable', 'on')
        set(handles.pop_aniList,            'Enable', 'on')
        set(handles.pb_delete_ID,            'Enable', 'on')
        % --- OFF
        set(handles.cb_trackAll,            'Enable', 'off')
        set(handles.ed_ErodeDilateErode,    'Enable', 'off')
        set(handles.ed_startTrack,          'Enable', 'off')
        set(handles.ed_track_steps,         'Enable', 'off')
        set(handles.ed_endTrack,            'Enable', 'off')
        set(handles.ed_threshold,           'Enable', 'off')
        set(handles.pb_track,               'Enable', 'off')
        set(handles.pb_auto_assign,         'Enable', 'off')
        
    case 'BackgroundSubtracted'
        % --- ON
        set(handles.cb_deleteAll,           'Enable', 'on')
        set(handles.cb_interpolateAll,      'Enable', 'on')
        set(handles.tg_invertIMG,           'Enable', 'on')
        set(handles.cb_nextFrame,           'Enable', 'on')
        set(handles.cb_trackAll,            'Enable', 'on')
        set(handles.ed_addID,               'Enable', 'on')
        set(handles.ed_currentFrame,        'Enable', 'on')
        set(handles.ed_ErodeDilateErode,    'Enable', 'on')
        set(handles.ed_nAnimals,            'Enable', 'on')
        set(handles.ed_playSteps,           'Enable', 'on')
        set(handles.ed_startDel,            'Enable', 'on')
        set(handles.ed_startFillMissing,    'Enable', 'on')
        set(handles.ed_startTrack,          'Enable', 'on')
        set(handles.ed_track_steps,         'Enable', 'on')
        set(handles.ed_stopDel,             'Enable', 'on')
        set(handles.ed_stopFillMissing,     'Enable', 'on')
        set(handles.ed_endTrack,            'Enable', 'on')
        set(handles.ed_threshold,           'Enable', 'on')
        set(handles.mn_openTracks,          'Enable', 'on')
        set(handles.mn_save,                'Enable', 'on')
        set(handles.mn_masks_main,          'Enable', 'on')
        set(handles.mn_masks_circles,       'Enable', 'on')
        set(handles.mn_masks_rectangles,    'Enable', 'on')
        set(handles.pb_assignID,            'Enable', 'on')
        set(handles.pb_CalcBG,              'Enable', 'on')
        set(handles.pb_delAssignment,       'Enable', 'on')
        set(handles.pb_fillMissing,         'Enable', 'on')
        set(handles.pb_play,                'Enable', 'on')
        set(handles.pb_stop,                'Enable', 'on')
        set(handles.pb_track,               'Enable', 'on')
        set(handles.pop_fillMissingMethod,  'Enable', 'on')
        set(handles.sl_main,                'Enable', 'on')
        set(handles.tg_indicateBlobs,       'Enable', 'on')
        set(handles.tg_subtractBG,          'Enable', 'on')
        set(handles.cb_flatfield,           'Enable', 'on')
        set(handles.ed_flatfield_sigma,     'Enable', 'on')
        set(handles.cb_reduce_haze,         'Enable', 'on')
        set(handles.cb_adjust_contrast,     'Enable', 'on')
        set(handles.cb_sharpen,             'Enable', 'on')
        set(handles.ed_fraction_for_BG,     'Enable', 'on')
        set(handles.tg_watershed,           'Enable', 'on')
        set(handles.pb_generate_blobs,      'Enable', 'on')
        set(handles.pb_auto_assign,         'Enable', 'on')
        set(handles.pop_aniList,            'Enable', 'on')
        set(handles.pb_delete_ID,           'Enable', 'on')
        % --- OFF
        % /
        
    case 'BackgroundNotSubtracted'
        % --- ON
        set(handles.cb_deleteAll,           'Enable', 'on')
        set(handles.cb_interpolateAll,      'Enable', 'on')
        set(handles.tg_invertIMG,           'Enable', 'on')
        set(handles.cb_nextFrame,           'Enable', 'on')
        set(handles.ed_addID,               'Enable', 'on')
        set(handles.ed_currentFrame,        'Enable', 'on')
        set(handles.ed_nAnimals,            'Enable', 'on')
        set(handles.ed_playSteps,           'Enable', 'on')
        set(handles.ed_startDel,            'Enable', 'on')
        set(handles.ed_startFillMissing,    'Enable', 'on')
        set(handles.ed_stopDel,             'Enable', 'on')
        set(handles.ed_stopFillMissing,     'Enable', 'on')
        set(handles.mn_openTracks,          'Enable', 'on')
        set(handles.mn_save,                'Enable', 'on')
        set(handles.mn_masks_main,          'Enable', 'on')
        set(handles.mn_masks_circles,       'Enable', 'on')
        set(handles.mn_masks_rectangles,    'Enable', 'on')
        set(handles.pb_assignID,            'Enable', 'on')
        set(handles.pb_CalcBG,              'Enable', 'on')
        set(handles.pb_delAssignment,       'Enable', 'on')
        set(handles.pb_fillMissing,         'Enable', 'on')
        set(handles.pb_play,                'Enable', 'on')
        set(handles.pb_stop,                'Enable', 'on')
        set(handles.pop_fillMissingMethod,  'Enable', 'on')
        set(handles.sl_main,                'Enable', 'on')
        set(handles.tg_indicateBlobs,       'Enable', 'on')
        set(handles.tg_subtractBG,          'Enable', 'on')
        set(handles.cb_flatfield,           'Enable', 'on')
        set(handles.ed_flatfield_sigma,     'Enable', 'on')
        set(handles.cb_reduce_haze,         'Enable', 'on')
        set(handles.cb_adjust_contrast,     'Enable', 'on')
        set(handles.cb_sharpen,             'Enable', 'on')
        set(handles.ed_fraction_for_BG,     'Enable', 'on')
        set(handles.tg_watershed,           'Enable', 'on')
        set(handles.pb_generate_blobs,      'Enable', 'on')
        set(handles.pop_aniList,            'Enable', 'on')
        set(handles.pb_delete_ID,            'Enable', 'on')
        % --- OFF
        set(handles.cb_trackAll,            'Enable', 'off')
        set(handles.ed_ErodeDilateErode,    'Enable', 'off')
        set(handles.ed_startTrack,          'Enable', 'off')
        set(handles.ed_track_steps,         'Enable', 'off')
        set(handles.ed_endTrack,            'Enable', 'off')
        set(handles.ed_threshold,           'Enable', 'off')
        set(handles.pb_track,               'Enable', 'off')
        set(handles.pb_auto_assign,         'Enable', 'off')
        
end

function Centroids = GetCentroids(frame)
% Get blob images
Labels = bwlabel(frame);
% Get detected blobs
BlobIDs = unique(Labels);
% Preallocation
Centroids = (nan(length(BlobIDs)-1,2));
% Iterate over all true blobs
for iBlob = 2:length(BlobIDs) % Note that the BG has the unique ID of zero (first entry). Therefore, start at 2
    % Get pixels corresponding to current blob
    [rows, cols] = find(Labels == BlobIDs(iBlob));
    % Get the centroid
    Centroids(iBlob-1, :) = [mean(cols), mean(rows)];
end%iBlob
Centroids = reshape(Centroids, [1, numel(Centroids)]);
