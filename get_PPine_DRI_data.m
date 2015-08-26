function soilData = get_PPine_DRI_data( year )
% GET_PPINE_DRI_DATA - parse DRI data for Ponderosa Pine site to dataset
% array and extract the observations for a specified year.
%
% The PPine soil data are parsed from
% $FLUXROOT/Flux_Tower_Data_by_Site/PPine/secondary_loggers/DRI_logger/PPine_soil_data_20080101_20141118.dat.
%
% If this is not found, and new file must be created from the raw data
%
% INPUTS:
%     year: four-digit year; specifies the year for data extraction
%
% OUTPUTS
%     soilData: dataset array; SWC and Tsoil data for the specified year
%
% SEE ALSO
%     dataset
%
% author: Gregory E. Maurer, UNM, March 2015
% adapted from code by Timothy W. Hilton (preprocess_PPine_soil_data.m);

% This file contains the concatenated data for PPine
% Raw data files are in the PPine_2008_2014_raw_soil_data directory, and
% these are concatenated into file below by:
% concatenate_all_PPine_soil_data.m
fname = fullfile( get_site_directory( UNM_sites.PPine ), ...
    'secondary_loggers', 'DRI_logger', ...
    'PPine_soil_data_20080101_20141118.dat' );

if exist( fname, 'file' )
    fprintf( 'reading %s \n', fname );
    fmt = repmat( '%f', 1, 89 );
    ds = dataset( 'File', fname, ...
        'format', fmt, 'Delimiter', '\t' );
else
    try
        fprintf('%s file not found. Concatenating files...\n');
        ds = concatenate_all_PPine_soil_data();
    catch
        error( 'PPine DRI soil data not found! ');
    end
end

% Read the file to a dataset - FIXME to table (and regexp_ds_vars)
fmt = repmat( '%f', 1, 89 );
ds = dataset( 'File', fname, ...
              'format', fmt, 'Delimiter', '\t' );
          
% Find the SWC and SoilT variables
[ SWCvars, SWCidx ] = regexp_ds_vars( ds, 'VWC' );
[ SoilTvars, SoilTidx ] = regexp_ds_vars( ds, 'SoilT_C' );
% Remove extra columns
soilData = ds( :, { 'timestamp',  SWCvars{ : }, SoilTvars{ : } } );
% Change the header of the SWC columns
soilData.Properties.VarNames = regexprep( soilData.Properties.VarNames, ...
    'VWC', 'cs616SWC' );

% May be nice to remove negative SWC values... or not
%arr = double( SWC );
%arr( arr < 0 ) = NaN;
%SWC = replacedata( SWC, arr );

% return data for requested year
[ datayear, ~, ~, ~, ~, ~ ] = datevec( soilData.timestamp );
soilData = soilData( datayear == year, : );

warning('Compatibility check - Converting PPine data from dataset to table' );
soilData = dataset2table( soilData );







