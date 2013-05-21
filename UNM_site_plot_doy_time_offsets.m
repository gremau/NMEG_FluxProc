function UNM_site_plot_doy_time_offsets( sitecode, year, doy, varargin )
% UNM_SITE_PLOT_DOY_TIME_OFFSETS - 
%
% USAGE
%   UNM_site_plot_doy_time_offsets( sitecode, year, doy )
% 
% INPUTS
%   sitecode: integer or UNM_sites object
%   year: integer: the year requested
%   doy: integer: the day of year to plot
%
% OUTPUTS
%   no outputs
%
% (c) Timothy W. Hilton, UNM, June 2012

[ this_year, ~, ~, ~, ~, ~ ] = datevec( now() );

args = inputParser;
args.addRequired( 'sitecode', @(x) ( isintval( x ) | isa( x, 'UNM_sites' ) ) );
args.addRequired( 'year', ...
                  @(x) ( isintval( x ) & ( x >= 2006 ) & ( x <= this_year ) ...
                         ) );
args.addRequired( 'doy', @(x) ( isintval( x ) & ( x > 0 ) & ( x < 367 ) ) );
args.addParamValue( 'Rg', [],  @(x) ( isnumeric( x ) ) );
args.addParamValue( 'timestamp', [],  @(x) ( isnumeric( x ) ) );

% parse optional inputs
args.parse( sitecode, year, doy, varargin{ : } );

if isempty( args.Results.Rg )
    data = parse_forgapfilling_file( args.Results.sitecode, ...
                                     args.Results.year );
    timestamp = data.timestamp;
    Rg = data.Rg;
else
    timestamp = args.Results.timestamp;
    Rg = args.Results.Rg;
end

sol_ang = UNM_get_solar_angle( args.Results.sitecode, timestamp );
opt_off = match_solarangle_radiation( Rg, ...
                                      sol_ang, ...
                                      timestamp, ...
                                      args.Results.doy, ...
                                      args.Results.year, true );

