function UNM_site_plot_doy_time_offsets( sitecode, year, doy, varargin )
% UNM_SITE_PLOT_DOY_TIME_OFFSETS - plot calculated solar angle and observed
% incoming shortwave side by side for a given site and day.
%
% Examining the two daily cycles side by side helps to identify periods where
% the datalogger clock is incorrect.
%
% Uses match_solarangle_radiation to calculate the offsets.
%
% USAGE
%   UNM_site_plot_doy_time_offsets( sitecode, year, doy )
% 
% INPUTS
%   sitecode: integer or UNM_sites object; specifies the site
%   year: integer: the year requested
%   doy: integer: the day of year to plot
% PARAMETER-VALUE PAIRS
%    Rg: numeric vector; Rg data to be used.  If omitted, Rg data are read
%        from fluxall_for_gap_filling file (written by UNM_RemoveBadData).
%    timestamp: timestamps for optional Rg parameter.  Must be provided if Rg
%        is provided.
% OUTPUTS
%   no outputs
%
% SEE ALSO
%   UNM_sites, UNM_RemoveBadData, UNM_RemoveBadData_pre2012,
%   UNM_site_plot_fullyear_time_offsets, match_solarangle_radiation
%
% author: Timothy W. Hilton, UNM, June 2012

warning('This script (UNM_site_plot_doy_time_offsets) is deprecated!');

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

sol_ang = get_solar_elevation( args.Results.sitecode, timestamp );
opt_off = match_solarangle_radiation( Rg, ...
                                      sol_ang, ...
                                      timestamp, ...
                                      args.Results.doy, ...
                                      args.Results.year, true );

