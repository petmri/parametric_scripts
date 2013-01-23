%combineFLASH.m
%Thomas Ng 21st April, 2009
%Combines the slices from multiple FLASH experiments into one.

path(path,'/home/tommy/scripts/matlabcode/niftitools');

%Data dir
home='/data/studies';

%Affliation eg. COH
afil='COH';

%Subject Name
subj={'tn05_10apr09'};

%Date
dat1=[20090421];

%---------------------------
%Path
pat1='T1map';

angle = [];
imag1 = [];
outname = [];
for i = 1:numel(subj)
  for j = 1:numel(dat1)
    
    inpath=fullfile(home, afil, subj{i}, num2str(dat1(j)), pat1);
    
    [g,c,m,tou] = getFiles(inpath,strcat(num2str(dat1(j)),'_',subj{i}, ...
                                         '_T1map'),'', '.nii');
    
    for k = 1:tou
      imagefile = m{k};
      
      nii = load_nii(imagefile);
      res = nii.hdr.dime.pixdim;
      res = res(2:4);
      ima = nii.img;
      size(ima);
      
      if(k == 1)
        imag1 = zeros(size(ima,1), size(ima,2),size(ima,3));
        imag1 = ima;
        
      else
        imag1(:,:,end+1:end+size(ima,3)) = ima;
      end
      
      %Find the angle of the image
      [qw, filename] = fileparts(imagefile);
      
      
      s2 = regexp(filename, '\_', 'split');
      angle(end+1) = str2num(char(s2(end)));
      
      if(k == 1)
        outname = strrep(imagefile,['_' char(s2(end))],'combined');
      end
    end
  end
end


nii = make_nii(imag1,res ,[1 1 1],512,num2str(angle));

save_nii(nii, outname);

angle

  
      
      
      
      
    
    
    
    
