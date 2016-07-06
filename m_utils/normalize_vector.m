function out = normalize_vector( in, minval, maxval)
% NORMALIZE_VECTOR - normalized a vector of numeric data to [ minval, maxval ]
%   
% USAGE
%    out = normalize_vector( in, minval, maxval)
%
% INPUTS
%    in: numeric vector to be normalized
%    minval: minimum of the normalized data
%    maxval: maximum of the normalized data
%
% OUTPUTS
%    out: normalized data
%
% author: Timothy W. Hilton, UNM, Nov 2012

out = in - nanmin( in );
out = out ./ nanmax( out );

out = out .* ( maxval - minval );
out = out + minval;