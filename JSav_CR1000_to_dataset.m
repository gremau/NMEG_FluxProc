function ds = JSav_CR1000_to_dataset( year )
% JSAV_CR1000_TO_DATASET - return all CR1000 soil data from a specified year
% in a dataset array.

% searches $FLUXROOT/Flux_Tower_Data_by_Site/JSav/soil for all CR1000 soil data
% files from a specified year.  Year must be greater than or equal to 2012.
% Prior to May 2012 JSav soil data were in the same TOA5 file as all other
% 30-minute variables.
%   
% USAGE:
%     ds = JSav_CR1000_to_dataset( year );
%
% INPUTS: 
%     year: four digit year >= 2012.
%
% OUTPUTS
%     ds: dataset array; JSav soil data for the requested year
%
% SEE ALSO
%     dataset
%
% author: Timothy W. Hilton, UNM, Dec 2012

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

