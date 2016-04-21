function ds = concatenate_all_MCon_soil_data()
% CONCATENATE_ALL_MCON_SOIL_DATA - concatenate all .dat files from the working directory into a single MCon soil dataset object
%   
% FIXME - deprecated file, replaced by parse_MCon_SAHRA_data.m
%
ds = parse_MCon_soil_DAT_file( 'MCon_soil_data_20070101_20130814.dat' );

%==================================================_
function ds = parse_MCon_soil_DAT_file( fname )
% PARSE_PPINE_SOIL_DAT_FILE - parse a single MCon soil .dat file
%   

n_headerlines = 4;
dlm = ',';  % files are comma-delimited

% parse the headers (four lines)
headerlines = cell( n_headerlines, 1 );
fid = fopen( fname, 'r' );
for i = 1:n_headerlines
    headerlines{ i } = fgetl( fid );
end
fclose( fid );

% pull out and format the headers
headers = process_headers( headerlines );
% parse the data into a dataset object
ds = dlmread( fname, dlm, n_headerlines + 1, 0 );
ds = dataset( { ds, headers{ : } } );
ds.timestamp = datenum( num2str( ds.DateTime_YYMMDDhhmm, '%0.10d' ), ...
                        'yymmddHHMM' );

% calibration factor of 10000 for soil water content data
[ ~, swc_idx ] = regexp_ds_vars( ds, 'SWC' );
swc = double( ds( :, swc_idx ) ) / 1e4;
swc = replacedata( ds( :, swc_idx ), swc );
ds( :, swc_idx ) = swc;

% we don't know what the fourth column in each soil water pit represents --
% remove these data from the output
[ ~, idx_discard ] = regexp_ds_vars( ds, 'SWC_.*_4$' );
ds( :, idx_discard ) = [];

% data are hourly; interpolate to 30-minutes
ds = hourly_2_30min( ds );

% export data to a comma-delimited ASCII file
all_but_datenum_timestamp = 1:( size( ds, 2 ) - 1 );
out_file = fullfile( pwd(), 'MCon_combined_soil_water_data.dat' );
fprintf( 'writing output to %s...', out_file );
export( ds( :, all_but_datenum_timestamp ), ...
        'File', out_file, ...
        'Delimiter', ',' );
fprintf( 'done\n' );


%==================================================
function headers = process_headers( headerlines )
% PROCESS_HEADERS - process the headers from their formats in the file to
%   descriptive matlab-legal variable names

headerlines = regexprep( headerlines, ':', '' );
headerlines = regexprep( headerlines, '[ \t/\.]', '' );
headerlines = regexprep( headerlines, '-', '_' );
h3 = regexp( headerlines{ 3 }, ',', 'split' );
h4 = regexp( headerlines{ 4 }, ',', 'split' );

headers = cellfun( @( a, b ) [ a, '_', b ], ...
                   h3, h4, ...
                   'UniformOutput', false );

% columns are labeled soil_1_1, soil_1_2, etc. -- convert these to cover
% type, pit number, depth
headers = regexprep( headers, 'Soil_1', 'SWC_open_1' );
headers = regexprep( headers, 'Soil_2', 'SWC_canopyedge_1' );
headers = regexprep( headers, 'Soil_3', 'SWC_undertree_1' );

% depths
headers = regexprep( headers, '(SWC.*)_1$', '$1_50' );
headers = regexprep( headers, '(SWC.*)_2$', '$1_20' );
headers = regexprep( headers, '(SWC.*)_3$', '$1_5' );


%==================================================
function ds = hourly_2_30min( ds )
% HOURLY_2_30MIN - interpolate the data from hourly to 30-minute
%   

thirty_mins = 30 / ( 60 * 24 );  % thirty minutes in units of days
ts_30 = ds.timestamp + thirty_mins;
non_time_vars = 2:size( ds, 2 ) - 1; %all the variables that aren't timestamps
data_interp = interp1( ds.timestamp, ...
                       double( ds( :, non_time_vars ) ), ...
                       ts_30 );
varnames = ds.Properties.VarNames( non_time_vars );
data_interp = dataset( { data_interp, varnames{:} } );
data_interp.timestamp = ts_30;
data_interp.DateTime_YYMMDDhhmm = str2num( datestr( ts_30, 'yymmddHHMM' ) );

% % debugging plot -- make sure the interpolated data look like the originals
% h = figure();
% subplot( 1, 2, 1 );
% plot( ds.Soil_1_1, '.' );
% title( 'Soil_1_1 original' );
% subplot( 1, 2, 2 );
% plot( ds.Soil_1_1, '.' );
% title( 'Soil_1_1 interpolated' );

% combine the hourly data with the interpolated data and sort by timestamp
ds = vertcat( ds, data_interp );
[ ~, idx ] = sort( ds.timestamp );
ds = ds( idx, : );
