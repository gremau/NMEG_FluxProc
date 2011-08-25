%----------
% check whether a variable has an integer value
% this is different from isinteger(), which checks the *class*.  A
% variable of class double with an integral value will pass here.
% INPUTS:
%   x: matlab object
% OUTPUTS:
%   result: logical; true if x contains an integral value
%
%Timothy W. Hilton, UNM, August 2011
     
function [result] = isintval(x)
    result = isnumeric(x) && mod(x, 1) == 0;

