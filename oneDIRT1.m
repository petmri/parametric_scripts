%Version 1 in RAREvTR processing.
%Processes 1 image in one Direction
% oneDIRADC(A, B, 'linearsimp', 0, ones(5,5,10), 'single', 'extraCPU', 'multiCPU', '/data/scripts/ADC/processing')


function output = oneDIRT1(imagea, b_values, fitype, noise, mask, varargin)

%ploter, noise, status, ...
%                         jm, config, ADCpath, numCPUhold, mask)

possibleinputs = {'mode'; 'jobm'; 'jobcfg'; 'ADCpath'; 'ploter';'numCPU'; 'bnought'};

%     bnought = 1;
%      indy = find_str_cell(varargin, 'bnought', 'n', 'n');
%      if(sum(indy(:))  == 1)
%        x = find(indy == 1);
%        bnought = varargin{x+1};
%      end

%      if(bnought)
%          actualbval = size(b_values,2) - 1;
%      else
actualbval = size(b_values,2);
%end

width    = size(imagea,1);
length   = size(imagea,2);
slices   = size(imagea, 3)/ actualbval;
total    = width*length*slices;
numBvals = size(b_values, 2);
b_values;
factor = -10;


ADCpath = '/home/thomasn/scripts/MGET2star';
ploter      = 0;
numCPUhold  = 1;
niftpath = '/home/thomasn/scripts/niftitools/';


indy = find_str_cell(varargin, 'niftpath', 'n', 'n');
if(sum(indy(:))  == 1)
	x = find(indy == 1);
	niftpath = varargin{x+1};
end

indy = find_str_cell(varargin, 'mode', 'n', 'n');
if(sum(indy(:))  == 1)
	x = find(indy == 1);
	status = varargin{x+1};
end

indy = find_str_cell(varargin, 'jobm', 'n', 'n');
if(sum(indy(:))  == 1)
	x = find(indy == 1);
	jm = varargin{x+1};
end

indy = find_str_cell(varargin, 'jobcfg', 'n', 'n');
if(sum(indy(:))  == 1)
	x = find(indy == 1);
	config = varargin{x+1};
end

indy = find_str_cell(varargin, 'ADCpath', 'n', 'n');
if(sum(indy(:))  == 1)
	x = find(indy == 1);
	ADCpath = varargin{x+1};
end
indy = find_str_cell(varargin, 'ploter', 'n', 'n');
if(sum(indy(:))  == 1)
	x = find(indy == 1);
	ploter = varargin{x+1};
end
indy = find_str_cell(varargin, 'numCPU', 'n', 'n');
if(sum(indy(:))  == 1)
	x = find(indy == 1);
	numCPUhold = varargin{x+1};
end


%Make Weighting Matrix
W = ones(1,numBvals);
sizera = size(noise);

for i = 1:numBvals
	noisevolume = zeros(sizera(1), sizera(2), slices);
	k = 1;
	for j = 1:slices
		(j-1)*numBvals+i;
		noisevolume(:,:,k) = noise(:,:,(j-1)*numBvals+i);
		k = k+1;
	end
	
	noisevolume = noisevolume(:);
	onlynoisevolume = noisevolume;
	newnoisevolume = std(onlynoisevolume);
	
	if(newnoisevolume == 0)
		W(1,i) = 1;
	else
		W(1,i) = 1/(newnoisevolume)^2;
	end
end
clear noisevolume
clear newonoisevolume
clear onlynoisevolume

W;

%Fitype
if(size(b_values, 2) == 2)
	fitype = 'linearsimp';
end

%Calculate the output


%Find the indices for the masked ROI
found = find(mask == 1);
size(found);
width*length*slices;




fprintf(['Width:' num2str(width) ' Height:' num2str(length) ' Slices:' ...
	num2str(slices) ' Total Pixels:' num2str(total) '\nB-value:' ...
	num2str(b_values) ' \nNon-mask Factor:' num2str(factor) ['\nMasked ' ...
	'Pixels:'] num2str(sum(mask(:))) ' Weighting Mat:' num2str(W) ' Fitype:' fitype ' NumCPU:' num2str(numCPUhold) '\n']);

tic


%Modified for neuroecon
xdata{1}.b_values = b_values;
xdata{1}.found    = found;
xdata{1}.W        = W;
xdata{1}.fitype   = fitype;
xdata{1}.ploter   = ploter;
xdata{1}.slices   = slices;
xdata{1}.numBvals = numBvals;
xdata{1}.imagea   = imagea;
xdata{1}.found    = found;
numvoxels = numel(found);
xdata{1}.numvoxels = numvoxels;

neuroecon = 0;



if(neuroecon)
	%Schedule object, neuroecon
	
	sched = findResource('scheduler', 'configuration', 'NeuroEcon.local');
	set(sched, 'SubmitArguments', '-l walltime=12:00:00 -m abe -M thomasn@caltech.edu')
	
	
	warning off
	
	p = pwd;
	n = '/home/thomasn/scripts/niftitools';
	
	
	
	j = createMatlabPoolJob(sched, 'configuration', 'NeuroEcon.local','PathDependencies', {p})
	set(j, 'MaximumNumberOfWorkers', 20);
	set(j, 'MinimumNumberOfWorkers', 1);
	createTask(j, @MGET2starfitfnhelper, 1,{xdata, numvoxels});
	
	submit(j)
	waitForState(j)
	results = getAllOutputArguments(j)
	destroy(j);
	
	Sout = cell2mat(results);
else
	
	Sout = MGET2starfitfnhelper(xdata, numvoxels);
	
	size(Sout)
end
t2_fit					 = Sout(:,1);
rho_fit					 = Sout(:,2);
r_squared				 = Sout(:,3);
confidence_interval_low	 = Sout(:,4);
confidence_interval_high = Sout(:,5);

toc

disp('DONE with T2 fitting')
%
%     SADCA(100:110);
%     SRA(1:10);

output.t2_fit					= reshape(t2_fit, [width, length, slices]);
output.rho_fit					= reshape(rho_fit,  [width, length, slices]);
output.r_squared				= reshape(r_squared, [width, length, slices]);
output.confidence_interval_low  = reshape(confidence_interval_low, [width, length, slices]);
output.confidence_interval_high = reshape(confidence_interval_high, [width, length, slices]);



