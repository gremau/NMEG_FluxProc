function tstamps = tstamps_from_filenames( fnames )
% TSTAMPS_FROM_FILENAMES - extracts timestamps (in format YYYY_MM_DD_HHMM)
% from data file names and returns them as Matlab serial datenumbers.
%
% USAGE
%   tstamps = tstamps_from_filenames( fnames );
%
% INPUTS
%   fnames: cell array of strings containing file names
%
% OUTPUTS
%   tstamps: array of datenums corresponding to file names
%
% SEE ALSO
%   datenum
%
% author: Gregory E. Maurer, UNM, Jan 2015
% Adapted from Tim Hilton's code 'tstamps_from_TOB1_filenames.m'

%read the time stamps from the file names into matlab datenums
tstamp_strings = regexp( fnames, ...
                         '\d\d\d\d_\d\d_\d\d_\d\d\d\d', ...
                         'match', 'once' );

% ignore files with no properly-formatted timestamp in the file name
empty_idx = find( cellfun( @isempty, tstamp_strings ) );
tstamp_strings( empty_idx ) = [];

tstamps = cellfun( @( x ) datenum(x, 'yyyy_mm_dd_HHMM'), ...
              tstamp_strings, ...
              'UniformOutput', false );

tstamps = cell2mat( tstamps );



