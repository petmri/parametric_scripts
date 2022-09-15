% Performs different types of fits on exponential decay (T1, T2, and T2*) data
function fit_output = fitParameter(parameter,fit_type,si,tr, userfile, ncoeffs, coeffs, tr_present,rsquared_threshold)

% Verify all numbers exists
ok_ = isfinite(parameter) & isfinite(si);
if ~all( ok_ )
    warning( 'GenerateMFile:IgnoringNansAndInfs', ...
        'Ignoring NaNs and Infs in data' );
end

% First do a fast sanity check on data, prevents time consuming fits
% of junk data
if(strcmp(fit_type,'t1_tr_fit'))
    ln_si = log((si-max(si)-1)*-1);
    Ybar = mean(ln_si(ok_));
    Xbar = mean(parameter(ok_));
    y = ln_si(ok_)-Ybar;
    x = parameter(ok_)-Xbar;
    %     slope =sum(x.*y)/sum(x.^2);
    %     intercept = Ybar-slope.*Xbar; %#ok<NASGU>
    r_squared = (sum(x.*y)/sqrt(sum(x.^2)*sum(y.^2)))^2;
    if ~isfinite(r_squared)
        r_squared = 0;
    end
elseif(strcmp(fit_type,'t1_fa_fit'))
    y_lin = si./sin(pi/180*parameter);
    x_lin = si./tan(pi/180*parameter);
    Ybar = mean(y_lin(ok_));
    Xbar = mean(x_lin(ok_));
    y = y_lin(ok_)-Ybar;
    x = x_lin(ok_)-Xbar;
    slope =sum(x.*y)/sum(x.^2);
    %     intercept = Ybar-slope.*Xbar; %#ok<NASGU>
    r_squared = (sum(x.*y)/sqrt(sum(x.^2)*sum(y.^2)))^2;
    % Prevents negative slopes and complex results
    if ~isfinite(r_squared) || slope<0
        r_squared = 0;
    end
elseif(strcmp(fit_type,'t2_linear_fast') || strcmp(fit_type,'t1_fa_linear_fit')) || strcmp(fit_type, 'ADC_linear_fast')
    % Skip check as we are doing a fast linear fit
    r_squared = 2.0;
elseif(strcmp(fit_type,'t1_ti_exponential_fit'))
    % Skip check as no linearization exists
    r_squared = 2.0;
elseif(strcmp(fit_type, 'user_input'))
    % Skip check as user input
    r_squared = 2.0;
else
    ln_si = log(si);
    Ybar = mean(ln_si(ok_));
    Xbar = mean(parameter(ok_));
    y = ln_si(ok_)-Ybar;
    x = parameter(ok_)-Xbar;
    %     slope =sum(x.*y)/sum(x.^2);
    %     intercept = Ybar-slope.*Xbar; %#ok<NASGU>
    r_squared = (sum(x.*y)/sqrt(sum(x.^2)*sum(y.^2)))^2;
    if ~isfinite(r_squared)
        r_squared = 0;
    end
end

% Continue if fit is rational
if r_squared>=rsquared_threshold
    if(strcmp(fit_type,'t2_exponential'))
        % Restrict fits for T2 from 1ms to 2500ms, and coefficient ('rho') from
        % 0 to inf
        fo_ = fitoptions('method','NonlinearLeastSquares','Lower',[0 -1],'Upper',[Inf   -.0004]);
        % The start point prevents convergance for some reason, do not use
        % 		st_ = [si(end) -.035 ];
        % 		set(fo_,'Startpoint',st_);
        %set(fo_,'Weight',w);
        ft_ = fittype('exp1');
        
        % Fit the model
        [cf_, gof] = fit(parameter(ok_),si(ok_),ft_,fo_);
        
        % Save Results
        sum_squared_error = gof.sse;
        r_squared = gof.rsquare;
        confidence_interval = confint(cf_,0.95);
        rho_fit = cf_.a;
        exponential_fit   = -1/cf_.b;
        exponential_95_ci = -1./confidence_interval(:,2);
    elseif(strcmp(fit_type,'t2_exponential_plus_c')) %Wood's model
        % t = time vector in seconds
        % s = S(t) in arbitrary units

        t = parameter(ok_);
        s = si(ok_);

        % Find maximum absolute signal
        M0_est = max(s);
        M1_est = min(s);
        T2_est = (max(t)-min(t))/log(M0_est/M1_est);
        % T2_est = 0.05;     % s

        % Setup optimization parameters
%         options = optimset('lsqcurvefit');
%         options.Display = 'off';
%         options.TolFun = 1e-12;
%         options.TolX = 1e-12;
%         options.MaxIter = 10000;
        
        if(T2_est<10)
            ft_ =  fittype('a*exp(-x/b)+c');
            
            % Initial parameter guess
            x0 = [M0_est T2_est M1_est];

            % Parameter constraints
            lb = [0   0   0];
            ub = [Inf 100  Inf];
        else
            ft_ = fittype('exp1');
            
            % Initial parameter guess
            x0 = [M0_est T2_est];

            % Parameter constraints
            lb = [0   -Inf];
            ub = [Inf -0.01];
        end


        % Start optimization
%         x_fit = lsqcurvefit('wood_exp_plus_const',x0,t,s,lb,ub,options);
        
        fo_ = fitoptions('method','NonlinearLeastSquares','Lower',lb,'Upper',ub);
        set(fo_,'Startpoint',x0);
        set(fo_,'Maxiter',10000);
        set(fo_,'TolX',1e-12);
        set(fo_,'TolFun',1e-12);
        
        
        % Fit the model
        [cf_, gof] = fit(parameter(ok_),si(ok_),ft_,fo_);

        % Calculate fitted function values
%         s_fit = exp_plus_const(x_fit,t);
%         T2r=sum((s-s_fit).^2);              % Error power
%         s_fit2 = exp_plus_const(x0,t);
        
        % Calculate return values
%         M0 = x_fit(1);
%         T2s = x_fit(2);
%         M1 = x_fit(3); 
        
        % Save Results
%         sum_squared_error = T2r;
%         r_squared = 1-sum_squared_error/sum(s.^2);
%         if ~isfinite(r_squared) || ~isreal(r_squared)
%             r_squared = 0;
%         end 
%         rho_fit = M0;
%         exponential_fit   = T2s;
%         % Confidence intervals not calculated
%         exponential_95_ci(1) = -1;
%         exponential_95_ci(2) = -1;
        
        % Save Results
        sum_squared_error = gof.sse;
        r_squared = gof.rsquare;
        confidence_interval = confint(cf_,0.95);
        rho_fit = cf_.a;
        if(T2_est<10)
            exponential_fit   = cf_.b;
            exponential_95_ci = confidence_interval(:,2);
            plus_c = cf_.c;
            plus_c_low = confidence_interval(1,3);
            plus_c_high = confidence_interval(2,3);
        else
            exponential_fit   = -1/cf_.b;
            exponential_95_ci = -1./confidence_interval(:,2);
            plus_c = 0;
            plus_c_low = 0;
            plus_c_high = 0;
        end
       
    elseif(strcmp(fit_type,'ADC_exponential'))
        % Restrict fits for ADC from 0 to Inf, and coefficient ('rho') from
        % 0 to inf
        fo_ = fitoptions('method','NonlinearLeastSquares','Lower',[0 -Inf],'Upper',[Inf   0]);
        % The start point prevents convergance for some reason, do not use
        % 		st_ = [si(end) -.035 ];
        % 		set(fo_,'Startpoint',st_);
        %set(fo_,'Weight',w);
        ft_ = fittype('exp1');
        
        % Fit the model
        [cf_, gof] = fit(parameter(ok_),si(ok_),ft_,fo_);
        
        % Save Results
        sum_squared_error = gof.sse;
        r_squared = gof.rsquare;
        confidence_interval = confint(cf_,0.95);
        rho_fit = cf_.a;
        exponential_fit   = -1*cf_.b;
        exponential_95_ci = -1*confidence_interval(:,2);
    elseif(strcmp(fit_type,'ADC_linear_weighted'))
        % Restrict fits for ADC from 0 to Inf, and coefficient ('rho') from
        % 0 to inf
        fo_ = fitoptions('method','LinearLeastSquares','Lower',[-1 -Inf],'Upper',[-Inf 0]);
        ft_ = fittype('poly1');
        set(fo_,'Weight',si);
        ln_si = log(si);
        
        % Fit the model
        [cf_, gof] = fit(parameter(ok_),ln_si(ok_),ft_,fo_);
        
        % Save Results
        sum_squared_error = gof.sse;
        r_squared = gof.rsquare;
        confidence_interval = confint(cf_,0.95);
        rho_fit = cf_.p2;
        exponential_fit   = -1*cf_.p1;
        exponential_95_ci = -1*confidence_interval(:,1);
        
    elseif(strcmp(fit_type,'t2_linear_weighted'))
        % Restrict fits for T2 from 1ms to 2500ms, and coefficient ('rho') from
        % 0 to inf
        fo_ = fitoptions('method','LinearLeastSquares','Lower',[-1 0],'Upper',[-.0004 Inf]);
        ft_ = fittype('poly1');
        set(fo_,'Weight',si);
        ln_si = log(si);
        
        % Fit the model
        [cf_, gof] = fit(parameter(ok_),ln_si(ok_),ft_,fo_);
        
        % Save Results
        sum_squared_error = gof.sse;
        r_squared = gof.rsquare;
        confidence_interval = confint(cf_,0.95);
        rho_fit = cf_.p2;
        exponential_fit   = -1/cf_.p1;
        exponential_95_ci = -1./confidence_interval(:,1);
    elseif(strcmp(fit_type,'t2_linear_simple'))
        % Restrict fits for T2 from 1ms to 2500ms, and coefficient ('rho') from
        % 0 to inf
        fo_ = fitoptions('method','LinearLeastSquares','Lower',[-1 0],'Upper',[-.0004 Inf]);
        ft_ = fittype('poly1');
        ln_si = log(si);
        
        % Fit the model
        [cf_, gof] = fit(parameter(ok_),ln_si(ok_),ft_,fo_);
        
        % Save Results
        sum_squared_error = gof.sse;
        r_squared = gof.rsquare;
        confidence_interval = confint(cf_,0.95);
        rho_fit = cf_.p2;
        exponential_fit   = -1/cf_.p1;
        exponential_95_ci = -1./confidence_interval(:,1);
    elseif(strcmp(fit_type,'ADC_linear_simple'))
        % Restrict fits for T2 from 0 to Inf, and coefficient ('rho') from
        % 0 to inf
        fo_ = fitoptions('method','LinearLeastSquares','Lower',[-Inf 0],'Upper',[0 Inf]);
        ft_ = fittype('poly1');
        ln_si = log(si);
        
        % Fit the model
        [cf_, gof] = fit(parameter(ok_),ln_si(ok_),ft_,fo_);
        
        % Save Results
        sum_squared_error = gof.sse;
        r_squared = gof.rsquare;
        confidence_interval = confint(cf_,0.95);
        rho_fit = cf_.p2;
        exponential_fit   = -1*cf_.p1;
        exponential_95_ci = -1*confidence_interval(:,1);
    elseif(strcmp(fit_type,'t2_linear_fast'))
        ln_si = log(si);
        
        % Fit the model
        Ybar = mean(ln_si(ok_));
        Xbar = mean(parameter(ok_));
        
        y = ln_si(ok_)-Ybar;
        x = parameter(ok_)-Xbar;
        slope =sum(x.*y)/sum(x.^2);
        intercept = Ybar-slope.*Xbar; 
        r_squared = (sum(x.*y)/sqrt(sum(x.^2)*sum(y.^2)))^2;
        sum_squared_error = (1-r_squared)*sum(y.^2);
        if ~isfinite(r_squared) || ~isreal(r_squared)
            r_squared = 0;
        end
        % Save Results
        exponential_fit = -1/slope;
        rho_fit = intercept;
        % Confidence intervals not calculated
        exponential_95_ci(1) = -1;
        exponential_95_ci(2) = -1;
    elseif(strcmp(fit_type,'ADC_linear_fast'))
        ln_si = log(si);
        
        % Fit the model
        Ybar = mean(ln_si(ok_));
        Xbar = mean(parameter(ok_));
        
        y = ln_si(ok_)-Ybar;
        x = parameter(ok_)-Xbar;
        slope =sum(x.*y)/sum(x.^2);
        intercept = Ybar-slope.*Xbar; 
        r_squared = (sum(x.*y)/sqrt(sum(x.^2)*sum(y.^2)))^2;
        sum_squared_error = (1-r_squared)*sum(y.^2);
        if ~isfinite(r_squared) || ~isreal(r_squared)
            r_squared = 0;
        end
        % Save Results
        exponential_fit = -1*slope;
        rho_fit = intercept;
        % Confidence intervals not calculated
        exponential_95_ci(1) = -1;
        exponential_95_ci(2) = -1;
    elseif(strcmp(fit_type,'t1_tr_fit'))
        % Restrict fits for T1 from 0ms to 5000ms, and coefficient ('rho') from
        % 0 to inf
        fo_ = fitoptions('method','NonlinearLeastSquares','Lower',[0 0],'Upper',[Inf   10000]);
        st_ = [max(si) 500 ];
        set(fo_,'Startpoint',st_);
        %set(fo_,'Weight',w);
        ft_ =  fittype('a*(1-exp(-x/b))');
        
        % Fit the model
        [cf_, gof] = fit(parameter(ok_),si(ok_),ft_,fo_);
        
        % Save Results
        sum_squared_error = gof.sse;
        r_squared = gof.rsquare;
        confidence_interval = confint(cf_,0.95);
        rho_fit = cf_.a;
        exponential_fit   = cf_.b;
        exponential_95_ci = confidence_interval(:,2);
    elseif(strcmp(fit_type,'t1_fa_fit'))
        % Convert flip angle (stored in te) from sdegrees to radians
        parameter = parameter*pi/180;
        % scale si, non-linear fit has trouble converging with big numbers
        scale_max = max(si);
        si = si./scale_max;
        
        % Restrict fits for T1 from 0ms to 5000ms, and coefficient ('rho') from
        % 0 to inf
        fo_ = fitoptions('method','NonlinearLeastSquares','Lower',[0 0],'Upper',[Inf   10000]);
        st_ = [max(si)*10 500 ];
        set(fo_,'Startpoint',st_);
        %set(fo_,'Weight',w);
        ft_ =  fittype('a*( (1-exp(-tr/t1))*sin(theta) )/( 1-exp(-tr/t1)*cos(theta) )',...
            'dependent',{'si'},'independent',{'theta','tr'},...
            'coefficients',{'a','t1'});
        
        % Fit the model
        tr_array = tr*ones(size(parameter));
        [cf_, gof] = fit([parameter(ok_),tr_array],si(ok_),ft_,fo_);
        
        % Save Results
        sum_squared_error = gof.sse;
        r_squared = gof.rsquare;
        confidence_interval = confint(cf_,0.95);
        % Scale a as it was fit to a scaled dataset
        rho_fit = cf_.a*scale_max;
        exponential_fit   = cf_.t1;
        exponential_95_ci = confidence_interval(:,2);
    elseif(strcmp(fit_type,'t1_fa_linear_fit'))
        y_lin = si./sin(pi/180*parameter);
        x_lin = si./tan(pi/180*parameter);
        
        Ybar = mean(y_lin(ok_));
        Xbar = mean(x_lin(ok_));
        y = y_lin(ok_)-Ybar;
        x = x_lin(ok_)-Xbar;
        
        slope =sum(x.*y)/sum(x.^2);
        intercept = Ybar-slope.*Xbar;
        
        r_squared = (sum(x.*y)/sqrt(sum(x.^2)*sum(y.^2)))^2;
        sum_squared_error = (1-r_squared)*sum(y.^2);
        if ~isfinite(r_squared)
            r_squared = 0;
        end
        rho_fit = intercept;
        % Prevent complex results
        if slope<0
            exponential_fit = -0.4;
        else
            exponential_fit   = -tr/log(slope);
        end
%         if exponential_fit>10000
%             exponential_fit = 10001;
%         end
        if exponential_fit<0
            exponential_fit = -0.5;
        end
        exponential_95_ci = [-1 -1];
    elseif(strcmp(fit_type,'t1_ti_exponential_fit'))
        % te stores the TI in ms
        
        % scale si, non-linear fit has trouble converging with big numbers
        scale_max = max(si);
        si = si./scale_max;
        
        % Restrict fits for T1 from 0ms to 5000ms, and coefficient ('rho') from
        % 0 to inf
        fo_ = fitoptions('method','NonlinearLeastSquares','Lower',[0 0],'Upper',[Inf   10000]);
        st_ = [max(si)*10 500 ];
        set(fo_,'Startpoint',st_);
        %set(fo_,'Weight',w);
        ft_ =  fittype('abs( a* (1-2*exp(-ti/t1)-exp(-tr/t1) ) )',...
            'dependent',{'si'},'independent',{'ti','tr'},...
            'coefficients',{'a','t1'});
        
        % Fit the model
        tr_array = tr*ones(size(parameter));
        [cf_, gof] = fit([parameter(ok_),tr_array],si(ok_),ft_,fo_);
        
        % Save Results
        sum_squared_error = gof.sse;
        r_squared = gof.rsquare;
        confidence_interval = confint(cf_,0.95);
        % Scale a as it was fit to a scaled dataset
        rho_fit = cf_.a*scale_max;
        exponential_fit   = cf_.t1;
        exponential_95_ci = confidence_interval(:,2);
        
    elseif(strcmp(fit_type, 'user_input'))
        [PATHSTR,NAME,~] = fileparts(userfile);
        
        %Add the usefile function to path
%         path(path, PATHSTR)
%         
%         save('Moo.,mat', 'PATHSTR')
        
        userFN = str2func(NAME);
        
        % scale si, non-linear fit has trouble converging with big numbers
        scale_max = max(si);
        si = si./scale_max;
            
        [cf_, gof, output] = userFN(parameter(ok_), si(ok_));
        
        % Save Results
        sum_squared_error = gof.sse;
        r_squared = gof.rsquare;
        confidence_interval = confint(cf_,0.95);
        %rho_fit = cf_.a;
        %exponential_fit   = cf_.b;
        exponential_95_ci = confidence_interval;
      
        coeffvals = coeffvalues(cf_);
        coeffvals = coeffvals(:)';

    elseif(strcmp(fit_type,'none'))
        sum_squared_error = 0;
        r_squared = 1;
        rho_fit = 1;
        exponential_fit   = 1;
        exponential_95_ci = [1 1];
    end
    
else
    rho_fit = -2;
    exponential_fit = -2;
    exponential_95_ci(1) = -2;
    exponential_95_ci(2) = -2;
    sum_squared_error = -2;
    plus_c = -2;
    plus_c_low = -2;
    plus_c_high = -2;
end

if strcmp(fit_type, 'user_input')
    fit_output = [coeffvals r_squared exponential_95_ci(1,:) exponential_95_ci(2,:) sum_squared_error];
elseif strcmp(fit_type, 't2_exponential_plus_c')
    fit_output = [exponential_fit rho_fit r_squared exponential_95_ci(1) exponential_95_ci(2) sum_squared_error plus_c plus_c_low plus_c_high];
else
    fit_output = [exponential_fit rho_fit r_squared exponential_95_ci(1) exponential_95_ci(2) sum_squared_error];   
end
