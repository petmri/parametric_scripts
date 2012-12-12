%We alter it to suit T2star fitting MGET2starfitfnv2 for neuroecon


function Sout = MGET2starfitfnv3(xdata, index)


x = xdata{1}.b_values;
found    = xdata{1}.found;
W        = xdata{1}.W;
fitype   = xdata{1}.fitype;
ploter   = xdata{1}.ploter;
slices   = xdata{1}.slices;
numBvals = xdata{1}.numBvals;
imagea   = xdata{1}.imagea;
xyplane  = [size(imagea, 1) size(imagea,2)];
index = found(index);


[i, j, k] = ind2sub([xyplane slices], index);

Szero = 0;
SR    = 0;
SADC  = 0;
SQ    = 0;




%{

[Szero, SR, ST2, SQ] = RAREVTRfitv2(x,index,W, slices, numBvals, xyplane, ...
                                           imagea)
%}
[i, j, k] = ind2sub([xyplane slices], index);
cool = reshape(imagea(i, j,([1:numBvals]-1)*slices + k), 1,numBvals);
y = cast(cool, 'double') ;

TE = x';
Q = y';


W = W(:);
W = W;

t = TE/1000;
S = Q;
% --- Create fit "fit 1"
fo_ = fitoptions('method','NonlinearLeastSquares','Upper',[Inf   0]);
ok_ = isfinite(t) & isfinite(S);
if ~all( ok_ )
    warning( 'GenerateMFile:IgnoringNansAndInfs', ...
        'Ignoring NaNs and Infs in data' );
end
st_ = [Q(end) -14.014000638344352723 ];
set(fo_,'Startpoint',st_);
set(fo_,'Weight',W);
ft_ = fittype('exp1');

% Fit this model using new data
[cf_ gof] = fit(t(ok_),S(ok_),ft_,fo_);

% Or use coefficients from the original fit:
if 0
    cv_ = { 1556.7854374929556798, -10.701659430790392946};
    [cf_ gof] = cfit(ft_,cv_{:});
end
% % % --- Create fit "fit 2"
% fo_ = fitoptions('method','NonlinearLeastSquares','Lower',[-Inf    0    0],'MaxFunEvals',100,'MaxIter',100,'TolFun',1e-010,'TolX',1e-010, 'Display', 'off');
% %fo_ = fitoptions('method','NonlinearLeastSquares','Lower',[0    0 -Inf]);
% ok_ = isfinite(TE) & isfinite(Q);
% if ~all( ok_ )
%     warning( 'GenerateMFile:IgnoringNansAndInfs', ...
%         'Ignoring NaNs and Infs in data' );
% end
% st_ = [max(Q) 0.4 0.095100000000000003975 ];
% set(fo_,'Startpoint',st_);
% set(fo_,'Weight',W(ok_));
% ft_ = fittype('a*exp(-b*x)+c',...
%     'dependent',{'y'},'independent',{'x'},...
%     'coefficients',{'a', 'b', 'c'});

% Fit this model using new data


SR    = gof.rsquare;

if(SR < 0)
    Szero = 0;
    ST2 = 0;
else
    
    Szero = cf_.a;
    ST2   = -1/cf_.b;
end
SQ    = 0;%cf_.c;



%Do NNLS fit;
TE;
Q;

% t2 = 1:0.5:2000;
% A  = exp(-kron(TE, 1./t2));
% size(A)
% A  = [A ones(size(A,1), 1)];
%
% x  = lsqnonneg(A, Q);
% x;
%
% SQ = x(end);
% amplitudes = x(1:end-1);
%
% if(sum(amplitudes) == 0)
%     %Terrible fit, initialize to be zero;
%     Szero = (-1);
%     ST2   = -1;
%     %SR    = -1;
%     SQ    = -1;
% else
%
% ind = find(amplitudes == max(amplitudes));
% Szero = amplitudes(ind);
% ST2 = t2(ind);
% end
% QE = A*x;
%
%
% residuals = sum((Q-QE).^2);
% SR = residuals;


% xdata{1}.TR = D1;
% xdata{1}.W  = W';
%
% options = optimset(optimset('lsqcurvefit'), 'Algorithm', {'levenberg-marquardt' 0.01}, 'LevenbergMarquardt','on','Diagnostics', 'off','Display', 'off', 'DerivativeCheck', 'on','LargeScale', 'off' );
% warning off all
% [x resnorm residual] = lsqcurvefit(@RARETReq, [1 1], xdata,row, [0 0], '', options);
%
% save('D1.mat', 'D1' ,'row', 'xdata')
% pause
%RAREVTRFITV2    Create plot of datasets and fits
%   RAREVTRFITV2(D1,ROW)
%   Creates a plot, similar to the plot in the main curve fitting
%   window, using the data that you provide as input.  You can
%   apply this function to the same data you used with cftool
%   or with different data.  You may want to edit the function to
%   customize the code and this help message.
%
%   Number of datasets:  1
%   Number of fits:  1


% Data from dataset "row vs. D1":
%    X = D1:
%    Y = row:
%    Unweighted
%
% This function was automatically generated on 13-Mar-2009 17:30:02





% % --- Create fit "fit 1"
% fo_ = fitoptions('method','NonlinearLeastSquares','Lower',[0 0]);
% ok_ = isfinite(D1) & isfinite(row);
% if ~all( ok_ )
%     warning( 'GenerateMFile:IgnoringNansAndInfs', ...
%         'Ignoring NaNs and Infs in data' );
% end
% st_ = [1000 1000 ];
% set(fo_,'Startpoint',st_, 'Weight',W(ok_));
% ft_ = fittype('S0*(1-exp(-TR./T1))',...
%      'dependent',{'S'},'independent',{'TR'},...
%      'coefficients',{'S0', 'T1'});
%
% % Fit this model using new data
% [cf_ gof] = fit(D1(ok_),row(ok_),ft_,fo_);
%
% % Or use coefficients from the original fit:
% if 0
%    cv_ = { 5570.6962805019875304, 824.79300523715869531};
%    cf_ = cfit(ft_,cv_{:});
% end
%
% Szero = cf_.a;
% ST2   = (1/cf_.b);
% SR    = gof.rsquare;
%
% if(SR > 0.8)
%     fprintf('p');
% end
%  SQ = cf_.c;
%
%  S = Szero.*exp(-TE./ST2) + SQ;
%
% %  scatter(TE, Q), hold on, plot(TE, S), hold off
% %  SR
% t
% S
 %plot(t, S, 'bx'), hold on, plot(t, Szero.*exp(-t./ST2), 'g'), hold off
%  

Sout = [Szero SR ST2 SQ];

%pause
%
