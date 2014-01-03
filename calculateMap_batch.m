%Wrapper function for calculateMap

function [single_IMG, submit, dataset_num, errormsg] = calculateMap_batch(JOB_struct, submit, dataset_num)
%Initialize error checks
errormsg = '';
single_IMG  = '';
errors   = 0;

if submit
    % Lodging a batch job
    file_list  = JOB_struct(1).file_list;
    current_dir= JOB_struct(1).current_dir;
    log_name   = JOB_struct(1).log_name;
    
    % log actual done logs
    done = 0;
    new_txtname = '';
    
    for i = 1:numel(file_list)
        % Check if the relevant dataset is to be made
        
        to_do = file_list(i).to_do;
        
        if to_do
            CUR_JOB                 = JOB_struct;
            CUR_JOB(1).file_list    = {};
            
            if numel(file_list) >1
                CUR_JOB(1).file_list = file_list(i);
            else
                CUR_JOB(1).file_list = file_list;
            end
            
            CUR_JOB(1).submit       = 1;
            
            [single_IMG, errormsg_ind, CUR_JOB, new_txtname(done+1).txtname] = calculateMap(CUR_JOB, i);
             
            if single_IMG & isempty(errormsg_ind)
                % Map was made properly, so we update the batch data
                % structure log to reflect this
                cur_file_list = CUR_JOB(1).file_list;
                file_list(i) = cur_file_list;
                
                JOB_struct(1).file_list = file_list;
                save(fullfile(JOB_struct(1).current_dir, strrep(JOB_struct(1).log_name, '.log', '_log.mat')), 'JOB_struct', '-mat');
                done = done +1;
                %save(fullfile(current_dir, log_name), 'JOB_struct', '-mat');
            else
                errormsg(i).msg = errormsg_ind;
                errors = 1;
                
            end
        end
    end

    % The batch job has completed. Now we check for log saves
    
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
    else
        for i = 1:done
            delete(new_txtname(i).txtname);
        end
    end
    
    if ~JOB_struct(1).separate_logs
        
        for i = 1:done
            
            if exist(new_txtname(i).txtname, 'file')
                delete(new_txtname(i).txtname);
            end
        end
    end
    
    
    if JOB_struct(1).save_log
        save(fullfile(JOB_struct(1).current_dir, strrep(JOB_struct(1).log_name, '.log', '_log.mat')), 'JOB_struct', '-mat');
        log_name = fullfile(JOB_struct(1).current_dir, strrep(JOB_struct(1).log_name, '.log', '_log.mat'));
        
    end
    
    % Need to think about logging behavior
    %% Email the user that the map has ended.

    if ~isempty(JOB_struct(1).email) && ~errors
        % Email the person on completion
        % Define these variables appropriately:
        mail = 'immune.caltech@gmail.com'; %Your GMail email address
        password = 'antibody'; %Your GMail password
        % Then this code will set up the preferences properly:
        setpref('Internet','E_mail',mail);
        setpref('Internet','SMTP_Server','smtp.gmail.com');
        setpref('Internet','SMTP_Username',mail);
        setpref('Internet','SMTP_Password',password);
        props = java.lang.System.getProperties;
        props.setProperty('mail.smtp.auth','true');
        props.setProperty('mail.smtp.socketFactory.class', 'javax.net.ssl.SSLSocketFactory');
        props.setProperty('mail.smtp.socketFactory.port','465');
        
        hostname = char( getHostName( java.net.InetAddress.getLocalHost ) );
        
        attachments = '';
        if JOB_struct(1).save_txt
            attachments{end+1} = combined_txt_name;
        end
        if JOB_struct(1).save_log
            attachments{end+1} = log_name;
        end
        
        sendmail(JOB_struct(1).email,'MRI map processing completed',['Hello! Your Map Calc job on '...
            ,hostname,' is done! Logs of data and txt attached if desired'], attachments);
    end
    
else
    %Checking a particular Map
    
    CUR_JOB    = JOB_struct;
    file_list  = JOB_struct(1).file_list;

    if strcmp(file_list(dataset_num).fit_type, 'user_input') || strcmp(file_list(dataset_num).fit_type, 't1_ti_exponential_fit')
        errormsg = 'Non-linear fit; no preview';
        disp(errormsg)
    else
        CUR_JOB(1).file_list = file_list(dataset_num);
        CUR_JOB(1).submit    = 0;
        [single_IMG, errormsg] = calculateMap(CUR_JOB);
    end
    
end



