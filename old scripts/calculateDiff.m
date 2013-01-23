%Parallized

function [res_pixels] = calculateDiff(img_stack, b_values, width, height, ...
                                      slices, numBvals, numImages, fitype, ...
                                      ploter, noise)
    if mod(slices, numBvals) ~= 0
        error('calculateDiff.m: Number of b-values should be divisible by total number of slices!');
    end
    
    if(numBvals == 2)
      fitype = 'linearsimp';
    end
    

    fprintf('Performing calculations ... \n');
    %source_pixels = zeros(numB, numImages, width*height);
     source_pixels = zeros(width, height, numImages*numBvals);
     
     sosize = size(source_pixels);
     isize = size(img_stack);

    %{
    for i=1:numBvals
        for j=1:numImages
            for k=1:(width*height)
                source_pixels(i, j, k) = img_stack(mod(k-1, width)+1, ...
                                                   floor((k-1)/width)+1, ...
                                                   (i-1)*numImages+j);
                
                mod(k-1, width)+1;
                                                   floor((k-1)/width)+1;
                
                
            end
        end
    end
    %}

    %Reslice from 3 slices x 7 values to 7 values x 3 slices orientation
    k = 1;
    for i = 1:numImages
      for j = 1:numBvals
        source_pixels(:,:,k) = img_stack(:,:, i+numImages*(j-1));
        k = k+1;
      end
    end
    
    %Make Weighting Matrix
    
    W = ones(1,numBvals);
    
    sizera = size(noise);

    numBvals;
       
    for i = 1:numBvals
      noisevolume = zeros(sizera(1), sizera(2), numImages); 
      
      k = 1;
      for j = 1:numImages
        j;
        (j-1)*numBvals+i;
        k;
        noisevolume(:,:,k) = noise(:,:,(j-1)*numBvals+i);
        k = k+1;
        %noisetemp(:,:,k) = noisetemplate(:,:,k);
      end
      
      
      
      
      noisevolume = noisevolume(:);
      %noisetemp = noisetemp(:);
      
      for k = 1:size(noisevolume,1)
        %if(noisetemp(i) == 1)
          
          onlynoisevolume(k) = noisevolume(k);
        %else
         % onlynoisevolume(i) = 0;
        %end
      end
      
      
      
      newnoisevolume = std(onlynoisevolume);
      
      if(newnoisevolume == 0)
        W(1,i) = 1;
      else
        W(1,i) = 1/(newnoisevolume)^2;
      end
    end
    
      
      W
      
     
    
    if(strcmp(fitype, 'ackerman'))
        outnum = 4;
    elseif(strcmp(fitype, 'acksimp'))
        outnum = 4;
    elseif(strcmp(fitype,'linearsimp'))
        outnum = 3;
    elseif(strcmp(fitype, 'simp'))
        outnum = 3;
    else
        error('No Fit Type Defined.');
    end
    
    
    res_pixels = zeros(numImages, outnum, width*height);
    dtmp = zeros(1, outnum);
    size(res_pixels);
    for r = 1:numImages
        for q = 1:(width*height)
            dtmp = fitPointsToDiffCurve(source_pixels, r, q, b_values, ...
                                        numBvals, fitype, ploter, W);
            
            for i = 1:outnum
            res_pixels(r, i, q) = dtmp(i);
         
            end
        end
    end
return