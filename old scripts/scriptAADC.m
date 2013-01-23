%ADC Version 2008 September

clear all
 %matlabpool close
 
 %Section 1 - General Info

 email = 'flomato@gmail.com';
 
 %Log name
 jobname = 'tommyADC';
 
 %Log Info
 %Do not Alter these next few lines
 lognamebase = strcat('/data/log/log',jobname);
 logname = [lognamebase '_' datestr(now, 'yyyy_mm_dd_HH_MM') '.log'];
 diary(logname)
 
 starttime = int2str(fix(clock));
 fprintf(['Starting time is: ' starttime '\n']);
 %Core dir
 dire = '/data/studies';
    
 %Study Affiliation
 affil = 'COH';

 %numCPU - if single then it defaults to 1
 numCPU = 7;

 %NIFTIpath
 niftpath = '/home/tommy/scripts/matlabcode/niftitools/';
    
 %Where the scripts are
 scriptspath = '/data/scripts/ADC/processing';
 path(path, niftpath);
 path(path, scriptspath);
 
 %Status
 status = 'DCE';
 config = 'multiADC2';
 
  
 %Bvalues   
 D2      = [203.342276 903.342276];
    
 D3      = [3.132794 203.132794 803.132794];
    
 D5      = [1.771465 301.771465 501.771465 701.771465 1301.771465];
 
 D1      = [0 800 1200];
 
 %Indices of b_values to be processed
 
 %indD3  = [3];
 
 
 %Dates
 dateAA = [20090227 20090228];
 %dateA  = [20080719];
 dateA  = [dateAA];% dateA];
 %subjects = {'hs01_12may08', 'hs02_12may08', 'hs01_16may08', 'hs02_16may08', ...
             %'hs04_16may08'}
             
             subjects = {'hs01_11jul08','hs02_11jul08', 'hs03_11jul08', 'hs04_11jul08','hs05_11jul08','hs06_11jul08'};
             subjects = {'hs01_12may08','hs02_12may08', 'hs01_16may08', 'hs02_16may08','hs04_16may08','hs01_16may08'};
             subjects = {'hs04_07oct08', 'hs02_07oct08'}%, 'hs03_05dec08', 'hs04_dec08'};
             subjects = {'hs03_24feb09','hs02_24feb09','hs02_23feb09','hs01_23feb09', 'water', 'hs04_24feb09', 'hs05_24feb09'}
 index = 02;
 
 

 if(~strcmp(status, 'single'))
      
    matlabpool('open', config,  numCPU);
  end
 

  for j = 1:size(subjects, 2)
      subjB = subjects{1,j};
    for i = 1:size(dateA,2)
      dateB = num2str(dateA(i));
        
       disp(['Date:' dateB '_Subject:' subjB]);
    
    
    
  
            
     errorlog = processADC(dateB, subjB, index,  D1, 3, dire, affil, 'mode', status,'jobm', 'extraCPU', ...
                           'jobcfg', 'multiADC', 'ADCpath', scriptspath, ...
       'numCPU', numCPU, 'bnought', 1)
     
   end
 end
 
 if(~strcmp(status, 'single'))
      
   matlabpool('close', 'force', config);
 end
          
 
     
                
%Email the person on completion
% Define these variables appropriately:
mail = 'immune.caltech@gmail.com'; %Your GMail email address
password = 'antibody'; %Your GMail password
 %email = 'flomato@gmail.com';
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
diary off

sendmail(email,'ADC Processing completed',['Hello! Your job from is done! ' ...
                    ']from_' starttime '_to_' endtime], logname);
