function [result] = isintval(x)
% ISINTVAL -- check whether a variable has an integer value
%
% This is different from isinteger(), which checks the *class*.  A
% variable of class double with an integral value will return true here.
%
% usage
%    result = isintval(x);
% 
% INPUTS:
%    x: matlab object
% OUTPUTS:
%    result: true|false; true if x contains an integral value
%
% SEE ALSO
%    isinteger
%
% author: Timothy W. Hilton, UNM, August 2011

result = isnumeric(x) && mod(x, 1) == 0;

