% Parallel wrapper for the T2 fitting algorithm
function fit_output = parallelFit(te,fit_type,shaped_image)

[dim_x, dim_y, dim_z, dim_te] = size(shaped_image);
linear_shape = reshape(shaped_image,dim_x*dim_y*dim_z,dim_te);
number_voxels = dim_x*dim_y*dim_z;

% Preallocate for speed
fit_output = zeros([number_voxels 5],'double');
matlabpool local 4;
% previous_row = 1;
parfor n = 1:number_voxels
% for n = 1:number_voxels
    %image has been reshaped to try and reduce data transfered to each
    %thread, hopefully only the single exponential decay is transfered
%     [i, j, k] = ind2sub([dim_x,dim_y,dim_z],n);
%     if(i==44 && j==66)
%         foos = 1;
%     if(j~=previous_row)
%         previous_row = j;
%         str = ['Processing row ',num2str(j)];
%         disp(str);
%     end
    si = linear_shape(n,:)';
    si = cast(si,'double');
    fit_output(n,:) = fitT2(te,fit_type,si);
%     end
end

matlabpool close
    

