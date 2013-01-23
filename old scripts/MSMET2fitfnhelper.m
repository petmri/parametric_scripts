%% MGET2star fit fn v2 helper wrapper to allow usage on neuroecon

function  Sout = MGET2starfitfnhelper(xdata, numvoxels)

 %Sout = zeros(numvoxels, 4);

parfor j = 1:numvoxels%(j = found(1:100)')

    
    % if(numel(find(j == found)) > 1)
    
    
    Sout(j,:) = MGET2starfitfnv3(xdata, j);
    

    
    %else
    %   SzeroA(j) = factor;
    %  SRA(j)    = factor;
    % SADCA(j)  = factor;
    %SQA(j)    = factor;
    %end
    
end