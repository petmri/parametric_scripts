% Read JOB_struct to repopulate GUI

function handles = update_handles(handles, JOB_struct)

email       = JOB_struct(1).email;
batch_data   = JOB_struct(1).batch_data;
save_log    = JOB_struct(1).save_log;
email_log   = JOB_struct(1).email_log;
batch_log=JOB_struct(1).batch_log;
current_dir = JOB_struct(1).current_dir;
log_name    = JOB_struct(1).log_name;
save_txt    = JOB_struct(1).save_txt;

%Set handles to reflect the JOB_struct

handles.batch_data = batch_data;
set(handles.email_box, 'String', email);
set(handles.save_log, 'Value', save_log);
set(handles.email_log,'Value', email_log);
set(handles.batch_log, 'Value', batch_log);
set(handles.save_txt, 'Value', save_txt);
set(handles.log_name, 'String', log_name);
set(handles.current_dir, 'String', current_dir);

%Update Dataset list
handles.datasets = numel(batch_data);

if numel(batch_data) > 0
    list = '';
    for i = 1:numel(batch_data)
        
        if i > 9 
        list = [list;  ['Dataset ' num2str(i)]];
        else
            list = [list;  ['Dataset  ' num2str(i)]]; 
        end
        
        if numel(batch_data) > 1
            curfilelist = batch_data(1);
        else
            curfilelist = batch_data;
        end
    end
    
    set(handles.batch_set,'String',list, 'Value',1);
    set(handles.filename_box, 'String', curfilelist.file_list);
    set(handles.batch_total, 'String', num2str(handles.datasets), 'Value', 1);
    
    set(get(handles.fit_type,'SelectedObject'),'Value', 0);
    set(get(handles.data_order, 'SelectedObject'), 'Value', 0);

    if ~isempty(curfilelist.fit_type)
    eval(['set(handles.' curfilelist.fit_type ', ''Value'', 1)']);
    end
    if ~isempty(curfilelist.data_order)
    eval(['set(handles.' curfilelist.data_order ', ''Value'', 1)']);
    end
    %set(handles.data_order, 'SelectedObject', curfilelist.data_order);
    %set(handles.fit_type, 'SelectedObject', curfilelist.fit_type);
    set(handles.te_box, 'String', curfilelist.parameters);
    set(handles.output_basename, 'String', curfilelist.output_basename);
    set(handles.rsquared_threshold, 'String', curfilelist.rsquared);
    set(handles.tr, 'String', curfilelist.tr);
    set(handles.odd_echoes, 'Value', curfilelist.odd_echoes);
else
    % Reset if no datasets present
    set(handles.batch_set,'String','', 'Value',0);
    set(handles.filename_box, 'String', '', 'Value', 0);
    set(handles.batch_total, 'String', num2str(handles.datasets), 'Value', 1);
    
    set(get(handles.fit_type,'SelectedObject'),'Value', 0);
    set(get(handles.data_order, 'SelectedObject'), 'Value', 0);
    
    %set(handles.data_order, 'SelectedObject', curfilelist.data_order);
    %set(handles.fit_type, 'SelectedObject', curfilelist.fit_type);
    set(handles.te_box, 'String', '');
    set(handles.output_basename, 'String', '');
    set(handles.rsquared_threshold, 'String', '');
    set(handles.tr, 'String', '');
    set(handles.odd_echoes, 'Value',0);
end
