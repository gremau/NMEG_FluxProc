function fnames = get_loggernet_filenames( site_code, date_start, date_end, ...
    type, varargin )
% GET_LOGGERNET_FILENAMES - find all TOB1 or TOA5 files for a specified site and
% date range.
%
% generates a list of filenames containing all TOB1 or TOA5 files within the
% site's data directory that contain data from between start date and end date.
% The directories searched are SITEDIR/ts_data, SITEDIR/toa5, or SITEDIR/subdir,
% where SITEDIR is the output of get_site_directory( site_code ).
%
% USAGE:
%   fnames = get_loggernet_filenames( site_code, date_start, date_end, type )
%   
% INPUTS:
%   site_code: integer; the site numeric code
%   date_start: matlab datenumber; the starting date
%   date_end: matlab_datenumber; the ending date
%   type: string; TOA5 or TOB1
% OPTIONAL INPUTS
%   subdir: string indicating subdirectory to look in
% OUTPUTS:
%   fnames: cell array of strings; list of complete paths of TOB1/A5 files
%
% SEE ALSO
%   get_site_directory
%
% author: Timothy W. Hilton, UNM, Dec 2011
% Modified by Gregory E. Maurer, UNM, March 2016

args = inputParser;
args.addRequired( 'site_code', @(x) ( isintval(x) | isa( x, 'UNM_sites' )));
args.addRequired( 'date_start', @isnumeric );
args.addRequired( 'date_end', @isnumeric );
args.addRequired( 'type', @(x) strcmpi( x, 'toa5' ) | strcmpi( x, 'tob1' ));
args.addParameter( 'subdir', '', @ischar );

% parse required and optional inputs
args.parse( site_code, date_start, date_end, type, varargin{ : } );
site_code = args.Results.site_code;
date_start = args.Results.date_start;
date_end = args.Results.date_end;
type = args.Results.type;
subdir = args.Results.subdir;
% Get default flux data subdirectory if no other subdir provided
if ~isempty( subdir )
    data_subdir = subdir;
else
    switch lower( type )
        case 'toa5'
            data_subdir = 'toa5';
        case 'tob1'
            data_subdir = 'ts_data';
    end
end
% Get the data directory path
data_dir = fullfile( get_site_directory( site_code ), ...
    data_subdir );
% Choose the regex based on file type
switch lower( type )
    case 'toa5'
        re = '^TOA5_.*_(\d\d\d\d)_(\d\d)_(\d\d)_(\d\d)(\d\d).*\.(dat|DAT)$';
    case 'tob1'
        re = '^TOB1_.*_(\d\d\d\d)_(\d\d)_(\d\d)_(\d\d)(\d\d).*\.(dat|DAT)$';
end
% Get filenames
fnames = list_files( data_dir, re );

% make datenums for the dates
dns = tstamps_from_filenames( fnames );

% sort by date
[ dns, idx ] = sort( dns );
fnames = fnames( idx );

% find the files that are within the date range requested
idx = find( ( dns >= date_start ) & ( dns <= date_end ) );
% if looking at TOA5 files, included the latest file dated *before* the
% start date -- it could contain data from the requested range
if all( dns < date_start ) & strcmpi( type, 'TOA5' )
    idx = numel( dns );
elseif ( not(strcmp( type, 'TOB1' ))) & ( idx( 1 ) ~= 1 )
    idx = [ idx( 1 ) - 1, idx ];
end
fnames = fnames( idx );

%------------------------------------------------------------
