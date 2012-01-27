function [ amflux_gaps, amflux_gf ] = ...
        UNM_Ameriflux_prepare_output_data( sitecode, ...
                                           year, ...
                                           data, ...
                                           ds_qc, ...
                                           ds_gf, ...
                                           ds_pt, ...
                                           ds_soil )
    % UNM_AMERIFLUX_PREPARE_FLUXES - prepare observed fluxes for writing to
    %   Ameriflux files.  Mostly creates QC flags and gives various observations the
    %   names they should have for Ameriflux.
    % This code is largely taken from UNM_Ameriflux_file_maker_011211.m
    %
    % (c) Timothy W. Hilton, UNM, January 2012

    % create a column of -9999s to place in the dataset where a site does not record
    % a particular variable
    dummy = repmat( -9999, size( ds_qc, 1 ), 1 );

    % initialize flags to 1
    f_flag = repmat( 1, size( data, 1 ), 1 );
    NEE_flag = f_flag;
    LE_flag = f_flag;
    H_flag = f_flag;
    TA_flag = f_flag;
    Rg_flag=f_flag;
    VPD_flag = f_flag;
    
    VPD_f = ds_gf.VPD ./ 10; % convert to kPa
                             % what is "_g"?  "good" values?  --TWH
    VPD_g = dummy;
    VPD_g( ~isnan( ds_qc.rH ) ) = VPD_f( ~isnan( ds_qc.rH ) );
    Tair_f = ds_gf.Tair_f;
    Rg_f = ds_gf.Rg_f;

    % set met flags to zero where data are missing
    TA_flag( ~isnan( ds_qc.air_temp_hmp ) ) = 0;
    Rg_flag( ~isnan( ds_qc.sw_incoming ) ) = 0;
    VPD_flag( ~isnan( ds_qc.rH ) ) = 0;

    % Take out some extra uptake values at Grassland premonsoon.
    if sitecode ==1
        to_remove = find( ds_qc.fc_raw_massman_wpl( 1:7000 ) <= 1.5 );
        ds_qc.fc_raw_massman_wpl( to_remove ) = NaN;
        to_remove = find( ds_qc.fc_raw_massman_wpl( 1:5000 ) <= 0.75 );
        ds_qc.fc_raw_massman_wpl( to_remove ) = NaN;
    end
    % Take out some extra uptake values at Ponderosa respiration.
    if sitecode == 5
        to_remove= find( ds_qc.fc_raw_massman_wpl > 8 );
        ds_qc.fc_raw_massman_wpl( to_remove ) = NaN;
    end

    % initialize observed fluxes to NaNs
    NEE_obs = dummy;
    LE_obs = dummy;
    H_obs = dummy;
    
    % fill in valid flux obs. and set corresponding flags to zero for...
    % NEE,
    idx = ~isnan( ds_qc.fc_raw_massman_wpl );
    NEE_obs( idx ) =   ds_qc.fc_raw_massman_wpl( idx );
    NEE_flag( idx ) = 0;
    % LE,
    idx = ~isnan( ds_qc.HL_wpl_massman );
    LE_obs( idx ) = ds_qc.HL_wpl_massman( idx );
    LE_flag( ~isnan(ds_qc.E_wpl_massman) ) = 0;
    % and H
    idx = ~isnan( ds_qc.HSdry_massman );
    H_obs( idx ) = ds_qc.HSdry_massman( idx );
    H_flag( idx ) = 0;


    NEE_f = ds_pt.NEE_HBLR;
    RE_f  = ds_pt.Reco_HBLR;
    GPP_f = ds_pt.GPP_HBLR;
    LE_f = ds_gf.LE_f;
    H_f = ds_gf.H_f;

    % Make sure NEE contain observations where available
    NEE_2 = NEE_f;
    idx = ~isnan( ds_qc.fc_raw_massman_wpl );
    NEE_2( idx ) = NEE_obs( idx );

    % To ensure carbon balance, calculate GPP as remainder when NEE is
    % subtracted from RE. This will give negative GPP when NEE exceeds
    % modelled RE. So set GPP to zero and add difference to RE.
    GPP_2 = RE_f - NEE_2;
    idx_neg_GPP = find( GPP_2 < 0 );
    RE_2 = RE_f;
    RE_2( idx_neg_GPP ) = RE_f( idx_neg_GPP ) - GPP_2( idx_neg_GPP );
    GPP_2( idx_neg_GPP ) = 0;

    % Make sure LE and H contain observations where available
    LE_2 = LE_f;
    idx = ~isnan( ds_qc.HL_wpl_massman );
    LE_2( idx ) = ds_qc.HL_wpl_massman( idx );

    H_2 = H_f;
    idx = ~isnan( ds_qc.HSdry_massman );
    H_2( idx ) = ds_qc.HSdry_massman( idx );

    % Make GPP and RE "obs" for output to file with gaps using modeled RE
    % and GPP as remainder
    GPP_obs = dummy;
    idx = ~isnan( ds_qc.fc_raw_massman_wpl );
    GPP_obs( idx ) = GPP_2( idx );
    RE_obs = dummy;
    RE_obs( idx ) = RE_2( idx );

    ds_qc.HL_wpl_massman( isnan(ds_qc.E_wpl_massman ) ) = NaN;

    %get the names of the soil heat flux variables (how many there are varies
    %site to site
    shf_vars = regexp_ds_vars( ds_soil, 'SHF.*' );
    
    % A little cleaning - very basic high/low filtering
    % anon function to find values in x outside of [L H]
    HL = @( x, L, H )  (x < L) | (x > H);
    
    ds_soil.Tsoil_1( HL(ds_soil.Tsoil_1, -10, 50 ) ) = NaN;    
    ds_soil.SWC_1( HL( ds_soil.SWC_1, 0, 1 ) ) = NaN;
    ds_qc.lw_incoming( HL( ds_qc.lw_incoming, 120, 600 ) ) = NaN;
    ds_qc.lw_outgoing( HL( ds_qc.lw_outgoing, 120, 650 ) ) = NaN;
    ds_qc.E_wpl_massman( HL( ds_qc.E_wpl_massman .* 18, -5, Inf ) ) = NaN;
    ds_qc.CO2_mean( HL( ds_qc.CO2_mean, 350, Inf ) ) = NaN;
    ds_qc.wnd_spd( HL( ds_qc.wnd_spd, 25, Inf ) ) = NaN;
    ds_qc.atm_press( HL( ds_qc.atm_press, 20, 150 ) ) = NaN;
    ds_qc.Par_Avg( HL( ds_qc.Par_Avg, -100, 2500 ) ) = NaN;
    for i = 1:numel( shf_vars )
        this_shf = ds_soil.( shf_vars{ i } );
        this_shf( HL( this_shf, -150, 150 ) ) = NaN;
        ds_soil.( shf_vars{ i } ) = this_shf;
    end

    NEE_f( HL( NEE_f, -50, 50 ) ) = NaN;
    RE_f( HL( RE_f, -50, 50) ) = NaN;
    GPP_f( HL( GPP_f, -50, 50 ) ) = NaN;
    NEE_obs( HL( NEE_obs, -50, 50 ) ) = NaN;  
    RE_obs( HL( RE_obs, -50, 50 ) ) = NaN;  
    GPP_obs( HL( GPP_obs, -50, 50 ) ) = NaN;
    NEE_2( HL( NEE_2, -50, 50 ) ) = NaN;  
    RE_2( HL( RE_2, -50, 50 ) ) = NaN;  
    GPP_2( HL( GPP_2, -50, 50 ) ) = NaN;

    if sitecode == 6 && year == 2008
        ds_qc.lw_incoming( ~isnan( ds_qc.lw_incoming ) ) = NaN;
        ds_qc.lw_outgoing( ~isnan( ds_qc.lw_outgoing ) ) = NaN;
        ds_qc.NR_tot( ~isnan( ds_qc.NR_tot ) ) = NaN;
    end

    % replace 9999s with matlab NaNs
    fp_tol = 0.0001;  % tolerance for floating point comparison
    NEE_obs = replace_badvals( NEE_obs, -9999, fp_tol );
    GPP_obs = replace_badvals( GPP_obs, -9999, fp_tol );
    RE_obs = replace_badvals( RE_obs, -9999, fp_tol );
    H_obs = replace_badvals( H_obs, -9999, fp_tol );
    LE_obs = replace_badvals( LE_obs, -9999, fp_tol );
    VPD_f = replace_badvals( VPD_f, -999.9, fp_tol );
    
    % calculate mean soil heat flux across all pits
    SHF_vars = ds_soil( :, regexp_ds_vars( ds_soil, 'SHF.*' ) );    
    SHF_mean = nanmean( double( SHF_vars ), 2 );
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % place calculated values into Matlab datasets 
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    % initialize variable names, units, etc.
    [amflux_gaps, amflux_gf] = ...
        UNM_Ameriflux_create_output_datasets( sitecode, size( ds_qc, 1 ) );
    
    % assign values to aflx1
    amflux_gaps.YEAR = str2num( datestr( ds_qc.timestamp, 'YYYY' ) );
    amflux_gaps.DTIME = ds_qc.timestamp - datenum( amflux_gaps.YEAR, 1, 1 ) + 1;
    amflux_gaps.DOY = floor( amflux_gaps.DTIME );
    amflux_gaps.HRMIN = str2num( datestr( ds_qc.timestamp, 'HHMM' ) ); 
    amflux_gaps.UST = ds_qc.u_star;
    amflux_gaps.TA = ds_qc.air_temp_hmp;
    amflux_gaps.WD = ds_qc.wnd_dir_compass;
    amflux_gaps.WS = ds_qc.wnd_spd;
    amflux_gaps.NEE = dummy;
    amflux_gaps.FC = NEE_obs;
    amflux_gaps.SFC = dummy;
    amflux_gaps.H = H_obs;
    amflux_gaps.SSA = dummy;
    amflux_gaps.LE = LE_obs;
    amflux_gaps.SLE = dummy;
    amflux_gaps.G1 = SHF_mean;
    amflux_gaps.TS_2p5cm = ds_soil.Tsoil_1;
    amflux_gaps.PRECIP = ds_qc.precip;
    amflux_gaps.RH = ds_qc.rH .* 100;
    amflux_gaps.PA = ds_qc.atm_press;
    amflux_gaps.CO2 = ds_qc.CO2_mean;
    amflux_gaps.VPD = VPD_g;
    amflux_gaps.SWC_2p5cm = ds_soil.SWC_1;
    amflux_gaps.RNET = ds_qc.NR_tot;
    amflux_gaps.PAR = ds_qc.Par_Avg;
    amflux_gaps.PAR_DIFF = dummy;
    amflux_gaps.PAR_out = dummy;
    amflux_gaps.Rg = ds_qc.sw_incoming;
    amflux_gaps.Rg_DIFF = dummy;
    amflux_gaps.Rg_out = ds_qc.sw_outgoing;
    amflux_gaps.Rlong_in = ds_qc.lw_incoming;
    amflux_gaps.Rlong_out = ds_qc.lw_outgoing;
    amflux_gaps.FH2O = ds_qc.E_wpl_massman .* 18;
    amflux_gaps.H20 = ds_qc.H2O_mean;
    amflux_gaps.RE = RE_obs;
    amflux_gaps.GPP = GPP_obs;
    amflux_gaps.APAR = dummy;
    
    % assign values to amflux_gaps
    amflux_gf.YEAR = amflux_gaps.YEAR;
    amflux_gf.DOY = amflux_gaps.DOY;
    amflux_gf.HRMIN = amflux_gaps.HRMIN;
    amflux_gf.DTIME = amflux_gaps.DTIME;
    amflux_gf.UST = ds_qc.u_star;
    amflux_gf.TA = Tair_f;
    amflux_gf.TA_flag = TA_flag;
    amflux_gf.WD = ds_qc.wnd_dir_compass;
    amflux_gf.WS = ds_qc.wnd_spd;
    amflux_gf.NEE = dummy;
    amflux_gf.FC = NEE_2;
    amflux_gf.FC_flag = NEE_flag;
    amflux_gf.SFC = dummy;
    amflux_gf.H = H_2;
    amflux_gf.H_flag = H_flag;
    amflux_gf.SSA = dummy;
    amflux_gf.LE = LE_2;
    amflux_gf.LE_flag = LE_flag;
    amflux_gf.SLE = dummy;
    amflux_gf.G1 = SHF_mean;
    amflux_gf.TS_2p5cm = ds_soil.Tsoil_1;
    amflux_gf.PRECIP = ds_qc.precip;
    amflux_gf.RH = ds_qc.rH .* 100;
    amflux_gf.PA = ds_qc.atm_press;
    amflux_gf.CO2 = ds_qc.CO2_mean;
    amflux_gf.VPD = VPD_f;
    amflux_gf.VPD_flag = VPD_flag;
    amflux_gf.SWC_2p5cm = ds_soil.SWC_1;
    amflux_gf.RNET = ds_qc.NR_tot;
    amflux_gf.PAR = ds_qc.Par_Avg;
    amflux_gf.PAR_DIFF = dummy;
    amflux_gf.PAR_out = dummy;
    amflux_gf.Rg = Rg_f;
    amflux_gf.Rg_flag = Rg_flag;
    amflux_gf.Rg_DIFF = dummy;
    amflux_gf.Rg_out = ds_qc.sw_outgoing;
    amflux_gf.Rlong_in = ds_qc.lw_incoming;
    amflux_gf.Rlong_out = ds_qc.lw_outgoing;
    amflux_gf.FH2O = ds_qc.E_wpl_massman .* 18;
    amflux_gf.H20 = ds_qc.H2O_mean;
    amflux_gf.RE = RE_2;
    amflux_gf.RE_flag = NEE_flag;
    amflux_gf.GPP = GPP_2;
    amflux_gf.GPP_flag = NEE_flag;
    amflux_gf.APAR = dummy;
    amflux_gf.SWC_2 = ds_soil.SWC_2;
    amflux_gf.SWC_3 = ds_soil.SWC_3;