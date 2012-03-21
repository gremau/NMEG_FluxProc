function result = UNM_fill_met_gaps_from_nearby_site( sitecode, year, draw_plots )
% UNM_FILL_MET_GAPS_FROM_NEARBY_SITE - fills gaps in site's meteorological data
%   from the closest nearby site
%
% USAGE
%     result = UNM_fill_met_gaps_from_nearby_site(sitecode, year)
%
% INPUTS
%     sitecode [ integer ]: code of site to be filled
%     year [ integer ]: year to be filled
%
% OUTPUTS
%     result [ integer ]: 0 on success, -1 on failure
%
% (c) Timothy W. Hilton, UNM, March 2012
    
% initialize
result = -1;
nearby_2 = [];

%--------------------------------------------------
% parse unfilled data from requested site
    
fprintf( 'parsing %s_flux_all_%d_for_gapfilling.txt ("destination")\n', ...
         get_site_name( sitecode ), year );
this_data = parse_forgapfilling_file( sitecode, year );

%--------------------------------------------------
% parse data with which to fill T & RH
                
switch sitecode
  case 1    % fill GLand from SLand, then Sev Deep Well station (# 40)
    fprintf( 'parsing %s_flux_all_%d_for_gapfilling.txt ("source")\n', ...
             get_site_name( 2 ), year );  %
    nearby_data = parse_forgapfilling_file( 2, year );
    nearby_2 = UNM_parse_sev_met_data( year );
    nearby_2 = prepare_sev_met_data( nearby_2, year, 40 );
  case 2    % fill SLand from GLand, then Sev Five Points station (# 49 )
    fprintf( 'parsing %s_flux_all_%d_for_gapfilling.txt ("source")\n', ...
             get_site_name( 1 ), year );
    nearby_data = parse_forgapfilling_file( 1, year );
    nearby_2 = UNM_parse_sev_met_data( year );
    nearby_2 = prepare_sev_met_data( nearby_2, year, 49 );
  case 4     % fill PJ from PJ girdle    
    fprintf( 'parsing %s_flux_all_%d_for_gapfilling.txt ("source")\n', ...
             get_site_name( 10 ), year );
    nearby_data = parse_forgapfilling_file( 10, year );
  case 5     % fill PPine from Valles Caldera HQ met station ( station 11 )
    fprintf( 'parsing Valles Caldera headquarters met station ("source")\n' );
    nearby_data = UNM_parse_valles_met_data( year );
    nearby_data = prepare_valles_met_data( nearby_data, year, 11 );
  case 6     % fill MCon from Valles Caldera Redondo met station ( station 14 )
    fprintf( 'parsing Valles Caldera Redondo met station ("source")\n' );
    nearby_data =UNM_parse_valles_met_data( year );
    nearby_data = prepare_valles_met_data( nearby_data, year, 14 );
  case 10    % fill PJ_girdle from PJ
    fprintf( 'parsing %s_flux_all_%d_for_gapfilling.txt ("source")\n', ...
             get_site_name( 4 ), year );
    nearby_data = parse_forgapfilling_file( 4, year );
  case 11    % fill New_GLand from GLand
    fprintf( 'parsing %s_flux_all_%d_for_gapfilling.txt ("source")\n', ...
             get_site_name( 1 ), year );
    nearby_data = parse_forgapfilling_file( 1, year );
  otherwise
    fprintf( 'filling not yet implemented for %s\n', ...
             get_site_name( sitecode ) );
    result = -1;
    return
end

%--------------------------------------------------
% sychronize nearby_site timestamps to this_data timestamps
seconds = repmat( 0.0, size( this_data, 1 ), 1 );
ts = datenum( this_data.year, this_data.month, this_data.day, ...
              this_data.hour, this_data.minute, seconds );
nearby_data.timestamp = ts;
thirty_mins = 1.0 / 48.0;   % 30 minutes in units of days
nearby_data = dataset_fill_timestamps( nearby_data, 'timestamp', ...
                                       thirty_mins, ...
                                       min( ts ), ...
                                       max( ts ) );
if not( isempty( nearby_2 ) )
    nearby_2 = dataset_fill_timestamps( nearby_2, 'timestamp', ...
                                        thirty_mins, ...
                                        min( ts ), ...
                                        max( ts ) );
end

%--------------------------------------------------
% fill T, RH

% replace missing Tair with nearby site
n_missing = numel( find( isnan( this_data.Tair ) ) );
T_filled_1 = find( isnan( this_data.Tair ) & ...
                   ~isnan( nearby_data.Tair ) );
this_data.Tair( T_filled_1 ) = nearby_data.Tair( T_filled_1 );
% if there is a secondary site, fill remaining missing values 
T_filled_2 = [];  %initialize to empty in case there is no second site
if not( isempty( nearby_2 ) )
    T_filled_2 = find( isnan( this_data.Tair ) & ...
                       isnan( nearby_data.Tair ) & ...
                       ~isnan( nearby_2.Tair ) );
    this_data.Tair( T_filled_2 ) = nearby_2.Tair( T_filled_2 );
end
n_filled = numel( T_filled_1 ) + numel( T_filled_2 );
fprintf( 'Tair: replaced %d / %d missing observations\n', ...
         n_filled, n_missing );

% replace missing rH with nearby site
n_missing = numel( find( isnan( this_data.rH ) ) );
RH_filled_1 = find( isnan( this_data.rH ) & ~isnan( nearby_data.rH ) );
this_data.rH( RH_filled_1 ) = nearby_data.rH( RH_filled_1 );
% if there is a secondary site, fill remaining missing values 
RH_filled_2 = [];
if not( isempty( nearby_2 ) )
    RH_filled_2 = find( isnan( this_data.rH ) & ...
                        isnan( nearby_data.rH ) & ...
                        ~isnan( nearby_2.rH ) );
    this_data.rH( RH_filled_2 ) = nearby_2.rH( RH_filled_2 );
end
n_filled = numel( RH_filled_1 ) + numel( RH_filled_2 );
fprintf( 'rH: replaced %d / %d missing observations\n', ...
         n_filled, n_missing );

%--------------------------------------------------
% fill RH, plot if requested

if draw_plots
    % calculate day of year for 30-minute data
    doy = ( 1:size( this_data, 1 ) ) / 48.0;

    h_RH_fig = figure();
    h_obs = plot( doy, this_data.rH, '.k' );
    hold on;
    h_filled_1 = plot( doy( RH_filled_1 ), ...
                       nearby_data.rH( RH_filled_1 ), ...
                       '.', 'MarkerEdgeColor', [ 27, 158, 119 ] / 255.0 );
    if not( isempty( RH_filled_2 ) )
        h_filled_2 = plot( doy( RH_filled_2 ), ...
                           nearby_2.rH( RH_filled_2 ), ...
                           '.', 'MarkerEdgeColor', [ 217, 95, 2 ] / 255.0 );
    else
        h_filled_2 = 0;
    end
    ylabel( 'RH (%)' );
    xlabel( 'day of year' );
    legend( [ h_obs, h_filled_1, h_filled_2 ], ...
            'observed', 'filled 1', 'filled 2' );

    h_T_fig = figure();
    h_obs = plot( doy, this_data.Tair, '.k' );
    hold on;
    h_filled_1 = plot( doy( T_filled_1 ), ...
                       nearby_data.Tair( T_filled_1 ), ...
                       '.', 'MarkerEdgeColor', [ 27, 158, 119 ] / 255.0 );
    if not( isempty( T_filled_2 ) )
        h_filled_2 = plot( doy( T_filled_2 ), ...
                           nearby_2.Tair( T_filled_2 ), ...
                           '.', 'MarkerEdgeColor', [ 217, 95, 2 ] / 255.0 );
    else
        h_filled_2 = 0;
    end
    ylabel( 'Tair (C)' );
    xlabel( 'day of year' );
    legend( [ h_obs, h_filled_1, h_filled_2 ], ...
            'observed', 'filled 1', 'filled 2' );

end

% replace NaNs with -999
temp = double( this_data );
temp( isnan( temp ) ) = -999.0;
this_data = replacedata( this_data, temp );

% write filled data to file
outfile = fullfile( get_out_directory( sitecode ), ...
                    sprintf( '%s_flux_all_%d_for_gap_filling_filled.txt', ...
                             get_site_name( sitecode ), year ) );
fprintf( 'writing %s\n', outfile );
export( this_data, 'file', outfile );

result = 0;

%===========================================================================

function ds = prepare_valles_met_data( ds, year, station )
% helper function to trim and sychronize timestamps for Valles data
    time_ds = ds( ds.sta == station, { 'year', 'day', 'time' } );
    ts = datenum( time_ds.year, 1, 1 ) + ...
         ( time_ds.day - 1 ) + ...
         ( time_ds.time / 24.0 );
    ds = ds( ds.sta == station, { 'airt', 'rh' } );
    ds.rh = ds.rh / 100.0;  %rescale from [ 0, 100 ] to [ 0, 1 ]
    ds.timestamp = ts;
    
    % these readings are hourly -- interpolate to 30 mins
    thirty_mins = 30 / ( 60 * 24 );  % thirty minutes in units of days
    ts_30 = ts + thirty_mins;
    rh_interp = interp1( ts, ds.rh, ts_30 );
    T_interp = interp1( ts, ds.airt, ts_30 );
    
    ds = vertcat( ds, dataset( { [ ts_30, rh_interp, T_interp ], ...
                               'timestamp', 'rh', 'airt' } ) );

    % filter out nonsensical values
    ds.airt( abs( ds.airt ) > 100 ) = NaN;
    ds.rh( ds.rh > 1.0 ) = NaN;
    ds.rh( ds.rh < 0.0 ) = NaN;
    
    % make the field names match the "for gapfilling" data
    ds.Properties.VarNames{ strcmp( ds.Properties.VarNames, 'rh' ) } = 'rH';
    ds.Properties.VarNames{ strcmp( ds.Properties.VarNames, 'airt' ) } = 'Tair';
    
    % sort by timestamp
    [ discard, idx ] = sort( ds.timestamp );
    ds = ds( idx, : );
    
%===========================================================================

function ds = prepare_sev_met_data( ds, year, station )
% helper function to trim and sychronize timestamps for Valles data
    ds = ds( ds.Station_ID == station, : );
    time_ds = ds( :, { 'Year', 'Jul_Day', 'Hour' } );
    ts = datenum( time_ds.Year, 1, 1 ) + ...
         ( time_ds.Jul_Day - 1 ) + ...
         ( time_ds.Hour / 24.0 );
    ds = ds( :, { 'Temp_C', 'RH' } );
    ds.Properties.VarNames = { 'Tair', 'rH' };
    ds.rH = ds.rH / 100.0;  %rescale from [ 0, 100 ] to [ 0, 1 ]
    ds.timestamp = ts;
    
    % these readings are hourly -- interpolate to 30 mins
    thirty_mins = 30 / ( 60 * 24 );  % thirty minutes in units of days
    ts_30 = ts + thirty_mins;
    rh_interp = interp1( ts, ds.rH, ts_30 );
    T_interp = interp1( ts, ds.Tair, ts_30 );
    
    ds = vertcat( ds, dataset( { [ ts_30, rh_interp, T_interp ], ...
                               'timestamp', 'rH', 'Tair' } ) );

    % filter out nonsensical values
    ds.Tair( abs( ds.Tair ) > 100 ) = NaN;
    ds.rH( ds.rH > 1.0 ) = NaN;
    ds.rH( ds.rH < 0 ) = NaN;
    
    % sort by timestamp
    [ discard, idx ] = sort( ds.timestamp );
    ds = ds( idx, : );