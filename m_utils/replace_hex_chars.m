function str_out = replace_hex_chars( str_in )
% REPLACE_HEX_CHARS - replace hexadecimal representations of characters '(',
%   ')', ',', '.' with characters that are legal in matlab variable names
%
% USAGE
%     str_out = replace_hex_chars( str_in )
%
% INPUTS
%     str_in: string or cell array of strings
%
% OUTPUTS
%     str_out: string or cell array of strings (same as str_in) with
%         hexadecimal characters replaced
%
% author: Timothy W. Hilton, UNM, July 2012


if ischar( str_in ) 
    str_out = replace_hex_chars_single_string( str_in );
elseif iscell( str_in )
    str_out = cellfun( @replace_hex_chars_single_string, ...
                       str_in, ...
                       'UniformOutput', false );
end

%============================================================

function str_out = replace_hex_chars_single_string( str_in )
% DO_REPLACEMENT - helper function -- does the actual regular expression
%   replacement for replace_hex_chars

re_hex = '0x[0-9A-F][0-9A-F]'; %regular expression to match two-character
                               %hexadecimal numbers

% find hexadecimal characters within str_in
hex_chars = regexp( str_in, re_hex, 'match' );...
if not( isempty( hex_chars ) )
    % convert hex chars to ascii
    ascii_chars = cellfun( @(str) { char( sscanf( str, '%x' ) ) }, hex_chars );
    % replace the hex chars in str_in with their ascii representation
    str_out = regexprep( str_in, re_hex, ascii_chars, 'once' );
else
    str_out = str_in;
end

