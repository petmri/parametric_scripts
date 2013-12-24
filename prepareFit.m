% Read a Curve-fitting tool box extracted data, comment out plot commands,
% add output structure to the variables returned and extract the equation
% to show on the GUI

function [equation, fit_name, errormsg, ncoeffs, coeffs] = prepareFit(fit_file)

errormsg = '';
equation = '';
fit_name = '';
ncoeffs = 0;
coeffs   = '';

%1. Check presence of fit_file

if ~exist(fit_file)
    errormsg = 'File does not exist';
    return;
else
    tmp_fit_file = strrep(fit_file, '.m', '_tmp.m');
    
    fid_fit = fopen(fit_file);
    
    fid_tmp = fopen(tmp_fit_file, 'w');
    
    tr = 0;
    file_contents = '';
    
    tline = fgets(fid_fit);
    while ischar(tline)
        
        if ~isempty(strfind(tline, '[fitresult, gof]'))
            tline = strrep(tline, '[fitresult, gof]', '[fitresult, gof, output]');
        end
        
        if ~isempty(strfind(tline, 'ft = fittype('))
            comma = strfind(tline, ',');
            bracket=strfind(tline, '(');
            equation = tline((bracket(1)+1):(comma(1)-1));
            
            % Make fittype object
            eval(tline);
            % find number of coeff
            ncoeffs = numcoeffs(ft);
            coeffs  = coeffnames(ft);
            
            if strfind(equation, 'tr')
                tr = 1;
                % Need to add tr as an input at file line 
                % and remove it from coeffs list
                ncoeffs = ncoeffs-1;
                
                for i = 1:numel(coeffs)
                    if(strcmp(coeffs{i}, 'tr'))
                        coeffs(i) = [];
                    end
                end
            end
            
        end
        
        if ~isempty(strfind(tline, 'Plot fit with data'))
            tline = '%{';
        end
        
        if ~isempty(strfind(tline, 'figure('))
            comma = strfind(tline, ',');
            bracket=strfind(tline, ')');
            fit_name = tline((comma(1)+1):(bracket(1)-1));
            fit_name = strrep(fit_name, ' ', '_');
        end
        
        % If tr is part of the equation, need to convert that into a
        % independent variable.
        
        if ~isempty(strfind(tline, '''independent'', ''x'',')) && strfind(equation, 'tr')
            
            tline = strrep(tline, '''independent'', ''x'',', '''independent'', {''x'',''tr''},');
            
        end
        
        file_contents{end+1}.String = tline;
        
        tline = fgets(fid_fit);
    end
    
    
    % Write to temp file
    for i = 1:numel(file_contents)
        
        tline = file_contents{1}.String;
        
        if tr
            if strfind(tline, 'function ')
                tline = strrep(')', ', tr)');
            end
        end
        
        fprintf(fid_tmp,'%s\r\n',tline);
    end
    fprintf(fid_tmp,'%s\r\n','%Modified by ROCKETSHIP to comment out plot');
    fprintf(fid_tmp,'%s\r\n','%}');
    
    fclose(fid_fit);
    fclose(fid_tmp);
    % movefile(tmp_fit_file, 'fit_file', 'f');
    
end

