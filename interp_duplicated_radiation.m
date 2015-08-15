function data_out = interp_duplicated_radiation( data_in, headertext, t, varargin )
% INTERP_DUPLICATED_RADIATION - Interpolate hourly radiation
% observations to half-hourly.
%
% At some sites the radiation sensor made hourly measurements.  These
% were then duplicated so that the observations on the half hours are
% identical to the preceeding observations.  Here, we remove the
% duplicated measurements and replace them with the
% linearly-interpolated measurements.
%
% USAGE
%     rad = interp_duplicated_radiation( rad, t );
%
% INPUTS
%     data_in: numeric; array of data from Fluxall file
%     headertext: cell array of strings; column headers for the fluxall file
%     t: timestamps, Matlab serial datenumbers
%
% OUTPUTS
%     rad: radiation observations with duplicated measurements replaced by
%         interpolated measurements.
%
% SEE ALSO
%     datenum
%
% author: Gregory E. Maurer, UNM, May 2015


% -----
% define optional inputs, with defaults and typechecking
% -----
args = inputParser;
args.addRequired( 'data_in', @isnumeric );
args.addRequired( 'headertext', @iscell );
args.addRequired( 't', @isnumeric );
args.addParamValue( 'draw_plots', true, @islogical );

% parse optional inputs
args.parse( data_in, headertext, t, varargin{ : } );
data_in = args.Results.data_in;
headertext = args.Results.headertext;
t = args.Results.t;

% find the incoming shortwave within fluxall data
Rg_col = find( strcmp('Rad_short_Up_Avg', headertext) | ...
               strcmp('pyrr_incoming_Avg', headertext) );
rad = data_in( :, Rg_col );

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
    suptitle( sprintf( ' %d duplicated radiation fix results', median( year ) ) );
end


data_out = data_in;
data_out( :, Rg_col ) = rad;

fprintf( 'Duplicated %d radiation repaired\n', median( year ) );
