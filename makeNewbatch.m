% Create a dataset object and return

function handles = makeNewbatch(handles)

% Add a dataset
list = get(handles.batch_set,'String');
% Add selected files to batchbox
if strcmp(list,'No Datasets')
    handles.datasets = handles.datasets +1;
    
    list = ['Dataset  ' num2str(handles.datasets)];
    
    set(handles.selected_dataset, 'String', num2str(1));
else
    handles.datasets = handles.datasets +1;
    
    if handles.datasets >9
        list = [list;  ['Dataset ' num2str(handles.datasets)]];
    else
        list = [list;  ['Dataset  ' num2str(handles.datasets)]];
        
    end
end

%Global Values
set(handles.batch_set,'String',list, 'Value',handles.datasets);
set(handles.batch_total, 'String', num2str(handles.datasets), 'Value', 1);

%Batch Specific Values
cur_batch = handles.datasets;
handles.batch_data(cur_batch).curslice = str2num(get(handles.slice_num, 'String'));
handles.batch_data(cur_batch).data_order= '';
handles.batch_data(cur_batch).file_list = {};
handles.batch_data(cur_batch).fit_type = '';
handles.batch_data(cur_batch).odd_echoes = get(handles.odd_echoes, 'Value');
handles.batch_data(cur_batch).output_basename = '';
handles.batch_data(cur_batch).parameters  = str2num(get(handles.te_box, 'String'));
handles.batch_data(cur_batch).rsquared = str2num(get(handles.rsquared_threshold, 'String'));
handles.batch_data(cur_batch).tr = str2num(get(handles.tr, 'String'));
handles.batch_data(cur_batch).xy_smooth_size = str2num(get(handles.smooth_size, 'String'));
handles.batch_data(cur_batch).preview_image = [];

handles = load_batch(handles);

