%Wrapper function for calculateMap

function [single_IMG, submit, dataset_num, errormsg] = calculateMap_batch(JOB_struct, submit, dataset_num)


 
 if submit
     % Lodging a batch job
      file_list  = JOB_struct(1).file_list;
     for i = 1:numel(file_list)
         CUR_JOB    = JOB_struct;
         CUR_JOB(1).file_list = {};
         CUR_JOB(1).file_list(1) = file_list(i);
         CUR_JOB(1).submit    = 1;
         
         % Check if the relevant dataset is to be made
         to_do = file_list(i).to_do;
         
         if(to_do)
         [single_IMG, errormsg] = calculateMap(CUR_JOB);
         else
         end
     end
 else
     %Checking a particular Map
     
     CUR_JOB    = JOB_struct;
     file_list  = JOB_struct(1).file_list;
     CUR_JOB(1).file_list = file_list(dataset_num);
     CUR_JOB(1).submit    = 0;
     [single_IMG, errormsg] = calculateMap(CUR_JOB);

 end
     


