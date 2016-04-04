function cr23x_fnames = get_cr23x_filenames( sitecode, ...
                                             start_date, end_date, subdir )
% GET_CR23X_FILENAMES - parse CR23X soil data for PJ or PJ_girdle.
%
% Retrieves a list of filenames for CR23X files in a specified subdirectory
% (below the default site data directory). Filenames are parsed and files
% containing data outside of the requested date range are excluded.
%
% USAGE
%    cr23xData = get_cr23x_filenames( sitecode, start_date, end_date, ...
%                                                           subdir )
% INPUTS
%    sitecode: integer or UNM_sites object; either PJ or PJ_girdle
%    start_date: matlab datenumber; the starting date
%    end_date: matlab_datenumber; the ending date
%    subdir: string indicating subdirectory to look in
% OUTPUTS:
%    cr23x_fnames: matlab cell array containing all the names of all
%       datalogger files in the specified time period
%
%
% author: Gregory E. Maurer, UNM, March 2015

% Modified by Gregory E. Maurer, UNM, March 2016

args = inputParser;
args.addRequired( 'sitecode', @(x) ( isintval(x) | isa( x, 'UNM_sites' )));
args.addRequired( 'start_date', @isnumeric );
args.addRequired( 'end_date', @isnumeric );
args.addRequired( 'subdir', @ischar );

% parse required and optional inputs
args.parse( sitecode, start_date, end_date, subdir );
sitecode = args.Results.sitecode;
start_date = args.Results.start_date;
end_date = args.Results.end_date;
subdir = args.Results.subdir; 

% determine file path for site and add subdirectory
filePath = fullfile( get_site_directory( sitecode ), subdir );

% IMPORTANT: Make sure the files have the format:
% 'cr23x_$sitename$_YYYY_MM_DD_HHMM.dat'
% or similar
regularExpr = ...
    '^cr23x_.*_(\d\d\d\d)_(\d\d)_(\d\d)_(\d\d)(\d\d).*\.(dat|DAT)$';
fileNames = list_files( filePath, regularExpr );

% Make datenums for the dates
fileDateNumbers = tstamps_from_filenames(fileNames);

% Sort by datenum
[ fileDateNumbers, idx ] = sort( fileDateNumbers );
fileNames = fileNames( idx );

% Choose data files containing data from requested time period, which
% includes the last file of the previous year ( by filename ).
chooseFiles = find( fileDateNumbers >= start_date & ...
    fileDateNumbers <= end_date );
if min( chooseFiles ) ~= 1
    chooseFiles = [ min( chooseFiles ) - 1, chooseFiles ];
end

cr23x_fnames = fileNames( chooseFiles );

