% Performs different types of fits on exponential decay (T1, T2, and T2*) data
function fit_output = fitT2(te,fit_type,si)

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
	y_lin = si./sin(te);
	x_lin = si./tan(te);
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
if r_squared>=0.7
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
		% Restrict fits for T1 from 0ms to 5000ms, and coefficient ('rho') from 
		% 0 to inf
		fo_ = fitoptions('method','NonlinearLeastSquares','Lower',[0 0],'Upper',[Inf   5000]);
		st_ = [max(si) 500 ];
		set(fo_,'Startpoint',st_);
		%set(fo_,'Weight',w);
		ft_ =  fittype('a*( (1-exp(-tr/t1))*sin(theta) )/( 1-exp(-tr/t1)*cos(theta) )',...
			'dependent',{'si'},'independent',{'theta','tr'},...
			'coefficients',{'a','t1'});

		% Fit the model
		tr = [8 8 8 8 8 8];
		[cf_, gof] = fit([te(ok_)',tr'],si(ok_)',ft_,fo_);

		% Save Results
		r_squared = gof.rsquare;
		confidence_interval = confint(cf_,0.95);
		rho_fit = cf_.a;
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
