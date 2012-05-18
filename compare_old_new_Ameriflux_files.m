function compare_old_new_Ameriflux_files(sitecode, year, fname_suffix)
% SCRIPT_COMPARE_OLD_NEW_AMERIFLUX_FILES - 

% sitecode = 10;
% year = 2010;

%fname_suffix = 'with_gaps';
%fname_suffix = 'gapfilled';

new_data = NaN;
old_data = NaN;

%--------------------------------------------------
% build file name
sites_info = parse_UNM_site_table();
aflx_site_name = char( sites_info.Ameriflux( sitecode ) );
fname = sprintf( '%s_%d_%s.txt', ...
                 aflx_site_name, ...
                 year, ...
                 fname_suffix );

%--------------------------------------------------
% parse the new file
fpath = fullfile( get_out_directory( sitecode ), fname );
if exist( fpath )
    new_data = parse_ameriflux_file( fpath );
else
    fprintf( '%s does not exist\n', fpath );
end

%--------------------------------------------------
% parse the old file
fpath_old = fullfile( getenv( 'FLUXROOT' ), ...
                      'Ameriflux_files', ...
                      'Old', ...
                      'From_FTP_15May12', ...
                      fname );
if exist( fpath_old )
    old_data = parse_ameriflux_file( fpath_old );
else
   fprintf( '%s does not exist\n', fpath_old );
end 

if isa( new_data, 'dataset' ) & isa( old_data, 'dataset' )

    %--------------------------------------------------
    % plot side by side
    fh = figure( 'NumberTitle', 'off', ...
                 'Name', fname, ...
                 'Units', 'Normalized', ...
                 'Position', [0.01, 0.3, 0.6, 0.6 ] );

    ax_new = subplot( 3, 1, 1 );
    h_new = plot( new_data.DTIME, new_data.FC, '.k' );
    title( 'new' );
    xlim( [ 0, 366 ] );
    ax_old = subplot( 3, 1, 2 );
    h_old = plot( old_data.DTIME, old_data.FC, '.k' );
    title( 'old' );
    xlim( [ 0, 366 ] );

    ylim = [ get( ax_old, 'ylim' ); ...
             get( ax_old, 'ylim' ) ];

    set( ax_old, 'ylim', [ min( ylim( :, 1 ) ), max( ylim( :, 2 ) ) ] );

    %--------------------------------------------------
    % % plot difference
    % old_data_unfilled = old_data;
    % mm = mod( old_data.HRMIN, 100 );
    % hh = floor( old_data.HRMIN / 100 );
    % old_data.timestamp = datenum( year, 1, 0 ) + floor( old_data.DTIME ) + ...
    %     ( mm / (24 * 60 ) ) + ( hh / 24 ) ;
    
    % new_data.timestamp = datenum( year, 1, 0 ) + new_data.DTIME;
    % old_data = dataset_fill_timestamps( old_data, ...
    %                                     'timestamp',...
    %                                     't_min', datenum( year, 1, 1 ), ...
    %                                     't_max', datenum( year, 12, 31, ...
    %                                                   23, 59, 59 ) );
    % new_data = dataset_fill_timestamps( new_data, ...
    %                                     'timestamp',...
    %                                     't_min', datenum( year, 1, 1 ), ...
    %                                     't_max', datenum( year, 12, 31, ...
    %                                                   23, 59, 59 ) );
    % ax_diff = subplot( 3, 1, 3 );
    % %h_diff = plot( new_data.DTIME, old_data.FC - new_data.FC, '.b' );
    % h_diff = plot( new_data.DTIME, ...
    %                old_data.FC - new_data.FC, '.b' );
    % title( 'old - new' );
    
    linkaxes( [ ax_old, ax_new ], 'xy' );
    
    % keyboard()
    
    waitfor( fh );
end