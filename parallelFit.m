% Parallel wrapper for the T2 fitting algorithm
function fit_output = parallelFit(te,fit_type,shaped_image,tr)

[dim_x, dim_y, dim_z, dim_te] = size(shaped_image);
linear_shape = reshape(shaped_image,dim_x*dim_y*dim_z,dim_te);
number_voxels = dim_x*dim_y*dim_z;

% Preallocate for speed
fit_output = zeros([number_voxels 5],'double');

% Break up parfor to allow for progress bar, and create progress bar
parallel_size = 1000;
h = waitbar(0,'Starting...','Name','Calculating T2...',...
            'CreateCancelBtn',...
            'setappdata(gcbf,''canceling'',1)');
setappdata(h,'canceling',0)
cancel_button = false;

for n=1:parallel_size:number_voxels
	parfor m = n:min(n+(parallel_size-1),number_voxels)
		% iteration code here
		% note that z will be your iteration
		si = linear_shape(m,:)';
		si = cast(si,'double');
		fit_output(m,:) = fitT2(te,fit_type,si,tr);
	end
	% check for cancel
	if getappdata(h,'canceling')
		cancel_button = true;
        break
	end
	% update waitbar each "parallel_size"th iteration
	waitbar(n/number_voxels,h,...
		sprintf('Completed %d of %d T2 fits',n,number_voxels));
end

delete(h)       % DELETE the waitbar; don't try to CLOSE it.

if cancel_button
	warning( 'Calculation canceled, data not valid' );
	return;
end

% parfor n = 1:number_voxels
% 
%     si = linear_shape(n,:)';
%     si = cast(si,'double');
%     fit_output(n,:) = fitT2(te,fit_type,si);
% 
% end


    

