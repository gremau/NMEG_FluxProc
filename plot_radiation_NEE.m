function h_fig = plot_radiation_NEE( sitecode, year )
% PLOT_RADIATION_NEE - 
%   

% parse for gapfill file (product of UNM_RemoveBadData)
data_GF  = parse_forgapfilling_file( sitecode, year, 'filled' );
% parse QC file (product of UNM_RemoveBadData)
data_QC = UNM_parse_QC_txt_file( sitecode, year );
[ y, ~, ~, ~, ~, ~ ] = datevec( data_QC.timestamp );
data_QC( y ~= year, : ) = [];
PAR = data_QC.Par_Avg;
PAR_doy = data_QC.timestamp - datenum( year, 1, 0 );

% remove any data not from requested year
[ y, ~, ~, ~, ~, ~ ] = datevec( data_GF.timestamp );
data_GF( y ~= year, : ) = [];
% calculate fractional doy of year for each observation
doy = data_GF.timestamp - datenum( year, 1, 0 );


% plot Rg, NEE on two vertical axes
h_fig = figure( 'Name', sprintf( '%s %d', char( sitecode ), year ), ...
                'NumberTitle', 'Off' );
[ ax, h_PAR, h_NEE ] = plotyy( PAR_doy, PAR, ...
                              doy, data_GF.NEE );
align_axes_zeros( ax( 1 ), ax( 2 ) );

hold( ax( 1 ), 'on' );
h_Rg = plot( doy, data_GF.Rg );

% use a nice color palette, set axes labels for each vertical axis
%     left vertical axis
pal = cbrewer( 'qual', 'Dark2', 3 );
set( h_Rg, 'Color', pal( 2, : ) );
set( ax( 1 ), 'YColor', 'k', ...
              'Xlim', [ 0, 366 ] );
axes( ax( 1 ) );
ylabel( 'Radiation [ W m^{-2} ]' );
xlabel( 'day of year' );
%     right vertical axis
set( h_NEE, 'Color', pal( 1, : ) );
set( ax( 2 ), 'YColor', pal( 1, : ), ...
              'XLim', [ 0, 366 ] );
axes( ax( 2 ) );
ylabel( 'NEE [ \mu mol m^{-2} s^{-1} ]' );
%     PAR curve color
set( h_PAR, 'Color', 'black' );

% make a legend
legend( [ h_Rg, h_PAR, h_NEE ], 'Rg', 'PAR', 'NEE', 'Location', 'best' );
title( sprintf( '%s %d', char( sitecode ), year ) );

set( h_fig, 'Units', 'Normalized' );
pos = get( h_fig, 'Position' );
pos( 1 ) = 0;
pos( 3 ) = 1;
set( h_fig, 'Position', pos );