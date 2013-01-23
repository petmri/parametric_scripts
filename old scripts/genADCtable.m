%Generate the pathtable given the filename and bvalue in a cell array

function outputable = genADCtable(fb)
  
  sizer = size(fb);
  sizer = sizer(2);
  
  names = fieldnames(fb);
  fields = size(names);
  fields = fields(1);
  
  for i = 1:sizer
    
    for j = 1:fields
      namer = names{j};
      %getfield(fb, {i}, namer)
      outputable{i,j} = getfield(fb, {i}, namer);
    end
    
    %error log
    outputable{i,fields+1} = '';
  end
  
  