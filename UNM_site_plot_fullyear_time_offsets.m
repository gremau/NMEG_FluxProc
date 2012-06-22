function UNM_site_plot_fullyear_time_offsets( sitecode, year, varargin )
% UNM_SITE_PLOT_DOY_TIME_OFFSETS - 
%  
% USAGE
%    UNM_site_plot_fullyear_time_offsets( sitecode, year )
%    UNM_site_plot_fullyear_time_offsets( sitecode, year, save_fig )
%
% INPUTS
%    sitecode: integer or UNM_sites object
%    year: integer
%    save_fig: optional, logical; if true, save the figure to an eps file
%        (default false)
%
% OUTPUTS
%    no outputs
%
% (c) Timothy W. Hilton, UNM, June 2012

% -----
% define optional inputs, with defaults and typechecking
% -----
args = inputParser;
args.addRequired( 'sitecode', @(x) ( isintval( x ) | isa( x, 'UNM_sites' ) ) );
[ this_year, ~, ~ ] = datevec( now );
args.addRequired( 'year', ...
               @(x) ( isintval( x ) & ( x >= 2006 ) & ( x <= this_year ) ) );
args.addParamValue( 'save_fig', false, @islogical );

% parse optional inputs
args.parse( sitecode, year, varargin{ : } );

% place user arguments into variables
sitecode = args.Results.sitecode;
if ~isa( sitecode, 'UNM_sites' )
    sitecode = UNM_sites( sitecode );
end
year = args.Results.year;

% -----
% calculate the offsets
% -----
data = parse_forgapfilling_file( sitecode, year, '' );
sol_ang = UNM_get_solar_angle( sitecode, data.timestamp );

opt_off_Rg = repmat( NaN, 1, numel( 1:365 ) );
opt_off_PAR = repmat( NaN, 1, numel( 1:365 ) );
for doy = 1:365
    opt_off_Rg( doy ) = match_solarangle_radiation( data.Rg, ...
                                                    sol_ang, ...
                                                    data.timestamp, ...
                                                    doy, year, false );
    % opt_off_PAR( doy ) = match_solarangle_radiation( data.PAR, ...
    %                                              sol_ang, ...
    %                                              data.timestamp, ...
    %                                              doy, year, false );
end

t_str = sprintf( '%s %d radiation offset', char( sitecode ), year ); 
h_fig = figure( 'Name', t_str );
h_Rg = plot( opt_off_Rg, '.k' );
% hold on;
% h_PAR = plot( opt_off_PAR, 'ob' );
title( t_str );
xlabel( 'DOY' );
ylabel( 'offset, hours' );
%legend( [ h_Rg, h_PAR ], 'Rg', 'PAR', 'Location', 'best' );

% -----
% if requested, save plot to eps file
% -----
if args.Results.save_fig
    fname_plot = fullfile( 'C:', 'Users', 'Tim', 'Plots', 'RadiationOffset', ...
                           sprintf( 'radiation_offset_%s_%d.eps', ...
                                    char( sitecode ), year ) );
    set( h_fig, 'PaperPositionMode', 'auto' );
    print( h_fig, '-depsc2', fname_plot );
end