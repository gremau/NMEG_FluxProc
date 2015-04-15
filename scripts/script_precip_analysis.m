function [] = script_precip_analysis()

% sitelist = {UNM_sites.MCon, UNM_sites.PJ,...
%     UNM_sites.PPine, , UNM_sites.PJ_girdle, UNM_sites.SLand, UNM_sites.JSav, UNM_sites.GLand};
sitelist = {UNM_sites.GLand};
yearlist = 2007;
count = 1;
this_soildat = []


for i = 1:length(sitelist)
    for j = 1:length(yearlist)
        % Set site and year
        sitecode = sitelist{i};
        year = yearlist(j);
        
        % initialize
        filled_file_false = false;
        
        %--------------------------------------------------
        % parse unfilled data from requested site
        
        fprintf( 'parsing %s_flux_all_%d_for_gapfilling.txt ("destination")\n', ...
            get_site_name( sitecode ), year );
        thisData = parse_forgapfilling_file( sitecode, year, ...
            'use_filled', filled_file_false );
        thisData = dataset2table(thisData);
        
        this_qc = UNM_parse_QC_txt_file(sitecode, year);
        
        if year < 2013
            soilFname = fullfile(getenv('FLUXROOT'), 'Ameriflux_files', 'Original',...
                sprintf('%s_%d_soil.txt', UNM_sites_info(sitecode).ameriflux, year));
            this_soildat = parse_ameriflux_file( soilFname);
            this_soildat.timestamp = this_soildat.DOY + (datenum(year, 1, 1) - 1);
        end
        
        %--------------------------------------------------
        % Select data with which to fill T, RH, Rg and precip
        
        NMEG_site = [];
        SevMet_site = [];
        VCMet = [];
        GHCND_site = [];
        SNOTEL_site = [];
        
        switch sitecode
            case UNM_sites.GLand    % fill GLand from SLand, then
                % (# 40)
                NMEG_site = 2; % SLand
                if year < 2014; % no sev met data available for 2014 yet
                    SevMet_site = 40; % Sev Deep Well station
                end
                
            case UNM_sites.SLand   % Fill SLand from GLand and Sev Five Points stn
                NMEG_site = 1; % GLand
                if year < 2014 % no sev met data available for 2014
                    SevMet_site = 49; % Sev Five Points station (# 49 )
                end
                
            case UNM_sites.JSav    % Fill JSav from PJ, with regressions
                NMEG_site = 4; % PJ
                GHCND_site = 'ESTANCIA';
                if (year < 2012 )
                    GHCND_site = 'PROGRESSO';
                end
                
            case UNM_sites.PJ     % Fill PJ from PJ girdle or JSav
                if year > 2009  % use PJ_girdle after 2009
                    NMEG_site = 10; % PJ_girdle
                else  % use JSav before 2009
                    NMEG_site = 3; % JSav
                end
                
            case UNM_sites.PPine  % For 2013 onward fill PPine from the DRI Jemez
                SNOTEL_site = 744; % Senorita Divide
                SNOTEL_site2 = [];
                % station. Earlier, fill from Valles Caldera HQ
                if year >= 2009
                    VCMet = 'DRI'; % DRI Jemez station
                    VCMet_site = [];
                else
                    VCMet = 'VCP';
                    VCMet_site = 11; % Valles Caldera HQ met station (11)
                end
                
            case UNM_sites.MCon     % Fill MCon from Valles Caldera Redondo met station
                VCMet = 'VCP';
                VCMet_site = 14; % Valles Caldera Redondo met station (14)
                SNOTEL_site = 1017; % Vacas Locas
                SNOTEL_site2 = 708; % Quemazon
                
            case UNM_sites.PJ_girdle    % Fill PJ_girdle from PJ
                NMEG_site = 4; % PJ
                
            case UNM_sites.New_GLand    % Fill New_GLand from GLand
                NMEG_site = 1; % GLand
                if year < 2014; % no sev met data available for 2014 yet
                    SevMet_site = 40; % Sev Deep Well station
                end
                
            otherwise
                fprintf( 'filling not yet implemented for %s\n', ...
                    get_site_name( sitecode ) );
                result = -1;
                return
        end
        
        % Now parse that data
        fillTables = {};
        
        if NMEG_site  % Parse the nearest NMEG site
            fprintf( 'parsing %s_flux_all_%d_for_gapfilling.txt ("source")\n', ...
                get_site_name( NMEG_site), year );
            NMEG_data = parse_forgapfilling_file( NMEG_site, year, ...
                'use_filled', filled_file_false );
            NMEG_qc = UNM_parse_QC_txt_file(NMEG_site, year);
            NMEG_data.Precip = NMEG_qc.precip;
            NMEG_data = dataset2table(NMEG_data);
        end
        if SevMet_site % Parse the nearest Sevilletta met site
            SevMet_data = UNM_parse_sev_met_data( year );
            SevMet_data = prepare_met_data(...
                SevMet_data, year, 'Sev', SevMet_site );
        end
        if VCMet % Parse the nearest VC met site (DRI or VCP)
            VCMet_data = UNM_parse_valles_met_data( VCMet, year );
            if VCMet_site % Parse one of several VCP sites from the data file
                VCMet_data = prepare_met_data(...
                    VCMet_data, year, 'VCP', VCMet_site );
            else % But DRI files only contain 1
                VCMet_data = prepare_met_data( VCMet_data, year, 'DRI' );
            end
        end
        if SNOTEL_site % Parse the nearest SNOTEL site
            SNOTEL_data = UNM_parse_SNOTEL_data( SNOTEL_site, year );
            SNOTEL_data = prepare_daily_precip(SNOTEL_data, 'Precip');
            if SNOTEL_site2 % Parse a second SNOTEL site
                SNOTEL_data2 = UNM_parse_SNOTEL_data( SNOTEL_site2, year );
                SNOTEL_data2 = prepare_daily_precip(SNOTEL_data2, 'Precip');
            end
        end
        if GHCND_site % Parse the nearest GHCND site
            GHCND_data = UNM_parse_GHCND_met_data( GHCND_site, year );
            GHCND_P = prepare_daily_precip(GHCND_data, 'PRCP');
            GHCND_P.Precip = GHCND_P.Precip ./ 10;
        end
        
        % Get PRISM and DayMet model precip data for the site
        prism_T = UNM_parse_PRISM_met_data(sitecode, year);
        prism_P = prepare_daily_precip(prism_T, 'Precip');
        daymet_T = UNM_parse_DayMet_data(sitecode, year);
        daymet_P = prepare_daily_precip(daymet_T, 'prcp_mm_day_');
        
        %--------------------------------------------------
        % sychronize timestamps to thisData timestamps
        ts = thisData.timestamp;
        thisData = table_fill_timestamps( thisData, 'timestamp', ...
            't_min', min( ts ), ...
            't_max', max( ts ) );
        thisData.timestamp = datenum( thisData.timestamp );
        for k = 1:length(fillTables)
            % Trim the fill data
            fillTables{k} = fillTables{k}( ( fillTables{k}.timestamp >= min( ts ) & ...
                fillTables{k}.timestamp <= max( ts ) ), : );
            % Fill in timestamps
            fillTables{k} = table_fill_timestamps( fillTables{k}, 'timestamp', ...
                't_min', min( ts ), ...
                't_max', max( ts ) );
            fillTables{k}.timestamp = datenum( fillTables{k}.timestamp );
        end
        if NMEG_site
            NMEG_data = NMEG_data( ( NMEG_data.timestamp >= min( ts ) & ...
                NMEG_data.timestamp <= max( ts ) ), : );
            % Fill in timestamps
            NMEG_data = table_fill_timestamps( NMEG_data, 'timestamp', ...
                't_min', min( ts ), 't_max', max( ts ) );
            NMEG_data.timestamp = datenum( NMEG_data.timestamp );
        end
        if SevMet_site
            SevMet_data = SevMet_data( ( SevMet_data.timestamp >= min( ts ) & ...
                SevMet_data.timestamp <= max( ts ) ), : );
            % Fill in timestamps
            SevMet_data = table_fill_timestamps( SevMet_data, 'timestamp', ...
                't_min', min( ts ), 't_max', max( ts ) );
            SevMet_data.timestamp = datenum( SevMet_data.timestamp );
        end
        if VCMet
            VCMet_data = VCMet_data( ( VCMet_data.timestamp >= min( ts ) & ...
                VCMet_data.timestamp <= max( ts ) ), : );
            % Fill in timestamps
            VCMet_data = table_fill_timestamps( VCMet_data, 'timestamp', ...
                't_min', min( ts ), 't_max', max( ts ) );
            VCMet_data.timestamp = datenum( VCMet_data.timestamp );
        end
        if GHCND_site
            GHCND_P = GHCND_P( ( GHCND_P.timestamp >= min( ts ) & ...
                GHCND_P.timestamp <= max( ts ) ), : );
            % Fill in timestamps
            GHCND_P = table_fill_timestamps( GHCND_P, 'timestamp', ...
                't_min', min( ts ), 't_max', max( ts ) );
            GHCND_P.timestamp = datenum( GHCND_P.timestamp );
        end
        if ~isempty(prism_P)
            prism_P = prism_P( ( prism_P.timestamp >= min( ts ) & ...
                prism_P.timestamp <= max( ts ) ), : );
            % Fill in timestamps
            prism_P = table_fill_timestamps( prism_P, 'timestamp', ...
                't_min', min( ts ), 't_max', max( ts ) );
            prism_P.timestamp = datenum( prism_P.timestamp );
        end
        if ~isempty(daymet_P)
            daymet_P = daymet_P( ( daymet_P.timestamp >= min( ts ) & ...
                daymet_P.timestamp <= max( ts ) ), : );
            % Fill in timestamps
            daymet_P = table_fill_timestamps( daymet_P, 'timestamp', ...
                't_min', min( ts ), 't_max', max( ts ) );
            daymet_P.timestamp = datenum( daymet_P.timestamp );
        end
        
        %--------------------------------------------------
        % Get soil water content headers
        vwc2p5 = find(strncmpi('VWC_20x2E5_',...
            this_soildat.Properties.VarNames, 11));
        vwc5 = find(strncmpi('VWC_5_',...
            this_soildat.Properties.VarNames, 6))
        if vwc2p5
            shallowVWC = vwc2p5;
        elseif vwc5
            shallowVWC = vwc5
        else
            disp('No shallow soil data!')
        end
        %--------------------------------------------------
        
        newfig = figure( 'Name', sprintf('Precip filling, %s %d',...
            get_site_name(sitecode), year),...
        'Units', 'centimeters', 'PaperPosition', [5, 6, 16, 22], ...
        'Position', [5, 6, 16, 22]);
        ax(1) = subplot(811);
        plot(this_qc.timestamp, this_qc.precip);
        title('Tower data'); ylim([-5, 40]);
        ax(2) = subplot(812);
        if NMEG_site
            plot(NMEG_data.timestamp, NMEG_data.Precip, 'r');
            title(sprintf('Nearest NMEG site (%s)', get_site_name(NMEG_site)));
            ylim([-5, 40]);
        end
        ax(3) = subplot(813);
        if GHCND_site
            plot(GHCND_P.timestamp, GHCND_P.Precip, 'r');
            title(sprintf('Nearest GHCND site (%s)', GHCND_site));
        elseif VCMet
            plot(VCMet_data.timestamp, VCMet_data.Precip, 'r');
            if VCMet_site
                title(sprintf('Nearest VCP site (%s - %d)', VCMet, VCMet_site));
            else
                title(sprintf('Nearest VCP site (%s)', VCMet));
            end
        elseif SevMet_site
            plot(SevMet_data.timestamp, SevMet_data.Precip, 'r');
            title(sprintf('Nearest Sevilleta met site (%d)', SevMet_site));
        end
        ylim([-5, 40]);
        ax(4) = subplot(814);
        if SNOTEL_site
            plot(SNOTEL_data.timestamp, SNOTEL_data.Precip, 'g');
            title(sprintf('Nearest SNOTEL site (%d)', SNOTEL_site));
            if SNOTEL_site2
                hold on;
                plot(SNOTEL_data2.timestamp, SNOTEL_data2.Precip, 'm');
                legend(num2str(SNOTEL_site), num2str(SNOTEL_site2));
            end
        end
        ylim([-5, 40]);
        ax(5) = subplot(815);
        plot(prism_P.timestamp, prism_P.Precip, 'r');
        title('PRISM'); ylim([-5, 40]);
        ax(6) = subplot(816);
        plot(daymet_P.timestamp, daymet_P.Precip, 'r');
        title('DayMet'); ylim([-5, 40]);
        ax(7) = subplot(817);
        if ~isempty(this_soildat)
            plot(this_soildat.timestamp, this_soildat(:, shallowVWC), 'b');
        end
%         if SevMet_site
%             hold on;
%             plot(SevMet_data.timestamp, SevMet_data.VWC, 'm');
%             legend('This site', 'Nearest Sev site');
%         end
        title('SWC');
        ax(8) = subplot(818);
        plot(this_qc.timestamp, this_qc.fc_raw_massman_wpl, 'b');
        title('NEE');
        linkaxes(ax, 'x'); datetick();
        
        figname = fullfile(getenv('FLUXROOT'), 'QAQC_analyses', 'precip_filling',...
            sprintf('precip_filling_%s_%d.png', get_site_name(sitecode), year));
        print(newfig, '-dpng', figname ); 
    end
end
%===========================================================================

function T = prepare_met_data( T_in, year, site, varargin )
    if nargin == 4
        station = varargin{1};
    end
    % Initialize some variables
    stnVar = [];
    if strcmp(site, 'VCP')
        hr_2_30min = true; prec_conv = false;
        varCell = { 'sta', 'airt', 'rh', 'sol', 'ppt'};
        [stnVar, TairVar, rhVar, RgVar, PrecVar] = deal(varCell{:});
    elseif strcmp(site, 'DRI')
        hr_2_30min = false; prec_conv = true;
        varCell = { 'tair_F', 'rh_pct', 'solarrad_wm2', 'precip_in' };
        [TairVar, rhVar, RgVar, PrecVar] = deal(varCell{:});
    elseif strcmp(site, 'Sev')
        hr_2_30min = true; prec_conv = false;
        varCell = { 'Station_ID', 'Temp_C', 'RH', 'Solar_Rad', 'Precip', ...
            'Mois_10_cm'};
        [stnVar, TairVar, rhVar, RgVar, PrecVar, vwcVar] = deal(varCell{:});
    end
    
    % Trim out extra sites from some datasets
    if stnVar
        T_in = T_in( T_in.(stnVar) == station, : );
    end
    
    % Get subset of met variables and rename
    T = T_in( : , {'timestamp', TairVar, rhVar, RgVar, PrecVar} );
    T.Properties.VariableNames = { 'timestamp', 'Tair', 'rH', 'Rg', 'Precip' };
    
    % Convert rH from [ 0, 100 ] to [ 0, 1 ]
    if nanmax(T.rH > 2)
        T.rH = T.rH ./ 100.0;
    end
    % Convert precip to mm
    if prec_conv
        T.Precip = T.Precip .* 25.4;
    end

    % If readings are hourly -- interpolate to 30 mins
    if hr_2_30min
        ts = T.timestamp;
        thirty_mins = 30 / ( 60 * 24 );  % thirty minutes in units of days
        ts_30 = ts + thirty_mins;
        valid = find( ~isnan( T.rH ) );
        rh_interp = interp1( ts( valid ), T.rH( valid ), ts_30 );
        valid = find( ~isnan( T.Tair ) );
        T_interp = interp1( ts( valid ), T.Tair( valid ), ts_30 );
        valid = find( ~isnan( T.Rg ) );
        Rg_interp = interp1( ts( valid ), T.Rg( valid ), ts_30 );

        % Setting 30 min Precip to 0
        Prec_interp = zeros(length(ts_30), 1);
        
        T = vertcat( T, table( ts_30, rh_interp, T_interp, Rg_interp , ...
            Prec_interp,...
            'VariableNames', { 'timestamp', 'rH', 'Tair', 'Rg', 'Precip' } ) );
    end

    % filter out bogus values
    T.Tair( abs( T.Tair ) > 100 ) = NaN;
    T.rH( T.rH > 1.0 ) = NaN;
    T.rH( T.rH < 0.0 ) = NaN;
    T.Rg( T.Rg < -20.0 ) = NaN;

    % sort by timestamp
    [ ~, idx ] = sort( T.timestamp );
    T = T( idx, : );
end

%===========================================================================

function T_resamp = prepare_daily_precip( T, varname )
    T = T( : , { 'timestamp', varname } );
    T.Properties.VariableNames = { 'timestamp', 'Precip' };
    
    % remove duplicated timestamps
    dup_timestamps = find( abs( diff( T.timestamp ) ) < 1e-10 );
    T( dup_timestamps, : ) = [];
    
    % Resample the timeseries to 30mins
    nsamples = repmat(48, 1, length(T.timestamp) - 1);
    x = cumsum([1 nsamples]);
    ts_resamp = interp1(x, T.timestamp, x(1):x(end))';
    
    % Create a new 30 min table and move values over
    Precip = zeros(length(ts_resamp), 1);
    T_resamp = table(ts_resamp, Precip);
    match_rs = find(ismember(ts_resamp, T.timestamp)); %Match by timestamp
    T_resamp.Precip(match_rs) = T.Precip;
    
    % filter out nonsensical values
    T_resamp.Precip( T_resamp.Precip < 0 ) = NaN;
    T_resamp.Precip( T_resamp.Precip > 100 ) = NaN;
    
    % sort by timestamp
    [ discard, idx ] = sort( T_resamp.ts_resamp );
    T_resamp = T_resamp( idx, : );
    T_resamp.Properties.VariableNames{'ts_resamp'} = 'timestamp';
end
end

%===========================================================================

