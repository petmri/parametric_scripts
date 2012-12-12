%T2 Version 2009 March
warning off all
clear all
%matlabpool close

%Section 1 - General Info

email = 'flomato@gmail.com';

%Log name
jobname = 'tommyT2';

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
affil = 'SURF2011'

%numCPU - if single then it defaults to 1
numCPU =7;

%NIFTIpath
niftpath = '/home/tommy/scripts/matlabcode/niftitools/';

%Where the scripts are
scriptspath = '/data/scripts/RARET1';
path(path, niftpath);
path(path, scriptspath);

%Status
status = 'DCE';
config = 'local';


%TR values
D1      = [600 1134.865 1766.473 2537.723 3528.416 4915.378 7246.633 17500];
D1      = [402.37 799.666 1257.723 1798.546 2458.787 3306.579 4492.698 ...
	6483.102 15000];
D1      = [11.49 22.98 34.48 45.97 57.46 68.95 80.44 91.94 103.43 114.92 126.41 137.90 149.40 160.89 172.38 183.87 195.36 206.86 218.35 229.84];
D1      = [10.5 21 31.5 42 52.5 63];
%Indices of b_values to be processed

%indD3  = [3];


%Dates
dateAA = [20090801:20090831 20090901:20090931 20091001:20091031 20091101:20091131 20091201:20091231];%[20091029]%:20090730];
dateA  = [20100206];
dateA = [20110617];%:20100129 20100201]%:20090721];%20080730];
%dateA  = [dateAA];% dateA];
%subjects = {'hs01_12may08', 'hs02_12may08', 'hs01_16may08', 'hs02_16may08', ...
%'hs04_16may08'}

subjects = {'hs01_11jul08','hs02_11jul08', 'hs03_11jul08', 'hs04_11jul08','hs05_11jul08','hs06_11jul08'};
subjects = {'hs01_12may08','hs02_12may08', 'hs01_16may08', 'hs02_16may08','hs04_16may08','hs01_16may08'};
subjects = {'hs04_07oct08', 'hs02_07oct08'};%, 'hs03_05dec08', 'hs04_dec08'};
subjects = {'hs03_24feb09','hs02_24feb09','hs02_23feb09', ...
	'hs01_23feb09', 'water', 'hs04_24feb09', 'hs05_24feb09'};
subjects = {'tn03_01jun11'};
%subjects = { 'ba04_07jun10','ba01_25may10', 'ba01_07jun10', 'ba03_07jun10','ba05_07jun10', 'ba01_07jun10'};
%subjects =  {'hs01_30jun09', 'hs02_30jun09', 'hs03_30jun09', 'hs05_30jun09', 'tn01_14aug09', 'tn03_14aug09', 'tn06_14aug09'};% 'tn01_12mar10', 'tn03_12mar10', 'tn04_12mar10'};%{'MD_LEG_TUMOR'}%, 'hs02_15jan10', 'hs03_15jan10', 'hs04_15jan10'} ;%'hs03_13nov09', 'hs04_13nov09', 'hs05_13nov09', 'hs01_02oct09', 'hs03_02oct09', 'hs04_02oct09', 'hs07_02oct09', 'hs01_13nov09', 'hs01_24nov09', 'hs02_24nov09' , 'hs03_24nov09' , 'hs04_24nov09' , 'hs05_24nov09'};%{'MD_LEG_TUMOR'};%, 'hs04_02oct09'};%, 'tn06_14aug09'};%, 'hs04_30jun09', 'hs06_30jun09'}
index = 04;



if(~strcmp(status, 'single'))
	
	matlabpool('open', config,  numCPU);
end


for j = 1:size(subjects, 2)
	subjB = subjects{1,j};
	for i = 1:size(dateA,2)
		dateB = num2str(dateA(i));
		
		disp(['Date:' dateB '_Subject:' subjB]);
		
		
		
		
		
		errorlog = processT1(dateB, subjB, index,  D1, 1, dire, affil, 'mode', status,'jobm', 'extraCPU', ...
			'jobcfg', 'multiADC', 'ADCpath', scriptspath, ...
			'numCPU', numCPU, 'bnought', 0, 'separate', 1)
		
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

sendmail(email,'T2 star map Processing completed',['Hello! Your job from is done! ' ...
	']from_' starttime '_to_' endtime], logname);
