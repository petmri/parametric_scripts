%processADC makes everything for one file

%function errorlog = processADC(dateA, subjectA, index, b_val, core, affil, varagin)





function errorlog = processT1(dateA, subjectA, index, b_val, directions, ...
	core, affil, varargin)
%{
  partial, partindex, ...
                               fitype, ploter,isotropic, separate, ...
                               directions,partdir, dirindex,partslice, ...
                               sliceind, status, jm, config, ADCpath, numCPUhold, core, affil, mask)
  
  
  dateA: The Date in question
  subjectA: The subject name
  b_val: The b value matrix
  fitype: Fitype
  ploter: plot diagrams?
  isotropic: make a isotropic map
  separate: Save each directions by themselves
  status: single or DCE
  index is the ADC file in the sequence
	%}
	
	errorlog = '';
	
	
	possibleinputs = {'mode'; 'jobm'; 'jobcfg'; 'ADCpath'; 'ploter';'numCPU'; ...
		'fitype'; 'mask'; 'separate'; 'isotropic'; 'bnought'; 'indD'};
	
	bnought = 0;
	status  = 'single';
	jm      = 'extraCPU';
	config  = 'multiADC';
	ADCpath = '/data/scripts/MSMET2';
	ploter      = 0;
	numCPUhold  = 1;
	fitype  = 'linearsimp';
	mask    = 0;
	separate= 0;
	isotropic = 1;
	niftpath = '/home/tommy/scripts/matlabcode/niftitools/';
	
	indy = find_str_cell(varargin, 'bnought', 'n', 'n');
	if(sum(indy(:))  == 1)
		x = find(indy == 1);
		bnought = varargin{x+1};
	end
	
	indy = find_str_cell(varargin, 'niftpath', 'n', 'n');
	if(sum(indy(:))  == 1)
		x = find(indy == 1);
		niftpath = varargin{x+1};
	end
	
	indy = find_str_cell(varargin, 'isotropic', 'n', 'n');
	if(sum(indy(:))  == 1)
		x = find(indy == 1);
		isotropic = varargin{x+1};
	end
	indy = find_str_cell(varargin, 'separate', 'n', 'n');
	if(sum(indy(:))  == 1)
		x = find(indy == 1);
		separate = varargin{x+1};
	end
	indy = find_str_cell(varargin, 'mask', 'n', 'n');
	if(sum(indy(:))  == 1)
		x = find(indy == 1);
		mask = varargin{x+1};
	end
	indy = find_str_cell(varargin, 'fitype', 'n', 'n');
	if(sum(indy(:))  == 1)
		x = find(indy == 1);
		fitype = varargin{x+1};
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
	indy = find_str_cell(varargin, 'indD', 'n', 'n');
	if(sum(indy(:))  == 1)
		x = find(indy == 1);
		indD = varargin{x+1};
	end
	
	%Not ADC
	isotropic = 0;
	
	try
		
		
		
		
		%Find the file
		
		if(strcmp(index, 'all'))
			indext = 0;
		else
			indext = index;
		end
		
		indext
		
		numB      = size(b_val, 2);
		bvalname = strcat(num2str(numB), 'B');
		inpatha = fullfile(core, affil, subjectA, dateA);
		
		DD = dir(inpatha)
		
		for qw = 1:numel(DD)
			DD(qw).name
			if((~strcmp(DD(qw).name, '.') && ~strcmp(DD(qw).name, '..')) && DD(qw).isdir)
				
				inpath = fullfile(inpatha, DD(qw).name, 'T2star');
				
				
				fprintf(['Inpath: ' inpath '\n']);
				
				
				[f,b,n,tot] = getFiles(inpath, strcat(dateA, '_', DD(qw).name,'_',subjectA), indext, '*nii');
				
				
				tot
				
				if(tot > 1)
					disp([ 'More than one matching file: check '  dateA '_' subjectA]);
				elseif(tot < 1)
					% disp(['No files Found: ' dateA '-' subjectA]);
					
				else
					disp([ 'One File found matching: ' dateA '-' subjectA]);
				end
				
				if(mask == 1)
					
					[g,c,m,tou] = getFiles(inpath, strcat(dateA, '_', subjectA, '_mask'), ...
						indext, '.img');
					
					if(tou ~= tot)
						error('Number of masks do not equal Files');
					end
				end
				
				%tot = 1;
				
				for i = 1:tot
					tic
					
					imagefile = n{i}
					
					%imagefile = '/data/studies/PETMRI/attenuation/20080618/ADC/20080618_attenuation_ADC_01.nii';
					
					[qw, filename]  = fileparts(imagefile);
					
					
					nii = load_nii(imagefile);
					
					res = nii.hdr.dime.pixdim;
					res = res(2:4);
					imagea = nii.img;
					size(imagea);
					
					%% T2 file with MSME, so we reshape it
					numTE = numB;
					
					slices = size(imagea, 3) / numTE;
					reshapedimage = [];
					checks = [1:numTE:size(imagea,3)];
					for i = 1:numTE
						slicecount = [1:slices];
						if(i == 1)
							reshapedimage(:,:,slicecount) = imagea(:,:,checks + i-1);
						else
							checks+i-1;
							reshapedimage(:,:,end+slicecount) = imagea(:,:, checks+i-1);
							
						end
						
					end
					
					imagea = reshapedimage;
					
					% AAA = make_nii(imagea);
					% save_nii(AAA, strrep(imagefile, '.nii', 'ordered.nii'));
					%
					%
					%     strrep(imagefile, '.nii', 'ordered.nii')
					
					%%
					
					
					
					if(size(directions, 2) == 1)
						numDIR = directions(1);
					else
						numDIR    = size(directions, 1);
					end
					
					
					factora = numB*numDIR;
					
					factora;
					
					numB;
					
					
					numslices = size(imagea, 3)/factora;
					
					
					
					w = size(imagea,1);
					h = size(imagea, 2);
					z = numslices*numB;
					
					if(mask == 1)
						maskfile = m{i};
						mii      = load_nii(maskfile);
						maskimage= mii.img;
						maskimage = maskimage(:,:, [1:numslices]);
						
						if(size(maskimage,1) == w && size(maskimage,2) == h && size(maskimage,3) ...
								== numslices)
						else
							error('Mask dimensions do not equal image')
						end
					else
						maskimage = ones(w,h,numslices);
					end
					
					
					%Derive the noise matrix
					noisemat = setnoise(inpath, w, h, z, imagea);
					
					%Initialize Directions
					
					if(isotropic == 1)
						SADCiso = zeros(size(imagea,1), size(imagea,2), numslices);
					end
					
					if(bnought)
						Bzero(:,:,[1:numslices])     = imagea(:,:,[1:numslices]);
						numB = numB-1;
					end
					
					
					
					%Process Each direction
					
					imagec = zeros(size(imagea,1), size(imagea,2), numDIR*numslices);
					imageR = zeros(size(imagea,1), size(imagea,2), numDIR*numslices);
					imageS = zeros(size(imagea,1), size(imagea,2), numDIR*numslices);
					
					if(numB < 1)
						error('Not enough TR-values');
					end
					
					numDIR
					
					for i = 1:numDIR
						
						if(bnought)
							imageb(:,:,[1:numslices]) = Bzero;
							slicefactor = numslices;
							%b_val = [0 b_val];
						else
							slicefactor = 0;
						end
						
						numslices;
						
						slicefactor;
						
						totalslices = [1:numslices*(numB)];
						
						actualslices = slicefactor+i.*totalslices;
						size(imagea)
						
						
						imageb(:,:,slicefactor+totalslices) = imagea(:,:,actualslices);
						
						
						
						output = oneDIRT1(imageb, b_val,fitype, noisemat, maskimage, 'mode', status, ...
							'jobm', jm, 'jobcfg', config, 'ADCpath', ADCpath, 'numCPU',numCPUhold, 'bnought', bnought);
						
						D(i).output = output;
						
						D(i).outname = strcat(filename, 'DIR', num2str(i));
						
						SADC  = output.SADC;
						Szero = output.Szero;
						SR    = output.SR;
						SQ    = output.SQ;
						
						%       SADC(100:110);
						%       SR(1:10);
						
						if(isotropic == 1)
							SADCiso = SADCiso + SADC;
						end
						
						if(separate == 1)
							fullpathADC = fullfile(inpath, ['T2star_map_', fitype,'_', filename,'.nii'])
							fullpathR   = fullfile(inpath, ['R2_map_', fitype,'_', filename ...
								, '.nii'])
							fullpathSo   = fullfile(inpath, ['So_map_', fitype,'_', filename ...
								, '.nii'])
							fullpathC   = fullfile(inpath, ['C_map_', fitype,'_', filename ...
								, '.nii'])
							
							
							ADCdirnii = make_nii(SADC, res, [1 1 1], [], b_val);
							Rdirnii   = make_nii(SR, res, [1 1 1], [], b_val);
							Sodirnii  = make_nii(Szero, res, [1 1 1], [], b_val);
							SQdirnii  = make_nii(SQ, res, [1 1 1], [], b_val);
							save_nii(ADCdirnii, fullpathADC);
							save_nii(Rdirnii, fullpathR);
							save_nii(Sodirnii, fullpathSo);
							save_nii(SQdirnii, fullpathC);
							
						else
							
							imagec(:,:,(i-1)*numslices + [1:numslices]) = SADC;
							imageR(:,:,(i-1)*numslices + [1:numslices]) = SR;
							imageS(:,:,(i-1)*numslices + [1:numslices]) = Szero;
						end
						
						
					end
					
					%Save if not separate
					if(separate ~= 1)
						fullpathADC = fullfile(inpath, ['T2_map_', fitype,'_all', filename, ...
							'.nii'])
						fullpathR   = fullfile(inpath, ['R2_map_', fitype,'_all', filename, ...
							'.nii'])
						fullpathSo   = fullfile(inpath, ['So_map_', fitype,'_', filename ...
							, '.nii'])
						
						ADCnii = make_nii(imagec, res, [], [], b_val);
						Rnii   = make_nii(imageR, res, [], [], b_val);
						Sodirnii  = make_nii(Szero, res, [], [], b_val);
						
						save_nii(ADCnii, fullpathADC);
						save_nii(Rnii, fullpathR);
						save_nii(Sodirnii, fullpathSo);
					end
					
					
					%Save if isotropic
					if(isotropic == 1)
						
						SADCiso = SADCiso./numDIR;
						
						isonii = make_nii(SADCiso, res, [], [], b_val);
						
						
						fullpath = fullfile(inpath, ['ISOADC_map_', fitype,'_', filename, '.nii'])
						
						save_nii(isonii, fullpath);
						
					end
					toc
					disp('Total For 1 file');
				end
			end
		end
		
		
		
	catch myEx
		disp(myEx.message)
		
		errorlog = myEx.message;
	end
	
	