% Performs different types of fits on exponential decay (T1, T2, and T2*) data
function fit_output = fitT2(te,fit_type,si,tr)

% Verify all numbers exists
ok_ = isfinite(te) & isfinite(si);
if ~all( ok_ )
	warning( 'GenerateMFile:IgnoringNansAndInfs', ...
		'Ignoring NaNs and Infs in data' );
end

% First do a fast sanity check on data, prevents time consuming fits
% of junk data
if(strcmp(fit_type,'t1_tr_fit'))
	ln_si = log((si-max(si)-1)*-1);
	Ybar = mean(ln_si(ok_)); 
	Xbar = mean(te(ok_));
	y = ln_si(ok_)-Ybar;
	x = te(ok_)-Xbar;
	%     slope =sum(x.*y)/sum(x.^2);
	%     intercept = Ybar-slope.*Xbar; %#ok<NASGU>
	r_squared = (sum(x.*y)/sqrt(sum(x.^2)*sum(y.^2)))^2;
	if ~isfinite(r_squared)
		r_squared = 0;
	end
elseif(strcmp(fit_type,'t1_fa_fit'))
	y_lin = si./sin(pi/180*te);
	x_lin = si./tan(pi/180*te);
	Ybar = mean(y_lin(ok_)); 
	Xbar = mean(x_lin(ok_));
	y = y_lin(ok_)-Ybar;
	x = x_lin(ok_)-Xbar;
	%     slope =sum(x.*y)/sum(x.^2);
	%     intercept = Ybar-slope.*Xbar; %#ok<NASGU>
	r_squared = (sum(x.*y)/sqrt(sum(x.^2)*sum(y.^2)))^2;
	if ~isfinite(r_squared)
		r_squared = 0;
	end
elseif(strcmp(fit_type,'linear_fast') || strcmp(fit_type,'t1_fa_linear_fit'))
	% Skip check as we are doing a fast linear fit
	r_squared = 2.0;
elseif(strcmp(fit_type,'t1_ti_exponential_fit'))
	% Skip check as no linearization exists
	r_squared = 2.0;
else
	ln_si = log(si);
	Ybar = mean(ln_si(ok_)); 
	Xbar = mean(te(ok_));
	y = ln_si(ok_)-Ybar;
	x = te(ok_)-Xbar;
	%     slope =sum(x.*y)/sum(x.^2);
	%     intercept = Ybar-slope.*Xbar; %#ok<NASGU>
	r_squared = (sum(x.*y)/sqrt(sum(x.^2)*sum(y.^2)))^2;
	if ~isfinite(r_squared)
		r_squared = 0;
	end
end

% Continue if fit is rational
if r_squared>=0.6
	if(strcmp(fit_type,'exponential'))
		% Restrict fits for T2 from 1ms to 2500ms, and coefficient ('rho') from 
		% 0 to inf
		fo_ = fitoptions('method','NonlinearLeastSquares','Lower',[0 -1],'Upper',[Inf   -.0004]);
		% The start point prevents convergance for some reason, do not use
% 		st_ = [si(end) -.035 ];
% 		set(fo_,'Startpoint',st_);
		%set(fo_,'Weight',w);
		ft_ = fittype('exp1');

		% Fit the model
		[cf_, gof] = fit(te(ok_),si(ok_),ft_,fo_);

		% Save Results
		r_squared = gof.rsquare;
		confidence_interval = confint(cf_,0.95);
		rho_fit = cf_.a;
		t2_fit   = -1/cf_.b;
		t2_95_ci = -1./confidence_interval(:,2);
	elseif(strcmp(fit_type,'linear_weighted'))
		% Restrict fits for T2 from 1ms to 2500ms, and coefficient ('rho') from 
		% 0 to inf
		fo_ = fitoptions('method','LinearLeastSquares','Lower',[-1 0],'Upper',[-.0004 Inf]);
		ft_ = fittype('poly1');
		set(fo_,'Weight',si);
		ln_si = log(si);

		% Fit the model
		[cf_, gof] = fit(te(ok_),ln_si(ok_),ft_,fo_);

		% Save Results
		r_squared = gof.rsquare;
		confidence_interval = confint(cf_,0.95);
		rho_fit = cf_.p2;
		t2_fit   = -1/cf_.p1;
		t2_95_ci = -1./confidence_interval(:,1);
	elseif(strcmp(fit_type,'linear_simple'))
		% Restrict fits for T2 from 1ms to 2500ms, and coefficient ('rho') from 
		% 0 to inf
		fo_ = fitoptions('method','LinearLeastSquares','Lower',[-1 0],'Upper',[-.0004 Inf]);
		ft_ = fittype('poly1');
		ln_si = log(si);

		% Fit the model
		[cf_, gof] = fit(te(ok_),ln_si(ok_),ft_,fo_);

		% Save Results
		r_squared = gof.rsquare;
		confidence_interval = confint(cf_,0.95);
		rho_fit = cf_.p2;
		t2_fit   = -1/cf_.p1;
		t2_95_ci = -1./confidence_interval(:,1);
	elseif(strcmp(fit_type,'linear_fast'))
		ln_si = log(si);

		% Fit the model
		Ybar = mean(ln_si(ok_)); 
		Xbar = mean(te(ok_));

		y = ln_si(ok_)-Ybar;
		x = te(ok_)-Xbar;
		slope =sum(x.*y)/sum(x.^2);
		intercept = Ybar-slope.*Xbar; %#ok<NASGU>
		r_squared = (sum(x.*y)/sqrt(sum(x.^2)*sum(y.^2)))^2;
		if ~isfinite(r_squared)
			r_squared = 0;
		end
		% Save Results
		t2_fit = -1/slope;
		rho_fit = intercept;
		% Confidence intervals not calculated
		t2_95_ci(1) = -1;
		t2_95_ci(2) = -1;
	elseif(strcmp(fit_type,'t1_tr_fit'))
		% Restrict fits for T1 from 0ms to 5000ms, and coefficient ('rho') from 
		% 0 to inf
		fo_ = fitoptions('method','NonlinearLeastSquares','Lower',[0 0],'Upper',[Inf   5000]);
		st_ = [max(si) 500 ];
		set(fo_,'Startpoint',st_);
		%set(fo_,'Weight',w);
		ft_ =  fittype('a*(1-exp(-x/b))');

		% Fit the model
		[cf_, gof] = fit(te(ok_),si(ok_),ft_,fo_);

		% Save Results
		r_squared = gof.rsquare;
		confidence_interval = confint(cf_,0.95);
		rho_fit = cf_.a;
		t2_fit   = cf_.b;
		t2_95_ci = confidence_interval(:,2);
	elseif(strcmp(fit_type,'t1_fa_fit'))
		% Convert flip angle (stored in te) from degrees to radians
 		te = te*pi/180;
		% scale si, non-linear fit has trouble converging with big numbers
		si = si./max(si);
		
		% Restrict fits for T1 from 0ms to 5000ms, and coefficient ('rho') from 
		% 0 to inf
		fo_ = fitoptions('method','NonlinearLeastSquares','Lower',[0 0],'Upper',[Inf   5000]);
		st_ = [max(si)*10 500 ];
 		set(fo_,'Startpoint',st_);
		%set(fo_,'Weight',w);
		ft_ =  fittype('a*( (1-exp(-tr/t1))*sin(theta) )/( 1-exp(-tr/t1)*cos(theta) )',...
			'dependent',{'si'},'independent',{'theta','tr'},...
			'coefficients',{'a','t1'});
		
		% Fit the model
		tr_array = tr*ones(size(te));
		[cf_, gof] = fit([te(ok_),tr_array],si(ok_),ft_,fo_);

		% Save Results
		r_squared = gof.rsquare;
		confidence_interval = confint(cf_,0.95);
		% Scale a as it was fit to a scaled dataset
		rho_fit = cf_.a*max(si);
		t2_fit   = cf_.t1;
		t2_95_ci = confidence_interval(:,2);
	elseif(strcmp(fit_type,'t1_fa_linear_fit'))
		y_lin = si./sin(pi/180*te);
		x_lin = si./tan(pi/180*te);
		
		Ybar = mean(y_lin(ok_)); 
		Xbar = mean(x_lin(ok_));
		y = y_lin(ok_)-Ybar;
		x = x_lin(ok_)-Xbar;
		
		slope =sum(x.*y)/sum(x.^2);
		intercept = Ybar-slope.*Xbar; 
		
		r_squared = (sum(x.*y)/sqrt(sum(x.^2)*sum(y.^2)))^2;
		if ~isfinite(r_squared)
			r_squared = 0;
		end
		rho_fit = intercept;
		t2_fit   = -tr/log(slope);
		if t2_fit>5000
			t2_fit = 5001;
		end
		if t2_fit<0
			t2_fit = -0.5;
		end
		t2_95_ci = [-1 -1];
	elseif(strcmp(fit_type,'t1_ti_exponential_fit'))
		% te stores the TI in ms
 		
		% scale si, non-linear fit has trouble converging with big numbers
		si = si./max(si);
		
		% Restrict fits for T1 from 0ms to 5000ms, and coefficient ('rho') from 
		% 0 to inf
		fo_ = fitoptions('method','NonlinearLeastSquares','Lower',[0 0],'Upper',[Inf   5000]);
		st_ = [max(si)*10 500 ];
 		set(fo_,'Startpoint',st_);
		%set(fo_,'Weight',w);
		ft_ =  fittype('abs( a* (1-2*exp(-ti/t1)-exp(-tr/t1) ) )',...
			'dependent',{'si'},'independent',{'ti','tr'},...
			'coefficients',{'a','t1'});
		
		% Fit the model
		tr_array = tr*ones(size(te));
		[cf_, gof] = fit([te(ok_),tr_array],si(ok_),ft_,fo_);

		% Save Results
		r_squared = gof.rsquare;
		confidence_interval = confint(cf_,0.95);
		% Scale a as it was fit to a scaled dataset
		rho_fit = cf_.a*max(si);
		t2_fit   = cf_.t1;
		t2_95_ci = confidence_interval(:,2);		
	elseif(strcmp(fit_type,'none'))
		r_squared = 1;
		rho_fit = 1;
		t2_fit   = 1;
		t2_95_ci = [1 1];
	end
else
	rho_fit = -2;
	t2_fit = -2;
	t2_95_ci(1) = -2;
	t2_95_ci(2) = -2;
end



fit_output = [t2_fit rho_fit r_squared t2_95_ci(1) t2_95_ci(2)];
