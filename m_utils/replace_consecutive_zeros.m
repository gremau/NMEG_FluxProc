function out = replace_consecutive_zeros( in, n, new_val )
% REPLACE_CONSECUTIVE_ZEROS - replace more than n consective zeros in a
% vector with a different value
%   
% USAGE
%    out = replace_consecutive_zeros( in, n, new_val )
%
% INPUTS:
%    in: numerical vector: data to be manipulated
%    n: more than n consecutive zeros will be replaced with new_val
%    new_val: value to replace consecutive zeros with
%
% OUTPUTS:
%    out: numerical vector of same dimensions as in, with consecutive zeros
%        replace with new_val
%
% (c) Timothy W. Hilton, UNM, Nov 2012

in_row = reshape( in, 1, [] );
runs = rle( in_row );
vals = runs{ 1 };
lengths = runs{ 2 };
idx_rle = find( ( vals == 0 ) & ( lengths > n ) );

vals( idx_rle ) = new_val;
out = rle( { vals, lengths } );

out = reshape( out, size( in ) );