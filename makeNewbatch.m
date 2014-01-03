% Create a dataset object and return

function handles = makeNewbatch(handles)

% Add a dataset
list = get(handles.batch_set,'String');
% Add selected files to batchbox
if strcmp(list,'No Datasets')
    handles.datasets = handles.datasets +1;
    
    list = ['Dataset  ' num2str(handles.datasets)];
    
    set(handles.dataset_num, 'String', num2str(1));
else
    handles.datasets = handles.datasets +1;
    
    if handles.datasets >9
        list = [list;  ['Dataset ' num2str(handles.datasets)]];
    else
        list = [list;  ['Dataset  ' num2str(handles.datasets)]];
        
    end
end

set(handles.batch_set,'String',list, 'Value',1);
set(handles.batch_total, 'String', num2str(handles.datasets), 'Value', 1);
cur_batch = handles.datasets;
handles.file_list(cur_batch).output_basename = '';
handles.file_list(cur_batch).tr = str2num(get(handles.tr, 'String'));
handles.file_list(cur_batch).rsquared = str2num(get(handles.rsquared_threshold, 'String'));
handles.file_list(cur_batch).curslice = str2num(get(handles.slice_num, 'String'));
handles.file_list(handles.datasets).file_list = {};
handles.file_list(handles.datasets).odd_echoes = get(handles.odd_echoes, 'Value');
handles.file_list(cur_batch).fit_type = '';
handles.file_list(cur_batch).data_order= '';

