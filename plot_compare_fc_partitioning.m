function fighandle = plot_compare_fc_partitioning( site, yr, ...
                                                   data_in, varargin )
% PLOT_COMPARE_FC_PARTITIONING - makes diagnostic figures showing the
% output of several different NEE partitioning methods.
%
% Called from Ameriflux File Maker
% FIXME - documentation
%
% INPUTS
%    site: UNM_sites object; specifies the site to show
%    yr: four-digit year: specifies the year to show
%    data_in: MATLAB table: array including partitioned flux columns
%    keenan: boolean; flag to toggle plotting of keenan partitioned data
%
% OUTPUTS
%    figure handles
%
% SEE ALSO
%    UNM_sites, table, UNM_Ameriflux_File_Maker
%
% author: Gregory E. Maurer, UNM, April 2015

[ this_year, ~, ~ ] = datevec( now );

% -----
% define inputs, with defaults and type checking
% -----
args = inputParser;
args.addRequired( 'site', @(x) ( isintval( x ) | isa( x, 'UNM_sites' ) ) );
args.addRequired( 'yr', ...
    @(x) ( isintval( x ) & ( x >= 2006 ) & ( x <= this_year ) ) );
args.addRequired( 'data_in', @istable );
args.addParameter( 'keenan', false, @logical );

% parse optional inputs
args.parse( site, yr, data_in, varargin{ : } );

site = args.Results.site;
yr = args.Results.yr;
pt_tbl = args.Results.data_in; % Contains partitioned NEE values
keenan = args.Results.keenan;

% Set up figure window
fighandle = figure( 'Name',...
    sprintf('NEE partitioning comparison, %s %d', site, yr),...
    'Units', 'centimeters', 'Position', [2, 2, 34, 22] );

% Four subplots
ax( 1 ) = subplot( 2, 3, 1:2 );
h = compare_timeseries( 'RE', ax( 1 ), pt_tbl, keenan );
if keenan
    legend( 'filled NEE', 'Reichstein', 'Lasslop', 'Keenan x 100', ...
        'Location','northwest' )
else
    legend( 'filled NEE', 'Reichstein', 'Lasslop', ...
        'Location','northwest' )
end

ax( 2 ) = subplot( 2, 3, 3 );
h = compare_cumulative_series( 'RE', ax( 2 ), pt_tbl, keenan );

ax( 3 ) = subplot( 2, 3, 4:5 );
h = compare_timeseries( 'GPP', ax( 3 ), pt_tbl, keenan );

ax( 4 ) = subplot( 2, 3, 6 );
h = compare_cumulative_series( 'GPP', ax( 4 ), pt_tbl, keenan );

title( ax( 1 ), sprintf('Partitioning Comparison: %s %d', ...
    get_site_name( site ), yr ));
linkaxes( ax, 'x' );

% figname = fullfile(getenv('FLUXROOT'), 'QAQC_analyses', 'partitioning_comparison',...
%     sprintf('part_compare_%s_%d.pdf', get_site_name(sitecode), yr(1)));
% print(partition_comp_fig, '-dpdf', figname );

%----------------------------------------------------------------------
% SUBFUNCTIONS

% Plot the timeseries from all partitioning methods
    function handles = compare_timeseries( var, axis, tbl, keen )
        if strcmp( var, 'RE' )
            tbl_vars = { 'Reco', 'Reco_HBLR', 'RE_f_TK201X' };
            ylimit = [ -2, max( tbl.( tbl_vars{ 2 } )) ];
            sc = 1; % RE should have a positive sign convention
        elseif strcmp( var, 'GPP' )
            tbl_vars = { 'GPP_f', 'GPP_HBLR', 'GPP_f_TK201X' };
            ylimit = [ -max( tbl.( tbl_vars{ 2 } )), 5 ];
            sc = -1; % GPP has a negative sign convention
        end
        plot( axis, tbl.timestamp, tbl.NEE_f, ':', ...
            'color', [ 0.7,0.7,0.7 ] );
        hold on;
        plot( axis, tbl.timestamp, tbl.( tbl_vars{ 1 } ) * sc, '-k' );
        plot( axis, tbl.timestamp, tbl.( tbl_vars{ 2 } ) * sc, '-b' );
        if keen
            plot( axis, tbl.timestamp, ...
                tbl.( tbl_vars{ 3 } ) * sc * 100, ':r' );
        end
        ylabel( axis, [ var ' (umol/m2/s)' ]);
        ylim( axis, ylimit );
        datetick();
        handles = axis;
    end

% Plot the cumulative series
    function handles = compare_cumulative_series( var, axis, tbl, keen )
        if strcmp( var, 'RE' )
            tbl_vars = { 'Reco', 'Reco_HBLR', 'RE_f_TK201X' };
            sc = 1; % RE should have a positive sign convention
        elseif strcmp( var, 'GPP' )
            tbl_vars = { 'GPP_f', 'GPP_HBLR', 'GPP_f_TK201X' };
            sc = -1; % GPP has a negative sign convention
        end
        plot( tbl.timestamp, ...
            nan_cumsum( tbl.( tbl_vars{ 1 } )) * sc, '.k' );
        hold on;
        plot( tbl.timestamp, ...
            nan_cumsum( tbl.( tbl_vars{ 2 } )) * sc, '.b' );
        if keen
            plot( tbl.timestamp, ...
                nan_cumsum( tbl.( tbl_vars{ 3 } )) * sc * 100, '.r' );
        end
        ylabel( axis, [ 'Cum. ' var ' (umol/m2/s)' ]);
        datetick();
        handles = axis;
    end

% Small function to cumsum over invalid values ( NaN )
    function nonan = nan_cumsum( arr )
        nonan = arr;
        nonan( find( isnan( nonan ) )) = 0;
        nonan = cumsum( nonan );
    end

end