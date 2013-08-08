function h_fig = plot_radiation_NEE( sitecode, year, varargin )
% PLOT_RADIATION_NEE - 
%   
% USAGE
%    h_fig = plot_radiation_NEE( sitecode, year, 'source', source )
%    h_fig = plot_radiation_NEE( sitecode, year, PAR, Rg, NEE, doy )
%
% INPUTS
%     sitecode: UNM_sites object or integer; specifies site to process
%     year: integer; year to process
%     source: string; 'RBD' or 'Ameriflux'.  If 'RBD', get NEE, PAR, Rg from
%          output of UNM_RemoveBadData (QC, for_gapfill files).  If
%          'Ameriflux', get them from the gapfilled ameriflux file.
%     NEE, Rg, NEE, doy: numeric vectors containing the data to plot
%
% OUTPUTS
%     h_fig: handle to the figure containing the plot
%
% author: Timothy W. Hilton, UNM, July 2012

[ this_year, ~, ~, ~, ~, ~ ] = datevec( now() );

%%%%% parse arguments %%%%%
args = inputParser;
args.addRequired( 'sitecode', @(x) ( isintval( x ) | isa( x, 'UNM_sites' ) ) );
args.addRequired( 'year', ...
                  @(x) ( isintval( x ) & ( x >= 2006 ) & ( x <= this_year ) ) );
args.addOptional( 'PAR', [], @isnumeric );
args.addOptional( 'Rg', [], @isnumeric );
args.addOptional( 'NEE', [], @isnumeric );
args.addOptional( 'doy', [], @isnumeric );
args.addParamValue( 'source', '', ...
                    @(x) ismember( lower( x ), ...
                                   { 'rbd', 'rbd_filled', 'ameriflux' } ) );
% parse optional inputs
args.parse( sitecode, year, varargin{ : } );

% place user arguments into variables
sitecode = args.Results.sitecode;
year = args.Results.year;
source = lower( args.Results.source );

%%%%% get NEE, PAR, Rg, DOY from the arguments the user provided %%%%%
switch source
  case 'rbd'
    gf_suffix = '';
  case 'rbd_filled'
    gf_suffix = 'filled';
end

switch source
  case { 'rbd', 'rbd_filled' }
    %%%%% get PAR, Rg, NEE from output of UNM_RemoveBadData %%%%%
    % parse for gapfill file (product of UNM_RemoveBadData)
    data_GF  = parse_forgapfilling_file( sitecode, year, gf_suffix );
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
    Rg = data_GF.Rg;
    NEE = data_GF.NEE;
    
  case 'ameriflux'
    fname = get_ameriflux_filename( sitecode, year, 'gapfilled' );
    ameriflux_data = parse_ameriflux_file( fname );
    PAR = ameriflux_data.PAR;
    PAR_doy = ameriflux_data.DTIME;
    NEE = ameriflux_data.FC;
    Rg = ameriflux_data.Rg;
    doy = ameriflux_data.DTIME;
    
  case ''
    NEE = args.Results.NEE;
    Rg = args.Results.Rg;
    PAR = args.Results.PAR;
    PAR_doy = args.Results.doy;
    doy = args.Results.doy;
end
    
%%%%% draw the plot %%%%%

% plot Rg, NEE on two vertical axes
h_fig = figure( 'Name', sprintf( '%s %d', char( sitecode ), year ), ...
                'NumberTitle', 'Off' );
[ ax, h_PAR, h_NEE ] = plotyy( PAR_doy, PAR, ...
                               doy, NEE );
align_axes_zeros( ax( 1 ), ax( 2 ) );

hold( ax( 1 ), 'on' );
h_Rg = plot( doy, Rg );

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