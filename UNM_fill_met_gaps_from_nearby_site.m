function result = UNM_fill_met_gaps_from_nearby_site( sitecode, year, varargin )
% UNM_FILL_MET_GAPS_FROM_NEARBY_SITE - fills gaps in site's meteorological data
%   from the closest nearby site
%
% USAGE
%     result = UNM_fill_met_gaps_from_nearby_site( sitecode, year )
%     result = UNM_fill_met_gaps_from_nearby_site( sitecode, year, draw_plots )
%
% INPUTS
%     sitecode [ UNM_sites object ]: code of site to be filled
%     year [ integer ]: year to be filled
% PARAMETER-VALUE PAIRS
%     draw_plots: {true} | false; if true, plot observed and filled T, Rg, RH.
%
% OUTPUTS
%     result [ integer ]: 0 on success, -1 on failure
%
% SEE ALSO
%     UNM_sites
%
% author: Timothy W. Hilton, UNM, March 2012
  
% -----
% define optional inputs, with defaults and typechecking
% -----
[ this_year, ~, ~ ] = datevec( now() );
args = inputParser;
args.addRequired( 'sitecode', @(x) ( isintval( x ) | isa( x, 'UNM_sites' ) ) );
args.addRequired( 'year', ...
                  @(x) ( isintval( x ) & ( x >= 2006 ) & ( x <= this_year ) ) );
args.addParamValue( 'draw_plots', true, ...
                    @(x) ( islogical( x ) & numel( x ) == 1 ) );
args.parse( sitecode, year, varargin{ : } );
% -----

sitecode = args.Results.sitecode;
year = args.Results.year;
draw_plots = args.Results.draw_plots;

linfit = specify_site_linfits( sitecode );

if isintval( sitecode )
    sitecode = UNM_sites( sitecode );
else
    error( 'sitecode must be an integer' );
end

% initialize
result = -1;
nearby_2 = [];
filled_file_false = false;

%--------------------------------------------------
% parse unfilled data from requested site
    
fprintf( 'parsing %s_flux_all_%d_for_gapfilling.txt ("destination")\n', ...
         get_site_name( sitecode ), year );
thisData = parse_forgapfilling_file( sitecode, year, ...
                                      'use_filled', filled_file_false );
thisData = dataset2table(thisData);
%--------------------------------------------------
% Select data with which to fill T, RH, Rg and precip

NMEG_site = [];
SevMet_site = [];
VCMet = [];
GHCND_site = [];
SNOTEL_site = [];
SNOTEL_site2 = [];

switch sitecode    
    case UNM_sites.GLand    % fill GLand from SLand, then
        % (# 40)
        NMEG_site = 2; % SLand
        if year < 2014; % no sev met data available for 2014 yet
            SevMet_site = 40; % Sev Deep Well station
        end
        %     try
        %         fprintf( 'parsing %s_flux_all_%d_for_gapfilling.txt ("source")\n', ...
        %                  get_site_name( 2 ), year );  %
        %         nearby_data = parse_forgapfilling_file( 2, year, ...
        %             'use_filled', filled_file_false );
        %     catch err
        %         if strcmp( err.identifier, 'MATLAB:FileIO:InvalidFid' )
        %             error( ['unable to open SLand for gapfill file -- cannot fill ' ...
        %                     'GLand'] );
        %             rethrow( err )
        %         end
        %     end
    case UNM_sites.SLand   % Fill SLand from GLand and Sev Five Points stn
        NMEG_site = 1; % GLand
        if year < 2014 % no sev met data available for 2014
            SevMet_site = 49; % Sev Five Points station (# 49 )
        end
        
    case UNM_sites.JSav    % Fill JSav from PJ, with regressions
        NMEG_site = 4; % PJ
        if year < 2014
            GHCND_site = 'ESTANCIA';
        elseif (year < 2012 )
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
        % station. Earlier, fill from Valles Caldera HQ
        if year > 2012
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
    % Convert from tenths to mm
    GHCND_P.Precip = GHCND_P.Precip ./ 10;
end

% Get PRISM and DayMet model precip data for the site (if data available)
try
    prism_T = UNM_parse_PRISM_met_data(sitecode, year);
    prism_P = prepare_daily_precip(prism_T, 'Precip');
    daymet_T = UNM_parse_DayMet_data(sitecode, year);
    daymet_P = prepare_daily_precip(daymet_T, 'prcp_mm_day_');
catch
    warning('PRISM and DAYMET data not yet available')
end

%--------------------------------------------------
% sychronize timestamps to thisData timestamps
ts = thisData.timestamp;
thisData = table_fill_timestamps( thisData, 'timestamp', ...
                                     't_min', min( ts ), ...
                                     't_max', max( ts ) );
thisData.timestamp = datenum( thisData.timestamp );
for i = 1:length(fillTables)
    % Trim the fill data
    fillTables{i} = fillTables{i}( ( fillTables{i}.timestamp >= min( ts ) & ...
                           fillTables{i}.timestamp <= max( ts ) ), : );
    % Fill in timestamps
    fillTables{i} = table_fill_timestamps( fillTables{i}, 'timestamp', ...
                                       't_min', min( ts ), ...
                                       't_max', max( ts ) );
    fillTables{i}.timestamp = datenum( fillTables{i}.timestamp );
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
if SNOTEL_site
    SNOTEL_data = SNOTEL_data( ( SNOTEL_data.timestamp >= min( ts ) & ...
                           SNOTEL_data.timestamp <= max( ts ) ), : );
    % Fill in timestamps
    SNOTEL_data = table_fill_timestamps( SNOTEL_data, 'timestamp', ...
                            't_min', min( ts ), 't_max', max( ts ) );
    SNOTEL_data.timestamp = datenum( SNOTEL_data.timestamp );
end
if SNOTEL_site2
    SNOTEL_data2 = SNOTEL_data2( ( SNOTEL_data2.timestamp >= min( ts ) & ...
                           SNOTEL_data2.timestamp <= max( ts ) ), : );
    % Fill in timestamps
    SNOTEL_data2 = table_fill_timestamps( SNOTEL_data2, 'timestamp', ...
                            't_min', min( ts ), 't_max', max( ts ) );
    SNOTEL_data2.timestamp = datenum( SNOTEL_data2.timestamp );
end

% Sync prism and daymet
if exist(prism_P, 'var')
    prism_P = prism_P( ( prism_P.timestamp >= min( ts ) & ...
        prism_P.timestamp <= max( ts ) ), : );
    % Fill in timestamps
    prism_P = table_fill_timestamps( prism_P, 'timestamp', ...
        't_min', min( ts ), 't_max', max( ts ) );
    prism_P.timestamp = datenum( prism_P.timestamp );
end
if exist(daymet_P, 'var')
    daymet_P = daymet_P( ( daymet_P.timestamp >= min( ts ) & ...
        daymet_P.timestamp <= max( ts ) ), : );
    % Fill in timestamps
    daymet_P = table_fill_timestamps( daymet_P, 'timestamp', ...
        't_min', min( ts ), 't_max', max( ts ) );
    daymet_P.timestamp = datenum( daymet_P.timestamp );
end

%--------------------------------------------------
% Assign variables to use in filling
nearby_met2 = [];
if NMEG_site
    nearby_met = NMEG_data;
elseif VCMet
    nearby_met = VCMet_data;
end
if SevMet_site
    nearby_met2 = SevMet_data;
    nearby_precip = SevMet_data;
    nearby_precip2 = prism_P;
else
    nearby_precip = prism_P;
    nearby_precip2 = daymet_P;
end

%--------------------------------------------------
% fill T, RH, Rg, and precip
if numel( linfit ) == 1
    % T      RH    Rg
    linfit = [ false, false, linfit, false ];
elseif numel( linfit ) ~= 4
    error( ['linfit argument must be single logical value or 4-element '...
            ' logical array'] );
end

% replace missing Tair with nearby site
[ thisData, T_filled_1, T_filled_2 ] = ...
    fill_variable( thisData, nearby_met, nearby_met2, ...
                   'Tair', 'Tair', 'Tair', linfit( 1 ) );

% replace missing rH with nearby site
[ thisData, RH_filled_1, RH_filled_2 ] = ...
    fill_variable( thisData, nearby_met, nearby_met2, ...
                   'rH', 'rH', 'rH', linfit( 2 ) );
thisData.rH( thisData.rH > 1.0 ) = 1.0;
thisData.rH( thisData.rH < 0.0 ) = 0.0;

% replace missing Rg with nearby site
[ thisData, Rg_filled_1, Rg_filled_2 ] = ...
    fill_variable( thisData, nearby_met, nearby_met2, ...
                   'Rg', 'Rg', 'Rg', linfit( 3 ) );
thisData.Rg( thisData.Rg < -50 ) = NaN;

% replace missing Precip with nearby site
[ thisData, precip_filled_1, precip_filled_2 ] = ...
    fill_variable( thisData, nearby_precip, nearby_precip2, ...
                   'Precip', 'Precip', 'Precip', linfit( 4 ) );
thisData.Precip( thisData.Precip < 0 ) = NaN;

%--------------------------------------------------
% plot filled variables if requested

if draw_plots
    h_fig_T = plot_filled_variable( thisData, nearby_met, nearby_met2, ...
        'Tair', T_filled_1, T_filled_2, ...
        sitecode, year );
    h_fig_RH = plot_filled_variable( thisData, nearby_met, nearby_met2, ...
        'rH', RH_filled_1, RH_filled_2, ...
        sitecode, year );
    h_fig_Rg = plot_filled_variable( thisData, nearby_met, nearby_met2, ...
        'Rg', Rg_filled_1, Rg_filled_2, ...
        sitecode, year );
    h_fig_prec = plot_filled_variable( thisData, nearby_precip, nearby_precip2, ...
        'Precip', precip_filled_1, precip_filled_2, ...
        sitecode, year );
end

% replace NaNs with -9999
foo = table2array( thisData );
foo( isnan( foo ) ) = -9999;
thisData{:,:} = foo;

% write filled data to file except for matlab datenum timestamp column
outfile = fullfile( get_site_directory( sitecode ), ...
                    'processed_flux', ...
                    sprintf( '%s_flux_all_%d_for_gap_filling_filled.txt', ...
                             get_site_name( sitecode ), year ) );
fprintf( 'writing %s\n', outfile );
thisData.timestamp = [];
thisData2 = table2dataset(thisData);
export_dataset_tim( outfile, thisData2, 'write_units', true );
%export( thisData( :, 2:end ), 'file', outfile );

result = 0;

%===========================================================================
    
function [ ds_dest, idx1, idx2 ] = fill_variable( ds_dest, ...
                                                  ds_source1, ds_source2, ...
                                                  var_dest, ...
                                                  var_source1, ...
                                                  var_source2, ... 
                                                  linfit_source1 )
    % replace missing values in on variable of dataset ds_dest with
    % corresponding values from dataset ds_source1.  Where ds_source1 also
    % has missing values, fall back to ds_source2 if provided.
    
    % replace missing values with nearby site
    n_missing = numel( find( isnan( ds_dest.( var_dest ) ) ) );
    idx1 = find( isnan( ds_dest.( var_dest ) ) & ...
                 ~isnan( ds_source1.( var_source1 ) ) );

    if linfit_source1
        replacement = linfit_var( ds_source1.( var_source1 ), ...
                                  ds_dest.( var_dest ), ...
                                  idx1 );
    else
        replacement = ds_source1.( var_source1 );        
    end

    ds_dest.( var_dest )( idx1 ) = replacement( idx1 );
    % if there is a secondary site, fill remaining missing values 
    idx2 = [];  %initialize to empty in case no second site provided
    if not( isempty( ds_source2 ) )
        idx2 = find( isnan( ds_dest.( var_dest ) ) & ...
                     isnan( ds_source1.( var_source1 ) ) & ...
                     ~isnan( ds_source2.( var_source2 ) ) );
        ds_dest.( var_dest )( idx2 ) = ds_source2.( var_source2 )( idx2 );
    end
    n_filled = numel( idx1 ) + numel( idx2 );
    fprintf( '%s: replaced %d / %d missing observations\n', ...
             var_dest, n_filled, n_missing );

%===========================================================================
    
function h_fig = plot_filled_variable( ds, ds_source1, ds_source2, ...
                                       var, filled_idx1, filled_idx2, ...
                                       sitecode, year )
    
    seconds = repmat( 0.0, size( ds, 1 ), 1 );
    ts = datenum( ds.year, ds.month, ds.day, ...
                  ds.hour, ds.minute, seconds );
    nobs = size( ds, 1 );
    jan1 = datenum( ds.year, repmat( 1, nobs, 1 ), repmat( 1, nobs, 1 ) );
    doy = ts - jan1 + 1;
    
    h_fig = figure();
    h_obs = plot( doy, ds.( var ), '.k' );
    hold on;
    h_filled_1 = plot( doy( filled_idx1 ), ...
                       ds.( var )( filled_idx1 ), ...
                       '.', 'MarkerEdgeColor', [ 27, 158, 119 ] / 255.0 );
    if not( isempty( filled_idx2 ) )
        h_filled_2 = plot( doy( filled_idx2 ), ...
                           ds.( var )( filled_idx2 ), ...
                           '.', 'MarkerEdgeColor', [ 217, 95, 2 ] / 255.0 );
    else
        h_filled_2 = 0;
    end
    ylabel( var );
    xlabel( 'day of year' );
    title( sprintf( '%s %d', get_site_name( sitecode ), year ) );
    legend( [ h_obs, h_filled_1, h_filled_2 ], ...
            'observed', 'filled 1', 'filled 2' );
    
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
        varCell = { 'Station_ID', 'Temp_C', 'RH', 'Solar_Rad', 'Precip' };
        [stnVar, TairVar, rhVar, RgVar, PrecVar] = deal(varCell{:});
    end
    
    % Trim out extra sites from some datasets
    if stnVar
        T_in = T_in( T_in.(stnVar) == station, : );
    end
    
    % Get subset of met variables and rename
    T = T_in( : , {'timestamp', TairVar, rhVar, RgVar, PrecVar } );
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
            Prec_interp, ...
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
%===========================================================================

% function ds = prepare_DRI_met_data( T, year )
% % helper function to trim and sychronize timestamps for Valles DRI data
% 
%     T = T( : , { 'timestamp', 'tair_F', 'rh_pct', 'solarrad_wm2' } );
%     T.rh_pct = T.rh_pct ./ 100.0;  %rescale from [ 0, 100 ] to [ 0, 1 ]
%     T.tair_F = (T.tair_F - 32) .* (5/9); % convert to Celsius
%     
% %     % these readings are hourly -- interpolate to 30 mins
% %     thirty_mins = 30 / ( 60 * 24 );  % thirty minutes in units of days
% %     ts_30 = ts + thirty_mins;
% %     valid = find( ~isnan( ds.rh ) );
% %     rh_interp = interp1( ts( valid ), ds.rh( valid ), ts_30 );
% %     valid = find( ~isnan( ds.airt ) );
% %     T_interp = interp1( ts( valid ), ds.airt( valid ), ts_30 );
% %     valid = find( ~isnan( ds.sol ) );
% %     Rg_interp = interp1( ts( valid ), ds.sol( valid ), ts_30 );
% %     
% %     ds = vertcat( ds, dataset( { [ ts_30, rh_interp, T_interp, Rg_interp ], ...
% %                                'timestamp', 'rh', 'airt', 'sol' } ) );
% % 
%     % filter out nonsensical values
%     T.tair_F( abs( T.tair_F ) > 100 ) = NaN;
%     T.rh_pct( T.rh_pct > 1.0 ) = NaN;
%     T.rh_pct( T.rh_pct < 0.0 ) = NaN;
%     t.solarrad_wm2( T.solarrad_wm2 < -20 ) = NaN;
% 
%     % make the field names match the "for gapfilling" data
%     T.Properties.VarNames{ strcmp( ds.Properties.VarNames, 'rh_pct' ) } = 'rH';
%     T.Properties.VarNames{ strcmp( ds.Properties.VarNames, 'tair_F' ) } = 'Tair';
%     T.Properties.VarNames{ strcmp( ds.Properties.VarNames, 'solarrad_wm2' ) } = 'Rg';
%     
%     % sort by timestamp
%     [ discard, idx ] = sort( T.timestamp );
%     T = T( idx, : );
%     
% %===========================================================================
% 
% function ds = prepare_sev_met_data( ds, year, station )
% % helper function to trim and sychronize timestamps for Sev data
%     ds = ds( ds.Station_ID == station, : );
%     time_ds = ds( :, { 'Year', 'Jul_Day', 'Hour' } );
%     ts = datenum( time_ds.Year, 1, 1 ) + ...
%          ( time_ds.Jul_Day - 1 ) + ...
%          ( time_ds.Hour / 24.0 );
%     ds = ds( :, { 'Temp_C', 'RH', 'Solar_Rad' } );
%     ds.Properties.VarNames = { 'Tair', 'rH', 'Rg' };
%     ds.rH = ds.rH ./ 100.0;  %rescale from [ 0, 100 ] to [ 0, 1 ]
%     ds.timestamp = ts;
%     % remove duplicated timestamps
%     dup_timestamps = find( abs( diff( ts ) ) < 1e-10 );
%     ds( dup_timestamps, : ) = [];
%     ts( dup_timestamps ) = [];
% 
%     % these readings are hourly -- interpolate to 30 mins
%     thirty_mins = 30 / ( 60 * 24 );  % thirty minutes in units of days
%     ts_30 = ts + thirty_mins;
%     valid = find( ~isnan( ds.rH ) );
%     rh_interp = interp1( ts( valid ), ds.rH( valid ), ts_30 );
%     valid = find( ~isnan( ds.Tair ) );
%     T_interp = interp1( ts( valid ), ds.Tair( valid ), ts_30 );
%     valid = find( ~isnan( ds.Rg ) );
%     Rg_interp = interp1( ts( valid ), ds.Rg( valid ), ts_30 );
%     
%     ds = vertcat( ds, dataset( { [ ts_30, rh_interp, T_interp, Rg_interp ], ...
%                                'timestamp', 'rH', 'Tair', 'Rg' } ) );
% 
%     % filter out nonsensical values
%     ds.Tair( abs( ds.Tair ) > 100 ) = NaN;
%     ds.rH( ds.rH > 1.0 ) = NaN;
%     ds.rH( ds.rH < 0 ) = NaN;
%     
%     % sort by timestamp
%     [ discard, idx ] = sort( ds.timestamp );
%     ds = ds( idx, : );
    
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


%===========================================================================

function result = linfit_var( x, y, idx )
    
% find timestamps without NaN in either variable
    nan_idx = any( isnan( [ x, y ] ), 2 );

    x_valid = x( ~nan_idx );
    y_valid = y( ~nan_idx );
    
    % linear regression of var2 against var1
    slope = fminsearch( @(m) sse_linfit_slope_only( x_valid, y_valid, m ), ...
                        1.10 );

    result = x;
    result( idx ) = x( idx ) * slope;

function sse = sse_linfit_slope_only( x, y, m )
    sse = sum( ( y - ( m * x ) ) .^ 2 );

function result = linfit_var2( x, y, idx )

% find timestamps without NaN in either variable
    nan_idx = any( isnan( [ x, y ] ), 2 );

    % linear regression of var2 against var1
    linfit = polyfit( x( ~nan_idx ), y( ~nan_idx ), 1 );

    % return prediction of var2 at idx based on regression
    result = x;
    result( idx ) = ( x( idx ) * linfit( 1 ) ) + linfit( 2 );
    
function linfit = specify_site_linfits( sitecode )
% SPECIFY_SITE_LINFITS - defines which variables (temp, relative humidity, and
%   PAR) to perform a regression for data from a nearby site

switch sitecode
  case { UNM_sites.GLand, UNM_sites.SLand, ...
         UNM_sites.PJ, UNM_sites.PJ_girdle }
    linfit = [ false false false false];
  case { UNM_sites.JSav, UNM_sites.New_GLand }
    linfit = [ true true true false];
  case { UNM_sites.PPine, UNM_sites.MCon }
    linfit = [ false false true false];
  otherwise
    error( sprintf( 'Not implemented for %s\n', char( sitecode ) ) );
end

