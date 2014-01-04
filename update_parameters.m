% Update the handles structure after button press

function handles = update_parameters(handles, cur_batch)

handles.batch_data(cur_batch).curslice = str2num(get(handles.slice_num, 'String'));
handles.batch_data(cur_batch).data_order = get(get(handles.data_order,'SelectedObject'),'Tag');
handles.batch_data(cur_batch).fit_type    = get(get(handles.fit_type,'SelectedObject'),'Tag');
handles.batch_data(cur_batch).odd_echoes = get(handles.odd_echoes, 'Value');
handles.batch_data(cur_batch).output_basename = get(handles.output_basename, 'String');
handles.batch_data(cur_batch).parameter  = get(handles.te_box, 'String');
handles.batch_data(cur_batch).rsquared = str2num(get(handles.rsquared_threshold, 'String'));
handles.batch_data(cur_batch).tr = str2num(get(handles.tr, 'String'));




