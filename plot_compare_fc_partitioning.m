function dfig_1 = plot_compare_fc_partitioning( site, yr, ...
                                                data_in )
% PLOT_COMPARE_FC_PARTITIONING - makes diagnostic figures showing the
% output of several different NEE partitioning methods.
%
% Called from Ameriflux File Maker
% FIXME - documentation
%
% INPUTS
%    sitecode: UNM_sites object; specifies the site to show
%    year: four-digit year: specifies the year to show
%    data_in: MATLAB table: array including partitioned flux columns
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

% parse optional inputs
args.parse( site, yr, data_in );

site = args.Results.site;
yr = args.Results.yr;
pt_tbl = args.Results.data_in; % Contains partitioned NEE values

% Small function to cumsum over invalid values ( NaN )
    function nonan = nan_cumsum( arr )
        nonan = arr;
        nonan( find( isnan( nonan ) )) = 0;
        nonan = cumsum( nonan );
    end

% Set up figure window
dfig_1 = figure( 'Name',...
    sprintf('NEE partitioning comparison, %s %d', site, yr),...
    'Units', 'centimeters', 'Position', [5, 5, 29, 23] );

% Four subplots
ax( 1 ) = subplot( 2, 3, 1:2 );
plot( pt_tbl.timestamp, pt_tbl.NEE_f, ':', 'color', [0.7,0.7,0.7] );
hold on;
plot( pt_tbl.timestamp, pt_tbl.Reco, '.k' );
plot( pt_tbl.timestamp, pt_tbl.Reco_HBLR, 'xb' );
legend( 'filled NEE', 'R_{eco} Reichstein', 'R_{eco} Lasslop', ...
    'Location','southwest' );
datetick(); %ylim([-15, 10]);

ax( 2 ) = subplot( 2, 3, 3 );
plot( pt_tbl.timestamp, nan_cumsum( pt_tbl.Reco ), '.k' );
hold on;
plot( pt_tbl.timestamp, nan_cumsum( pt_tbl.Reco_HBLR ), 'xb' );

ax( 3 ) = subplot( 2, 3, 4:5 );
plot( pt_tbl.timestamp, pt_tbl.NEE_f, ':', 'color', [ 0.7,0.7,0.7 ] );
hold on;
plot( pt_tbl.timestamp, -pt_tbl.GPP_f, '.k' );
plot( pt_tbl.timestamp, -pt_tbl.GPP_HBLR, 'xr' );
legend( 'filled NEE', 'GPP Reichstein', 'GPP Lasslop', ...
    'Location','southwest' );
datetick( ); %ylim([-15, 10]);

ax( 4 ) = subplot( 2, 3, 6 );
plot( pt_tbl.timestamp, nan_cumsum( pt_tbl.GPP_f ), '.k' );
hold on;
plot( pt_tbl.timestamp, nan_cumsum( pt_tbl.GPP_HBLR ), 'xr');
title( ax( 1 ), sprintf('Partitioning Comparison: %s %d', ...
    get_site_name( sitecode ), yr ));
linkaxes( ax, 'x' );

% figname = fullfile(getenv('FLUXROOT'), 'QAQC_analyses', 'partitioning_comparison',...
%     sprintf('part_compare_%s_%d.pdf', get_site_name(sitecode), yr(1)));
% print(partition_comp_fig, '-dpdf', figname );

end