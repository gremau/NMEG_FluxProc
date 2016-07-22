function Tmain = get_MCon_SAHRA_data( year )
% GET_MCON_SAHRA_DATA - parse data collected at MCon by SAHRA station.
%
% There was a SAHRA station at the MCon site that collected data between
% 2006 and 2013. These data include from met, sapflow, and (1) soil
% profile sensors. These data are parsed from
% $FLUXROOT/SiteData/MCon/secondary_loggers/SAHRA_logger/MCon_SAHRA_soil_all.dat.
% If this is not found, a new file must be created from the raw data,
% which can be downloaded from the DRI/WRCC website at:
% 
% <http://www.wrcc.dri.edu/cgi-bin/rawMAIN.pl?nmvcnx>
%
% See further notes about this in the comments and the README.md file in
% the MCon\secondary_loggers\SAHRA_logger directory.
%
% INPUTS:
%     year: four-digit year; specifies the year for data extraction
%
% OUTPUTS
%     Tmain: MATLAB table; VWC, Tsoil, sapflow, etc., for specified year
%
% SEE ALSO
%     table
%
% author: Gregory E. Maurer, UNM, March 2015
% adapted from code by Timothy W. Hilton (preprocess_MCon_soil_data.m and
% concatenate_all_MCon_soil_data.m);

% Raw data from the SAHRA site can be downloaded from:
% <http://www.wrcc.dri.edu/cgi-bin/rawMAIN.pl?nmvcnx>
% This file contains all data from the SAHRA site at MCon:
filePath = fullfile( get_site_directory( UNM_sites.MCon ), ...
    'secondary_loggers', 'SAHRA_logger' );
fname1 = fullfile( filePath, 'MCon_SAHRA_data_20061001_20130601.dat' );
fprintf( 'reading %s \n', fname1 );

if exist( fname1, 'file' )
    Tmain = parse_MCon_SAHRA_DAT_file( fname1 );
else
    error( 'MCon SAHRA file not found! Find/download before proceeding');
end

% Steven's HydraProbe data from the SAHRA site need to be run through
% Stevens proprietary software to convert voltages to SWC/Tsoil values.
% Converted data are stored in this file:
fname2 = fullfile( filePath, 'MCon_SAHRA_hydraprobes.dat' );
if exist( fname2, 'file' )
    Thydra = parse_MCon_SAHRA_hydraprobe_file( fname2 );
% If that file doesn't already exist, it must be created from the raw
% datafile ( now Tmain ), and then run, independently of MATLAB, through
% the Hyd_file.exe program.
else
    fprintf([ 'ABORTING - Converted HydraProbe file not found!\n'...
        'Creating input file for hydra_file.exe\n' ]);
    export_hydraprobe_voltage_file( Tmain, filePath );
    return
end

% HydraProbe data include 3 sensors vertically concatenated
[ nRows, nCols ] = size( Tmain );
sensor1Idx = 1:nRows;
sensor2Idx = ( nRows + 1 ):( nRows + nRows );
sensor3Idx = ( max( sensor2Idx ) + 1 ):( max( sensor2Idx ) + nRows ) ;
% Join Tmain and Thydra variables (timestamps should be the same)
% I don't know what the depths are, so variable names are place holders
Tmain.SWC_SAHRA_P1_D1 = Thydra{ sensor1Idx', 'VWC' };
Tmain.SWC_SAHRA_P1_D2 = Thydra{ sensor2Idx', 'VWC' };
Tmain.SWC_SAHRA_P1_D3 = Thydra{ sensor3Idx', 'VWC' };
Tmain.SOILT_SAHRA_P1_D1 = Thydra{ sensor1Idx', 'TSoil_C' };
Tmain.SOILT_SAHRA_P1_D2 = Thydra{ sensor2Idx', 'TSoil_C' };
Tmain.SOILT_SAHRA_P1_D3 = Thydra{ sensor3Idx', 'TSoil_C' };

% Linearly interpolate the 30 minute values
Tmain = hourly_2_30min( Tmain );

% return data for requested year
[ datayear, ~, ~, ~, ~, ~ ] = datevec( Tmain.timestamp );
Tmain = Tmain( datayear == year, : );

% make sure it is a complete series of 30-minute timestamps
Tmain = table_fill_timestamps( Tmain, ...
                               'timestamp', ...
                               't_min', min( Tmain.timestamp ), ...
                               't_max', max( Tmain.timestamp ) );
                           

%==================================================_
function T = parse_MCon_SAHRA_DAT_file( fname )
% PARSE_MCON_SOIL_DAT_FILE - parse a single MCon SAHRA .dat file

n_headerlines = 3; % First 3 lines are headers
dlm = ',';  % files are comma-delimited

% Parse the header lines
headerlines = cell( n_headerlines, 1 );
fid = fopen( fname, 'r' );
for i = 1:n_headerlines
    headerlines{ i } = fgetl( fid );
end
fclose( fid );

% Pull out and format the three header lines into 1
headers = process_headers( headerlines );
% parse the data into a dataset object
data = dlmread( fname, dlm, n_headerlines + 1, 0 );
T = readtable( fname, 'Delimiter', dlm, 'HeaderLines', n_headerlines, ...
    'ReadVariableNames', false );
T.Properties.VariableNames = headers;

% Parse and assign a matlab timestamp
T.timestamp = datenum( num2str( T.DateTime_YYMMDDhhmm, '%0.10d' ), ...
                        'yymmddHHMM' );

%==================================================_
function T = parse_MCon_SAHRA_hydraprobe_file( fname )
% PARSE_MCON_SAHRA_HYDRAPROBE_FILE - parse the output of the hyd_file.exe
% program, which contains VWC and Tsoil values from the hydraprobes.

n_skiplines = 16; % Header is a pain to parse, skip it
dlm = ' ';  % files are space-delimited

% File header is:
headers = { 'ID', 'SOIL', 'DielectricConst_Real', 'DielectricConst_i', ...
    'TSoil_C', 'DielectricConstTCor_Real', 'DielectricConstTCor_i', ...
    'VWC', 'LossTangent', 'Conductivity', 'ConductivityTCor' }; 

% Read data to correct format, removing invalid values created by
% 'hyd_file.exe'
formatstr = [ '%u%u' repmat( '%f', 1, 9 ) ];

T = readtable( fname, 'Format', formatstr, 'Delimiter', dlm, ...
    'HeaderLines', n_skiplines, ...
    'ReadVariableNames', false, ...
    'TreatAsEmpty', { '-1.#J', '-1.#IND' }, ...
    'MultipleDelimsAsOne', true);

T.Properties.VariableNames = headers;

%==================================================
function headers = process_headers( headerlines )
% PROCESS_HEADERS - process the headers from their formats in the file to
%   descriptive matlab-legal variable names

headerlines = regexprep( headerlines, ':', '' );
headerlines = regexprep( headerlines, '[ \t/\.]', '' );
headerlines = regexprep( headerlines, '-', '_' );
% Take the 2nd and 3rd header lines, split by delimiter, and fuse the 2
% lines together into 1
h2 = regexp( headerlines{ 2 }, ',', 'split' );
h3 = regexp( headerlines{ 3 }, ',', 'split' );
headers = cellfun( @( a, b ) [ a, '_', b ], ...
                   h2, h3, ...
                   'UniformOutput', false );

%==================================================
function T = hourly_2_30min( T )
% HOURLY_2_30MIN - interpolate the data from hourly to 30-minute
%   

thirty_mins = 30 / ( 60 * 24 );  % thirty minutes in units of days
ts_30 = T.timestamp + thirty_mins;
non_time_vars = 2:size( T, 2 );% - 1; %all the variables that aren't timestamps
data_interp = interp1( T.timestamp, ...
                       T{ :, non_time_vars }, ...
                       ts_30 );
varnames = T.Properties.VariableNames( non_time_vars );
data_interp = array2table( data_interp, 'VariableNames', varnames );
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
T = vertcat( T, data_interp );
[ ~, idx ] = sort( T.timestamp );
T = T( idx, : );

%==================================================
function export_hydraprobe_voltage_file( T, path )
% Export a file of raw HydraProbe voltages for conversion by Steven's
% proprietary software. This file can be read by 'hyd_file.exe', a copy of
% which should be found in the output directory or at the Steven's
% Hydraprobe website.
[ nRows, nCols ] = size( T );
% IDs must be integers? -  repeat same ids for each sensor
ID = repmat( ( 1:nRows )', 3, 1 );
SOIL = repmat( 4, nRows * 3 , 1 );
V1 = [ T.Soil_1_1 ; T.Soil_2_1 ; T.Soil_3_1 ] / 1000;
V2 = [ T.Soil_1_2 ; T.Soil_2_2 ; T.Soil_3_2 ] / 1000;
V3 = [ T.Soil_1_3 ; T.Soil_2_3 ; T.Soil_3_3 ] / 1000;
V4 = [ T.Soil_1_4 ; T.Soil_2_4 ; T.Soil_3_4 ] / 1000;
T_export = table( ID, SOIL, V1, V2, V3, V4 );

% Export the raw voltage file for reading in to Hyd_file.exe
fname = fullfile( path, 'MCon_SAHRA_hydraprobe_voltages.dat' );
writetable( T_export, fname, 'Delimiter', ' ' );





