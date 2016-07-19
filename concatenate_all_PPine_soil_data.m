function tbl = concatenate_all_PPine_soil_data()
% CONCATENATE_ALL_PPINE_SOIL_DATA - parses soil data for PPine from several
%   different sources and combines into one tab-delimited file.
%
% The files read and combined are:
%    PP_Site_2008_2009_soil112.csv
%    PP_Site_2009_2010_soil111.csv
%    all .DAT files in the directory from which this code is run.  These are
%        generally named in the format VLMMDDYY, with MM the month, DD the day, and
%        YY the year.
%
% These files are all the PPine soil data that Marcy was able to round up as of
% 14 Aug 2012.
%
% USAGE: 
%    ds = concatenate_all_PPine_soil_data()
%
% OUTPUT
%    ds: matlab dataset object containing the combined soil data,
%        interpolated to 30-minute timesteps (from one hour), with missing
%        timestamps filled in with NaN.
%
% Timothy W. Hilton

dataPath = fullfile( get_site_directory( UNM_sites.PPine ), ...
    'secondary_loggers', 'DRI_logger', 'PPine_DRI_raw_soil_data' );
outPath = fullfile( get_site_directory( UNM_sites.PPine ), ...
    'secondary_loggers', 'DRI_logger' );

[ t111, t112 ] = parse_PPine_soil_all_DAT_files( dataPath );
t111_0910 =  parse_PPine_soil_csv( ...
    fullfile( dataPath, 'PP_Site_2009_2010_soil111.csv' ));
t112_0809 =  parse_PPine_soil_csv( ...
    fullfile( dataPath, 'PP_Site_2008_2009_soil112.csv' ));

tbl = combine_data( t111, t112, t111_0910, t112_0809 );

t_start = datestr( min( tbl.timestamp ), 'yyyymmdd' );
t_end = datestr( max( tbl.timestamp ), 'yyyymmdd' );
outfile = fullfile( outPath, sprintf( 'PPine_soil_data_%s_%s.dat', ...
                   t_start, t_end ));
fprintf( 'writing %s\n', outfile );
write_table_std( outfile, tbl, 'precision', 15 );
%======================================================================
function t = combine_data( t111, t112, t111_0910, t112_0809 )

data_vars = not( ismember( t111.Properties.VariableNames, ...
                           { 'Array_ID', 'Year', 'Day', ...
                    'Time', 'timestamp' } ) );
t = horzcat( t112, t111( :, data_vars ) );

t_0810 = outerjoin( t111_0910, t112_0809, 'MergeKeys', true );
discard_idx = t_0810.timestamp > min( t.timestamp );
t_0810( discard_idx, : ) = [];

% New
t_0810 = t_0810( find_unique( t_0810.timestamp ), : );

t = vertcat( t_0810, t );


%======================================================================
function [ t111, t112 ] = parse_PPine_soil_all_DAT_files( path )
% PARSE_PPINE_SOIL_ALL_DAT_FILES - parses all PPine soil data .DAT files from
% the working directory.  Each .DAT file contains data from at least three separate
%   "arrays" of observations.  The arrays have the IDs 110, 111, and 112.  We
%   are currently ignoring array 110, so this function returns two matlab
%   dataset objects: one for array 110, one for array 112.

file_info = dir([ path '\*.DAT' ]);

% initialize cell arrays to contain parsed datasets
t111 = cell( 1, numel( file_info ) );
t112 = cell( 1, numel( file_info ) );

headers111 = PPine_array_headers( 111 );
headers112 = PPine_array_headers( 112 );

for i = 1:numel( file_info )
    fprintf( 'parsing %s\n', file_info( i ).name );
    [ data111, data112 ] = parse_PPine_soil_DAT_file( ...
        fullfile( path, file_info( i ).name ));

    t111{ i } = array2table( data111, 'VariableNames', headers111 );
    t112{ i } = array2table( data112, 'VariableNames', headers112 );
    
    t111{ i }.timestamp = mcconnel_times_2_datenum( t111{ i } );
    t112{ i }.timestamp = mcconnel_times_2_datenum( t112{ i } );
    
end

t111 = vertcat( t111{ : } );
t112 = vertcat( t112{ : } );

% discard duplicate timestamps
t111 = t111( find_unique( t111.timestamp ), : );
t112 = t112( find_unique( t112.timestamp ), : );

% fill in any missing hourly timestamps
t_min = min( [ t111.timestamp; t112.timestamp ] );
t_max = max( [ t111.timestamp; t112.timestamp ] );
one_hour = 1 / 24; % one hour in units of days
t111 = table_fill_timestamps( t111, 'timestamp', ...
                                 'delta_t', one_hour, ...
                                 't_min', t_min, ...
                                 't_max', t_max );
t112 = table_fill_timestamps( t112, 'timestamp', ...
                                 'delta_t', one_hour, ...
                                 't_min', t_min, ...
                                 't_max', t_max );

% interpolate from hourly to 30 minutes
t111 = hourly_2_30min( t111 );
t112 = hourly_2_30min( t112 );

% t_start = min( [ t111.timestamp; t112.timestamp ] );
% t_end = max( [ t111.timestamp; t112.timestamp ] );
% two_mins = 2 / ( 24 * 60 );  % two minutes in units of days
% [ t111, t112 ] = merge_datasets_by_datenum( t111, t112, ...
%                                               'timestamp', 'timestamp', ...
%                                               two_mins, ...
%                                               t_start, t_end );


%======================================================================
function dn = mcconnel_times_2_datenum( t )
% the timestamps in Joe McConnel's PPine soil data are give as year, day of
% year, and time in HHMM format.  Convert these to matlab datenums

mins_per_day = 24 * 60;
hours_per_day = 24;

hh = floor( t.Time / 100 );
mm = mod( t.Time, 100 );

dn = datenum( t.Year, 1, 0 ) + ...
     t.Day + ...
     ( hh / hours_per_day ) + ...
     ( mm / mins_per_day );
     

%======================================================================
function [ data111, data112 ] = parse_PPine_soil_DAT_file( fname )
% PARSE_PPINE_SOIL_DAT_FILE - parse a single PPine soil met .DAT file into a
%   matlab dataset object.  Each file contains data from at least three separate
%   "arrays" of observations.  The arrays have the IDs 110, 111, and 112.
%
% INPUTS
%     fname: full path to the file to be parsed
%
% OUTPUTS
%     data111: Nx35 array containing data from array 111
%     data112: Nx58 array containing data from array 112

% some of the data files contain garbled lines.  Therefore parse the file
% into a string, filter the string with a regular expression, and parse the
% filtered strings into a numeric array.
data_str = fileread( fname );
% split data_str into lines
data_str = regexp( data_str, '\n', 'split' );
% remove quotations -- some files have each line contained in quotations
data_str = regexprep( data_str, '"', '' );

% valid floating point characters are 0-9, ., -, e, and E.  Keep only lines
% containing these characters.
bad_idx = cellfun( @isempty, ...
                   regexp( data_str, '[0-9\.-eE]', 'match' ) );
data_str = data_str( not( bad_idx ) );

% scan the strings to numeric arrays
data = cellfun( @(x) textscan( x, '%f', 'delimiter', ',' ), data_str );

% pull out the arrayID (first element of each line) -- this determines how
% many observations should be in the line
arrayID = cellfun( @(x) x(1), data );

% array 111 should have 34 observations per line and array 112 should have
% 58.  There are two or three lines labeled 112 that have a different
% number.  Therefore filter each array to only accept lines with the correct
% number of observations.
data111 = data( arrayID == 111 );
data112 = data( arrayID == 112 );
n_obs111 = cellfun( @numel, data111 );
n_obs112 = cellfun( @numel, data112 );
data111( n_obs111 ~= 34 ) = [];
data112( n_obs112 ~= 58 ) = [];
data111 = horzcat( data111{ : } )';
data112 = horzcat( data112{ : } )';


%======================================================================
function t =  parse_PPine_soil_csv( fname )

dlm = ',';  %files are comma-delimited
start_row = 1; % skip first row (header)
start_col = 0; % do not skip any columns

data = dlmread( fname, ',', start_row, start_col );
arrayID = unique( data( 1 ) );
headers = PPine_array_headers( arrayID );

% New
data = replace_badvals( data, [ -6999 ], 1e-6 );

t = array2table( data, 'VariableNames', headers );

t.timestamp = mcconnel_times_2_datenum( t );

% remove duplicate timestamps
t = t( find_unique( t.timestamp ), : );

one_hour = 1 / 24; % one hour in units of days
t = table_fill_timestamps( t, 'timestamp', ...
                              'delta_t', one_hour, ...
                              't_min', min( t.timestamp ), ...
                              't_max', max( t.timestamp ) );

t = hourly_2_30min( t );

%======================================================================
function t = parse_Sarah_PPine_soil_xls( fname)
% PARSE_SARAH_PPINE_SOIL_XLS - parse a single PPine soil met .xls file compiled
%   by Sarah into a matlab dataset object.
% INPUTS
%     fname: full path to the file to be parsed
%
% OUTPUTS
%     ds: matlab dataset object containing the data with column labels and
%         units.

sheet_name = 'VWCandWP';
T_range = 'C8:F17527';
VWC_range = 'J8:J17527';
time_range = 'A8:A17527';

fprintf( 'parsing %s...', fname );
Tdata = xlsread( fname, sheet_name, T_range );
VWCdata = xlsread( fname, sheet_name, VWC_range );
[ ~, timestamps ] = xlsread( fname, sheet_name, time_range );
fprintf( 'done\n' );

timestamps = datenum( timestamps );

data = [ timestamps, Tdata, VWCdata ];

% replace -9999 with NaN
data = replace_badvals( data, [ -9999 ], 1e-6 );

% name the temperature variables with convention soilT_cover_pit_depth
var_names = { 'timestamp', ...
              'soilT_ponderosa_1_2', 'soilT_ponderosa_1_6', ...
              'soilT_ponderosa_2_2', 'soilT_ponderosa_2_6', ...
              'VWC_ponderosa_1_6' };
var_units = { 'time', 'C', 'C', 'C', 'C', '%' };

t = array2table( data, 'VariableNames', var_names );
t.Properties.VariableUnits = var_units;

%======================================================================
function headers = PPine_array_headers( arrayID )
% PPINE_ARRAY_111_HEADERS - defines the headers for soil data array 111 and 112
%   at PPine.  The headers were taken from the files PP_Site_2009_soil111.csv
%   and PP_Site_2009_soil112.csv on 10 Aug 2012.

logistical_vars = { 'Array_ID', 'Year', 'Day', 'Time' };

switch arrayID
  case 111
    pit_vars = { 'SoilT_C', 'SoilT_F', 'VWC', ...
                 'Soil_Conductivity', 'Dielectric_Loss_Tangent' };
  case 112
    pit_vars = { 'VWC', 'Soil_Conductivity_Tcorrected', ...
                 'SoilT_C', 'SoilT_F', ...
                 'Soil_Conductivity_raw', ...
                 'Real_Dielectric_Permittivity_raw', ...
                 'Imaginary_Dielectric_Permittivity_raw', ...
                 'Real_Dielectric_Permittivity_Tcorrected', ...
                 'Imaginary_Dielectric_Permittivity_Tcorrected'};
  otherwise
    error( 'array ID must be either 111 or 112' );
end

% anonymous function to append _N to each string in pit_vars, with
% integer argument N
append_pit = @( n ) cellfun( @(str) strcat( str, sprintf( '_obs%d', n ) ), ...
                             pit_vars, ...
                             'UniformOutput', false );

headers = [ logistical_vars, ...
            append_pit( 1 ), append_pit( 2 ), ...
            append_pit( 3 ), append_pit( 4 ), ...
            append_pit( 5 ), append_pit( 6 ) ];

% replace "pitN" with the actual depth (format: Covertype_PitNumber_Depth)
headers = regexprep( headers, 'obs1', ...
                     sprintf( 'ponderosa_%d1_5', arrayID ) );
headers = regexprep( headers, 'obs2', ...
                     sprintf( 'ponderosa_%d1_20', arrayID ) );
headers = regexprep( headers, 'obs3', ...
                     sprintf( 'ponderosa_%d1_50', arrayID ) );
headers = regexprep( headers, 'obs4', ...
                     sprintf( 'ponderosa_%d2_5', arrayID ) );
headers = regexprep( headers, 'obs5', ...
                     sprintf( 'ponderosa_%d2_20', arrayID ) );
headers = regexprep( headers, 'obs6', ...
                     sprintf( 'ponderosa_%d2_50', arrayID ) );

%==================================================
function t = hourly_2_30min( t )
% HOURLY_2_30MIN - interpolate the data from hourly to 30-minute
%   

thirty_mins = 30 / ( 60 * 24 );  % thirty minutes in units of days
ts_30 = t.timestamp + thirty_mins;
non_time_vars = setdiff( t.Properties.VariableNames, ...
                         { 'timestamp', 'Array_ID', ...
                    'Year', 'Day', 'Time' } );
data_interp = interp1( t.timestamp, ...
                       table2array( t( :, non_time_vars ) ), ...
                       ts_30 );
data_interp = array2table( data_interp, 'VariableNames', non_time_vars );
data_interp.timestamp = ts_30;
[ yyyy, ~, ~, ~, ~, ~ ] = datevec( ts_30 );
data_interp.Year = yyyy;
data_interp.Day = floor( ts_30 - datenum( yyyy, 1, 0 ) );
data_interp.Time = str2num( datestr( ts_30, 'HHMM' ) );
data_interp.Array_ID = t.Array_ID;

% % debugging plot -- make sure the interpolated data look like the originals
% h = figure();
% subplot( 1, 2, 1 );
% plot( ds.Soil_1_1, '.' );
% title( 'Soil_1_1 original' );
% subplot( 1, 2, 2 );
% plot( ds.Soil_1_1, '.' );
% title( 'Soil_1_1 interpolated' );

% combine the hourly data with the interpolated data and sort by timestamp
t = vertcat( t, data_interp );
[ ~, idx ] = sort( t.timestamp );
t = t( idx, : );
