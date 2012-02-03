%1-reads in raw ts data, separates into half-hour periods
%2-sends to other programs for processing/ averaging into half-hour values. 
%3-outputs half-hour values with timestamps corresponding to the end of the
%half-hour period

%modified by Krista Anderson-Teixeira 1/08
 
function [ date, hr, fco2out, tdryout, hsout, hlout, iokout, y ] = ...
        UNM_data_processor( sitecode, filename, rotation, lag, writefluxall )

ds = read_TOB1_file( filename );
data = double( ds );
     
% assign variable names to columns of data:
if (Nfields==14) % TX_forest & TX_grassland
     time1=(data(:,1));
     uin=(data(:,7));
     vin=(data(:,8));
     win=(data(:,9));
     Tin=(data(:,10)+273.15);
     co2in=(data(:,11))/44;
     h2oin=(data(:,12))/.018;
     Pin=(data(:,13));
     diagcsat=(data(:,14));
     diagsonin = zeros(length(diagcsat),1);
elseif (Nfields==11); % JSAV, PPINE, TX_savanna ....
     time1=(data(:,1)); % seconds since 1990(?)
     time2=(data(:,2)); % nanoseconds
     uin=(data(:,3));
     vin=(data(:,4));
     win=(data(:,5));
     co2in=(data(:,6))/44;
     h2oin=(data(:,7));
     %h2oin(h2oin<0)=0.01*ones(size(find(h2oin<0)));
     h2oin=h2oin/.018;
     Tin=(data(:,8)+273.15);
     Pin=(data(:,9));
     diagsonin=(data(:,10));
elseif (Nfields==12 & (sitecode==1 | sitecode==2 | sitecode==10));  %GLand, SLand. %Sev sites have their columns mixed up. There is no irga diagnositc!  
     time1=(data(:,1)); % seconds since 
     time2=(data(:,2)); % nanoseconds 
     uin=(data(:,3));
     vin=(data(:,4));
     win=(data(:,5));
     co2in=(data(:,6))/44;
     h2oin=(data(:,7));
     %h2oin(h2oin<0)=0.01*ones(size(find(h2oin<0)));
     h2oin=h2oin/.018;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Correction for dodgy IRGA calibration, September 2009 - 17 March 2010
%      if sitecode==10
%         h2oin=(h2oin.*0.8881)-133.65;
%      end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

     Tin=(data(:,8)+273.15);
     Pin=(data(:,9));
     diagsonin=(data(:,10));
elseif (Nfields==12 & ~(sitecode==1 | sitecode==2));
     time1=(data(:,1));  %seconds since 
     time2=(data(:,2));   % nanoseconds
     rn=(data(:,3));
     uin=(data(:,4));
     vin=(data(:,5));
     win=(data(:,6));
     co2in=(data(:,7))/44;
     h2oin=(data(:,8));
     %h2oin(h2oin<0)=0.01*ones(size(find(h2oin<0)));
     h2oin=h2oin/.018;
     Tin=(data(:,9)+273.15);
     Pin=(data(:,10));
     diagsonin=(data(:,11));
elseif (Nfields==9);
     uin=(data(:,1));
     vin=(data(:,2));
     win=(data(:,3));
     co2in=(data(:,4))/44;
     h2oin=(data(:,5));
     %h2oin(h2oin<0)=0.01*ones(size(find(h2oin<0)));
     h2oin=h2oin/.018;
     Tin=(data(:,6)+273.15);
     Pin=(data(:,7));
     diagsonin=(data(:,8));
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Start for-loop for 48 half-hour periods  
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [ ds ] = process_thirty_minute_chunk( sitecode, timestamp, ...
                                               lag, rotation ...
                                               u, v, w, T, ...
                                               diagson, uvwt, co2, h2o, P )
    
    n_obs = numel( timestamp );

    [ year_ts, month_ts, day_ts, ...
      hour_ts, min_ts, second_ts ] = datevec( timestamp );

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% CALL UNM_dry_air_conversions  
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%        

        [CO2,H2O,PWATER,TD,RHO,IRGADIAG,IRGAP,P,removedco2] = ...
            UNM_dry_air_conversions(co2,h2o,P,T,n_obs,sitecode);
        removed(i,1:5) = removedco2;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Call UNM_csat3 for despiking sonic variables, calculating mean winds, and calculating theta.  
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        [uvwt2,SONDIAG,THETA,uvwtmean_,speed_]= UNM_csat3(uvwt',diagson',sitecode); %uvwt is transposed here because fluxcat3freemanKA was written for data in rows....
        
        % uvwt2 is despiked wind and temperature matrix
        % SONDIAG is sonic diagnostic variable combining both original diagson and despike (1 for good, 0 for bad)
        
        uvw2 = uvwt2(1:3,:); % pair down to just winds
        uvwtmean(i,1:4) = uvwtmean_; %mean values for (despiked) sonic measurements
        uvwmean = uvwtmean(i,1:3); % pair means down to just winds
        theta(i,1) = THETA;  %meteorological mean wind angle - it is the compass angle in degrees that the wind is blowing FROM (0 = North, 90 = east, etc)
        speed(i,1) = speed_;
        temp2 = uvwt2(4,:);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Split path for 3d versus planar rotation
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        if rotation == 0; % 3d rotation
            [UVWROT,uvwmeanrot_] = UNM_coordrot(uvw2,SONDIAG); % ROTATE COORDINATES SUCH THAT MEAN U, V, & W = 0
                      
            UVW2 = UVWROT; %in this case, UVW2 !! is !! rotated
            % ROW 1: sonic component rotated into the mean wind direction
            % ROW 2: sonic cross-wind component
            % ROW 3: sonic w component
            uvwmeanrot(i,1:3) = uvwmeanrot_; %mean values for despiked and 3D rotated sonic measurements 
            
        elseif rotation == 1 % planar rotation
            UVW2 = uvw2; %in this case, UVW2 !! is not !! rotated
            uvwmeanrot(i,1:3) = NaN*ones(3,1);
        end
        
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% CALL UNM_flux
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        if lag == 0
	  [CO2_,H2O_,FCO2_,FH2O_,HSENSIBLE_,HLATENT_,RHOM_,TDRY_,IOKNUM_,zoL, ...
	   UVWTVAR_,COVUVWT_,HBUOYANT_,USTAR_,TRANSPORT_, u_vector_,w_mean_,rH_] ...
	      = UNM_flux_031010(year_ts, month_ts, day_ts, UVW2, uvwmean, ...
				SONDIAG, CO2', H2O', TD', RHO', IRGADIAG', ...
				rotation, site, sitecode, num, PWATER, ...
				uvwmeanrot(i,:), IRGAP, speed(i), temp2, ...
				theta(i));
             
        elseif lag==1
	  [CO2_,H2O_,FCO2_,FH2O_,HSENSIBLE_,HLATENT_,RHOM_,TDRY_,IOKNUM_, ...
	   LAGCO2, LAGH2O,zoL] = flux7500freeman_lag(UVW2,uvwmean,USTAR_, ...
						     SONDIAG,CO2',H2O',TD', ...
						     RHO',IRGADIAG',rotation, ...
						     sitecode,num, PWATER, ...
						     uvwmeanrot(i,1:3),hsout, ...
						     IRGAP,theta(i));
	  lagCO2(i,1:7)=LAGCO2;
	  lagH2O(i,1:5)=LAGH2O;
        end

        co2out(i,1:5) = CO2_; %CO2  (umol/mol dry air). 1- min, 2-max, 3-median, 4-mean, 5-std
        h2oout(i,1:5) = H2O_; %H20 (mmol/mol dry air)  1- min, 2-max, 3-median, 4-mean, 5-std
        fco2out(i,1:5) = FCO2_; %CO2 flux [Fc_corr;Fc_raw;Fc_heat_term;Fc_water_term;Fc_raw_massman;Fc_heat_term_massman;Fc_corr_massman_ourwpl]
        fh2oout(i,1:6) = FH2O_; %H20 flux [E_corr;Euncorr;E_heat_term;E_water_term;Euncorr_massman;E_heat_term_massman;E_corr_massman]
        hsout_flux(i,1:4) = HSENSIBLE_; %sensible heat (W m-2) [HSdry; HSwet; HSwetwet; HSdry_massman]
        hlout(i,1:3) = HLATENT_; %latent heat (W m-2) [HLuncorr; HLuncorr_massman; HLcorr_massman]
        rhomout(i,1:3) = RHOM_; %dry air molar density (moles/m^3 moist air)
        tdryout(i,1) = TDRY_;
        iokout(i,1:2) = IOKNUM_;
        zoLout(i,1) = zoL;
        uvwtvar(i,1:4) = UVWTVAR_;   %variances of ROTATED wind components and the sonic temperature
        covuvwt(i,1:6) = COVUVWT_;   %covariances of ROTATED wind components and the sonic temperature        
        hbuoyantout(i,1) = HBUOYANT_;  %bouyancy flux (W m-2)
        ustar(i,1) = USTAR_;  % NX1 friction velocity (m/s)
        transportout(i,1) = TRANSPORT_;  %turblent transport
        u_vector(i,1:3) = u_vector_;
        w_mean(i,1) = w_mean_; %this is rotated from planar fit
        rH(i,1) = rH_;

        julday(i,1) = jday;
        numdate(i,1) = date;
            
        UVW2      = NaN*ones(3,size(uvwt,2));
        UVWTVAR   = NaN*ones(4,1);
        COVUVWT   = NaN*ones(6,1);
        USTAR     = NaN;
        HBUOYANT  = NaN;
        TRANSPORT = NaN;
        hsout = NaN;
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Hold out periods of known calibration for Texas site
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%   

        if sitecode == 7 & numdate == 30107 & (decimal_day >= 60.4375 & decimal_day < 60.7083) %3/1/2007 10:30 to 17:00
            outputs = 0;
        elseif sitecode == 7 & numdate == 72307 & (decimal_day >= 204.5208 & decimal_day < 204.6458) %7/23/2007 12:30 to 15:30
            outputs = 0;
        elseif sitecode == 7 & numdate == 92707 & (decimal_day >= 270.4583 & decimal_day < 270.5208) %9/27/2007 11:00 to 12:30
            outputs = 0;
        elseif sitecode == 7 & numdate == 100207 & (decimal_day >= 275.4166 & decimal_day < 275.5833) %10/2/2007 10:00 to 14:00
            outputs = 0;
        elseif sitecode == 7 & numdate == 101607 & (decimal_day >= 289.4375 & decimal_day < 289.5625) %10/16/2007 10:30 to 13:30
            outputs = 0;
        elseif sitecode == 7 & numdate == 51607 & (decimal_day >= 136.5833 & decimal_day < 136.7083) %5/16/2007 14:00 to 17:00
            outputs = 0;
        elseif sitecode == 7 & numdate == 80707 & (decimal_day >= 219.4791 & decimal_day < 219.7291) %8/7/2007 11:30 to 17:30
            outputs = 0;
        elseif sitecode == 7 & numdate == 82007 & (decimal_day >= 232.4583 & decimal_day < 232.5416) %8/20/2007 11:00 to 13:00
            outputs = 0;
        elseif sitecode == 7 & numdate == 82107 & (decimal_day >= 233.4375 & decimal_day < 233.4791) %8/21/2007 10:30 to 11:30
            outputs = 0;
        elseif sitecode == 7 & numdate == 40907 & (decimal_day >= 99.6458 & decimal_day < 100) %4/9/2007 15:30 to 24:00
            outputs = 0;
        elseif sitecode == 7 & numdate == 41007 & (decimal_day >= 100 & decimal_day < 100.6041) %4/10/2007 0:00 to 14:30
            outputs = 0;
        elseif sitecode == 7 & numdate == 12406 & (decimal_day >= 24.4583 & decimal_day < 24.5416) %1/24/2006 11:00 to 13:00
            outputs = 0;
        elseif sitecode == 7 & numdate == 21206 & (decimal_day >= 43.3541 & decimal_day < 43.4375) %2/12/2006 8:30 to 10:30
            outputs = 0;
        elseif sitecode == 7 & numdate == 41006 & (decimal_day >= 100.4375 & decimal_day < 100.7291) %4/10/2006 10:30 to 17:30
            outputs = 0;
        elseif sitecode == 7 & numdate == 52206 & (decimal_day >= 142.5833 & decimal_day < 142.6458) %5/22/2006 14:00 to 15:30
            outputs = 0;
        elseif sitecode == 7 & numdate == 63006 & (decimal_day >= 181.5208 & decimal_day < 181.6041) %6/30/2006 12:30 to 14:30
            outputs = 0;
        elseif sitecode == 7 & numdate == 82406 & (decimal_day >= 236.2916 & decimal_day < 236.8541) %8/24/2006 7:00 to 20:30
            outputs = 0;
        elseif sitecode == 7 & numdate == 92906 & (decimal_day >= 272.4166 & decimal_day < 272.5) %9/29/2006 10:00 to 12:00
            outputs = 0;
        elseif sitecode == 7 & numdate == 10306 & (decimal_day >= 276.3958 & decimal_day < 276.4375) %10/3/2006 9:30 to 10:30
            outputs = 0;
        elseif sitecode == 7 & numdate == 103106 & (decimal_day >= 304.4375 & decimal_day < 304.5833) %10/31/2006 10:30 to 14:00
            outputs = 0;
        elseif sitecode == 7 & numdate == 11205 & (decimal_day >= 12.6041 & decimal_day < 12.6666) %1/12/2005 14:30 to 16:00
            outputs = 0;
        elseif sitecode == 7 & numdate == 41305 & (decimal_day >= 103.375) %4/13/2005 9:00 to 24:00
            outputs = 0;
        elseif sitecode == 7 & numdate == 41405 %4/14/2005 all day
            outputs = 0;
        elseif sitecode == 7 & numdate == 41505 & (decimal_day < 105.6666) %4/15/2005 0:00 to 16:00
            outputs = 0;
        elseif sitecode == 7 & numdate == 51905 & (decimal_day >= 139.6041 & decimal_day < 139.6666) %5/19/2005 14:30 to 16:00
            outputs = 0;
        elseif sitecode == 7 & numdate == 61805 & (decimal_day >= 169.4583 & decimal_day < 169.5833) %6/18/2005 11:00 to 14:00
            outputs = 0;
        elseif sitecode == 7 & numdate == 81605 & (decimal_day >= 228.5208 & decimal_day < 228.5833) %8/16/2005 12:30 to 14:00
            outputs = 0;
        elseif sitecode == 7 & numdate == 91205 & (decimal_day >= 255.4375 & decimal_day < 255.5208) %9/12/2005 10:30 to 12:30
            outputs = 0;
        elseif sitecode == 7 & numdate == 92305 & (decimal_day >= 266.5625 & decimal_day < 266.6041) %9/23/2005 13:30 to 14:30
            outputs = 0;
        else
            outputs = 1;
        end

        if outputs == 0
            julday(i,1)=jday;
            numdate(i,1)=date;
            %assign NaN's for missing data:
            uvwtmean(i,1:4)=NaN;
            uvwmeanrot(i,1:3)=NaN;
            theta(i,1)=NaN;
            uvwtvar(i,1:4)=NaN;
            covuvwt(i,1:6)=NaN;
            ustar(i,1)=NaN;
            speed(i,1)=NaN;
            hbuoyantout(i,1)=NaN;
            transportout(i,1)=NaN;
            co2out(i,1:5)=NaN;
            h2oout(i,1:5)=NaN;
            fco2out(i,1:5)=NaN;
            fh2oout(i,1:6)=NaN;
            hsout_flux(i,1:4)=NaN;
            hlout(i,1:3)=NaN;
            rhomout(i,1:3)=NaN;
            tdryout(i,1)=  NaN;
            iokout(i,1:2)=NaN;
            removed(i,1:5) = NaN;
            zoLout(i,1) = NaN;
            uvwtvar(i,1:4)=UVWTVAR_;   %variances of ROTATED wind components and the sonic temperature
            covuvwt(i,1:6)=COVUVWT_;   %covariances of ROTATED wind components and the sonic temperature        
            hbuoyantout(i,1)=HBUOYANT_;  %bouyancy flux (W m-2)
            ustar(i,1)=USTAR_;  % NX1 friction velocity (m/s)
            transportout(i,1)=TRANSPORT_;  %turblent transport
            u_vector(i,1:3) = u_vector_;
            w_mean(i,1) = w_mean_; %this is rotated from planar fit
        end    

    elseif size(find(day_ts==day & hr_ts==hr(i) & min_ts>=min_beg(i) & min_ts<min_end(i)),1) == 0  %no data
        datev_30(i,1:6) = [datev(1,1) datev(1,2) datev(1,3) hr(i) min_end(i) 0]; %assign timestamp (end of period)
        julday(i,1)=jday;
        numdate(i,1)=date;
        %assign NaN's for missing data:
        uvwtmean(i,1:4)=NaN;
        uvwmeanrot(i,1:3)=NaN;
        theta(i,1)=NaN;
        uvwtvar(i,1:4)=NaN;
        covuvwt(i,1:6)=NaN;
        ustar(i,1)=NaN;
        speed(i,1)=NaN;
        rH(i,1)=NaN;
        hbuoyantout(i,1)=NaN;
        transportout(i,1)=NaN;
        co2out(i,1:5)=NaN;
        h2oout(i,1:5)=NaN;
        fco2out(i,1:5)=NaN;
        fh2oout(i,1:6)=NaN;
        hsout_flux(i,1:4)=NaN;
        hlout(i,1:3)=NaN;
        rhomout(i,1:3)=NaN;
        tdryout(i,1)=  NaN;
        iokout(i,1:2)=NaN;
        removed(i,1:5) = NaN;
        zoLout(i,1) = NaN;
        u_vector(i,1) = NaN;
        w_mean(i,1) = NaN;
        if lag==1;
            lagCO2(i,1: 9)=NaN;
            lagH2O(i,1:5)=NaN;
        end    
    end % end if-then for enough data or not enough data
end % end 48 half-hour for-loop

timestamp = datestr(datev_30);
datenumber = datenum(datev_30);
ioko = iokout(:,2);

%make automatic plots using these variables



names = { 'year', 'month', 'day', ...
          'hour', 'min', 'second' };
y_units = repmat( { '-' }, 1, 6 );
y = dataset( { datev_30, names{:} } );

y.date = numdate;
y.jday = julday;
y.iok = ioko;
y_units = [ y_units, { '-', '-', '-' } ];

names = { 'u_mean', 'v_mean', 'w_mean', 'temp_mean' };
y_units = [ y_units, { 'm/s', 'm/s', 'm/s', 'C' } ];
y = [ y, dataset( { uvwtmean, names{:}  } ) ];

y.tdry = tdryout;
y.wind_direction = theta;
y.speed = speed;
y.rH = rH;
y_units = [ y_units, { 'K', 'degrees', 'm/s', '%' } ];

names = { 'along_wind_velocity_variance', ...
          'cross_wind_velocity_variance', ...
          'vertical_wind_velocity_variance',...
          'sonic_temperature_variance' } ;
y_units = [ y_units, repmat( { '-' }, size( names ) ) ];
y = [ y, dataset( { uvwtvar, names{ : } } ) ];

names = { 'uw_covariance', ...
          'vw_covariance', ...
          'uv_covariance', ...
          'ut_covariance', ...
          'vt_covariance', ...
          'wt_covariance' };
y_units = [ y_units, repmat( { '-' }, 1, 6 ) ];
y = [y, dataset( { covuvwt, names{ : } } ) ];

y.ustar = ustar;
y_units = [ y_units, { 'm/s' } ];

names = { 'CO2_min', 'CO2_max','CO2_median', ...
          'CO2_mean','CO2_std' };
y_units = [ y_units, repmat( { 'umol/mol dry air' }, 1, 5 ) ];
y = [ y, dataset( { co2out, names{ : } } ) ];

names = { 'H2O_min','H2O_max','H2O_median', ...
          'H2O_mean','H2O_std' };
y_units = [ y_units, repmat( { 'umol/mol dry air' }, 1, 5 ) ];
y = [ y, dataset( { h2oout, names{ : } } ) ];

names = { 'Fc_raw','Fc_raw_massman','Fc_water_term', ...
          'Fc_heat_term_massman','Fc_raw_massman_ourwpl' };
y_units = [ y_units, repmat( { 'umol/m2/s' }, 1, 5 ) ];
y = [ y, dataset( { fco2out, names{ : } } ) ];

names = { 'E_raw','E_raw_massman','E_water_term', ...
          'E_heat_term_massman','E_wpl_massman', ...
          'E_rhov_massman' };
y_units = [ y_units, repmat( { '-' }, 1, 6 ) ];
y = [ y, dataset( { fh2oout, names{ : } } ) ];

names = { 'SensibleHeat_dry','SensibleHeat_wet', ...
          'SensibleHeat_wetwet','HSdry_massman' };
y_units = [ y_units, repmat( { 'W/m2' }, 1, 4 ) ];
y = [ y, dataset( { hsout_flux, names{ : } } ) ];

names = { 'LatentHeat_raw', ...
          'LatentHeat_raw_massman', ...
          'LatentHeat_wpl_massman' };
y_units = [ y_units, repmat( { 'W/m2' }, 1, 3 ) ];
y = [ y, dataset( { hlout, names{ : } } ) ];

names = { 'rhoa_dry_air_molar_density', ...
          'rhov_dry_air_molar_density', ...
          'rhoc_dry_air_molar_density' };
y_units = [ y_units, repmat( { 'g/m3 moist air' }, 1, 3 ) ];
y = [ y, dataset( { rhomout, names{ : } } ) ];

y.buoyancy_flux = hbuoyantout;
y.transport = transportout;

names = { 'NaNs','Maxs','Mins','Spikes','Bad_variance' };
y = [ y, dataset( { removed, names{ : } } ) ];

y.zoL = zoLout;

names = { 'u_vector_u','u_vector_v','u_vector_w' };
y = [ y, ...
      dataset( { u_vector, names{ : } } ) ];

y.w_mean = w_mean;
y_units = [ y_units, repmat( { '-' }, 1, 11 ) ];

y.Properties.Units = y_units;

% data for output
% y = [datev_30, numdate,julday, ...
%      ioko, ...
%      uvwtmean, ...
%      tdryout,theta,speed,rH,uvwtvar,covuvwt,...
%      ustar,co2out,h2oout,fco2out,fh2oout,hsout_flux,hlout,rhomout,hbuoyantout,transportout,...
%      removed,zoLout,u_vector,w_mean];
% headertext = {'year', 'month', 'day', 'hour', 'min', 'second', 'date', 'jday', ...
%               'iok',...
%               'u_mean', 'v_mean', 'w_mean', 'temp_mean', ...
%               'tdry', 'wind direction (theta)', 'speed','rH',...
%               'along-wind velocity variance','cross-wind velocity variance','vertical-wind velocity variance',...
%               'sonic temperature variance','uw co-variance','vw co-variance','uv co-variance','ut co-variance','vt co-variance','wt co-variance',...
%               'ustar (friction velocity; m/s)',...
%               'CO2_min (umol/mol dry air)', 'CO2_max (umol/mol dry air)','CO2_median (umol/mol dry air)', 'CO2_mean (umol/mol dry air)','CO2_std (umol/mol dry air)',...
%               'H2O_min (mmol/mol dry air)','H2O_max (mmol/mol dry air)','H2O_median (mmol/mol dry air)','H2O_mean (mmol/mol dry air)','H2O_std (mmol/mol dry air)',...
%               'Fc_raw','Fc_raw_massman','Fc_water_term','Fc_heat_term_massman','Fc_raw_massman_ourwpl',...
%               'E_raw','E_raw_massman','E_water_term','E_heat_term_massman','E_raw_massman','E_rhov_massman',...
%               'SensibleHeat_dry (W m-2)','SensibleHeat_wet (W m-2)','SensibleHeat_wetwet (W m-2)','HSdry_massman',...
%               'LatentHeat_raw (W m-2)','LatentHeat_raw_massman','LatentHeat_wpl_massman',...
%               'rhoa_dry air molar density (g/m^3 moist air)','rhov_dry air molar density (g/m^3 moist air)','rhoc_dry air molar density (g/m^3 moist air)',...
%               'BouyancyFlux','transport',...
%               'NaNs','Maxs','Mins','Spikes','Bad variance','zoL',...
%               'urot','vrot','wrot',...
%               'u_vector_u','u_vector_v','u_vector_w','w_mean'};



% %write data to files
% disp('writing data to files....')
% date

% %excel daily files-- fairly useless, except as source for header
% fileout = strcat(outfolder, site,' processed data.xls');
% if lag == 0
%     xlswrite(fileout, headertext,int2str(date),'A1');
%     xlswrite(fileout, y,int2str(date),'A2');
% elseif lag == 1
%     xlswrite(fileout, headertext_lag,int2str(date),'A1');
%     xlswrite(fileout, y_lag,int2str(date),'A2');
% end
% disp('wrote excel file');

% %running compilation
% ofid = fopen(strcat(outfolder,site,' output'),'a');
% for i=1:size(y,1)
%    fprintf(ofid,'%f ',y(i,:));
%    fprintf(ofid, '\n');
% end
% fclose(ofid);

% if writefluxall==1
%     disp('preparing to enter data in FLUX_all file....')
%     fluxallfile = strcat(sitedir, site,'_FLUX_all.xls');
%     [num text] = xlsread(fluxallfile,'matlab','A1:A65500');
%     col='B';
    
%     timestamp2=text(5:size(text,1));
%     n=1;
%     time_match1=NaN; % time match lag is the row of the excel file for a given date/time (MF)
%     for i=1:48
%         if isnan(time_match1)==1 & ioko(i)>6000 %have not yet matched up first row
%             timenum=datenum(timestamp2);
%             time_match=find(abs(timenum-datenumber(i)) < 1/(48*3))+4;
%             if time_match >4  % a row with a matching date/time has been found in timestamp2 (MF)
%                 if lag==0
%                     y2(n,:)=y(i,:);
%                 elseif lag==1
%                     y2(n,:)=y_lag(i,:);
%                 end
%                 time_match1=time_match;  % set time match lag equal to time match if matching row found; otherwise leave as NaN (MF)
%                 n=n+1;
%             end
%         elseif isnan(time_match1)==0 & sum(find(ioko(i:48)>0))>0 %already have matched up first row & there is more data that day
%             if lag==0 
%                 y2(n,:)=y(i,:);
%             elseif lag==1
%                 y2(n,:)=y_lag(i,:);
%             end
%              n=n+1;
%         else %no more data
%         end  
%     end 

%     if isnan(time_match1)==0 & size(time_match1,1)==1;
%         xlswrite(fluxallfile,y2,'matlab', strcat(col,num2str(time_match1)));
%         disp('wrote to FLUX_all')
%     else
%          %disp('rows that match date/time') % MF Aug 2011
%          %disp(time_match1)                 % MF Aug 2011
         
%          disp('ERROR: FAILED TO WRITE TO FLUX_ALL!!!!!!!!!')   
%          disp('ERROR: FAILED TO WRITE TO FLUX_ALL!!!!!!!!!')
%          disp('ERROR: FAILED TO WRITE TO FLUX_ALL!!!!!!!!!')
%          disp('ERROR: FAILED TO WRITE TO FLUX_ALL!!!!!!!!!')
%          disp('ERROR: FAILED TO WRITE TO FLUX_ALL!!!!!!!!!')     
%     end
% end 

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% compoutput = [datev_30, numdate,julday, ioko, ustar, fco2out, fh2oout, hsout, hlout];
% 
% comparison = strcat(sitedir,site,'_lag_test'); %setting up the lag output file
% xlswrite(comparison,compoutput);

% removedfile = strcat(sitedir,site,'_removed'); %setting up the removed output file
% xlswrite(removedfile,removed);


