function str_out = format_probe_strings( str_in )
% FORMAT_PROBE_STRINGS - format soil data probe cover type labels using a common
% set of conventions. 
%
% There are a wide variety of variations in the labeling style of the soil data
% cover type within different sites' datalogger code.  This reformats probe
% labels by performing the following steps, in the following order:

% - open pits are usually designated with "O", but sometimes 'o' or '0'.
%     Change to "O"
% - juniper pits are usually designated with "J", but sometimes 'j'
%     Change to "J"
% - grass pits are usually designated with "g", sometimes "G"
%     Change to "G"
% - add separating underscore to J1, etc. probe designations
% - remove any parens that made it this far
% - remove trailing underscores
% - change decimal points to "p" (for legal Matlab variable names)
% - change _O_ to _open_, _J_ to _juniper_, _G_ to _grass_, _S_ to _cover_
%
% USAGE
%     str_out = format_probe_strings( str_in );
%
% INPUTS
%     str_in: cell array of strings; the probe strings to be formatted
%
% OUTPUTS
%     str_out: cell array of strings; str_in reformatted as described above
%
% author: Timothy W. Hilton, UNN, Dec 2012

% open pits are usually designated with "O", but sometimes 'o' or '0'
str_out = regexprep( str_in, '_[Oo0]([0-9])_', '_O_$1_' );
% juniper pits are usually designated with "J", but sometimes 'j'
str_out = regexprep( str_out, '_j([0-9])_', '_J$1_' );
% grass pits are usually designated with "g"
str_out = regexprep( str_out, '_g([0-9])_', '_G_$1_' );
% add separating underscore to J1, etc. probe designations
str_out = regexprep( str_out, '_([GJOS])([0-9])_', '_$1_$2_' );
% remove any parens that made it this far
str_out = regexprep( str_out, '[\(\)]', '_' );
% remove trailing underscores
str_out = regexprep( str_out, '_$', '' );
% change decimal points to "p" (for legal Matlab variable names)
str_out = regexprep( str_out, '([0-9])\.([0-9])', '$1p$2' );
% change _O_ to _open_, _J_ to _juniper_, _G_ to _grass_
str_out = regexprep( str_out, '_O_', '_open_' );
str_out = regexprep( str_out, '_J_', '_juniper_' );
str_out = regexprep( str_out, '_G_', '_grass_' );
str_out = regexprep( str_out, '_S_', '_cover_' );