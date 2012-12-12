%Using DCE to process ADC files
%Version 1.1 January 2008

clear all
warning off

starttime = int2str(fix(clock));

fprintf(['Starting time is: ' starttime '\n']);

%Section 1 - General Info

    email = 'flomato@gmail.com';
    %Log name
    jobname = 'tommyADC';
    
    %DCE or single
    status = 'DCE';

%Section 2 = Directory Dependencies and CPU usage

    %Core dir
    dire = '/data/ADC';

    %numCPU - if single then it defaults to 1
    numCPU = 2;

    %NIFTIpath
    niftpath = '/home/tommy/scripts/matlabcode/niftitools/';
    
    %Where the scripts are
    scriptspath = '/data/scripts/ADC/processing';

%Section 3 - Input data values for job

    %b values arrays
s7 = [1.771465 101.771465 301.771465 501.771465 701.771465 901.771465 1301.771465];
b7   = [1.771465 101.771465 301.771465 501.771465 701.771465 901.771465 ...
           1001.771465];
D2      = [1.688815 701.688815];

preset = {s7 b7 D2};

alt = {b7 D2 s7};

     %Filename

     %NOTE: 10 before 3 in file listing - alter the bvalue array
     %assignment accordingly!!!
%{
filenames = {'ms0107j.Ll1' , preset; 'ms0107j.Lm1' , preset; 'ms0107j.Ln1', preset; 'ms0107j.Lo1', preset; 'ms0207j.Ll1', preset;'ms0207j.Lm1', ...
            preset; 'ms0207j.Ln2', preset; 'ms0207j.Lo1', preset; ...
             'ms0307j.Ll1', preset; 'ms0307j.Lm1', preset; 'ms0307j.Ln1', ...
            preset; 'ms0307j.Lo1', preset; 'ms0407j.Ll1', preset; ...
             'ms0407j.Lm1', preset; 'ms0407j.Ln1', preset; 'ms0407j.Lo1', ...
            {b7 D2 s7}};
%}

filenames = {'ms0207j.Ln2', preset;  ...
             'ms0307j.Ll1', preset; 'ms0307j.Lm1', preset; 'ms0307j.Ln1', ...
            preset; 'ms0307j.Lo1', preset; 'ms0407j.Ll1', preset; ...
             'ms0407j.Lm1', preset; 'ms0407j.Ln1', preset; 'ms0407j.Lo1', ...
            {b7 D2 s7}};


filenames = {'ms0207j.Ln2', preset;  ...
             'ms0307j.Ll1', preset; 'ms0307j.Lm1', preset};


%filenames = { 'ms0407j.Lo1', alt};

%---------------------------------------
%Under the table
%This Stuff parses the files for the createDiffmaps
if(strcmp(status, 'DCE') ~= 1)
  numCPU = 1;
else
end

total = size(filenames);
total = total(1);

totalFiles = 0;

for i = 1:total
  

  
  [f, b, n, tot] = getFiles(dire, filenames{i,1}, 'nii');
  
  %return
  tot;
  
  bvaluelist = filenames{1,2};
  
  for j = 1:tot
    totalFiles = totalFiles + 1;
    
    [p,ne, e, v] = fileparts(n{j});
    fb(totalFiles).filenames = n{j};
    fb(totalFiles).bvalues   = bvaluelist{j};
    fb(totalFiles).direct    = [p];
  end
  
end

fprintf(['\n Total Files processed in this job: ' int2str(totalFiles) '\n']);

out1 = genADCtable(fb);

%return

numCPUreal = numCPU;

%Comment out if you want to go back to 1 job per worker
numCPU = totalFiles;

numCPUhold = min(numCPU, numCPUreal);

outputable = parsetables(out1, numCPU);

if(strcmp(status, 'DCE'))
%Change Jobmanager settings for CPU usage
 jm = findResource('scheduler','type', 'jobmanager', 'Name', 'extraCPU','configuration','multiCPU')
 
 j = createJob(jm, 'Name', 'Immuneparajob');
 
 set(j, 'PathDependencies', {[dire, niftpath, scriptspath]});
 
 
 for i = 1:numCPU
   pathing = outputable(i);
   pathing1 = pathing.table;

   tsize1 = size(pathing1);
   tsize1 = tsize1(1);
   CPUnumber = i;
   filesAssigned = tsize1;
   
   %fprintf(['CPU number:' int2str(CPUnumber) '_Has:' int2str(filesAssigned) ...
   %         '_files\n']);

  
   t(i).t = createTask(j, @createDiffmapsDCE, 1, {outputable(i)}, 'FinishedFcn', ...
                  @clientTaskCompleted, 'configuration', 'multiCPU');

   for k = 1:tsize1   
     hello = get(j, 'PathDependencies');
     size(hello);
     hello = [hello; pathing1{k,3}];
     set(j, 'PathDependencies', hello);
   end
 
 end
 
 set(j, 'MaximumNumberOfWorkers', numCPUhold);
 set(j, 'MinimumNumberOfWorkers', numCPUhold);
 set(j, 'RestartWorker', true);

fprintf('\n')
fprintf('Now Submitting job\n\n');
submit(j)
 
waitForState(j, 'finished')

fprintf('Job Done! Error Checking\n\n')

results = getAllOutputArguments(j);
else

  p = genpath(scriptspath);
 
  h = genpath(niftpath);
  q = genpath(dire);
  path([p,h,q],path);
  results = createDiffmapsDCE(outputable);
end

  
rnum = size(results);
rnum = rnum(1);
 
if(rnum ~= numCPU )
  error('Output does not equal input')
elseif (anyempty(results))
  Status = 'Error in Worker process'
else
  
end

for i = 1:numCPU

a = t(i).t;
ER = a.ErrorMessage;
in = a.InputArguments;

if(isempty(ER))
  %return;
else
  
  in = in{1};
  in = in.table;
  fi = in{1};
  b = in{2};
  
    fprintf(['Error with file: ' fi ' with B-values: ' b ' with Error Message: ' ER '\n']);
end

end

  

%p = genpath('/data/scripts/testing');
%path(path,p);

%plotTasks(j);

if(strcmp(status, 'DCE'))
destroy(j);
end

logtable = outputable;

jobname = [jobname '_' datestr(now, 'yyyy_mm_dd_HH_MM')];

jobname = fullfile('/data/log', [jobname '.log',''] );

save(jobname, 'logtable');

fprintf(['Finished ADC processing. Log of this is stored at:' jobname '\n'])

%Email the person on completion
% Define these variables appropriately:
mail = 'immune.caltech@gmail.com'; %Your GMail email address
password = 'antibody'; %Your GMail password

% Then this code will set up the preferences properly:
setpref('Internet','E_mail',mail);
setpref('Internet','SMTP_Server','smtp.gmail.com');
setpref('Internet','SMTP_Username',mail);
setpref('Internet','SMTP_Password',password);
props = java.lang.System.getProperties;
props.setProperty('mail.smtp.auth','true');
props.setProperty('mail.smtp.socketFactory.class', 'javax.net.ssl.SSLSocketFactory');
props.setProperty('mail.smtp.socketFactory.port','465');

endtime = int2str(fix(clock));

fprintf(['Ending time is:' endtime '\n']);

sendmail(email,'ADC Processing completed',['Hello! Your job from is done! ' ...
                    ']from_' starttime '_to_' endtime]);

  
  