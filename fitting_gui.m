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

% Last Modified by GUIDE v2.5 12-Dec-2013 19:22:46

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
imagesc(zeros(100,100))
set(handles.r2graph, 'XTick', []);
set(handles.r2graph, 'YTick', []);

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

% Get Selected Dataset
batch_selected = get(handles.batch_set,'Value');

[filename, pathname, filterindex] = uigetfile( ...
    {  '*.nii','Nifti Files (*.nii)'; ...
	'*2dseq','Bruker Files (2dseq)'; ...
    '*.hdr;*.img','Analyze Files (*.hdr, *.img)';...
    '*.*',  'All Files (*.*)'}, ...
    'Pick a file', ...
    'MultiSelect', 'on'); 
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

    filename = filename';
    fullpath = fullpath';
        
    % Add selected files to listbox
	if strcmp(list,'No Files')
		list = filename;
		handles.file_list(batch_selected).filelist = fullpath;
	else
		list = [list;  filename];
		handles.file_list(batch_selected).filelist = [handles.file_list(batch_selected).filelist; fullpath];
	end
    
	% Read and autoset TE if present in description field
	% Use last file on list by default
	[nii.hdr,nii.filetype,nii.fileprefix,nii.machine] = load_nii_hdr(fullpath{end});
	te = nii.hdr.hist.descrip;
    
    
	if ~isempty(te)
		set(handles.te_box,'String',te);
        handles.file_list(batch_selected).parameters = te; 
    else
        set(handles.te_box,'String','');
        handles.file_list(batch_selected).parameters = ''; 
    end
	
    
    set(handles.filename_box,'String',list, 'Value',1);
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
curfile_list = handles.file_list(batch_selected).filelist;
list(index_selected) = [];
curfile_list(index_selected) = [];

handles.file_list(batch_selected).filelist = curfile_list;
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

% Get Selected Dataset
batch_selected = get(handles.batch_set,'Value');

te = get(hObject,'String');
str2num(get(hObject,'String'));
handles.file_list(batch_selected).parameters = te;


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

disp('User selected Ok')
file_list = handles.file_list;
parameter_list = get(handles.te_box,'String'); %#ok<ST2NM>
fit_type = get(get(handles.fittype,'SelectedObject'),'Tag');
data_order = get(get(handles.data_order,'SelectedObject'),'Tag');
% single_fit = get(handles.single_fit,'Value');
number_cpus = str2num(get(handles.number_cpus,'String')); %#ok<ST2NM>
neuroecon = get(handles.neuroecon,'Value');
email = get(handles.email_box,'String');
output_basename = get(handles.output_basename,'String');
odd_echoes = get(handles.odd_echoes, 'Value');
rsquared_threshold = str2num(get(handles.rsquared_threshold, 'String')); %#ok<ST2NM>
tr = str2num(get(handles.tr, 'String')); %#ok<ST2NM>

delete(handles.figure1);
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
calculateMap(file_list,parameter_list,fit_type,odd_echoes,rsquared_threshold, number_cpus, neuroecon, output_basename,data_order,tr, email);
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
  
elseif ~isempty(strfind(fit_type, 'NA'));

	set(handles.output_basename,'String','T1_map');
   
     
	if ~isempty(strfind(fit_type,'fa')) || ~isempty(strfind(fit_type,'ti_exponential'))
		set(handles.tr,'Enable','on')
	else
		set(handles.tr,'Enable','off')
    end
else
    %User input edit as needed.
    set(handles.output_basename,'String','');
     handles.file_list(batch_selected).output_basename = set(handles.output_basename,'String');
    set(handles.tr,'Enable','off');
    
end

handles.file_list(batch_selected).tr = '';
handles.file_list(batch_selected).output_basename = get(handles.output_basename, 'String');

% Update handles structure
guidata(hObject, handles);



function rsquared_threshold_Callback(hObject, eventdata, handles)
% hObject    handle to rsquared_threshold (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of rsquared_threshold as text
%        str2double(get(hObject,'String')) returns contents of rsquared_threshold as a double

set(handles.r2slider, 'Value', str2double(get(hObject,'String')));

% Get Selected Dataset
batch_selected = get(handles.batch_set,'Value');

handles.file_list(batch_selected).rsquared = str2double(get(hObject,'String'));


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



function tr_Callback(hObject, eventdata, handles)
% hObject    handle to tr (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of tr as text
%        str2double(get(hObject,'String')) returns contents of tr as a double

% Get Selected Dataset
batch_selected = get(handles.batch_set,'Value');

handles.file_list(batch_selected).tr =  str2num(get(hObject,'String'));


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
        
        cur_batch = get(hObject,'Value');
        
        list = handles.file_list(cur_batch).filelist;
        
        set(handles.filename_box,'String',list, 'Value',1);
        
        set(handles.output_basename,'String',handles.file_list(cur_batch).output_basename);
        
        set(handles.tr,'Enable',handles.file_list(cur_batch).tr);
 
        guidata(hObject, handles);
        
        set(handles.dataset_num, 'String', num2str(cur_batch));



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
        % Add a dataset
        list = get(handles.batch_set,'String');
        % Add selected files to batchbox
        if strcmp(list,'No Datasets')
            handles.datasets = handles.datasets +1;
            
            list = ['Dataset ' num2str(handles.datasets)];
            handles.file_list(handles.datasets).filelist = {};
             set(handles.dataset_num, 'String', num2str(1));
        else
            handles.datasets = handles.datasets +1;
            list = [list;  ['Dataset ' num2str(handles.datasets)]];
            handles.file_list(handles.datasets).filelist = {};
        end
        
        set(handles.batch_set,'String',list, 'Value',1);
        set(handles.batch_total, 'String', num2str(handles.datasets), 'Value', 1);
       
        cur_batch = handles.datasets;
        handles.file_list(cur_batch).output_basename = '';
        handles.file_list(cur_batch).tr = 'off';
        handles.file_list(cur_batch).rsquared = handles.rsquared_threshold;
        handles.file_list(cur_btach).curslice = handles.slice_num;
        
        
        
        guidata(hObject, handles);



% --- Executes on button press in remove_batch.
function remove_batch_Callback(hObject, eventdata, handles)
% hObject    handle to remove_batch (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

index_selected = get(handles.batch_set,'Value');
list = get(handles.batch_set,'String');

 list(end,:) = [];
 handles.file_list(index_selected) = [];

set(handles.batch_set,'String',list, 'Value',1)

handles.datasets = handles.datasets - 1;
set(handles.batch_total, 'String', num2str(handles.datasets), 'Value', 1);

set(handles.dataset_num, 'String', 'Reselect Dataset');

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

set(handles.slice_slider, 'Value', str2double(get(hObject,'String')));


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

slice_slide = get(hObject,'Value');

set(handles.slice_num, 'String', num2str(slice_slide));


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
