function dn = nan_datenum( str, fmt )
% NAN_DATENUM - processes strings to matlab datenums, also handling missing
% elements (NaNs).  Matlab's datenum function refuses to process NaNs if
% given the optional format string as input.
%   
% USAGE
%   dn = nan_datenum( str, fmt )
%
% INPUTS
%   str: character array (representing a date), or NaN
%   fmt: character array specifying date format (see datenum documentation)
%
% OUTPUTS
%   dn: if str represents a date, a matlab datenum.  If str is NaN, NaN.
%
% SEE ALSO
%   datenum
%
% author: Timothy W. Hilton, UNM, April 2012

dn = NaN;

if ~isempty( str )
    dn = datenum( str, fmt );
end
