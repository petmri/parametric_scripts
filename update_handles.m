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
