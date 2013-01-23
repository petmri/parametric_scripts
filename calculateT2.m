
function calculateT2(file_list,te_list,fit_type,number_cpus,neuroecon,email)

% INPUTS
%------------------------------------
% file_list = {'file1';'file2'};
%                     % must point to valid nifti files
% te_list = [10.5 21 31.5 42 52.5 63]';
%                     % units of ms
% fit_type = 'linear_weighted'; 
%                     % options{'none','linear_simple','linear_weighted','exponential','linear_fast'}
% number_cpus = 4;    % not used if running on neuroecon
% neuroecon = 0;      % boolean
% email = srsbarnes@gmail.com;
%                     % Email will be sent to this address on job completion
%------------------------------------

% Sanity check on input
if nargin < 5
    warning( 'Arguments missing' );
    return;
end
if nargin < 6
    email = '';
end
ok_ = isfinite(te_list) & ~isnan(te_list);
if ~all( ok_ ) || isempty(te_list)
	warning( 'TE contains invalid values' );
    disp(te_list);
    return;
end
for m=size(file_list,1):-1:1
    testfile=cell2mat(file_list(m));
    if ~exist(testfile, 'file')
      % File does not exist.
      warning( 'File does not exist' );
      disp(testfile);
      return;
    end
    for n=(m-1):-1:1
        comparefile=file_list(n);
        if strcmp(testfile,comparefile)
            disp( 'Removing duplicates' );
            disp(comparefile);
            file_list(m)=[];
        end
    end
end

% fit_type = 'none';
disp(['Starting execution at ', datestr(now,'mmmm dd, yyyy HH:MM:SS')])
disp('User selected files: ');
disp(file_list);
disp('User slected TE: ');
disp(te_list);
disp('User slected fit: ');
disp(fit_type);
disp('User slected CPUs: ');
disp(number_cpus);
disp('User slected Neuroecon: ');
disp(neuroecon);
disp('User slected email: ');
disp(email);
% return;

% Create parallel processing pool
if ~neuroecon
    matlabpool('local', number_cpus);
end

execution_time = zeros(size(file_list,1));

% For each file in list do processing
for n=1:size(file_list,1)
    tic %start timer
    imagefile=cell2mat(file_list(n));
    
	% Read file and get header information
    [file_path, filename]  = fileparts(imagefile);
    nii = load_nii(imagefile);
    res = nii.hdr.dime.pixdim;
    res = res(2:4);
    image_3d = nii.img;
    [dim_x, dim_y, dim_zte] = size(image_3d);
    dim_te = size(te_list,1);
    dim_z = dim_zte / dim_te;

    % Reshape image to extract individual decay curves
    % shaped to be four dimensional with dimensions [x,y,z,te]
    shaped_image = reshape(image_3d,dim_x,dim_y,dim_te,dim_z);
    % **************
    %     shaped_image = shaped_image(:,:,:,1);
    %     dim_z = 1;
    % **************
    shaped_image = permute(shaped_image,[1,2,4,3]);


    % Run Fitting Algorithms
    if(neuroecon)
        %Schedule object, neuroecon
        sched = findResource('scheduler', 'configuration', 'NeuroEcon.local');
        set(sched, 'SubmitArguments', '-l walltime=12:00:00 -m abe -M thomasn@caltech.edu')

        warning off; %#ok<WNOFF>

        p = pwd;
%         n = '/home/thomasn/scripts/niftitools';

        job = createMatlabPoolJob(sched, 'configuration', 'NeuroEcon.local','PathDependencies', {p});
        set(job, 'MaximumNumberOfWorkers', 20);
        set(job, 'MinimumNumberOfWorkers', 1);
        createTask(job, @parallelFit, 1,{te_list,fit_type,shaped_image});

        submit(job)
        waitForState(job)
        results = getAllOutputArguments(job);
        destroy(job);

        fit_output = cell2mat(results);
    else
        fit_output = parallelFit(te_list,fit_type,shaped_image);
    end

    % Collect and reshpae outputs
    t2_fit					 = fit_output(:,1);
    rho_fit					 = fit_output(:,2);
    r_squared				 = fit_output(:,3);
    confidence_interval_low	 = fit_output(:,4);
    confidence_interval_high = fit_output(:,5);

    t2_fit					= reshape(t2_fit, [dim_x, dim_y, dim_z]);
    rho_fit					= reshape(rho_fit,  [dim_x, dim_y, dim_z]); %#ok<NASGU>
    r_squared				= reshape(r_squared, [dim_x, dim_y, dim_z]);
    confidence_interval_low  = reshape(confidence_interval_low, [dim_x, dim_y, dim_z]);
    confidence_interval_high = reshape(confidence_interval_high, [dim_x, dim_y, dim_z]);

    % Create output names
    fullpathT2 = fullfile(file_path, ['T2star_map_', fit_type,'_', filename,'.nii']);
    fullpathRsquared   = fullfile(file_path, ['Rsquared_', fit_type,'_', filename ...
        , '.nii']);
    fullpathCILow   = fullfile(file_path, ['CI_low_', fit_type,'_', filename ...
        , '.nii']);
    fullpathCIHigh   = fullfile(file_path, ['CI_high_', fit_type,'_', filename ...
        , '.nii']);

    % Write output
    T2dirnii = make_nii(t2_fit, res, [1 1 1], [], 'T2 Values');
    Rsquareddirnii   = make_nii(r_squared, res, [1 1 1], [], 'R Squared of fit');
    save_nii(T2dirnii, fullpathT2);
    save_nii(Rsquareddirnii, fullpathRsquared);
    % Linear_fast does not calculate confidence intervals
    if ~strcmp(fit_type,'linear_fast')
        CILowdirnii  = make_nii(confidence_interval_low, res, [1 1 1], [], 'Low 95% confidence interval');
        CIHighdirnii  = make_nii(confidence_interval_high, res, [1 1 1], [], 'High 95% confidence interval');
        save_nii(CILowdirnii, fullpathCILow);
        save_nii(CIHighdirnii, fullpathCIHigh);
    end
    
    execution_time(n) = toc;
    
    disp(['Map completed at ', datestr(now,'mmmm dd, yyyy HH:MM:SS')])
    disp(['Execution time was: ',datestr(datenum(0,0,0,0,0,execution_time(n)),'HH:MM:SS')]);
    disp('Map saved to: ');
    disp(fullpathT2);
end

% Close parallel processing pool
if ~neuroecon
    matlabpool close;
end

if ~isempty(email)
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

    sendmail(email,'T2 star map processing completed',['Hello! Your T2 Calc job is done! ' ...
        'compution time was ',num2str(execution_time)]);
end

disp(['All processing complete at ', datestr(now,'mmmm dd, yyyy HH:MM:SS')])
total_time = sum(execution_time);
disp(['Total execution time was: ',datestr(datenum(0,0,0,0,0,total_time(n)),'HH:MM:SS')]);
