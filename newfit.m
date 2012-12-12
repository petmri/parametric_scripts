function [cf_, gof] = newfit(b,S)
%   NEWFIT    Create plot of datasets and fits
%   NEWFIT(B,S)
%   Creates a plot, similar to the plot in the main curve fitting
%   window, using the data that you provide as input.  You can
%   apply this function to the same data you used with cftool
%   or with different data.  You may want to edit the function to
%   customize the code and this help message.
%
%   Number of datasets:  1
%   Number of fits:  1

b = b(:);
S = S(:);

% --- Create fit "ADC"
fo_ = fitoptions('method','NonlinearLeastSquares','Robust','off','MaxIter',1000000000000000);
ok_ = isfinite(b) & isfinite(S);
if ~all( ok_ )
    warning( 'GenerateMFile:IgnoringNansAndInfs', ...
        'Ignoring NaNs and Infs in data' );
end
%st_ = [13683.121584233009344 -9.8620525886159490087e-05 ];
%set(fo_,'Startpoint',st_);
ft_ = fittype('exp1');

% Fit this model using new data
[cf_, gof] = fit(b(ok_),S(ok_),ft_,fo_);

% Or use coefficients from the original fit:

%if 0
 %  cv_ = { 13939.733543363900026, -0.00013771464910958800985};
  % cf_ = cfit(ft_,cv_{:});
%end

return