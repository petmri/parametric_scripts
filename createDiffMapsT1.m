function [adc] = createDiffMapsT1(filename, b_values, fitype, ploter, ...
                                noisepath, weight)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   createDiffmapsT1  -   calculate and create T1, R2 and Constant maps
%                       using y = So*(1-e^(-x/T1)+C exponential fitting
%
%   Parameters:     
%       filename  -  input image filename (required)
%       b-values  -  array of TR times (if this parameter is missing,
%                    program will try to read it from description field
%                    in the header of the input image(hdr.hist.descrip))
%       fitype    - The type of fit you want (default is simple ADC exp
%       fit)
%       plot      - The figures for each voxel fit is fitted (default is 0) 
%
%   Return value:
%       adc -   nx3x(widthxheight) array, where
%               n is number of slices
%               1st column contains calculated ADC values for each slice
%               2nd column contains calculated R2 error values
%               3rd column contains calculated So values
%
%   Output files (each output file will contain one image per slice):
%       T1_map_<filename>.nii
%       R2_map_<filename>.nii
%       So_map_<filename>.nii
%       C_map_<filename>.nii
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    if ~exist('filename','var'),
        error('Usage: [adc] = runDiffMode(filename, b-values');
    end
    
   
    

    nii = load_nii(filename);
    
    res = nii.hdr.dime.pixdim;
    res = res(2:4);

    if ~exist('b_values','var')
        fprintf('Getting b-values from header ... \n');
        b_values = str2num(nii.hdr.hist.descrip);
    end
    if strcmp(b_values, '')
        e1 = 'No b-values stored in header.  Enter b-values manually.  ';
        e2 = 'Usage: [adc] = runDiffMode(filename, b-values)';
        error(strcat(e1, e2));
    end

    dim = size(nii.img);
    width = dim(1);
    height = dim(2);
    slices = dim(3);
    numBvals = length(b_values)
    numImages = slices/numBvals
    
    if(numBvals == 2)
       fitype = 'linearsimp';
    end
    
    inputimage = nii.img;
    
    %Adding in noise calculations --- NEED TO IMPLEMENT EXTRACTROI
    %MASKING--DONE
    noisepath
    d = dir(noisepath)
    sizer = size(d,1)
    
     
   
    
    
    if(sizer == 0 || weight == 0) 
      
    
      realnoisenii = ones(width,height,numImages*numBvals);
    else
        noisepath = strrep(noisepath, 'lnoisefill*', d(1).name);
      noisenii = load_nii(noisepath);
      disp('Noise Matrix loaded')
      noisenii = noisenii.img;
      
      
      sizerb = size(noisenii);
      
      g = find(noisenii ~= 0);
      if(size(g,1) == 0)
         realnoisenii = ones(width,height,numImages*numBvals);
      else
  
      
      for i = 1:width
        for j = 1:height
          for k = numImages*numBvals
        
            if(noisenii(i,j,1) == 1)
              realnoisenii(i,j,k) = inputimage(i,j,k);
            else
              
            end
          end
        end
      end
      
      
      
      %{
      for i = 1:slices
        realnoisenii(:,:,i) = int16(noisenii(:,:,1)).*inputimage(:,:,i);
        noisetemplate(:,:,i) = noisenii(:,:,1);
      end
      %}
     
      end
      
      
    end

   
   % return
%  Perform actual calculations 
    adc = calculateDiff(nii.img, b_values, width, height, slices, numBvals, ...
                        numImages , fitype, ploter, realnoisenii);
   
%  Saving calculated maps

     
 %   nii.hdr.dime.dim(4) = numImages;
  %  nii.hdr.dime.pixdim = [0 1.0 1.0 1.0 0 0 0 0];
   % nii.hdr.dime.datatype = 16; %real type
   % nii.hdr.dime.bitpix = 32; %32-bit
   % nii.hdr.hist.descrip = b_values; %save b-values in header
    % Do the same for nii.original (needed for later conversion to Analyze)
   % nii.original.hdr.dime.dim(4) = numImages;
   % nii.original.hdr.dime.pixdim = [0 1.0 1.0 1.0 0 0 0 0];
   % nii.original.hdr.dime.datatype = 16;
   % nii.original.hdr.dime.bitpix = 32;
   % nii.original.hdr.hist.descrip = b_values;

    adc_img = zeros(width, height, numImages);
    r2_img = zeros(width, height, numImages);
    so_img = zeros(width, height, numImages);
    
    if(strcmp(fitype, 'ackerman'))
        sig_img = zeros(width, height, numImages); 
    elseif(strcmp(fitype, 'acksimp'))
        sig_img = zeros(width, height, numImages); 
    else
    end
    
    
%  Change the structure of array to match nifti image format
%{
    for i=1:width
      for j=1:height
          for k=1:numImages
              adc_img(i, j, k) = adc(k, 1, (j-1)*width+i); 
              r2_img(i, j, k) = adc(k, 2, (j-1)*width+i);
              so_img(i, j, k) = adc(k, 3, (j-1)*width+i);
          end
      end
    end
    %}
    
    for k = 1:numImages
      for a = 1:(width*height)
         [i, j] = ind2sub([width height], a);
          adc_img(i, j, k) = adc(k, 1, a); 
          r2_img(i, j, k) = adc(k, 2, a);
          so_img(i, j, k) = adc(k, 3, a);
          if(strcmp(fitype, 'ackerman'))
          sig_img(i, j, k) = adc(k, 4, a);
          elseif(strcmp(fitype, 'acksimp'))
              sig_img(i, j, k) = adc(k, 4, a);
          else
          end
      end
    end
    
         
    nii = make_nii(adc_img, res, [], [], b_values);
    
    filename = strrep(filename, '.nii', '');
    g = findstr(filename, '/');
    h = size(g);
    h = h(2);
    g = g(h);
    
    if(g > 0) 
    strdir = substr(filename, 0, g-1);
    strrecon = strrep(filename, ' ', '');
    strrecon = strrep(strrecon, strdir , '');
    strrecon = strrep(strrecon, '/','');
    else
        strdir = '';
    end
    
  
    
    adcfilename = strcat(strdir, '/', 'T1_map_', fitype,'_', strrecon, '.nii')
    
    save_nii(nii, adcfilename);
    


    nii = make_nii(r2_img, res, [], [], b_values);
    
    r2filename = strcat(strdir, '/', 'R2_map_',fitype,'_', strrecon, '.nii')
    save_nii(nii, r2filename );

    nii = make_nii(so_img, res, [],[], b_values);
    
    sofilename = strcat(strdir, '/', 'So_map_',fitype,'_', strrecon, '.nii')
    save_nii(nii, sofilename);
    
  
    
        cmd3 = ['chmod 777 ' adcfilename];
        cmd1 = ['chmod 777 ' r2filename];
        cmd2 = ['chmod 777 ' sofilename];
        
        system(cmd1);
        system(cmd2);
        system(cmd3);
        
         nii = make_nii(sig_img, res, [],[], b_values);
              sigfilename = strcat(strdir, '/', 'C_map_',fitype,'_', strrecon, '.nii')
              save_nii(nii, sigfilename);
              cmd4 = ['chmod 777 ' sigfilename];
              system(cmd4);
        
      

