% Performs different types of fits on exponential decay (T2 and T2*) data
function fit_output = fitT2(te,fit_type,si)

% Verify all numbers exists
ok_ = isfinite(te) & isfinite(si);
if ~all( ok_ )
	warning( 'GenerateMFile:IgnoringNansAndInfs', ...
		'Ignoring NaNs and Infs in data' );
end

% First do a fast sanity check on data, prevents time consuming fits
% of junk data
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

% Continue if fit is rational
if r_squared>=0.6
	if(strcmp(fit_type,'exponential'))
		% Restrict fits for T2 from 1ms to 2500ms, and coefficient ('rho') from 
		% 0 to inf
		fo_ = fitoptions('method','NonlinearLeastSquares','Lower',[0 -1],'Upper',[Inf   -.0004]);
		st_ = [si(end) -.035 ];
		set(fo_,'Startpoint',st_);
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

	elseif(strcmp(fit_type,'none'))
		r_squared = 1;
		rho_fit = 1;
		t2_fit   = 1;
		t2_95_ci = [1 1];
	end
end


% Throw out bad results
if(r_squared < 0.6)
	rho_fit = -1;
	t2_fit = -1;
	t2_95_ci(1) = -1;
	t2_95_ci(2) = -1;
end
if(t2_95_ci(2)<0)
    t2_95_ci(2) = -1;
end


fit_output = [t2_fit rho_fit r_squared t2_95_ci(1) t2_95_ci(2)];
