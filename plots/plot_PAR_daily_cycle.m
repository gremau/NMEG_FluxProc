function fh = plot_PAR_daily_cycle( sitecode )
% PLOT_PAR_DAILY_CYCLE - plots PAR vs hour of day within each year from 2007 to
% 2013 for a single UNM site.  
%
% Each site-year is plotted in its own panel.  This helps indicate whether
% site-years are all using the same time convention (e.g. daylight savings time
% vs. standard time).
%
% USAGE
%     fh = plot_PAR_daily_cycle( sitecode );
%
% INPUTS
%     sitecode: UNM_sites object; specifies the site
%
% OUTPUTS
%     fh: handle to the figure containing the plot.
%
% SEE ALSO
%     UNM_sites
%
% author: Timothy W. Hilton, UNM, June 2012

data = {};
all_axes = [];
years = [];

sd = parse_UNM_site_table();

%RJL extended to 2013 per conversation with Marcy, 12/03/2013.
for this_year = 2007:2013
    fname = get_ameriflux_filename( sitecode, this_year, 'gapfilled' );
    if exist( fname )
        fprintf( 'parsing %s\n', fname );
        this_data = parse_ameriflux_file( fname );
    else
        this_data = NaN;
    end
    years = horzcat( years, this_year );
    data = horzcat( data, { this_data } );
end

fh = figure( 'Units', 'Normalized' );
pos = get( fh, 'Position' );
pos( [ 2, 4 ] ) = [ 0, 1 ];
set( fh, 'Position', pos );

for i = 1:numel( years )
    H = mod(data{i}.DTIME, floor(data{i}.DTIME))*24
    all_axes( i ) = subplot( numel( years ), 1, i );
    plot( H, data{i}.PAR, '.k' );
    xlim( [ 0, 24 ] );
    ylim( [ -50, 500 ] );
    xlabel( 'hour' );
    ylabel( 'PAR' );
    title( sprintf( '%s %d', sd.SITE_NAME{ sitecode }, years( i ) ) );
end

linkaxes( all_axes( : ), 'x' );