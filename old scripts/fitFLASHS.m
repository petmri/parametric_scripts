TR = 400/1000;
moo = moo(:);
xdata{1}.TR = TR;
xdata{1}.alpha = angle.*(pi/180);


%configure the optimset for use with lsqcurvefit
options = optimset('lsqcurvefit');
 
%increase the number of function evaluations for more accuracy
options.MaxFunEvals = 5000;


[x, error] = lsqcurvefit(@FLASHS, [30000, 1/2], xdata, moo,[0 0],'',options);