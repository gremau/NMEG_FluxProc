function tstamps = tstamps_from_TOB1_filenames( fnames )
% TSTAMPS_FROM_TOB1_FILENAMES - extracts timestamps from TOB1 file names and
%   returns them as Matlab serial datenumbers.  Filename timestamps must be in
%   format YYYY_MM_DD_HHMM.
%
% USAGE
%   tstamps = tstamps_from_TOB1_filenames( fnames );
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
% author: Timothy W. Hilton, UNM, Sep 2012

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

tstamps = [ tstamps{:} ];



