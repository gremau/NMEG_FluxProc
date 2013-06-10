classdef FLUXALL_data

properties
    
    sitecode;
    year_arg;
    
    %observed data
    atm_press;
    CNR1TK;
    CO2_mean;
    decimal_day;
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
    HL_raw;
    HL_wpl_massman;
    HSdry;
    HSdry_massman;
    lw_incoming;
    lw_outgoing;
    NR_tot;
    Par_Avg;
    precip;
    rH;
    rhoa_dry;
    rhoa_dry_kg;
    sw_incoming;
    sw_outgoing;
    Tair_TOA5;
    Tdry;
    t_mean;
    timestamp;
    u_mean;
    u_star;
    wnd_dir_compass;
    wnd_spd;
end

methods
    % --------------------------------------------------
        function [ obj ] = FLUXALL_data( sitecode, year_arg, varargin )
        % class constructor.
        % If year_arg < 2012, loads matlab binary of parsed excel data.
        
        args = inputParser;
        args.addRequired( 'sitecode', @( x ) isa( x, 'UNM_sites' ) );
        args.addRequired( 'year_arg', @isnumeric );
        args.addParamValue( 'load_binary', true, @islogical );
        args.parse( sitecode, year_arg, varargin{ : } );
        
        obj.sitecode = args.Results.sitecode;
        obj.year_arg = args.Results.year_arg;
        
        if obj.year_arg < 2012 
            obj = obj.FLUXALL_data_intake_pre2012( args.Results.load_binary );
        end

        obj.decimal_day = obj.timestamp - ...
            datenum( args.Results.year_arg, 1, 0 );
        
        end
    % --------------------------------------------------
        
        function obj = FLUXALL_data_intake_pre2012( obj, load_binary )
        %FLUXALL_DATA_INTAKE_PRE2012 - obtains the FLUXDATA for site-years prior to
        %   2012.

        save_fname = fullfile( getenv( 'FLUXROOT' ), 'FluxallConvert', ...
                               sprintf( '%s_%d_FA_Convert.mat', ...
                                        char( obj.sitecode ), obj.year_arg ) );

        RBDrc = UNM_RBD_config( obj.sitecode, obj.year_arg );

        if not( load_binary )
            if obj.year_arg <= 2012
                row1=5;  %first row of data to process - rows 1 - 4 are header
                filename = strcat(site,'_flux_all_',num2str(year))
                %filename = strcat(site,'_new_radiation_flux_all_',num2str(year))
                filelength = num2str(RBDrc.filelength_n);
                %datalength = RBDrc.filelength_n - row1 + 1; 
                filein = fullfile( getenv( 'FLUXROOT' ), ...
                                   'Flux_Tower_Data_by_Site', ...
                                   site, ...
                                   filename );
                range = strcat('B',num2str(row1),':',RBDrc.lastcolumn,filelength);
                headerrange = strcat('B2:',RBDrc.lastcolumn,'2');
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
                obj.timestamp = datenum(timestamp);
                disp('file read');

                save( save_fname );
                fprintf( 'saved %s\n', save_fname );
            end
        else  %load binary data
            load( save_fname );
            obj.timestamp = datenumber;
        end

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % some siteyears have periods where the observed radition does not line
        % up with sunrise.  Fix this here so that the matched time/radiation
        % propagates through the rest of the calculations
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        data = UNM_fix_datalogger_timestamps( obj.sitecode, ...
                                              obj.year_arg, ...
                                              data, ...
                                              headertext, ...
                                              obj.timestamp, ...
                                              'debug', true );
        if ( obj.sitecode == UNM_sites.MCon ) & ...
                ( obj.year_arg <= 2008 )
            data = revise_MCon_duplicated_Rg( data, headertext, obj.timestamp );
        end 

        
        obj = obj.fluxall_data_to_matlab_vars_pre2012( data, headertext );
        obj = obj.put_nans_in_missing_variables( size( data, 1 ) );
        
        if not( load_binary )
            binary_fluxall_fname = strrep( filein, 'xls', 'mat' );
            keyboard();
            %save( binary_fluxall_fname, 'obj' );
        end
        
        end

    %------------------------------------------------------------

        function obj = fluxall_data_to_matlab_vars_pre2012( obj, data, headertext )
        % FLUXALL_DATA_TO_MATLAB_VARS - 
        %   
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Read in Matlab processed ts data (these are in the same columns for all
        % sites, so they can be just hard-wired in by column number
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        if ( obj.sitecode == UNM_sites.TX) & ( obj.year_arg == 2008 )

            jday=data(:,8);
            iok=data(:,9);
            obj.Tdry=data(:,14);
            obj.wnd_dir_compass=data(:,15);
            obj.wnd_spd=data(:,16);
            obj.u_star=data(:,28);
            obj.CO2_mean=data(:,32);
            CO2_std=data(:,33);
            obj.H2O_mean=data(:,37);
            H2O_std=data(:,38);
            obj.u_mean=data(:,10);
            obj.t_mean=data(:,13);

            obj.fc_raw = data(:,39);
            obj.fc_raw_massman = data(:,40);
            obj.fc_water_term = data(:,41);
            obj.fc_heat_term_massman = data(:,42);
            obj.fc_raw_massman_wpl = data(:,43); % = flux_co2_massman + flux_co2_wpl_water + flux_co2_massman_wpl_heat

            E_raw = data(:,44);
            E_raw_massman = data(:,45);
            obj.E_water_term = data(:,46);
            obj.E_heat_term_massman = data(:,47);
            obj.E_wpl_massman = data(:,48); % = flux_h20_wpl_water + flux_h20_massman_wpl_heat

            obj.HSdry = data(:,50);
            obj.HSdry_massman = data(:,53);

            obj.HL_raw = data(:,54);
            obj.HL_wpl_massman = data(:,56);
            HL_wpl_massman_un = repmat( NaN, size( data, 1 ), 1 );
            % Half hourly data filler only produces uncorrected obj.HL_wpl_massman, but use
            % these where available
            %obj.HL_wpl_massman(isnan(obj.HL_wpl_massman)&~isnan(HL_wpl_massman_un))=HL_wpl_massman_un(isnan(obj.HL_wpl_massman)&~isnan(HL_wpl_massman_un));

            obj.rhoa_dry = data(:,57);

            for i=1:numel( headertext );
                if strcmp('RH',headertext(i)) == 1 || strcmp('rh_hmp', headertext(i)) == 1 || strcmp('rh_hmp_4_Avg', headertext(i)) == 1
                    obj.rH = data(:,i-1);
                end
            end


        elseif obj.year_arg < 2009 && obj.sitecode ~= 3 
            if obj.sitecode == 7 && obj.year_arg == 2008 % This is set up for 2009 output
                disp('TX 2008 is set up as 2009 output');
                %stop
            end
            
            jday=data(:,8);
            iok=data(:,9);
            obj.Tdry=data(:,14);
            obj.wnd_dir_compass=data(:,15);
            obj.wnd_spd=data(:,16);
            obj.u_star=data(:,27);
            obj.CO2_mean=data(:,31);
            CO2_std=data(:,32);
            obj.H2O_mean=data(:,36);
            H2O_std=data(:,37);
            obj.u_mean=data(:,10);
            obj.t_mean=data(:,13);

            obj.fc_raw = data(:,40);
            obj.fc_raw_massman = data(:,44);
            obj.fc_water_term = data(:,42);
            obj.fc_heat_term_massman = data(:,45);
            obj.fc_raw_massman_wpl = data(:,46); % = flux_co2_massman + flux_co2_wpl_water + flux_co2_massman_wpl_heat

            E_raw = data(:,49);
            E_raw_massman = data(:,53);
            obj.E_water_term = data(:,51);
            obj.E_heat_term_massman = data(:,54);
            obj.E_wpl_massman = data(:,55); % = flux_h20_wpl_water + flux_h20_massman_wpl_heat

            obj.HSdry = data(:,56);
            obj.HSdry_massman = data(:,59);

            obj.HL_raw = data(:,61);
            obj.HL_wpl_massman = data(:,64);
            HL_wpl_massman_un = data(:,63);
            % Half hourly data filler only produces uncorrected obj.HL_wpl_massman, but use
            % these where available
            obj.HL_wpl_massman(isnan(obj.HL_wpl_massman)&~isnan(HL_wpl_massman_un))=HL_wpl_massman_un(isnan(obj.HL_wpl_massman)&~isnan(HL_wpl_massman_un));

            obj.rhoa_dry = data(:,65);

            for i=1:numel( headertext );
                if strcmp('RH',headertext(i)) == 1 || strcmp('rh_hmp', headertext(i)) == 1 || strcmp('rh_hmp_4_Avg', headertext(i)) == 1
                    obj.rH = data(:,i-1);
                end
            end

            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        else  %JSav pre-2009
            
            jday=data(:,8);
            iok=data(:,9);
            obj.Tdry=data(:,14);
            obj.wnd_dir_compass=data(:,15);
            obj.wnd_spd=data(:,16);
            obj.u_star=data(:,28);
            obj.CO2_mean=data(:,32);
            CO2_std=data(:,33);
            obj.H2O_mean=data(:,37);
            H2O_std=data(:,38);
            obj.u_mean=data(:,10);
            obj.t_mean=data(:,13);

            obj.fc_raw = data(:,39);
            obj.fc_raw_massman = data(:,40);
            obj.fc_water_term = data(:,41);
            obj.fc_heat_term_massman = data(:,42);
            obj.fc_raw_massman_wpl = data(:,43); % = flux_co2_massman + flux_co2_wpl_water + flux_co2_massman_wpl_heat

            E_raw = data(:,44);
            E_raw_massman = data(:,45);
            obj.E_water_term = data(:,46);
            obj.E_heat_term_massman = data(:,47);
            obj.E_wpl_massman = data(:,48);

            obj.HSdry = data(:,50);
            obj.HSdry_massman = data(:,53);

            obj.HL_raw = data(:,54);
            obj.HL_wpl_massman = data(:,56);
            HL_wpl_massman_un = data(:,55);
            % Half hourly data filler only produces uncorrected obj.HL_wpl_massman, but use
            % these where available as very similar values
            obj.HL_wpl_massman(isnan(obj.HL_wpl_massman)&~isnan(HL_wpl_massman_un))=HL_wpl_massman_un(isnan(obj.HL_wpl_massman)&~isnan(HL_wpl_massman_un));

            obj.rhoa_dry = data(:,57);

        end

        %initialize RH to NaN
        obj.rH = repmat( NaN, size( data, 1), 1 );

        % filter out absurd u_star values
        obj.u_star( obj.u_star > 50 ) = NaN;

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Read in 30-min data, variable order and names in flux_all files are not  
        % consistent so match headertext
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        for i=1:numel( headertext );
            if strcmp('agc_Avg',headertext(i)) == 1
                agc_Avg = data(:,i-1);
            elseif strcmp( 'h2o_hmp_Avg', headertext( i ) )
                h2o_hmp = data( :, i-1 );
            elseif strcmp('RH',headertext(i)) == 1 || ...
                    strcmp('rh_hmp', headertext(i)) == 1 || ...
                    strcmp('rh_hmp_4_Avg', headertext(i)) == 1 || ...
                    strcmp('RH_Avg', headertext(i)) == 1
                obj.rH = data(:,i-1) / 100.0;
            elseif strcmp( 'Ts_mean', headertext( i ) )
                obj.Tair_TOA5 = data(:,i-1);
            elseif  strcmp('5point_precip', headertext(i)) == 1 || ...
                    strcmp('rain_Tot', headertext(i)) == 1 || ...
                    strcmp('precip', headertext(i)) == 1 || ...
                    strcmp('precip(in)', headertext(i)) == 1 || ...
                    strcmp('ppt', headertext(i)) == 1 || ...
                    strcmp('Precipitation', headertext(i)) == 1
                obj.precip = data(:,i-1);
            elseif strcmp('press_mean', headertext(i)) == 1 || ...
                    strcmp('press_Avg', headertext(i)) == 1 || ...
                    strcmp('press_a', headertext(i)) == 1 || ...
                    strcmp('press_mean', headertext(i)) == 1
                obj.atm_press = data(:,i-1);
            elseif strcmp('par_correct_Avg', headertext(i)) == 1  || ...
                    strcmp('par_Avg(1)', headertext(i)) == 1 || ...
                    strcmp('par_Avg_1', headertext(i)) == 1 || ...
                    strcmp('par_Avg', headertext(i)) == 1 || ...
                    strcmp('par_up_Avg', headertext(i)) == 1 || ...        
                    strcmp('par_face_up_Avg', headertext(i)) == 1 || ...
                    strcmp('par_incoming_Avg', headertext(i)) == 1 || ...
                    strcmp('par_lite_Avg', headertext(i)) == 1
                obj.Par_Avg = data(:,i-1);
            elseif strcmp('t_hmp_mean', headertext(i))==1 || ...
                    strcmp('AirTC_Avg', headertext(i))==1 || ...
                    strcmp('t_hmp_3_Avg', headertext(i))==1 || ...
                    strcmp('pnl_tmp_a', headertext(i))==1 || ...
                    strcmp('t_hmp_Avg', headertext(i))==1 || ...
                    strcmp('t_hmp_4_Avg', headertext(i))==1 || ...
                    strcmp('t_hmp_top_Avg', headertext(i))==1
                air_temp_hmp = data(:,i-1);
            elseif strcmp('AirTC_2_Avg', headertext(i))==1 && ...
                    (obj.year_arg == 2009 || ...
                     obj.year_arg ==2010) && obj.sitecode == 6
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
                obj.NR_tot = data(:,i-1);
            elseif strcmp('Rad_short_Up_Avg', headertext(i)) || ...
                    strcmp('pyrr_incoming_Avg', headertext(i))
                obj.sw_incoming = data(:,i-1);
            elseif strcmp('Rad_short_Dn_Avg', headertext(i))==1 || ...
                    strcmp('pyrr_outgoing_Avg', headertext(i))==1
                obj.sw_outgoing = data(:,i-1);
            elseif strcmp('Rad_long_Up_Avg', headertext(i)) == 1 || ...
                    strcmp('Rad_long_Up__Avg', headertext(i)) == 1
                obj.lw_incoming = data(:,i-1);
            elseif strcmp('Rad_long_Dn_Avg', headertext(i))==1 || ...
                    strcmp('Rad_long_Dn__Avg', headertext(i))==1
                obj.lw_outgoing = data(:,i-1);
            elseif strcmp('CNR1TC_Avg', headertext(i)) == 1 || ...
                    strcmp('Temp_C_Avg', headertext(i)) == 1
                obj.CNR1TK = data(:,i-1) + 273.15;
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

            if ismember( obj.sitecode, ...
                         [ UNM_sites.GLand, UNM_sites.SLand ] ) & ...
                    obj.year_arg == 2009
                Par_Avg = combine_PARavg_PARlite( headertext, data );
            end
            
            if ismember( obj.sitecode, [ UNM_sites.JSav, UNM_sites.PJ ] )
                % use "RH" at JSav, PJ
                rh_col = find( strcmp( 'RH', headertext ) ) - 1;
                fprintf( 'found RH\n' );
                obj.rH = data( :, rh_col ) / 100.0;
            elseif ismember( obj.sitecode, [ UNM_sites.PPine, UNM_sites.MCon ] )
                % use "RH_2" at PPine, MCon
                rh_col = find( strcmp( 'RH_2', headertext ) | ...
                               strcmp( 'RH_2_Avg', headertext ) ) - 1;
                if ~isempty( rh_col )
                    fprintf( 'found RH_2\n' );
                else
                    error( 'could not locate RH_2' );
                end
                obj.rH = data( :, rh_col ) / 100.0;
            elseif obj.sitecode == UNM_sites.PJ_girdle
                % at PJ girdle, calculate relative humidity from hmp obs using helper
                % function
                obj.rH = ...
                    thmp_and_h2ohmp_2_rhhmp( air_temp_hmp, h2o_hmp ) / 100.0;
            end
            
        end
            
        end
    
        function FLUXALL_soil_data_intake_pre2012( obj, data, headers )
        % FLUXALL_SOIL_DATA_INTAKE_PRE2012 - 
        %   
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Site-specific steps for soil temperature
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        if args.Results.sitecode == 1 %GLand   added TWH, 27 Oct 2011
            for i=1:ncol;
                if strcmp('TCAV_grass_Avg',headertext(i)) == 1
                    Tsoil = data(:,i-1);
                end
            end
            
            % find soil heat flux plate measurements
            SHF_idx = find( cellfun( @(x) ~isempty(x), ...
                                     regexp( headertext, 'hfp.*[Aa]vg' ) ) );
            if numel( SHF_idx ) ~= 2 
                %error( 'could not find two soil heat flux observations' );
            end
            soil_heat_flux = data( :, SHF_idx );
            SHF_labels = headertext( SHF_idx );
            SHF_labels = regexprep( SHF_labels, 'hfp01_(.*)', 'SHF_$1');

        elseif args.Results.sitecode == 2 %SLand   added TWH, 4 Nov 2011
            for i=1:ncol;
                if strcmp( 'shf_sh_1_Avg', headertext( i ) ) == 1
                    soil_heat_flux_1 = data(:,i-1);
                end    
                if strcmp( 'shf_sh_2_Avg', headertext( i ) ) == 1
                    soil_heat_flux_2 = data(:,i-1);
                end
            end
            SHF_labels = { 'shf_sh_1_Avg', 'shf_sh_2_Avg' };
            soil_heat_flux = [ soil_heat_flux_1, soil_heat_flux_1 ];

        elseif args.Results.sitecode == 3 %JSav   added TWH, 7 May 2012
            SHF_cols = find( ~cellfun( @isempty, regexp( headertext, 'shf_Avg.*' ) ) );
            soil_heat_flux = data( :, SHF_cols - 1 );
            if isempty( soil_heat_flux ) 
                soil_heat_flux = repmat( NaN, size( data, 1 ), 4 );
                soil_heat_flux_1 = soil_heat_flux( :, 1 );
                soil_heat_flux_2 = soil_heat_flux( :, 2 );
                soil_heat_flux_3 = soil_heat_flux( :, 3 );
                soil_heat_flux_4 = soil_heat_flux( :, 4 );
            end
            SHF_labels = { 'SHF_1', 'SHF_2', 'SHF_3', 'SHF_4' };

        elseif args.Results.sitecode == 4 %PJ
            for i=1:ncol;
                if strcmp('tcav_pinon_1_Avg',headertext(i)) == 1
                    Tsoil1 = data(:,i-1);
                elseif strcmp('tcav_jun_1_Avg',headertext(i)) == 1
                    Tsoil2 = data(:,i-1);
                end
            end
            if exist( 'Tsoil1' ) == 1 & exist( 'Tsoil2' ) == 1
                Tsoil = (Tsoil1 + Tsoil2)/2;
            else
                Tsoil = repmat( NaN, size( data, 1 ), 1 );
            end
            soil_heat_flux_1 = repmat( NaN, size( data, 1 ), 1 );
            soil_heat_flux_2 = repmat( NaN, size( data, 1 ), 1 );
            SHF_labels = { 'soil_heat_flux_1', 'soil_heat_flux_2' };
            soil_heat_flux = [ soil_heat_flux_1, soil_heat_flux_2 ];

            % related lines 678-682: corrections for site 4 (PJ) soil_heat_flux_1 and soil_heat_flux_2
            Tsoil=sw_incoming.*NaN;  %MF: note, this converts all values in Tsoil to NaN. Not sure if this was intended.
            
        elseif args.Results.sitecode == 5 || args.Results.sitecode == 6 % Ponderosa pine or Mixed conifer

            soil_heat_flux_1 = repmat( NaN, size( data, 1 ), 1 );
            soil_heat_flux_2 = soil_heat_flux_1;
            soil_heat_flux_3 = soil_heat_flux_1;

            for i=1:ncol;
                if strcmp('T107_C_Avg(1)',headertext(i)) == 1
                    Tsoil_2cm_1 = data(:,i-1);
                elseif strcmp('T107_C_Avg(2)',headertext(i)) == 1
                    Tsoil_2cm_2 = data(:,i-1);
                elseif strcmp('T107_C_Avg(3)',headertext(i)) == 1
                    Tsoil_6cm_1 = data(:,i-1);
                elseif strcmp('T107_C_Avg(4)',headertext(i)) == 1
                    Tsoil_6cm_2 = data(:,i-1);
                elseif strcmp('shf_Avg(1)',headertext(i)) == 1
                    soil_heat_flux_1 = data(:,i-1);
                elseif strcmp('shf_Avg(2)',headertext(i)) == 1
                    soil_heat_flux_2 = data(:,i-1);
                elseif strcmp('shf_Avg(3)',headertext(i)) == 1
                    soil_heat_flux_3 = data(:,i-1);
                end
            end
            Tsoil_2cm = (Tsoil_2cm_1 + Tsoil_2cm_2)/2;
            Tsoil_6cm = (Tsoil_6cm_1 + Tsoil_6cm_2)/2;
            Tsoil = Tsoil_2cm;

            SHF_labels = { 'soil_heat_flux_1', 'soil_heat_flux_2', 'soil_heat_flux_3' };
            soil_heat_flux = [ soil_heat_flux_1, soil_heat_flux_2, soil_heat_flux_3 ];
            
        elseif args.Results.sitecode == 7 % Texas Freeman
            for i=1:ncol;
                if strcmp('Tsoil_Avg(2)',headertext(i)) == 1
                    open_5cm = data(:,i-1);
                elseif strcmp('Tsoil_Avg(3)',headertext(i)) == 1
                    open_10cm = data(:,i-1);
                elseif strcmp('Tsoil_Avg(5)',headertext(i)) == 1
                    Mesquite_5cm = data(:,i-1);
                elseif strcmp('Tsoil_Avg(6)',headertext(i)) == 1
                    Mesquite_10cm = data(:,i-1);
                elseif strcmp('Tsoil_Avg(8)',headertext(i)) == 1
                    Juniper_5cm = data(:,i-1);
                elseif strcmp('Tsoil_Avg(9)',headertext(i)) == 1
                    Juniper_10cm = data(:,i-1);
                end
            end
            if args.Results.year == 2005 % juniper probes on-line after 5/19/05
                                         % before 5/19
                canopy_5cm = Mesquite_5cm(find(decimal_day < 139.61));
                canopy_10cm = Mesquite_10cm(find(decimal_day < 139.61));
                % after 5/19
                canopy_5cm(find(decimal_day >= 139.61)) = (Mesquite_5cm(find(decimal_day >= 139.61)) + Juniper_5cm(find(decimal_day >= 139.61)))/2;
                canopy_10cm(find(decimal_day >= 139.61)) = (Mesquite_10cm(find(decimal_day >= 139.61)) + Juniper_10cm(find(decimal_day >= 139.61)))/2;
                % clean strange 0 values
                canopy_5cm(find(canopy_5cm == 0)) = NaN;
                canopy_10cm(find(canopy_10cm == 0)) = NaN;
                Tsoil = (open_5cm + canopy_5cm)./2;
            else
                canopy_5cm = (Mesquite_5cm + Juniper_5cm)/2;
                canopy_10cm = (Mesquite_10cm + Juniper_10cm)/2;
                Tsoil = (open_5cm + canopy_5cm)/2;
            end
            
        elseif args.Results.sitecode == 10 || args.Results.sitecode == 11
            Tsoil=sw_incoming.*NaN;
            soil_heat_flux_1 =sw_incoming.*NaN;
            soil_heat_flux_2 =sw_incoming.*NaN;
            SHF_labels = { 'soil_heat_flux_1', 'soil_heat_flux_2' };
            soil_heat_flux = [ soil_heat_flux_1, soil_heat_flux_2 ];
        end


        % Juniper S heat flux plates need multiplying by calibration factors
        if args.Results.sitecode == 3
            soil_heat_flux_1 = soil_heat_flux_1.*32.27;
            soil_heat_flux_2 = soil_heat_flux_2.*33.00;
            soil_heat_flux_3 = soil_heat_flux_3.*31.60;
            soil_heat_flux_4 = soil_heat_flux_4.*32.20;
        end

        % Pinon Juniper heat flux plates need multiplying by calibration factors
        if args.Results.sitecode == 4 
            
            soil_heat_flux_1 = soil_heat_flux_1.*35.2;
            soil_heat_flux_2 = soil_heat_flux_2.*32.1;
        end


    
        end


end %methods

methods( Access = private )
        
    % --------------------------------------------------
        function obj = put_nans_in_missing_variables( obj, nrow )
        % PUT_NANS_IN_MISSING_VARIABLES - looks at the data fields of obj, filling
        % with NaN any variables that were not populated during data intake. 
        %   
    
        non_data_vars = { 'sitecode', 'year_arg' };
        data_vars = setdiff( fieldnames( obj ), non_data_vars );
        dummy = repmat( NaN, nrow, 1 );
        for i = 1:numel( data_vars )
            if isempty( obj.( data_vars{ i } ) )
                obj.( data_vars{ i } ) = dummy;
            end
        end
        
        end

    
    % --------------------------------------------------
end %private methods

end %classdef

