warning off
matlabpool local 4

p = genpath('/home/tommy');
t = genpath('/data/scripts');
path(p,path);

%createDiffMaps('0330nov07.KS1_10.nii', [ 1.688815 1001.688815 ]);
%createDiffMaps('0330nov07.KS1_3.nii', [1.771465 101.771465 301.771465 501.771465 701.771465 901.771465 1001.771465]);
%createDiffMaps('0330nov07.L01_7.nii', [1.771465 101.771465 301.771465 501.771465 701.771465 901.771465 1001.771465]);
%createDiffMaps('0330nov07.L01_8.nii', [ 1.688815 1001.688815 ]);


%cd('/data/ADC/ms05_30nov07')
%createDiffMaps('/data/ADC/ms05_30nov07/530nov07.KT1_4.nii', [1.771465 101.771465 301.771465 501.771465 701.771465 901.771465 1001.771465]);
%createDiffMaps('/data/ADC/ms05_30nov07/530nov07.KT1_5.nii', [ 1.688815 1001.688815 ]);
%createDiffMaps('/data/ADC/ms05_30nov07/530nov07.KT1_4.nii', [1.771465 101.771465 301.771465 501.771465 701.771465 901.771465 1001.771465]);
%createDiffMaps('/data/ADC/ms05_30nov07/530nov07.KZ2_5.nii', [1.771465 101.771465 301.771465 501.771465 701.771465 901.771465 1001.771465]);
%createDiffMaps('/data/ADC/ms05_30nov07/530nov07.KZ2_6.nii', [ 1.688815 1001.688815 ]);


%cd('/data/ADC/ms01_30nov07/')
createDiffMaps('/data/ADC/ms01_30nov07/30nov07.KU1_6.nii', [1.771465 101.771465 301.771465 501.771465 701.771465 901.771465 1001.771465]);
createDiffMaps('/data/ADC/ms01_30nov07/30nov07.KU1_7.nii', [ 1.688815 1001.688815 ]);
%createDiffMaps('/data/ADC/ms01_30nov07/30nov07.KZ2_4.nii', [1.771465 101.771465 301.771465 501.771465 701.771465 901.771465 1001.771465]);
%createDiffMaps('/data/ADC/ms01_30nov07/30nov07.KZ2_5.nii', [ 1.688815 1001.688815 ]);


%cd('/data/ADC/ms02_30nov07/')
%createDiffMaps('/data/ADC/ms02_30nov07/0230nov07.KT1_5.nii', [1.771465 101.771465 301.771465 501.771465 701.771465 901.771465 1001.771465]);
%createDiffMaps('/data/ADC/ms02_30nov07/0230nov07.KT1_6.nii', [ 1.688815 1001.688815 ]);
%createDiffMaps('/data/ADC/ms02_30nov07/0230nov07.KY3_4.nii', [1.771465 101.771465 301.771465 501.771465 701.771465 901.771465 1001.771465]);
%createDiffMaps('/data/ADC/ms02_30nov07/0230nov07.L01_4.nii', [1.771465 101.771465 301.771465 501.771465 701.771465 901.771465 1001.771465]);
%createDiffMaps('/data/ADC/ms02_30nov07/0230nov07.L01_5.nii', [ 1.688815 1001.688815 ]);

%}


matlabpool close

 %Email the person on completion
% Define these variables appropriately:
mail = 'immune.caltech@gmail.com'; %Your GMail email address
password = 'antibody'; %Your GMail password
email = 'flomato@gmail.com';
% Then this code will set up the preferences properly:
setpref('Internet','E_mail',mail);
setpref('Internet','SMTP_Server','smtp.gmail.com');
setpref('Internet','SMTP_Username',mail);
setpref('Internet','SMTP_Password',password);
props = java.lang.System.getProperties;
props.setProperty('mail.smtp.auth','true');
props.setProperty('mail.smtp.socketFactory.class', 'javax.net.ssl.SSLSocketFactory');
props.setProperty('mail.smtp.socketFactory.port','465');

endtime = int2str(fix(clock))

sendmail(email,'ADC Processing completed',['Hello! Your job from is done!']);



