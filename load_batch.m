%Load the selected batch so it can be editted/updated

function handles = load_batch(handles)

%cur_batch = get(hObject,'Value');
batch_selected = get(handles.batch_set,'Value');
list = handles.batch_data(batch_selected).file_list;

%Remove the directory path to allow nice visualization
list = visualize_list(list);

%handles.batch_data(cur_batch)

% Reset radiobuttons
set(get(handles.fit_type,'SelectedObject'),'Value', 0);
set(get(handles.data_order, 'SelectedObject'), 'Value', 0);
set(handles.te_box, 'String', '');
set(handles.tr, 'String', '');
set(handles.odd_echoes, 'Value', 0);
set(handles.output_basename,'String','');
set(handles.rsquared_threshold,  'String' ,num2str(0.6));
set(handles.filename_box,'String','No Files', 'Value',1);
handles = visualize_R2(handles);

if ~isempty(list)
    % Set radiobuttons
	set(handles.filename_box,'String',list, 'Value',1);
    handles.batch_data(batch_selected).fit_type
    disp('batch select')
    if ~isempty(handles.batch_data(batch_selected).fit_type)
        eval(['set(handles.' handles.batch_data(batch_selected).fit_type ', ''Value'', 1)']);
    end
    if ~isempty(handles.batch_data(batch_selected).data_order)
        eval(['set(handles.' handles.batch_data(batch_selected).data_order ', ''Value'', 1)']);
    end
    set(handles.output_basename,'String',handles.batch_data(batch_selected).output_basename);
    set(handles.te_box, 'String', num2str(handles.batch_data(batch_selected).parameters));
    set(handles.tr,'String',handles.batch_data(batch_selected).tr);
    set(handles.odd_echoes, 'Value', handles.batch_data(batch_selected).odd_echoes);
    set(handles.rsquared_threshold,  'String' ,num2str(handles.batch_data(batch_selected).rsquared));
	handles = visualize_R2(handles);
end

set(handles.selected_dataset, 'String', num2str(batch_selected));

% Update R2
% submit = 0;
% dataset_num = batch_selected;

[errormsg] = quick_check(handles);
handles = disp_error(errormsg, handles);

% Update handles structure
handles = update_parameters(handles, batch_selected);
% JOB_struct = setup_job(handles);
% 
% if isempty(errormsg)
%     [single_IMG submit data_setnum] = calculateMap_batch(JOB_struct, submit, dataset_num);
%     
%     if ~isempty(errormsg)
%         
%         handles = disp_error(errormsg, handles);
%         
%         
%         %     elseif isempty(single_IMG)
%         %         errormsg = 'Empty image';
%         %
%         %         handles = disp_error(errormsg, handles);
%     else
%         %Display Image
%         
%         handles = visualize_R2(handles, single_IMG);
%         
%     end
% else
%     set(get(handles.fit_type,'SelectedObject'), 'Value', 0);
%     set(handles.output_basename, 'String', '');
% end