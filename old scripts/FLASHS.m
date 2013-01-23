%FLASHS gives the function for curve fitting

function S = FLASHS(x, xdata)
  
  TR    = xdata{1}.TR;
  alpha = xdata{1}.alpha;
  
  S0    = x(1);
  R1    = x(2);
  
  for i = 1:numel(alpha)
  S(i) = S0*(sin(alpha(i))*(1-exp(-TR*R1))/(1-exp(-TR*R1)*cos(alpha(i))));
  end
  S = S(:);
  
  
  
  