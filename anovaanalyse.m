%Analyze the histograms with ANOVA repeated measures
%17th September, 2008

clear ADCvalues

subjects = [1 1 1 5 5 5 5 5 2 3 3 3 3 3 3 6 6 6];

tests    = [1 2 3 1 2 3 4 5 1 1 2 3 4 5 6 1 2 3];


for i = 4:8

    data = compact(i).all;
    data = data.ADC;
    
[phat pci] = normfit(data);

ADCvalues(i-3,1) = phat;
ADCvalues(i-3,2) = tests(i);
ADCvalues(i-3,3) = 1;%subjects(i);

end

RMAOV1a = RMAOV1(ADCvalues, 0.1)