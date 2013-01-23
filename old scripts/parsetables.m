%Given the number of processors, we sort out the table array a new
%structure that is per processor new version

function outputable = parsetables(table, numCPU)
  
tsize = size(table);
numfiles = tsize(1);
numfields = tsize(2);
tablesize = numfiles/numCPU;

%Totalfiles = numfiles


if(tablesize < 1)
  numCPUused = numfiles;
end

numCPUused = numCPU;
%averagefilesperStack = tablesize

counter = 0;

  
  %for k = 1:numCPUused
    for i = 1:ceil(tablesize)
      
      for k = 1:numCPUused
      if((counter  < numfiles)) 
        counter = counter + 1;
        
          for j = 1:numfields
            
            %hello = table{counter, j}
            counter ;
            j;
            outputable(k).table{i,j} = table{counter, j};
        
          end
         
          
          
       
      else
        %return;
      end
      end
    end
  %end
  WorkerandSize = [];
  for h = 1:numCPUused
    WorkerandSize = [WorkerandSize h];
    CPUWorkerNumber = h;
    WorkerSize = size(outputable(h).table);
    WorkerSize = WorkerSize(1);
    WorkerandSize = [WorkerandSize WorkerSize];
  end
  
  %WorkerandSize
  
  