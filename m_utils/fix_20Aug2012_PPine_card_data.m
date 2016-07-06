function [ toa5_data, tob1_data ] = fix_20Aug2012_PPine_card_data( )
% FIX_20AUG2012_PPINE_CARD_DATA - correct problems in Aug 2012 PPine data.
%   

toa5_data_dir = fullfile( get_site_directory( UNM_sites.PPine ), ...
                          'toa5', 'TOA5_PPine_2012_08_20_0000' );

toa5_fname = fullfile( toa5_data_dir, 'TOA5_FIX1_test.flux_2012_05_09_1300.dat' );
toa5_data = toa5_2_table( toa5_fname );


% We know the card was pulled on 20 Aug.  Therefore line 34 (sunrise on 21
% Aug, according to the shortave incoming data) is 6:30 MDT (sunrise in Jemez
% Springs, NM on 21 Aug 2012), or 5:30 MST.  Therefore set line 34 to 5:30 21
% Aug 2012 and fill in other timestamps accordingly.

toa5_data.timestamp = fix_times( toa5_data.timestamp, ...
                                 1429, ...
                                 datenum( 2012, 8, 20, 5, 30, 0 ) );

% FIX TOB1 timestamps

tob1_data_file = fullfile( get_site_directory( UNM_sites.PPine ), ...
                           'ts_data', ...
                           '20_Aug_2012_PPine_tsdata', ...
                           '20_Aug_2012_PPine_TOB1_processed_filled.mat' );
load( tob1_data_file );
tob1_data = all_data;
clear( 'all_data' );

tob1_fld = tob1_data.temp_mean;
toa5_fld = toa5_data.Ts_Avg;

[c_ww,lags] = xcorr( inpaint_nans( tob1_fld ), inpaint_nans( toa5_fld ) );
figure();
plot( lags, c_ww, '.' );
xlabel( 'lag' );
ylabel( 'xcorr' );

[ ~, idx_min ] = max( c_ww );
offset = lags( idx_min );

% adjust TOB1 timestamps so that the temperature records match.
tob1_data.timestamp = fix_times( tob1_data.timestamp, ...
                                 offset, ...
                                 toa5_data.timestamp( 1 ) );
tob1_data.timestamp2 = tob1_data.timestamp;
[ tob1_data.year, tob1_data.month, tob1_data.day, ...
  tob1_data.hour, tob1_data.min, tob1_data.second ] = ...
    datevec( tob1_data.timestamp );
tob1_data.jday = tob1_data.timestamp - datenum( 2012, 1, 0 );
tob1_data.date = str2num( datestr( tob1_data.timestamp, 'mmddyy' ) );



if 0
    figure();
    idx = ( 1:numel( tob1_fld ) ) + offset - 1;
    h_tob1 = plot( tob1_fld( offset:end), '-' );
    hold on
    h_tob1_un = plot( tob1_fld, '-r' );
    idx = ( 1:numel( toa5_fld ) ) + offset - 1;
    h_toa5 = plot( toa5_fld, '-k' );
    legend( [ h_tob1, h_tob1_un, h_toa5 ], ...
            { 'TOB1 temp, adj', 'TOB1 temp', 'TOA5 temp' } );
end

% --------------------------------------------------
function t_fixed = fix_times( t_in, idx, ref_date )
% FIX_TIMES - sets t_in( idx ) to ref_date, and fills in the surrounding
%   30-minute timestamps accordingly


thirty_mins = 1 / 48;  % thirty minutes in units of days

t_fixed = t_in;
t_fixed( idx ) = ref_date;
t_fixed( idx+1:end ) = thirty_mins;

% fill in later timestamps by consectively adding 30 minutes
t_fixed( idx+1:end ) = ...
    t_fixed( idx ) + cumsum( t_fixed( idx+1:end ) );
% fill in earlier timestamps by consectively subtracting 30 minutes
t_early = repmat( -1 * thirty_mins, idx-1, 1 );
t_early = flipud( cumsum( t_early ) );
t_fixed( 1:idx-1 ) = t_fixed( idx ) + t_early;

