function clean_names = clean_up_varnames(messy_names)
% CLEAN_UP_VARNAMES - processes variable name strings into names that matlab
%   will find acceptable

% replace ( ) , ; with _
clean_names = regexprep( messy_names, '[\(\),/;]', '_' );
% remove ^ " - or whitespace
clean_names = regexprep( clean_names, '[\^" -]', '' );
% remove trailing _
clean_names = regexprep( clean_names, '_+$', '' ); 
% remove leading _
clean_names = regexprep( clean_names, '^_+', '' ); 
% replace decimal points in clean_names with 'p'
clean_names = regexprep( clean_names, '([0-9])\.([0-9])', '$1p$2' );

% remove trailing whitespace, 
clean_names = deblank(clean_names); 
%remove tabs
clean_names = strrep(clean_names, '\t', '');


