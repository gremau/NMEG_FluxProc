function UNM_site_plot_fullyear_time_offsets( sitecode, year, varargin )
% UNM_SITE_PLOT_DOY_TIME_OFFSETS - plot the offset between observed incoming
% shortwave radiation daily cycle and calculated solar angle daily cycle for
% each day of the specified year.
%  
% USAGE
%    UNM_site_plot_fullyear_time_offsets( sitecode, year )
%    UNM_site_plot_fullyear_time_offsets( sitecode, year, save_fig )
%
% INPUTS
%    sitecode: integer or UNM_sites object
%    year: integer
% PARAMETER-VALUE PAIRS
%    save_fig: true|{false}; if true, save the figure to an eps file
%    data: optional; dataset array; data for the site year.  Must contain fields
%        Rg and timestamp.  If omitted the data are obtained from
%        fluxall_for_gapfilling
%
% OUTPUTS
%    no outputs
%
% SEE ALSO
%    dataset, UNM_site_plot_doy_time_offsets
% 
% author: Timothy W. Hilton, UNM, June 2012

% -----
% define optional inputs, with defaults and typechecking
% -----

warning('This script (UNM_site_plot_fullyear_time_offsets) is deprecated!');

args = inputParser;
args.addRequired( 'sitecode', @(x) ( isintval( x ) | isa( x, 'UNM_sites' ) ) );
[ this_year, ~, ~ ] = datevec( now );
args.addRequired( 'year', ...
               @(x) ( isintval( x ) & ( x >= 2006 ) & ( x <= this_year ) ) );
args.addParamValue( 'save_fig', false, @islogical );
args.addParamValue( 'data', [], @(x) isa( x, 'dataset' ) );

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
if isempty( args.Results.data )
    data = parse_forgapfilling_file( sitecode, year, 'use_filled', false );
else 
    data = args.Results.data;
end
%RJL sol_ang = UNM_get_solar_angle( sitecode, data.timestamp );
sol_ang = get_solar_elevation( sitecode, data.timestamp );

opt_off_Rg = repmat( NaN, 1, numel( 1:365 ) );
opt_off_PAR = repmat( NaN, 1, numel( 1:365 ) );
for doy = 1:365
    opt_off_Rg( doy ) = match_solarangle_radiation( data.Rg, ...
                                                    sol_ang, ...
                                                    data.timestamp, ...
                                                    doy, year, false );
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