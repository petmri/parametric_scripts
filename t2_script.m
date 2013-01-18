% INPUTS
%------------------------------------
file_list = {'file1';'file2'};
                    % must point to valid nifti files
te_list = [10.5 21 31.5 42 52.5 63]';
                    % units of ms
fit_type = 'linear_weighted'; 
                    % options{'none','linear_simple','linear_weighted','exponential','linear_fast'}
number_cpus = 4;    % not used if running on neuroecon
neuroecon = 0;      % boolean
email = srsbarnes@gmail.com;
                    % Email will be sent to this address on job completion
%------------------------------------

% Call T2 Function
calculateT2(file_list,te_list,fit_type, number_cpus, neuroecon, email);