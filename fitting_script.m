% INPUTS
%------------------------------------
file_list = {'file1';'file2'};
					% must point to valid nifti files
parameter_list = [10.5 21 31.5 42 52.5 63]';
					% units of ms or degrees
fit_type = 'linear_weighted'; 
					% options{'none','t2_linear_simple','t2_linear_weighted','t2_exponential','t2_linear_fast'
					%			't1_tr_fit','t1_fa_fit','t1_fa_linear_fit','t1_ti_exponential_fit'}
odd_echoes = 0;		% boolean, if selected only odd parameters will be
					% used for fit
rsquared_threshold = 0.2;
					% all fits with R^2 less than this set to -1
number_cpus = 4;	% not used if running on neuroecon
neuroecon = 0;		% boolean
output_basename = 'foo';
					% base of output filename
data_order = 'xyzn';% in what order is the data organized
					% options{'xynz','xyzn','xyzfile'}
tr = 20;			% units ms, only used for T1 FA fitting
email = srsbarnes@gmail.com;
					% Email will be sent to this address on job completion
%------------------------------------

% Call Mapping Function
calculateMap(file_list,parameter_list,fit_type,odd_echoes,rsquared_threshold,number_cpus,neuroecon,output_basename,data_order,tr,email);
