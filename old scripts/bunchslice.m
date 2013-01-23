function imagea = bunchslice(imageslice, slices, numBvals)
  %{
  imagea = zeros(size(imageslice, 1)*slices, size(imageslice, 2), ...
                 numBvals);
  
  size(imagea);
  
  size(imageslice);
  for i = 1:slices
    
    onsetsliceindex = (([1:numBvals]-1).*slices + i);
    
    
    imagea(([1:size(imageslice, 1)]+(i-1)*size(imageslice,1)), :,[1:numBvals]) ...
        = imageslice(:,:, onsetsliceindex);
  end
  %}
  
  
  onesetsliceindex = zeros(slices, numBvals);
  
  for i = 1:slices
    for j = 1:numBvals
      
      onsetsliceindex(i,j) = i+(j-1)*slices;
    end
  end
  
  imagea = zeros(size(imageslice,1)*slices*size(imageslice,2), ...
                 numBvals);
  
  size(imagea);
  
  imageslice = reshape(imageslice, size(imageslice, 1)*size(imageslice,2), ...
                       numBvals*slices);
  
  onsetsliceindex;
  size(imageslice);
  
  for i = 1:slices
    [1:size(imageslice,1)]+(i-1)*(size(imageslice,1));
    
    imageslice(:,onsetsliceindex(i,:));
    
    imagea([1:size(imageslice,1)]+(i-1)*(size(imageslice,1)), :) = imageslice(:,onsetsliceindex(i,:));
  end
  
  %imagea = cast(imagea, 'double');
  
  imagea = mat2cell(imagea, ones(size(imagea,1),1), [numBvals]);
  
  