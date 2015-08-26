function cr1000Data = get_MCon_cr1000_data( year )
% GET_MCON_CR1000_DATA - return all CR1000 data from a specified year
% in a table array.
%
% searches $FLUXROOT/Flux_Tower_Data_by_Site/MCon/secondary_loggers/precip_cr1000/TOA5Processed
% for all CR1000 met station data files from a specified year. Year must be
% greater than or equal to 2014 since Prior to 2014 this cr1000 did not exist.
%
% USAGE:
%     ds = get_MCon_cr1000_data( year );
%
% INPUTS:
%     year: four digit year >= 2012.
%
% OUTPUTS
%     ds: dataset array; MCon precip station data for the requested year
%
% SEE ALSO
%     dataset
%
% author: Gregory E. Maurer, UNM, March 2015
% based on code by: Timothy W. Hilton, Dec 2012 (JSAV_CR1000_TO_DATASET)

if year < 2014
    warning( ['Prior to 2014 there was no precip CR1000 at MCon' ] );
    cr1000Data = dataset();
    return
end

dataDirectory = fullfile( get_site_directory( UNM_sites.MCon ), ...
    'secondary_loggers', 'precip_cr1000', 'TOA5Processed' );

% IMPORTANT: Make sure the files have the format:
% 'TOA5_49012.precip_out_YYYY_MM_DD_HHMM.dat'
regularExpr = ...
    '^TOA5_49012.precip_out_(\d\d\d\d)_(\d\d)_(\d\d)_(\d\d)(\d\d).(dat|DAT)$';

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

if ~isempty( chooseFiles );
    % This should concatenate data and fill in missing timestamps for
    % all thefileNames. Dont think headers have changed at this point.
    cr1000Data = combine_and_fill_datalogger_files( ...
        'file_names', fileNames( chooseFiles ), ...
        'datalogger_type', 'cr1000', 'resolve_headers', false );
    % FIXME - changing var names so they don't conflict with tower ones
    change = find( strcmp( 'RH', cr1000Data.Properties.VariableNames ))
    cr1000Data.Properties.VariableNames{ change } = 'RH_cr1k';
    
elseif isempty( chooseFiles )
    fprintf( 'No cr1000 data available for MCon in %d\n', year );
    cr1000Data = table([]);
end
