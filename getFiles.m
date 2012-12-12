%Given a root directory, a root file name and an extension, the returns
%the output of the dirr function and the total number of files found

%eg. [a b c d] = getFiles('/data/ADC', '530nov07.Lg1', 'nii')
%/data/ADC/ms05_30nov07/530nov07.Lg1_4/530nov07.Lg1_4.nii is one file
%that is returned

%NOTE: 10 before 3 in file listing



function [f, b, n, total] = getFiles(direm, rootfile, index, ext)
  
  if(index == 0)
    indext = '';
  else
    indext = int2str(index);
  end
  
  
  searchexp = ['\<' rootfile '.*' [indext '.' ext] '\>'];
  
  [f, b, n] = dirr(direm, searchexp, 'name');
  
  
  
  total = size(n);
  total = total(2);
  