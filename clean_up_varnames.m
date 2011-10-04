function clean_names = clean_up_varnames(messy_names)
% CLEAN_UP_VARNAMES - processes variable name strings into names that matlab
%   will find acceptable

    %remove quotations 
    clean_names = strrep(messy_names, '"', '');  
    % throw out parenthesized portions of varnames
    clean_names = strtok(clean_names, '(');      
    % remove trailing whitespace, 
    clean_names = deblank(clean_names); 
    %change remaining spaces to '_'
    clean_names = strrep(clean_names, ' ', '_');
    %remove tabs
    clean_names = strrep(clean_names, '\t', '');
    % remove '-' characters from varnames
    clean_names = strrep(clean_names, '-', '');  
    