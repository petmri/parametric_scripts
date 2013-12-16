% Update the handles structure after button press

function handles = update_parameters(handles, cur_batch)

handles.file_list(cur_batch).data_order = get(get(handles.data_order,'SelectedObject'),'Tag');
handles.file_list(cur_batch).fittype    = get(get(handles.fittype,'SelectedObject'),'Tag');
handles.file_list(cur_batch).parameter  = get(handles.te_box, 'String');
handles.file_list(cur_batch).output_basename = get(handles.output_basename, 'String');
handles.file_list(cur_batch).rsquared = str2num(get(handles.rsquared_threshold, 'String'));
handles.file_list(cur_batch).tr = str2num(get(handles.tr, 'String'));
handles.file_list(cur_batch).curslice = str2num(get(handles.slice_num, 'String'));
handles.file_list(handles.datasets).odd_echoes = get(handles.odd_echoes, 'Value');
