sitecode = 10;
year = 2009;
fname_suffix = 'with_gaps';
fname_suffix = 'gapfilled';

%--------------------------------------------------
% build file name
fname = sprintf( '%s_%d_%s.txt', ...
                 aflx_site_name, ...
                 year, ...
                 fname_suffix );
sites_info = parse_UNM_site_table();
aflx_site_name = char( sites_info.Ameriflux( sitecode ) );

%--------------------------------------------------
% parse the new file
fpath = fullfile( get_out_directory( sitecode ), fname );
new_data = parse_ameriflux_file( fpath );

%--------------------------------------------------
% parse the old file
fpath_old = fullfile( getenv( 'FLUXROOT' ), ...
                      'Ameriflux_files', ...
                      'Old', ...
                      'From_FTP_15May12', ...
                      fname );
old_data = parse_ameriflux_file( fpath_old );

%--------------------------------------------------
% plot side by side
fh = figure( 'NumberTitle', 'off', ...
             'Name', fname );
ax_new = subplot( 2, 1, 1 );
h_new = plot( new_data.DTIME, new_data.FC, '.k' );
title( 'new' );
xlim( [ 0, 366 ] );
ax_old = subplot( 2, 1, 2 );
h_old = plot( old_data.DTIME, old_data.FC, '.k' );
title( 'old' );
xlim( [ 0, 366 ] );

ylim = [ get( ax_old, 'ylim' ); ...
         get( ax_old, 'ylim' ) ];

set( ax_old, 'ylim', [ min( ylim( :, 1 ) ), max( ylim( :, 2 ) ) ] );

linkaxes( [ ax_old, ax_new ], 'xy' );



                