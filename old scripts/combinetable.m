%Flatten the multiple tables

function logtable = combinetable(output, workers, numfields, totalfiles)
  
  counter = 1;
  
  output;
  logtable = cell(totalfiles, numfields);
  for i = 1:workers
    
    table = output(i).table;
    tsize = size(table);
    numfields = tsize(2);
    numfiles = tsize(1);
    for k = 1:numfiles
      if(not((totalfiles - counter) < 0))
        
        for j = 1:numfields
                 
        
                 
            logtable{counter,j} = table{k,j};
           
         
        end
        counter = counter + 1;
      else
      end
    end
  end
  