% Setup job parameters

function JOB_struct = setup_job(handles)

 number_cpus    = str2num(get(handles.number_cpus,'String')); %#ok<ST2NM>
 neuroecon      = get(handles.neuroecon,'Value');
 email          = get(handles.email_box,'String');
 file_list      = handles.file_list;
 save_log       = get(handles.save_log, 'Value');
 email_log      = get(handles.email_log, 'Value');
 separate_logs  = get(handles.separate_logs, 'Value');
 current_dir    = get(handles.current_dir, 'String');
 log_name       = get(handles.log_name, 'String');
 
 JOB_struct(1).number_cpus = number_cpus;
 JOB_struct(1).neuroecon = neuroecon;
 JOB_struct(1).email = email;
 JOB_struct(1).file_list = file_list;
 JOB_struct(1).save_log = save_log;
 JOB_struct(1).email_log = email_log;
 JOB_struct(1).separate_logs = separate_logs;
 JOB_struct(1).current_dir = current_dir;
 JOB_struct(1).log_name = log_name;

 