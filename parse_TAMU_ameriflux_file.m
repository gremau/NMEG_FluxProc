function amflux_ds = parse_TAMU_ameriflux_file( fname )
% PARSE_AMERIFLUX_FILE - parse one of Jim Heilman and Ray Kamp's (from Texas A&M
% University) Ameriflux files to a Matlab dataset.
% 
% USAGE:
%   amflux_ds = parse_TAMY_ameriflux_file( fname )
%
% (c) Timothy W. Hilton, UNM, Apr 2013

headerlines = 20;
delim = detect_delimiter( fname );

fid = fopen( fname, 'r' );

for i = 1:headerlines
    discard = fgetl( fid );
end

var_names = fgetl( fid );
var_names = regexp( var_names, delim, 'split' );
var_names = cellfun( @char, var_names, 'UniformOutput',  false );
var_names = cellfun( @genvarname, var_names, 'UniformOutput',  false );
var_units = fgetl( fid );
var_units = regexp( var_units, delim, 'split' );
var_units = cellfun( @char, var_units, 'UniformOutput',  false );

n_vars = numel( var_names );
fmt = strcat( '%f%*s', repmat( '%f', 1, n_vars - 2 ) );
data = cell2mat( textscan( fid, fmt, 'delimiter', delim ) );
data =  replace_badvals( data, [ -9999 ], 1e-10 );

fclose( fid );

% some of the TAMU files (2011, at the very least) have tens of thousands of
% empty lines (,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,) at the end.  Get rid of those.
last_data_line = min( find( all( isnan( data ), 2 ) ) ) - 1;
data = data( 1:last_data_line, : );

% as per Marcy's email of 25 Apr 2013: 
% This site is super close to our site.  Can you grab the variables we need from
% there please.  I would take PAR, Rg, ppt, pressure, AirT, RH at least.
% Incoming longwave is probably fine.  Would not get outgoing.

% the char string date column in the TAMU format is not useful; keep all
% other columns and create dataset; then keep the columns we want by name.
ds_names=  var_names( [ 1, 3:end ] );
ds_units=  var_units( [ 1, 3:end ] );
amflux_ds = dataset( { data, ds_names{ : } } );
amflux_ds.Properties.Units = ds_units;

amflux_ds = amflux_ds( :, { 'YEAR', 'DTIME', 'PAR', ...
                    'Rg0x2DKnZ', 'PREC', ...
                    'PRESS', 'TA', 'RH', 'VPD', 'Rgl' } ); 

amflux_ds.Properties.VarNames = { 'YEAR', 'DTIME', 'PAR', ...
                    'Rg', 'PRECIP', ...
                    'PA', 'TA', 'RH', 'VPD', 'Rlong_in' };

% several of these variables use different missing values.  Replace them
% individually with NaN
epsilon = 1e-6;
amflux_ds.Rlong_in( abs( amflux_ds.Rlong_in - 9999 ) < epsilon ) = NaN;
amflux_ds.VPD( abs( amflux_ds.VPD - -9.999 ) < epsilon ) = NaN;
amflux_ds.Rg( abs( amflux_ds.Rg - 9999 ) < epsilon ) = NaN;

% make sure the data have a complete set of timestamps 1 Jan 00:00 to 31 Dec
% 23:30
amflux_ds.timestamp = datenum( amflux_ds.YEAR, 1, 0 ) + amflux_ds.DTIME;
amflux_ds = ...
    dataset_fill_timestamps( amflux_ds, ...
                             'timestamp', ...
                             't_min',  datenum( amflux_ds.YEAR( 1 ), 1, 1 ), ...
                             't_max', datenum( amflux_ds.YEAR( 1 ), 12, 31, ...
                                               23, 30, 0 ) );

% make sure newly-created rows have YEAR and DSTIME filled in
[ y, ~, ~, ~, ~, ~ ] = datevec( amflux_ds.timestamp );
idx = isnan( amflux_ds.YEAR );
amflux_ds.YEAR( idx )  = y( idx );
amflux_ds.DTIME( idx ) = amflux_ds.timestamp( idx ) - ...
    datenum( amflux_ds.YEAR( idx ), 1, 0 );
amflux_ds.timestamp = [];