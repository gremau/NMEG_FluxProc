function metTable = UNM_parse_valles_met_data( station_name, year_arg )
% Parse ancillary Valles Caldera met data files to matlab table
%
% See the README.md file in the $FLUXROOT/Ancillary_met_data/ directory for
% details on the files and their origin and formatting.
%
% The script issues an error if these files are not found.
%
% USAGE
%     metData = UNM_parse_valles_met_data( sitecode, year_arg );
%
% INPUTS
%     station_name: string; met station to retrieve data from (Redondo,
%         Headquarters, or Jemez)
%     year_arg: numeric; the year to parse
%
% OUTPUTS:
%     metTable: table array; the met data
%
% SEE ALSO
%     table
%
% author: Gregory E. Maurer, UNM, December 2014
% adapted from code by: Timothy W. Hilton, UNM, March 2012

% Choose network and get data
fname = fullfile( getenv( 'FLUXROOT' ), 'Ancillary_met_data', ...
    sprintf( 'VC_%s_dri_06-current.dat', station_name ) );

% Set delimiter and open file
delim = ',';
fid = fopen( fname, 'r' );
% Read header and units
var_units = fgetl( fid );
var_units = regexp( var_units, delim, 'split' );
var_units = cellfun( @char, var_units, 'UniformOutput',  false );
var_names = fgetl( fid );
var_names = regexp( var_names, delim, 'split' );
var_names = cellfun( @char, var_names, 'UniformOutput',  false );
% Read data to array and replace bad data values
n_vars = numel( var_names );
fmt = repmat( '%f', 1, n_vars );
data = cell2mat( textscan( fid, fmt, 'delimiter', delim ) );
data =  replace_badvals( data, [ -9999 ], 1e-10 );
% Close file
fclose( fid );
% Create table
metTable = array2table( data, 'VariableNames', var_names );
metTable.Properties.VariableUnits =  var_units;

% Trim to year and add a timestamp
dstring = num2str( metTable.YYMMDDhhmm, '%010u' );
tvec = datevec( dstring, 'YYmmDDHHMM' );
metTable = metTable( tvec( :, 1 ) == year_arg, : );
dstring = dstring( tvec( :, 1 ) == year_arg, : );
metTable.timestamp = datenum( dstring, 'YYmmDDHHMM' );

% Convert cumulative precip to hourly increments in mm
p_diff = [ 0; diff( metTable.Precip )];
% Remove negative increments
p_diff( p_diff < 0 ) = 0;
metTable.Precip_inc = p_diff;



