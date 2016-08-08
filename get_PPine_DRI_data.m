function DRIsoil = get_PPine_DRI_data( year )
% GET_PPINE_DRI_DATA - parse DRI data for Ponderosa Pine site to table
% array and extract the observations for a specified year.
%
% The PPine soil data are parsed from
% $FLUXROOT/SiteData/PPine/secondary_loggers/DRI_logger/PPine_soil_data_20080101_20141118.dat.
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
%     table
%
% author: Gregory E. Maurer, UNM, March 2015
% adapted from code by Timothy W. Hilton (preprocess_PPine_soil_data.m);

% This file contains the concatenated data for PPine
% Raw data files are in the PPine_2008_2014_raw_soil_data directory, and
% these are concatenated into file below by:
% concatenate_all_PPine_soil_data.m
fname = fullfile( get_site_directory( UNM_sites.PPine ), ...
    'secondary_loggers', 'DRI_logger', ...
    'PPine_soil_data_20080101_20150128.dat' );

if exist( fname, 'file' )
    fprintf( 'reading %s \n', fname );
    fmt = repmat( '%f', 1, 89 );
    tbl = readtable( fname, 'Delimiter', '\t' );
else
    try
        fprintf('%s file not found. Concatenating files...\n');
        tbl = concatenate_all_PPine_soil_data();
    catch
        error( 'PPine DRI soil data not found! ');
    end
end

% Get header names for T and VWC    
[ t_vars, t_var_idx ] = regexp_header_vars( tbl, 'SoilT_C' );
[ w_vars, w_var_idx ] = regexp_header_vars( tbl, 'VWC_' );

DRIsoil = tbl( :, { 'timestamp', t_vars{:}, w_vars{:} } );

% Change the header of the SWC and SoilT columns
DRIsoil.Properties.VariableNames = regexprep( ...
    DRIsoil.Properties.VariableNames, ...
    'VWC', 'SWC_DRI' );
DRIsoil.Properties.VariableNames = regexprep( ...
    DRIsoil.Properties.VariableNames, ...
    'SoilT_C', 'SOILT_DRI' );

% return data for requested year
[ datayear, ~, ~, ~, ~, ~ ] = datevec( DRIsoil.timestamp );
getyear = find( datayear==year) + 1;
getyear = getyear( getyear < numel( datayear )+1 );
DRIsoil = DRIsoil( getyear, : );  







