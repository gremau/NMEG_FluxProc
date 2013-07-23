function ds = JSav_CR1000_to_dataset( year )
% JSAV_CR1000_TO_DATASET - 
%   

if year < 2012
    error( ['Prior to May 2012 JSav soil water data were in the same TOA5 ' ...
            'file as all other 30-minute variables' ] );
end

fnames = get_data_file_names( datenum( year, 1, 1), ...
                              datenum( year, 12, 31 ), ...
                              UNM_sites.JSav, ...
                              'soil' );

ds = combine_and_fill_TOA5_files( fnames );

[ ~, discard_vars ] = regexp_ds_vars( ds, 'PA.*' );
ds( :, discard_vars ) = [];

var_names = format_probe_strings( ds.Properties.VarNames );
var_names = regexprep( var_names, 'swc', 'cs616SWC' );
var_names = regexprep( var_names, '_avg$', '' );
ds.Properties.VarNames = var_names;

