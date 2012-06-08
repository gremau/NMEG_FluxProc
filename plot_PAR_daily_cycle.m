function fh = plot_PAR_daily_cycle( sitecode )
% PLOT_PAR_DAILY_CYCLE - plots PAR vs hour of day.  This indicates whether
%   site-years are all using the same time convention (e.g. daylight savings
%   time vs. standard time)

data = {};
all_axes = [];
years = [];

sd = parse_UNM_site_table();

for this_year = 2007:2011
    fname = get_ameriflux_filename( sitecode, this_year, 'gapfilled' );
    if exist( fname )
        fprintf( 'parsing %s\n', fname );
        this_data = parse_ameriflux_file( fname );
    end
    years = horzcat( years, this_year );
    data = horzcat( data, { this_data } );
end

fh = figure( 'Units', 'Normalized' );
pos = get( fh, 'Position' );
pos( [ 2, 4 ] ) = [ 0, 1 ];
set( fh, 'Position', pos );

for i = 1:numel( years )
    H = floor( data{i}.HRMIN / 100 ) + ( mod( data{i}.HRMIN, 100 ) / 60 );

    all_axes( i ) = subplot( numel( years ), 1, i );
    plot( H, data{i}.PAR, '.k' );
    xlim( [ 0, 24 ] );
    ylim( [ -50, 500 ] );
    xlabel( 'hour' );
    ylabel( 'PAR' );
    title( sprintf( '%s %d', sd.SITE_NAME{ sitecode }, years( i ) ) );
end

linkaxes( all_axes( : ), 'x' );