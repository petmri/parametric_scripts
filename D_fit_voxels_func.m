function results = D_fit_voxels_func(results_b_path,dce_model,time_smoothing,time_smoothing_window,xy_smooth_size,number_cpus,roi_list,fit_voxels,neuroecon)

% D_fit_voxels_func - Fit DCE curve to various models on a voxel by voxel
% or ROI basis
%
% Inputs:
%  results_b_path     - *.mat Results from part B
%  dce_model          - Select fitting model
%                       'aif_vp' = tofts with vascular compartment
%                       'aif' = tofts without vascular compartment
%                       'fxr' = not implemented
%                       'sauc' = not implemented 
%                       'ss' = not implemented 
%                       'fractal' = not implemented
%                       'auc' = not implemented
%                       'auc_rr' = not implemented
%  time_smoothing     - type of time smoothing
%                       'none' = no smoothing
%                       'moving' = moving average
%                       'rlowess' = robust local regression
%  time_smoothing_window - size of time smoothing window (time points)
%  xy_smooth_size     -	sigma of the Gaussian low pass smooth function
%  number_cpus        - number of cpu cores for parallel processing
%  roi_list           - paths to ROIs that specify homogenous regions to
%                       calculate a single DCE fit for. Values >0
%                       considered in the ROI, values <=0 considered
%                       outside the ROI
%  fit_voxels         - perform DCE fit on individual voxels
%  neuroecon          - perform processing on neuroecon server
%
% The script loads the data arrays generated from B_AIF_fitting_func(). 
% Then it will fit a DCE curve according to various models
% 
% Requires:
% ???
% 
% Samuel Barnes
% Caltech
% December 2013


% Toggle options
%************************
r2filter = 0;		% Filter out all fits with r2 < r2filter
close_pool = 0;		% Close matlabpool when done with processing
% End options
%************************

% a) Load the data files
load(results_b_path);
PathName = PathName1;

% Log input results
log_path = fullfile(PathName, ['D_' rootname dce_model '_fit_voxels.log']);
if exist(log_path, 'file')==2
  delete(log_path);
end
diary(log_path);
fprintf('************** User Input **************\n\n');
disp('User selected part B results: ');
disp(results_b_path);
Opt.Input = 'file';
b_md5 = DataHash(results_b_path, Opt);
fprintf('File MD5 hash: %s\n\n', b_md5)
disp('User selected dce model: ');
fprintf('%s\n\n',dce_model);
disp('User selected time smoothing model: ');
fprintf('%s\n\n',time_smoothing);
disp('User selected time smoothing window size: ');
disp(time_smoothing_window);
disp('User selected XY smooth size (sigma)');
disp(xy_smooth_size);
disp('User selected number of CPU cores');
disp(number_cpus);
disp('User selected ROI list');
[nrows,ncols]= size(roi_list);
for row=1:nrows
	disp(roi_list{row,:})
end
disp(' ');
disp('User selected fit individual voxels');
disp(fit_voxels);
disp('User selected use neuroecon');
disp(neuroecon);
fprintf('************** End User Input **************\n\n\n');

disp('Starting Part D - Fitting Voxels/ROIs')
disp(datestr(now))
disp(' ');
tic

% Start processing
xdata{1}.numvoxels = numvoxels;
disp(['Fitting data using the ' dce_model ' model']);

% Open pool if not open or improperly sized
if matlabpool('size')~= number_cpus
	% Do not launch pool with diary on, locks the log file
	diary off;
	if matlabpool('size')>0
		matlabpool close;
	end
	matlabpool('local', number_cpus);
	diary on;
end

% Save original data
xdata{1}.Ct_original = xdata{1}.Ct;

% Perpare any ROIs
number_rois = 0;
if ~isempty(roi_list) && ~strcmp('No Files',cell2mat(roi_list(1)))
	%Sanitize list
	for m=size(roi_list,1):-1:1
		testfile=cell2mat(roi_list(m));
		if ~exist(testfile, 'file')
		  % File does not exist.
		  warning( 'File does not exist' );
		  disp(testfile);
		  return;
		end
		for n=(m-1):-1:1
			comparefile=roi_list(n);
			if strcmp(testfile,comparefile)
				disp( 'Removing duplicates' );
				disp(comparefile);
				roi_list(m)=[];
			end
		end
	end
	number_rois = size(roi_list,1);
	%After sanitizing make sure we have some left
	if number_rois~=0
		[~, roi_name, roi_ext] = arrayfun(@(x) fileparts(x{:}), roi_list, 'UniformOutput', false);

		%Load ROI, find the selected voxels
		for r=number_rois:-1:1
			single_file=cell2mat(roi_list(r));

			single_roi = load_nii(single_file);
			single_roi = double(single_roi.img);
			roi_index{r}= find(single_roi > 0);
		end

		original_timepoint = zeros(size(currentimg));
		roi_series = zeros(size(xdata{1}.Ct,1),number_rois);
		for t=1:size(xdata{1}.Ct,1)
			original_timepoint(tumind) = xdata{1}.Ct(t,:);
	% 		original_timepoint(roi_index{r}) = 1e-4;
	% 		imshow(original_timepoint.*20000);
			%Average ROI voxels, insert into time series
			for r=number_rois:-1:1	
				roi_series(t,r) = mean(original_timepoint(roi_index{r}));
			end
		end
		%make backup
		roi_series_original = roi_series;
	end
end

if ~fit_voxels && number_rois==0
	print('nothing to fit, select an ROI file or check "fit voxels"');
	return;
end

% for r=number_rois:-1:1	
% 	figure;
% 	plot(xdata{1}.timer,roi_series(:,r));
% end
% return;

% a1) smoothing in image domain
if xy_smooth_size~=0 && fit_voxels
	% original_timepoint = NaN(size(currentimg));
	original_timepoint = zeros(size(currentimg));
	% make size 3*sigma rounded to nearest odd
	xy_smooth_size_odd = 2.*round((xy_smooth_size*3+1)/2)-1;
	if xy_smooth_size_odd<3
		xy_smooth_size_odd = 3;
	end
	h = fspecial('gaussian', [xy_smooth_size_odd xy_smooth_size_odd],xy_smooth_size);
	for i=1:size(xdata{1}.Ct,1)
		original_timepoint(tumind) = xdata{1}.Ct(i,:);
	% 	imshow(smooth_timepoint.*20000)
		smooth_timepoint = filter2(h, original_timepoint);
		xdata{1}.Ct(i,:) = smooth_timepoint(tumind)';
	end
end

% a2) smoothing in time domain
if ~strcmp(time_smoothing,'none')
	disp('Smoothing time domain');
	
	if fit_voxels
		Ct_all = xdata{1}.Ct;
		p = ProgressBar(size(Ct_all,2));
		parfor i=1:size(Ct_all,2)
			Ct_smooth = Ct_all(:,i);
			if strcmp(time_smoothing,'moving')
				Ct_smooth = smooth(Ct_smooth,time_smoothing_window,'moving');
			elseif strcmp(time_smoothing,'rlowess')
				Ct_smooth = smooth(Ct_smooth,time_smoothing_window/size(Ct_smooth,1),'rlowess');
			else
				% no smoothing
			end

			Ct_all(:,i) = Ct_smooth;
			p.progress;
		end
		xdata{1}.Ct = Ct_all;
		p.stop;
	end
	
	for r=1:number_rois	
		roi_series(:,r);
		roi_smooth = roi_series(:,r);
		if strcmp(time_smoothing,'moving')
			roi_smooth = smooth(roi_smooth,time_smoothing_window,'moving');
		elseif strcmp(time_smoothing,'rlowess')
			roi_smooth = smooth(roi_smooth,time_smoothing_window/size(roi_smooth,1),'rlowess');
		else
			% no smoothing
		end

		roi_series(:,r) = roi_smooth;
	end
end

% b) voxel by voxel fitting
%************************
% tic
if(neuroecon)
	warning off
	
	p = pwd
	n = '/home/thomasn/scripts/niftitools';
   % for k = 1:totale 
		sched = findResource('scheduler', 'configuration', 'NeuroEcon.local');
		set(sched, 'SubmitArguments', '-l walltime=5:00:00 -m abe -M thomasn@caltech.edu')
		
		jj = createMatlabPoolJob(sched, 'PathDependencies', {p});
		
		set(jj, 'MaximumNumberOfWorkers', number_cpus)
		set(jj, 'MinimumNumberOfWorkers', number_cpus)        
%         STARTEND(k,:)
%         %We only feed the workers only the voxels that they can handle
%         
%         xdata{1}.Ct = wholeCt(:,STARTEND(k,1):STARTEND(k,2));
		
		%Schedule object, neuroecon
		t = createTask(jj, @FXLfit_generic, 1,{xdata, numvoxels, dce_model});
		set(t, 'CaptureCommandWindowOutput', true);
   
		submit(jj)
		waitForState(jj,'finished')
		jj
		results = getAllOutputArguments(jj)
		destroy(jj)
	
		clear jj
		fitting_results = cell2mat(results);
	   % x(STARTEND(k,1):STARTEND(k,2),:) = cell2mat(results);  
else
	if number_rois~=0
		disp(['Starting fitting for ' num2str(number_rois) ' ROIs...']);

		roi_data{1}.Cp = xdata{1}.Cp;
		roi_data{1}.timer = xdata{1}.timer;
		roi_data{1}.Ct = roi_series;
		roi_results = FXLfit_generic(roi_data, number_rois, dce_model);

		disp('ROI fitting done')
        disp(' ')
	end
	if fit_voxels
		disp(['Starting fitting for ' num2str(numvoxels) ' voxels...']);

		fitting_results = FXLfit_generic(xdata, numvoxels, dce_model);

		disp('Voxel fitting done')
	end
end
% processing_time = toc;
% disp(['processing completed in ' datestr(processing_time/86400, 'HH:MM:SS') ' (hr:min:sec)']);
if close_pool
	matlabpool close;
end

% c) Save file
%************************
fit_data.fit_voxels = fit_voxels;
fit_data.tumind = tumind;
fit_data.dynam_name = dynam_name;
fit_data.PathName = PathName;
fit_data.time_smoothing = time_smoothing;
fit_data.time_smoothing_window =time_smoothing_window;
fit_data.dce_model =dce_model;
	
if number_rois~=0
	xdata{1}.roi_series = roi_series;
	xdata{1}.roi_series_original = roi_series_original;
	xdata{1}.number_rois = number_rois;
	fit_data.roi_results = roi_results;
	fit_data.roi_name = roi_name;
end
if fit_voxels
	fit_data.fitting_results  = fitting_results;
end

save(fullfile(PathName, ['D_' rootname dce_model '_fit_voxels.mat']),  'xdata','fit_data')
results = fullfile(PathName, ['D_' rootname dce_model '_fit_voxels.mat']);
Opt.Input = 'file';
mat_md5 = DataHash(results, Opt);
disp(' ')
disp('MAT results saved to: ')
disp(results)
disp(['File MD5 hash: ' mat_md5])

% d) Check if physiologically possible, if not, remove
%************************
% checkind = find(x(:,1) < 0);
% x(checkind,:) = [];
% tumind(checkind) = [];

% ve > 1
% checkind = find(x(:,2) > 1);
% x(checkind,:) = [];
% tumind(checkind) = [];
% 
% % ve < 0
% checkind = find(x(:,2) < 0);
% x(checkind,:) = [];
% tumind(checkind) = [];
% 
% % vp > 1
% checkind = find(x(:,3) > 1);
% x(checkind,:) = [];
% tumind(checkind) = [];
% 
% % vp < 0
% checkind = find(x(:,3) < 0);
% x(checkind,:) = [];
% tumind(checkind) = [];
% 
% % Ktrans > 3
% checkind = find(x(:,1) > 3);
% x(checkind,:) = [];
% tumind(checkind) = [];
% 
% % Ktrans < 0
% checkind = find(x(:,1) < 0);
% x(checkind,:) = [];
% tumind(checkind) = [];
% 
% %% d.2) Check R2 fit
% 
% checkind = find(x(:,4) < r2filter);
% x(checkind,:)    = [];
% tumind(checkind) = [];


% f) Make maps and Save image files
%************************
[discard, actual] = fileparts(strrep(dynam_name, '\', '/'));
res = [0 0.25 0.25 2];

if strcmp(dce_model, 'aif')
	% Write ROI results
	if number_rois~=0
		headings = {'ROI path', 'ROI', 'Ktrans', 'Ve','Residual', 'Ktrans 95% low', ...
			'Ktrans 95% high', 'Ve 95% low', 'Ve 95% high'};
		roi_results(:,3) = []; %erase vp column
		xls_results = [roi_list roi_name mat2cell(roi_results,ones(1,size(roi_results,1)),ones(1,size(roi_results,2)))];
		xls_results = [headings; xls_results];
		xls_path = fullfile(PathName, [rootname dce_model '_rois.xls']);
		xlswrite(xls_path,xls_results);
	end
	% Write voxel results
	if fit_voxels
		KtransROI = zeros(size(currentimg));
		veROI     = zeros(size(currentimg));
		residual  = zeros(size(currentimg));
		ci_95_low_ktrans	= zeros(size(currentimg));
		ci_95_high_ktrans	= zeros(size(currentimg));
		ci_95_low_ve		= zeros(size(currentimg));
		ci_95_high_ve		= zeros(size(currentimg));	

		KtransROI(tumind) = fitting_results(:,1);
		veROI(tumind)     = fitting_results(:,2);
		residual(tumind)  = fitting_results(:,4);
		ci_95_low_ktrans(tumind)	= fitting_results(:,5);
		ci_95_high_ktrans(tumind)	= fitting_results(:,6);
		ci_95_low_ve(tumind)		= fitting_results(:,7);
		ci_95_high_ve(tumind)		= fitting_results(:,8);

		nii_path{1} = fullfile(PathName, [rootname dce_model '_Ktrans.nii']);
		nii_path{2} = fullfile(PathName, [rootname dce_model '_ve.nii']);
		nii_path{3} = fullfile(PathName, [rootname dce_model '_residual.nii']);
		nii_path{4} = fullfile(PathName, [rootname dce_model '_ktrans_ci_low.nii']);
		nii_path{5} = fullfile(PathName, [rootname dce_model '_ktrans_ci_high.nii']);
		nii_path{6} = fullfile(PathName, [rootname dce_model '_ve_ci_low.nii']);
		nii_path{7} = fullfile(PathName, [rootname dce_model '_ve_ci_high.nii']);

		save_nii(make_nii(KtransROI, res(2:4), [1 1 1]), nii_path{1});
		save_nii(make_nii(veROI, res(2:4), [1 1 1]), nii_path{2});
		save_nii(make_nii(residual, res(2:4), [1 1 1]), nii_path{3});
		save_nii(make_nii(ci_95_low_ktrans, res(2:4), [1 1 1]), nii_path{4});
		save_nii(make_nii(ci_95_high_ktrans, res(2:4), [1 1 1]), nii_path{5});
		save_nii(make_nii(ci_95_low_ve, res(2:4), [1 1 1]), nii_path{6});
		save_nii(make_nii(ci_95_high_ve, res(2:4), [1 1 1]), nii_path{7});
	end
elseif strcmp(dce_model, 'aif_vp')
	% Write ROI results
	if number_rois~=0
		headings = {'ROI path', 'ROI', 'Ktrans', 'Ve','Vp','Residual', 'Ktrans 95% low', ...
		'Ktrans 95% high', 'Ve 95% low', 'Ve 95% high','Vp 95% low','Vp 95% high'};
		xls_results = [roi_list roi_name mat2cell(roi_results,ones(1,size(roi_results,1)),ones(1,size(roi_results,2)))];
		xls_results = [headings; xls_results];
		xls_path = fullfile(PathName, [rootname dce_model '_rois.xls']);
		xlswrite(xls_path,xls_results);
	end
	% Write voxel results
	if fit_voxels
		KtransROI = zeros(size(currentimg));
		veROI     = zeros(size(currentimg));
		vpROI     = zeros(size(currentimg));
		residual  = zeros(size(currentimg));
		ci_95_low_ktrans	= zeros(size(currentimg));
		ci_95_high_ktrans	= zeros(size(currentimg));
		ci_95_low_ve		= zeros(size(currentimg));
		ci_95_high_ve		= zeros(size(currentimg));	
		ci_95_low_vp		= zeros(size(currentimg));
		ci_95_high_vp		= zeros(size(currentimg));	

		KtransROI(tumind) = fitting_results(:,1);
		veROI(tumind)     = fitting_results(:,2);
		vpROI(tumind)     = fitting_results(:,3);
		residual(tumind)  = fitting_results(:,4);
		ci_95_low_ktrans(tumind)	= fitting_results(:,5);
		ci_95_high_ktrans(tumind)	= fitting_results(:,6);
		ci_95_low_ve(tumind)		= fitting_results(:,7);
		ci_95_high_ve(tumind)		= fitting_results(:,8);
		ci_95_low_vp(tumind)		= fitting_results(:,9);
		ci_95_high_vp(tumind)		= fitting_results(:,10);

		nii_path{1} = fullfile(PathName, [rootname dce_model '_Ktrans.nii']);
		nii_path{2} = fullfile(PathName, [rootname dce_model '_ve.nii']);
		nii_path{3} = fullfile(PathName, [rootname dce_model '_vp.nii']);
		nii_path{4} = fullfile(PathName, [rootname dce_model '_residual.nii']);
		nii_path{5} = fullfile(PathName, [rootname dce_model '_ktrans_ci_low.nii']);
		nii_path{6} = fullfile(PathName, [rootname dce_model '_ktrans_ci_high.nii']);
		nii_path{7} = fullfile(PathName, [rootname dce_model '_ve_ci_low.nii']);
		nii_path{8} = fullfile(PathName, [rootname dce_model '_ve_ci_high.nii']);
		nii_path{9} = fullfile(PathName, [rootname dce_model '_vp_ci_low.nii']);
		nii_path{10} = fullfile(PathName, [rootname dce_model '_vp_ci_high.nii']);
		
		save_nii(make_nii(KtransROI, res(2:4), [1 1 1]), nii_path{1});
		save_nii(make_nii(veROI, res(2:4), [1 1 1]), nii_path{2});
		save_nii(make_nii(vpROI, res(2:4), [1 1 1]), nii_path{3});
		save_nii(make_nii(residual, res(2:4), [1 1 1]), nii_path{4});
		save_nii(make_nii(ci_95_low_ktrans, res(2:4), [1 1 1]), nii_path{5});
		save_nii(make_nii(ci_95_high_ktrans, res(2:4), [1 1 1]), nii_path{6});
		save_nii(make_nii(ci_95_low_ve, res(2:4), [1 1 1]), nii_path{7});
		save_nii(make_nii(ci_95_high_ve, res(2:4), [1 1 1]), nii_path{8});
		save_nii(make_nii(ci_95_low_vp, res(2:4), [1 1 1]), nii_path{9});
		save_nii(make_nii(ci_95_high_vp, res(2:4), [1 1 1]), nii_path{10});
	end
end

% Calculate file hashes and log them
Opt.Input = 'file';
if number_rois~=0
	xls_md5 = DataHash(xls_path, Opt);
	disp(' ')
	disp('ROI results saved to: ')
	disp(xls_path)
	disp(['File MD5 hash: ' xls_md5])
end
if fit_voxels 
	disp(' ')
	disp('Voxel results saved to: ')
	for i=1:numel(nii_path)
		nii_md5 = DataHash(nii_path{i}, Opt);
		disp(nii_path{i})
		disp(['File MD5 hash: ' nii_md5])
	end
end

disp(' ');
disp('Finished D');
disp(datestr(now))
toc
diary off;



