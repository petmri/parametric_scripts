%Reslice T2 for matlab, since it orders it by slice

%TE
numTE = 20;

filename = '20090713_hs04_30jun09_T2_01.nii';

A = load_nii(filename);

A = A.img;

slices = size(A, 3) / numTE;
AA = [];
checks = [1:numTE:size(A,3)];
for i = 1:numTE
    slicecount = [1:slices];
    if(i == 1)
        AA(:,:,slicecount) = A(:,:,checks + i-1);
    else
        checks+i-1
        AA(:,:,end+slicecount) = A(:,:, checks+i-1);
    end
    
end

size(AA)

A = make_nii(AA);

save_nii(A, strrep(filename, '.nii', '.nii'));

        