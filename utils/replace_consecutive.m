function out = replace_consecutive( in, n, varargin )
% REPLACE_CONSECUTIVE - replace more than n consective identical values in
% a vector with a different value
%   
% USAGE
%    out = replace_consecutive_zeros( in, n, new_val )
%
% INPUTS:
%    in: numerical vector: data to be manipulated
%    n: more than n consecutive zeros will be replaced with new_val
% KEYWORD ARGUMENTS
%    flag_val: optional; if specified, the value whose consecutive instances will
%        be replaced.  Default is zero.
%    new_val: optional; value to replace consecutive instances of flag_val
%        with.  Default is NaN.
%
% OUTPUTS:
%    out: numerical vector of same dimensions as in, with consecutive zeros
%        replace with new_val
%
% (c) Timothy W. Hilton, UNM, Nov 2012

% -----
% define optional inputs, with defaults and typechecking
% -----
args = inputParser;
args.addRequired( 'in', @isnumeric );
args.addRequired( 'n', @isnumeric );
args.addParamValue( 'flag_val', 0.0, @isnumeric );
args.addParamValue( 'new_val', NaN, @isnumeric );

% parse optional inputs
args.parse( in, n, varargin{ : } );
in = args.Results.in;
n = args.Results.n;
flag_val = args.Results.flag_val;
new_val = args.Results.new_val;

% -----
% arguments are parsed -- now do the work
% -----

in_row = reshape( in, 1, [] );
runs = rle( in_row );
vals = runs{ 1 };
lengths = runs{ 2 };
idx_rle = find( ( abs( vals - flag_val ) < 1e-10 ) & ( lengths > n ) );

vals( idx_rle ) = new_val;
out = rle( { vals, lengths } );

out = reshape( out, size( in ) );