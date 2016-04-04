function cr1000data = get_JSav_cr1000_data( year )
% GET_JSAV_CR1000_DATA - return all CR1000 data from a specified year
% in a table array.
%
% searches $FLUXROOT/Flux_Tower_Data_by_Site/JSav/soil for all CR1000 data
% files from a specified year.  Year must be greater than or equal to 2012.
% Prior to May 2012 JSav soil data were in the same TOA5 file as all other
% 30-minute variables ( main datalogger ).
%
% USAGE:
%     cr1000data = get_JSav_cr1000_data( year );
%
% INPUTS:
%     year: four digit year >= 2012.
%
% OUTPUTS
%     cr1000data: MATLAB table; JSav soil data for the requested year
%
% SEE ALSO
%     dataset
%
% author: Gregory E. Maurer, UNM, March 2015
% based on code by: Timothy W. Hilton, Dec 2012 (JSAV_CR1000_TO_DATASET)

% This is probably not needed anymore since work is done in
% card_data_processor and combine_and_fill scripts
warning('This file is deprecated!')

if year < 2012 | year > 2014
    error( ['Prior to May 2012 JSav soil water data were in the same TOA5 ' ...
        'file as all other 30-minute variables' ] );
end

dataDirectory = fullfile( getenv( 'FLUXROOT' ), ...
    'Flux_Tower_Data_by_Site', ...
    'JSav', 'secondary_loggers' );

% IMPORTANT: Make sure the files have the format:
% 'TOA5_JSav_cr1000_YYYY_MM_DD_HHMM.dat'
regularExpr = ...
    '^TOA5_JSav_cr1000_(\d\d\d\d)_(\d\d)_(\d\d)_(\d\d)(\d\d).(dat|DAT)$';

fileNames = list_files( dataDirectory, regularExpr );

% Make datenums for the dates
fileDateNumbers = tstamps_from_filenames(fileNames);

% Sort by datenum
[ fileDateNumbers, idx ] = sort( fileDateNumbers );
fileNames = fileNames( idx );

% Choose data files containing data from requested year, which should
% include the last file of the previous year ( by filename ).
s = datenum( year, 0, 0 );
e = datenum( year + 1, 0, 0 );
chooseFiles = find( fileDateNumbers > s & fileDateNumbers < e );
if min( chooseFiles ) ~= 1
    chooseFiles = [ min( chooseFiles ) - 1, chooseFiles ];
end

% This should concatenate data and fill in missing timestamps for all the
% chosen fileNames
cr1000data = combine_and_fill_datalogger_files( ...
    'file_names', fileNames( chooseFiles ), ...
    'datalogger_type', 'cr1000', 'resolve_headers', true );

