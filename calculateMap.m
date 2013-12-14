
function [single_IMG, errormsg] = calculateMap(JOB_struct);

% Initialize empty variables
single_IMG = '';
errormsg   = '';

% Sanity check on input
if nargin < 1
    warning( 'Arguments missing' );
    return;
end

% Extract parameters

 number_cps     = JOB_struct(1).number_cpus;
 neuroecon      = JOB_struct(1).neuroecon;
 email          = JOB_struct(1).email;
 cur_dataset    = JOB_struct(1).file_list;
 save_log       = JOB_struct(1).save_log;
 email_log      = JOB_struct(1).email_log;
 separate_logs  = JOB_struct(1).separate_logs;
 current_dir    = JOB_struct(1).current_dir;
 log_name       = JOB_struct(1).log_name;
 submit         = JOB_struct(1).submit;

% Extract INPUTS

file_list           = cur_dataset.file_list;
parameter_list      = cur_dataset.parameters;
fit_type            = cur_dataset.fit_type;
odd_echoes          = cur_dataset.odd_echoes;
rsquared_threshold  = cur_dataset.rsquared;
tr                  = cur_dataset.tr;

%------------------------------------
% file_list = {'file1';'file2'};
% 					% must point to valid nifti files
% parameter_list = [10.5 21 31.5 42 52.5 63]';
% 					% units of ms or degrees
% fit_type = 'linear_weighted'; 
% 					% options{'none','t2_linear_simple','t2_linear_weighted','t2_exponential','t2_linear_fast'
% 					%			't1_tr_fit','t1_fa_fit','t1_fa_linear_fit','t1_ti_exponential_fit'}
% odd_echoes = 0;	% boolean, if selected only odd parameters will be
% 					% used for fit
% rsquared_threshold = 0.2;
% 					% all fits with R^2 less than this set to -1
% number_cpus = 4;	% not used if running on neuroecon
% neuroecon = 0;	% boolean
% output_basename = 'foo';
% 					% base of output filename
% data_order = 'xyzn';% in what order is the data organized
% 					% options{'xynz','xyzn','xyzfile'}
% tr = 20;			% units ms, only used for T1 FA fitting
% submit            % Let's the function know if this is a tester job of
%                     actual file generation

%------------------------------------



ok_ = isfinite(parameter_list) & ~isnan(parameter_list);
if ~all( ok_ ) || isempty(parameter_list)
	warning( 'TE/TR/FA/TI list contains invalid values' );
    disp(parameter_list);
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

if submit
% fit_type = 'none';
disp(['Starting execution at ', datestr(now,'mmmm dd, yyyy HH:MM:SS')])
disp('User selected files: ');
disp(file_list);
disp('User selected TE/TR/FA/TI: ');
disp(parameter_list);
disp('User selected fit: ');
disp(fit_type);
disp('User selected CPUs: ');
disp(number_cpus);
disp('User selected Neuroecon: ');
disp(neuroecon);
disp('User selected email: ');
disp(email);
disp('User selected data order: ');
disp(data_order);
disp('User selected output basename: ');
disp(output_basename);
disp('User selected only odd echoes: ');
disp(odd_echoes);
if ~isempty(strfind(fit_type,'t1')) && ~isempty(strfind(fit_type,'fa'))
	disp('User selected tr: ');
	disp(tr);
end
end
disp('User selected r^2 threshold: ');
disp(rsquared_threshold);


% return;

% Calculate number of fits
dim_n = size(parameter_list,1);
if strcmp(data_order,'xyzfile')
	number_of_fits = size(file_list,1)/dim_n;
	if rem(size(file_list,1),dim_n)~=0
        warning on
		errormsg = warning( 'Number of files not evenly divisible by number or parameters' );
		return;
	end
else
	number_of_fits = size(file_list,1);
end

% Create parallel processing pool
if ~neuroecon && exist('matlabpool') && submit
    s = matlabpool('size');   
    if s
        matlabpool close 
    end
    matlabpool('local', number_cpus);
end

execution_time = zeros(size(file_list,1),1);

% do processing
for n=1:number_of_fits
    tic %start timer   
    
	% Read only one file then process it
	if ~strcmp(data_order,'xyzfile')
		imagefile=cell2mat(file_list(n));
		
		% Read file and get header information
		[file_path, filename]  = fileparts(imagefile);
% 		nii = load_nii(imagefile);
		nii = load_untouch_nii(imagefile);
		res = nii.hdr.dime.pixdim;
		res = res(2:4);
		image_3d = nii.img;
		[dim_x, dim_y, dim_zn] = size(image_3d);
% 		dim_n = size(parameter_list,1);
		dim_z = dim_zn / dim_n;

		% Reshape image to extract individual decay curves
		% shaped to be four dimensional with dimensions [x,y,z,te]
		if strcmp(data_order,'xynz')
			shaped_image = reshape(image_3d,dim_x,dim_y,dim_n,dim_z);
			shaped_image = permute(shaped_image,[1,2,4,3]);
		elseif strcmp(data_order,'xyzn')
			shaped_image = reshape(image_3d,dim_x,dim_y,dim_z,dim_n);
% 			shaped_image = permute(shaped_image,[1,2,4,3]);
        else
            warning on
			warning( 'Unknown data order' );
            errormsg = warning( 'Number of files not evenly divisible by number or parameters' );
			return;
		end
	% Read all files as all are needed for fit
	else
		% For each file in list load and add to larger matrix
		for m=1:dim_n
			imagefile=cell2mat(file_list(m+(n-1)*dim_n));

			% Read file and get header information
			[file_path, filename]  = fileparts(imagefile);
% 			nii = load_nii(imagefile);
			nii = load_untouch_nii(imagefile);
			res = nii.hdr.dime.pixdim;
			res = res(2:4);
			image_3d = nii.img;
			[dim_x, dim_y, dim_z] = size(image_3d);
			dim_n = size(parameter_list,1);

			if m==1
				shaped_image = zeros([dim_x dim_y dim_z dim_n]);
			end
			shaped_image(:,:,:,m) = image_3d;
		end
	end
	
	
	% Remove even echoes if requested
	if odd_echoes
		dim_n = floor((dim_n+1)/2);
		temp_image = zeros(dim_x,dim_y,dim_z,dim_n);
		temp_n = zeros(dim_n,1);
		for m=1:dim_n
			temp_image(:,:,:,m) = shaped_image(:,:,:,1+2*(m-1));
			temp_n(m) = parameter_list(1+2*(m-1));
		end
		shaped_image = temp_image;
		parameter_list = temp_n;
    end
    
    % Change fittype to linear if needed for visualization
    if ~submit
        
        if ~isempty(strfind(fit_type,'t2'))
            fit_type = 't2_linear_fast';
        elseif ~isempty(strfind(fit_type,'t1_fa'))
            fit_type = 't1_fa_linear_fit';
        elseif ~isempty(strfind(fit_type, 'ADC'))
            fit_type = 'ADC_linear_simple';
        else
            % EDIT NEEDED. 
            % Currently, no preview available for other types of fitting
        end
    end
            
        


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
        createTask(job, @parallelFit, 1,{parameter_list,fit_type,shaped_image,tr});

        submit(job)
        waitForState(job)
        results = getAllOutputArguments(job);
        destroy(job);

        fit_output = cell2mat(results);
    else
        fit_output = parallelFit(parameter_list,fit_type,shaped_image,tr);
    end

    % Collect and reshape outputs
    exponential_fit			 = fit_output(:,1);
    rho_fit					 = fit_output(:,2);
    r_squared				 = fit_output(:,3);
    confidence_interval_low	 = fit_output(:,4);
    confidence_interval_high = fit_output(:,5);
	
	% Throw out bad results
	for m=1:size(exponential_fit) 
		if(r_squared(m) < rsquared_threshold && exponential_fit(m)~=-2)
			rho_fit(m) = -1;
			exponential_fit(m) = -1;
			confidence_interval_low(m) = -1;
			confidence_interval_high(m) = -1;
		end
	end
	
    exponential_fit			= reshape(exponential_fit, [dim_x, dim_y, dim_z]);
    rho_fit					= reshape(rho_fit,  [dim_x, dim_y, dim_z]); %#ok<NASGU>
    r_squared				= reshape(r_squared, [dim_x, dim_y, dim_z]);
    confidence_interval_low  = reshape(confidence_interval_low, [dim_x, dim_y, dim_z]);
    confidence_interval_high = reshape(confidence_interval_high, [dim_x, dim_y, dim_z]);

if submit

    % Create output names
    fullpathT2 = fullfile(file_path, [output_basename, '_', fit_type,'_', filename ...
        ,'.nii']);
    fullpathRsquared   = fullfile(file_path, ['Rsquared_', fit_type,'_', filename ...
        , '.nii']);
    fullpathCILow   = fullfile(file_path, ['CI_low_', fit_type,'_', filename ...
        , '.nii']);
    fullpathCIHigh   = fullfile(file_path, ['CI_high_', fit_type,'_', filename ...
        , '.nii']);

    % Write output
    T2dirnii = make_nii(exponential_fit, res, [1 1 1], [], fit_type);
    Rsquareddirnii   = make_nii(r_squared, res, [1 1 1], [], 'R Squared of fit');
    save_nii(T2dirnii, fullpathT2);
    save_nii(Rsquareddirnii, fullpathRsquared);
    % Linear_fast does not calculate confidence intervals
    if ~strcmp(fit_type,'t2_linear_fast') && ~strcmp(fit_type,'t1_fa_linear_fit')
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
    
    number_cps, neuroecon, separate_logs, log_name, cur_dataset, submit
    
    if separate_logs
        log_name = strrep(fullpathT2, 'nii', 'log');
        save(log_name, 'cur_dataset'
        
    
    single_IMG = 1;
else
    % Process R2 map for quick visualization
    single_IMG = r_squared;
end
    
end

% Close parallel processing pool
if ~neuroecon && exist('matlabpool') && submit
    matlabpool close;
end

total_time = sum(execution_time);

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

	hostname = char( getHostName( java.net.InetAddress.getLocalHost ) );
	
    sendmail(email,'MRI map processing completed',['Hello! Your Map Calc job on '...
		,hostname,' is done! compution time was ',datestr(datenum(0,0,0,0,0,total_time),'HH:MM:SS')]);
end

disp(['All processing complete at ', datestr(now,'mmmm dd, yyyy HH:MM:SS')])
disp(['Total execution time was: ',datestr(datenum(0,0,0,0,0,total_time),'HH:MM:SS')]);
