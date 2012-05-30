% ------------------------------------------------------------
% parse data
% ------------------------------------------------------------

pal = brewer_palettes( 'Dark2' );

filename = fullfile(  'C:', 'Users', 'Tim', ...
                     'DataSandbox', ...
                     '20120503_Andy_Differences_PJG2009.txt' );

fmt = repmat( '%f%f%d', 1, 4 );

andy = dataset( 'File', filename, ...
                'Delimiter', '\t', ...
                'HeaderLines', 4, ...
                'Format', fmt );

andy.Properties.VarNames = { 'DTIME_2010_old', 'FC_2010_old', ...
                    'FC_flag_2010_old', 'DTIME_2010_new', 'FC_2010_new', ...
                    'FC_flag_2010_new', 'DTIME_2009_old', 'FC_2009_old', ...
                    'FC_flag_2009_old', 'DTIME_2009_new', 'FC_2009_new', ...
                    'FC_flag_2009_new' };



load( ['C:\Research_Flux_Towers\FluxOut\TOB1_data\' ...
       'PJ_girdle_TOB1_2009_filled.mat'] );

pjg09_Aflx_file = ['C:\Research_Flux_Towers\FluxOut\US-' ...
                   'Mpg_2009_gapfilled.txt'];
tim_aflx09 = parse_ameriflux_file( pjg09_Aflx_file );

pjg10_Aflx_file = ['C:\Research_Flux_Towers\FluxOut\US-' ...
                   'Mpg_2010_gapfilled.txt'];
tim_aflx10 = parse_ameriflux_file( pjg10_Aflx_file );

% ------------------------------------------------------------
% plot 2009 old, new
% ------------------------------------------------------------
figure();
h_old = plot( andy.DTIME_2009_old, andy.FC_2009_old, 'k.' );
hold on
h_new = plot( andy.DTIME_2009_new, andy.FC_2009_new, ...
              'o', 'Color', pal( 1, : ) );
h_tim = plot( all_data.jday, ...
              all_data.Fc_raw_massman_ourwpl, ...
              'x', 'Color', pal( 2, : ) );
h_tim_aflx = plot( tim_aflx09.DTIME, tim_aflx09.FC, ...
                   'd', 'Color', pal( 3, : ) );
hold off
set( h_new, 'Visible', 'off' );
% axes limits, labels
xlim( [ 0, 366 ] );
ylim( [ -10, 10 ] );
xlabel( 'DOY' );
ylabel( 'NEE (umol/m2/s' );
title( 'PJg 2009' );
legend( [ h_old, h_new, h_tim, h_tim_aflx ], ...
        { 'Andy old', 'Andy new', 'Tim-raw', 'Tim Aflx' } );

% ------------------------------------------------------------
% plot 2010 old, new
% ------------------------------------------------------------
figure();
h_old = plot( andy.DTIME_2010_old, andy.FC_2010_old, 'k.' );
hold on
h_new = plot( andy.DTIME_2010_new, andy.FC_2010_new, 'bo' );
h_tim_aflx = plot( tim_aflx10.DTIME, tim_aflx10.FC, ...
                   'd', 'Color', pal( 3, : ) );
hold off
% axes limits, labels
xlim( [ 0, 366 ] );
ylim( [ -10, 10 ] );
xlabel( 'DOY' );
ylabel( 'NEE (umol/m2/s' );
title( 'PJg 2010' );
legend( [ h_old, h_new, h_tim_aflx ], { 'Andy old', 'Andy new', 'Tim aflx' } );

% ----------------------------------------------------------------------

% figure()
% h_old = plot( andy.DTIME_2010_old, andy.FC_2010_old, 'k.' );
% hold on
% h_new = plot( tim_aflx.DTIME, tim_aflx.FC, 'bo' );
% hold off
% % axes limits, labels
% xlim( [ 0, 366 ] );
% ylim( [ -10, 10 ] );
% xlabel( 'DOY' );
% ylabel( 'NEE (umol/m2/s' );
% title( 'PJg 2010' );
% legend( [ h_old, h_new ], { 'old', 'new' } );

