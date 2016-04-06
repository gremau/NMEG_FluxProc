function arr = replace_badvals( arr, badvals, tol )
% REPLACE_BADVALS - replace specifed values within an array with NaN, with
% floating point comparison 
% 
% (see, for example, http://support.microsoft.com/kb/69333,
% http://en.wikipedia.org/wiki/Floating_point).
%
% Elements of arr that are equal to any element of badvals are replaced with NaN.
% 
% USAGE
%     arr = replace_badvals( arr, badvals, tol )
%
% INPUTS
%     arr: table or dataset array in which to replace bad values
%     badvals: array of values to be replace with NaN
%     tol: tolerance for floating point comparison; floating point values
%         that differ by less than tol are considered equal.
%
% OUTPUTS
%     arr: input array with specified bad values replaced with NaNs
%
% SEE ALSO
%     dataset
%
% author: Timothy W. Hilton, UNM
% modified by Gregory E. Maurer, UNM
    
arg_is_dataset = false;
arg_is_table = false;

if isa( arr, 'dataset' )
    arg_is_dataset = true;
    arr_arg = arr;
    arr = double( arr );
elseif isa( arr, 'table' )
    arg_is_table = true;
    arr_arg = arr;
    arr = table2array( arr );
end

badvals = reshape( badvals, 1, [] );
badval_idx = zeros( size( arr ) );

for i = 1:length( badvals )
    
    badval_idx = badval_idx | abs( arr - badvals( i ) ) < tol;
    arr( badval_idx ) = NaN;
    
end

% Convert back to table/dataset
if ( arg_is_dataset )
    arr = replacedata( arr_arg, arr );
elseif ( arg_is_table )
    arr = array2table( arr, ...
        'VariableNames', arr_arg.Properties.VariableNames );
    arr.Properties.VariableUnits = arr_arg.Properties.VariableUnits;
end
