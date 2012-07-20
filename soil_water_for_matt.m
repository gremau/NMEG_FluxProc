function fluxes_with_SWC = soil_water_for_matt( sitecode, year )
% SOIL_WATER_FOR_MATT - create dataset of soil water contents and fluxes
% USAGE
%    fluxes_with_SWC = soil_water_for_matt( sitecode, year )
%
% (c) Timothy W. Hilton, UNM, July 2012

%get the soil water data

switch sitecode
  case { UNM_sites.GLand, UNM_sites.SLand, UNM_sites.JSav, ...
         UNM_sites.New_GLand }
    fname = fullfile( getenv( 'UNMDATA' ), ...
                      'BinaryData', ...
                      sprintf( '%s_%d_fluxall.mat', char( sitecode ), year ) );
    load( fname );
    
    this_data = UNM_assign_soil_data_labels( sitecode, year, this_data );
    fprintf( '%s %d -- SWC vars: %d\n', ...
             char( sitecode ), ...
             year, ...
             numel( regexp_ds_vars( this_data, 'cs616' ) ) );
    
    SWC_vars = regexp_ds_vars( this_data, 'cs616' );
    SWC = this_data( :, SWC_vars );

    % convert from CS616 period to volumetric water content
    % non-temperature corrected: apply quadratic form of calibration equation
    % (section 6.3, p. 29, CS616 manual)
    vwc = @( raw_swc ) repmat( -0.0663, ( size( raw_swc ) ) ) - ...
          ( 0.0063 .* raw_swc ) + ...
          ( 0.0007 .* ( raw_swc .* raw_swc ) );
    % apply calibration to raw CS616 measurements
    is_CS616 = double( SWC ) > 15.5;  
    calibrated_swc = double( SWC );
    calibrated_swc( is_CS616 ) = vwc( calibrated_swc( is_CS616 ) );
    SWC = replacedata( SWC, calibrated_swc );
    
    timestamp = this_data.timestamp;
    
  case { UNM_sites.PJ, UNM_sites.PJ_girdle }
    
    [ T, SWC ] = preprocess_PJ_soil_data( sitecode, year );
    timestamp = SWC.tstamps;
    SWC.tstamps = [];
end
    
[ SWC_hilo_removed, ...
  SWC_hilo_replaced, ...
  SWC_runmean ] = UNM_soil_data_smoother( SWC );

SWC = SWC_runmean;
SWC_dbl = double( SWC );
SWC_dbl( SWC_dbl < 0 ) = NaN;
SWC_dbl( SWC_dbl > 1 ) = NaN;
SWC = replacedata( SWC, SWC_dbl );
SWC.timestamp = timestamp;

aflx_data = assemble_multi_year_ameriflux( sitecode, year:year, ...
                                           'binary_data', true );

% combine fluxes and SWC into dataset and write ASCII file
fluxes = aflx_data( :, { 'timestamp', 'FC', 'GPP', 'RE', 'LE', 'H' } );
fluxes.Properties.VarNames = strrep( fluxes.Properties.VarNames, 'FC', 'NEE' );

secs_per_day = 60 * 60 * 24;
two_minutes = 120 / secs_per_day;

fprintf( 'sychronizing flux, SWC timestamps\n' )
t0 = now();
[ fluxes, SWC ] = merge_datasets_by_datenum( fluxes, SWC, ...
                                             'timestamp', 'timestamp', ...
                                             two_minutes, ...
                                             datenum( year, 1, 1 ), ...
                                             datenum( year, 12, 31, ...
                                                  23, 30, 00 ) );
t_run = now() - t0;

SWC.timestamp = [];
fluxes_with_SWC = [ fluxes, SWC ];
