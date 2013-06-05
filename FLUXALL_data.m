classdef FLUXALL_data

properties
    
    sitecode;
    year_arg;
    
    %observed data
    atm_press;
    CNR1TK;
    co2mean;
    CO2_mean;
    CO2_mean_clean;
    E_heat_term_massman;
    E_raw;
    E_raw_massman;
    E_water_term;
    E_wpl_massman;
    fc_heat_term_massman;
    fc_raw;
    fc_raw_massman;
    fc_raw_massman_wpl;
    fc_water_term;
    H2O_mean;
    H_dry;
    HL_raw;
    HL_wpl_massman;
    HSdry;
    HSdry_massman;
    Lv;
    lw_incoming;
    lw_outgoing;
    NR_lw;
    NR_sw;
    NR_tot;
    Par_Avg;
    Par_Avg1;
    Par_Avg2;
    precip;
    Properties;
    rH;
    rhoa_dry;
    rhoa_dry_kg;
    sw_incoming;
    sw_outgoing;
    Tair_TOA5;
    Tdry;
    timestamp;
    t_mean;
    t_meank;
    t_meanK;
    u_mean;
    u_star;
    wnd_dir_compass;
    wnd_spd;
end

methods
    % --------------------------------------------------
        function obj = FLUXALL_data( sitecode, year_arg, varargin )
        % class constructor.
        % If year_arg < 2012, loads matlab binary of parsed excel data.
        

        end
    
        function data = FLUXALL_data_intake_pre2012( varargin )
% FLUXALL_DATA_INTAKE_PRE2012 - obtains the FLUXDATA for site-years prior to
%   2012.

args = inputParser;
args.addRequired( 'sitecode', @( x ) isa( x, 'UNM_sites' ) );
args.addRequired( 'year_arg', @isnumeric );
args.addParamValue( 'load_binary', true, @islogical );
args.parse( sitecode, year, varargin{ : } );

save_fname = fullfile( getenv( 'FLUXROOT' ), 'FluxallConvert', ...
                       sprintf( '%s_%d_FA_Convert.mat', ...
                                char( args.Results.sitecode ), year_arg ) );
if not( args.Results.load_binary )
    if args.Results.year_arg <= 2012
        row1=5;  %first row of data to process - rows 1 - 4 are header
        filename = strcat(site,'_flux_all_',num2str(year))
        %filename = strcat(site,'_new_radiation_flux_all_',num2str(year))
        filelength = num2str(filelength_n);
        %datalength = filelength_n - row1 + 1; 
        filein = fullfile( getenv( 'FLUXROOT' ), ...
                           'Flux_Tower_Data_by_Site', ...
                           site, ...
                           filename );
        range = strcat('B',num2str(row1),':',lastcolumn,filelength);
        headerrange = strcat('B2:',lastcolumn,'2');
        time_stamp_range = strcat('A5:A',filelength);
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Open file and parse out dates and times
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        disp('reading data...')
        [num xls_text] = xlsread(filein,headerrange);
        headertext = xls_text;
        %does not read in first column because it's text!!!!!!!!
        [num xls_text] = xlsread(filein,range);  
        data = num;
        ncol = size(data,2)+1;
        datalength = size(data,1);
        [num xls_text] = xlsread(filein,time_stamp_range);
        timestamp = xls_text;
        [year month day hour minute second] = datevec(timestamp);
        datenumber = datenum(timestamp);
        disp('file read');

        save( save_fname );
        fprintf( 'saved %s\n', save_fname );
    end
else  %load binary data
    this_args = args;  %preserve arguments from local function call
    load( save_fname );
    args = this_args;
    fprintf( 'loaded %s\n', save_fname );
end

obj = fluxall_data_to_matlab_vars_pre2012( data, headertext );

end

%------------------------------------------------------------

function data_out = fluxall_data_to_matlab_vars_pre2012( data, headertext )
% FLUXALL_DATA_TO_MATLAB_VARS - 
%   
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Read in Matlab processed ts data (these are in the same columns for all
% sites, so they can be just hard-wired in by column number
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if ( args.Results.sitecode == 7 ) & ( year == 2008 )

    jday=data(:,8);
    iok=data(:,9);
    Tdry=data(:,14);
    wnd_dir_compass=data(:,15);
    wnd_spd=data(:,16);
    u_star=data(:,28);
    CO2_mean=data(:,32);
    CO2_std=data(:,33);
    H2O_mean=data(:,37);
    H2O_std=data(:,38);
    u_mean=data(:,10);
    t_mean=data(:,13);
    t_meanK=t_mean+ 273.15;

    fc_raw = data(:,39);
    fc_raw_massman = data(:,40);
    fc_water_term = data(:,41);
    fc_heat_term_massman = data(:,42);
    fc_raw_massman_wpl = data(:,43); % = flux_co2_massman + flux_co2_wpl_water + flux_co2_massman_wpl_heat

    E_raw = data(:,44);
    E_raw_massman = data(:,45);
    E_water_term = data(:,46);
    E_heat_term_massman = data(:,47);
    E_wpl_massman = data(:,48); % = flux_h20_wpl_water + flux_h20_massman_wpl_heat

    HSdry = data(:,50);
    HSdry_massman = data(:,53);

    HL_raw = data(:,54);
    HL_wpl_massman = data(:,56);
    HL_wpl_massman_un = repmat( NaN, size( data, 1 ), 1 );
    % Half hourly data filler only produces uncorrected HL_wpl_massman, but use
    % these where available
    %HL_wpl_massman(isnan(HL_wpl_massman)&~isnan(HL_wpl_massman_un))=HL_wpl_massman_un(isnan(HL_wpl_massman)&~isnan(HL_wpl_massman_un));

    rhoa_dry = data(:,57);

    decimal_day = ( datenum( year, month, day, hour, minute, second ) - ...
                    datenum( year, 1, 1 ) + 1 );
    
    for i=1:ncol;
        if strcmp('RH',headertext(i)) == 1 || strcmp('rh_hmp', headertext(i)) == 1 || strcmp('rh_hmp_4_Avg', headertext(i)) == 1
            rH = data(:,i-1);
        end
    end


elseif args.Results.year < 2009 && args.Results.sitecode ~= 3 
    if args.Results.sitecode == 7 && args.Results.year == 2008 % This is set up for 2009 output
        disp('TX 2008 is set up as 2009 output');
        %stop
    end
    
    jday=data(:,8);
    iok=data(:,9);
    Tdry=data(:,14);
    wnd_dir_compass=data(:,15);
    wnd_spd=data(:,16);
    u_star=data(:,27);
    CO2_mean=data(:,31);
    CO2_std=data(:,32);
    H2O_mean=data(:,36);
    H2O_std=data(:,37);
    u_mean=data(:,10);
    t_mean=data(:,13);
    t_meanK=t_mean+ 273.15;

    fc_raw = data(:,40);
    fc_raw_massman = data(:,44);
    fc_water_term = data(:,42);
    fc_heat_term_massman = data(:,45);
    fc_raw_massman_wpl = data(:,46); % = flux_co2_massman + flux_co2_wpl_water + flux_co2_massman_wpl_heat

    E_raw = data(:,49);
    E_raw_massman = data(:,53);
    E_water_term = data(:,51);
    E_heat_term_massman = data(:,54);
    E_wpl_massman = data(:,55); % = flux_h20_wpl_water + flux_h20_massman_wpl_heat

    HSdry = data(:,56);
    HSdry_massman = data(:,59);

    HL_raw = data(:,61);
    HL_wpl_massman = data(:,64);
    HL_wpl_massman_un = data(:,63);
    % Half hourly data filler only produces uncorrected HL_wpl_massman, but use
    % these where available
    HL_wpl_massman(isnan(HL_wpl_massman)&~isnan(HL_wpl_massman_un))=HL_wpl_massman_un(isnan(HL_wpl_massman)&~isnan(HL_wpl_massman_un));

    rhoa_dry = data(:,65);

    decimal_day = ( datenum( year, month, day, hour, minute, second ) - ...
                    datenum( year, 1, 1 ) + 1 );
    
    for i=1:ncol;
        if strcmp('RH',headertext(i)) == 1 || strcmp('rh_hmp', headertext(i)) == 1 || strcmp('rh_hmp_4_Avg', headertext(i)) == 1
            rH = data(:,i-1);
        end
    end

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
else  %JSav pre-2009
    
    jday=data(:,8);
    iok=data(:,9);
    Tdry=data(:,14);
    wnd_dir_compass=data(:,15);
    wnd_spd=data(:,16);
    u_star=data(:,28);
    CO2_mean=data(:,32);
    CO2_std=data(:,33);
    H2O_mean=data(:,37);
    H2O_std=data(:,38);
    u_mean=data(:,10);
    t_mean=data(:,13);
    t_meanK=t_mean+ 273.15;

    fc_raw = data(:,39);
    fc_raw_massman = data(:,40);
    fc_water_term = data(:,41);
    fc_heat_term_massman = data(:,42);
    fc_raw_massman_wpl = data(:,43); % = flux_co2_massman + flux_co2_wpl_water + flux_co2_massman_wpl_heat

    E_raw = data(:,44);
    E_raw_massman = data(:,45);
    E_water_term = data(:,46);
    E_heat_term_massman = data(:,47);
    E_wpl_massman = data(:,48);

    HSdry = data(:,50);
    HSdry_massman = data(:,53);

    HL_raw = data(:,54);
    HL_wpl_massman = data(:,56);
    HL_wpl_massman_un = data(:,55);
    % Half hourly data filler only produces uncorrected HL_wpl_massman, but use
    % these where available as very similar values
    HL_wpl_massman(isnan(HL_wpl_massman)&~isnan(HL_wpl_massman_un))=HL_wpl_massman_un(isnan(HL_wpl_massman)&~isnan(HL_wpl_massman_un));

    rhoa_dry = data(:,57);

    decimal_day = ( datenum( year, month, day, hour, minute, second ) - ...
                    datenum( year, 1, 1 ) + 1 );

end

%initialize RH to NaN
rH = repmat( NaN, size( data, 1), 1 );

% filter out absurd u_star values
u_star( u_star > 50 ) = NaN;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Read in 30-min data, variable order and names in flux_all files are not  
% consistent so match headertext
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

for i=1:ncol;
    if strcmp('agc_Avg',headertext(i)) == 1
        agc_Avg = data(:,i-1);
    elseif strcmp( 'h2o_hmp_Avg', headertext( i ) )
        h2o_hmp = data( :, i-1 );
    elseif strcmp('RH',headertext(i)) == 1 || ...
            strcmp('rh_hmp', headertext(i)) == 1 || ...
            strcmp('rh_hmp_4_Avg', headertext(i)) == 1 || ...
            strcmp('RH_Avg', headertext(i)) == 1
        rH = data(:,i-1) / 100.0;
    elseif strcmp( 'Ts_mean', headertext( i ) )
        Tair_TOA5 = data(:,i-1);
    elseif  strcmp('5point_precip', headertext(i)) == 1 || ...
            strcmp('rain_Tot', headertext(i)) == 1 || ...
            strcmp('precip', headertext(i)) == 1 || ...
            strcmp('precip(in)', headertext(i)) == 1 || ...
            strcmp('ppt', headertext(i)) == 1 || ...
            strcmp('Precipitation', headertext(i)) == 1
        precip = data(:,i-1);
    elseif strcmp('press_mean', headertext(i)) == 1 || ...
            strcmp('press_Avg', headertext(i)) == 1 || ...
            strcmp('press_a', headertext(i)) == 1 || ...
            strcmp('press_mean', headertext(i)) == 1
        atm_press = data(:,i-1);
    elseif strcmp('par_correct_Avg', headertext(i)) == 1  || ...
            strcmp('par_Avg(1)', headertext(i)) == 1 || ...
            strcmp('par_Avg_1', headertext(i)) == 1 || ...
            strcmp('par_Avg', headertext(i)) == 1 || ...
            strcmp('par_up_Avg', headertext(i)) == 1 || ...        
            strcmp('par_face_up_Avg', headertext(i)) == 1 || ...
            strcmp('par_incoming_Avg', headertext(i)) == 1 || ...
            strcmp('par_lite_Avg', headertext(i)) == 1
        Par_Avg = data(:,i-1);
    elseif strcmp('t_hmp_mean', headertext(i))==1 || ...
            strcmp('AirTC_Avg', headertext(i))==1 || ...
            strcmp('t_hmp_3_Avg', headertext(i))==1 || ...
            strcmp('pnl_tmp_a', headertext(i))==1 || ...
            strcmp('t_hmp_Avg', headertext(i))==1 || ...
            strcmp('t_hmp_4_Avg', headertext(i))==1 || ...
            strcmp('t_hmp_top_Avg', headertext(i))==1
        air_temp_hmp = data(:,i-1);
    elseif strcmp('AirTC_2_Avg', headertext(i))==1 && ...
            (args.Results.year == 2009 || ...
             args.Results.year ==2010) && args.Results.sitecode == 6
        air_temp_hmp = data(:,i-1);
    elseif strcmp('Tsoil',headertext(i)) == 1 || ...
            strcmp('Tsoil_avg',headertext(i)) == 1 || ...
            strcmp('soilT_Avg(1)',headertext(i)) == 1
        Tsoil = data(:,i-1);
    elseif strcmp('Rn_correct_Avg',headertext(i))==1 || ...
            strcmp('NR_surf_AVG', headertext(i))==1 || ...
            strcmp('NetTot_Avg_corrected', headertext(i))==1 || ...
            strcmp('NetTot_Avg', headertext(i))==1 || ...
            strcmp('Rn_Avg',headertext(i))==1 || ...
            strcmp('Rn_total_Avg',headertext(i))==1
        NR_tot = data(:,i-1);
    elseif strcmp('Rad_short_Up_Avg', headertext(i)) || ...
            strcmp('pyrr_incoming_Avg', headertext(i))
        sw_incoming = data(:,i-1);
    elseif strcmp('Rad_short_Dn_Avg', headertext(i))==1 || ...
            strcmp('pyrr_outgoing_Avg', headertext(i))==1
        sw_outgoing = data(:,i-1);
    elseif strcmp('Rad_long_Up_Avg', headertext(i)) == 1 || ...
            strcmp('Rad_long_Up__Avg', headertext(i)) == 1
        lw_incoming = data(:,i-1);
    elseif strcmp('Rad_long_Dn_Avg', headertext(i))==1 || ...
            strcmp('Rad_long_Dn__Avg', headertext(i))==1
        lw_outgoing = data(:,i-1);
    elseif strcmp('CNR1TC_Avg', headertext(i)) == 1 || ...
            strcmp('Temp_C_Avg', headertext(i)) == 1
        CNR1TK = data(:,i-1) + 273.15;
    elseif strcmp('VW_Avg', headertext(i))==1
        VWC = data(:,i-1);
    elseif strcmp('shf_Avg(1)', headertext(i))==1 || ...
            strcmp('shf_pinon_1_Avg', headertext(i))==1
        soil_heat_flux_1 = data(:,i-1);
        disp('FOUND shf_pinon_1_Avg');       
    elseif any( strcmp( headertext(i), ...
                        { 'hfp_grass_1_Avg', 'hfp01_grass_Avg' } ) )
        soil_heat_flux_1 = data(:,i-1);
        disp('FOUND hfp_grass_1_Avg');       
    elseif any( strcmp( headertext( i ), ...
                        { 'hfp_grass_2_Avg', 'hft3_grass_Avg' } ) )
        soil_heat_flux_2 = data(:,i-1);
        disp('FOUND hfp_grass_2_Avg');       
    elseif strcmp('shf_Avg(2)', headertext(i))==1 || ...
            strcmp('shf_jun_1_Avg', headertext(i))==1
        soil_heat_flux_2 = data(:,i-1);
    elseif strcmp('hfpopen_1_Avg', headertext(i))==1 % only for TX
        soil_heat_flux_open = data(:,i-1);
    elseif strcmp('hfpmescan_1_Avg', headertext(i))==1 % only for TX
        soil_heat_flux_mescan = data(:,i-1);
    elseif strcmp('hfpjuncan_1_Avg', headertext(i))==1 % only for TX
        soil_heat_flux_juncan = data(:,i-1);
        %Shurbland flux plates 2009 onwards
    elseif strcmp('hfp01_1_Avg', headertext(i))==1 
        soil_heat_flux_1 = data(:,i-1);
    elseif strcmp('hfp01_2_Avg', headertext(i))==1 
        soil_heat_flux_2 = data(:,i-1);
    elseif strcmp('hfp01_3_Avg', headertext(i))==1 
        soil_heat_flux_3 = data(:,i-1);
    elseif strcmp('hfp01_4_Avg', headertext(i))==1 
        soil_heat_flux_4 = data(:,i-1);
    elseif strcmp('hfp01_5_Avg', headertext(i))==1 
        soil_heat_flux_5 = data(:,i-1);
    elseif strcmp('hfp01_6_Avg', headertext(i))==1 
        soil_heat_flux_6 = data(:,i-1);
    elseif strcmp('shf_Avg(3)', headertext(i))==1 
        soil_heat_flux_3 = data(:,i-1);
    elseif strcmp('shf_Avg(4)', headertext(i))==1 
        soil_heat_flux_4 = data(:,i-1);
        
    end
    
    obj.atm_press = atm_press;
    obj.CNR1TK = CNR1TK;
    obj.co2mean = co2mean;
    obj.CO2_mean = CO2_mean;
    obj.CO2_mean_clean = CO2_mean_clean;
    obj.E_heat_term_massman = E_heat_term_massman;
    obj.E_raw = E_raw;
    obj.E_raw_massman = E_raw_massman;
    obj.E_water_term = E_water_term;
    obj.E_wpl_massman = E_wpl_massman;
    obj.fc_heat_term_massman = fc_heat_term_massman;
    obj.fc_raw = fc_raw;
    obj.fc_raw_massman = fc_raw_massman;
    obj.fc_raw_massman_wpl = fc_raw_massman_wpl;
    obj.fc_water_term = fc_water_term;
    obj.H2O_mean = H2O_mean;
    obj.H_dry = H_dry;
    obj.HL_raw = HL_raw;
    obj.HL_wpl_massman = HL_wpl_massman;
    obj.HSdry = HSdry;
    obj.HSdry_massman = HSdry_massman;
    obj.Lv = Lv;
    obj.lw_incoming = lw_incoming;
    obj.lw_outgoing = lw_outgoing;
    obj.NR_lw = NR_lw;
    obj.NR_sw = NR_sw;
    obj.NR_tot = NR_tot;
    obj.Par_Avg = Par_Avg;
    obj.Par_Avg1 = Par_Avg1;
    obj.Par_Avg2 = Par_Avg2;
    obj.precip = precip;
    obj.Properties = Properties;
    obj.rH = rH;
    obj.rhoa_dry = rhoa_dry;
    obj.rhoa_dry_kg = rhoa_dry_kg;
    obj.sw_incoming = sw_incoming;
    obj.sw_outgoing = sw_outgoing;
    obj.Tair_TOA5 = Tair_TOA5;
    obj.Tdry = Tdry;
    obj.timestamp = timestamp;
    obj.t_mean = t_mean;
    obj.t_meank = t_meank;
    obj.t_meanK = t_meanK;
    obj.u_mean = u_mean;
    obj.u_star = u_star;
    obj.wnd_dir_compass = wnd_dir_compass;
    obj.wnd_spd = wnd_spd;
    
end


end %methods

end %classdef

