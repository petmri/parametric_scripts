% Check if TR is in the equation and if so, whether the TR has been defined
function [errormsg, tr_ready, equation, ncoeffs] = check_TRfit(handles, fit_file);

errormsg = '';
equation = '';
tr_ready = 0;
ncoeffs  = 0;

%1. Check presence of fit_file

if ~exist(fit_file)
    errormsg = 'File does not exist';
    return;
else
    fid_fit = fopen(fit_file);
    tline = fgets(fid_fit);
    while ischar(tline)
        
        if ~isempty(strfind(tline, 'ft = fittype('))
            comma = strfind(tline, ',');
            bracket=strfind(tline, '(');
            equation = tline((bracket(1)+1):(comma(1)-1));
            % Make fittype object
            eval(tline);
            % find number of coeff
            coeffs  = coeffnames(ft);
            for i = 1:numel(coeffs)
                if strcmp(coeffs{i}, 'tr')
                    % Check if tr is defined
                    if isempty(num2str(str2num(get(handles.tr, 'String'))))
                        errormsg = 'TR not defined, but needed';
                        return
                    else
                        tr_ready = str2num(get(handles.tr, 'String'));
                    end
                end
                
            end
            if ~tr_ready
                tr_ready = 1;
            end
        end
        
        tline = fgets(fid_fit);
    end
    
    ncoeffs=  numel(coeffs);
    
end

