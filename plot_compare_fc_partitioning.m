function fighandle = plot_compare_fc_partitioning( sitecode, yr, ...
                                                   data_in, varargin )
% PLOT_COMPARE_FC_PARTITIONING - makes diagnostic figures showing the
% output of several different NEE partitioning methods.
%
% Called from Ameriflux File Maker
% FIXME - documentation
%
% INPUTS
%    sitecode: UNM_sites object; specifies the site to show
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
args.addRequired( 'sitecode', @(x) ( isintval( x ) | isa( x, 'UNM_sites' ) ) );
args.addRequired( 'yr', ...
    @(x) ( isintval( x ) & ( x >= 2006 ) & ( x <= this_year ) ) );
args.addRequired( 'data_in', @istable );
args.addParameter( 'keenan', false, @islogical );

% Parse optional inputs
args.parse( sitecode, yr, data_in, varargin{ : } );
sitecode = args.Results.sitecode;
yr = args.Results.yr;
af_tbl = args.Results.data_in; % Contains partitioned NEE values
keenan = args.Results.keenan;

% These are the partitioned flux variables to be plotted
re_vars = { 'RECO_MR2005', 'RECO_GL2010', 'RECO_F_TK201X' };
gpp_vars = { 'GPP_F_MR2005', 'GPP_GL2010', 'GPP_F_TK201X' };

% Set up figure window
fighandle = figure( 'Name',...
    sprintf('NEE partitioning comparison, %s %d', sitecode, yr),...
    'Units', 'centimeters', 'Position', [2, 2, 34, 22] );

% Four subplots
ax( 1 ) = subplot( 2, 3, 1:2 );
h = compare_timeseries( 'RECO', ax( 1 ), af_tbl, keenan );
if keenan
    legend( 'filled NEE', 'Reichstein', 'Lasslop', 'Keenan x 100', ...
        'Location','northwest' )
else
    legend( 'filled NEE', 'Reichstein', 'Lasslop', ...
        'Location','northwest' )
end

ax( 2 ) = subplot( 2, 3, 3 );
h = compare_cumulative_series( 'RECO', ax( 2 ), af_tbl, keenan );

ax( 3 ) = subplot( 2, 3, 4:5 );
h = compare_timeseries( 'GPP', ax( 3 ), af_tbl, keenan );

ax( 4 ) = subplot( 2, 3, 6 );
h = compare_cumulative_series( 'GPP', ax( 4 ), af_tbl, keenan );

title( ax( 1 ), sprintf('Partitioning Comparison: %s %d', ...
    get_site_name( sitecode ), yr ));
linkaxes( ax, 'x' );

figname = fullfile( getenv( 'FLUXROOT' ), 'Plots', ...
    'partitioning_comparison', sprintf( 'part_compare_%s_%d.pdf', ...
    get_site_name( sitecode ), yr( 1 ) ));
print( fighandle, '-dpdf', figname );

%----------------------------------------------------------------------
% SUBFUNCTIONS

% Plot the timeseries from all partitioning methods
    function handles = compare_timeseries( var, axis, tbl, keen )
        if strcmp( var, 'RECO' )
            tbl_vars = re_vars;
            ylimit = [ -2, max( tbl.( tbl_vars{ 2 } )) ];
            sc = 1; % RE should have a positive sign convention
        elseif strcmp( var, 'GPP' )
            tbl_vars = gpp_vars;
            ylimit = [ -max( tbl.( tbl_vars{ 2 } )), 5 ];
            sc = -1; % GPP has a negative sign convention
        end
        plot( axis, tbl.timestamp, tbl.FC_F, ':', ...
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
        if strcmp( var, 'RECO' )
            tbl_vars = re_vars;
            sc = 1; % RE should have a positive sign convention
        elseif strcmp( var, 'GPP' )
            tbl_vars = gpp_vars;
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