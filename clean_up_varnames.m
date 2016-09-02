function clean_names = clean_up_varnames( messy_names )
% CLEAN_UP_VARNAMES - Reformat variable name strings into legal matlab variable
% names.
%
% See documentation for isvarname for rules for valid Matlab variable names.
%
% The operations performed here remove characters that occur commonly within
% UNM data file variables that are not legal in matlab variable names while
% attempting to preserve the readability of the variable name.
%
% Within variable names, the following operations are performed in the
% following order:
%    - the following symbols are replaced with _ (underscore): ( ) , ;
%    - the following symbols are removed: ^ " - space
%    - leading and trailing underscores are removed
%    - decimal points (defined as '.' occuring between two digits 0-9) are
%      replaced with 'p' (as in 'point')
%    - trailing whitespace is removed
%    - tab characters are removed
%
% USAGE
%    clean_names = clean_up_varnames( messy_names );
% 
% INPUTS
%     messy_names: string or cell array of strings; the variable names to be
%         "cleaned"
%
% OUTPUTS
%     clean_names: cell array of strings; the cleaned up variable names
%
% SEE ALSO
%     isvarname
%
% author: Timothy W. Hilton, UNM, Oct 2011


% replace ( ) , ; with _
clean_names = regexprep( messy_names, '[\(\),/;]', '_' );
% replace * with _star (For u* and T*)
clean_names = regexprep( clean_names, '\*','_star');
% remove ^ " - or whitespace
clean_names = regexprep( clean_names, '[\^" -]', '' );
% remove trailing _
clean_names = regexprep( clean_names, '_+$', '' ); 
% remove leading _
clean_names = regexprep( clean_names, '^_+', '' ); 
% replace decimal points in clean_names with 'p'
clean_names = regexprep( clean_names, '([0-9])\.([0-9])', '$1p$2' );
% replace % with prcnt
clean_names = regexprep( clean_names, '\%','prcnt');
% replace 2nd '_mean' with '_mean2'
if numel(clean_names) > 174;
clean_names{175} = 'mean2';
end
% remove trailing whitespace, 
clean_names = deblank(clean_names); 
%remove tabs
clean_names = strrep(clean_names, '\t', '');



