%Wrapper function for calculateMap

function [single_IMG, submit, dataset_num, errormsg] = calculateMap_batch(JOB_struct, submit, dataset_num)

%Initialize error checks
errormsg = '';
errorlog = '';

if submit
    % Lodging a batch job
    file_list  = JOB_struct(1).file_list;
    current_dir= JOB_struct(1).current_dir;
    log_name   = JOB_struct(1).log_name;
    
    for i = 1:numel(file_list)
        
        % Check if the relevant dataset is to be made
        to_do = file_list(i).to_do;
        
        if to_do
            CUR_JOB    = JOB_struct;
            CUR_JOB(1).file_list = {};
            CUR_JOB(1).file_list(1) = file_list(i);
            CUR_JOB(1).submit    = 1;      
            [single_IMG, errormsg_ind, CUR_JOB] = calculateMap(CUR_JOB);
            
            if ~isempty(single_IMG) && ~isempty(errormsg)
                % Map was made properly, so we update the batch data
                % structure log to reflect this             
                cur_file_list = CUR_JOB(1).file_list;
           
                file_list(i) = cur_file_list;
                JOB_struct(1).file_list = file_list;
                save(fullfile(current_dir, log_name), 'JOB_struct', '-mat');
            else
            errormsg(i).msg = errormsg_ind;
            end
               
        else
        end
    end
    
    % The batch job has completed. Now we check for log saves  
    
    % Need to think about logging behavior
    
    %% Email the user that the map has ended.
    
    % if ~isempty(email)
%     % Email the person on completion
%     % Define these variables appropriately:
%     mail = 'immune.caltech@gmail.com'; %Your GMail email address
%     password = 'antibody'; %Your GMail password
%     % Then this code will set up the preferences properly:
%     setpref('Internet','E_mail',mail);
%     setpref('Internet','SMTP_Server','smtp.gmail.com');
%     setpref('Internet','SMTP_Username',mail);
%     setpref('Internet','SMTP_Password',password);
%     props = java.lang.System.getProperties;
%     props.setProperty('mail.smtp.auth','true');
%     props.setProperty('mail.smtp.socketFactory.class', 'javax.net.ssl.SSLSocketFactory');
%     props.setProperty('mail.smtp.socketFactory.port','465');
%     
%     hostname = char( getHostName( java.net.InetAddress.getLocalHost ) );
%     
%     sendmail(email,'MRI map processing completed',['Hello! Your Map Calc job on '...
%         ,hostname,' is done! compution time was ',datestr(datenum(0,0,0,0,0,total_time),'HH:MM:SS')]);
% end
    
else
    %Checking a particular Map
    
    CUR_JOB    = JOB_struct;
    file_list  = JOB_struct(1).file_list;
    CUR_JOB(1).file_list = file_list(dataset_num);
    CUR_JOB(1).submit    = 0;
    [single_IMG, errormsg] = calculateMap(CUR_JOB);
    
end



