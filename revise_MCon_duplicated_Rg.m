function data = revise_MCon_duplicated_Rg( data, headertext, t, varargin )
% REVISE_MCON_DUPLICATED_RG - in 2007 and 2008 the radiation sensor at MCon made
%   hourly measurements.  These were, in most cases, duplicated so that the
%   observations on the half hours are identical to the preceeding observations
%   on the hours.  Here, we remove the duplicated measurements and replace them
%   with the (most likely more realistic) linearly-interpolated measurements.
%
% USAGE
%     rad = revise_MCon_duplicated_Rg( rad, t );
%
% INPUTS
%     data: array of data from Fluxall file
%     headertext: column headers for the fluxall file
%     t: timestamps, matlab datenums
%
% OUTPUTS
%     rad: radiation observations with duplicated measurements replaced by
%         interpolated measurements.
%
% (c) Timothy W. Hilton, UNM, May 2013


% -----
% define optional inputs, with defaults and typechecking
% -----
args = inputParser;
args.addRequired( 'data', @isnumeric );
args.addRequired( 'headertext', @iscell );
args.addRequired( 't', @isnumeric );
args.addParamValue( 'draw_plots', true, @islogical );

% parse optional inputs
args.parse( data, headertext, t, varargin{ : } );
data = args.Results.data;
headertext = args.Results.headertext;
t = args.Results.t;

% find the incoming shortwave within fluxall data
Rg_col = find( strcmp('Rad_short_Up_Avg', headertext) | ...
               strcmp('pyrr_incoming_Avg', headertext) ) - 1;
rad = data( :, Rg_col );

% identify Nov and Dec measurements
[ year, month, ~, hour, minute, ~ ] = datevec( t );

% find differences between consecutive radiation observations.  Place NaN in
% first element because there is no preceeding element, so no diff value.
rad_diff = [ NaN; diff( rad ) ];

% only want to find daytime duplicates.
is_day = rad > 1;

% find daytime duplicated observations
is_dup = ( abs( rad_diff ) < 1e-6 ) & is_day;
not_dup = not( is_dup );

% replace duplicated Rg observations with interpolated values
rad_raw = rad;
rad( is_dup ) = interp1( find( not_dup ), rad( not_dup ), find( is_dup ) );
% rad( is_dup ) = NaN;
% rad = inpaint_nans( rad );

if args.Results.draw_plots
    figure();
    % plot raw Rg (straight from datalogger, no calibration corrections)
    ax1 = subplot( 3, 1, 1 );
    plot( rad_raw, '.k' );
    hold on;
    h_dup = plot( find( is_dup ), rad_raw( find( is_dup ) ), '.r' );
    ylabel( 'Rg raw' );
    legend( h_dup, 'duplicate', 'Location', 'best' );
    % plot Rg consecutive differences
    ax2 = subplot( 3, 1, 2 );
    plot( rad_diff, '.' );
    ylabel( 'Rg diff' );
    % plot interpolated Rg
    ax3 = subplot( 3, 1, 3 );
    plot( rad, '.k' );
    hold on;
    h_dup = plot( find( is_dup ), rad( find( is_dup ) ), '.r' );
    ylabel( 'Rg fixed' );
    h_leg = legend( h_dup, 'interpolated', 'Location', 'best' );
    xlabel( 'array index' );
    % 
    linkaxes( [ ax1, ax2, ax3 ], 'x' );
    suptitle( sprintf( 'MCon %d duplicated radiation fix results', median( year ) ) );
end


hour_minute = hour + ( minute ./ 60 );
idx_nov = ( month == 11 ) & ( rad > 1 ) & ...
          ( ( hour_minute <= 7.0 ) | ( hour_minute >= 17.5 ) );
idx_dec = ( month == 12 ) & ( rad > 1 ) & ...
          ( ( hour_minute <= 7.5 ) | ( hour_minute >= 18.0 ) );
idx_oct = ( month == 12 ) & ( rad > 1 ) & ...
          ( ( hour_minute <= 7.5 ) | ( hour_minute >= 19.0 ) );
idx = idx_oct & idx_nov | idx_dec;

if args.Results.draw_plots
    doy = t - datenum( median( year ), 1, 0 );
    figure();
    plot( doy, rad, '.k' );
    hold on;
    h_nan = plot( doy( idx ), rad( idx ), '.r' );
    ylabel( 'Rg raw' );
    xlabel( 'DOY' );
    title( sprintf( 'MCon %d Nov/Dec radiation fix results', median( year ) ) );
    legend( h_nan, 'set to NaN', 'Location', 'best' );
end

rad( idx ) = NaN;
data( :, Rg_col ) = rad;

fprintf( 'MCon %d radiation repaired\n', median( year ) );
