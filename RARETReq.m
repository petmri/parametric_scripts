%function RARETR

function S = RARETReq(x, xdata)

Szero = x(1);
T1    = x(2);

TR    = xdata{1}.TR;
W     = xdata{1}.W;

for i = 1:numel(TR)
S(i) = W(i)*(Szero*(1-exp(-TR(i)/T1)));
end

