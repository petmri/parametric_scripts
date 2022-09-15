function varargout = fitting_gui(varargin)
% FITTING_GUI MATLAB code for fitting_gui.fig
%      FITTING_GUI, by itself, creates a new FITTING_GUI or raises the existing
%      singleton*.
%
%      H = FITTING_GUI returns the handle to a new FITTING_GUI or the handle to
%      the existing singleton*.
%
%      FITTING_GUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in FITTING_GUI.M with the given input arguments.
%
%      FITTING_GUI('Property','Value',...) creates a new FITTING_GUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before fitting_gui_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to fitting_gui_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help fitting_gui

% Last Modified by GUIDE v2.5 13-Oct-2015 14:49:58

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
    'gui_Singleton',  gui_Singleton, ...
    'gui_OpeningFcn', @fitting_gui_OpeningFcn, ...
    'gui_OutputFcn',  @fitting_gui_OutputFcn, ...
    'gui_LayoutFcn',  [] , ...
    'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    warning off
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before fitting_gui is made visible.
function fitting_gui_OpeningFcn(hObject, eventdata, handles, varargin)

% Choose default command line output for fitting_gui
handles.output = hObject;

% Create structure to hold file list
handles.batch_data = {};
% Create counter for number of datasets to make
handles.datasets = 0;

% initialize r2 graph
axes(handles.r2graph)
%imagesc(zeros(100,100))
imshow('REJ.jpg');
set(handles.r2graph, 'XTick', []);
set(handles.r2graph, 'YTick', []);

set(handles.current_dir, 'String', pwd);

% initialize file_list
handles.batch_data(1).file_list = {};
handles.batch_data(1).roi_list = {'No Files'};

% Create structure to hold files and roi lists
handles.roi_list = {};
% handles.file_list = {};

% initialize masterlog name
master_name = strrep(['ROCKETSHIP_MAPPING_' strrep(datestr(now), ' ', '_') '.log'], ':', '-');
set(handles.log_name, 'String', master_name);

% Create parallel processing pool during gui

% Find the maximum cluster
myCluster = parcluster('local');
set(handles.number_cpus, 'String', num2str(myCluster.NumWorkers));

% if exist('matlabpool')
%     s = matlabpool('size');
%     if s
%         matlabpool close
%     end
%     matlabpool('local', str2num(get(handles.number_cpus, 'String')));
% end

% Generate empty dataset
handles = makeNewbatch(handles);

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes fitting_gui wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = fitting_gui_OutputFcn(hObject, eventdata, handles)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on button press in add_files.
function add_files_Callback(hObject, eventdata, handles)

guidata(hObject, handles);

% Check if there is a dataset already. If not, add one.
list = get(handles.batch_set,'String');
% Add selected files to batchbox
if strcmp(list,'No Datasets')
    handles = makeNewbatch(handles);
    guidata(hObject, handles);
end

[filename, pathname, filterindex] = uigetfile( ...
    { '*.nii','Nifti Files (*.nii)'; ...
    '*2dseq','Bruker Files (2dseq)'; ...
    '*.hdr;*.img','Analyze Files (*.hdr, *.img)';...
    '*.*',  'All Files (*.*)'}, ...
    'Pick a file', ...
    'MultiSelect', 'on');
%'*.dcm', '3D Dicom Files (*.dcm)'; 
if isequal(filename,0)
    %disp('User selected Cancel')
    return;
end

%disp(['User selected ', fullfile(pathname, filename)])
list = get(handles.filename_box,'String');

% Combine path and filename together
fullpath = strcat(pathname,filename);

% Stupid matlab uses a different datastructure if only one file
% is selected, handle special case
if ischar(list)
    list = {list};
end
if ischar(filename)
    filename = {filename};
end
if ischar(fullpath)
    fullpath = {fullpath};
end
if isempty(list)
    list = {''};
end

filename = filename';
fullpath = fullpath';

% Get Selected Dataset
batch_selected = get(handles.batch_set,'Value');


% Add selected files to listbox
if strcmp(list,'No Files')
    list = filename;
%     handles.file_list = fullpath;
    handles.batch_data(batch_selected).file_list = fullpath;
elseif isempty(list(1)) || isempty(list{1}) 
    list = filename;
%     handles.file_list = fullpath;
    handles.batch_data(batch_selected).file_list = fullpath;
else
    list = [list;  filename];
%     handles.file_list = [handles.file_list; fullpath];
    handles.batch_data(batch_selected).file_list = [handles.batch_data(batch_selected).file_list; fullpath];
end
set(handles.filename_box,'String',list, 'Value',1);

% Load file
[~, ~, ext] = fileparts(fullpath{end});
if strcmp(ext, '.nii')
    % Read and autoset TE if present in description field
    % Use last file on list by default
    [nii.hdr,nii.filetype,nii.fileprefix,nii.machine] = load_nii_hdr(fullpath{end});
    te = nii.hdr.hist.descrip;
else
    te = '';
end

% Auto fill TE
if ~isempty(te)
    set(handles.te_box,'String',te);
%     handles.batch_data(batch_selected).parameters = str2num(te);
else
    set(handles.te_box,'String','');
%     handles.batch_data(batch_selected).parameters = '';
end


% Update handles structure
handles = update_parameters(handles, batch_selected);

% Adding files to list, need to calculateMap. set toggle to reflect
% this
handles.batch_data(batch_selected).to_do = 1;


[errormsg] = quick_check(handles);
handles = disp_error(errormsg, handles);

guidata(hObject, handles);




% --- Executes on button press in remove_files.
function remove_files_Callback(hObject, eventdata, handles)

index_selected = get(handles.filename_box,'Value');

% Get Selected Dataset
batch_selected = get(handles.batch_set,'Value');

list = get(handles.filename_box,'String');
if ~isempty(list) && ~strcmp(list(1),'No Files')
    curfile_list = handles.batch_data(batch_selected).file_list;
    list(index_selected) = [];
    curfile_list(index_selected) = [];

    handles.batch_data(batch_selected).file_list = curfile_list;
    set(handles.filename_box,'String',list, 'Value',1)
end

[errormsg] = quick_check(handles);
handles = disp_error(errormsg, handles);

guidata(hObject, handles);



function te_box_Callback(hObject, eventdata, handles) %#ok<*INUSD>

guidata(hObject, handles);
% Get Selected Dataset
batch_selected = get(handles.batch_set,'Value');

% Update handles structure
handles = update_parameters(handles, batch_selected);
% JOB_struct = setup_job(handles);

guidata(hObject, handles);
uiremember;


% --- Executes during object creation, after setting all properties.
function te_box_CreateFcn(hObject, eventdata, handles)
% hObject    handle to te_box (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
% --- Executes on button press in ok_button.
function ok_button_Callback(hObject, eventdata, handles) %#ok<*INUSL>

disp('User selected Submit Jobs')

[errormsg] = quick_check(handles);
handles = disp_error(errormsg, handles);
if ~isempty(errormsg)
    disp('Error');
    disp(errormsg);
    return
end

% If do_all toggled, set to_do for all file_list to 1
if get(handles.do_all, 'Value')
    file_list = handles.batch_data;
    for i = 1:numel(file_list)
        file_list(i).to_do = 1;
    end
    handles.batch_data = file_list;
end

% Reset to_do toggle if needed.
if get(handles.redo_done, 'Value')
    list = handles.batch_data;
    
    for i = 1:numel(list)
        handles.batch_data(i).to_do = 1;
    end
end

% Update handles structure
%handles = update_parameters(handles, batch_selected);
JOB_struct = setup_job(handles);

submit = 1;
dataset_to_process = 0; % 0 for all files

% Call fitting Function
[single_IMG submit data_setnum] = calculateMap_batch(JOB_struct, submit, dataset_to_process);


% --- Executes on button press in cancel_button.
function cancel_button_Callback(hObject, eventdata, handles)

disp('User selected Cancel')
delete(handles.figure1);



function number_cpus_Callback(hObject, eventdata, handles)
myCluster = parcluster('local');
set(handles.number_cpus, 'String', num2str(min(str2num(get(hObject,'String')),myCluster.NumWorkers)));
uiremember;


function output_basename_Callback(hObject, eventdata, handles)

% Get Selected Dataset
batch_selected = get(handles.batch_set,'Value');

% Update handles structure
handles = update_parameters(handles, batch_selected);

guidata(hObject, handles);



% --- Executes when selected object is changed in fit_type.
function fit_type_SelectionChangeFcn(hObject, eventdata, handles)

% Reset user input
set(handles.user_input_fn, 'String', 'No user function defined');

% Update handles structure
guidata(hObject, handles);

% Get Selected Dataset
batch_selected = get(handles.batch_set,'Value');

fit_type = get(get(handles.fit_type,'SelectedObject'),'Tag');

if ~isempty(strfind(fit_type,'t2'))
    set(handles.output_basename,'String','T2star_map');
    set(handles.tr,'Enable','off');
    
elseif ~isempty(strfind(fit_type, 'ADC'))
    set(handles.output_basename, 'String', 'ADC_map');
    set(handles.tr, 'Enable', 'off');
    
elseif ~isempty(strfind(fit_type, 't1'));
    set(handles.output_basename,'String','T1_map');
      
    if ~isempty(strfind(fit_type,'fa')) || ~isempty(strfind(fit_type,'ti_exponential'))
        set(handles.tr,'Enable','on');
    else
        set(handles.tr,'Enable','off');
    end
elseif ~isempty(strfind(fit_type, 'user_input'));
    [filename, pathname] = uigetfile( ...
        {'*.m';'*.*'}, ...
        'Pick custom fit file generated from cftool');
    
    if ~filename
        set(get(handles.fit_type,'SelectedObject'), 'Value', 0);
        return
    end
    
    % Prep file for ROCKETship
    % Check if tr is in equation and if so, whether TR has been defined. If
    % not, let user know
    [errormsg, tr_ready, equation, ncoeffs] = check_TRfit(handles, fullfile(pathname, filename));
    
    if tr_ready
        [equation, fit_name, errormsg, ncoeffs, coeffs, tr_present, fit_filename] = prepareFit(fullfile(pathname, filename), tr_ready);
        handles = disp_error(errormsg, handles);
        set(handles.output_basename,'String',fit_name);
        
        %Display info about the user defined function
        
        coeffstr = '';
        
        for i = 1:ncoeffs
            coeffstr = [coeffstr ',' coeffs{i}];
        end
  
        display{1} = ['Equation: ' equation];
        display{2} = [num2str(ncoeffs) ' variables:'];
        display{3} = coeffstr;
       
        set(handles.user_input_fn, 'String', display);
        if tr_present
            set(handles.tr,'Enable','on');
        end
      
        handles.batch_data(batch_selected).user_fittype_file = fit_filename;
        handles.batch_data(batch_selected).ncoeffs           = ncoeffs;
        handles.batch_data(batch_selected).coeffs            = coeffs;
        handles.batch_data(batch_selected).tr_present        = tr_present;
    else
        display{1} = ['Equation: ' equation];
        display{2} = [num2str(ncoeffs) ' variables:'];
        set(handles.user_input_fn, 'String', display);
        set(handles.tr,'Enable','on');
        handles = disp_error(errormsg, handles);
    end 
else
    %User input edit as needed.
    set(handles.output_basename,'String','');
    handles.batch_data(batch_selected).output_basename = set(handles.output_basename,'String');
end

if ~isempty(strfind(fit_type, 'user_input'))
    if tr_ready
        handles.batch_data(batch_selected).tr = tr_ready;
    end
else
    handles.batch_data(batch_selected).tr = '';
end
handles.batch_data(batch_selected).fit_type = fit_type;
handles.batch_data(batch_selected).output_basename = get(handles.output_basename, 'String');

% Update handles structure
handles = update_parameters(handles, batch_selected);

[errormsg] = quick_check(handles);
handles = disp_error(errormsg, handles);

if isempty(errormsg)
%     [single_IMG submit data_setnum, errormsg] = calculateMap_batch(JOB_struct, submit, dataset_num);
%     
%     if ~isempty(errormsg)
%         
%         handles = disp_error(errormsg, handles);
%         
%         
%     elseif isempty(single_IMG)
%         errormsg = 'Empty image';
%         
%         handles = disp_error(errormsg, handles);
%     else
%         %Display Image
%         
%         handles = visualize_R2(handles, single_IMG);
%         
%     end
else
%     set(get(handles.fit_type,'SelectedObject'), 'Value', 0);
%     set(handles.output_basename, 'String', '');
end


% Update handles structure
guidata(hObject, handles);



function rsquared_threshold_Callback(hObject, eventdata, handles)

cur_r2 = str2double(get(hObject,'String'));
if isempty(cur_r2)
    cur_r2 = 0;
    set(hobject, 'String', '0');
end

set(handles.r2slider, 'Value', cur_r2);

% Get Selected Dataset
batch_selected = get(handles.batch_set,'Value');

% Update handles structure
handles = update_parameters(handles, batch_selected);

[errormsg] = quick_check(handles);
handles = disp_error(errormsg, handles);

handles = visualize_R2(handles);

% Update handles structure
guidata(hObject, handles);
uiremember;



% --- Executes on button press in odd_echoes.
function odd_echoes_Callback(hObject, eventdata, handles)

% Get Selected Dataset
batch_selected = get(handles.batch_set,'Value');

% Update handles structure
handles = update_parameters(handles, batch_selected);

guidata(hObject, handles);
uiremember;


function tr_Callback(hObject, eventdata, handles)

% Get Selected Dataset
batch_selected = get(handles.batch_set,'Value');

% Update handles structure
handles = update_parameters(handles, batch_selected);

guidata(hObject, handles);
uiremember;

function smooth_size_Callback(hObject, eventdata, handles)

% Get Selected Dataset
batch_selected = get(handles.batch_set,'Value');

% Update handles structure
handles = update_parameters(handles, batch_selected);

guidata(hObject, handles);
uiremember;

% --- Executes on selection change in batch_set.
function batch_set_Callback(hObject, eventdata, handles)

guidata(hObject, handles);

handles = load_batch(handles);

guidata(hObject, handles);




% --- Executes on button press in add_batch.
function add_batch_Callback(hObject, eventdata, handles)

handles = makeNewbatch(handles);
guidata(hObject, handles);



% --- Executes on button press in remove_batch.
function remove_batch_Callback(hObject, eventdata, handles)

index_selected = get(handles.batch_set,'Value');
list = get(handles.batch_set,'String');

if ~isempty(list) && ~strcmp(list,'No Datasets')
    list(index_selected,:) = [];
    handles.batch_data(index_selected) = [];
    handles.datasets = handles.datasets - 1;
    set(handles.batch_total, 'String', num2str(handles.datasets), 'Value', 1);

    if handles.datasets < 1
        set(handles.selected_dataset, 'String', 'No current Dataset');
        set(handles.batch_set,'String', 'No Datasets');
        % Create new default dataset
        handles = makeNewbatch(handles);

    else
        set(handles.selected_dataset, 'String', 'Reselect Dataset');
        
        % Attempt to select the top dataset
        set(handles.batch_set,'String',list, 'Value',1)
        set(handles.filename_box, 'String', '');

        JOB_struct = setup_job(handles);
        handles = update_handles(handles, JOB_struct);
        handles = load_batch(handles);
    end
end

guidata(hObject, handles);


% --- Executes on slider movement.
function r2slider_Callback(hObject, eventdata, handles)

rsquared_slider = get(hObject,'Value');
set(handles.rsquared_threshold, 'String', num2str(rsquared_slider));

% Get Selected Dataset
batch_selected = get(handles.batch_set,'Value');
handles = update_parameters(handles, batch_selected);
% handles.batch_data(batch_selected).rsquared = str2double(get(hObject,'String'));

[errormsg] = quick_check(handles);
handles = disp_error(errormsg, handles);

handles = visualize_R2(handles);

guidata(hObject, handles);



function slice_num_Callback(hObject, eventdata, handles)

cur_slice = str2double(get(hObject,'String'));
if isempty(cur_slice)
    cur_slice = 1;
    set(hobject, 'String', '0');
end

set(handles.slice_slider, 'Value', cur_slice);

% Make sure that single_IMG exists
% try
%     check_single_IMG = handles.single_IMG;
%     check_single_IMG = 1;
% catch
%     check_single_IMG = 0;
% end

% if check_single_IMG
%     handles = visualize_R2(handles, handles.single_IMG);
% else
% end
handles = visualize_R2(handles);

% Update handles structure
guidata(hObject, handles);




% --- Executes on slider movement.
function slice_slider_Callback(hObject, eventdata, handles)

slice_slide = round(get(hObject,'Value'));

if slice_slide == 0
    slice_slide = 1;
end

set(handles.slice_num, 'String', num2str(slice_slide));

% try
%     check_single_IMG = handles.single_IMG;
%     check_single_IMG = 1;
% catch
%     check_single_IMG = 0;
% end
% 
% if check_single_IMG
%     
%     handles = visualize_R2(handles, handles.single_IMG);
% else
% end
handles = visualize_R2(handles);   

% Update handles structure
guidata(hObject, handles);



% --- Executes when selected object is changed in data_order.
function data_order_SelectionChangeFcn(hObject, eventdata, handles)

% Update handles structure
guidata(hObject, handles);

% Get Selected Dataset
batch_selected = get(handles.batch_set,'Value');

% Update handles structure
handles = update_parameters(handles, batch_selected);

[errormsg] = quick_check(handles);
handles = disp_error(errormsg, handles);

% Update handles structure
guidata(hObject, handles);


% --- Executes on button press in save_txt.
function save_txt_Callback(hObject, eventdata, handles)

guidata(hObject, handles);

curtoggle = get(hObject,'Value');

if(curtoggle)
    
    set(handles.email_log,'Enable','on');
    set(handles.batch_log, 'Enable', 'on');
else
    %No log save, need to uncheck everything else
    set(handles.email_log, 'Value', 0);
    set(handles.batch_log, 'Value', 0);
    set(handles.email_log,'Enable','off');
    set(handles.batch_log, 'Enable', 'off');
end

% Update handles structure
guidata(hObject, handles);
uiremember;


% --- Executes on button press in choose_log.
function choose_log_Callback(hObject, eventdata, handles)

guidata(hObject, handles);
folder_name = uigetdir(pwd, 'Choose Location to store master log');
set(handles.current_dir, 'String', folder_name);
guidata(hObject, handles);



% --- Executes on button press in old_log.
function old_log_Callback(hObject, eventdata, handles)

[FileName,PathName,FilterIndex] = uigetfile(fullfile(pwd, '*_log.mat'),'Select old batch log');

exist(fullfile(PathName, FileName))
fullfile(PathName, FileName)
%Error handling add here

if ~FileName
    % Cancel, nothing
    return
elseif ~exist(fullfile(PathName, FileName))
    warning([FileName ' does not exist.']);
    set(handles.status, 'String', [FileName ' does not exist.']);
    set(handles.status, 'ForegroundColor', 'red');
    set(handles.status, 'FontSize', 8);
else
    load(fullfile(PathName, FileName));
    
    if ~exist('JOB_struct')
        warning([FileName ' has wrong structure']);
        set(handles.status, 'String', [FileName ' has wrong structure']);
        set(handles.status, 'ForegroundColor', 'red');
        set(handles.status, 'FontSize', 8);
    else
        handles = update_handles(handles, JOB_struct);
        set(handles.status, 'String', ['Using old log: ' FileName]);
        set(handles.status, 'FontSize', 8);
    end
end

set(handles.redo_done, 'Enable', 'on');

guidata(hObject, handles);


% --- Executes on button press in file_up.
function file_up_Callback(hObject, eventdata, handles)

% Update handles structure
guidata(hObject, handles);


% Check if there is a dataset already. If not, do nothing.
list = get(handles.batch_set,'String');

if strcmp(list,'No Datasets')
    
else
    % Get the list of files present
    list = get(handles.filename_box,'String');
    
    % Get Selected Dataset
    batch_selected = get(handles.batch_set,'Value');
    
    % Get selected File
    file_selected  = get(handles.filename_box, 'Value');
    
    if file_selected > 1
        curfile_list = handles.batch_data(batch_selected).file_list;
        
        newfile_list = curfile_list;
        newlist      = list;
        
        newfile_list(file_selected-1) = curfile_list(file_selected);
        newlist(file_selected-1)      = list(file_selected);
        
        newfile_list(file_selected)   = curfile_list(file_selected-1);
        newlist(file_selected)        = list(file_selected-1);
        
        handles.batch_data(batch_selected).file_list = newfile_list;
        set(handles.filename_box,'String',newlist, 'Value',1)
        
        % Update handles structure
        handles = update_parameters(handles, batch_selected);
%         JOB_struct = setup_job(handles);
        set(handles.filename_box, 'Value', file_selected-1);
    end
end

guidata(hObject, handles);


% --- Executes on button press in file_down.
function file_down_Callback(hObject, eventdata, handles)

% Update handles structure
guidata(hObject, handles);

% Check if there is a dataset already. If not, do nothing.
batch_list = get(handles.batch_set,'String');
if ~isempty(batch_list) && ~strcmp(batch_list,'No Datasets')
    % Get the list of files present
    temp_file_list = get(handles.filename_box,'String');
    if ischar(temp_file_list)
        temp_file_list = {temp_file_list};
    end
    % Get Selected Dataset
    batch_selected = get(handles.batch_set,'Value');    
    % Get selected File
    file_selected  = get(handles.filename_box, 'Value');

    if file_selected < numel(temp_file_list);
        curfile_list = handles.batch_data(batch_selected).file_list;
        
        newfile_list = curfile_list;
        newlist      = temp_file_list;
        
        newfile_list(file_selected+1) = curfile_list(file_selected);
        newlist(file_selected+1)      = temp_file_list(file_selected);
        
        newfile_list(file_selected)   = curfile_list(file_selected+1);
        newlist(file_selected)        = temp_file_list(file_selected+1);
        
        handles.batch_data(batch_selected).file_list = newfile_list;
        set(handles.filename_box,'String',newlist, 'Value',1)
        
        % Update handles structure
        handles = update_parameters(handles, batch_selected);
%         JOB_struct = setup_job(handles);
        set(handles.filename_box, 'Value', file_selected+1);
    end
end
guidata(hObject, handles);


% --- Executes on button press in run_estimate.
function run_estimate_Callback(hObject, eventdata, handles)

batch_selected = get(handles.batch_set,'Value');
submit = 0;

[errormsg] = quick_check(handles);
handles = disp_error(errormsg, handles);

% Update handles structure
% handles = update_parameters(handles, batch_selected);
JOB_struct = setup_job(handles);


if isempty(errormsg)
    [single_IMG , ~ , ~, errormsg] = calculateMap_batch(JOB_struct, submit, batch_selected);
    
    if ~isempty(errormsg) 
        handles = disp_error(errormsg, handles);   
    elseif isempty(single_IMG)
        errormsg = 'Empty image';
        handles = disp_error(errormsg, handles);
    else
        %Store Image
        batch_selected = get(handles.batch_set,'Value');
        handles.batch_data(batch_selected).preview_image = single_IMG;
        
        %Display Image
        handles = visualize_R2(handles);
    end
end

% Update handles structure
guidata(hObject, handles);


% --- Executes on selection change in roi_box.
function roi_box_Callback(hObject, eventdata, handles)


% --- Executes during object creation, after setting all properties.
function roi_box_CreateFcn(hObject, eventdata, handles)

if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in add_roi.
function add_roi_Callback(hObject, eventdata, handles)
guidata(hObject, handles);

[filename, pathname, filterindex] = uigetfile( ...
    {  '*.nii','Nifti Files (*.nii)'; ...
    '*.roi','ImageJ ROI Files (*.roi)'; ...
    '*.hdr;*.img','Analyze Files (*.hdr, *.img)';...
    '*.*',  'All Files (*.*)'}, ...
    'Pick a file', ...
    'MultiSelect', 'on'); %#ok<NASGU>
if isequal(filename,0)
    %disp('User selected Cancel')
else
    %disp(['User selected ', fullfile(pathname, filename)])
    list = get(handles.roi_box,'String');
    
    % Combine path and filename together
    fullpath = strcat(pathname,filename);
    
    % Stupid matlab uses a different datastructure if only one file
    % is selected, handle special case
    if ischar(list)
        list = {list};
    end
    if ischar(filename)
        filename = {filename};
    end
    if ischar(fullpath)
        fullpath = {fullpath};
    end

    filename = filename';
    fullpath = fullpath';
    
    % Add selected files to listbox
    if strcmp(list,'No Files')
        list = filename;
        handles.roi_list = fullpath;
    elseif isempty(list) || isempty(list(1)) || isempty(list{1})
        list = filename;
        handles.roi_list = fullpath;
    else
        list = [list;  filename];
        handles.roi_list = [handles.roi_list; fullpath];
    end 
    
    set(handles.roi_box,'String',list, 'Value',1)
end

% Get Selected Dataset
batch_selected = get(handles.batch_set,'Value');

% Update handles structure
handles = update_parameters(handles, batch_selected);

guidata(hObject, handles);

% --- Executes on button press in remove_roi.
function remove_roi_Callback(hObject, eventdata, handles)
index_selected = get(handles.roi_box,'Value');
list = get(handles.roi_box,'String');
if ~isempty(handles.roi_list)
    for n=size(index_selected,2):-1:1
        % Remove from end of list first so resizing does not 
        % change subsequent index numbers
        %disp(['User removed ', list{index_selected(n)}]);
        list(index_selected(n)) = [];
        handles.roi_list(index_selected(n)) = [];
    end
end

set(handles.roi_box,'String',list, 'Value',1)
% Get Selected Dataset
batch_selected = get(handles.batch_set,'Value');

% Update handles structure
handles = update_parameters(handles, batch_selected);

guidata(hObject, handles);

% --- Executes on button press in fit_voxels.
function fit_voxels_Callback(hObject, eventdata, handles)
% Get Selected Dataset
batch_selected = get(handles.batch_set,'Value');

% Update handles structure
handles = update_parameters(handles, batch_selected);

guidata(hObject, handles);
uiremember;

% --- Executes during object creation, after setting all properties.
function fit_voxels_CreateFcn(hObject, eventdata, handles)
uirestore;


% --- Executes on selection change in filename_box.
function filename_box_Callback(hObject, eventdata, handles)


% --- Executes during object creation, after setting all properties.
function rsquared_threshold_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
uirestore;


% --- Executes during object creation, after setting all properties.
function slice_num_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes during object creation, after setting all properties.
function r2slider_CreateFcn(hObject, eventdata, handles)

if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


% --- Executes during object creation, after setting all properties.
function slice_slider_CreateFcn(hObject, eventdata, handles)

if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end

% --- Executes during object creation, after setting all properties.
function filename_box_CreateFcn(hObject, eventdata, handles)

if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes during object creation, after setting all properties.
function tr_CreateFcn(hObject, eventdata, handles)
uirestore;
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes during object creation, after setting all properties.
function output_basename_CreateFcn(hObject, eventdata, handles)

if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in file_format.
function file_format_Callback(hObject, eventdata, handles)
uiremember;

% --- Executes during object creation, after setting all properties.
function file_format_CreateFcn(hObject, eventdata, handles)
uirestore;
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes during object creation, after setting all properties.
function batch_set_CreateFcn(hObject, eventdata, handles)
uirestore;
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function email_box_Callback(hObject, eventdata, handles)
uiremember;

% --- Executes during object creation, after setting all properties.
function email_box_CreateFcn(hObject, eventdata, handles)
uirestore;
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes during object creation, after setting all properties.
function number_cpus_CreateFcn(hObject, eventdata, handles)
uirestore;
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in neuroecon.
function neuroecon_Callback(hObject, eventdata, handles)
uiremember;

% --- Executes during object creation, after setting all properties.
function save_txt_CreateFcn(hObject, eventdata, handles)
uirestore;

% --- Executes on button press in save_log.
function save_log_Callback(hObject, eventdata, handles)
uiremember;

% --- Executes during object creation, after setting all properties.
function save_log_CreateFcn(hObject, eventdata, handles)
uirestore;

% --- Executes on button press in email_log.
function email_log_Callback(hObject, eventdata, handles)
uiremember;

% --- Executes during object creation, after setting all properties.
function email_log_CreateFcn(hObject, eventdata, handles)
uirestore;

% --- Executes on button press in batch_log.
function batch_log_Callback(hObject, eventdata, handles)
uiremember;

% --- Executes during object creation, after setting all properties.
function batch_log_CreateFcn(hObject, eventdata, handles)
uirestore;

% --- Executes on button press in redo_done.
function redo_done_Callback(hObject, eventdata, handles)
uiremember;

% --- Executes during object creation, after setting all properties.
function redo_done_CreateFcn(hObject, eventdata, handles)
uirestore;

% --- Executes on selection change in do_all.
function do_all_Callback(hObject, eventdata, handles)
uiremember;

% --- Executes during object creation, after setting all properties.
function do_all_CreateFcn(hObject, eventdata, handles)
uirestore;
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes during object creation, after setting all properties.
function odd_echoes_CreateFcn(hObject, eventdata, handles)
uirestore;

% --- Executes during object creation, after setting all properties.
function neuroecon_CreateFcn(hObject, eventdata, handles)
uirestore;

% --- Executes during object creation, after setting all properties.
function smooth_size_CreateFcn(hObject, eventdata, handles)
uirestore;
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
