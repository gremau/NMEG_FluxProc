function result = true_or_false( in )
% TRUE_OR_FALSE - return true if input argument is [true] or [false]
%   
% returns true if in is a one-element vector containing a logical value (true
% or false).  Differs from islogical in that true_or_false returns false if
% its input has more than one element.
%
% result = true_or_false( in );
%
% INPUTS
%    in: any matlab variable; the object to be tested
% 
% OUTPUTS
%    result: true contains a single logical value, false otherwise.
%
% author: Timothy W. Hilton, UNM, August 2013

result = ( numel(in) == 1 ) & all( ismember( in, [ true, false ] ) );




 
