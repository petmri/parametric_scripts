% Read JOB_struct to repopulate GUI

function handles = update_handles(handles, JOB_struct);

email       = JOB_struct(1).email;
file_list   = JOB_struct(1).file_list;
save_log    = JOB_struct(1).save_log;
email_log   = JOB_struct(1).email_log;
separate_logs=JOB_struct(1).separate_logs;
current_dir = JOB_struct(1).current_dir;
log_name    = JOB_struct(1).log_name;
save_txt    = JOB_struct(1).save_txt;

%Set handles to reflect the JOB_struct

handles.file_list = file_list;
set(handles.email_box, 'String', email);
set(handles.save_log, 'Value', save_log);
set(handles.email_log,'Value', email_log);
set(handles.separate_logs, 'Value', separate_logs);
set(handles.save_txt, 'Value', save_txt);
set(handles.log_name, 'String', log_name);
set(handles.current_dir, 'String', current_dir);

%Update Dataset list
handles.datasets = numel(file_list);

if numel(file_list) > 0
    list = '';
    for i = 1:numel(file_list)
        list = [list;  ['Dataset ' num2str(i)]];
        
        if numel(file_list) > 1
            curfilelist = file_list(1);
        else
            curfilelist = file_list;
        end
    end
    
    set(handles.batch_set,'String',list, 'Value',1);
    set(handles.filename_box, 'String', curfilelist.file_list);
    set(handles.batch_total, 'String', num2str(handles.datasets), 'Value', 1);
    
    set(get(handles.fittype,'SelectedObject'),'Value', 0);
    set(get(handles.data_order, 'SelectedObject'), 'Value', 0);

    if ~isempty(curfilelist.fittype)
    eval(['set(handles.' curfilelist.fittype ', ''Value'', 1)']);
    end
    if ~isempty(curfilelist.data_order)
    eval(['set(handles.' curfilelist.data_order ', ''Value'', 1)']);
    end
    %set(handles.data_order, 'SelectedObject', curfilelist.data_order);
    %set(handles.fittype, 'SelectedObject', curfilelist.fittype);
    set(handles.te_box, 'String', curfilelist.parameter);
    set(handles.output_basename, 'String', curfilelist.output_basename);
    set(handles.rsquared_threshold, 'String', curfilelist.rsquared);
    set(handles.tr, 'String', curfilelist.tr);
    set(handles.odd_echoes, 'Value', curfilelist.odd_echoes);
else
    % Reset if no datasets present
    set(handles.batch_set,'String','', 'Value',0);
    set(handles.filename_box, 'String', '', 'Value', 0);
    set(handles.batch_total, 'String', num2str(handles.datasets), 'Value', 1);
    
    set(get(handles.fittype,'SelectedObject'),'Value', 0);
    set(get(handles.data_order, 'SelectedObject'), 'Value', 0);
    
    %set(handles.data_order, 'SelectedObject', curfilelist.data_order);
    %set(handles.fittype, 'SelectedObject', curfilelist.fittype);
    set(handles.te_box, 'String', '');
    set(handles.output_basename, 'String', '');
    set(handles.rsquared_threshold, 'String', '');
    set(handles.tr, 'String', '');
    set(handles.odd_echoes, 'Value',0);
end
