function SWC = preprocess_MCon_soil_data( year, timestamps )
% PREPROCESS_MCON_SOIL_DATA - parse combined MCon soil data file and return soil
%   water content.
% 
% FIXME - Deprecated. This function will be superceded by 
%                     parse_MCon_SAHRA_data.m
%
% Soil data for the mixed conifer site are collected by Desert Research
% Institute (DRI) and posted online. Timothy W. Hilton wrote Matlab code to
% combine the downloaded DRI files into a single data file
% $FLUXROOT/Flux_Tower_Data_by_Site/MCon/soil_data/MCon_combined_soil_water_data.dat.
% For details see README and concatenate_all_MCon_soil_data.m within
% $FLUXROOT/Flux_Tower_Data_by_Site/MCon/soil_data/.  The combined file contains
% many observations in addition to soil water content: wind data, sap data, etc.
% preprocess_MCon_soil_data parses the combined file, extracts the soil water
% content data for a specified year to a dataset array, and converts the
% timestamps to Matlab serial datenumbers.  It then calls
% dataset_fill_timestamps to remove duplicated timestamps and fill any missing
% timestamps with NaNs.
%
% INPUTS: 
%    year: four digit year to be processed
%    timestamps: 1xN array of Matlab serial datenums; SWC timestamps are
%        filled to contain a complete record of 30-minute timestamps between the
%        earliest and latest dates contained in this argument.
%
% OUTPUTS:
%    SWC: dataset array; soil water content observations
% 
% SEE ALSO
%    datenum, dataset, dataset_fill_timestamps
%
% author: Timothy W. Hilton, UNM, Aug 2012

warning( 'This function ( preprocess_MCon_soil_data ) is deprecated ');

fname = fullfile( get_site_directory( UNM_sites.MCon ), ...
                  'soil_data', ...
                  'MCon_combined_soil_water_data.dat' );

% get header line to count variables
fid = fopen( fname, 'r' );
header = fgetl( fid );
vars = regexp( header, ',', 'split' );
fclose( fid );

% parse the data
start_row = 1; %skip header row -- already read it.
start_col = 0;
delimiter = ',';
data = dlmread( fname , delimiter, start_row, start_col );

% create dataset object
ds = dataset( { data, vars{ : } } );

SWC_vars = regexp_ds_vars( ds, 'SWC' );
SWC = ds( :, SWC_vars );

SWC_temp = double( SWC );
idx_bogus = SWC_temp < 0;
SWC_temp( idx_bogus ) = NaN;
SWC = replacedata( SWC, SWC_temp );

SWC.timestamp = datenum( num2str( ds.DateTime_YYMMDDhhmm, '%0.10d' ), ...
                        'yymmddHHMM' );
SWC.Properties.VarNames = regexprep( SWC.Properties.VarNames, ...
                                     'SWC', 'cs616SWC' );

% return data for requested year
[ datayear, ~, ~, ~, ~, ~ ] = datevec( SWC.timestamp );
SWC = SWC( datayear == year, : );

% make sure it is a complete series of 30-minute timestamps
SWC = dataset_fill_timestamps( SWC, ...
                               'timestamp', ...
                               't_min', min( timestamps ), ...
                               't_max', max( timestamps ) );