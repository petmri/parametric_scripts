function sse=fitfun(params,Input,Actual_Output)
So=params(1);
T1=params(2);
%C =params(3);

Fitted_Curve=So.*(1-exp(-Input./T1));
Error_Vector=Fitted_Curve - Actual_Output;
% When curvefitting, a typical quantity to
% minimize is the sum of squares error
sse=sum(Error_Vector.^2);
% You could also write sse as
% sse=Error_Vector(:)'*Error_Vector(:);