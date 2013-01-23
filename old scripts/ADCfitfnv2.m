%function [cf_, gof] = ADCfitfn(x,y,W, fitype, ploter)
%function out = ADCfitfn(x,y,W, fitype, ploter)

function [Szero, SR, SADC, SQ] = ADCfitfnv2(x,index, W, fitype, ploter, ...
                                            slices, numBvals, xyplane, ...
                                            imagea)
  
  [i, j, k] = ind2sub([xyplane slices], index);
  cool = reshape(imagea(i, j,([1:numBvals]-1)*slices + k), 1,numBvals);
  y = cast(cool, 'double') ;

  x = x';
  y = y';
  W = W';
  
 
  
 

% ploter = ploter{1};
 % x = x{1};
 % y = y{1};
 % W = W{1};
 % fitype = fitype{1};
%ACKERMAN    Create plot of datasets and fits
%   ACKERMAN(X,Y,W)
%   Creates a plot, similar to the plot in the main curve fitting
%   window, using the data that you provide as input.  You can
%   apply this function to the same data you used with cftool
%   or with different data.  You may want to edit the function to
%   customize the code and this help message.
%
%   Number of datasets:  2
%   Number of fits:  1

%Fits - ackerman, acksimp, linearsimp, simp
cfita = 0;
 
% Data from dataset "y vs. x":
%    X = x:
%    Y = y:
%    Unweighted
 
% Data from dataset "y vs. x with W":
%    X = x:
%    Y = y:
%    Weights = W:
%
% This function was automatically generated on 31-Jan-2008 01:51:45



if(ploter == 1)
% Set up figure to receive datasets and fits
f_ = clf;
figure(f_);
set(f_,'Units','Pixels','Position',[1 14 1920 1030]);
legh_ = []; legt_ = {};   % handles and text for legend
xlim_ = [Inf -Inf];       % limits of x axis
ax_ = axes;
set(ax_,'Units','normalized','OuterPosition',[0 0 1 1]);
set(ax_,'Box','on');
axes(ax_); hold on;



% --- Plot data originally in dataset "y vs. x"
x = x(:);
y = y(:);
% This dataset does not appear on the plot
% Add it to the plot by removing the if/end statements that follow
% and by selecting the desired color and marker
if 0
   h_ = line(x,y,'Color','r','Marker','.','LineStyle','none');
   xlim_(1) = min(xlim_(1),min(x));
   xlim_(2) = max(xlim_(2),max(x));
   legh_(end+1) = h_;
   legt_{end+1} = 'y vs. x';
end       % end of "if 0"
 
% --- Plot data originally in dataset "y vs. x with W"
W = W(:);
h_ = line(x,y,'Parent',ax_,'Color',[0.333333 0.666667 0],...
     'LineStyle','none', 'LineWidth',1,...
     'Marker','.', 'MarkerSize',12);
xlim_(1) = min(xlim_(1),min(x));
xlim_(2) = max(xlim_(2),max(x));
legh_(end+1) = h_;
legt_{end+1} = 'y vs. x with W';

% Nudge axis limits beyond data limits
if all(isfinite(xlim_))
   xlim_ = xlim_ + [-1 1] * 0.01 * diff(xlim_);
   set(ax_,'XLim',xlim_)
else
    set(ax_, 'XLim',[0.91000000000000003109, 10.089999999999999858]);
end
end

if(strcmp(fitype, 'ackerman'))
% --- Create fit "ackerman"
fo_ = fitoptions('method','NonlinearLeastSquares','Robust','off','Lower', ...
                 [0 0 0],'Upper', [5000000000000000000 5000000000000000 50000000000000000], 'MaxIter',50000000000000000000000);
ok_ = isfinite(x) & isfinite(y) & isfinite(W);
if ~all( ok_ )
    warning( 'GenerateMFile:IgnoringNansAndInfs', ...
        'Ignoring NaNs and Infs in data' );
end
%st_ = [0 0 0 ];
%set(fo_,'Startpoint',st_);
set(fo_,'Weight',W(ok_));
ft_ = fittype('exp(-x*D+(x*Q)^2)*S*((1+erfc((D/(Q*sqrt(2))-(x*Q/sqrt(2)))/(1+erfc(D/(Q*sqrt(2)))))))',...
     'dependent',{'y'},'independent',{'x'},...
     'coefficients',{'D', 'Q', 'S'});

% Fit this model using new data
[cf_,gof] = fit(x(ok_),y(ok_),ft_,fo_);

% Or use coefficients from the original fit:
if (cfita == 1)
   cv_ = { 0.46732548150994940306, 0.1959174108688591931, 1.4241788454089927551};
   cf_ = cfit(ft_,cv_{:});
end

%Get prediction bounds
%[predfit, ypred1] = predint(cf_, x, 0.95);

if(ploter == 1)
% Plot this fit
h_ = plot(cf_,'fit',0.95);
legend off;  % turn off legend from plot method call
set(h_(1),'Color',[1 0 0],...
     'LineStyle','-', 'LineWidth',2,...
     'Marker','none', 'MarkerSize',6);
legh_(end+1) = h_(1);
legt_{end+1} = 'ackerman';
end

elseif(strcmp(fitype, 'acksimp'))
    y = log(y);
    % --- Create fit "Acksimp"
fo_ = fitoptions('method','LinearLeastSquares','Lower',[0 0 -Inf]);
ok_ = isfinite(x) & isfinite(y) & isfinite(W);
if ~all( ok_ )
    warning( 'GenerateMFile:IgnoringNansAndInfs', ...
        'Ignoring NaNs and Infs in data' );
end
set(fo_,'Weight',W(ok_));
ft_ = fittype({'(x*x/2)', 'x', '1'},...
     'dependent',{'y'},'independent',{'x'},...
     'coefficients',{'Qsq', 'D', 'Sln'});

% Fit this model using new data
[cf_,gof] = fit(x(ok_),y(ok_),ft_,'Weight',W(ok_));

% Or use coefficients from the original fit:
if (cfita == 1)
   cv_ = { 0.46755638860386372624, 0.19596509828526928465, 1.4270702096214844534};
   cf_ = cfit(ft_,cv_{:});
end

%Get prediction bounds
%[predfit, ypred1] = predint(cf_, x, 0.95);

if(ploter == 1)
% Plot this fit
h_ = plot(cf_,'fit',0.95);
legend off;  % turn off legend from plot method call
set(h_(1),'Color',[0 0 1],...
     'LineStyle','-', 'LineWidth',2,...
     'Marker','none', 'MarkerSize',6);
legh_(end+1) = h_(1);
legt_{end+1} = 'AckSimp';
end

elseif(strcmp(fitype,'linearsimp'))
      y = log(y);
    % --- Create fit "fit 4"
fo_ = fitoptions('method','LinearLeastSquares');
ok_ = isfinite(x) & isfinite(y) & isfinite(W);
if ~all( ok_ )
    warning( 'GenerateMFile:IgnoringNansAndInfs', ...
        'Ignoring NaNs and Infs in data' );
end
set(fo_,'Weight',W(ok_));
ft_ = fittype({'x', '1'},...
     'dependent',{'y'},'independent',{'x'},...
     'coefficients',{'D', 'Sln'});

% Fit this model using new data
[cf_,gof] = fit(x(ok_),y(ok_),ft_,fo_);

% Or use coefficients from the original fit:
if (cfita == 1)
   cv_ = { 0, 0.636341757303911848};
   cf_ = cfit(ft_,cv_{:});
end

%Get prediction bounds
%[predfit, ypred1] = predint(cf_, x, 0.95);

if(ploter == 1)
% Plot this fit
h_ = plot(cf_,'fit',0.95);
legend off;  % turn off legend from plot method call
set(h_(1),'Color',[0 0 1],...
     'LineStyle','-', 'LineWidth',2,...
     'Marker','none', 'MarkerSize',6);
legh_(end+1) = h_(1);
legt_{end+1} = 'LinSimp';
end

elseif(strcmp(fitype, 'simp'))
    
    % --- Create fit "ADC"
fo_ = fitoptions('method','NonlinearLeastSquares','Robust','off','MaxIter',1000000000000000);
ok_ = isfinite(x) & isfinite(y) & isfinite(W);
if ~all( ok_ )
    warning( 'GenerateMFile:IgnoringNansAndInfs', ...
        'Ignoring NaNs and Infs in data' );
end
set(fo_,'Weight',W(ok_));
%st_ = [13683.121584233009344 -9.8620525886159490087e-05 ];
%set(fo_,'Startpoint',st_);
ft_ = fittype('exp1');

% Fit this model using new data
[cf_, gof] = fit(x(ok_),y(ok_),ft_,fo_);

% Or use coefficients from the original fit:

if(cfita == 1)
   cv_ = { 13939.733543363900026, -0.00013771464910958800985};
   cf_ = cfit(ft_,cv_{:});
end

%Get prediction bounds
%[predfit, ypred1] = predint(cf_, x, 0.95);

if(ploter == 1)
% Plot this fit
h_ = plot(cf_,'fit',0.95);
legend off;  % turn off legend from plot method call
set(h_(1),'Color',[0 0 1],...
     'LineStyle','-', 'LineWidth',2,...
     'Marker','none', 'MarkerSize',6);
legh_(end+1) = h_(1);
legt_{end+1} = 'Simp';
end


else
    error('No Fit algorithm selected');
end


if(ploter == 1)
% Done plotting data and fits.  Now finish up loose ends.
hold off;
leginfo_ = {'Orientation', 'vertical', 'Location', 'NorthEast'}; 
h_ = legend(ax_,legh_,legt_,leginfo_{:});  % create legend
set(h_,'Interpreter','none');
xlabel(ax_,'');               % remove x label
ylabel(ax_,'');               % remove y label
end


cf = cf_;
gof = gof;




if(strcmp(fitype, 'ackerman'))
      
  Szero = cf.S;
  SR    = gof.rsquare;
  SADC  = cf.D;
  SQ    = cf.Q;
  
elseif(strcmp(fitype, 'acksimp'))
  
  Szero = exp(cf.Sln);
  SR    = gof.rsquare;
  SADC  = -1*cf.D;
  SQ    = cf.Qsq;
  
elseif(strcmp(fitype,'linearsimp'))
      
  Szero = exp(cf.Sln);
  SR    = gof.rsquare;
  SADC  = -1*cf.D;
  SQ    = 0;
         
elseif(strcmp(fitype, 'simp'))
         
  Szero = cf.a;
  SR    = gof.rsquare;
  SADC  = -1*cf.b;
  SQ    = 0;
else
  error('Something is wrong in the fitting!');
end

if(SADC < 0)
    SADC = 0;
end