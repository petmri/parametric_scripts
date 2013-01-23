function [Szero, SR, ST1, SQ] = RAREVTRfit(x,index,W, slices, numBvals, xyplane, ...
                                           imagea)
  
  [i, j, k] = ind2sub([xyplane slices], index);
  cool = reshape(imagea(i, j,([1:numBvals]-1)*slices + k), 1,numBvals);
  y = cast(cool, 'double') ;
  
  x = x';
  y = y';
  
  Starting = [1000 1000];
  
  options=optimset('Display', 'notify', 'MaxFunEvals', 10000);
  Estimates=fminsearch(@fitfun, Starting, options, x, y);
  
  if((i == 224 && j == 75 && k == 2) ||  (i == 75 && j == 224 && k == 2))
  
  scatter(x,y,'b');
  hold on
  scatter(x, Estimates(1).*(1-exp(-y./Estimates(2))),'r');
  hold off
  pause
  end 
  Szero = Estimates(1);
  ST1   = Estimates(2);
  SQ    = 0;
  SR    = 1;
 
  
 return
 %{
  %W = W';
%RAREVTRFIT    Create plot of datasets and fits
%   RAREVTRFIT(X,Y)
%   Creates a plot, similar to the plot in the main curve fitting
%   window, using the data that you provide as input.  You can
%   apply this function to the same data you used with cftool
%   or with different data.  You may want to edit the function to
%   customize the code and this help message.
%
%   Number of datasets:  1
%   Number of fits:  1

 
% Data from dataset "y vs. x":
%    X = x:
%    Y = y:
%    Unweighted
%
% This function was automatically generated on 05-Mar-2009 21:32:48

W = W(:);

% Set up figure to receive datasets and fits
  %{
f_ = clf;
figure(f_);
set(f_,'Units','Pixels','Position',[440.667 243 680 484]);
legh_ = []; legt_ = {};   % handles and text for legend
xlim_ = [Inf -Inf];       % limits of x axis
ax_ = axes;
set(ax_,'Units','normalized','OuterPosition',[0 0 1 1]);
set(ax_,'Box','on');
axes(ax_); hold on;

 %}
% --- Plot data originally in dataset "y vs. x"
x = x(:);
y = y(:);

%{
h_ = line(x,y,'Parent',ax_,'Color',[0.333333 0 0.666667],...
     'LineStyle','none', 'LineWidth',1,...
     'Marker','.', 'MarkerSize',12);
xlim_(1) = min(xlim_(1),min(x));
xlim_(2) = max(xlim_(2),max(x));
legh_(end+1) = h_;
legt_{end+1} = 'y vs. x';

% Nudge axis limits beyond data limits
if all(isfinite(xlim_))
   xlim_ = xlim_ + [-1 1] * 0.01 * diff(xlim_);
   set(ax_,'XLim',xlim_)
end
%}

% --- Create fit "Saturation Recovery T1"
fo_ = fitoptions('method','NonlinearLeastSquares','Lower',[0 0 0], 'MaxIter', 5000);
ok_ = isfinite(x) & isfinite(y);
set(fo_,'Weight',W(ok_));
st_ = [0.777216393946 1000 0.213 ];
set(fo_,'Startpoint',st_);
ft_ = fittype('a*(1-exp(-x/b))+c',...
     'dependent',{'y'},'independent',{'x'},...
     'coefficients',{'a', 'b', 'c'});

% Fit this model using new data
[cf gof] = fit(x(ok_),y(ok_),ft_,fo_);

% Or use coefficients from the original fit:
if 0
   cv_ = { 55.14606047472, 55.15749852806, 0.0003895143781427};
   cf_ = cfit(ft_,cv_{:});
end
%{
% Plot this fit
h_ = plot(cf_,'fit',0.95);
legend off;  % turn off legend from plot method call
set(h_(1),'Color',[1 0 0],...
     'LineStyle','-', 'LineWidth',2,...
     'Marker','none', 'MarkerSize',6);
legh_(end+1) = h_(1);
legt_{end+1} = 'Saturation Recovery T1';

% Done plotting data and fits.  Now finish up loose ends.
hold off;
leginfo_ = {'Orientation', 'vertical', 'Location', 'NorthEast'}; 
h_ = legend(ax_,legh_,legt_,leginfo_{:});  % create legend
set(h_,'Interpreter','none');
xlabel(ax_,'');               % remove x label
ylabel(ax_,'');               % remove y label
%}

Szero = cf.a;
SR  = gof.rsquare;
ST1 = cf.b;
SQ  = cf.c;
 %}
