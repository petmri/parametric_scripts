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

% Last Modified by GUIDE v2.5 28-Dec-2013 10:15:54

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
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to fitting_gui (see VARARGIN)

% Choose default command line output for fitting_gui
handles.output = hObject;

% Create structure to hold file list
handles.file_list = {};
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
handles.file_list(1).file_list = {};

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


% Update handles structure
guidata(hObject, handles);

% UIWAIT makes fitting_gui wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = fitting_gui_OutputFcn(hObject, eventdata, handles)
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on button press in add_files.
function add_files_Callback(hObject, eventdata, handles)
% hObject    handle to add_files (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Update handles structure
guidata(hObject, handles);

% Check if there is a dataset already. If not, add one.
list = get(handles.batch_set,'String');
% Add selected files to batchbox
if strcmp(list,'No Datasets')
    
    handles = makeNewbatch(handles);
    guidata(hObject, handles);
end

% Get Selected Dataset
batch_selected = get(handles.batch_set,'Value');

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
else
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
  
    
    % Add selected files to listbox
    if strcmp(list,'No Files')
        list = filename;
        handles.file_list(batch_selected).file_list = fullpath;
    elseif isempty(list(1)) || isempty(list{1}) 
        list = filename;
        handles.file_list(batch_selected).file_list = fullpath;
    else

           list = [list;  filename];
 
        handles.file_list(batch_selected).file_list = [handles.file_list(batch_selected).file_list; fullpath];
    end
    
   
    
    [~, ~, ext] = fileparts(fullpath{end});
    if strcmp(ext, '.nii')
        % Read and autoset TE if present in description field
        % Use last file on list by default
        [nii.hdr,nii.filetype,nii.fileprefix,nii.machine] = load_nii_hdr(fullpath{end});
        te = nii.hdr.hist.descrip;
    else
        te = '';
    end
    
    
    if ~isempty(te)
        set(handles.te_box,'String',te);
        handles.file_list(batch_selected).parameters = te;
    else
        set(handles.te_box,'String','');
        handles.file_list(batch_selected).parameters = '';
    end
    
    % Adding files to list, need to calculateMap. set toggle to reflect
    % this
    handles.file_list(batch_selected).to_do = 1;
    
    set(handles.filename_box,'String',list, 'Value',1);
    
    % Update handles structure
    handles = update_parameters(handles, batch_selected);
    JOB_struct = setup_job(handles);
end

guidata(hObject, handles);




% --- Executes on button press in remove_files.
function remove_files_Callback(hObject, eventdata, handles)
% hObject    handle to remove_files (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
index_selected = get(handles.filename_box,'Value');

% Get Selected Dataset
batch_selected = get(handles.batch_set,'Value');

list = get(handles.filename_box,'String');
curfile_list = handles.file_list(batch_selected).file_list;
list(index_selected) = [];
curfile_list(index_selected) = [];

handles.file_list(batch_selected).file_list = curfile_list;
set(handles.filename_box,'String',list, 'Value',1)
guidata(hObject, handles);

% --- Executes on selection change in filename_box.
function filename_box_Callback(hObject, eventdata, handles)
% hObject    handle to filename_box (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns filename_box contents as cell array
%        contents{get(hObject,'Value')} returns selected item from filename_box



% --- Executes during object creation, after setting all properties.
function filename_box_CreateFcn(hObject, eventdata, handles)
% hObject    handle to filename_box (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function te_box_Callback(hObject, eventdata, handles) %#ok<*INUSD>
% hObject    handle to te_box (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of te_box as text
%        str2double(get(hObject,'String')) returns contents of te_box as a double

guidata(hObject, handles);
% Get Selected Dataset
batch_selected = get(handles.batch_set,'Value');

te = get(hObject,'String');
handles.file_list(batch_selected).parameters = str2num(te);

% Update handles structure
handles = update_parameters(handles, batch_selected);
JOB_struct = setup_job(handles);

guidata(hObject, handles);



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
% hObject    handle to ok_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

disp('User selected Submit Jobs')
% file_list = handles.file_list;
% parameter_list = get(handles.te_box,'String'); %#ok<ST2NM>
% fit_type = get(get(handles.fittype,'SelectedObject'),'Tag');
% data_order = get(get(handles.data_order,'SelectedObject'),'Tag');
% % single_fit = get(handles.single_fit,'Value');
% number_cpus = str2num(get(handles.number_cpus,'String')); %#ok<ST2NM>
% neuroecon = get(handles.neuroecon,'Value');
% email = get(handles.email_box,'String');
% output_basename = get(handles.output_basename,'String');
% odd_echoes = get(handles.odd_echoes, 'Value');
% rsquared_threshold = str2num(get(handles.rsquared_threshold, 'String')); %#ok<ST2NM>
% tr = str2num(get(handles.tr, 'String')); %#ok<ST2NM>

% All files now in file_list structure
%{
handles.file_list().file_list: file_list
handles.file_list().parameters: parameter_list
handles.file_list().fit_type: fit_type
handles.file_list().data_order: xyzn, xynz, xyz/file
handles.file_list().output_basename: outputbasename
handles.file_list().odd_echoes: odd_echoes
handles.file_list().rsquared: rsquared_threshold
handles.file_list().tr: tr
%}

% If do_all toggled, set to_do for all file_list to 1
if get(handles.do_all, 'Value')
    file_list = handles.file_list;
    for i = 1:numel(file_list)
        file_list(i).to_do = 1;
    end
    handles.file_list = file_list;
end


[errormsg] = quick_check(handles);
handles = disp_error(errormsg, handles);

% Reset to_do toggle if needed.

if get(handles.redo_done, 'Value')
    
    list = handles.file_list;
    
    for i = 1:numel(list)
        handles.file_list(i).to_do = 1;
    end
end

% Update handles structure
%handles = update_parameters(handles, batch_selected);
JOB_struct = setup_job(handles);


submit = 1;
dataset_num = 0; % 0 for all files

%delete(handles.figure1);
% disp('User selected files: ');
% disp(file_list);
% disp('User slected TE: ');
% disp(te_list);
% disp('User slected fit: ');
% disp(fit_type);
% disp('User slected CPUs: ');
% disp(number_cpus);
% disp('User slected Neuroecon: ');
% disp(neuroecon);
% disp('User slected email: ');
% disp(email);

% Call T2 Function
[single_IMG submit data_setnum] = calculateMap_batch(JOB_struct, submit, dataset_num);

%calculateMap(file_list,parameter_list,fit_type,odd_echoes,rsquared_threshold, number_cpus, neuroecon, output_basename,data_order,tr, email);


% if single_fit
% 	calculateMultiFile(file_list,te_list,fit_type,rsquared_threshold, number_cpus, neuroecon, output_basename,tr, email);
% else
% 	calculateT2(file_list,te_list,fit_type,odd_echoes,rsquared_threshold, number_cpus, neuroecon, output_basename,tr, email);
% end

% --- Executes on button press in cancel_button.
function cancel_button_Callback(hObject, eventdata, handles)
% hObject    handle to cancel_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
disp('User selected Cancel')
delete(handles.figure1);


% --- Executes on button press in neuroecon.
function neuroecon_Callback(hObject, eventdata, handles)
% hObject    handle to neuroecon (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of neuroecon



function number_cpus_Callback(hObject, eventdata, handles)
% hObject    handle to number_cpus (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of number_cpus as text
%        str2double(get(hObject,'String')) returns contents of number_cpus as a double

myCluster = parcluster('local');
set(handles.number_cpus, 'String', num2str(min(str2num(get(hObject,'String')),myCluster.NumWorkers)));



% --- Executes during object creation, after setting all properties.
function number_cpus_CreateFcn(hObject, eventdata, handles)
% hObject    handle to number_cpus (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function email_box_Callback(hObject, eventdata, handles)
% hObject    handle to email_box (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of email_box as text
%        str2double(get(hObject,'String')) returns contents of email_box as a double


% --- Executes during object creation, after setting all properties.
function email_box_CreateFcn(hObject, eventdata, handles)
% hObject    handle to email_box (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in single_fit.
function single_fit_Callback(hObject, eventdata, handles)
% hObject    handle to single_fit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of single_fit



function output_basename_Callback(hObject, eventdata, handles)
% hObject    handle to output_basename (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of output_basename as text
%        str2double(get(hObject,'String')) returns contents of output_basename as a double

% Get Selected Dataset
batch_selected = get(handles.batch_set,'Value');

handles.file_list(batch_selected).output_basename = get(hObject,'String');

% Update handles structure
handles = update_parameters(handles, batch_selected);
JOB_struct = setup_job(handles);

guidata(hObject, handles);



% --- Executes during object creation, after setting all properties.
function output_basename_CreateFcn(hObject, eventdata, handles)
% hObject    handle to output_basename (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



% --- Executes when selected object is changed in fittype.
function fittype_SelectionChangeFcn(hObject, eventdata, handles)
% hObject    handle to the selected object in fittype
% eventdata  structure with the following fields (see UIBUTTONGROUP)
%	EventName: string 'SelectionChanged' (read only)
%	OldValue: handle of the previously selected object or empty if none was selected
%	NewValue: handle of the currently selected object
% handles    structure with handles and user data (see GUIDATA)

% Reset user input
set(handles.user_input_fn, 'String', 'No user function defined');

% Update handles structure
guidata(hObject, handles);

% Get Selected Dataset
batch_selected = get(handles.batch_set,'Value');

fit_type = get(get(handles.fittype,'SelectedObject'),'Tag');

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
      
        handles.file_list(batch_selected).user_fittype_file = fit_filename;
        handles.file_list(batch_selected).ncoeffs           = ncoeffs;
        handles.file_list(batch_selected).coeffs            = coeffs;
        handles.file_list(batch_selected).tr_present        = tr_present;
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
    handles.file_list(batch_selected).output_basename = set(handles.output_basename,'String');
    
    
end


if ~isempty(strfind(fit_type, 'user_input'))
    if tr_ready
        handles.file_list(batch_selected).tr = tr_ready;
    end
else
    handles.file_list(batch_selected).tr = '';
end
handles.file_list(batch_selected).fit_type = fit_type;
handles.file_list(batch_selected).output_basename = get(handles.output_basename, 'String');


submit = 0;
dataset_num = batch_selected;

[errormsg] = quick_check(handles);
handles = disp_error(errormsg, handles);

% Update handles structure
handles = update_parameters(handles, batch_selected);
JOB_struct = setup_job(handles);


if isempty(errormsg)
    [single_IMG submit data_setnum, errormsg] = calculateMap_batch(JOB_struct, submit, dataset_num);
    
    if ~isempty(errormsg)
        
        handles = disp_error(errormsg, handles);
        
        
    elseif isempty(single_IMG)
        errormsg = 'Empty image';
        
        handles = disp_error(errormsg, handles);
    else
        %Display Image
        
        handles = visualize_R2(handles, single_IMG);
        
    end
else
    set(get(handles.fittype,'SelectedObject'), 'Value', 0);
    set(handles.output_basename, 'String', '');
end




% Update handles structure
guidata(hObject, handles);



function rsquared_threshold_Callback(hObject, eventdata, handles)
% hObject    handle to rsquared_threshold (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of rsquared_threshold as text
%        str2double(get(hObject,'String')) returns contents of rsquared_threshold as a double

cur_r2 = str2double(get(hObject,'String'));
if isempty(cur_r2)
    cur_r2 = 0;
    set(hobject, 'String', '0');
end

set(handles.r2slider, 'Value', cur_r2);

% Get Selected Dataset
batch_selected = get(handles.batch_set,'Value');

handles.file_list(batch_selected).rsquared = str2num(get(hObject,'String'));


submit = 0;
dataset_num = batch_selected;

[errormsg] = quick_check(handles);
handles = disp_error(errormsg, handles);

% Update handles structure
handles = update_parameters(handles, batch_selected);
JOB_struct = setup_job(handles);
% if isempty(errormsg)
%     [single_IMG submit data_setnum errormsg] = calculateMap_batch(JOB_struct, submit, dataset_num);
%
%
%     if ~isempty(errormsg)
%         handles = disp_error(errormsg, handles);
%     elseif isempty(single_IMG)
%         errormsg = 'Empty image';
%         handles = disp_error(errormsg, handles);
%     else
%         %Display Image
%
%         handles = visualize_R2(handles, single_IMG);
%
%     end
% end
% Update handles structure
guidata(hObject, handles);


% --- Executes during object creation, after setting all properties.
function rsquared_threshold_CreateFcn(hObject, eventdata, handles)
% hObject    handle to rsquared_threshold (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in odd_echoes.
function odd_echoes_Callback(hObject, eventdata, handles)
% hObject    handle to odd_echoes (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of odd_echoes

% Get Selected Dataset
batch_selected = get(handles.batch_set,'Value');

handles.file_list(batch_selected).odd_echoes =  get(hObject,'Value');

% Update handles structure
handles = update_parameters(handles, batch_selected);
JOB_struct = setup_job(handles);

guidata(hObject, handles);



function tr_Callback(hObject, eventdata, handles)
% hObject    handle to tr (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of tr as text
%        str2double(get(hObject,'String')) returns contents of tr as a double

% Get Selected Dataset
batch_selected = get(handles.batch_set,'Value');

handles.file_list(batch_selected).tr =  str2num(get(hObject,'String'));

% Update handles structure
handles = update_parameters(handles, batch_selected);
JOB_struct = setup_job(handles);

guidata(hObject, handles);


% --- Executes during object creation, after setting all properties.
function tr_CreateFcn(hObject, eventdata, handles)
% hObject    handle to tr (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function batch_num_Callback(hObject, eventdata, handles)
% hObject    handle to batch_num (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of batch_num as text
%        str2double(get(hObject,'String')) returns contents of batch_num as a double


% --- Executes during object creation, after setting all properties.
function batch_num_CreateFcn(hObject, eventdata, handles)
% hObject    handle to batch_num (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function batch_total_Callback(hObject, eventdata, handles)
% hObject    handle to batch_total (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of batch_total as text
%        str2double(get(hObject,'String')) returns contents of batch_total as a double


% --- Executes during object creation, after setting all properties.
function batch_total_CreateFcn(hObject, eventdata, handles)
% hObject    handle to batch_total (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in batch_set.
function batch_set_Callback(hObject, eventdata, handles)
% hObject    handle to batch_set (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns batch_set contents as cell array
%        contents{get(hObject,'Value')} returns selected item from batch_set
guidata(hObject, handles);
cur_batch = get(hObject,'Value');

list = handles.file_list(cur_batch).file_list;

%Remove the directory path to allow nice visualization
list = visualize_list(list);

%handles.file_list(cur_batch)


% Reset radiobuttons
set(get(handles.fittype,'SelectedObject'),'Value', 0);
set(get(handles.data_order, 'SelectedObject'), 'Value', 0);
set(handles.te_box, 'String', '');
set(handles.filename_box,'String',list, 'Value',1);
set(handles.tr, 'String', '');
set(handles.odd_echoes, 'Value', 0);
set(handles.output_basename,'String','');
set(handles.rsquared_threshold,  'String' ,num2str(0.6));
handles = visualize_R2(handles, '');

if ~isempty(list)
    % Set radiobuttons
    handles.file_list(cur_batch).fit_type
    disp('batch select')
    if ~isempty(handles.file_list(cur_batch).fit_type)
        eval(['set(handles.' handles.file_list(cur_batch).fit_type ', ''Value'', 1)']);
    end
    if ~isempty(handles.file_list(cur_batch).data_order)
        eval(['set(handles.' handles.file_list(cur_batch).data_order ', ''Value'', 1)']);
    end
    set(handles.output_basename,'String',handles.file_list(cur_batch).output_basename);
    set(handles.te_box, 'String', num2str(handles.file_list(cur_batch).parameters));
    set(handles.tr,'String',handles.file_list(cur_batch).tr);
    set(handles.odd_echoes, 'Value', handles.file_list(cur_batch).odd_echoes);
    set(handles.rsquared_threshold,  'String' ,num2str(handles.file_list(cur_batch).rsquared));
end

set(handles.dataset_num, 'String', num2str(cur_batch));

% Update R2
submit = 0;
dataset_num = cur_batch;

[errormsg] = quick_check(handles);
handles = disp_error(errormsg, handles);

% Update handles structure
handles = update_parameters(handles, cur_batch);
JOB_struct = setup_job(handles);

if isempty(errormsg)
    [single_IMG submit data_setnum] = calculateMap_batch(JOB_struct, submit, dataset_num);
    
    if ~isempty(errormsg)
        
        handles = disp_error(errormsg, handles);
        
        
        %     elseif isempty(single_IMG)
        %         errormsg = 'Empty image';
        %
        %         handles = disp_error(errormsg, handles);
    else
        %Display Image
        
        handles = visualize_R2(handles, single_IMG);
        
    end
else
    set(get(handles.fittype,'SelectedObject'), 'Value', 0);
    set(handles.output_basename, 'String', '');
end


guidata(hObject, handles);



% --- Executes during object creation, after setting all properties.
function batch_set_CreateFcn(hObject, eventdata, handles)
% hObject    handle to batch_set (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in add_batch.
function add_batch_Callback(hObject, eventdata, handles)
% hObject    handle to add_batch (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles = makeNewbatch(handles);


guidata(hObject, handles);



% --- Executes on button press in remove_batch.
function remove_batch_Callback(hObject, eventdata, handles)
% hObject    handle to remove_batch (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

index_selected = get(handles.batch_set,'Value');
list = get(handles.batch_set,'String');

list(index_selected,:) = [];
handles.file_list(index_selected) = [];
handles.datasets = handles.datasets - 1;
set(handles.batch_total, 'String', num2str(handles.datasets), 'Value', 1);

if handles.datasets < 1
    set(handles.dataset_num, 'String', 'No current Dataset');
    list = '';
    list(1,:) = 'No Datasets';
else
    set(handles.dataset_num, 'String', 'Reselect Dataset');
end

index_selected
set(handles.batch_set,'String',list, 'Value',1)

set(handles.filename_box, 'String', '');

JOB_struct = setup_job(handles);
handles = update_handles(handles, JOB_struct);

guidata(hObject, handles);


% --- Executes on slider movement.
function r2slider_Callback(hObject, eventdata, handles)
% hObject    handle to r2slider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider

rsquared_slider = get(hObject,'Value');

set(handles.rsquared_threshold, 'String', num2str(rsquared_slider));


% Get Selected Dataset
batch_selected = get(handles.batch_set,'Value');

handles.file_list(batch_selected).rsquared = str2double(get(hObject,'String'));


submit = 0;
dataset_num = batch_selected;


[errormsg] = quick_check(handles);
handles = disp_error(errormsg, handles);



% if isempty(errormsg)
%     % Update handles structure
%     handles = update_parameters(handles, batch_selected);
%     JOB_struct = setup_job(handles);
%     [single_IMG submit data_setnum errormsg] = calculateMap_batch(JOB_struct, submit, dataset_num);
%
%     if ~isempty(errormsg)
%
%         handles = disp_error(errormsg, handles);
% %     elseif isempty(single_IMG)
% %         errormsg = 'Empty image';
% %
% %         handles = disp_error(errormsg, handles);
%     else
%         %Display Image
%
%         handles = visualize_R2(handles, single_IMG);
%
%
%     end
% end
% Update handles structure
guidata(hObject, handles);





% --- Executes during object creation, after setting all properties.
function r2slider_CreateFcn(hObject, eventdata, handles)
% hObject    handle to r2slider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end



function slice_num_Callback(hObject, eventdata, handles)
% hObject    handle to slice_num (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of slice_num as text
%        str2double(get(hObject,'String')) returns contents of slice_num as a double



cur_slice = str2double(get(hObject,'String'));
if isempty(cur_slice)
    cur_slice = 1;
    set(hobject, 'String', '0');
end

set(handles.slice_slider, 'Value', cur_slice);

% Make sure that single_IMG exists
try
    check_single_IMG = handles.single_IMG;
    check_single_IMG = 1;
catch
    check_single_IMG = 0;
end

if check_single_IMG
    
    handles = visualize_R2(handles, handles.single_IMG);
else
    
    
end

% Update handles structure
guidata(hObject, handles);




% --- Executes during object creation, after setting all properties.
function slice_num_CreateFcn(hObject, eventdata, handles)
% hObject    handle to slice_num (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on slider movement.
function slice_slider_Callback(hObject, eventdata, handles)
% hObject    handle to slice_slider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider

slice_slide = round(get(hObject,'Value'));

if slice_slide == 0
    slice_slide = 1;
end

set(handles.slice_num, 'String', num2str(slice_slide));

try
    check_single_IMG = handles.single_IMG;
    check_single_IMG = 1;
catch
    check_single_IMG = 0;
end

if check_single_IMG
    
    handles = visualize_R2(handles, handles.single_IMG);
else
    
    
end

% Update handles structure
guidata(hObject, handles);



% --- Executes during object creation, after setting all properties.
function slice_slider_CreateFcn(hObject, eventdata, handles)
% hObject    handle to slice_slider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


% --- If Enable == 'on', executes on mouse press in 5 pixel border.
% --- Otherwise, executes on mouse press in 5 pixel border or over xynz.
function xynz_ButtonDownFcn(hObject, eventdata, handles)
% hObject    handle to xynz (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes when selected object is changed in data_order.
function data_order_SelectionChangeFcn(hObject, eventdata, handles)
% hObject    handle to the selected object in data_order
% eventdata  structure with the following fields (see UIBUTTONGROUP)
%	EventName: string 'SelectionChanged' (read only)
%	OldValue: handle of the previously selected object or empty if none was selected
%	NewValue: handle of the currently selected object
% handles    structure with handles and user data (see GUIDATA)

% Update handles structure
guidata(hObject, handles);

% Get Selected Dataset
batch_selected = get(handles.batch_set,'Value');

data_order = get(get(handles.data_order,'SelectedObject'),'Tag');
if ~isempty(strfind(data_order,'xyzn'))
    handles.file_list(batch_selected).data_order = 'xyzn';
    
elseif ~isempty(strfind(data_order, 'xynz'))
    handles.file_list(batch_selected).data_order = 'xynz';
    
elseif ~isempty(strfind(data_order, 'xyzfile'));
    handles.file_list(batch_selected).data_order = 'xyzfile';
    
else
    %Nothing right now
    
end

[errormsg] = quick_check(handles);
handles = disp_error(errormsg, handles);

% Update handles structure
handles = update_parameters(handles, batch_selected);
JOB_struct = setup_job(handles);


% Update handles structure
guidata(hObject, handles);


% --- Executes on button press in save_txt.
function save_txt_Callback(hObject, eventdata, handles)
% hObject    handle to save_txt (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of save_txt
guidata(hObject, handles);

curtoggle = get(hObject,'Value');

if(curtoggle)
    
    set(handles.email_log,'Enable','on');
    set(handles.separate_logs, 'Enable', 'on');
else
    %No log save, need to uncheck everything else
    set(handles.email_log, 'Value', 0);
    set(handles.separate_logs, 'Value', 0);
    set(handles.email_log,'Enable','off');
    set(handles.separate_logs, 'Enable', 'off');
end

% Update handles structure
guidata(hObject, handles);


% --- Executes on button press in email_log.
function email_log_Callback(hObject, eventdata, handles)
% hObject    handle to email_log (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of email_log


% --- Executes on button press in separate_logs.
function separate_logs_Callback(hObject, eventdata, handles)
% hObject    handle to separate_logs (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of separate_logs



function edit13_Callback(hObject, eventdata, handles)
% hObject    handle to choose_log (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of choose_log as text
%        str2double(get(hObject,'String')) returns contents of choose_log as a double


% --- Executes during object creation, after setting all properties.
function choose_log_CreateFcn(hObject, eventdata, handles)
% hObject    handle to choose_log (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in choose_log.
function choose_log_Callback(hObject, eventdata, handles)
% hObject    handle to choose_log (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

guidata(hObject, handles);
folder_name = uigetdir(pwd, 'Choose Location to store master log');
set(handles.current_dir, 'String', folder_name);
guidata(hObject, handles);


% --- Executes during object creation, after setting all properties.
function log_name_CreateFcn(hObject, eventdata, handles)
% hObject    handle to log_name (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes when figure1 is resized.
function figure1_ResizeFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in old_log.
function old_log_Callback(hObject, eventdata, handles)
% hObject    handle to old_log (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

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



% --- Executes on button press in save_log.
function save_log_Callback(hObject, eventdata, handles)
% hObject    handle to save_log (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of save_log


% --- Executes on selection change in do_all.
function do_all_Callback(hObject, eventdata, handles)
% hObject    handle to do_all (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns do_all contents as cell array
%        contents{get(hObject,'Value')} returns selected item from do_all
guidata(hObject, handles);


% --- Executes during object creation, after setting all properties.
function do_all_CreateFcn(hObject, eventdata, handles)
% hObject    handle to do_all (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on slider movement.
function slider5_Callback(hObject, eventdata, handles)
% hObject    handle to slice_slider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider


% --- Executes during object creation, after setting all properties.
function slider5_CreateFcn(hObject, eventdata, handles)
% hObject    handle to slice_slider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


% --------------------------------------------------------------------
function fittype_ButtonDownFcn(hObject, eventdata, handles)
% hObject    handle to fittype (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

disp('ButtonDow')


% --- Executes on key press with focus on remove_files and none of its controls.
function remove_files_KeyPressFcn(hObject, eventdata, handles)
% hObject    handle to remove_files (see GCBO)
% eventdata  structure with the following fields (see UICONTROL)
%	Key: name of the key that was pressed, in lower case
%	Character: character interpretation of the key(s) that was pressed
%	Modifier: name(s) of the modifier key(s) (i.e., control, shift) pressed
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in file_up.
function file_up_Callback(hObject, eventdata, handles)
% hObject    handle to file_up (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

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
        curfile_list = handles.file_list(batch_selected).file_list;
        
        newfile_list = curfile_list;
        newlist      = list;
        
        newfile_list(file_selected-1) = curfile_list(file_selected);
        newlist(file_selected-1)      = list(file_selected);
        
        newfile_list(file_selected)   = curfile_list(file_selected-1);
        newlist(file_selected)        = list(file_selected-1);
        
        handles.file_list(batch_selected).file_list = newfile_list;
        set(handles.filename_box,'String',newlist, 'Value',1)
        
        % Update handles structure
        handles = update_parameters(handles, batch_selected);
        JOB_struct = setup_job(handles);
        set(handles.filename_box, 'Value', file_selected-1);
    end
end

guidata(hObject, handles);


% --- Executes on button press in file_down.
function file_down_Callback(hObject, eventdata, handles)
% hObject    handle to file_down (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

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
    
    if file_selected < numel(list);
        curfile_list = handles.file_list(batch_selected).file_list;
        
        newfile_list = curfile_list;
        newlist      = list;
        
        newfile_list(file_selected+1) = curfile_list(file_selected);
        newlist(file_selected+1)      = list(file_selected);
        
        newfile_list(file_selected)   = curfile_list(file_selected+1);
        newlist(file_selected)        = list(file_selected+1);
        
        handles.file_list(batch_selected).file_list = newfile_list;
        set(handles.filename_box,'String',newlist, 'Value',1)
        
        % Update handles structure
        handles = update_parameters(handles, batch_selected);
        JOB_struct = setup_job(handles);
        set(handles.filename_box, 'Value', file_selected+1);
    end
end
guidata(hObject, handles);


% --- If Enable == 'on', executes on mouse press in 5 pixel border.
% --- Otherwise, executes on mouse press in 5 pixel border or over file_up.
function file_up_ButtonDownFcn(hObject, eventdata, handles)
% hObject    handle to file_up (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- If Enable == 'on', executes on mouse press in 5 pixel border.
% --- Otherwise, executes on mouse press in 5 pixel border or over add_files.
function add_files_ButtonDownFcn(hObject, eventdata, handles)
% hObject    handle to add_files (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in redo_done.
function redo_done_Callback(hObject, eventdata, handles)
% hObject    handle to redo_done (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of redo_done


% --- Executes on selection change in file_format.
function file_format_Callback(hObject, eventdata, handles)
% hObject    handle to file_format (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns file_format contents as cell array
%        contents{get(hObject,'Value')} returns selected item from file_format


% --- Executes during object creation, after setting all properties.
function file_format_CreateFcn(hObject, eventdata, handles)
% hObject    handle to file_format (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- If Enable == 'on', executes on mouse press in 5 pixel border.
% --- Otherwise, executes on mouse press in 5 pixel border or over user_input.
function user_input_ButtonDownFcn(hObject, eventdata, handles)
% hObject    handle to user_input (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
