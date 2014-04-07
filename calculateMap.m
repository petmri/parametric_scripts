
function [single_IMG, errormsg, JOB_struct, txtlog_output_path] = calculateMap(JOB_struct, dataset)

% Initialize empty variables
single_IMG = '';
errormsg   = '';
txtlog_output_path   = '';

% Sanity check on input
if nargin < 1
    warning( 'Arguments missing' );
    return;
end

% Extract parameters

number_cpus    = JOB_struct(1).number_cpus;
neuroecon      = JOB_struct(1).neuroecon;
email          = JOB_struct(1).email;
cur_dataset    = JOB_struct(1).batch_data;
save_log       = JOB_struct(1).save_log;
email_log      = JOB_struct(1).email_log;
batch_log      = JOB_struct(1).batch_log;
current_dir    = JOB_struct(1).current_dir;
log_name       = JOB_struct(1).log_name;
submit         = JOB_struct(1).submit;
save_txt       = JOB_struct(1).save_txt;

% Extract INPUTS

file_list           = cur_dataset.file_list;
parameter_list      = cur_dataset.parameters;
parameter_list      = parameter_list(:);
fit_type            = cur_dataset.fit_type;
odd_echoes          = cur_dataset.odd_echoes;
rsquared_threshold  = cur_dataset.rsquared;
tr                  = cur_dataset.tr;
data_order          = cur_dataset.data_order;
output_basename     = cur_dataset.output_basename;

% Add the location of the user input file if exists, else empty
if strcmp(fit_type, 'user_input')
    fit_file = cur_dataset.user_fittype_file;
    ncoeffs  = cur_dataset.ncoeffs;
    coeffs   = cur_dataset.coeffs;
    tr_present=cur_dataset.tr_present;
else
    fit_file = '';
    ncoeffs  = 0;
    coeffs   = '';
    tr_present='';
end

% Start logging txt if save_txt
if save_txt && submit
    imagefile=cell2mat(file_list(end));
    % Read file and get header information
    [file_path, filename]  = fileparts(imagefile);
    
    if exist(file_path)
        % Make log name the same as the saved map name
        txtlog_output_path = fullfile(file_path, [output_basename, '_', fit_type,'_', filename ...
                ,'.txt']);
        diary(txtlog_output_path);
    else
        errormsg = warning('Path of files does not exist');
        return;
    end
end


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
    errormsg = warning( 'TE/TR/FA/TI list contains invalid values' );
    disp(parameter_list);
    return;
end

for m=size(file_list,1):-1:1
    testfile=cell2mat(file_list(m));
    if ~exist(testfile, 'file')
        % File does not exist.
        errormsg = warning( 'File does not exist' );
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
    [nrows,ncols]= size(file_list);
    for row=1:nrows
        disp(file_list{row,:})
    end
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

if strcmp(fit_type, 'user_input')
    disp('User selected fit file: ');
    disp(fit_file);
end


% return;

% Calculate number of fits

dim_n = numel(parameter_list);
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
if ~neuroecon && exist('matlabpool')
    s = matlabpool('size');
    if s~=number_cpus
        if s>0
            matlabpool close
        end
        matlabpool('local', number_cpus); % Check
    end
    
    if strcmp(fit_type, 'user_input') && submit
       matlabpool('ADDATTACHEDFILES', {fit_file});
    end    
end

execution_time = zeros(size(file_list,1),1);

% do processing
for n=1:number_of_fits
    tic %start timer
    
    % Read only one file then process it
    if ~strcmp(data_order,'xyzfile')
        imagefile=cell2mat(file_list(n));
        
        % Read file and get header information
        [file_path, filename ext]  = fileparts(imagefile);
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
            
            % Resize to small for visualization
            if ~submit
                for j = 1:size(image_3d,3)
                    image_3d_small(:,:,j) = imresize(image_3d(:,:,j), 0.4);
                end
                image_3d = image_3d_small;
            end
            
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
            fit_type = 'ADC_linear_fast';
        elseif ~isempty(strfind(fit_type, 'ADC'))
            fit_type = 'user_input';
        else
           
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
        createTask(job, @parallelFit, 1,{parameter_list,fit_type,shaped_image,tr, submit, fit_file, ncoeffs, coeffs, tr_present,rsquared_threshold});
        
        submit(job);
        waitForState(job)
        results = getAllOutputArguments(job);
        destroy(job);
        
        fit_output = cell2mat(results);
    else

        fit_output = parallelFit(parameter_list,fit_type,shaped_image,tr, submit, fit_file, ncoeffs, coeffs, tr_present,rsquared_threshold);

    end
    
    if strfind(fit_type, 'user_input')
        
        for i = 1:ncoeffs
            eval([coeffs{i} '_fit = fit_output(:,' num2str(i) ');']);
            
            eval([coeffs{i} '_cilow = fit_output(:,' num2str(ncoeffs+i+1) ');']);
            eval([coeffs{i} '_cihigh= fit_output(:,' num2str(ncoeffs+i+1) ');']);
        end
        
        r_squared				 = fit_output(:,ncoeffs+1);

        % Throw out bad results
        ind = [];
        for i = 1:ncoeffs
            ind = [ind, eval(['find(' coeffs{i} '_fit ~= -2);'])];
            ind = unique(ind);
        end
        
        indr = find(r_squared < rsquared_threshold);
        
        indbad = intersect(indr, ind);
        
        for i = 1:ncoeffs
            eval([coeffs{i} '_fit(indbad) = -1;']);
            eval([coeffs{i} '_fit = reshape(' coeffs{i} '_fit, [dim_x, dim_y, dim_z]);']);
            
            eval([coeffs{i} '_cilow(indbad) = -1;']);
            eval([coeffs{i} '_cilow = reshape(' coeffs{i} '_cilow, [dim_x, dim_y, dim_z]);']);
            
            eval([coeffs{i} '_cihigh(indbad) = -1;']);
            eval([coeffs{i} '_cihigh = reshape(' coeffs{i} '_cihigh, [dim_x, dim_y, dim_z]);']);
        end
       
        r_squared				= reshape(r_squared, [dim_x, dim_y, dim_z]);
        
    else
        % Collect and reshape outputs
        exponential_fit			 = fit_output(:,1);
        rho_fit					 = fit_output(:,2);
        r_squared				 = fit_output(:,3);
        confidence_interval_low	 = fit_output(:,4);
        confidence_interval_high = fit_output(:,5);
        
        % Throw out bad results
        indr = find(r_squared < rsquared_threshold);
        inde = find(exponential_fit ~=-2);
        m    =intersect(indr,inde);
        
        rho_fit(m) = -1;
        exponential_fit(m) = -1;
        confidence_interval_low(m) = -1;
        confidence_interval_high(m) = -1;
        
        
        %         for m=1:size(exponential_fit)
        %             if(r_squared(m) < rsquared_threshold && exponential_fit(m)~=-2)
        %                 rho_fit(m) = -1;
        %                 exponential_fit(m) = -1;
        %                 confidence_interval_low(m) = -1;
        %                 confidence_interval_high(m) = -1;
        %             end
        %         end

        exponential_fit			= reshape(exponential_fit, [dim_x, dim_y, dim_z]);
        rho_fit					= reshape(rho_fit,  [dim_x, dim_y, dim_z]); %#ok<NASGU>
        r_squared				= reshape(r_squared, [dim_x, dim_y, dim_z]);
        confidence_interval_low  = reshape(confidence_interval_low, [dim_x, dim_y, dim_z]);
        confidence_interval_high = reshape(confidence_interval_high, [dim_x, dim_y, dim_z]);
    end
    
    if submit
        
        %             for i = 1:ncoeffs
        %             eval([coeffs{i} '_fit(indbad) = -1;']);
        %             eval([coeffs{i} '_fit = reshape(' coeffs{i} '_fit, [dim_x, dim_y, dim_z]);']);
        %
        %         end
        if strfind(fit_type, 'user_input')
            % Create output names
            
            for i = 1:ncoeffs
                fullpathT2{i} = fullfile(file_path, [output_basename, '_', coeffs{i},'_', filename ...
                    ,'.nii']);
                
                fullpathCILow{i}   = fullfile(file_path, ['CI_low_', coeffs{i},'_', filename ...
                    , '.nii']);
                fullpathCIHigh{i}   = fullfile(file_path, ['CI_high_', coeffs{i},'_', filename ...
                    , '.nii']);
            end
            fullpathRsquared   = fullfile(file_path, ['Rsquared_', fit_type,'_', filename ...
                , '.nii']);
            
            
            % Write output
            for i = 1:ncoeffs
                
                eval(['T2dirnii(' num2str(i) ').nii = make_nii(' coeffs{i} '_fit, res, [1 1 1], [], output_basename);']);
                eval(['save_nii(T2dirnii(' num2str(i) ').nii, fullpathT2{' num2str(i) '});']);
                
                eval(['CILOWdirnii(' num2str(i) ').nii = make_nii(' coeffs{i} '_cilow, res, [1 1 1], [], output_basename);']);
                eval(['save_nii(CILOWdirnii(' num2str(i) ').nii, fullpathCILow{' num2str(i) '});']);
                
                 eval(['CIHIGHdirnii(' num2str(i) ').nii = make_nii(' coeffs{i} '_cihigh, res, [1 1 1], [], output_basename);']);
                eval(['save_nii(CIHIGHdirnii(' num2str(i) ').nii, fullpathCIHigh{' num2str(i) '});']);
            end
            
            Rsquareddirnii   = make_nii(r_squared, res, [1 1 1], [], 'R Squared of fit');
            save_nii(Rsquareddirnii, fullpathRsquared);
           
        else
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
        end
        
        execution_time(n) = toc;
        
        disp(['Map completed at ', datestr(now,'mmmm dd, yyyy HH:MM:SS')])
        disp(['Execution time was: ',datestr(datenum(0,0,0,0,0,execution_time(n)),'HH:MM:SS')]);
        disp('Map saved to: ');
        if iscell(fullpathT2)
            for i = 1:numel(fullpathT2)
                disp(fullpathT2{i});
            end
        else
            disp(fullpathT2);
        end
        
        %    number_cps, neuroecon, batch_log, log_name, cur_dataset, submit
        
        single_IMG = 1;
    else
        % Process R2 map for quick visualization
        single_IMG = r_squared;
    end
end

% Close parallel processing pool
% if ~neuroecon && exist('matlabpool') && submit
%     matlabpool close;
% end

if submit
    total_time = sum(execution_time);
    disp(['All processing complete at ', datestr(now,'mmmm dd, yyyy HH:MM:SS')])
    disp(['Total execution time was: ',datestr(datenum(0,0,0,0,0,total_time),'HH:MM:SS')]);
    
    % The map was calculated correctly, so we note this in the data structure
    cur_dataset.to_do = 0;
    JOB_struct(1).batch_data = cur_dataset;
end


% Save text and data structure logs if desired.
if submit
    % Create data structures for curve fit analysis
    fit_data.fit_voxels = logical(numel(shaped_image));
    fit_data.fitting_results = fit_output;
    fit_data.model_name = fit_type;
    fit_data.number_rois = 0;
    fit_data.fit_file = fit_file;
    fit_data.ncoeffs = ncoeffs;
    fit_data.coeffs = coeffs;
    xdata{1}.x_values = parameter_list;
    xdata{1}.y_values = shaped_image;
    xdata{1}.tr = tr;
    xdata{1}.dimensions = [dim_x, dim_y, dim_z];
    xdata{1}.numvoxels = numel(fit_output);
    if strfind(fit_type,'ADC')
    	xdata{1}.x_units = 'b-value';
    elseif strfind(fit_type,'fa')
        xdata{1}.x_units = 'FA (degrees)';
    elseif strcmp(fit_type,'user_input')
        xdata{1}.x_units = 'a.u.';
    else
        xdata{1}.x_units = 'ms';
    end
    xdata{1}.y_units = 'a.u.';
    
    log_name = strrep(fullpathT2, '.nii', '.mat');
    
    if save_log
        save(log_name, 'JOB_struct','fit_data','xdata', '-mat');
        disp(['Saved log at: ' log_name]);
    end
end

if submit
    diary off
end




