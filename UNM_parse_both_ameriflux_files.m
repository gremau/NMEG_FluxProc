function [ds_gaps, ds_GF ] = UNM_parse_both_ameriflux_files( sitecode, year )
% UNM_PARSE_BOTH_AMERIFLUX_FILES - parses gapfilled and with_gaps ameriflux
%   files to two datasets
%
% USAGE:
%   [ds_gaps, ds_GF ] = UNM_parse_both_ameriflux_files( sitecode, year )
%
% author: Timothy W. Hilton, UNM, June 2012

% read site names
sites_ds = parse_UNM_site_table();

% parse the Ameriflux Files
fname_gaps = fullfile( get_out_directory( sitecode ), ...
                       sprintf( '%s_%d_with_gaps.txt', ...
                                sites_ds.Ameriflux{ sitecode }, year ) );
fname_filled = fullfile( get_out_directory( sitecode ), ...
                         sprintf( '%s_%d_gapfilled.txt', ...
                                  sites_ds.Ameriflux{ sitecode }, year ) );

fprintf( 'parsing %s and %s\n', fname_gaps, fname_filled );

ds_gaps = parse_ameriflux_file( fname_gaps );
ds_GF = parse_ameriflux_file( fname_filled );