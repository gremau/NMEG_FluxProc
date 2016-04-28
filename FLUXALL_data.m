classdef FLUXALL_data
% Class to represent UNM annual FLUXALL file data.
%
% this class is meant to unify the Matlab representation of data in the
% (pre-2012) Excel spreadsheet fluxall files and the 2012-present delimited
% ASCII fluxall files.  It is a work in progress (As of Aug 2013).  The idea is
% to provide storage for all of the data that might be present in a given
% fluxall files and methods to read both fluxall formats (currently performed by
% the file parsing parts of UNM_RemoveBadData).  Then RemoveBadData would do
% just that - remove the bad data.

properties
    
    sitecode;
    year_arg;
    
    %observed data
    obs = struct;  % struct to contain observations
    ds_soil;
end

properties ( SetAccess = private, GetAccess = private )
    % this stuff is internal to the class
    datalength;
    binary_fluxall_fname;
    draw_plots;
    process_soil_data;
    write_mat_file = true;
end

methods
    % --------------------------------------------------
        function [ obj ] = FLUXALL_data( sitecode, year_arg, varargin )
        % class constructor.
        % If year_arg < 2012, loads matlab binary of parsed excel data.
        % USAGE:
        %   FA = FLUXALL_data( sitecode, year_arg );
        %   FA = FLUXALL_data( sitecode, year_arg, 'load_binary', false );
        %   FA = FLUXALL_data( sitecode, year_arg, ..., 'draw_plots', false );
        %   FA = FLUXALL_data( sitecode, year_arg, ..., 'process_soil_data', false );
        %
        % INPUTS
        %   sitecode
        %   year_arg
        % KEYWORD ARGUMENTS
        %   load_binary; logical, default true
        %   draw_plots; logical, default true
        %   process_soil_data; logical, default true
        %
        % author: Timothy W. Hilton, UNM, 2013


        args = inputParser;
        args.addRequired( 'sitecode', @( x ) isa( x, 'UNM_sites' ) );
        args.addRequired( 'year_arg', @isnumeric );
        args.addParamValue( 'load_binary', true, @islogical );
        args.addParamValue( 'draw_plots', true, @islogical );
        args.addParamValue( 'process_soil_data', true, @islogical );
        args.parse( sitecode, year_arg, varargin{ : } );
        
        % construct filename for a binary representation of fluxall data
        site_str = char( UNM_sites( args.Results.sitecode ) );
        binary_fluxall_fname = fullfile( getenv( 'FLUXROOT' ), ...
                                         'SiteData', ...
                                         site_str, ...
                                         sprintf( '%s_flux_all_%d.mat', ...
                                                  site_str, ...
                                                  args.Results.year_arg ) );
        obj.binary_fluxall_fname = binary_fluxall_fname;
        
        if args.Results.load_binary
            try 
                load( binary_fluxall_fname );
                obj = FA_data;
                obj.binary_fluxall_fname = binary_fluxall_fname;
                fprintf( 'loaded %s\n', binary_fluxall_fname );
            catch err
                fprintf( 'Unable to open %s\n', binary_fluxall_fname );
                rethrow( err );
            end
        else
            % construct object from FLUXALL file
            obj.sitecode = args.Results.sitecode;
            obj.year_arg = args.Results.year_arg;
            obj.draw_plots = args.Results.draw_plots;
            obj.process_soil_data = args.Results.process_soil_data;
            
            % initialize observations to fields that should becommon to all
            % site-years
            obj = obj.initialize_FLUXALL_vars();
            
            % parse the data -- Excel FLUXALL files pre-2012, ASCII text files
            % for 2012 and later
            if obj.year_arg < 2012 
                obj = obj.FLUXALL_data_intake_pre2012( );
            end

            % create a timestamp variable
            obj.obs.decimal_day = obj.obs.timestamp - ...
                datenum( args.Results.year_arg, 1, 0 );
            
            % write FLUXALL data to matlab binary .mat file
            if obj.write_mat_file
                obj.write_fluxall_binary_file();
            end
            
        end % if args.Results.load_binary
        
        end  %constructor
    
    % --------------------------------------------------
    
        function success = write_fluxall_binary_file( obj )
        % WRITE_FLUXALL_BINARY_FILE - write a binary representation of the fluxall data
        %   to a .mat file

        
        FA_data = obj;
        save( obj.binary_fluxall_fname, 'FA_data' );
        fprintf( 'wrote %s\n', obj.binary_fluxall_fname );
        
        end

    % --------------------------------------------------
    
        function obj = initialize_FLUXALL_vars( obj )
        % INITIALIZE_FLUXALL_VARS - returns a struct with empty variables to populate

        obj.obs = struct( 'air_temp_hmp', [], ...
                          'atm_press', [], ...
                          'agc_Avg', [], ...
                          'CNR1TK', [], ...
                          'CO2_mean', [], ...
                          'CO2_std', [], ...
                          'decimal_day', [], ...
                          'E_heat_term_massman', [], ...
                          'E_raw', [], ...
                          'E_raw_massman', [], ...
                          'E_water_term', [], ...
                          'E_wpl_massman', [], ...
                          'fc_heat_term_massman', [], ...
                          'fc_raw', [], ...
                          'fc_raw_massman', [], ...
                          'fc_raw_massman_wpl', [], ...
                          'fc_water_term', [], ...
                          'H2O_mean', [], ...
                          'h2o_hmp', [], ...
                          'H2O_std', [], ...
                          'HL_raw', [], ...
                          'HL_wpl_massman', [], ...
                          'HSdry', [], ...
                          'HSdry_massman', [], ...
                          'iok', [], ...
                          'lw_incoming', [], ...
                          'lw_outgoing', [], ...
                          'NR_tot', [], ...
                          'Par_Avg', [], ...
                          'precip', [], ...
                          'rH', [], ...
                          'rhoa_dry', [], ...
                          'rhoa_dry_kg', [], ...
                          'sw_incoming', [], ...
                          'sw_outgoing', [], ...
                          'Tair_TOA5', [], ...
                          'Tdry', [], ...
                          'Tsoil', [], ...
                          't_mean', [], ...
                          'timestamp', [], ...
                          'u_mean', [], ...
                          'u_star', [], ...
                          'wnd_dir_compass', [], ...
                          'wnd_spd', [] );
        end % initialize_FLUXALL_vars
    
    % --------------------------------------------------
    
        function obj = FLUXALL_data_intake_pre2012( obj )
        %FLUXALL_DATA_INTAKE_PRE2012 - obtains the FLUXDATA for site-years prior to
        %   2012.

        RBDrc = UNM_RBD_config( obj.sitecode, obj.year_arg );

        row1=5;  %first row of data to process - rows 1 - 4 are header
        filename = strcat( char( obj.sitecode ),'_flux_all_',num2str(obj.year_arg));
        %filename = strcat(site,'_new_radiation_flux_all_',num2str(year))
        filelength = num2str(RBDrc.filelength_n);
        %datalength = RBDrc.filelength_n - row1 + 1; 
        filein = fullfile( getenv( 'FLUXROOT' ), ...
                           'SiteData', ...
                           char( obj.sitecode ), ...
                           filename );
        range = strcat('B',num2str(row1),':',RBDrc.lastcolumn,filelength);
        headerrange = sprintf( 'A2:%s5',RBDrc.lastcolumn );
        time_stamp_range = strcat('A5:A',filelength);
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Open file and parse out dates and times
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        
        
        disp('reading data...')

        [ num, headertext ] = xlsread( filein, headerrange );
        headertext = fluxall_extract_column_headers( headertext );
        empty_headers = find( cellfun( @isempty, headertext ) );
        dummyheaders = arrayfun( @(x) sprintf('Col_%03d', x), ...
                                 empty_headers( : ), ...
                                 'UniformOutput', false );
        headertext( empty_headers ) = dummyheaders;

        %does not read in first column because it's text!!!!!!!!
        [num xls_text] = xlsread(filein,range);  
        data = num;
        ncol = size(data,2)+1;
        obj.datalength = size(data,1);
        [num xls_text] = xlsread(filein,time_stamp_range);
        timestamp = xls_text;
        [year month day hour minute second] = datevec(timestamp);
        obj.obs.timestamp = datenum(timestamp);
        disp('file read');
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % some siteyears have periods where the observed radition does not line
        % up with sunrise.  Fix this here so that the matched time/radiation
        % propagates through the rest of the calculations
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        data = UNM_fix_datalogger_timestamps( obj.sitecode, ...
                                              obj.year_arg, ...
                                              data, ...
                                              headertext, ...
                                              obj.obs.timestamp, ...
                                              'debug', obj.draw_plots );
        if ( obj.sitecode == UNM_sites.MCon ) & ...
                ( obj.year_arg <= 2008 )
            data = revise_MCon_duplicated_Rg( data, headertext, obj.obs.timestamp );
        end 
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % populate obj.obs from the parsed excel data
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        obj = obj.fluxall_data_to_matlab_vars_pre2012( data, headertext );

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % locate and smooth soil variables
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        if obj.process_soil_data
            var_names = genvarname( headertext( 2:end ) );
            ds = dataset( { data, var_names{ : } } );
            ds.timestamp = obj.obs.timestamp;
            obj.ds_soil = UNM_Ameriflux_prepare_soil_met( obj.sitecode, ...
                                                          obj.year_arg, ...
                                                          ds, ...
                                                          obj.obs.precip );
        end
        
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % variables that aren't present in FLUXALL get filled with NaN
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        obj = obj.put_nans_in_missing_variables( size( data, 1 ) );
        
        end %function FLUXALL_data_intake_pre2012

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
                obj.obs.iok=data(:,9);
                obj.obs.Tdry=data(:,14);
                obj.obs.wnd_dir_compass=data(:,15);
                obj.obs.wnd_spd=data(:,16);
                obj.obs.u_star=data(:,28);
                obj.obs.CO2_mean=data(:,32);
                obj.obs.CO2_std=data(:,33);
                obj.obs.H2O_mean=data(:,37);
                obj.obs.H2O_std=data(:,38);
                obj.obs.u_mean=data(:,10);
                obj.obs.t_mean=data(:,13);

                obj.obs.fc_raw = data(:,39);
                obj.obs.fc_raw_massman = data(:,40);
                obj.obs.fc_water_term = data(:,41);
                obj.obs.fc_heat_term_massman = data(:,42);
                obj.obs.fc_raw_massman_wpl = data(:,43); % = flux_co2_massman + flux_co2_wpl_water + flux_co2_massman_wpl_heat

                obj.obs.E_raw = data(:,44);
                obj.obs.E_raw_massman = data(:,45);
                obj.obs.E_water_term = data(:,46);
                obj.obs.E_heat_term_massman = data(:,47);
                obj.obs.E_wpl_massman = data(:,48); % = flux_h20_wpl_water + flux_h20_massman_wpl_heat

                obj.obs.HSdry = data(:,50);
                obj.obs.HSdry_massman = data(:,53);

                obj.obs.HL_raw = data(:,54);
                obj.obs.HL_wpl_massman = data(:,56);
                HL_wpl_massman_un = repmat( NaN, size( data, 1 ), 1 );
                % Half hourly data filler only produces uncorrected obj.obs.HL_wpl_massman, but use
                % these where available
                %obj.obs.HL_wpl_massman(isnan(obj.obs.HL_wpl_massman)&~isnan(HL_wpl_massman_un))=HL_wpl_massman_un(isnan(obj.obs.HL_wpl_massman)&~isnan(HL_wpl_massman_un));

                obj.obs.rhoa_dry = data(:,57);

                for i=1:numel( headertext );
                    if strcmp('RH',headertext(i)) == 1 || strcmp('rh_hmp', headertext(i)) == 1 || strcmp('rh_hmp_4_Avg', headertext(i)) == 1
                        obj.obs.rH = data(:,i-1);
                    end
                end


            elseif obj.year_arg < 2009 && obj.sitecode ~=  UNM_sites.JSav 
                if obj.sitecode ==  UNM_sites.TX && obj.year_arg == 2008 % This is set up for 2009 output
                    disp('TX 2008 is set up as 2009 output');
                    %stop
                end
                
                jday=data(:,8);
                obj.obs.iok=data(:,9);
                obj.obs.Tdry=data(:,14);
                obj.obs.wnd_dir_compass=data(:,15);
                obj.obs.wnd_spd=data(:,16);
                obj.obs.u_star=data(:,27);
                obj.obs.CO2_mean=data(:,31);
                obj.obs.CO2_std=data(:,32);
                obj.obs.H2O_mean=data(:,36);
                obj.obs.H2O_std=data(:,37);
                obj.obs.u_mean=data(:,10);
                obj.obs.t_mean=data(:,13);

                obj.obs.fc_raw = data(:,40);
                obj.obs.fc_raw_massman = data(:,44);
                obj.obs.fc_water_term = data(:,42);
                obj.obs.fc_heat_term_massman = data(:,45);
                obj.obs.fc_raw_massman_wpl = data(:,46); % = flux_co2_massman + flux_co2_wpl_water + flux_co2_massman_wpl_heat

                obj.obs.E_raw = data(:,49);
                obj.obs.E_raw_massman = data(:,53);
                obj.obs.E_water_term = data(:,51);
                obj.obs.E_heat_term_massman = data(:,54);
                obj.obs.E_wpl_massman = data(:,55); % = flux_h20_wpl_water + flux_h20_massman_wpl_heat

                obj.obs.HSdry = data(:,56);
                obj.obs.HSdry_massman = data(:,59);

                obj.obs.HL_raw = data(:,61);
                obj.obs.HL_wpl_massman = data(:,64);
                HL_wpl_massman_un = data(:,63);
                % Half hourly data filler only produces uncorrected obj.obs.HL_wpl_massman, but use
                % these where available
                obj.obs.HL_wpl_massman(isnan(obj.obs.HL_wpl_massman)&~isnan(HL_wpl_massman_un))=HL_wpl_massman_un(isnan(obj.obs.HL_wpl_massman)&~isnan(HL_wpl_massman_un));

                obj.obs.rhoa_dry = data(:,65);

                for i=1:numel( headertext );
                    if strcmp('RH',headertext(i)) == 1 || strcmp('rh_hmp', headertext(i)) == 1 || strcmp('rh_hmp_4_Avg', headertext(i)) == 1
                        obj.obs.rH = data(:,i-1);
                    end
                end

                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            else  %JSav pre-2009
                
                jday=data(:,8);
                obj.obs.iok=data(:,9);
                obj.obs.Tdry=data(:,14);
                obj.obs.wnd_dir_compass=data(:,15);
                obj.obs.wnd_spd=data(:,16);
                obj.obs.u_star=data(:,28);
                obj.obs.CO2_mean=data(:,32);
                obj.obs.CO2_std=data(:,33);
                obj.obs.H2O_mean=data(:,37);
                obj.obs.H2O_std=data(:,38);
                obj.obs.u_mean=data(:,10);
                obj.obs.t_mean=data(:,13);

                obj.obs.fc_raw = data(:,39);
                obj.obs.fc_raw_massman = data(:,40);
                obj.obs.fc_water_term = data(:,41);
                obj.obs.fc_heat_term_massman = data(:,42);
                obj.obs.fc_raw_massman_wpl = data(:,43); % = flux_co2_massman + flux_co2_wpl_water + flux_co2_massman_wpl_heat

                obj.obs.E_raw = data(:,44);
                obj.obs.E_raw_massman = data(:,45);
                obj.obs.E_water_term = data(:,46);
                obj.obs.E_heat_term_massman = data(:,47);
                obj.obs.E_wpl_massman = data(:,48);

                obj.obs.HSdry = data(:,50);
                obj.obs.HSdry_massman = data(:,53);

                obj.obs.HL_raw = data(:,54);
                obj.obs.HL_wpl_massman = data(:,56);
                HL_wpl_massman_un = data(:,55);
                % Half hourly data filler only produces uncorrected obj.obs.HL_wpl_massman, but use
                % these where available as very similar values
                obj.obs.HL_wpl_massman(isnan(obj.obs.HL_wpl_massman)&~isnan(HL_wpl_massman_un))=HL_wpl_massman_un(isnan(obj.obs.HL_wpl_massman)&~isnan(HL_wpl_massman_un));

                obj.obs.rhoa_dry = data(:,57);

            end

            %initialize RH to NaN
            obj.obs.rH = repmat( NaN, size( data, 1), 1 );

            % filter out absurd u_star values
            obj.obs.u_star( obj.obs.u_star > 50 ) = NaN;

            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % Read in 30-min data, variable order and names in flux_all files are not  
            % consistent so match headertext
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

            for i=1:numel( headertext );
                if strcmp('agc_Avg',headertext(i)) == 1
                    obj.obs.agc_Avg = data(:,i-1);
                elseif strcmp( 'h2o_hmp_Avg', headertext( i ) )
                    obj.obs.h2o_hmp = data( :, i-1 );
                elseif strcmp('RH',headertext(i)) == 1 || ...
                        strcmp('rh_hmp', headertext(i)) == 1 || ...
                        strcmp('rh_hmp_4_Avg', headertext(i)) == 1 || ...
                        strcmp('RH_Avg', headertext(i)) == 1
                    obj.obs.rH = data(:,i-1) / 100.0;
                elseif strcmp( 'Ts_mean', headertext( i ) )
                    obj.obs.Tair_TOA5 = data(:,i-1);
                elseif  strcmp('5point_precip', headertext(i)) == 1 || ...
                        strcmp('rain_Tot', headertext(i)) == 1 || ...
                        strcmp('precip', headertext(i)) == 1 || ...
                        strcmp('precip(in)', headertext(i)) == 1 || ...
                        strcmp('ppt', headertext(i)) == 1 || ...
                        strcmp('Precipitation', headertext(i)) == 1
                    obj.obs.precip = data(:,i-1);
                elseif strcmp('press_mean', headertext(i)) == 1 || ...
                        strcmp('press_Avg', headertext(i)) == 1 || ...
                        strcmp('press_a', headertext(i)) == 1 || ...
                        strcmp('press_mean', headertext(i)) == 1
                    obj.obs.atm_press = data(:,i-1);
                elseif strcmp('par_correct_Avg', headertext(i)) == 1  || ...
                        strcmp('par_Avg(1)', headertext(i)) == 1 || ...
                        strcmp('par_Avg_1', headertext(i)) == 1 || ...
                        strcmp('par_Avg', headertext(i)) == 1 || ...
                        strcmp('par_up_Avg', headertext(i)) == 1 || ...        
                        strcmp('par_face_up_Avg', headertext(i)) == 1 || ...
                        strcmp('par_incoming_Avg', headertext(i)) == 1 || ...
                        strcmp('par_lite_Avg', headertext(i)) == 1
                    obj.obs.Par_Avg = data(:,i-1);
                elseif strcmp('t_hmp_mean', headertext(i))==1 || ...
                        strcmp('AirTC_Avg', headertext(i))==1 || ...
                        strcmp('t_hmp_3_Avg', headertext(i))==1 || ...
                        strcmp('pnl_tmp_a', headertext(i))==1 || ...
                        strcmp('t_hmp_Avg', headertext(i))==1 || ...
                        strcmp('t_hmp_4_Avg', headertext(i))==1 || ...
                        strcmp('t_hmp_top_Avg', headertext(i))==1
                    obj.obs.air_temp_hmp = data(:,i-1);
                elseif strcmp('AirTC_2_Avg', headertext(i))==1 && ...
                        (obj.year_arg == 2009 || ...
                         obj.year_arg ==2010) && ( obj.sitecode == UNM_sites.MCon)
                    obj.obs.air_temp_hmp = data(:,i-1);
                elseif strcmp('Tsoil',headertext(i)) == 1 || ...
                        strcmp('Tsoil_avg',headertext(i)) == 1 || ...
                        strcmp('soilT_Avg(1)',headertext(i)) == 1
                    obj.obs.Tsoil = data(:,i-1);
                elseif strcmp('Rn_correct_Avg',headertext(i))==1 || ...
                        strcmp('NR_surf_AVG', headertext(i))==1 || ...
                        strcmp('NetTot_Avg_corrected', headertext(i))==1 || ...
                        strcmp('NetTot_Avg', headertext(i))==1 || ...
                        strcmp('Rn_Avg',headertext(i))==1 || ...
                        strcmp('Rn_total_Avg',headertext(i))==1
                    obj.obs.NR_tot = data(:,i-1);
                elseif strcmp('Rad_short_Up_Avg', headertext(i)) || ...
                        strcmp('pyrr_incoming_Avg', headertext(i))
                    obj.obs.sw_incoming = data(:,i-1);
                elseif strcmp('Rad_short_Dn_Avg', headertext(i))==1 || ...
                        strcmp('pyrr_outgoing_Avg', headertext(i))==1
                    obj.obs.sw_outgoing = data(:,i-1);
                elseif strcmp('Rad_long_Up_Avg', headertext(i)) == 1 || ...
                        strcmp('Rad_long_Up__Avg', headertext(i)) == 1
                    obj.obs.lw_incoming = data(:,i-1);
                elseif strcmp('Rad_long_Dn_Avg', headertext(i))==1 || ...
                        strcmp('Rad_long_Dn__Avg', headertext(i))==1
                    obj.obs.lw_outgoing = data(:,i-1);
                elseif strcmp('CNR1TC_Avg', headertext(i)) == 1 || ...
                        strcmp('Temp_C_Avg', headertext(i)) == 1
                    obj.obs.CNR1TK = data(:,i-1) + 273.15;
                elseif strcmp('VW_Avg', headertext(i))==1
                    obj.obs.VWC = data(:,i-1);
                elseif strcmp('shf_Avg(1)', headertext(i))==1 || ...
                        strcmp('shf_pinon_1_Avg', headertext(i))==1
                    obj.obs.soil_heat_flux_1 = data(:,i-1);
                    disp('FOUND shf_pinon_1_Avg');       
                elseif any( strcmp( headertext(i), ...
                                    { 'hfp_grass_1_Avg', 'hfp01_grass_Avg' } ) )
                    obj.obs.soil_heat_flux_1 = data(:,i-1);
                    disp('FOUND hfp_grass_1_Avg');       
                elseif any( strcmp( headertext( i ), ...
                                    { 'hfp_grass_2_Avg', 'hft3_grass_Avg' } ) )
                    obj.obs.soil_heat_flux_2 = data(:,i-1);
                    disp('FOUND hfp_grass_2_Avg');       
                elseif strcmp('shf_Avg(2)', headertext(i))==1 || ...
                        strcmp('shf_jun_1_Avg', headertext(i))==1
                    obj.obs.soil_heat_flux_2 = data(:,i-1);
                elseif strcmp('hfpopen_1_Avg', headertext(i))==1 % only for TX
                    obj.obs.soil_heat_flux_open = data(:,i-1);
                elseif strcmp('hfpmescan_1_Avg', headertext(i))==1 % only for TX
                    obj.obs.soil_heat_flux_mescan = data(:,i-1);
                elseif strcmp('hfpjuncan_1_Avg', headertext(i))==1 % only for TX
                    obj.obs.soil_heat_flux_juncan = data(:,i-1);
                    %Shurbland flux plates 2009 onwards
                elseif strcmp('hfp01_1_Avg', headertext(i))==1 
                    obj.obs.soil_heat_flux_1 = data(:,i-1);
                elseif strcmp('hfp01_2_Avg', headertext(i))==1 
                    obj.obs.soil_heat_flux_2 = data(:,i-1);
                elseif strcmp('hfp01_3_Avg', headertext(i))==1 
                    obj.obs.soil_heat_flux_3 = data(:,i-1);
                elseif strcmp('hfp01_4_Avg', headertext(i))==1 
                    obj.obs.soil_heat_flux_4 = data(:,i-1);
                elseif strcmp('hfp01_5_Avg', headertext(i))==1 
                    obj.obs.soil_heat_flux_5 = data(:,i-1);
                elseif strcmp('hfp01_6_Avg', headertext(i))==1 
                    obj.obs.soil_heat_flux_6 = data(:,i-1);
                elseif strcmp('shf_Avg(3)', headertext(i))==1 
                    obj.obs.soil_heat_flux_3 = data(:,i-1);
                elseif strcmp('shf_Avg(4)', headertext(i))==1 
                    obj.obs.soil_heat_flux_4 = data(:,i-1);
                    
                end

            end % headertext loop
            
            if ismember( obj.sitecode, ...
                         [ UNM_sites.GLand, UNM_sites.SLand ] ) & ...
                    obj.year_arg == 2009
                Par_Avg = combine_PARavg_PARlite( headertext, data );
            end
            
            if ismember( obj.sitecode, [ UNM_sites.JSav, UNM_sites.PJ ] )
                % use "RH" at JSav, PJ
                rh_col = find( strcmp( 'RH', headertext ) ) - 1;
                fprintf( 'found RH\n' );
                obj.obs.rH = data( :, rh_col ) / 100.0;
            elseif ismember( obj.sitecode, [ UNM_sites.PPine, UNM_sites.MCon ] )
                % use "RH_2" at PPine, MCon
                rh_col = find( strcmp( 'RH_2', headertext ) | ...
                               strcmp( 'RH_2_Avg', headertext ) ) - 1;
                if ~isempty( rh_col )
                    fprintf( 'found RH_2\n' );
                else
                    error( 'could not locate RH_2' );
                end
                obj.obs.rH = data( :, rh_col ) / 100.0;
            elseif obj.sitecode == UNM_sites.PJ_girdle
                % at PJ girdle, calculate relative humidity from hmp obs using helper
                % function
                obj.obs.rH = ...
                    thmp_and_h2ohmp_2_rhhmp( obj.obs.air_temp_hmp, ...
                                             obj.obs.h2o_hmp ) / 100.0;
            end % if ismember...
            
            
            end
        % --------------------------------------------------    
        
            function obj = FLUXALL_soil_data_intake_pre2012( obj, data, headertext )
            % FLUXALL_SOIL_DATA_INTAKE_PRE2012 - 
            %   
            
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % Site-specific steps for soil temperature
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            switch obj.sitecode
              case UNM_sites.GLand   %added TWH, 27 Oct 2011
                for i=1:numel( headertext );
                    if strcmp('TCAV_grass_Avg',headertext(i)) == 1
                        obj.obs.Tsoil = data(:,i-1);
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

              case UNM_sites.SLand   %added TWH, 4 Nov 2011
                for i=1:numel( headertext );
                    if strcmp( 'shf_sh_1_Avg', headertext( i ) ) == 1
                        soil_heat_flux_1 = data(:,i-1);
                    end    
                    if strcmp( 'shf_sh_2_Avg', headertext( i ) ) == 1
                        soil_heat_flux_2 = data(:,i-1);
                    end
                end
                SHF_labels = { 'shf_sh_1_Avg', 'shf_sh_2_Avg' };
                soil_heat_flux = [ soil_heat_flux_1, soil_heat_flux_1 ];

              case UNM_sites.JSav   %added TWH, 7 May 2012
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
                
                % Juniper S heat flux plates need multiplying by calibration factors
                soil_heat_flux_1 = soil_heat_flux_1.*32.27;
                soil_heat_flux_2 = soil_heat_flux_2.*33.00;
                soil_heat_flux_3 = soil_heat_flux_3.*31.60;
                soil_heat_flux_4 = soil_heat_flux_4.*32.20;
                
              case UNM_sites.PJ
                for i=1:numel( headertext );
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
                
                % Pinon Juniper heat flux plates need multiplying by calibration factors
                soil_heat_flux_1 = soil_heat_flux_1.*35.2;
                soil_heat_flux_2 = soil_heat_flux_2.*32.1;
                
              case { UNM_sites.PPine, UNM_sites.MCon }

                soil_heat_flux_1 = repmat( NaN, size( data, 1 ), 1 );
                nsoil_heat_flux_2 = soil_heat_flux_1;
                soil_heat_flux_3 = soil_heat_flux_1;

                for i=1:numel( headertext );
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
                
              case UNM_sites.TX
                for i=1:numel( headertext );
                    if strcmp('Tsoil_Avg(2)',headertext(i)) == 1
                        obj.obs.open_5cm = data(:,i-1);
                    elseif strcmp('Tsoil_Avg(3)',headertext(i)) == 1
                        obj.obs.open_10cm = data(:,i-1);
                    elseif strcmp('Tsoil_Avg(5)',headertext(i)) == 1
                        obj.obs.Mesquite_5cm = data(:,i-1);
                    elseif strcmp('Tsoil_Avg(6)',headertext(i)) == 1
                        obj.obs.Mesquite_10cm = data(:,i-1);
                    elseif strcmp('Tsoil_Avg(8)',headertext(i)) == 1
                        obj.obs.Juniper_5cm = data(:,i-1);
                    elseif strcmp('Tsoil_Avg(9)',headertext(i)) == 1
                        obj.obs.Juniper_10cm = data(:,i-1);
                    end
                end
                if args.Results.year == 2005 % juniper probes on-line after 5/19/05
                                             % before 5/19
                    obj.obs.canopy_5cm = Mesquite_5cm(find(decimal_day < 139.61));
                    obj.obs.canopy_10cm = Mesquite_10cm(find(decimal_day < 139.61));
                    % after 5/19
                    obj.obs.canopy_5cm(find(decimal_day >= 139.61)) = (Mesquite_5cm(find(decimal_day >= 139.61)) + Juniper_5cm(find(decimal_day >= 139.61)))/2;
                    obj.obs.canopy_10cm(find(decimal_day >= 139.61)) = (Mesquite_10cm(find(decimal_day >= 139.61)) + Juniper_10cm(find(decimal_day >= 139.61)))/2;
                    % clean strange 0 values
                    obj.obs.canopy_5cm(find(canopy_5cm == 0)) = NaN;
                    obj.obs.canopy_10cm(find(canopy_10cm == 0)) = NaN;
                    obj.obs.Tsoil = (open_5cm + canopy_5cm)./2;
                else
                    obj.obs.canopy_5cm = (Mesquite_5cm + Juniper_5cm)/2;
                    obj.obs.canopy_10cm = (Mesquite_10cm + Juniper_10cm)/2;
                    obj.obs.Tsoil = (open_5cm + canopy_5cm)/2;
                end
                
                % min/max QC for TX soil heat fluxes

                if args.Results.year == 2005
                    obj.obs.soil_heat_flux_open(find(soil_heat_flux_open > 100 | ...
                                                     soil_heat_flux_open < -50)) = NaN;
                    obj.obs.soil_heat_flux_mescan(find(soil_heat_flux_mescan > 50 | ...
                                                       soil_heat_flux_mescan < -40)) = NaN;
                    obj.obs.soil_heat_flux_juncan(find(soil_heat_flux_juncan > 50 | ...
                                                       soil_heat_flux_juncan < -60)) = NaN;
                elseif args.Results.year == 2006
                    obj.obs.soil_heat_flux_open(find(soil_heat_flux_open > 90 | ...
                                                     soil_heat_flux_open < -60)) = NaN;
                    obj.obs.soil_heat_flux_mescan(find(soil_heat_flux_mescan > 50 | ...
                                                       soil_heat_flux_mescan < -50)) = NaN;
                    soil_heat_flux_juncan(find(soil_heat_flux_juncan > 50 | ...
                                               soil_heat_flux_juncan < -60)) = NaN;
                elseif args.Results.year == 2007 
                    obj.obs.soil_heat_flux_open(find(soil_heat_flux_open > 110 | ...
                                                     soil_heat_flux_open < -50)) = NaN;
                    obj.obs.soil_heat_flux_mescan(find(soil_heat_flux_mescan > 40 | ...
                                                       soil_heat_flux_mescan < -40)) = NaN;
                    obj.obs.soil_heat_flux_juncan(find(soil_heat_flux_juncan > 20 | ...
                                                       soil_heat_flux_juncan < -40)) = NaN;
                end
                
              case { UNM_stes.PJ_girdle, UNM_sites.New_GLand }
                Tsoil=sw_incoming.*NaN;
                soil_heat_flux_1 =sw_incoming.*NaN;
                soil_heat_flux_2 =sw_incoming.*NaN;
                SHF_labels = { 'soil_heat_flux_1', 'soil_heat_flux_2' };
                soil_heat_flux = [ soil_heat_flux_1, soil_heat_flux_2 ];

            end   %switch obj.sitecode

            for i = 1:numel( SHF_labels )
                obj.obs.( SHF_labels{ i } ) = soil_heat_flux( :, i );
            end
            
            end % function obj = FLUXALL_soil_data_intake_pre2012( obj,        
            
            % --------------------------------------------------
            
                function Tsoil = get_avg_Tsoil( obj )
                % GET_AVG_TSOIL - returns average soil temperature (C) across all measurement
                %   depths, cover types
                dummy = repmat( NaN, numel( obj.obs.Tdry ), 1 );
                if isempty( obj.ds_soil )
                    Tsoil = dummy;
                else
                    Tsoil_vars = regexp_header_vars( obj.ds_soil, 'Tsoil_[0-9A-Za-z]+_Avg' );
                    if isempty( Tsoil_vars )
                        Tsoil = dummy;
                    else
                        Tsoil = nanmean( double( obj.ds_soil( :, Tsoil_vars ) ), 2 );
                    end
                end
                

                end % function Tsoil = get_avg_Tsoil( obj )
                
end % methods


methods( Access = private )
    
    % --------------------------------------------------
        function obj = put_nans_in_missing_variables( obj, nrow )
        % PUT_NANS_IN_MISSING_VARIABLES - looks at the data fields of obj, filling
        % with NaN any variables that were not populated during data intake. 
        %   
        
        dummy = repmat( NaN, nrow, 1 );
        flds = fieldnames( obj.obs );
        for i = 1:numel( flds )
            if isempty( obj.obs.( flds{ i } ) )
                fprintf( 'Field %s not found; inserting NaNs\n', flds{ i } );
                obj.obs.( flds{ i } ) = dummy;
            end
        end
        
        end

    
    % --------------------------------------------------
end %private methods

end %classdef

function headertext = fluxall_extract_column_headers( headertext )
% FLUXALL_EXTRACT_COLUMN_HEADERS - locate and return the column headers for a
%   fluxall xls file.  The headers for the Matlab sections and 30-minute
%   sections to not always appear on the same line, so locate them by searching
%   for the two "timestamp" headers.  Helper function for
%   UNM_parse_fluxall_xls_file.

[ row, col ] = find( cellfun( @(x) ~isempty(x), ...
                              regexpi( headertext, 'timestamp' ) ) );
headertext{ row(end), col(end) } = 'TOA5_timestamp';
headertext = [ headertext( row(1), col(1):col(end)-1 ), ...
               headertext( row(end), col(end):end ) ];
end

