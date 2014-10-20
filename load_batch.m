%Load the selected batch so it can be editted/updated

function handles = load_batch(handles)

selected_name = get(handles.batch_set,'String');
if strcmp(selected_name,'No Datasets')
    return
end
    
batch_selected = get(handles.batch_set,'Value');
list = handles.batch_data(batch_selected).file_list;
roi_list = handles.batch_data(batch_selected).roi_list;

%Remove the directory path to allow nice visualization
list = visualize_list(list);
roi_list = visualize_list(roi_list);

%handles.batch_data(cur_batch)

% Reset radiobuttons
set(get(handles.fit_type,'SelectedObject'),'Value', 0);
set(get(handles.data_order, 'SelectedObject'), 'Value', 0);
set(handles.te_box, 'String', '');
set(handles.tr, 'String', '');
set(handles.smooth_size, 'String', '');
set(handles.odd_echoes, 'Value', 0);
set(handles.output_basename,'String','');
set(handles.rsquared_threshold,  'String' ,num2str(0.6));
set(handles.filename_box,'String','No Files', 'Value',1);
handles = visualize_R2(handles);

% Set radiobuttons
set(handles.filename_box,'String',list, 'Value',1);
set(handles.roi_box,'String',roi_list, 'Value',1);
handles.batch_data(batch_selected).fit_type;
if ~isempty(handles.batch_data(batch_selected).fit_type)
    eval(['set(handles.' handles.batch_data(batch_selected).fit_type ', ''Value'', 1)']);
end
if ~isempty(handles.batch_data(batch_selected).data_order)
    eval(['set(handles.' handles.batch_data(batch_selected).data_order ', ''Value'', 1)']);
end
set(handles.output_basename,'String',handles.batch_data(batch_selected).output_basename);
set(handles.te_box, 'String', num2str(handles.batch_data(batch_selected).parameters));
set(handles.tr,'String',handles.batch_data(batch_selected).tr);
set(handles.smooth_size,'String',handles.batch_data(batch_selected).xy_smooth_size);
set(handles.odd_echoes, 'Value', handles.batch_data(batch_selected).odd_echoes);
set(handles.rsquared_threshold,  'String' ,num2str(handles.batch_data(batch_selected).rsquared));
handles = visualize_R2(handles);

set(handles.selected_dataset, 'String', num2str(batch_selected));

[errormsg] = quick_check(handles);
handles = disp_error(errormsg, handles);

% Update handles structure
% handles = update_parameters(handles, batch_selected);
