function amflux_ds = parse_ameriflux_file( fname )
% PARSE_AMERIFLUX_FILE - parse an ameriflux file to a matlab dataset
% 

headerlines = 3;
delim = '\t';

fid = fopen( fname, 'r' );

for i = 1:headerlines
    discard = fgetl( fid );
end

var_names = fgetl( fid );
var_names = regexp( var_names, delim, 'split' );
var_names = cellfun( @char, var_names, 'UniformOutput',  false );
var_units = fgetl( fid );
var_units = regexp( var_units, delim, 'split' );
var_units = cellfun( @char, var_units, 'UniformOutput',  false );

n_vars = numel( var_names );
fmt = repmat( '%f', 1, n_vars );
data = cell2mat( textscan( fid, fmt, 'delimiter', delim ) );
data =  replace_badvals( data, [ -9999 ], 1e-10 );

amflux_ds = dataset( { data, var_names{ : } } );
amflux_ds.Properties.Units = var_units;

