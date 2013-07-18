function SWC = preprocess_MCon_soil_data( year )
% PREPROCESS_MCON_SOIL_DATA - parse combined MCon soil data file and return soil
%   water content 

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
                               't_min', datenum( year, 1, 1 ), ...
                               't_max', datenum( year, 12, 31, 23, 59, 59 ) );