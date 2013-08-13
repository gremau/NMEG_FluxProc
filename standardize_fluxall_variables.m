function FA = standardize_fluxall_variables( sitecode, ...
                                             year_arg, ...
                                             headertext, ...
                                             timestamp, ...
                                             data )
% STANDARDIZE_FLUXALL_VARIABLES - assign common names to the observed fields
% found in UNM FLUXALL files.
%
% Accepts a dataset array data, and returns the dataset array with names
% standardized.  This is a work in progress, and needs testing/debugging.

ncol = numel( headertext );

[ year, month, day, hour, minute, second ] = datevec( timestamp );

%% create a dataset array FA to hold the fluxall data
t_vars = { 'year', 'month', 'day', 'hour', 'minute', 'second' };
var_names = genvarname(headertext( 2:end ) );
FA = dataset( { data, var_names{ : } } );

if ( sitecode == UNM_sites.TX ) & ( year_arg == 2008 )

    var_names{ 8 } = 'jday';
    var_names{ 9 } = 'iok';
    var_names{ 14 } = 'Tdry';
    var_names{ 15 } = 'wnd_dir_compass';
    var_names{ 16 } = 'wnd_spd';
    var_names{ 28 } = 'u_star';
    var_names{ 32 } = 'CO2_mean';
    var_names{ 33 } = 'CO2_std';
    var_names{ 37 } = 'H2O_mean';
    var_names{ 38 } = 'H2O_std';
    var_names{ 10 } = 'u_mean';
    var_names{ 13 } = 't_mean';

    var_names{ 39 } = 'fc_raw';
    var_names{ 40 } = 'fc_raw_massman';
    var_names{ 41 } = 'fc_water_term';
    var_names{ 42 } = 'fc_heat_term_massman';
    var_names{ 43 } = 'fc_raw_massman_wpl'; 

    var_names{ 44 } = 'E_raw';
    var_names{ 45 } = 'E_raw_massman';
    var_names{ 46 } = 'E_water_term';
    var_names{ 47 } = 'E_heat_term_massman';
    var_names{ 48 } = 'E_wpl_massman'; 

    var_names{ 50 } = 'HSdry';
    var_names{ 53 } = 'HSdry_massman';

    var_names{ 54 } = 'HL_raw';
    var_names{ 56 } = 'HL_wpl_massman';
    var_names{ 57 } = 'rhoa_dry';


elseif ( year_arg < 2009 ) && ( sitecode ~= UNM_sites.JSav )
    if ( sitecode == UNM_sites.TX ) && ( year_arg == 2008 )
        % This is set up for 2009 output
        disp('TX 2008 is set up as 2009 output');
        %stop
    end
    
    var_names{ 8 } = 'jday';
    var_names{ 9 } = 'iok';
    var_names{ 14 } = 'Tdry';
    var_names{ 15 } = 'wnd_dir_compass';
    var_names{ 16 } = 'wnd_spd';
    var_names{ 27 } = 'u_star';
    var_names{ 31 } = 'CO2_mean';
    var_names{ 32 } = 'CO2_std';
    var_names{ 36 } = 'H2O_mean';
    var_names{ 37 } = 'H2O_std';
    var_names{ 10 } = 'u_mean';
    var_names{ 13 } = 't_mean';

    var_names{ 40 } = 'fc_raw';
    var_names{ 44 } = 'fc_raw_massman';
    var_names{ 42 } = 'fc_water_term';
    var_names{ 45 } = 'fc_heat_term_massman';
    var_names{ 46 } = 'fc_raw_massman_wpl'; % = flux_co2_massman + flux_co2_wpl_water + flux_co2_massman_wpl_heat

    var_names{ 49 } = 'E_raw';
    var_names{ 53 } = 'E_raw_massman';
    var_names{ 51 } = 'E_water_term';
    var_names{ 54 } = 'E_heat_term_massman';
    var_names{ 55 } = 'E_wpl_massman'; % = flux_h20_wpl_water + flux_h20_massman_wpl_heat

    var_names{ 56 } = 'HSdry';
    var_names{ 59 } = 'HSdry_massman';

    var_names{ 61 } = 'HL_raw';
    var_names{ 64 } = 'HL_wpl_massman';
    var_names{ 63 } = 'HL_wpl_massman_un';
    var_names{ 65 } = 'rhoa_dry';

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

else
    
    var_names{ 8 } = 'jday';
    var_names{ 9 } = 'iok';
    var_names{ 14 } = 'Tdry';
    var_names{ 15 } = 'wnd_dir_compass';
    var_names{ 16 } = 'wnd_spd';
    var_names{ 28 } = 'u_star';
    var_names{ 32 } = 'CO2_mean';
    var_names{ 33 } = 'CO2_std';
    var_names{ 37 } = 'H2O_mean';
    var_names{ 38 } = 'H2O_std';
    var_names{ 10 } = 'u_mean';
    var_names{ 13 } = 't_mean';

    var_names{ 39 } = 'fc_raw';
    var_names{ 40 } = 'fc_raw_massman';
    var_names{ 41 } = 'fc_water_term';
    var_names{ 42 } = 'fc_heat_term_massman';
    var_names{ 43 } = 'fc_raw_massman_wpl'; % = flux_co2_massman + flux_co2_wpl_water + flux_co2_massman_wpl_heat

    var_names{ 44 } = 'E_raw';
    var_names{ 45 } = 'E_raw_massman';
    var_names{ 46 } = 'E_water_term';
    var_names{ 47 } = 'E_heat_term_massman';
    var_names{ 48 } = 'E_wpl_massman';

    var_names{ 50 } = 'HSdry';
    var_names{ 53 } = 'HSdry_massman';

    var_names{ 54 } = 'HL_raw';
    var_names{ 56 } = 'HL_wpl_massman';
    var_names{ 55 } = 'HL_wpl_massman_un';
    var_names{ 57 } = 'rhoa_dry';

end

% filter out absurd u_star values
FA.u_star( FA.u_star > 50 ) = NaN;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Read in 30-min data, variable order and names in flux_all files are not  
% consistent so match headertext
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

for i=1:ncol;
    if strcmp('agc_Avg',headertext(i)) == 1
        var_names{ i-1 } = 'agc_Avg';
    elseif strcmp( 'h2o_hmp_Avg', headertext( i ) )
        var_names{  i-1 } = 'h2o_hmp';
    elseif strcmp('RH',headertext(i)) == 1 || ...
            strcmp('rh_hmp', headertext(i)) == 1 || ...
            strcmp('rh_hmp_4_Avg', headertext(i)) == 1 || ...
            strcmp('RH_Avg', headertext(i)) == 1
        var_names{ i-1 } = 'rH';
    elseif strcmp( 'Ts_mean', headertext( i ) )
        var_names{ i-1 } = 'Tair_TOA5';
    elseif  strcmp('5point_precip', headertext(i)) == 1 || ...
            strcmp('rain_Tot', headertext(i)) == 1 || ...
            strcmp('precip', headertext(i)) == 1 || ...
            strcmp('precip(in)', headertext(i)) == 1 || ...
            strcmp('ppt', headertext(i)) == 1 || ...
            strcmp('Precipitation', headertext(i)) == 1
        var_names{ i-1 } = 'precip';
    elseif strcmp('press_mean', headertext(i)) == 1 || ...
            strcmp('press_Avg', headertext(i)) == 1 || ...
            strcmp('press_a', headertext(i)) == 1 || ...
            strcmp('press_mean', headertext(i)) == 1
        var_names{ i-1 } = 'atm_press';
    elseif strcmp('par_correct_Avg', headertext(i)) == 1  || ...
            strcmp('par_Avg(1)', headertext(i)) == 1 || ...
            strcmp('par_Avg_1', headertext(i)) == 1 || ...
            strcmp('par_Avg', headertext(i)) == 1 || ...
            strcmp('par_up_Avg', headertext(i)) == 1 || ...        
            strcmp('par_face_up_Avg', headertext(i)) == 1 || ...
            strcmp('par_incoming_Avg', headertext(i)) == 1 || ...
            strcmp('par_lite_Avg', headertext(i)) == 1
        var_names{ i-1 } = 'Par_Avg';
    elseif strcmp('t_hmp_mean', headertext(i))==1 || ...
            strcmp('AirTC_Avg', headertext(i))==1 || ...
            strcmp('t_hmp_3_Avg', headertext(i))==1 || ...
            strcmp('pnl_tmp_a', headertext(i))==1 || ...
            strcmp('t_hmp_Avg', headertext(i))==1 || ...
            strcmp('t_hmp_4_Avg', headertext(i))==1 || ...
            strcmp('t_hmp_top_Avg', headertext(i))==1
        var_names{ i-1 } = 'air_temp_hmp';
    elseif strcmp('AirTC_2_Avg', headertext(i))==1 && ...
            (year_arg == 2009 || year_arg ==2010) && sitecode == UNM_sites.MCon
        var_names{ i-1 } = 'air_temp_hmp';
    elseif strcmp('Tsoil',headertext(i)) == 1 || ...
            strcmp('Tsoil_avg',headertext(i)) == 1 || ...
            strcmp('soilT_Avg(1)',headertext(i)) == 1
        var_names{ i-1 } = 'Tsoil';
    elseif strcmp('Rn_correct_Avg',headertext(i))==1 || ...
            strcmp('NR_surf_AVG', headertext(i))==1 || ...
            strcmp('NetTot_Avg_corrected', headertext(i))==1 || ...
            strcmp('NetTot_Avg', headertext(i))==1 || ...
            strcmp('Rn_Avg',headertext(i))==1 || ...
            strcmp('Rn_total_Avg',headertext(i))==1
        var_names{ i-1 } = 'NR_tot';
    elseif strcmp('Rad_short_Up_Avg', headertext(i)) || ...
            strcmp('pyrr_incoming_Avg', headertext(i))
        var_names{ i-1 } = 'sw_incoming';
    elseif strcmp('Rad_short_Dn_Avg', headertext(i))==1 || ...
            strcmp('pyrr_outgoing_Avg', headertext(i))==1
        var_names{ i-1 } = 'sw_outgoing';
    elseif strcmp('Rad_long_Up_Avg', headertext(i)) == 1 || ...
            strcmp('Rad_long_Up__Avg', headertext(i)) == 1
        var_names{ i-1 } = 'lw_incoming';
    elseif strcmp('Rad_long_Dn_Avg', headertext(i))==1 || ...
            strcmp('Rad_long_Dn__Avg', headertext(i))==1
        var_names{ i-1 } = 'lw_outgoing';
    elseif strcmp('CNR1TC_Avg', headertext(i)) == 1 || ...
            strcmp('Temp_C_Avg', headertext(i)) == 1
        var_names{ i-1 } = 'CNR1TK';
    elseif strcmp('VW_Avg', headertext(i))==1
        var_names{ i-1 } = 'VWC';
    elseif strcmp('shf_Avg(1)', headertext(i))==1 || ...
            strcmp('shf_pinon_1_Avg', headertext(i))==1
        var_names{ i-1 } = 'soil_heat_flux_1';
        disp('FOUND shf_pinon_1_Avg');       
    elseif any( strcmp( headertext(i), ...
                        { 'hfp_grass_1_Avg', 'hfp01_grass_Avg' } ) )
        var_names{ i-1 } = 'soil_heat_flux_1';
        disp('FOUND hfp_grass_1_Avg');       
    elseif any( strcmp( headertext( i ), ...
                        { 'hfp_grass_2_Avg', 'hft3_grass_Avg' } ) )
        var_names{ i-1 } = 'soil_heat_flux_2';
        disp('FOUND hfp_grass_2_Avg');       
    elseif strcmp('shf_Avg(2)', headertext(i))==1 || ...
            strcmp('shf_jun_1_Avg', headertext(i))==1
        var_names{ i-1 } = 'soil_heat_flux_2';
    elseif strcmp('hfpopen_1_Avg', headertext(i))==1 % only for TX
        var_names{ i-1 } = 'soil_heat_flux_open';
    elseif strcmp('hfpmescan_1_Avg', headertext(i))==1 % only for TX
        var_names{ i-1 } = 'soil_heat_flux_mescan';
    elseif strcmp('hfpjuncan_1_Avg', headertext(i))==1 % only for TX
        var_names{ i-1 } = 'soil_heat_flux_juncan';
        %Shurbland flux plates 2009 onwards
    elseif strcmp('hfp01_1_Avg', headertext(i))==1 
        var_names{ i-1 } = 'soil_heat_flux_1';
    elseif strcmp('hfp01_2_Avg', headertext(i))==1 
        var_names{ i-1 } = 'soil_heat_flux_2';
    elseif strcmp('hfp01_3_Avg', headertext(i))==1 
        var_names{ i-1 } = 'soil_heat_flux_3';
    elseif strcmp('hfp01_4_Avg', headertext(i))==1 
        var_names{ i-1 } = 'soil_heat_flux_4';
    elseif strcmp('hfp01_5_Avg', headertext(i))==1 
        var_names{ i-1 } = 'soil_heat_flux_5';
    elseif strcmp('hfp01_6_Avg', headertext(i))==1 
        var_names{ i-1 } = 'soil_heat_flux_6';
    elseif strcmp('shf_Avg(3)', headertext(i))==1 
        var_names{ i-1 } = 'soil_heat_flux_3';
    elseif strcmp('shf_Avg(4)', headertext(i))==1 
        var_names{ i-1 } = 'soil_heat_flux_4';
    end
end

FA.Properties.VarNames = genvarname( var_names );

FA.t_meanK=FA.t_mean+ 273.15;
FA.rH = FA.rH / 100.0;

% Half hourly data filler only produces uncorrected HL_wpl_massman, but use
% these where available as very similar values
idx = isnan( FA.HL_wpl_massman ) & ~isnan( FA.HL_wpl_massman_un );
FA.HL_wpl_massman( idx ) = FA.HL_wpl_massman_un( idx );

FA.CNR1TK = FA.CNR1TK + 273.15;