function result = UNM_fill_met_gaps_from_nearby_site( sitecode, year, ...
                                                      draw_plots, ...
                                                      linfit_Rg )
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
filled_file_false = false;

%--------------------------------------------------
% parse unfilled data from requested site
    
fprintf( 'parsing %s_flux_all_%d_for_gapfilling.txt ("destination")\n', ...
         get_site_name( sitecode ), year );
this_data = parse_forgapfilling_file( sitecode, year, filled_file_false );

%--------------------------------------------------
% parse data with which to fill T & RH
                
switch sitecode    
  case 1    % fill GLand from SLand, then Sev Deep Well station (# 40)
    fprintf( 'parsing %s_flux_all_%d_for_gapfilling.txt ("source")\n', ...
             get_site_name( 2 ), year );  %
    nearby_data = parse_forgapfilling_file( 2, year, filled_file_false );
    nearby_2 = UNM_parse_sev_met_data( year );
    nearby_2 = prepare_sev_met_data( nearby_2, year, 40 );
  case 2    % fill SLand from GLand, then Sev Five Points station (# 49 )
    fprintf( 'parsing %s_flux_all_%d_for_gapfilling.txt ("source")\n', ...
             get_site_name( 1 ), year );
    nearby_data = parse_forgapfilling_file( 1, year, filled_file_false );
    nearby_2 = UNM_parse_sev_met_data( year );
    nearby_2 = prepare_sev_met_data( nearby_2, year, 49 );
  case 4     % fill PJ from PJ girdle    
    fprintf( 'parsing %s_flux_all_%d_for_gapfilling.txt ("source")\n', ...
             get_site_name( 10 ), year );
    nearby_data = parse_forgapfilling_file( 10, year, filled_file_false );
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
    nearby_data = parse_forgapfilling_file( 4, year, filled_file_false );
  case 11    % fill New_GLand from GLand
    fprintf( 'parsing %s_flux_all_%d_for_gapfilling.txt ("source")\n', ...
             get_site_name( 1 ), year );
    nearby_data = parse_forgapfilling_file( 1, year, filled_file_false );
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
save( './mcon.mat' )
if not( isempty( nearby_2 ) )
    nearby_2 = dataset_fill_timestamps( nearby_2, 'timestamp', ...
                                        thirty_mins, ...
                                        min( ts ), ...
                                        max( ts ) );
end

%--------------------------------------------------
% fill T, RH

% replace missing Tair with nearby site
[ this_data, T_filled_1, T_filled_2 ] = ...
    fill_variable( this_data, nearby_data, nearby_2, ...
                   'Tair', 'Tair', 'Tair', false );

% replace missing rH with nearby site
[ this_data, RH_filled_1, RH_filled_2 ] = ...
    fill_variable( this_data, nearby_data, nearby_2, ...
                   'rH', 'rH', 'rH', false );

% replace missing Rg with nearby site
[ this_data, Rg_filled_1, Rg_filled_2 ] = ...
    fill_variable( this_data, nearby_data, nearby_2, ...
                   'Rg', 'Rg', 'Rg', linfit_Rg );

%--------------------------------------------------
% plot filled variables if requested

if draw_plots
    h_fig_T = plot_filled_variable( this_data, nearby_data, nearby_2, ...
                                    'Tair', T_filled_1, T_filled_2, ...
                                    sitecode, year );
    h_fig_RH = plot_filled_variable( this_data, nearby_data, nearby_2, ...
                                     'rH', RH_filled_1, RH_filled_2, ...
                                     sitecode, year );
    h_fig_Rg = plot_filled_variable( this_data, nearby_data, nearby_2, ...
                                     'Rg', Rg_filled_1, Rg_filled_2, ...
                                     sitecode, year );
end

% replace NaNs with -999
foo = double( this_data );
foo( isnan( foo ) ) = -9999;
this_data = replacedata( this_data, foo );

% write filled data to file except for matlab datenum timestamp column
outfile = fullfile( get_site_directory( sitecode ), ...
                    'processed_flux', ...
                    sprintf( '%s_flux_all_%d_for_gap_filling_filled.txt', ...
                             get_site_name( sitecode ), year ) );
fprintf( 'writing %s\n', outfile );
n_col = size( this_data, 2 );
export( this_data( :, 1:n_col - 1 ), 'file', outfile );

result = 0;

%===========================================================================
    
function [ ds_dest, idx1, idx2 ] = fill_variable( ds_dest, ...
                                                  ds_source1, ds_source2, ...
                                                  var_dest, ...
                                                  var_source1, ...
                                                  var_source2, ... 
                                                  linfit_source1 )
    % replace missing values in on variable of dataset ds_dest with
    % corresponding values from dataset ds_source1.  Where ds_source1 also
    % has missing values, fall back to ds_source2 if provided.
    
    % replace missing values with nearby site
    n_missing = numel( find( isnan( ds_dest.( var_dest ) ) ) );
    idx1 = find( isnan( ds_dest.( var_dest ) ) & ...
                 ~isnan( ds_source1.( var_source1 ) ) );

    if linfit_source1
        replacement = linfit_var( ds_source1.( var_source1 ), ...
                                  ds_dest.( var_dest ), ...
                                  idx1 );
    else
        replacement = ds_source1.( var_source1 );        
    end

    ds_dest.( var_dest )( idx1 ) = replacement( idx1 );
    % if there is a secondary site, fill remaining missing values 
    idx2 = [];  %initialize to empty in case no second site provided
    if not( isempty( ds_source2 ) )
        idx2 = find( isnan( ds_dest.( var_dest ) ) & ...
                     isnan( ds_source1.( var_source1 ) ) & ...
                     ~isnan( ds_source2.( var_source2 ) ) );
        ds_dest.( var_dest )( idx2 ) = ds_source2.( var_source2 )( idx2 );
    end
    n_filled = numel( idx1 ) + numel( idx2 );
    fprintf( '%s: replaced %d / %d missing observations\n', ...
             var_dest, n_filled, n_missing );

%===========================================================================
    
function h_fig = plot_filled_variable( ds, ds_source1, ds_source2, ...
                                       var, filled_idx1, filled_idx2, ...
                                       sitecode, year )
    
    seconds = repmat( 0.0, size( ds, 1 ), 1 );
    ts = datenum( ds.year, ds.month, ds.day, ...
                  ds.hour, ds.minute, seconds );
    nobs = size( ds, 1 );
    jan1 = datenum( ds.year, repmat( 1, nobs, 1 ), repmat( 1, nobs, 1 ) );
    doy = ts - jan1 + 1;
    
    h_fig = figure();
    h_obs = plot( doy, ds.( var ), '.k' );
    hold on;
    h_filled_1 = plot( doy( filled_idx1 ), ...
                       ds.( var )( filled_idx1 ), ...
                       '.', 'MarkerEdgeColor', [ 27, 158, 119 ] / 255.0 );
    if not( isempty( filled_idx2 ) )
        h_filled_2 = plot( doy( filled_idx2 ), ...
                           ds.( var )( filled_idx2 ), ...
                           '.', 'MarkerEdgeColor', [ 217, 95, 2 ] / 255.0 );
    else
        h_filled_2 = 0;
    end
    ylabel( var );
    xlabel( 'day of year' );
    title( sprintf( '%s %d', get_site_name( sitecode ), year ) );
    legend( [ h_obs, h_filled_1, h_filled_2 ], ...
            'observed', 'filled 1', 'filled 2' );
    
%===========================================================================

function ds = prepare_valles_met_data( ds, year, station )
% helper function to trim and sychronize timestamps for Valles data
    time_ds = ds( ds.sta == station, { 'year', 'day', 'time' } );
    ts = datenum( time_ds.year, 1, 1 ) + ...
         ( time_ds.day - 1 ) + ...
         ( time_ds.time / 24.0 );
    ds = ds( ds.sta == station, { 'airt', 'rh', 'sol' } );
    ds.rh = ds.rh / 100.0;  %rescale from [ 0, 100 ] to [ 0, 1 ]
    ds.timestamp = ts;
    
    % these readings are hourly -- interpolate to 30 mins
    thirty_mins = 30 / ( 60 * 24 );  % thirty minutes in units of days
    ts_30 = ts + thirty_mins;
    rh_interp = interp1( ts, ds.rh, ts_30 );
    T_interp = interp1( ts, ds.airt, ts_30 );
    Rg_interp = interp1( ts, ds.sol, ts_30 );
    
    ds = vertcat( ds, dataset( { [ ts_30, rh_interp, T_interp, Rg_interp ], ...
                               'timestamp', 'rh', 'airt', 'sol' } ) );

    % filter out nonsensical values
    ds.airt( abs( ds.airt ) > 100 ) = NaN;
    ds.rh( ds.rh > 1.0 ) = NaN;
    ds.rh( ds.rh < 0.0 ) = NaN;
    ds.sol( ds.sol < -20.0 ) = NaN;

    % make the field names match the "for gapfilling" data
    ds.Properties.VarNames{ strcmp( ds.Properties.VarNames, 'rh' ) } = 'rH';
    ds.Properties.VarNames{ strcmp( ds.Properties.VarNames, 'airt' ) } = 'Tair';
    ds.Properties.VarNames{ strcmp( ds.Properties.VarNames, 'sol' ) } = 'Rg';
    
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
    ds = ds( :, { 'Temp_C', 'RH', 'Solar_Rad' } );
    ds.Properties.VarNames = { 'Tair', 'rH', 'Rg' };
    ds.rH = ds.rH / 100.0;  %rescale from [ 0, 100 ] to [ 0, 1 ]
    ds.timestamp = ts;
    
    % these readings are hourly -- interpolate to 30 mins
    thirty_mins = 30 / ( 60 * 24 );  % thirty minutes in units of days
    ts_30 = ts + thirty_mins;
    rh_interp = interp1( ts, ds.rH, ts_30 );
    T_interp = interp1( ts, ds.Tair, ts_30 );
    Rg_interp = interp1( ts, ds.Rg, ts_30 );
    
    ds = vertcat( ds, dataset( { [ ts_30, rh_interp, T_interp, Rg_interp ], ...
                               'timestamp', 'rH', 'Tair', 'Rg' } ) );

    % filter out nonsensical values
    ds.Tair( abs( ds.Tair ) > 100 ) = NaN;
    ds.rH( ds.rH > 1.0 ) = NaN;
    ds.rH( ds.rH < 0 ) = NaN;
    
    % sort by timestamp
    [ discard, idx ] = sort( ds.timestamp );
    ds = ds( idx, : );

%===========================================================================

function result = linfit_var( x, y, idx )
    
% find timestamps without NaN in either variable
    nan_idx = any( isnan( [ x, y ] ), 2 );

    x_valid = x( ~nan_idx );
    y_valid = y( ~nan_idx );
    
    % linear regression of var2 against var1
    slope = fminsearch( @(m) sse_linfit_slope_only( x_valid, y_valid, m ), ...
                        1.10 );

    result = x;
    result( idx ) = x( idx ) * slope;

function sse = sse_linfit_slope_only( x, y, m )
    sse = sum( ( y - ( m * x ) ) .^ 2 );

function result = linfit_var2( x, y, idx )

% find timestamps without NaN in either variable
    nan_idx = any( isnan( [ x, y ] ), 2 );

    % linear regression of var2 against var1
    linfit = polyfit( x( ~nan_idx ), y( ~nan_idx ), 1 );

    % return prediction of var2 at idx based on regression
    result = x;
    result( idx ) = ( x( idx ) * linfit( 1 ) ) + linfit( 2 );
    
