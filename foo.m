clear all;

% INPUTS
%------------------------------------
%imagefile = n{i}
%imagefile = 'E:\MATLAB\COH\ns06_11oct12\20121031\gI1\new\20121031_gI1_ns06_11oct12_T2star_01.nii';
imagefile = 'C:\Users\sbarnes\Documents\MATLAB\COH\ns06_11oct12\20121031\gI1\new\20121031_gI1_ns06_11oct12_T2star_01.nii';
te = [10.5 21 31.5 42 52.5 63]';
fit_type = 'linear_weighted';
fit_type_list = {'none','linear_simple','linear_weighted','exponential'};
%fit_type_list = {'none','none','none','none'};
neuroecon = 0;
%------------------------------------
n=1;
for n=1:size(fit_type_list,2)
    fit_type = fit_type_list{n};
    tic
    % Read file and get header information
    [file_path, filename]  = fileparts(imagefile);
    nii = load_nii(imagefile);
    res = nii.hdr.dime.pixdim;
    res = res(2:4);
    image_3d = nii.img;
    [dim_x, dim_y, dim_zte] = size(image_3d);
    dim_te = size(te,1);
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

        warning off

        p = pwd;
        n = '/home/thomasn/scripts/niftitools';

        job = createMatlabPoolJob(sched, 'configuration', 'NeuroEcon.local','PathDependencies', {p})
        set(job, 'MaximumNumberOfWorkers', 20);
        set(job, 'MinimumNumberOfWorkers', 1);
        createTask(job, @parallelFit, 1,{te,fit_type,shaped_image});

        submit(job)
        waitForState(job)
        results = getAllOutputArguments(job)
        destroy(job);

        fit_output = cell2mat(results);
    else
        
        fit_output = parallelFit(te,fit_type,shaped_image);

    end

    % Collect and reshpae outputs
    t2_fit					 = fit_output(:,1);
    rho_fit					 = fit_output(:,2);
    r_squared				 = fit_output(:,3);
    confidence_interval_low	 = fit_output(:,4);
    confidence_interval_high = fit_output(:,5);

    t2_fit					= reshape(t2_fit, [dim_x, dim_y, dim_z]);
    rho_fit					= reshape(rho_fit,  [dim_x, dim_y, dim_z]);
    r_squared				= reshape(r_squared, [dim_x, dim_y, dim_z]);
    confidence_interval_low  = reshape(confidence_interval_low, [dim_x, dim_y, dim_z]);
    confidence_interval_high = reshape(confidence_interval_high, [dim_x, dim_y, dim_z]);

    % Create output names
    fullpathT2 = fullfile(file_path, ['T2star_map_', fit_type,'_', filename,'.nii'])
    fullpathRsquared   = fullfile(file_path, ['Rsquared_', fit_type,'_', filename ...
        , '.nii'])
    fullpathCILow   = fullfile(file_path, ['CI_low_', fit_type,'_', filename ...
        , '.nii'])
    fullpathCIHigh   = fullfile(file_path, ['CI_high_', fit_type,'_', filename ...
        , '.nii'])

    % Write output
    T2dirnii = make_nii(t2_fit, res, [1 1 1], [], 'T2 Values');
    Rsquareddirnii   = make_nii(r_squared, res, [1 1 1], [], 'R Squared of fit');
    CILowdirnii  = make_nii(confidence_interval_low, res, [1 1 1], [], 'Low 95% confidence interval');
    CIHighdirnii  = make_nii(confidence_interval_high, res, [1 1 1], [], 'High 95% confidence interval');
    save_nii(T2dirnii, fullpathT2);
    save_nii(Rsquareddirnii, fullpathRsquared);
    save_nii(CILowdirnii, fullpathCILow);
    save_nii(CIHighdirnii, fullpathCIHigh);
    
    t(n) = toc
end
disp(t)

%% Email the person on completion
% Define these variables appropriately:
mail = 'immune.caltech@gmail.com'; %Your GMail email address
password = 'antibody'; %Your GMail password
email = 'srsbarnes@gmail.com';
% Then this code will set up the preferences properly:
setpref('Internet','E_mail',mail);
setpref('Internet','SMTP_Server','smtp.gmail.com');
setpref('Internet','SMTP_Username',mail);
setpref('Internet','SMTP_Password',password);
props = java.lang.System.getProperties;
props.setProperty('mail.smtp.auth','true');
props.setProperty('mail.smtp.socketFactory.class', 'javax.net.ssl.SSLSocketFactory');
props.setProperty('mail.smtp.socketFactory.port','465');


sendmail(email,'T2 star map Processing completed',['Hello! Your job from is done! ' ...
                    'compution time was ',num2str(t)]);
