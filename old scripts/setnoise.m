function noisemat = setnoise(inpath, width,height,z, inputimage)
  
   noisepath = strcat(inpath, '/lnoisefill*');
   
    d = dir(noisepath);
    sizer = size(d,1);
    
     
   
    
    
    if(sizer == 0) 
      
    
      realnoisenii = ones(width,height,z);
    else
      noisepath = strrep(noisepath, 'lnoisefill*', d(1).name);
      noisenii = load_nii(noisepath);
      disp('Noise Matrix loaded')
      noisenii = noisenii.img;
      
      
      sizerb = size(noisenii);
      
      g = find(noisenii ~= 0);
      if(size(g,1) == 0)
         realnoisenii = ones(width,height,z);
      else
  
      
      for i = 1:width
        for j = 1:height
          for k = z
        
            if(noisenii(i,j,1) == 1)
              realnoisenii(i,j,k) = inputimage(i,j,k);
            else
              
            end
          end
        end
      end
      
      
      
   
     
      end
      
      
    end
    
    noisemat = realnoisenii;