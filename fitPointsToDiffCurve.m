function [diff] = fitPointsToDiffCurve(stack1, imageOffset, xyOffset, ...
                                       b_values, numBvals, fitype, ploter, ...
                                       W)
  
  %-------------------------------------
  % This takes out the voxel rep time series worth of data, fit the T1
  % equation to the curve and returns the diff object with the Szero, T1,
  % R2 and constant C from the fitting
  %-------------------------------------
    
   
                                   
    dim = size(stack1);
    width = dim(1);
    height = dim(2);
    slices = dim(3);
    
    
    
    %coordinates on the xy face
    [x, y] = ind2sub([width height], xyOffset);
    
    sigs = zeros(1, numBvals);
    %Hardwire for now
    %W    = ones(1,numBvals);
    
    %stack1 is in 7 bvalues x 3 slices orientation
    for i=1:numBvals
        sigs(1, i) = stack1(x,y, i + numBvals*(imageOffset-1));
    end
    
    b_values;
    sigs;
    W;
    
    %[cf_, gof] = ADCfitfn(b_values',sigs',W', fitype, ploter);
    [Szero, SR, ST1, SQ] = RAREVTRfit(b_values', sigs');
    %[cf_2, gof2] = ADCfitfn(b_values',sigs',W', 'simp', ploter);
    
    diff = zeros(1,4);
    diff(1) = ST1;
    diff(2) = SR;
    diff(3) = Szero;
    diff(4) = SQ;
    
    
    
return