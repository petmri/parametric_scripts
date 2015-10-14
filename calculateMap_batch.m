%Wrapper function for calculateMap

function [single_IMG, submit, dataset_num, errormsg] = calculateMap_batch(JOB_struct, submit, dataset_num)
%Initialize error checks
errormsg = '';
single_IMG  = '';
errors   = 0;

if submit
    % Lodging a batch job
    batch_data  = JOB_struct(1).batch_data;
    current_dir= JOB_struct(1).current_dir;
    log_name   = JOB_struct(1).log_name;
    
    % Get preferences
    if exist('email_preferences.txt', 'file') == 2
        prefs = parse_preference_file('email_preferences.txt',0,...
            {'gmail_from_username' 'gmail_from_password'});
        gmail_from_username = prefs.gmail_from_username;
        gmail_from_password = prefs.gmail_from_password;
    else
        gmail_from_username = '';
        gmail_from_password = '';
        if JOB_struct(1).email_log
            warning('No email user/password specified in email_preferences.txt, unable to send email');
            %In case warnings are disabled
            disp('No email user/password specified in email_preferences.txt, unable to send email');
            
            JOB_struct(1).email_log = 0;
        end
    end

    % log actual done logs
    done = 0;
    new_txtname = '';
    
    for i = 1:numel(batch_data)
        % Check if the relevant dataset is to be made
        
        to_do = batch_data(i).to_do;
        
        if to_do
            CUR_JOB                 = JOB_struct;
            CUR_JOB(1).batch_data    = {};
            
            if numel(batch_data) >1
                CUR_JOB(1).batch_data = batch_data(i);
            else
                CUR_JOB(1).batch_data = batch_data;
            end
            
            CUR_JOB(1).submit       = 1;
            
            [single_IMG, errormsg_ind, CUR_JOB, new_txtname(done+1).txtname] = calculateMap(CUR_JOB, i);
             
            if single_IMG && isempty(errormsg_ind)
                % Map was made properly, so we update the batch data
                % structure log to reflect this
                cur_batch_data = CUR_JOB(1).batch_data;
                batch_data(i) = cur_batch_data;
                
                JOB_struct(1).batch_data = batch_data;
%                 save(fullfile(JOB_struct(1).current_dir, strrep(JOB_struct(1).log_name, '.log', '_log.mat')), 'JOB_struct', '-mat');
                done = done +1;
                %save(fullfile(current_dir, log_name), 'JOB_struct', '-mat');
            else
                errormsg(i).msg = errormsg_ind;
                errors = 1;
                
            end
        end
    end

    % The batch job has completed. Now we check for log saves
    if JOB_struct(1).batch_log
        if JOB_struct(1).save_txt
            % Combine txt logs
            combined_txt_name = strrep(fullfile(JOB_struct(1).current_dir, JOB_struct(1).log_name), '.log', '_log.txt');

            if done > 1
                % If more than 1 file then we have to combine with type or cat
                if ispc
                    system_file = 'type';
                end
                if isunix
                    system_file = 'cat';
                end

                for i = 1:done
                    system_file = [system_file ' '  '"' new_txtname(i).txtname '" '];

                end

                system_file = [system_file ' > ' '"' combined_txt_name '"'];

                % Run system command
                if system(system_file)
                    errormsg = 'Problem saving txt file';
                else
                    for i = 1:done
                        delete(new_txtname(i).txtname);
                    end

                end
            elseif done > 0
                movefile(new_txtname(1).txtname, combined_txt_name);
            else
                diary(combined_txt_name)
                disp('No files processed: nothing to do.');
                diary off
            end
        end

        if JOB_struct(1).save_log
            save(fullfile(JOB_struct(1).current_dir, strrep(JOB_struct(1).log_name, '.log', '_log.mat')), 'JOB_struct', '-mat');
            log_name = fullfile(JOB_struct(1).current_dir, strrep(JOB_struct(1).log_name, '.log', '_log.mat'));
        end
    end
    
    % Need to think about logging behavior
    %% Email the user that the map has ended.

    if JOB_struct(1).email_log && ~errors
        % Email the person on completion
        % from username and password set in email_preferences.txt
        setpref('Internet','E_mail',gmail_from_username);
        setpref('Internet','SMTP_Server','smtp.gmail.com');
        setpref('Internet','SMTP_Username',gmail_from_username);
        setpref('Internet','SMTP_Password',gmail_from_password);
        props = java.lang.System.getProperties;
        props.setProperty('mail.smtp.auth','true');
        props.setProperty('mail.smtp.socketFactory.class', 'javax.net.ssl.SSLSocketFactory');
        props.setProperty('mail.smtp.socketFactory.port','465');
        
        hostname = char( getHostName( java.net.InetAddress.getLocalHost ) );
        
        attachments = '';
        if JOB_struct(1).batch_log
            if JOB_struct(1).save_txt
                attachments{end+1} = combined_txt_name;
            end
            if JOB_struct(1).save_log
                attachments{end+1} = log_name;
            end
        else
            if JOB_struct(1).save_txt
                for i=1:length(new_txtname)
                    attachments{end+1} = new_txtname(i).txtname;
                end
            end
        end
        
        
        sendmail(JOB_struct(1).email,'MRI map processing completed',['Hello! Your Map Calc job on '...
            ,hostname,' is done! Logs of data and txt attached if desired'], attachments);
    end
    
else
    %Checking a particular Map
    
    CUR_JOB    = JOB_struct;
    batch_data  = JOB_struct(1).batch_data;

    if strcmp(batch_data(dataset_num).fit_type, 'user_input') || strcmp(batch_data(dataset_num).fit_type, 't1_ti_exponential_fit')
        errormsg = 'Non-linear fit; no preview';
        disp(errormsg)
    else
        CUR_JOB(1).batch_data = batch_data(dataset_num);
        CUR_JOB(1).submit    = 0;
        [single_IMG, errormsg] = calculateMap(CUR_JOB);
    end
    
end



