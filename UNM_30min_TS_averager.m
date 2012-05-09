function [ ds_out ] = UNM_30min_TS_averager( sitecode, timestamp, ...
                                             lag, rotation, data )
    % calculates average values for a 30-minute chunk of 10-hz timeseries
    % data.  Mostly calls other functions to do the number crunching.
    % modified by Krista Anderson-Teixeira 1/08
    % substantially rewritten by Timothy W. Hilton, Jan 2012
    %
    % (c) Timothy W. Hilton, UNM, Jan 2012

    Nfields = size( data, 2 );

    time1 = data.SECONDS;
    uin = data.Ux;
    vin = data.Uy;
    win = data.Uz;
    Tin = data.Ts;
    Pin = data.press;
    co2in = data.co2;
    h2oin = data.h2o;
    diagsonin = data.diag_csat;
    
    n_obs = size( data , 1 );

    [ year_ts, month_ts, day_ts, ...
      hour_ts, min_ts, second_ts ] = datevec( timestamp );
    uvwt = [ uin, vin, win, Tin ];

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % CALL UNM_dry_air_conversions  
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    [CO2,H2O,PWATER,TD,RHO,IRGADIAG,IRGAP,P,removedco2] = ...
        UNM_dry_air_conversions(co2in,h2oin,Pin,Tin,n_obs,sitecode);
    removed = removedco2;

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Call UNM_csat3 for despiking sonic variables, calculating mean winds,
    % and calculating theta.
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    %uvwt is transposed here because fluxcat3freemanKA was written for data in
    %rows....
    [ uvwt2, SONDIAG, theta, uvwtmean, speed ] = ...
        UNM_csat3( uvwt', diagsonin', sitecode); 
    
    % uvwt2 is despiked wind and temperature matrix
    % SONDIAG is sonic diagnostic variable combining both original diagson and
    % despike (1 for good, 0 for bad)
    
    % pare down to just winds
    uvw2 = uvwt2(1:3,:); 
    % pare means down to just winds
    uvwmean = uvwtmean(1:3); 
    %meteorological mean wind angle - it is the compass angle in degrees
    %that the wind is blowing FROM (0 = North, 90 = east, etc)
    temp2 = uvwt2(4,:);

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Split path for 3d versus planar rotation
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    if rotation == sonic_rotation.threeD; 

        % ROTATE COORDINATES SUCH THAT MEAN U, V, & W = 0
        [ UVWROT, uvwmeanrot ] = UNM_coordrot( uvw2, SONDIAG ); 

        %in this case, UVW2 !! is !! rotated                      
        % ROW 1: sonic component rotated into the mean wind direction
        % ROW 2: sonic cross-wind component
        % ROW 3: sonic w component
        UVW2 = UVWROT; 

    elseif rotation == sonic_rotation.planar

        %in this case, UVW2 !! is not !! rotated
        UVW2 = uvw2; 
        uvwmeanrot = NaN * ones( 3, 1 );
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % CALL UNM_flux
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    if lag == 0
        [ CO2, H2O, FCO2, FH2O, HSENSIBLE, HLATENT, RHOM, TDRY, ...
          IOKNUM, zoL, UVWTVAR, COVUVWT, HBUOYANT, USTAR, TRANSPORT, ...
          uvector, wmean ] = UNM_flux_031010( year_ts,  month_ts, ...
                                                  day_ts,  UVW2,  uvwmean', ...
                                                  SONDIAG,  CO2',  H2O', ...
                                                  TD',  RHO',  IRGADIAG', ...
                                                  rotation, ...
                                                  get_site_name( sitecode ), ...
                                                  sitecode,  n_obs,  PWATER, ...
                                                  uvwmeanrot, ...
                                                  IRGAP,  speed, ...
                                                  temp2, theta );
        
    elseif lag == 1
        %% I think this will fail -- USTAR cannot be defined...  TWH Feb 2012
        [CO2, H2O, FCO2, FH2O, HSENSIBLE, HLATENT, RHOM, TDRY, ...
         IOKNUM, lagCO2,  lagH2O, zoL] = flux7500freeman_lag(UVW2, uvwmean, ...
                                                          USTAR, SONDIAG, ...
                                                          CO2', H2O', TD', ...
                                                          RHO', IRGADIAG', ...
                                                          rotation, sitecode, ...
                                                          n_obs,  PWATER, ...
                                                          uvwmeanrot, ...
                                                          hsout, IRGAP, ...
                                                          theta );
    end

    %------
    % create variables for output
    
    % UVW2      = NaN*ones(3,size(uvwt,2));
    % UVWTVAR   = NaN*ones(4,1);
    % COVUVWT   = NaN*ones(6,1);
    % USTAR     = NaN;
    % HBUOYANT  = NaN;
    % TRANSPORT = NaN;
    % hsout = NaN;
    
    % done creating output variables
    %-----
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Hold out periods of known calibration for Texas site
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    if ( sitecode == 7 )
        if any( TX_site_known_calibrations( timestamp ) )
            julday = jday;
            numdate = date;
            %assign NaN's for missing data:
            uvwtmean( : ) = NaN; 
            uvwmeanrot( : ) = NaN;
            theta = NaN;
            uvwtvar( : ) = NaN;
            covuvwt( : ) = NaN;
            ustar = NaN;
            speed = NaN;
            HBUOYANT = NaN;
            TRANSPORT( i, 1 ) = NaN;
            CO2( : ) = NaN;
            H2O( : ) = NaN;
            FCO2( : ) = NaN;
            FH2O( : ) = NaN;
            HSENSIBLE( : ) = NaN;
            HLATENT( : ) = NaN;
            RHOM( : ) = NaN;
            TDRY =   NaN;
            IOKNUM( : ) = NaN;
            removed( : )  =  NaN;
            zoL = NaN;
        end    
    end

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % create matlab dataset of output variables
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    names = { 'year', 'month', 'day', ...
              'hour', 'min', 'second' };
    y_units = repmat( { '-' }, 1, 6 );
    y = dataset( { datevec( timestamp ), names{:} } );

    y.date = datestr( timestamp, 'YYYYMMDD' );
    y.jday = timestamp - datenum( y.year, 1, 1 ) + 1;
    y.iok = IOKNUM;
    y_units = [ y_units, { '-', '-', '-' } ];

    names = { 'u_mean', 'v_mean', 'w_mean', 'temp_mean' };
    y_units = [ y_units, { 'm/s', 'm/s', 'm/s', 'C' } ];
    y = [ y, dataset( { uvwtmean', names{:}  } ) ];

    y.tdry = TDRY;
    y.wind_direction = theta;
    y.speed = speed;
    y.rH = NaN;  % we are using the RH from the 30-min data now
    y_units = [ y_units, { 'K', 'degrees', 'm/s', '%' } ];

    names = { 'along_wind_velocity_variance', ...
              'cross_wind_velocity_variance', ...
              'vertical_wind_velocity_variance',...
              'sonic_temperature_variance' } ;
    y_units = [ y_units, repmat( { '-' }, size( names ) ) ];
    y = [ y, dataset( { UVWTVAR', names{ : } } ) ];

    names = { 'uw_covariance', ...
              'vw_covariance', ...
              'uv_covariance', ...
              'ut_covariance', ...
              'vt_covariance', ...
              'wt_covariance' };
    y_units = [ y_units, repmat( { '-' }, 1, 6 ) ];
    y = [y, dataset( { COVUVWT', names{ : } } ) ];

    y.ustar = USTAR;
    y_units = [ y_units, { 'm/s' } ];

    names = { 'CO2_min', 'CO2_max','CO2_median', ...
              'CO2_mean','CO2_std' };
    y_units = [ y_units, repmat( { 'umol/mol dry air' }, 1, 5 ) ];
    y = [ y, dataset( { CO2', names{ : } } ) ];

    names = { 'H2O_min','H2O_max','H2O_median', ...
              'H2O_mean','H2O_std' };
    y_units = [ y_units, repmat( { 'umol/mol dry air' }, 1, 5 ) ];
    y = [ y, dataset( { H2O', names{ : } } ) ];

    names = { 'Fc_raw','Fc_raw_massman','Fc_water_term', ...
              'Fc_heat_term_massman','Fc_raw_massman_ourwpl' };
    y_units = [ y_units, repmat( { 'umol/m2/s' }, 1, 5 ) ];
    y = [ y, dataset( { FCO2', names{ : } } ) ];

    names = { 'E_raw','E_raw_massman','E_water_term', ...
              'E_heat_term_massman','E_wpl_massman', ...
              'E_rhov_massman' };
    y_units = [ y_units, repmat( { '-' }, 1, 6 ) ];
    y = [ y, dataset( { FH2O', names{ : } } ) ];

    names = { 'SensibleHeat_dry','SensibleHeat_wet', ...
              'SensibleHeat_wetwet','HSdry_massman' };
    y_units = [ y_units, repmat( { 'W/m2' }, 1, 4 ) ];
    y = [ y, dataset( { HSENSIBLE', names{ : } } ) ];

    names = { 'LatentHeat_raw', ...
              'LatentHeat_raw_massman', ...
              'LatentHeat_wpl_massman' };
    y_units = [ y_units, repmat( { 'W/m2' }, 1, 3 ) ];
    y = [ y, dataset( { HLATENT', names{ : } } ) ];

    names = { 'rhoa_dry_air_molar_density', ...
              'rhov_dry_air_molar_density', ...
              'rhoc_dry_air_molar_density' };
    y_units = [ y_units, repmat( { 'g/m3 moist air' }, 1, 3 ) ];
    y = [ y, dataset( { RHOM', names{ : } } ) ];

    y.buoyancy_flux = HBUOYANT;
    y.transport = TRANSPORT;

    names = { 'NaNs','Maxs','Mins','Spikes','Bad_variance' };
    y = [ y, dataset( { removed, names{ : } } ) ];

    y.zoL = zoL;

    names = { 'u_vector_u','u_vector_v','u_vector_w' };
    y = [ y, ...
          dataset( { uvector', names{ : } } ) ];

    y.w_mean = wmean;
    y_units = [ y_units, repmat( { '-' }, 1, 11 ) ];

    y.Properties.Units = y_units;

    ds_out = y;
