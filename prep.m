function imagea = bunchslice(imageslice, slices, numBvals)
  
  cast(imageslice, 'double');
  
  onesetsliceindex = zeros(slices, numBvals)
  
  for i = 1:slices
    for j = 1:numBvals
      
      onsetsliceindex(i,j) = i+(j-1)*slices;
    end
  end
  
  imagea = zeros(size(imageslice,1)*slices, size(imageslice,2), ...
                 numBvals);
  
  for i = 1:slices
    
    imagea([1:size(imageslice,1)]+(i-1)*size(imageslice,1), size(imageslice,2), ...
           :) = imageslice(:,:,onsetsliceindex(i,:));
  end
  
  
  
  