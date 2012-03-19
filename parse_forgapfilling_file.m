function ds = parse_forgapfilling_file( site_code, year )
% PARSE_FORGAPFILLING_FILE - parse an ASCII for_gapfilling file to a matlab dataset
%   
% USAGE
%    ds = parse_forgapfilling_file( site_code, year )
%
% INPUTS
%     site_code [ integer ]: code of site to be filled
%     year [ integer ]: year to be filled
%
% OUTPUTS
%     ds [ matlab dataset ]: the data contained in the file
%
% (c) Timothy W. Hilton, UNM, March 2012

fname = fullfile( get_site_directory( site_code ), ...
                  'processed flux', ...
                   sprintf( '%s_flux_all_%d_for_gap_filling.txt', ...
                            get_site_name( site_code ), year ) );

ds = dataset( 'File', fname );
ds_names = ds.Properties.VarNames;
ds_dbl = double( ds );
ds_dbl = replace_badvals( ds_dbl, [ -9999.0 ], 1e-6 );
clear ds;

ds = dataset( { ds_dbl, ds_names{:} } );