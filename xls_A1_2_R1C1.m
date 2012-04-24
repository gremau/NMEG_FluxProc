function R1C1 = xls_A1_2_R1C1( A1 )
% xls_A1_2_R1C1 - convert a spreadsheet column reference in "A1" format to
% "R1C1" format
%   
% USAGE: 
%   R1C1 = xls_A1_2_R1C1(letter_column)
%
% INPUTS:
%   A1: column reference in "A1" style, e.g. B, CZ, etc.
%
% OUTPUTS:
%   R1C1: column reference in "R1C1" style: B becomes 2
%
% (c) Timothy W. Hilton, UNM, April 2012
    
    if length( A1 ) == 1
        R1C1 = A1 - 'A' + 1;
    elseif length( A1 ) == 2
        R1C1 = ( A1( 1 ) - 'A' + 1 ) * 26 + ...
              ( A1( 2 ) - 'A' + 1 );
    else
        error( 'A1 must be a two-element character array' );
    end
    
