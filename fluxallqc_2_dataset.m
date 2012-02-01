function ds = fluxallqc_2_dataset( qc_num, sitecode, year )
% FLUXALLQC_2_DATASET( qc_num, sitecode, year ) - places Flux_all_QC data into
% matlab dataset
%   

    timestamp = excel_date_2_matlab_datenum( qc_num( :, 1 ) );
    ds = dataset( { timestamp, 'timestamp' } );
    
    qc_num = qc_num( :, 2:end );
    ds.year = qc_num( :, 1 );

    ds.month = qc_num( :, 2 );
    ds.day = qc_num( :, 3 );
    ds.hour= qc_num( :, 4 );
    ds.minute = qc_num( :, 5 );
    ds.jday = qc_num( :, 7 );

    % create a column of NaNs to place in dataset where a site does not
    % record a particular variable
    nan_col = repmat( NaN, size( ds, 1 ), 1 );
    
    if sitecode == 7  %% TX
        ds.u_star = qc_num( :, 10 );
        ds.air_temp_hmp = qc_num( :, 32 );
        ds.wnd_dir_compass = qc_num( :, 11 );
        ds.wnd_spd = qc_num( :, 12 );
        ds.fc_raw_massman_wpl = qc_num( :, 21 );
        ds.HSdry_massman = qc_num( :, 28 );
        ds.HL_wpl_massman = qc_num( :, 30 );
        ds.soil_heat_flux_1 = qc_num( :, 38 );
        ds.soil_heat_flux_2 = qc_num( :, 39 );
        ds.soil_heat_flux_3 = qc_num( :, 40 );
        ds.Tsoil_hfp = qc_num( :, 33 );
        ds.Tsoil_5c = qc_num( :, 34 );
        ds.Tsoil_10c = qc_num( :, 35 );
        ds.Tsoil_5o = qc_num( :, 36 );
        ds.Tsoil_10o = qc_num( :, 37 );
        ds.precip = qc_num( :, 41 );
        ds.rH = qc_num( :, 43 );
        ds.atm_press = qc_num( :, 42 );
        ds.CO2_mean = qc_num( :, 13 );
        ds.NR_tot = qc_num( :, 51 );
        ds.Par_Avg = qc_num( :, 44 );
        ds.sw_incoming = qc_num( :, 45 );
        ds.sw_outgoing = qc_num( :, 46 );
        ds.lw_incoming = qc_num( :, 47 );
        ds.lw_outgoing = qc_num( :, 48 );
        ds.E_wpl_massman = qc_num( :, 26 );
        ds.H2O_mean = qc_num( :, 15 );
    
    elseif sitecode == 8  %% TX forest   
        ds.u_star = qc_num( :,  9 );
        ds.air_temp_hmp = qc_num( :, 31 );
        ds.wnd_dir_compass = qc_num( :, 10 );
        ds.wnd_spd = qc_num( :, 11 );
        ds.fc_raw_massman_wpl = qc_num( :, 20 );
        ds.HSdry_massman = qc_num( :, 27 );
        ds.HL_wpl_massman = qc_num( :, 29 );
        ds.soil_heat_flux_1 = nan_col;
        ds.soil_heat_flux_2 = nan_col;
        ds.soil_heat_flux_3 = nan_col;
        ds.Tsoil_hfp = nan_col;
        ds.Tsoil_5c = nan_col;
        ds.Tsoil_10c = nan_col;
        ds.Tsoil_5o = nan_col;
        ds.Tsoil_10o = nan_col;
        ds.precip = qc_num( :, 32 );
        ds.rH = qc_num( :, 34 );
        ds.atm_press = qc_num( :, 33 );
        ds.CO2_mean = qc_num( :, 12 );
        ds.NR_tot = nan_col;
        ds.Par_Avg = nan_col;
        ds.sw_incoming = nan_col;
        ds.sw_outgoing = nan_col;
        ds.lw_incoming = nan_col;
        ds.lw_outgoing = nan_col;
        ds.E_wpl_massman = qc_num( :, 25 );
        ds.H2O_mean = qc_num( :, 14 );

    else  %% site is not TX or TX forest
        ds.u_star=qc_num( :, 10 );
        ds.air_temp_hmp=qc_num( :, 32 );
        ds.wnd_dir_compass=qc_num( :, 11 );
        ds.wnd_spd=qc_num( :, 12 );
        ds.fc_raw_massman_wpl=qc_num( :, 21 );
        ds.HSdry_massman=qc_num( :, 28 );
        ds.HL_wpl_massman=qc_num( :, 30 );
        ds.soil_heat_flux_1=qc_num( :, 34 );
        ds.soil_heat_flux_2=qc_num( :, 35 );
        ds.Tsoil_hfp=qc_num( :, 33 );
        ds.precip=qc_num( :, 36 );
        ds.rH=qc_num( :, 38 );
        ds.atm_press=qc_num( :, 37 );
        ds.CO2_mean=qc_num( :, 13 );
        ds.NR_tot=qc_num( :, 46 );
        ds.Par_Avg=qc_num( :, 39 );
        ds.sw_incoming=qc_num( :, 40 );
        ds.sw_outgoing=qc_num( :, 41 );
        ds.lw_incoming=qc_num( :, 42 );
        ds.lw_outgoing=qc_num( :, 43 );
        ds.E_wpl_massman=qc_num( :, 26 );
        ds.H2O_mean=qc_num( :, 15 );
    end

    %% convert excel serial dates to matlab datenums
    
