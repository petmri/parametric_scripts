%Runs createDiffMaps in DCE mode
function logtable = createDiffmapsDCE(table)
  table = table.table;
  tsize = size(table);
  tsize = tsize(1);
  
  logtable = table;
  
  for (i = 1:tsize)
  
    
  filename = table{i,1};
  bvalues  = table{i,2};
  direct   = table{i,3};
  fitype = table{i,4};
  ploter = table{i,5};
  weight = table{i,6};
  
  bvalues = bvalues{1};
  fprintf(['Filename is:' filename '\n']);
  fprintf(['B-values used (Integer Approximation):' int2str(bvalues) '\n']);
  
  noisepath = [direct '/lnoisefill*'];
  
  try
    
    
  
  [adc] = createDiffMapsT1(filename, bvalues, fitype, ploter, noisepath, ...
                         weight);
    catch myEx
      %status = myEx.message;
      disp(myEx.message);
      lastfield = size(table,2);
      
      logtable{i,lastfield} = [logtable{i,lastfield} ' : ' myEx.message];
      
    end
        
  
  end
  
  logtable;