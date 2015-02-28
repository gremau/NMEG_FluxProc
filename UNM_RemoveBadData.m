function [] = UNM_RemoveBadData( sitecode, year, varargin )
% UNM_REMOVEBADDATA - remove bogus observations from UNM flux data and write
% filtered data to delimited ASCII files FOR SITE-YEARS 2012 AND LATER.
%
% This program was created by Krista Anderson Teixeira in July 2007
% Modified by John DeLong 2008 through 2009.
% Modifed by Timothy W. Hilton, 2011 through 2013
%
% The program reads site_fluxall_year delimited text files and pulls in a
% combination of matlab processed ts data and data logged average 30-min flux
% data.  It then flags values based on a variety of criteria and writes out new
% files that do not have the identified bad values.  It writes out a
% site_flux_all_qc file and a site_flux_all_for_gap_filling file to send to
% REddyProc for gapfilling and flux partitioning.  It can be adjusted to make
% other subsetted files too.
%
% USAGE
%     UNM_RemoveBadData( sitecode, year )
%     UNM_RemoveBadData( sitecode, year, 'iteration', iteration )
%     UNM_RemoveBadData( sitecode, year, ..., 'write_QC', write_QC )
%     UNM_RemoveBadData( sitecode, year, ..., 'write_GF', write_GF )
%     UNM_RemoveBadData( sitecode, year, ..., 'draw_plots', draw_plots )
%
% INPUTS
%     sitecode: UNM_sites object or integer; specifies site to process
%     year: integer; year to process
% PARAMETER-VALUE PAIRS
%     iteration: integer 1-6 (Default is 6); defines which set of bad data tasks
%          to perform (see code for details)
%     write_QC: {true}|false; if true, writes flux_all_qc file
%     write_GF: {true}|false; if true, writes flux_all_for_gapfilling file
%     draw_plots: 0|{1}|2|3; determines extent of plotting.  larger values
%         cause more plots to be drawn.
%          0: draw no plots
%          1 (default): plot only NEE time series with NEE filter results
%          2: all plots from 1, plus:
%             - PAR normalization results
%             - radiation timing correction results
%             - six-panel plot showing "fingerprints" for incoming shortwave
%               (Rg), relative humidity (RH), air temperature (T), net ecosystem
%               exchange (NEE), latent heat (LE), and sensible heat (H),
%          3: all plots from 1 and 2, plus:
%             - latent heat diagnostic plot showing LE and PAR time series
%               with the results of various filters (see plot legend)
%             - four-panel plot showing time series for NEE, T, carbon
%               dioxide concentration ([CO2]), and pcp
%             - NEE vs wind speed scatter plot
%             - NEE vs wind direction scatter plot (split by day/night)
%             - NEE vs friction velocity (ustar) scatter plot
%             - [CO2] time series, with results of various filters (see plot
%               legend)
%             - Burba cold temperature correction results
%
% OUTPUTS:
%     This function has no outputs
%
% SEE ALSO
%     UNM_RemoveBadData_pre2012
%
% author: Timothy W. Hilton, UNM, 2012-2013

%clear all
%close all

[ this_year, ~, ~ ] = datevec( now );

% -----
% define optional inputs, with defaults and typechecking
% -----
args = inputParser;
args.addRequired( 'sitecode', @(x) ( isintval( x ) | isa( x, 'UNM_sites' ) ) );
args.addRequired( 'year', ...
    @(x) ( isintval( x ) & ( x >= 2006 ) & ( x <= this_year ) ) );
args.addParamValue( 'iteration', 6, ...
    @(x) ( isintval( x ) & ( x >= 1 ) & ( x <= 6 ) ) );
args.addParamValue( 'write_QC', true, @islogical );
args.addParamValue( 'write_GF', true, @islogical );
args.addParamValue( 'old_fluxall', false, @islogical );
args.addParamValue( 'xls_fluxall', false, @islogical );
args.addParamValue( 'draw_plots', 1, ...
    @(x) ( isnumeric( x ) & ismember( x, [ 0, 1, 2, 3 ] ) ) );

% parse optional inputs
args.parse( sitecode, year, varargin{ : } );

% place user arguments into variables
sitecode = args.Results.sitecode;
year_arg = args.Results.year;
site = char( sitecode );
iteration = int8( args.Results.iteration );

%true to write "[sitename].._qc", -- file with all variables & bad data removed
write_complete_out_file = args.Results.write_QC;
%true to write file for Reichstein's online gap-filling. SET U* LIM (including
%site- specific ones--comment out) TO 0!!!!!!!!!!
write_gap_filling_out_file = args.Results.write_GF;

% Parameters used to select between versions of fluxall files
use_old_fluxall = args.Results.old_fluxall;
use_xls_fluxall = args.Results.xls_fluxall;

draw_plots = args.Results.draw_plots;


data_for_analyses = 0; %1 to output file with data sorted for specific analyses
ET_gap_filler = 0; %run ET gap-filler program

winter_co2_min = -100;  %initialization -- will be set for specific sites later
obs_per_day = 48;  % half-hourly observations

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Specify some details about sites and years
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if sitecode == UNM_sites.GLand; % grassland
    ustar_lim = 0.06;
    co2_min_by_month = -15; co2_max_by_month = 6;
    n_SDs_filter_hi = 3.0; % how many std devs above the mean NEE to allow
    n_SDs_filter_lo = 3.0; % how many std devs below the mean NEE to allow
    wind_min = 330; wind_max = 30; % these are given a sonic_orient = 180;
    Tdry_min = 240; Tdry_max = 320;
    HS_min = -100; HS_max = 450;
    HSmass_min = -100; HSmass_max = 450;
    LH_min = -150; LH_max = 450;
    rH_min = 0; rH_max = 1;
    h2o_max = 30; h2o_min = 0;
    
elseif sitecode == UNM_sites.SLand; % shrubland
    ustar_lim = 0.08;
    co2_min_by_month = -15; co2_max_by_month = 6;
    n_SDs_filter_hi = 3.0; % how many std devs above the mean NEE to allow
    n_SDs_filter_lo = 3.0; % how many std devs below the mean NEE to allow
    wind_min = 330; wind_max = 30; % these are given a sonic_orient = 180;
    Tdry_min = 240; Tdry_max = 320;
    HS_min = -100; HS_max = 450;
    HSmass_min = -100; HSmass_max = 450;
    LH_min = -150; LH_max = 450;
    rH_min = 0; rH_max = 1;
    h2o_max = 30; h2o_min = 0;
    
elseif sitecode == UNM_sites.JSav; % Juniper savanna
    ustar_lim = 0.11;
    co2_min_by_month = -15;
    co2_max_by_month = [ repmat( 4, 1, 6 ), repmat( 10, 1, 6 ) ];
    n_SDs_filter_hi = 3.0; % how many std devs above the mean NEE to allow
    n_SDs_filter_lo = 3.0; % how many std devs below the mean NEE to allow
    wind_min = 15; wind_max = 75; % these are given a sonic_orient = 225;
    Tdry_min = 240; Tdry_max = 320;
    HS_min = -100; HS_max = 550;
    HSmass_min = -100; HSmass_max = 550;
    LH_min = -150; LH_max = 450;
    rH_min = 0; rH_max = 1;
    h2o_max = 30; h2o_min = 0;
    press_min = 70; press_max = 130;
    
elseif sitecode == UNM_sites.PJ; % Pinyon Juniper
    ustar_lim = 0.22;
    n_SDs_filter_hi = 3.0; % how many std devs above the mean NEE to allow
    n_SDs_filter_lo = 3.0; % how many std devs below the mean NEE to allow
    wind_min = 15; wind_max = 75; % these are given a sonic_orient = 225;
    co2_min_by_month = -10;
    co2_max_by_month = 6;
    Tdry_min = 240; Tdry_max = 310;
    HS_min = -100; HS_max = 640;
    HSmass_min = -100; HSmass_max = 640;
    LH_min = -150; LH_max = 450;
    rH_min = 0; rH_max = 1;
    h2o_max = 30; h2o_min = 0;
    press_min = 70; press_max = 130;
    co2_max_by_month = [ 2, 2, 2, 2.5, 3, 3, 3, repmat( 6, 1, 5 ) ];
    
elseif sitecode == UNM_sites.PJ_girdle; % Pinyon Juniper girdle
    ustar_lim = 0.16;
    n_SDs_filter_hi = 3.0; % how many std devs above the mean NEE to allow
    n_SDs_filter_lo = 3.0; % how many std devs below the mean NEE to allow
    wind_min = 15; wind_max = 75; % these are given a sonic_orient = 225;
    Tdry_min = 240; Tdry_max = 310;
    HS_min = -100; HS_max = 640;
    HSmass_min = -100; HSmass_max = 640;
    LH_min = -150; LH_max = 450;
    rH_min = 0; rH_max = 1;
    h2o_max = 30; h2o_min = 0;
    press_min = 70; press_max = 130;
    co2_min_by_month = -10;
    co2_max_by_month = [ 1.5, 1.5, 2, 2, 3, 4, 4, repmat( 6, 1, 5 ) ];
    
elseif sitecode == UNM_sites.New_GLand; % new Grassland
    ustar_lim = 0.06;
    n_SDs_filter_hi = 4.5; % how many std devs above the mean NEE to allow
    n_SDs_filter_lo = 3.0; % how many std devs below the mean NEE to allow
    co2_min_by_month = -15; co2_max_by_month = 6;
    wind_min = 330; wind_max = 30; % these are given a sonic_orient = 180;
    Tdry_min = 240; Tdry_max = 320;
    HS_min = -100; HS_max = 450;
    HSmass_min = -100; HSmass_max = 450;
    LH_min = -150; LH_max = 450;
    rH_min = 0; rH_max = 1;
    h2o_max = 30; h2o_min = 0;
    
elseif sitecode == UNM_sites.PPine; % Ponderosa Pine
    % site default values
    co2_min_by_month = [-6 -6 -15 -15 -15 -15 -15 -15 -15 -15 -15 -5];
    co2_max_by_month = [4 4 4 5 30 30 30 30 30 30 5 4];
    co2_max_by_month = 30;
    ustar_lim = 0.2;
    n_SDs_filter_hi = 3.0; % how many std devs above the mean NEE to allow
    n_SDs_filter_lo = 3.0; % how many std devs below the mean NEE to allow
    wind_min = 119; wind_max = 179; % these are given a sonic_orient = 329;
    Tdry_min = 240; Tdry_max = 310;
    HS_min = -200; HS_max = 800;
    HSmass_min = -200; HSmass_max = 800;
    LH_min = -50; LH_max = 550;
    rH_min = 0; rH_max = 1;
    h2o_max = 30; h2o_min = 0;
    
elseif sitecode == UNM_sites.MCon; % Mixed conifer
    co2_min_by_month = [ -2.5, -2.5, repmat( -12, 1, 9 ), -2.5 ];%[ -1.5, -1.5, repmat( -12, 1, 9 ), -1.5 ];
    co2_max_by_month = 6;
    n_SDs_filter_hi = 2.0; % how many std devs above the mean NEE to allow
    n_SDs_filter_lo = 3.0; % how many std devs below the mean NEE to allow
    wind_min = 153; wind_max = 213; % these are given a sonic_orient = 333;
    Tdry_min = 250; Tdry_max = 300;
    HS_min = -200; HS_max = 800;
    HSmass_min = -200; HSmass_max = 800;
    LH_min = -50; LH_max = 550;
    rH_min = 0; rH_max = 1;
    h2o_max = 30; h2o_min = 0;
    ustar_lim = 0.2;
    
elseif sitecode == UNM_sites.TX;
    ustar_lim = 0.11;
    co2_min_by_month = -26;
    switch args.Results.year
        case 2011
            co2_max_by_month = [ 4.0, 4, 4, 4, 9, 10, ...
                10, 4, 4, 4, 4, 4.0 ];
        case 2012
            co2_max_by_month = [ 4.9, 6, 7, 8, 9, 12, ...
                12, 12, 9, 6, 6, 4.9 ];
    end
    n_SDs_filter_hi = 3.0; % how many std devs above the mean NEE to allow
    n_SDs_filter_lo = 3.0; % how many std devs below the mean NEE to allow
    wind_min = 296; wind_max = 356; % these are given a sonic_orient = 146;
    Tdry_min = 265; Tdry_max = 315;
    HS_min = -200; HS_max = 800;
    HSmass_min = -200; HSmass_max = 800;
    LH_min = -150; LH_max = 550;
    rH_min = 0; rH_max = 1;
    h2o_max = 30; h2o_min = 0;
    press_min = 70; press_max = 130;
    
elseif sitecode == UNM_sites.TX_forest;
    ustar_lim = 0.11;
    n_SDs_filter_hi = 3.0; % how many std devs above the mean NEE to allow
    n_SDs_filter_lo = 3.0; % how many std devs below the mean NEE to allow
    co2_min_by_month = -26; co2_max_by_month = 12;
    wind_min = 300; wind_max = 360; % these are given a sonic_orient = ;
    Tdry_min = 265; Tdry_max = 315;
    HS_min = -200; HS_max = 800;
    HSmass_min = -200; HSmass_max = 800;
    LH_min = -150; LH_max = 550;
    rH_min = 0; rH_max = 1;
    h2o_max = 30; h2o_min = 0;
    press_min = 70; press_max = 130;
    
elseif sitecode == UNM_sites.TX_grass;
    ustar_lim = 0.11;
    n_SDs_filter_hi = 3.0; % how many std devs above the mean NEE to allow
    n_SDs_filter_lo = 3.0; % how many std devs below the mean NEE to allow
    co2_min_by_month = -26; co2_max_by_month = 12;
    wind_min = 300; wind_max = 360; % these are given a sonic_orient = ;
    Tdry_min = 265; Tdry_max = 315;
    HS_min = -200; HS_max = 800;
    HSmass_min = -200; HSmass_max = 800;
    LH_min = -150; LH_max = 550;
    rH_min = 0; rH_max = 1;
    h2o_max = 35; h2o_min = 0;
    press_min = 70; press_max = 130;
    
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% read the fluxall file
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if use_old_fluxall
    pathname = fullfile( get_site_directory( sitecode ), ...
        'old_fluxall');
else
    pathname = fullfile( get_site_directory( sitecode ));
end

if use_xls_fluxall
    fname = sprintf( '%s_FLUX_all_%d.xls', get_site_name( sitecode ), ...
        year_arg );
    data = UNM_parse_fluxall_xls_file( sitecode, year_arg, ...
        'file', fullfile( pathname, fname ));
else
    fname = sprintf( '%s_FLUX_all_%d.txt', get_site_name( sitecode ), ...
        year_arg );
    data = UNM_parse_fluxall_txt_file( sitecode, year_arg, ...
        'file', fullfile( pathname, fname ));
end

outfolder = fullfile( get_site_directory( sitecode ), ...
    'processed_flux' );

headertext = data.Properties.VarNames;
timestamp = data.timestamp;
[year,month,day,hour,minute,second] = datevec( data.timestamp );
ncol = size( data, 2 );
filelength_n = size( data, 1 );

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% some siteyears have periods where the observed radition does not line
% up with sunrise.  Fix this here so that the matched time/radiation
% propagates through the rest of the calculations
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

data = UNM_fix_datalogger_timestamps( sitecode, year_arg, ...
    dataset2table( data ),...
    'debug', args.Results.draw_plots > 1 );

data = table2dataset( data );

%    data.timestamp = [];
if ( sitecode == UNM_sites.MCon )
    %        if ( year == 2007 | year == 2008)
    %            data = replacedata( data, ...
    %                   revise_MCon_duplicated_Rg( double( data ), ...
    %                                              headertext, ...
    %                                              timestamp ) );
    %        end
end
shift_t_str = 'shifted';

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Read in Matlab processed ts data
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

jday = data.jday;
iok = data.iok ;
Tdry = data.tdry ;
%wnd_dir_compass = data.wind_direction ;
wnd_spd = data.speed ;
%u_star = data.ustar ;
%CO2_mean = data.CO2_mean ;
%CO2_std = data.CO2_std ;
%H2O_mean = data.H2O_mean ;
%H2O_std = data.H2O_std ;
%u_mean = data.u_mean_unrot ;
t_mean = data.temp_mean;
t_meanK = t_mean + 273.15;

fc_raw = data.Fc_raw ;
fc_raw_massman = data.Fc_raw_massman ;
fc_water_term = data.Fc_water_term ;
fc_heat_term_massman = data.Fc_heat_term_massman ;
%fc_raw_massman_wpl = data.Fc_raw_massman_ourwpl;

E_raw = data.E_raw ;
E_raw_massman = data.E_raw_massman ;
E_water_term = data.E_water_term;
E_heat_term_massman = data.E_heat_term_massman;
E_wpl_massman = data.E_wpl_massman;

%HSdry = data.SensibleHeat_dry ;
%HSdry_massman = data.HSdry_massman;

%HL_raw = data.LatentHeat_raw;
%HL_wpl_massman = data.LatentHeat_raw_massman ; % Is this correct?
%HL_wpl_massman_un = repmat( NaN, size( data, 1 ), 1 );

%rhoa_dry = data.rhoa_dry_air_molar_density;

decimal_day = ( datenum( year, month, day, hour, minute, second ) - ...
    datenum( year, 1, 1 ) + 1 );
year_arg = year(2);

%initialize some variables to a NaN array
dummy = repmat( NaN, size( data, 1), 1 );
rH = dummy;
precip = dummy;
% Some sites are missing radiation measurements
sw_incoming = dummy;
lw_incoming = dummy;
sw_outgoing = dummy;
lw_outgoing = dummy;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Read in 30-min data, variable order and names in flux_all files are not
% consistent so match headertext
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% convert CNR1 temperature from centrigrade to Kelvins
% FIXME - this needs to handle different header names from early years
CNR1TK = [];
CNR1_var = regexp_ds_vars( data, 'CNR1*|Temp_C_Avg' );
if ~isempty(CNR1_var)
    CNR1TK = data.( CNR1_var{ 1 } ) + 273.15;
end

h2oflag_1 = 0;

data = double( data );

for i=1:numel( headertext );
    if strcmp('agc_Avg',headertext{i}) == 1
        agc_Avg = data(:,i);
    elseif strcmp('h2o_hmp_Avg', headertext{i}) == 1 | ...
            strcmp('h2o_hmp_mean', headertext{i}) == 1 | ...
            strcmp('h2o_hmp_mean_Avg', headertext{i}) == 1
        h2o_hmp = data( :, i );
    elseif strcmp('wind_direction', headertext{i}) == 1 | ...
            strcmp('windDirection_theta', headertext{i}) == 1
        wnd_dir_compass = data( :, i );
    elseif strcmp('ustar', headertext{i}) == 1 | ...
            strcmp('ustar_frictionVelocity_M_s', headertext{i}) == 1
        u_star = data( :, i );
        % filter out absurd u_star values
        u_star( u_star > 50 ) = NaN;
    elseif strcmp('u_mean_unrot', headertext{i}) == 1 | ...
            strcmp('u_mean', headertext{i}) == 1
        u_mean = data( :, i );
    elseif strcmp('CO2_mean', headertext{i}) == 1 | ...
            strcmp('CO2_mean_umol_molDryAir', headertext{i}) == 1
        CO2_mean = data( :, i );
    elseif strcmp('CO2_std', headertext{i}) == 1 | ...
            strcmp('CO2_std_umol_molDryAir', headertext{i}) == 1
        CO2_std = data( :, i );
    % This should come in from 10hz data in g/m3, but some fluxall
    % have it in mmol/mol, so convert it below
    elseif strcmp('H2O_mean', headertext{i}) == 1
        H2O_mean = data( :, i );
    elseif strcmp('H2O_mean_mmol_molDryAir', headertext{i}) == 1
        H2O_mean = data( :, i );
        h2oflag_1 = 1;
    elseif strcmp('H2O_std', headertext{i}) == 1 | ...
            strcmp('H2O_std_mmol_molDryAir', headertext{i}) == 1
        H2O_std = data( :, i );
    elseif strcmp('Fc_raw_massman_ourwpl', headertext{i}) == 1 | ...
            strcmp('Fc_raw_massman_wpl', headertext{i}) == 1
        fc_raw_massman_wpl = data( :, i );
    elseif strcmp('SensibleHeat_dry', headertext{i}) == 1 | ...
            strcmp('HSdry_WM2', headertext{i}) == 1
        HSdry = data( :, i );
    elseif strcmp('HSdry_massman', headertext{i}) == 1 | ...
            strcmp('HSdry_massman_WM2', headertext{i}) == 1
        HSdry_massman = data( :, i );
    elseif strcmp('LatentHeat_raw', headertext{i}) == 1 | ...
            strcmp('HL_raw_WM2', headertext{i}) == 1
        HL_raw = data( :, i );
    elseif strcmp('LatentHeat_raw_massman', headertext{i}) == 1 | ...
            strcmp('HL_raw_massman_WM2', headertext{i}) == 1
        HL_wpl_massman = data( :, i );% Is this correct? Its raw, not wpl
        
        HL_wpl_massman_un = repmat( NaN, size( data, 1 ), 1 );
        % Half hourly data filler only produces uncorrected HL_wpl_massman,
        % but use these where available as very similar values
        HL_wpl_massman( isnan( HL_wpl_massman ) & ...
            ~isnan( HL_wpl_massman_un ) ) = ...
            HL_wpl_massman_un( isnan( HL_wpl_massman ) & ...
            ~isnan( HL_wpl_massman_un ) );
    elseif strcmp('rhoa_dry_air_molar_density', headertext{i}) == 1 | ...
            strcmp('rhoa_dryAirMolarDensity_mols_m3MoistAir', headertext{i}) == 1 | ...
            strcmp('rhoa_dryAirMolarDensity_g_m3MoistAir', headertext{i}) == 1% Is this correct? Convert?
        rhoa_dry = data( :, i );
        
        % Input all the different relative humidity variables and change to 0-1.
    elseif strcmp('rH', headertext{i}) == 1 | ...
            strcmp('RH_Avg', headertext{i}) == 1 | ...
            strcmp('RH_4p5_Avg',headertext{i}) == 1 | ...
            strcmp('RH_4p5',headertext{i}) == 1 | ...
            strcmp('rh_hmp', headertext{i}) == 1 | ...
            strcmp('rh_hmp_4_Avg', headertext{i}) == 1 | ...
            strcmp('RH',headertext{i}) == 1 | ...
            strcmp('RH_2_Avg',headertext{i}) == 1 | ...
            strcmp('RH_10_Avg',headertext{i}) == 1 | ...
            strcmp('RH_6p85_Avg', headertext{i})==1
        %strcmp('RH_3p7_Avg',headertext{i}) == 1 | ...
        % strcmp('RH_2',headertext{i}) == 1 | ...
        
        %Fixed scaling the rH now on a per rH value to account for
        %the scale changes associated with program changes in the
        %fluxall.
        rH = data(:,i);
        scale = find(rH > 1);
        rH(scale) = rH(scale) ./ 100;
        
    elseif strcmp('Ts_mean', headertext{i}) == 1 | ...
            strcmp('Ts_Avg', headertext{i}) == 1
        Tair_TOA5 = data(:,i);
    elseif  strcmp('5point_precip', headertext{i}) == 1 | ...
            strcmp('rain_Tot', headertext{i}) == 1 | ...
            strcmp('precip', headertext{i}) == 1 | ...
            strcmp('precip(in)', headertext{i}) == 1 | ...
            strcmp('ppt', headertext{i}) == 1 | ...
            strcmp('Precipitation', headertext{i}) == 1
        precip = data(:,i);
    elseif strcmp( 'press_mean', headertext{i}) == 1 | ...
            strcmp('press_Avg', headertext{i}) == 1 | ...
            strcmp('press_a', headertext{i}) == 1
        atm_press = data(:,i);
    elseif strcmp('par_correct_Avg', headertext{i}) == 1  | ...
            strcmp('par_Avg(1)', headertext{i}) == 1 | ...
            strcmp('par_Avg_1', headertext{i}) == 1 | ...
            strcmp('par_Avg', headertext{i}) == 1 | ...
            strcmp('par_up_Avg', headertext{i}) == 1 | ...
            strcmp('par_face_up_Avg', headertext{i}) == 1 | ...
            strcmp('par_faceup_Avg', headertext{i}) == 1 | ...
            strcmp('par_incoming_Avg', headertext{i}) == 1 | ...
            strcmp('par_lite_Avg', headertext{i}) == 1
        Par_Avg = data(:,i);
    elseif strcmp('t_hmp_mean', headertext{i})==1 | ...
            strcmp('AirTC_Avg', headertext{i})==1 | ...
            strcmp('AirTC_2_Avg', headertext{i})==1 | ...
            strcmp('AirTC_10_Avg', headertext{i})==1 | ...
            strcmp('AirTC_4p5_Avg', headertext{i})==1 | ...
            strcmp('t_hmp_3_Avg', headertext{i})==1 | ...
            strcmp('pnl_tmp_a', headertext{i})==1 | ...
            strcmp('t_hmp_Avg', headertext{i})==1 | ...
            strcmp('t_hmp_4_Avg', headertext{i})==1 | ...
            strcmp('t_hmp_top_Avg', headertext{i})==1| ...
            strcmp('AirTC_6p85_Avg', headertext{i})==1
        air_temp_hmp = data(:,i);
    elseif strcmp('Tsoil',headertext{i}) == 1 | ...
            strcmp('Tsoil_avg',headertext{i}) == 1 | ...
            strcmp('soilT_Avg(1)',headertext{i}) == 1
        Tsoil = data(:,i);
    elseif strcmp('Rn_correct_Avg',headertext{i})==1 | ...
            strcmp('NR_surf_AVG', headertext{i})==1 | ...
            strcmp('NetTot_Avg_corrected', headertext{i})==1 | ...
            strcmp('NetTot_Avg', headertext{i})==1 | ...
            strcmp('Rn_Avg',headertext{i})==1 | ...
            strcmp('Rn_total_Avg',headertext{i})==1
        NR_tot = data(:,i);
    elseif strcmp('Rad_short_Up_Avg', headertext{i}) | ...
            strcmp('pyrr_incoming_Avg', headertext{i})
        sw_incoming = data(:,i);
    elseif strcmp('Rad_short_Dn_Avg', headertext{i})==1 | ...
            strcmp('pyrr_outgoing_Avg', headertext{i})==1
        sw_outgoing = data(:,i);
    elseif strcmp('Rad_long_Up_Avg', headertext{i}) == 1 | ...
            strcmp('Rad_long_Up__Avg', headertext{i}) == 1
        lw_incoming = data(:,i);
    elseif strcmp('CG3UpCo_Avg', headertext{i})==1 | ...
            strcmp('Rad_long_Up_TCor_Avg', headertext{i})==1
        lw_incoming_Co = data(:, i);
    elseif strcmp('Rad_long_Dn_Avg', headertext{i})==1 | ...
            strcmp('Rad_long_Dn__Avg', headertext{i})==1
        lw_outgoing = data(:,i);
    elseif strcmp('CG3DnCo_Avg', headertext{i})==1 | ...
            strcmp('Rad_long_Dn_TCor_Avg', headertext{i})==1
        lw_outgoing_Co = data(:, i);
    elseif strcmp('VW_Avg', headertext{i})==1 | ...
            strcmp('SWC_Avg_1', headertext{i})==1 | ...
            strcmp('SWC_P1_5_Avg', headertext{i})==1
        VWC = data(:,i);
    elseif strcmp('shf_Avg(1)', headertext{i})==1 | ...
            strcmp('shf_Avg_1', headertext{i})==1 | ...
            strcmp('shf_pinon_1_Avg', headertext{i})==1
        soil_heat_flux_1 = data(:,i);
        disp('FOUND shf_pinon_1_Avg');
    elseif any( strcmp( headertext{i}, ...
            { 'hfp_grass_1_Avg', 'hfp01_grass_Avg' } ) )
        soil_heat_flux_1 = data(:,i);
        disp('FOUND hfp_grass_1_Avg');
    elseif any( strcmp( headertext( i ), ...
            { 'hfp_grass_2_Avg', 'hft3_grass_Avg' } ) )
        soil_heat_flux_2 = data(:,i);
        disp('FOUND hfp_grass_2_Avg');
    elseif strcmp('shf_Avg(2)', headertext{i})==1 | ...
            strcmp('shf_Avg_2', headertext{i})==1 | ...
            strcmp('shf_jun_1_Avg', headertext{i})==1
        soil_heat_flux_2 = data(:,i);
    elseif strcmp('hfpopen_1_Avg', headertext{i})==1 % only for TX
        soil_heat_flux_open = data(:,i);
    elseif strcmp('hfpmescan_1_Avg', headertext{i})==1 % only for TX
        soil_heat_flux_mescan = data(:,i);
    elseif strcmp('hfpjuncan_1_Avg', headertext{i})==1 % only for TX
        soil_heat_flux_juncan = data(:,i);
        %Shrubland flux plates 2009 onwards
    elseif strcmp('hfp01_1_Avg', headertext{i})==1
        soil_heat_flux_1 = data(:,i);
    elseif strcmp('hfp01_2_Avg', headertext{i})==1
        soil_heat_flux_2 = data(:,i);
    elseif strcmp('hfp01_3_Avg', headertext{i})==1
        soil_heat_flux_3 = data(:,i);
    elseif strcmp('hfp01_4_Avg', headertext{i})==1
        soil_heat_flux_4 = data(:,i);
    elseif strcmp('hfp01_5_Avg', headertext{i})==1
        soil_heat_flux_5 = data(:,i);
    elseif strcmp('hfp01_6_Avg', headertext{i})==1
        soil_heat_flux_6 = data(:,i);
    elseif strcmp('shf_Avg(3)', headertext{i})==1 |...
            strcmp('shf_Avg_3', headertext{i})==1
        soil_heat_flux_3 = data(:,i);
    elseif strcmp('shf_Avg(4)', headertext{i})==1 |...
            strcmp('shf_Avg_4', headertext{i})==1
        soil_heat_flux_4 = data(:,i);
        
    end
end

% Fix selected atmospheric water content measuremnts
if h2oflag_1
    H2O_mean = H2O_mean .* ( ( ( 1 ./ ...
        ( 8.3143e-3 .* ( t_meanK ./ atm_press ) ) ) .* 18 ) ./ 1000);
end

% remove absurd precipitation measurements
precip( precip > 1000 ) = NaN;

if ismember( sitecode, [ 1, 2 ] ) & year(2) == 2009
    Par_Avg = combine_PARavg_PARlite( headertext, data );
end

% PJ girdle, calculate relative humidity from hmp obs using helper
% function. Not needed starting 1/10/2014
if sitecode == 10
    rH = thmp_and_h2ohmp_2_rhhmp( air_temp_hmp, h2o_hmp ) ./ 100.0;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Site-specific steps for soil temperature
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if sitecode == 1 %GLand   added TWH, 27 Oct 2011
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
    
elseif sitecode == 2 %SLand   changed TWH, 30 Oct 2012
    % regular expression to identify SHF variables
    re_SHF = '.*([Ss][Hh][Ff]).*|.*([Hh][Ff][Pp]).*';
    SHF_idx = find( ~cellfun( @isempty, regexp( headertext, re_SHF ) ) );
    SHF_labels = headertext( SHF_idx );
    soil_heat_flux = data( :, SHF_idx );
    
elseif sitecode == 3 %JSav   added TWH, 7 May 2012
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
    
elseif sitecode == 4 %PJ
    for i=1:ncol;
        if strcmp('tcav_pinon_1_Avg',headertext(i)) == 1
            Tsoil1 = data(:,i-1);
        elseif strcmp('tcav_jun_1_Avg',headertext(i)) == 1
            Tsoil2 = data(:,i-1);
        end
    end
    if exist( 'Tsoil1' ) == 1 & exist( 'Tsoil2' ) == 1
        Tsoil = (Tsoil1 + Tsoil2) ./ 2;
    else
        Tsoil = repmat( NaN, size( data, 1 ), 1 );
    end
    soil_heat_flux_1 = repmat( NaN, size( data, 1 ), 1 );
    soil_heat_flux_2 = repmat( NaN, size( data, 1 ), 1 );
    SHF_labels = { 'soil_heat_flux_1', 'soil_heat_flux_2' };
    soil_heat_flux = [ soil_heat_flux_1, soil_heat_flux_2 ];
    
    % related lines 678-682: corrections for site 4 (PJ) soil_heat_flux_1 and soil_heat_flux_2
    %Tsoil=sw_incoming .* NaN;  %MF: note, this converts all values in Tsoil to NaN. Not sure if this was intended.
    
elseif ismember( sitecode, [ UNM_sites.PPine, UNM_sites.MCon ] )
    
    SHF_labels = { 'soil_heat_flux_1', 'soil_heat_flux_2', 'soil_heat_flux_3' };
    soil_heat_flux = repmat( NaN, size( data, 1 ), 3 );
    Tsoil = repmat( NaN, size( data, 1 ), 1 );
    
elseif sitecode == 7 % Texas Freeman
    for i=1:ncol;
        if strcmp('Tsoil_Avg_2',headertext(i)) == 1
            open_5cm = data(:,i-1);
        elseif strcmp('Tsoil_Avg_3',headertext(i)) == 1
            open_10cm = data(:,i-1);
        elseif strcmp('Tsoil_Avg_5',headertext(i)) == 1
            Mesquite_5cm = data(:,i-1);
        elseif strcmp('Tsoil_Avg_6',headertext(i)) == 1
            Mesquite_10cm = data(:,i-1);
        elseif strcmp('Tsoil_Avg_8',headertext(i)) == 1
            Juniper_5cm = data(:,i-1);
        elseif strcmp('Tsoil_Avg_9',headertext(i)) == 1
            Juniper_10cm = data(:,i-1);
        end
    end
    if year_arg == 2005 % juniper probes on-line after 5/19/05
        % before 5/19
        canopy_5cm = Mesquite_5cm(find(decimal_day < 139.61));
        canopy_10cm = Mesquite_10cm(find(decimal_day < 139.61));
        % after 5/19
        canopy_5cm(find(decimal_day >= 139.61)) = ...
            (Mesquite_5cm(find(decimal_day >= 139.61)) + ...
            Juniper_5cm(find(decimal_day >= 139.61))) ./ 2;
        canopy_10cm(find(decimal_day >= 139.61)) = ...
            (Mesquite_10cm(find(decimal_day >= 139.61)) + ...
            Juniper_10cm(find(decimal_day >= 139.61))) ./ 2;
        % clean strange 0 values
        canopy_5cm(find(canopy_5cm == 0)) = NaN;
        canopy_10cm(find(canopy_10cm == 0)) = NaN;
        Tsoil = (open_5cm + canopy_5cm) ./ 2;
    else
        canopy_5cm = (Mesquite_5cm + Juniper_5cm) ./ 2;
        canopy_10cm = (Mesquite_10cm + Juniper_10cm) ./ 2;
        Tsoil = (open_5cm + canopy_5cm) ./ 2;
    end
    
elseif sitecode == 10 | sitecode == 11
    Tsoil=sw_incoming .* NaN;
    soil_heat_flux_1 =sw_incoming .* NaN;
    soil_heat_flux_2 =sw_incoming .* NaN;
    SHF_labels = { 'soil_heat_flux_1', 'soil_heat_flux_2' };
    soil_heat_flux = [ soil_heat_flux_1, soil_heat_flux_2 ];
end

% Juniper S heat flux plates need multiplying by calibration factors
if sitecode == 3
    soil_heat_flux_1 = soil_heat_flux_1 .* 32.27;
    soil_heat_flux_2 = soil_heat_flux_2 .* 33.00;
    soil_heat_flux_3 = soil_heat_flux_3 .* 31.60;
    soil_heat_flux_4 = soil_heat_flux_4 .* 32.20;
end

% Pinon Juniper heat flux plates need multiplying by calibration factors
if sitecode == 4
    
    soil_heat_flux_1 = soil_heat_flux_1 .* 35.2;
    soil_heat_flux_2 = soil_heat_flux_2 .* 32.1;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% data processing and fixing datalogger & instrument errors 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


% fix incorrect precipitation values
precip_uncorr= precip;
precip = fix_incorrect_precip_factors( sitecode, year, ...
                                             jday, precip );

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Radiation corrections
% RJL added the lw_incoming and lw_outgoing variables to output on 01172014
% Variables lw_incoming, lw_outgoing, NR_sw, NR_lw, and NR_tot are now
% corrected for temperature. New data logger programs starting 2014
% will have lw_incomingCo and lw_outgoingCo corrected variables.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

[ sw_incoming, sw_outgoing, ...
    lw_incoming, lw_outgoing, Par_Avg ] = ...
    UNM_RBD_apply_radiation_calibration_factors( sitecode, ...
    year_arg, ...
    decimal_day, ...
    sw_incoming, ...
    sw_outgoing, ...
    lw_incoming, ...
    lw_outgoing, ...
    Par_Avg, ...
    NR_tot, ...
    wnd_spd, ...
    CNR1TK );

[ NR_sw, NR_lw, NR_tot ] = ...
    UNM_RBD_calculate_net_radiation( sitecode, year_arg, ...
    sw_incoming, sw_outgoing, ...
    lw_incoming, lw_outgoing, ...
    NR_tot, wnd_spd, decimal_day );

% normalize PAR to account for calibration problems at some sites
Par_Avg = normalize_PAR_wrapper( sitecode, year_arg, decimal_day, Par_Avg, ...
    draw_plots > 1 );


save_fname = fullfile( getenv( 'FLUXROOT' ), 'FluxallConvert', ...
    sprintf( '%s_%d_after_radiation.mat', ...
    char( sitecode ), year(1) ) );
save( save_fname );
fprintf( 'saved %s\n', save_fname );

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Apply Burba 2008 correction for sensible heat conducted from 7500
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% define some constants
R = 8.3143e-3; % universal gas constant  [J / kmol / K ]
Rd = 287.04; % dry air gas constant [J / kg / K]
MWd = 28.97; % dry air molecular weight [g / mol]
R_h2o = 461.5; % water vapor gas constant [J / kg / K]
MW_h2o = 16; % water vapor molecular weight [g / mol]
Cp = 1004.67; % specific heat capacity of dry air @ constant pres [J / kg / K]

% This is the conversion from mumol mol to mg m3 for CO2
hh = (1 ./ ( R .* ( t_meanK ./ atm_press ) .* 1000 ) ) .* 44;
% convert umol CO2 / mol dry air to mg CO2 / m3 dry air -- TWH
% cf_co2 abbreviates "conversion factor CO2"
%cf_co2 = ( ( MWd * Rd * t_meanK ) ./ ( 1000 * atm_press ) ) .* ( 44 / 1000 );
%cf_co2 = ( ( MWd * Rd ) ./ 1000 ) .* (t_meanK ./ ( atm_press * 1000 ))...
%    .* ( 44 / 1000 );
%CO2_mg = CO2_mean .* cf_co2;
CO2_mg = CO2_mean .* hh;

% This is the conversion from mmol mol to g m3 for H2O
gg = ( ( 1 ./ ...
    ( R .* ( t_meanK ./ atm_press ) ) ) .* 18 ) ./ 1000;
% convert mmol H2O / mol dry air to g H2O / m3 dry air -- TWH
% cf_h2o abbreviates "conversion factor H2O"
%cf_h2o = ( MW_h2o * R_h2o * t_meanK ) ./ ( 1000 * atm_press );
%cf_h2o = ( Rd * MWd ) ./ 1000 .* (t_meanK ./ ( 1000 * atm_press ))...
%    .* MW_h2o;
%H2O_g = H2O_mean .* cf_h2o;

% I don't think it is necessary to convert this
H2O_g = H2O_mean;% .* gg;

% Convert dry air density from mol/m3 to kg/m3
rhoa_dry_kg = ( rhoa_dry .* MWd ) ./ 1000; % 

% Calculate heat capacity of air [J / kg / K] based on temperature
Cp = 1004.67 + ( Tdry .^ 2 ./ 3364. ); % Not yet sure why this is done.
RhoCp = rhoa_dry_kg .* Cp;

% Positive net radiation
NR_pos = find( NR_tot > 0 );

Kair = ( 0.000067 .* t_mean ) + 0.024343;

% Calculate temperature and heating differentials on LI7500 bodies
% with and without radiation
Ti_top = (1.008 .* t_mean - 0.4) + 273.16;
Ti_top(NR_pos) = (1.005 .* t_mean(NR_pos) + 0.24) + 273.16;

Ti_bot = (0.883 .* t_mean + 2.17) + 273.16;
Ti_bot(NR_pos) = (0.944 .* t_mean(NR_pos) + 2.57) + 273.16;

% There is a further correction for irga angle (Oechel 2014 in JGR)
% Correct the heating of the bottom cylinder based on angle
tbot_weight = 63; % Currently calculated with a spreadsheet sensivity analysis
ttop_weight = 100 - tbot_weight;
cbot_weight = 100;
ctop_weight = 100 - cbot_weight;
Ti_bot_angled = (1/100) .* (tbot_weight .* Ti_bot + ttop_weight .* Ti_top);

Ti_spar = (1.01 .* t_mean - 0.17) + 273.16;
Ti_spar(NR_pos) = (1.01 .* t_mean(NR_pos) + 0.36) + 273.16;

Si_bot = Kair .* (Ti_bot - t_meanK) ./ ...
    (0.004 .* sqrt(0.065 ./ abs(u_mean)) + 0.004);

% New coreection - Note that it uses angled Ti_bot (as per burba spreadsheet)
Si_bot_new = Kair .* (Ti_bot_angled - t_meanK) ./ ...
    (0.004 .* sqrt(0.065 ./ abs(u_mean)) + 0.004);

Si_top = ( Kair .* (Ti_top - t_meanK) .* ...
    (0.0225 + (0.0028 .* sqrt(0.045 ./ abs(u_mean)) + ...
    0.00025 ./ abs(u_mean) + 0.0045)) ./ ...
    (0.0225 .* (0.0028 .* sqrt(0.045 ./ abs(u_mean)) + ...
    0.00025 ./ abs(u_mean) + 0.0045)) );

Sip_spar = ( Kair .* (Ti_spar - t_meanK) ./ ...
    (0.0025 .* log((0.0025 + 0.0058 .* ...
    sqrt(0.005 ./ abs(u_mean))) ./ 0.0025)) .* 0.15 );

% And this corrects the Si_bot_new value (as per burba spreadsheet)
Si_bot_angled = (1/100) .* (cbot_weight .* Si_bot_new + ctop_weight .* Si_top);

% Dry air density
pd = 44.6 .* 28.97 .* atm_press ./ 101.3 .* 273.16 ./ t_meanK;
% Now calculate the correction to the flux
dFc = (Si_top + Si_bot + Sip_spar) ./ RhoCp .* CO2_mg ./...
    t_meanK .* (1 + 1.6077 .* H2O_g ./ pd);
% And the new, angled correction
dFc_angled = (Si_top + Si_bot_angled + Sip_spar) ./ RhoCp .* CO2_mg ./...
    t_meanK .* (1 + 1.6077 .* H2O_g ./ pd); 

% Convert correct flux from mumol/m2/s to mg/m2/s
fc_mg = fc_raw_massman_wpl .* 0.044;
% Add the burba correction to it
fc_mg_corr = (fc_raw_massman_wpl .* 0.044) + dFc;
% Apply this only if the temperature is below 0C
found = find(t_mean < 0);
fc_out = fc_mg;
fc_out(found) = fc_mg_corr(found);

% Convert back to mumol/m2/s
fc_out = fc_out .* (1 / 0.044);

% Make a diagnostic plot
if draw_plots > 2
    h_burba_fig = figure( 'Name', 'Burba correction',...
        'Units', 'centimeters', 'Position', [5, 6, 16, 22] );
    ax(1) = subplot(411);
    plot(timestamp, dFc,'.');
    hold on;
    plot(timestamp, dFc_angled,'.', 'color', [0.7 0.7 0.7]);
    ylim([-0.05 0.15]);
    legend('delta Fc in mg/m2/s', 'delta Fc - angled' ); datetick('x', 'mmm-yyyy');
    ylabel('Calculated correction (mg m^2 s^{-1}');
    title( sprintf('%s %d', get_site_name( sitecode ), year( 1 ) ) );
    ax(2) = subplot(412);
    plot(timestamp, fc_raw_massman_wpl, '.g');
    hold on;
    plot(timestamp, fc_out, '.k');
    ylabel('Fc (umol m^2 s^{-1})'); ylim([-25 15]);
    legend('uncorrected', 'corrected'); datetick('x', 'mmm-yyyy');
    ax(3) = subplot(413);
    fc_nonan1 = fc_raw_massman_wpl;
    fc_nonan1(find(isnan(fc_nonan1))) = 0;
    plot(timestamp, cumsum(fc_nonan1), '.g');
    hold on;
    fc_nonan2 = fc_out;
    fc_nonan2(find(isnan(fc_nonan2))) = 0;
    plot(timestamp, cumsum(fc_nonan2), '.k');
    legend('uncorrected', 'corrected'); datetick('x', 'mmm-yyyy');
    ax(4) = subplot(414);
    plot(timestamp, t_mean, '.r');
    hold on;
    plot(get(gca,'xlim'), [0 0], ':k');
    ylabel('T_{mean} (C)'); xlabel('Date'); datetick('x', 'mm-yyyy');
    linkaxes(ax, 'x');
end

% Make the burba corrected flux what we use from here out.
fc_raw_massman_wpl = fc_out;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Set up filters for co2 and make a master flag variable (decimal_day_nan)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

decimal_day_nan = decimal_day;
record = 1:1:length(fc_raw_massman_wpl);
conc_record = 1:1:length(CO2_mean);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Iteration 1 - run and plot fluxes with the following four filters with
% all other filters commented out, then evaluate the ustar cutoff with
% figure (1).  Use the plot to decide which ustar bin on the x-axis is the
% cutoff, and then use the printed out vector on the main screen to decide
% what the ustar value is for that bin.  That's the number you enter into
% the site-specific info above.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

disp('Number of co2 flux periods removed due to:');
% Original number of NaNs
nanflag = find(isnan(fc_raw_massman_wpl));
removednans = length(nanflag);
decimal_day_nan(nanflag) = NaN;
record(nanflag) = NaN;
co2_conc_nanflag = find(isnan(CO2_mean));
conc_record(co2_conc_nanflag) = NaN;
disp(sprintf('    original empties = %d',removednans));

% % Remove values during precipitation
precipflag = find(precip > 0);
removed_precip = length(precipflag);
decimal_day_nan(precipflag) = NaN;
record(precipflag) = NaN;
conc_record(precipflag) = NaN;
disp(sprintf('    precip = %d',removed_precip));

% Remove for behind tower wind direction
windflag = find(wnd_dir_compass > wind_min & wnd_dir_compass < wind_max);
removed_wind = length(windflag);
decimal_day_nan(windflag) = NaN;
record(windflag) = NaN;
disp(sprintf('    wind direction = %d',removed_wind));

% Remove night-time negative fluxes
% changed NEE cutoff from 0 to -0.2 as per conversation with Marcy 29 Mar 2012
nightnegflag = find( Par_Avg < 20.0 & fc_raw_massman_wpl < -0.2);
removed_nightneg = length(nightnegflag);
decimal_day_nan(nightnegflag) = NaN;
record(nightnegflag) = NaN;
disp(sprintf('    night-time negs = %d',removed_nightneg));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% PPINE EXTRA WIND DIRECTION REMOVAL
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% ppine has super high night respiration when winds come from ~ 50
% degrees, so these must be excluded also:
if sitecode == 5
    ppine_night_wind = find( ( wnd_dir_compass > 30 & ...
        wnd_dir_compass < 65 ) & ...
        ( hour <= 9 | hour > 18 ) );
    % ppine_night_wind = find( ( wnd_dir_compass > 30 & ...
    %                            wnd_dir_compass < 65 ) );
    windflag = unique( [ windflag; ppine_night_wind ] );
    removed_ppine_night_wind = length(ppine_night_wind);
    decimal_day_nan(ppine_night_wind) = NaN;
    record(ppine_night_wind) = NaN;
    conc_record(ppine_night_wind) = NaN;
    disp(sprintf('    ppine night winds = %d',removed_ppine_night_wind));
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Winter Sensible heat correction for C uptake - doesn't really do anything
% valuable and can be removed (HS) was not the problem
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% MCon has negative sensible
% if sitecode == 6 & year_arg == 2013
%     mcon_cold_hs = find( ( HSdry_massman < -50 & ...
%         air_temp_hmp < 0 ));
%     %windflag = unique( [ windflag; ppine_night_wind ] );
%     removed_mcon_cold_hs = length(mcon_cold_hs);
%     decimal_day_nan(mcon_cold_hs) = NaN;
%     record(mcon_cold_hs) = NaN;
%     conc_record(mcon_cold_hs) = NaN;
%     disp(sprintf('    mcon cold weather uptake = %d',removed_mcon_cold_hs));
% end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% gland 2007 had large fluxes for very cold temperatures early in the year.
if sitecode == 1 & year_arg == 2007
    gland_cold = find(Tdry < 271.);
    removed_gland_cold = length(gland_cold);
    decimal_day_nan(gland_cold) = NaN;
    record(gland_cold) = NaN;
    disp(sprintf('    gland cold = %d',removed_gland_cold));
end

% Take out dodgy calibration period at Shrubland in 2007
if sitecode == 2 & year_arg == 2007
    decimal_day_nan(12150:12250) = NaN;
    record(12150:12250) = NaN;
    conc_record(12600:12750) = NaN;
end

% Take out dodgy calibration period at Shrubland in 2009
if sitecode == 2 & year_arg == 2009
    conc_record(11595:11829) = NaN;
end

% Plot out to see and determine ustar cutoff
if iteration == 1
    u_star_2 = u_star(find(~isnan(decimal_day_nan)));
    fc_raw_massman_wpl_2 = fc_raw_massman_wpl(find(~isnan(decimal_day_nan)));
    hour_2 = hour(find(~isnan(decimal_day_nan)));
    
    ustar_bin = 1:1:30; % you can change this to have more or less categories
    ustar_mean = repmat( NaN, size( ustar_bin ) );
    for i = 1:30 % you can change this to have more or less categories
        if i == 1
            startbin(i) = 0;
        elseif i >= 2
            startbin(i) = (i - 1) * 0.01;
        end
        endbin(i) = 0.01 + startbin(i);
        elementstouse = find((u_star_2 > startbin(i) & ...
            u_star_2 < endbin(i))  & ...
            (hour_2 > 22 | hour_2 < 5));
        co2mean(i) = mean(fc_raw_massman_wpl_2(elementstouse));
        ustar_mean( i ) = mean( u_star_2( elementstouse ) );
    end
    
    startbin;
    if draw_plots > 2
        ufig = figure( 'Name', 'determine Ustar cutoff', 'NumberTitle', 'Off' );
        clf;
        plot( ustar_mean, co2mean, '.k' );
        xlabel( 'UStar' );
        ylabel( 'co2mean' );
        title( sprintf('UStar, %s %d', get_site_name(sitecode), year(1)));
        shg;
        figname = fullfile(getenv('FLUXROOT'), 'ustar_analysis',...
            sprintf('ustar_cutoff_%s_%d.png', get_site_name(sitecode), year(1)));
        print(ufig, '-dpng', figname ); 
    end
    return;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Iteration 2 - Now that you have entered a ustar cutoff in the site
% options above, run with iteration 2 to see the effect of removing those
% values
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if iteration > 1
    
    % Remove values with low U*
    ustarflag = find(u_star < ustar_lim);
    removed_ustar = length(ustarflag);
    decimal_day_nan(ustarflag) = NaN;
    record(ustarflag) = NaN;
    
    % display pulled ustar
    disp(sprintf('    u_star = %d',removed_ustar));
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Iteration 3 - now that values have been filtered for ustar, decide what
% the min and max co2 flux values should be by examining figure 2 and then
% entering them in the site options above, then run program with iteration
% 3 and see the effect of removing them in figure 2
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if iteration > 2
    
    [ fc_raw_massman_wpl, E_wpl_massman, HL_wpl_massman, ...
        HSdry, HSdry_massman, CO2_mean, H2O_mean, atm_press, NR_tot, ...
        sw_incoming, sw_outgoing, lw_incoming, lw_outgoing, precip, ...
        rH, Par_Avg, Tdry ] = ...
        remove_specific_problem_periods( sitecode, year_arg, ...
        fc_raw_massman_wpl, ...
        E_wpl_massman, ...
        HL_wpl_massman, ...
        HSdry, ...
        HSdry_massman, ...
        CO2_mean, ...
        H2O_mean, ...
        atm_press, ...
        NR_tot, ...
        sw_incoming, ...
        sw_outgoing, ...
        lw_incoming, ...
        lw_outgoing, ...
        precip, ...
        rH, ...
        Par_Avg, ...
        Tdry );
    
    [ DOY_co2_min, DOY_co2_max ] = get_daily_maxmin( month, ...
        co2_min_by_month, ...
        co2_max_by_month, ...
        winter_co2_min );
    
    removed_maxs_mins=0;
    maxminflag = [];
    
    [ DOY_co2_min, DOY_co2_max, std_exc_flag ] = ...
        specify_siteyear_filter_exceptions( sitecode, year_arg, ...
        DOY_co2_min, DOY_co2_max );
    
    maxminflag = ( ( fc_raw_massman_wpl > DOY_co2_max ) | ...
        ( fc_raw_massman_wpl < DOY_co2_min ) );
    
    removed_maxs_mins = numel( find( maxminflag ) );
    decimal_day_nan( maxminflag ) = NaN;
    record( maxminflag ) = NaN;
    
    % display what is pulled for maxs and mins
    disp(sprintf('    above max or below min = %d',removed_maxs_mins));
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Iteration 4 - Now examine the effect of high and low co2 filters by
% running program with iteration 4
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if iteration > 3
    
    % Remove high CO2 concentration points
    highco2flag = find(CO2_mean > 450);
    
    % exceptions
    co2_conc_filter_exceptions = repmat( false, size( CO2_mean ) );
    co2_conc_filter_exceptions = ...
        specify_siteyear_co2_conc_filter_exceptions( ...
        sitecode, year, co2_conc_filter_exceptions );
    
    removed_highco2 = length(highco2flag);
    decimal_day_nan(highco2flag) = NaN;
    record(highco2flag) = NaN;
    conc_record(highco2flag) = NaN;
    
    % Remove low CO2 concentration points
    if sitecode == 9
        lowco2flag = find(CO2_mean <250);
    elseif sitecode == 8 & year(1) ==2008
        lowco2flag = find(CO2_mean <250);
    elseif sitecode == 1 & year(1) ==2007
        lowco2flag = find(CO2_mean <344);
    else
        lowco2flag = find(CO2_mean <350);
    end
    
    removed_lowco2 = length(lowco2flag);
    decimal_day_nan(lowco2flag) = NaN;
    record(lowco2flag) = NaN;
    conc_record(lowco2flag) = NaN;
    
    % display what's pulled for too high or too low co2
    disp(sprintf('    low co2 = %d',removed_lowco2));
    disp(sprintf('    high co2 = %d',removed_highco2));
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Iteration 5 - Now clear out the last of the outliers by running iteration
% 5, which removes values outside a running standard deviation window
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if iteration > 4
    %     figure;
    %     element = gcf;
    % Remove values outside of a running standard deviation
    n_bins = 48;
    std_bin = zeros( 1, n_bins );
    bin_length = round(length(fc_raw_massman_wpl) / n_bins);
    
    % count up what's been filtered out already
    good_co2 = repmat( true, size( decimal_day ) );
    good_co2( highco2flag ) = false;
    good_co2( lowco2flag ) = false;
    good_co2( co2_conc_filter_exceptions ) = true;
    
    idx_NEE_good = repmat( true, size( decimal_day ) );
    idx_NEE_good( ustarflag ) = false;
    idx_NEE_good( precipflag ) = false;
    idx_NEE_good( nightnegflag ) = false;
    idx_NEE_good( windflag ) = false;
    idx_NEE_good( maxminflag ) = false;
    idx_NEE_good( nanflag ) = false;
    idx_NEE_good( ~good_co2 ) = false;
    %    idx_NEE_good( idx_std_removed ) = false;
    stdflag = repmat( false, size( idx_NEE_good ) );
    
    % figure();
    % idx_ax = axes();
    % plot( decimal_day, idx_std_removed, '.' );
    
    for i = 1:n_bins
        if i == 1
            startbin( i ) = 1;
        elseif i >= 2
            startbin( i ) = ((i-1) * bin_length);
        end
        endbin( i ) = min( bin_length + startbin( i ), numel( idx_NEE_good) );
        
        % make logical indices for elements that are (1) in this bin and (2)
        % not already filtered for something else
        this_bin = repmat( false, size( idx_NEE_good ) );
        this_bin( startbin( i ):endbin( i ) ) = true;
        
        std_bin(i) = nanstd( fc_raw_massman_wpl( this_bin & idx_NEE_good ) );
        mean_flux(i) = nanmean( fc_raw_massman_wpl( this_bin & idx_NEE_good ) );
        bin_ceil(i) = mean_flux( i ) + ( n_SDs_filter_hi * std_bin( i ) );
        bin_floor(i) = mean_flux( i ) - ( n_SDs_filter_lo * std_bin( i ) );
        stdflag_thisbin_hi = ( this_bin & ...
            fc_raw_massman_wpl > bin_ceil( i ) );
        stdflag_thisbin_low = ( this_bin & ...
            fc_raw_massman_wpl < bin_floor( i ) );
        stdflag = stdflag | stdflag_thisbin_hi | stdflag_thisbin_low;
        stdflag( find( std_exc_flag ) ) = false;
        
        % %plot each SD window and its mean and SD
        % figure()
        % h_all = plot( decimal_day( this_bin ),...
        %               fc_raw_massman_wpl( this_bin ), 'ok' );
        % hold on
        % if any( stdflag_thisbin_low | stdflag_thisbin_hi )
        %     h_out = plot( decimal_day( stdflag_thisbin_low | ...
        %                                stdflag_thisbin_hi ), ...
        %                   fc_raw_massman_wpl( stdflag_thisbin_low | ...
        %                                       stdflag_thisbin_hi ), ...
        %                   'r.' );
        %     refline( 0, bin_ceil( i ) );
        %     refline( 0, bin_floor( i ) );
        %     legend( [ h_all, h_out ], 'all NEE', 'filtered for SD' );
        % end
        % title( sprintf( 'SD filter, window %d/%d', i, n_bins ) );
        
        elementstouse_c = find(conc_record > startbin( i ) & ...
            conc_record <= endbin( i ) & ...
            isnan(conc_record) == 0);
        conc_std_bin(i) = std(CO2_mean(elementstouse_c));
        mean_conc(i) = mean(CO2_mean(elementstouse_c));
        if sitecode == 7
            conc_bin_index = find(CO2_mean(elementstouse_c) < ...
                (mean_conc(i)-(2 * conc_std_bin(i))) | ...
                CO2_mean(elementstouse_c) > ...
                (mean_conc(i)+(2 * conc_std_bin(i))) & ...
                wnd_spd(elementstouse_c) > 0.3);  ...
                %u_star(elementstouse_c) > ustar_lim);
        else
            conc_bin_index = find(CO2_mean(elementstouse_c) < ...
                (mean_conc(i) - (2 * conc_std_bin(i))) | ...
                CO2_mean(elementstouse_c) > (mean_conc(i) + ...
                (2 * conc_std_bin(i))) & ...
                wnd_spd(elementstouse_c) > 3);  %u_star(elementstouse_c) > ustar_lim);
        end
        conc_outofstdnan = elementstouse_c(conc_bin_index);
        conc_record(conc_outofstdnan) = NaN;
        
        CO2_to_plot = CO2_mean(elementstouse_c);
        wnd_to_plot = wnd_spd(elementstouse_c);
        xxo=ones(length(elementstouse_c),1);
        xaxis=linspace(1,length(elementstouse_c),length(elementstouse_c));
        %
        %         figure(element);
        %         plot(elementstouse_c,CO2_to_plot,'o'); hold on
        %         plot(elementstouse_c,xxo.*mean_conc(i),'r'); hold on
        %         plot(elementstouse_c,xxo.*(mean_conc(i)-(2.*conc_std_bin(i))),'g'); hold on
        %         plot(elementstouse_c,xxo.*(mean_conc(i)+(2.*conc_std_bin(i))),'g'); hold on
        %         plot(elementstouse_c(conc_bin_index),CO2_to_plot(conc_bin_index),'k*')
        %         plot(elementstouse_c,wnd_to_plot+mean_conc(i),'c'); hold on
        %         plot(elementstouse_c,1+mean_conc(i),'m'); hold on
        %         plot(elementstouse_c,10+mean_conc(i),'m'); hold on
        
        xx((i*2)-1)=startbin( i );
        xx(i*2)=endbin( i );
        yy((i*2)-1)=mean_conc(i);
        yy(i*2)=mean_conc(i);
        yyl((i*2)-1)=(mean_conc(i)-(2*conc_std_bin(i)));
        yyl(i*2)=(mean_conc(i)-(2*conc_std_bin(i)));
        yyu((i*2)-1)=(mean_conc(i)+(2*conc_std_bin(i)));
        yyu(i*2)=(mean_conc(i)+(2*conc_std_bin(i)));
        
    end
    idx_NEE_good( stdflag ) = false;
    decimal_day_nan(stdflag) = NaN;
    record(stdflag) = NaN;
    removed_outofstdnan = numel( find (stdflag ) );
    disp(sprintf('    above %d or below %d running standard deviations = %d', ...
        n_SDs_filter_hi, n_SDs_filter_lo, removed_outofstdnan ) );
    
    if xx( end ) > length( decimal_day )
        xx(end) = length(decimal_day);
    end
    pal = cbrewer( 'qual', 'Dark2', 8 );
    
    if draw_plots > 2
        h_co2_fig = figure( 'Name', '[CO2]' );
        CO2_mean_clean=CO2_mean;
        CO2_mean_clean(find(isnan(conc_record)))=-9999;
        h_co2_all = plot( decimal_day, CO2_mean, ...
            'Marker', '.', ...
            'Color', 'black', ...
            'LineStyle', 'none');
        title( sprintf( '%s %d', get_site_name( sitecode ), year( 1 ) ) );
        hold on;
        h_co2_clean = plot( decimal_day, CO2_mean_clean, ...
            'Marker', 'o', ...
            'Color', pal( 1, : ), ...
            'LineStyle', 'none');
        h_co2_mean = plot( decimal_day(xx), yy, ...
            'Marker', 'o', ...
            'Color', pal( 3, : ), ...
            'LineStyle', '-', ...
            'LineWidth', 3);
        h_co2_std = plot( decimal_day(xx), yyl, ...
            'Color', pal( 3, : ), ...
            'linewidth', 3 );
        h_co2_std = plot( decimal_day(xx), yyu, ...
            'Color', pal( 3, : ),...
            'linewidth', 3 );
        xx=linspace(1, length(CO2_mean), length(CO2_mean));
        ylim([300 450]);
        xlabel('day of year');
        ylabel('[CO_2], ppm');
        legend( [ h_co2_all, h_co2_clean, h_co2_mean, h_co2_std ], ...
            'all [CO2]', 'cleaned [CO2]', 'mean [CO2]', 'st dev [CO2]', ...
            'Location', 'best' );
    end  %co2 plot
end % close if statement for iterations

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Plot the co2 flux for the whole series
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

restore_fname = fullfile( getenv( 'FLUXROOT' ), ...
    'FluxOut', ...
    'QC_files', ...
    sprintf( '%s_%d_QC_Tim.mat', ...
    get_site_name( sitecode ), ...
    year( 2 ) ) );
save_vars = { 'sitecode', 'year', 'decimal_day', 'fc_raw_massman_wpl', ...
    'idx_NEE_good', 'ustarflag', 'precipflag', 'nightnegflag', ...
    'windflag', 'maxminflag', 'lowco2flag', 'highco2flag', ...
    'nanflag', 'stdflag', 'n_bins', 'endbin', 'startbin', ...
    'bin_ceil', 'bin_floor', 'mean_flux' };
save( restore_fname, save_vars{ : } );

maxminflag = find( maxminflag );


if sitecode == UNM_sites.PPine
    fprintf( 'Normalizing PPine respiration to [0,10]\n' );
    fc_raw_massman_wpl = normalize_PPine_NEE( fc_raw_massman_wpl, ...
        idx_NEE_good );
end

if draw_plots > 0
    [ h_fig_flux, ax_NEE, ax_flags ] = plot_NEE_with_QC_results( ...
        sitecode, ...
        year, ...
        decimal_day, ...
        fc_raw_massman_wpl, ...
        idx_NEE_good, ustarflag, ...
        precipflag, nightnegflag, ...
        windflag, maxminflag, ...
        lowco2flag, highco2flag, ...
        nanflag, stdflag, n_bins, ...
        endbin, startbin, bin_ceil, ...
        bin_floor, mean_flux );
    shg;  %bring current window to front
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Filter for sensible heat
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% max and mins for HSdry
HS_flag = find(HSdry > HS_max | HSdry < HS_min);
HSdry(HS_flag) = NaN;
% remove HS data when raining, use existing precipflag variable
HSdry(precipflag) = NaN;
% remove HS data when wind is wrong, use existing windflag variable
% HSdry(windflag) = NaN;
% remove HS data with low ustar, use existing ustarflag variable
if iteration > 1
    HSdry(ustarflag) = NaN;
    removed_HS = length(find(isnan(HSdry)));
end

% max and mins for HSdry_massman
HSmass_flag = find(HSdry_massman > HSmass_max | HSdry_massman < HSmass_min);
HSdry_massman(HSmass_flag) = NaN;
% remove HS data when raining, use existing precipflag variable
HSdry_massman(precipflag) = NaN;
% remove HS data when wind is wrong, use existing windflag variable
HSdry_massman(windflag) = NaN;
% remove HS data with low ustar, use existing ustarflag variable
HSdry_massman(ustarflag) = NaN;
removed_HSmass = length(find(isnan(HSdry_massman)));

% clean the co2 flux variables
fc_raw( not( idx_NEE_good ) ) = NaN;
fc_raw_massman( not( idx_NEE_good ) ) = NaN;
fc_water_term( not( idx_NEE_good ) ) = NaN;
fc_heat_term_massman( not( idx_NEE_good ) ) = NaN;
fc_raw_massman_wpl( not( idx_NEE_good ) ) = NaN;

% clean the h2o flux variables - remove points flagged for ustar, wind, or pcp
idx_E_good = repmat( true, size( E_raw ) );
idx_E_good( unique( [ ustarflag; windflag; precipflag ] ) ) = false;
E_raw( not( idx_E_good ) ) = NaN;
E_raw_massman( not( idx_E_good ) ) = NaN;
E_water_term( not( idx_E_good ) ) = NaN;
E_heat_term_massman( not( idx_E_good ) ) = NaN;
E_wpl_massman( not( idx_E_good ) ) = NaN;
% cap water flux at 200 (divide by 18 to get correct units)
E_wpl_massman( E_wpl_massman > ( 200 / 18 ) ) = NaN;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% correction for incorrectly-calculated latent heat flux pointed out by Jim
% Heilman 8 Mar 2012.  E_heat_term_massman should have been added to the
% latent heat flux.  To do the job right, this fix should happen in
% UNM_flux_DATE.m.  Doing the correction here is a temporary fix in order to
% get Ameriflux files created soon.
% -TWH 9 Mar 2012
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Lv = ( repmat( 2.501, size( E_raw_massman ) ) - ...
    0.00237 .* ( Tdry - 273.15 ) )  .* 10^3;
HL_wpl_massman = ( 18.016 / 1000.0 .* Lv ) .* ...
    ( E_raw_massman + E_heat_term_massman );

% clean the co2 concentration
CO2_mean( isnan( conc_record ) ) = NaN;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Filter for max's and min's for other variables
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% QC for HL_raw
LH_flag = ( HL_raw > LH_max ) | ( HL_raw < LH_min );
removed_LH = length( find( LH_flag ) );
HL_raw( LH_flag ) = NaN;

% QC for HL_wpl_massman
LH_min = -20;  %as per Jim Heilman, 28 Mar 2012
% if PAR measurement exists, use this to remove nighttime LE, otherwise
% use NR_tot
LH_rad = Par_Avg;
LH_rad( isnan( LH_rad ) ) = NR_tot( isnan( LH_rad ) );

LH_maxmin_flag = ( HL_wpl_massman > LH_max ) | ( HL_wpl_massman < LH_min );
LH_night_flag = ( LH_rad < 20.0 ) & ( abs( HL_wpl_massman ) > 20.0 );
LH_day_flag = ( LH_rad >= 20.0 ) & ( HL_wpl_massman < 0.0 );
if draw_plots > 2
    script_LE_diagnostic_plot;
end
removed_LH_wpl_mass = numel( find( LH_maxmin_flag | ...
    LH_night_flag | ...
    LH_day_flag ) );
HL_wpl_massman( LH_maxmin_flag | LH_night_flag | LH_day_flag ) = NaN;
% QC for sw_incoming

% QC for Tdry
Tdry_flag = find(Tdry > Tdry_max | Tdry < Tdry_min);
removed_Tdry = length(Tdry_flag);
Tdry(Tdry_flag) = NaN;

% QC for Tsoil

% QC for rH
rH_flag = find(rH > rH_max | rH < rH_min);
removed_rH = length(rH_flag);
rH(rH_flag) = NaN;

% QC for h2o mean values
h2o_flag = ( H2O_mean > h2o_max ) | ( H2O_mean < h2o_min );
removed_h2o = length( find ( h2o_flag ) );
H2O_mean( h2o_flag ) = NaN;

% QC for atmospheric pressure
press_flag = []; %find(atm_press > press_max | atm_press < press_min);
removed_press = length(press_flag);
atm_press(press_flag) = NaN;

% min/max QC for TX soil heat fluxes
if sitecode == 7
    if year_arg == 2005
        soil_heat_flux_open(find(soil_heat_flux_open > 100 | soil_heat_flux_open < -50)) = NaN;
        soil_heat_flux_mescan(find(soil_heat_flux_mescan > 50 | soil_heat_flux_mescan < -40)) = NaN;
        soil_heat_flux_juncan(find(soil_heat_flux_juncan > 50 | soil_heat_flux_juncan < -60)) = NaN;
    elseif year_arg == 2006
        soil_heat_flux_open(find(soil_heat_flux_open > 90 | soil_heat_flux_open < -60)) = NaN;
        soil_heat_flux_mescan(find(soil_heat_flux_mescan > 50 | soil_heat_flux_mescan < -50)) = NaN;
        soil_heat_flux_juncan(find(soil_heat_flux_juncan > 50 | soil_heat_flux_juncan < -60)) = NaN;
    elseif year_arg == 2007
        soil_heat_flux_open(find(soil_heat_flux_open > 110 | soil_heat_flux_open < -50)) = NaN;
        soil_heat_flux_mescan(find(soil_heat_flux_mescan > 40 | soil_heat_flux_mescan < -40)) = NaN;
        soil_heat_flux_juncan(find(soil_heat_flux_juncan > 20 | soil_heat_flux_juncan < -40)) = NaN;
    end
end

% remove days 295 to 320 for GLand 2010 for several variables -- the reported
% values look weirdly bogus -- TWH 9 Apr 2012
if sitecode == 1 & year(2) == 2010
    bogus_idx = ( decimal_day >= 294 ) & ( decimal_day <= 320 );
    HL_wpl_massman( bogus_idx ) = NaN;
    HSdry_massman( bogus_idx ) = NaN;
    E_wpl_massman( bogus_idx ) = NaN;
    lw_incoming( bogus_idx ) = NaN;
    lw_outgoing( bogus_idx ) = NaN;
end

if ( sitecode == 5 ) & ( year(2) == 2008 )
    bogus_idx = ( decimal_day >= 100 ) & ( decimal_day < 190 ) & ( rH < 0.03 );
    rH( bogus_idx ) = NaN;
end

if ( sitecode == 7 ) & ( year( 2 ) == 2008 )
    u_star( u_star > 200 ) = NaN;
end

if ( sitecode == 3 ) & ( year( 2 ) == 2009 )
    u_star( decimal_day < 34 ) = NaN;
    wnd_dir_compass( decimal_day < 34 ) = NaN;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Print to screen the number of removals
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

disp(' ');
disp(sprintf('number of co2 flux values pulled in post-process = %d',(filelength_n-sum(~isnan(record)))));
disp(sprintf('number of co2 flux values used = %d',sum(~isnan(record))));
disp(' ');
disp('Values removed for other qcd variables');
disp(sprintf('    number of latent heat values removed = %d',removed_LH));
disp(sprintf('    number of massman&wpl-corrected latent heat values removed = %d',removed_LH_wpl_mass));
disp(sprintf('    number of sensible heat values removed = %d',removed_HS));
disp(sprintf('    number of massman-corrected sensible heat values removed = %d',removed_HSmass));
disp(sprintf('    number of temperature values removed = %d',removed_Tdry));
disp(sprintf('    number of relative humidity values removed = %d',removed_rH));
disp(sprintf('    number of mean water vapor values removed = %d',removed_h2o));
disp(sprintf('    number of atm press values removed = %d',removed_press));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%WRITE FILE FOR ONLINE GAP-FILLING PROGRAM (REICHSTEIN)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

dd_idx = isnan(decimal_day_nan);
qc = ones(filelength_n,1);
%qc(dd_idx) = 2;
qc( not( idx_NEE_good ) ) = 2;
NEE = fc_raw_massman_wpl;
NEE( not( idx_NEE_good ) ) = -9999;
LE = HL_wpl_massman;
%LE(dd_idx) = -9999;

H_dry = HSdry_massman;
%H_dry(dd_idx) = -9999;
Tair = Tdry - 273.15;

% Calculate VPD Greg Maurer 8/22/2014
tair_temp = Tdry - 273.15;
vpd = 6.1078 * (1 - rH) .* exp(17.08085*tair_temp./(234.175+tair_temp));
%es = 0.6108*exp(17.27*air_temp_hmp./(air_temp_hmp+237.3));
%ea = rH .* es ;
%vpd2 = ea - es;

if draw_plots > 2
    figure('Name', 'NEE vs wind direction' );
    ax1 = subplot( 2, 1, 1 );
    idx = repmat( false, 1, size( fc_raw_massman_wpl, 1 ) );
    idx( idx_NEE_good ) = true;
    idx( sw_incoming < 10 ) = false;
    idx( wnd_dir_compass < 180 | wnd_dir_compass > 260 ) = false;
    plot( wnd_dir_compass( idx ), fc_raw_massman_wpl( idx ), '.' );
    ylabel( 'NEE' ); xlabel( 'wind direction (daytime )' );
    ax2 = subplot( 2, 1, 2 );
    idx = repmat( false, 1, size( fc_raw_massman_wpl, 1 ) );
    idx( idx_NEE_good ) = true;
    idx( sw_incoming > 10 ) = false;
    idx( wnd_dir_compass < 180 | wnd_dir_compass > 260 ) = false;
    plot( wnd_dir_compass( idx ), fc_raw_massman_wpl( idx ), '.' );
    ylabel( 'NEE' ); xlabel( 'wind direction (nighttime )' );
    
    idx = repmat( false, 1, size( fc_raw_massman_wpl, 1 ) );
    idx( idx_NEE_good ) = true;
    %idx( wnd_dir_compass < 180 | wnd_dir_compass > 260 ) = false;
    
    figure('Name', 'NEE vs ustar' );
    plot( u_star( idx ), fc_raw_massman_wpl( idx ), '.' );
    ylabel( 'NEE' ); xlabel( 'ustar' );
    
    figure('Name', 'NEE vs wind speed' );
    plot( wnd_spd( idx ), fc_raw_massman_wpl( idx ), '.' );
    ylabel( 'NEE' ); xlabel( 'wind speed' );
    
    figure( 'Name', 'NEE, T, [CO2], pcp' );
    ax1 = subplot( 4, 1, 1 );
    plot( decimal_day( idx ), fc_raw_massman_wpl( idx ), '.' );
    ylabel( 'NEE' ); xlabel( 'DOY' );
    ax2 = subplot( 4, 1, 2 );
    plot( decimal_day, Tair, '.' );
    ylabel( 'T' ); xlabel( 'DOY' );
    ax3 = subplot( 4, 1, 3 );
    plot( decimal_day( idx ), CO2_mean( idx ), '.' );
    ylabel( '[CO_2]' ); xlabel( 'DOY' );
    ax4 = subplot( 4, 1, 4 );
    plot( decimal_day( precip > 0 ), precip( precip > 0 ), '.' );
    ylabel( 'pcp' ); xlabel( 'DOY' );
    linkaxes( [ ax1, ax2, ax3, ax4 ], 'x' );
end

if sitecode == 1 & year == 2010
    Tair( 12993:end ) = Tair_TOA5(  12993:end );
end

if args.Results.draw_plots > 1
    h_fps = RBD_plot_fingerprints( sitecode, year_arg, decimal_day, ...
        sw_incoming, rH, Tair, NEE, LE, ...
        H_dry, ...
        'fingerprint plots' );
end

filename = sprintf( '%s_flux_all_%d', char( sitecode ), year_arg );
if write_gap_filling_out_file
    Tsoil=ones(size(qc)) .* -9999;
    disp('writing gap-filling file...')
    
    filename = sprintf( '%s_flux_all_%d', char( sitecode ), year_arg );
    outfilename_forgapfill = fullfile( outfolder, ...
        sprintf( '%s_for_gap_filling.txt', ...
        filename ) );
    timestamp = datenum( year, month, day, hour, minute, 0 );
    [ fgf, outfilename_forgapfill ] = ...
        UNM_write_for_gapfiller_file( 'timestamp', timestamp, ...
        'qcNEE', qc, ...
        'NEE', NEE, ...
        'LE', LE, ...
        'H', H_dry, ...
        'Rg', sw_incoming, ...
        'Tair', Tair, ...
        'Tsoil', Tsoil, ...
        'RH', rH, ...
        'VPD', vpd, ...
        'Ustar', u_star, ...
        'Precip', precip, ...
        'fname', outfilename_forgapfill );
    fprintf( 'wrote %s\n', outfilename_forgapfill );
end

% small runs of consecutive zeros in these fields are (1) almost certainly bogus
% and (2) seem to mess up the Lasslop flux partitioning.  Replace them
% here with NaN.
fc_raw_massman_wpl = ...
    replace_consecutive( fc_raw_massman_wpl, 1 );
HL_wpl_massman = ...
    replace_consecutive( HL_wpl_massman, 1 );
HSdry_massman = ...
    replace_consecutive( HSdry_massman, 1 );

% replace daytime consecutive runs of identical PAR observations with NaN
Par_Avg = replace_consecutive_with_condition( Par_Avg, Par_Avg > 5 );

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%WRITE COMPLETE OUT-FILE  (FLUX_all matrix with bad values removed)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if write_complete_out_file
    disp('writing qc file...')
    
    % PPine or MCon
    if sitecode == 5 | sitecode == 6
        header2 = {'timestamp', 'year', 'month', 'day', 'hour', 'minute', ...
            'second', 'jday', 'iok', 'agc_Avg', 'u_star', ...
            'wnd_dir_compass', 'wnd_spd', 'CO2_mean', 'CO2_std', ...
            'H2O_mean', 'H2O_std', 'fc_raw', 'fc_raw_massman', ...
            'fc_water_term', 'fc_heat_term_massman', ...
            'fc_raw_massman_wpl', 'E_raw', 'E_raw_massman', ...
            'E_water_term', 'E_heat_term_massman', 'E_wpl_massman', ...
            'HSdry', 'HSdry_massman', 'HL_raw', 'HL_wpl_massman', ...
            'Tdry', 'air_temp_hmp', ...
            'VWC_2cm', 'precip', 'atm_press', 'rH', 'Par_Avg', ...
            'sw_incoming', 'sw_outgoing', 'lw_incoming', ...
            'lw_outgoing', 'NR_sw', 'NR_lw', 'NR_tot'};
        datamatrix2 = [year, month, day, hour, minute, second, jday, iok, ...
            agc_Avg, u_star, wnd_dir_compass, wnd_spd, CO2_mean, ...
            CO2_std, H2O_mean, H2O_std, fc_raw, fc_raw_massman, ...
            fc_water_term, fc_heat_term_massman, ...
            fc_raw_massman_wpl, E_raw, E_raw_massman, ...
            E_water_term, E_heat_term_massman, E_wpl_massman, ...
            HSdry, HSdry_massman, HL_raw, HL_wpl_massman, Tdry, ...
            air_temp_hmp, VWC, precip ...
            atm_press, rH, Par_Avg, sw_incoming, sw_outgoing, ...
            lw_incoming, lw_outgoing, NR_sw, NR_lw, NR_tot];
        
    elseif sitecode == 7
        header2 = {'timestamp', 'year', 'month', 'day', 'hour', 'minute', ...
            'second', 'jday', 'iok', 'agc_Avg', 'u_star', ...
            'wnd_dir_compass', 'wnd_spd', 'CO2_mean', 'CO2_std', ...
            'H2O_mean', 'H2O_std', 'fc_raw', 'fc_raw_massman', ...
            'fc_water_term', 'fc_heat_term_massman', ...
            'fc_raw_massman_wpl', 'E_raw', 'E_raw_massman', ...
            'E_water_term', 'E_heat_term_massman', 'E_wpl_massman', ...
            'HSdry', 'HSdry_massman', 'HL_raw', 'HL_wpl_massman', ...
            'Tdry', 'air_temp_hmp', 'Tsoil', 'canopy_5cm', ...
            'canopy_10cm', 'open_5cm', 'open_10cm', ...
            'soil_heat_flux_open', 'soil_heat_flux_mescan', ...
            'soil_heat_flux_juncan', 'precip', 'atm_press', 'rH', ...
            'Par_Avg', 'sw_incoming', 'sw_outgoing', 'lw_incoming', ...
            'lw_outgoing', 'NR_sw', 'NR_lw', 'NR_tot'};
        datamatrix2 = [year, month, day, hour, minute, second, jday, iok, ...
            agc_Avg, u_star, wnd_dir_compass, wnd_spd, CO2_mean, ...
            CO2_std, H2O_mean, H2O_std, fc_raw, fc_raw_massman, ...
            fc_water_term, fc_heat_term_massman, ...
            fc_raw_massman_wpl, E_raw, E_raw_massman, ...
            E_water_term, E_heat_term_massman, E_wpl_massman, ...
            HSdry, HSdry_massman, HL_raw, HL_wpl_massman, Tdry, ...
            air_temp_hmp, Tsoil, canopy_5cm, canopy_10cm, ...
            open_5cm, open_10cm, soil_heat_flux_open, ...
            soil_heat_flux_mescan, soil_heat_flux_juncan, precip, ...
            atm_press, rH, Par_Avg, sw_incoming, sw_outgoing, ...
            lw_incoming, lw_outgoing, NR_sw, NR_lw, NR_tot];
        
    elseif sitecode == 8 | sitecode == 9
        header2 = {'timestamp', 'year', 'month', 'day', 'hour', 'minute', ...
            'second', 'jday', 'iok', 'u_star', 'wnd_dir_compass', ...
            'wnd_spd', 'CO2_mean', 'CO2_std', 'H2O_mean', 'H2O_std', ...
            'fc_raw', 'fc_raw_massman', 'fc_water_term', ...
            'fc_heat_term_massman', 'fc_raw_massman_wpl', 'E_raw', ...
            'E_raw_massman', 'E_water_term', 'E_heat_term_massman', ...
            'E_wpl_massman', 'HSdry', 'HSdry_massman', 'HL_raw', ...
            'HL_wpl_massman', 'Tdry', 'air_temp_hmp', 'precip', ...
            'atm_press', 'rH', 'Par_Avg', 'sw_incoming', ...
            'sw_outgoing', 'lw_incoming', 'lw_outgoing', 'NR_sw', ...
            'NR_lw', 'NR_tot'};
        %atm_press=ones(size(precip)) .* -999;
        %air_temp_hmp=ones(size(precip)) .* -999;
        datamatrix2 = [year, month, day, hour, minute, second, jday, iok, ...
            u_star, wnd_dir_compass, wnd_spd, CO2_mean, CO2_std, ...
            H2O_mean, H2O_std, fc_raw, fc_raw_massman, ...
            fc_water_term, fc_heat_term_massman, ...
            fc_raw_massman_wpl, E_raw, E_raw_massman, ...
            E_water_term, E_heat_term_massman, E_wpl_massman, ...
            HSdry, HSdry_massman, HL_raw, HL_wpl_massman, Tdry, ...
            air_temp_hmp, precip, atm_press, rH, Par_Avg, ...
            sw_incoming, sw_outgoing, lw_incoming, lw_outgoing, ...
            NR_sw,NR_lw,NR_tot];
        
        % General output
    else
        Tsoil=ones(size(qc)) .* -9999;
        header2 = {'timestamp', 'year', 'month', 'day', 'hour', ...
            'minute', 'second', 'jday', 'iok', 'agc_Avg', ...
            'u_star', 'wnd_dir_compass', 'wnd_spd', 'CO2_mean', ...
            'CO2_std', 'H2O_mean', 'H2O_std', 'fc_raw', ...
            'fc_raw_massman', 'fc_water_term', ...
            'fc_heat_term_massman', 'fc_raw_massman_wpl', ...
            'E_raw', 'E_raw_massman', 'E_water_term', ...
            'E_heat_term_massman', 'E_wpl_massman', 'HSdry', ...
            'HSdry_massman', 'HL_raw', 'HL_wpl_massman', 'Tdry', ...
            'air_temp_hmp', 'Tsoil', SHF_labels{ : }, 'precip', ...
            'atm_press', 'rH', 'Par_Avg', 'sw_incoming', ...
            'sw_outgoing', 'lw_incoming', 'lw_outgoing', 'NR_sw', ...
            'NR_lw', 'NR_tot'};
        datamatrix2 = [year, month, day, hour, minute, second, jday, iok, ...
            agc_Avg, u_star, wnd_dir_compass, wnd_spd,CO2_mean, ...
            CO2_std,H2O_mean,H2O_std, fc_raw, fc_raw_massman, ...
            fc_water_term, fc_heat_term_massman, ...
            fc_raw_massman_wpl, E_raw,E_raw_massman,E_water_term, ...
            E_heat_term_massman,E_wpl_massman, HSdry, ...
            HSdry_massman,HL_raw,HL_wpl_massman, Tdry, ...
            air_temp_hmp,Tsoil, soil_heat_flux, precip, atm_press, ...
            rH, Par_Avg, sw_incoming, sw_outgoing, lw_incoming, ...
            lw_outgoing,NR_sw,NR_lw,NR_tot];
    end
    
    outfilename_csv = fullfile( outfolder, ...
        sprintf( '%s_qc.txt', filename ) );
    out_data = dataset( { datamatrix2, header2{ 2:end } } );
    export_dataset_tim( outfilename_csv, out_data );
    %export( out_data, 'file', outfilename_csv );
    
    if iteration > 4
        
        if sitecode == 8 | sitecode == 9
            numbers_removed = [removednans removed_precip ...
                removed_wind removed_nightneg ...
                removed_ustar removed_maxs_mins ...
                removed_lowco2 removed_highco2 ...
                removed_outofstdnan NaN ...
                (filelength_n-sum(~isnan(record))) ...
                sum(~isnan(record)) removed_LH ...
                removed_LH_wpl_mass removed_HS ...
                removed_HSmass removed_Tdry ...
                removed_rH removed_h2o];
            removals_header = {'Original nans', ...
                'Precip periods', ...
                'Bad wind direction', ...
                'Night-time negs', ...
                'Low ustar', ...
                'Over max or min', ...
                'Low co2', ...
                'High co2', ...
                'Outside running std', ...
                '', ...
                'Total co2 pulled', ...
                'Total retained', ...
                'LH values removed', ...
                'LH with WPL/Massman removed', ...
                'HS removed', ...
                'HS with massman removed', ...
                'Temp removed', ...
                'Rel humidity removed', ...
                'Water removed'};
            % xlswrite(outfilename, ...
            %          numbers_removed', ...
            %          'numbers removed', ...
            %          'B1');
            % xlswrite (outfilename, ...
            %           removals_header', ...
            %           'numbers removed', ...
            %           'A1');
        else
            numbers_removed = [removednans removed_precip ...
                removed_wind removed_nightneg ...
                removed_ustar removed_maxs_mins ...
                removed_lowco2 removed_highco2 ...
                removed_outofstdnan NaN ...
                (filelength_n-sum(~isnan(record))) ...
                sum(~isnan(record)) removed_LH ...
                removed_LH_wpl_mass removed_HS ...
                removed_HSmass removed_Tdry ...
                removed_rH removed_h2o removed_press];
            removals_header = {'Original nans', ...
                'Precip periods', ...
                'Bad wind direction', ...
                'Night-time negs', ...
                'Low ustar',...
                'Over max or min', ...
                'Low co2', ...
                'High co2', ...
                'Outside running std', ...
                '',...
                'Total co2 pulled', ...
                'Total retained',...
                'LH values removed', ...
                'LH with WPL/Massman removed', ...
                'HS removed', ...
                'HS with massman removed',...
                'Temp removed', ...
                'Rel humidity removed', ...
                'Water removed', ...
                'Pressure removed'};
            % xlswrite(outfilename,numbers_removed','numbers removed','B1');
            % xlswrite (outfilename, removals_header', 'numbers removed', 'A1');
        end
    end
    
    
    if iteration > 6
        
        %         header2 = {'timestamp','year','month','day','hour','minute','second','jday','iok','agc_Avg',...
        %             'wnd_dir_compass','wnd_spd','CO2_mean','CO2_std','H2O_mean','H2O_std',...
        %             'fc_raw','fc_raw_massman','fc_water_term','fc_heat_term_massman','fc_raw_massman_wpl',...
        %             'E_raw','E_raw_massman','E_water_term','E_heat_term_massman','E_wpl_massman',...
        %             'HSdry','HSdry_massman','HL_raw','HL_wpl_massman',...
        %             'Tdry','air_temp_hmp','Tsoil_2cm','Tsoil_6cm','precip','atm_press','rH'...
        %             'Par_Avg','sw_incoming','sw_outgoing','lw_incoming','lw_outgoing','NR_sw','NR_lw','NR_tot'};
        %         datamatrix2 =
        %             [year,month,day,hour,minute,second,jday,iok,agc_Avg,...
        %             wnd_dir_compass,wnd_spd,CO2_mean,CO2_std,H2O_mean,H2O_std,...
        %             fc_raw,fc_raw_massman,fc_water_term,fc_heat_term_massman,fc_raw_massman_wpl,...
        %             E_raw,E_raw_massman,E_water_term,E_heat_term_massman,E_wpl_massman,...
        %             HSdry,HSdry_massman,HL_raw,HL_wpl_massman,...
        %             Tdry,air_temp_hmp,Tsoil_2cm,Tsoil_6cm,precip,atm_press,rH...
        %             Par_Avg,sw_incoming,sw_outgoing,lw_incoming,lw_outgoing,NR_sw,NR_lw,NR_tot];
        
        % RJL removed these 01/22/2014
        % time_out=fix(clock);
        % time_out=datestr(time_out);
        
        % sname={'Site name: Test'};
        % email={'Email: andyfox@unm.edu'};
        % timeo={'Created: ',time_out};
        % outfilename = strcat(outfolder,filename,'_AF.xls');
        % xlswrite(outfilename,sname,'data','A1');
        % xlswrite(outfilename,email,'data','A2');
        % xlswrite(outfilename,timeo,'data','A3');
        % xlswrite(outfilename,header2,'data','A4');
        % xlswrite(outfilename,header2,'data','A5');
        % xlswrite(outfilename,header2,'data','A6');
    end
end

% close all figure windows
%close( h_burba_fig, h_co2_fig, h_fig_flux );
%close( h_burba_fig, h_co2_fig );
%close all;
%------------------------------------------------------------

function NEE = normalize_PPine_NEE( NEE, idx_NEE_good )
% NORMALIZE_PPINE_NEE - normalizes respiration at PPine to a maximum of 10
%   umol/m2/s.  10 was chosen by ML and TWH based on our own data from PPine as
%   well as data from the Metolius ponderosa pine sites in Oregon.

idx = ( NEE > 0 ) & idx_NEE_good;
NEE_bak = NEE;
NEE( idx ) = normalize_vector( NEE( idx ), 0, 10 );

%------------------------------------------------------------

function [ doy_min, doy_max ] = get_daily_maxmin( data_month, ...
    co2_min_by_month, ...
    co2_max_by_month, ...
    winter_co2_min )
% GET_DAILY_MAXMIN - Expands monthly or single-value co2 max, co2 min
%   specifications to half-hourly values for specified year.  With half-hourly
%   values we can easily subsequently implement ad-hoc exceptions for specific
%   site years.

n_obs_in_siteyear = numel( data_month );

doy_max = []; %repmat( NaN, n_obs_in_siteyear, 1 );
doy_min = []; %repmat( NaN, n_obs_in_siteyear, 1 );

if numel( co2_min_by_month ) == 1
    co2_min_by_month = repmat( co2_min_by_month, 1, 12 );
end
if numel( co2_max_by_month ) == 1
    co2_max_by_month = repmat( co2_max_by_month, 1, 12 );
end

% set Jan, Feb, Dec minimum to more restrictive of co2_min_by_month,
% winter_co2_min
winter_co2_min = repmat( winter_co2_min, 1, 3 );
co2_min_by_month( [ 1, 2, 12 ] ) = max( winter_co2_min, ...
    co2_min_by_month( [ 1, 2, 12 ] ) );

for m = 1:12
    n_obs_this_month = numel( find( data_month == m ) );
    doy_max = [ doy_max; repmat( co2_max_by_month( m ), ...
        n_obs_this_month, ...
        1 ) ];
    doy_min = [ doy_min; repmat( co2_min_by_month( m ), ...
        n_obs_this_month, ...
        1 ) ];
end

%------------------------------------------------------------

function [ fc_raw_massman_wpl, E_wpl_massman, HL_wpl_massman, ...
    HSdry, HSdry_massman, CO2_mean, H2O_mean, atm_press, NR_tot, ...
    sw_incoming, sw_outgoing, lw_incoming, lw_outgoing, precip, ...
    rH, Par_Avg, Tdry ] = ...
    remove_specific_problem_periods( sitecode, ...
    year, ...
    fc_raw_massman_wpl, ...
    E_wpl_massman, ...
    HL_wpl_massman, ...
    HSdry, ...
    HSdry_massman, ...
    CO2_mean, ...
    H2O_mean, ...
    atm_press, ...
    NR_tot, ...
    sw_incoming, ...
    sw_outgoing, ...
    lw_incoming, ...
    lw_outgoing, ...
    precip, ...
    rH, ...
    Par_Avg, ...
    Tdry )

% Helper function for UNM_RemoveBadData (RBD for short).  Specifies periods
% where various flux observations did not activate any of the RBD filters,
% yet are deemed biologically impossible.

% if sitecode passed as integer, convert to UNM_sites object
if not( isa( sitecode, 'UNM_sites' ) )
    sitecode = UNM_sites( sitecode );
end

% GLand 2007
switch sitecode
    case UNM_sites.GLand
        switch year
            case 2007
                
                % IRGA problems
                idx = DOYidx( 156 ) : DOYidx( 163 );
                fc_raw_massman_wpl( idx ) = NaN;
                E_wpl_massman( idx ) = NaN;
                HL_wpl_massman( idx ) = NaN;
                CO2_mean( idx  ) = NaN;
                H2O_mean( idx ) = NaN;
                atm_press( idx ) = NaN;
                
                % IRGA problems here -- big jump in [CO2] and suspicious looking fluxes
                idx = DOYidx( 228.5 ) : DOYidx( 235.5 );
                fc_raw_massman_wpl( idx ) = NaN;
                H2O_mean( idx ) = NaN;
                
            case 2008
                sw_incoming( DOYidx( 7 ) : DOYidx( 9 ) ) = NaN;
                
            case 2010
                % IRGA problems
                idx = DOYidx( 102 ) : DOYidx( 119.5 );
                E_wpl_massman( idx ) = NaN;
                HL_wpl_massman( idx ) = NaN;
                H2O_mean( idx ) = NaN;
                
                H2O_mean( DOYidx( 85.5 ) : DOYidx( 102.5 ) ) = NaN;
                
                fc_raw_massman_wpl( DOYidx( 327 ) : DOYidx( 328 ) ) = NaN;
                
            case 2011
                
                % IRGA problems
                idx = DOYidx( 96 ) : DOYidx( 104 );
                fc_raw_massman_wpl( idx ) = NaN;
                E_wpl_massman( idx ) = NaN;
                HL_wpl_massman( idx ) = NaN;
                CO2_mean( idx ) = NaN;
                H2O_mean( idx ) = NaN;
                
                idx = DOYidx( 342 ) : DOYidx( 348 );
                fc_raw_massman_wpl( idx ) = NaN;
                E_wpl_massman( idx ) = NaN;
                HL_wpl_massman( idx ) = NaN;
                CO2_mean( idx ) = NaN;
                H2O_mean( idx ) = NaN;
                
                % [CO2] concentration calibration problem
                idx = DOYidx( 131.6 ) : DOYidx( 164.6 );
                CO2_mean( idx ) = CO2_mean( idx ) + 10.0;
        end
        
    case UNM_sites.SLand
        switch year
            case 2007
                NR_tot( DOYidx( 143 ) : DOYidx( 151 ) ) = NaN;
                sw_outgoing( DOYidx( 150 ) : DOYidx( 162 ) ) = NaN;
            case 2009
                CO2_mean( DOYidx( 139 ) : DOYidx( 142 ) ) = NaN;
                CO2_mean( DOYidx( 287.5 ) : DOYidx( 290.8 ) ) = NaN;
            case 2011
                idx = DOYidx( 342 ) : DOYidx( 348 );
                fc_raw_massman_wpl( idx ) = NaN;
                E_wpl_massman( idx ) = NaN;
                CO2_mean( idx ) = NaN;
                H2O_mean( idx ) = NaN;
                HL_wpl_massman( idx ) = NaN;
        end
        
    case UNM_sites.JSav
        switch year
            case 2010
                lw_outgoing( DOYidx( 130.3 ) : DOYidx( 131.5 ) ) = NaN;
                lw_outgoing( DOYidx( 331.4 ) : DOYidx( 332.7 ) ) = NaN;
                H2O_mean( DOYidx( 221 ) : DOYidx( 229 ) ) = NaN;
            case 2012
                E_wpl_massman( E_wpl_massman > ( 200 / 18 ) ) = NaN;
                
                % there are a smattering of really cold ( < -8 C ) Tdry observations
                % on day 38, 94 & 95, and 138 that are not recorded at PJ.  Remove
                % these here.
                C_to_K = @( T ) T + 273.15;
                tstamps_per_day = 48;  %there are 48 30-minute observations per day
                doy = ( 1:numel( Tdry ) ) ./ tstamps_per_day;
                doy = reshape( doy, size( Tdry ) );
                Tdry( ( Tdry < C_to_K( -10 ) ) & ( doy > 75 ) & ( doy < 150 ) ) = NaN;
                Tdry( ( Tdry < C_to_K( -8 ) ) & ( doy > 37 ) & ( doy < 38 ) ) = NaN;
        end
        
    case UNM_sites.PJ_girdle
        switch year
            case 2009
                CO2_mean( DOYidx( 131.4 ) : DOYidx( 141.5 ) ) = NaN;
                CO2_mean( DOYidx( 284 ) : DOYidx( 293.65 ) ) = NaN;
        end
        
    case UNM_sites.PPine
        switch year
            case 2008
                fc_raw_massman_wpl( DOYidx( 260 ) : DOYidx( 290 ) ) = NaN;
                rH( DOYidx( 100 ) : DOYidx( 187 ) ) = NaN;  %these observation are way
                %too small
                E_wpl_massman( E_wpl_massman > 200 ) = NaN;
            case 2009
                fc_raw_massman_wpl( DOYidx( 157 ) : DOYidx( 159 ) ) = NaN;
                idx = DOYidx( 157 ) : DOYidx( 183 );
                fc_raw_massman_wpl( idx ) = NaN;
                HL_wpl_massman( idx ) = NaN;
                E_wpl_massman( idx ) = NaN;
                E_wpl_massman( E_wpl_massman > 200 ) = NaN;
                HSdry( idx ) = NaN;
                HSdry_massman( idx ) = NaN;
            case 2011
                idx = DOYidx( 186 ) : DOYidx( 200 );
                fc_raw_massman_wpl( idx ) = NaN;
                HL_wpl_massman( idx ) = NaN;
                E_wpl_massman( idx ) = NaN;
            case 2012
                idx = DOYidx( 319.5 );
                % beginning here sw sensor reported all zeros and lw sensor
                % reported NaNs
                sw_incoming( idx:end ) = NaN;
                sw_outgoing( idx:end ) = NaN;
                lw_incoming( idx:end ) = NaN;
                lw_outgoing( idx:end ) = NaN;
            case 2013
                idx = DOYidx( 122.5 );
                % Radiation was still down in early 2013
                sw_incoming( 1:idx ) = NaN;
                sw_outgoing( 1:idx ) = NaN;
        end
        
    case UNM_sites.MCon
        switch year
            case 2009
                sw_incoming( DOYidx( 342 ) : end ) = NaN;
            case 2010
                idx = DOYidx( 134.4 ) : DOYidx( 146.5 );
                CO2_mean( idx ) = CO2_mean( idx ) + 10;
                
                idx = DOYidx( 301.6 ) : DOYidx( 344.7 );
                CO2_mean( idx ) = CO2_mean( idx ) - 17;
            case 2011
                idx = DOYidx( 225.4 ) : DOYidx( 237.8 );
                lw_incoming( idx ) = NaN;
                lw_outgoing( idx ) = NaN;
                E_wpl_massman( idx ) = NaN;
                HL_wpl_massman( idx ) = NaN;
                HSdry( idx ) = NaN;
                HSdry_massman( idx ) = NaN;
                % Our pcp gauge shows huge pcp on DOY 80 and 309, while the nearby
                % met station (Redondo-Redonito) shows none.
                precip( DOYidx( 80 ):DOYidx( 81 ) ) = 0.0;
                precip( DOYidx( 309 ):DOYidx( 310 ) ) = 0.0;
            case 2012
                idx = DOYidx( 254.5 ) : min( DOYidx( 263.7 ), numel( NR_tot ) );
                NR_tot( idx ) = NaN;
                sw_incoming( idx ) = NaN;
                sw_outgoing( idx ) = NaN;
                Par_Avg( DOYidx( 101 ) : DOYidx( 160 ) ) = NaN;
                Par_Avg( DOYidx( 286 ) : DOYidx( 300 ) ) = NaN;
                sw_incoming( DOYidx( 132 ) : DOYidx( 133 ) ) = NaN;
                Par_Avg( DOYidx( 132 ) : DOYidx( 133 ) ) = NaN;
                sw_incoming( DOYidx( 224 ) : DOYidx( 225 ) ) = NaN;
                Par_Avg( DOYidx( 224 ) : DOYidx( 225 ) ) = NaN;
        end
        
    case UNM_sites.TX
        switch year
            case { 2011, 2012 }
                % fill 2011, 2012 gaps at US-FR2 from US-FR3 (certain fields only, as per
                % Marcy's email of 25 Apr 2013: "This site is super close to our site.
                % Can you grab the variables we need from there please.  I would take
                % PAR, Rg, ppt, pressure, AirT, RH at least.  Incoming longwave is
                % probably fine.  Would not get outgoing.")
                fname = fullfile( get_site_directory( UNM_sites.TX_forest ), ...
                    'TAMU_Ameriflux_Files', ...
                    sprintf( 'HeilmanKamps_%dFR3WithGaps.csv', year ) );
                TAMU_data = parse_TAMU_ameriflux_file( fname );
                TAMU_data_shifted = shift_data( double( TAMU_data ), ...
                    1.0, ...
                    'cols_to_shift', ...
                    1:size( TAMU_data, 2 ) );
                
                TAMU_data = replacedata( TAMU_data, TAMU_data_shifted );
                
                TX_draw_plots = false;
                TAMU_data.PAR = normalize_PAR( UNM_sites.TX_forest, ...
                    TAMU_data.PAR, ...
                    TAMU_data.DTIME, ...
                    TX_draw_plots, ...
                    2500 );
                
                TAMU_data.Rg = normalize_PAR( UNM_sites.TX_forest, ...
                    TAMU_data.Rg, ...
                    TAMU_data.DTIME, ...
                    TX_draw_plots, ...
                    1200 );
                
                Par_Avg( isnan( Par_Avg ) ) = TAMU_data.PAR( isnan( Par_Avg ) );
                sw_incoming( isnan( sw_incoming ) ) = ...
                    TAMU_data.Rg( isnan( sw_incoming ) );
                precip( isnan( precip ) ) = TAMU_data.PRECIP( isnan( precip ) );
                atm_press( isnan( atm_press ) ) = TAMU_data.PA( isnan( atm_press ) );
                C_to_K = @(T) T + 273.15;
                Tdry( isnan( Tdry ) ) = ...
                    C_to_K( TAMU_data.TA( isnan( Tdry ) ) );
                rH( isnan( rH ) ) = TAMU_data.RH( isnan( rH ) );
                lw_incoming( isnan( lw_incoming ) ) = ...
                    TAMU_data.Rlong_in( isnan( lw_incoming ) );
                
                E_wpl_massman( E_wpl_massman > 200 ) = NaN;
        end
        
    case UNM_sites.New_GLand
        switch year
            case 2010
                sw_incoming( DOYidx( 355 ) : end ) = NaN;
            case 2014
                % The precip gauge was miswired from Jan 17 to April 2 2014
                precip( DOYidx( 17 ) : DOYidx( 92 ) ) = NaN;
        end
end

%------------------------------------------------------------

function [ DOY_co2_min, DOY_co2_max, std_exc_flag ] = ...
    specify_siteyear_filter_exceptions( sitecode, year, ...
    DOY_co2_min, DOY_co2_max )

% SPECIFY_SITEYEAR_MAXMIN_EXCEPTIONS - % Helper function for UNM_RemoveBadData
% (RBD for short).  Adds site-year-specific DOY-based CO2 NEE max/min values to
% the DOY-based max-min arrays, and defines exceptions to the standard deviation
% filter.  This is meant to be applied to cases where measured NEE seems
% biologically reasonable despite tripping one of the RBD filters.

% initialize standard deviation filter exceptions to no exceptions
std_exc_flag = repmat( false, size( DOY_co2_max ) );

if isa( sitecode, 'double') | isa( sitecode, 'integer' )
    sitecode = UNM_sites( sitecode );
end

switch sitecode
    case UNM_sites.GLand
        switch year
            case 2007
                DOY_co2_max( 1 : DOYidx( 15 ) ) = 1.25;
            case 2008
                idx = DOYidx( 184 ) : DOYidx( 186.5 );
                DOY_co2_max( idx ) = 15;
                std_exc_flag( idx ) = true;
            case 2009
                idx = DOYidx( 245 ) : DOYidx( 255 );
                DOY_co2_max( idx ) = 1.5;
                
                DOY_co2_max( DOYidx( 178 ) : DOYidx( 267 ) ) = 0.8;
                
                % the site burned DOY 210, 2009.  Here we remove points in the period
                % following the burn that look more like noise than biologically
                % realistic carbon uptake.
                DOY_co2_min( DOYidx( 210 ) : DOYidx( 256 ) ) = -0.5;
                DOY_co2_min( DOYidx( 256 ) : DOYidx( 270 ) ) = -1.2;
            case 2010
                DOY_co2_max( DOYidx( 200 ) : DOYidx( 225 ) ) = 2.5;
                DOY_co2_max( 1 : DOYidx( 160 ) ) = 1.5;
                DOY_co2_min( 1 : DOYidx( 160 ) ) = -1.5;
                
                idx = DOYidx( 223 ) : DOYidx( 229 );
                DOY_co2_min( idx ) = -17;
                std_exc_flag( idx ) = true;
            case 2011
                std_exc_flag( DOYidx( 158.4 ) : DOYidx( 158.6 ) ) = true;
                std_exc_flag( DOYidx( 159.4 ) : DOYidx( 159.6 ) ) = true;
                std_exc_flag( DOYidx( 245.4 ) : DOYidx( 245.6 ) ) = true;
                %    std_exc_flag( DOYidx( 337 ) : DOYidx( 343.7 ) ) = true;
                
                DOY_co2_min( DOYidx( 310 ) : end ) = -0.5;
                DOY_co2_min( 1 : DOYidx( 210 ) ) = -0.5;
                
                DOY_co2_max( DOYidx( 261 ) : end ) = 2.0;
                DOY_co2_max( DOYidx( 250 ) : DOYidx( 260 ) ) = 0.8;
                DOY_co2_max( DOYidx( 280 ) : DOYidx( 285 ) ) = 1.2;
            case 2012
                DOY_co2_max( DOYidx( 113 ) : DOYidx( 137 ) ) = 1.0;
                DOY_co2_max( DOYidx( 300 ) : DOYidx( 317 ) ) = 1.7;
                DOY_co2_max( DOYidx( 325 ) : DOYidx( 343 ) ) = 1.4;
                DOY_co2_max( DOYidx( 343 ) : DOYidx( 347 ) ) = 1.2;
                DOY_co2_max( DOYidx( 348 ) : end ) = 0.75;
                std_exc_flag( DOYidx( 174 ) : DOYidx( 175 ) ) = true;
        end %GLand
        
    case UNM_sites.SLand
        switch year
            case 2008
                DOY_co2_min( 1 : DOYidx( 50 ) ) = -0.5;
                
                idx = DOYidx( 184 ) : DOYidx( 190 );
                DOY_co2_max( idx ) = 20;
                std_exc_flag( idx ) = true;
            case 2010
                DOY_co2_min( 1 : DOYidx( 80 ) ) = -1.4;
                DOY_co2_max( DOYidx( 204 ) : DOYidx( 220 ) ) = 2.0;
            case 2011
                idx = DOYidx( 215.5 ) : DOYidx( 216.4 );
                std_exc_flag( idx ) = true;
                
                idx = DOYidx( 190 ) : DOYidx( 195 );
                DOY_co2_max( idx ) = 7;
                std_exc_flag( idx ) = true;
                
                DOY_co2_min(  1 : DOYidx( 70.0 ) ) = -0.5;
                DOY_co2_max(  1 : DOYidx( 70.0 ) ) = 1.0;
                DOY_co2_min( DOYidx( 80  ) : DOYidx( 100 ) ) = -2.0;
                
                std_exc_flag( DOYidx( 20.4) : DOYidx( 20.6 ) ) = true;
                
                DOY_co2_min(  DOYidx( 185 ) : end ) = -1.5;
            case 2012
                DOY_co2_max(  DOYidx( 285 ) : DOYidx( 328 ) ) = 0.95;
                DOY_co2_max(  DOYidx( 323.2 ) : DOYidx( 323.8 ) ) = 2.5;
                std_exc_flag( DOYidx( 323.2 ) : DOYidx( 323.8 ) ) = true;
                DOY_co2_max(  DOYidx( 328 ) : end ) = 0.5;
            case 2013
                DOY_co2_max(  DOYidx( 21 ) : DOYidx( 27 ) ) = 0.5;
                DOY_co2_max(  DOYidx( 28 ) : DOYidx( 30 ) ) = 2.0;
                DOY_co2_max(  DOYidx( 208 ) : DOYidx( 216 ) ) = 2.0;
                DOY_co2_max(  DOYidx( 216 ) : DOYidx( 225 ) ) = 2.7;
                DOY_co2_min(  DOYidx( 125 ) : DOYidx( 134 ) ) = -1.0;
                DOY_co2_min(  DOYidx( 155 ) : DOYidx( 170 ) ) = -1.0;
                DOY_co2_min(  DOYidx( 208 ) : DOYidx( 216 ) ) = -5.0;
                DOY_co2_min(  DOYidx( 224 ) : DOYidx( 225 ) ) = -5.0;
        end %SLand
        
    case UNM_sites.JSav
        switch year
            case 2008
                idx = DOYidx( 215 ) : DOYidx( 240 );
                DOY_co2_min( idx ) = -12.0;
                
            case 2009
                DOY_co2_max( 1 : DOYidx( 125 ) ) = 2.0;
                DOY_co2_max( DOYidx( 150 ) : DOYidx( 180 ) ) = 2.0;
                DOY_co2_max( DOYidx( 220 ) : DOYidx( 250 ) ) = 2.5;
                DOY_co2_max( DOYidx( 251 ) : DOYidx( 280 ) ) = 4.0;
                DOY_co2_max( DOYidx( 281 ) : DOYidx( 365 ) ) = 2.5;
                DOY_co2_min( 1 : DOYidx( 94 ) ) = -6.0;
                
            case 2010
                DOY_co2_max( 1 : DOYidx( 80 ) ) = 2.0;
                DOY_co2_max( DOYidx( 81 ) : DOYidx( 190 ) ) = 4.0;
                DOY_co2_max( DOYidx( 190 ) : DOYidx( 210 ) ) = 6.0;
                DOY_co2_max( DOYidx( 211 ) : DOYidx( 225 ) ) = 5.0;
                DOY_co2_max( DOYidx( 226 ) : end ) = 3.0;
                
            case 2011
                DOY_co2_min( 1 : DOYidx( 40 ) ) = -2.0;
                DOY_co2_max( DOYidx( 210 ) : DOYidx( 220 ) ) = 5.0;
                DOY_co2_max( DOYidx( 221 ) : DOYidx( 265 ) ) = 4.0;
                DOY_co2_max( DOYidx( 266 ) : end ) = 3.0;
                
                std_exc_flag( DOYidx( 12.5 ) : DOYidx( 12.6 ) ) = true;
                std_exc_flag( DOYidx( 17.4 ) : DOYidx( 17.6 ) ) = true;
                std_exc_flag( DOYidx( 20.4 ) : DOYidx( 20.7 ) ) = true;
                std_exc_flag( DOYidx( 58.4 ) : DOYidx( 58.6 ) ) = true;
                std_exc_flag( DOYidx( 64.3 ) : DOYidx( 64.5 ) ) = true;
                std_exc_flag( DOYidx( 73.4 ) : DOYidx( 73.5 ) ) = true;
                std_exc_flag( DOYidx( 184.5 ) : DOYidx( 186 ) ) = true;
                std_exc_flag( DOYidx( 232.0 ) : DOYidx( 232.1 ) ) = true;
                std_exc_flag( DOYidx( 313.4 ) : DOYidx( 313.6 ) ) = true;
                
            case 2012
                DOY_co2_max( DOYidx( 137 ) : DOYidx( 148 ) ) = 5.0;
                DOY_co2_max( DOYidx( 185 ) : DOYidx( 220 ) ) = 5.0;
                DOY_co2_max( DOYidx( 245 ) : DOYidx( 285 ) ) = 5.0;
                DOY_co2_max( DOYidx( 314 ) : DOYidx( 316 ) ) = 1.2;
                DOY_co2_max( DOYidx( 325 ) : DOYidx( 326 ) ) = 1.0;
                DOY_co2_min( DOYidx( 325 ) : DOYidx( 329 ) ) = -1.5;
                DOY_co2_min( DOYidx( 330 ) : end ) = -0.75;
                
        end  %JSav
        
    case UNM_sites.PJ
        switch year
            case 2008
                DOY_co2_max( 1 : DOYidx( 185 ) ) = 3.0;
                DOY_co2_min( DOYidx( 260 ) : DOYidx( 290 ) ) = -18.0;
                DOY_co2_min( DOYidx( 335 ) : DOYidx( 365 ) ) = -6.5;
                
            case 2009
                DOY_co2_max( 1 : DOYidx( 180 ) ) = 3.0;
                DOY_co2_max( DOYidx( 190 ) : DOYidx( 260 ) ) = 4.0;
                
            case 2011
                std_exc_flag( DOYidx( 31.5 ) : DOYidx( 31.7 ) ) = true;
                std_exc_flag( DOYidx( 182.6 ) : DOYidx( 182.8 ) ) = true;
                std_exc_flag( DOYidx( 183.4 ) : DOYidx( 183.7 ) ) = true;
                std_exc_flag( DOYidx( 329.0 ) : DOYidx( 329.7 ) ) = true;
                
                DOY_co2_max( DOYidx( 329.0 ) : DOYidx( 329.7 ) ) = 6.5;
                DOY_co2_min( DOYidx( 350 ) : end ) = -1.0;
                
            case 2012
                DOY_co2_max( DOYidx( 307 ) : end ) = 1.0;
                
            case 2013
                DOY_co2_max( DOYidx( 195 ) : DOYidx( 195 ) ) = 2.0;
                DOY_co2_max( DOYidx( 210 ) : DOYidx( 227 ) ) = 4.0;
        end  %PJ
        
    case UNM_sites.PPine
        switch year
            case 2007
                DOY_co2_max( DOYidx( 185 ) : DOYidx( 259.99 ) ) = 10.0;
                DOY_co2_max( DOYidx( 240 ) : DOYidx( 276 ) ) = 5.5;
                DOY_co2_max( DOYidx( 276 ) : DOYidx( 277 ) ) = 5.0;
                DOY_co2_max( DOYidx( 277 ) : DOYidx( 279 ) ) = 10.0;
                DOY_co2_max( DOYidx( 280 ) : end ) = 5.0;
                
            case 2009
                DOY_co2_max( : ) = 10;
                DOY_co2_max( DOYidx( 64 ) : DOYidx( 67 ) ) = 15.0;
                DOY_co2_max( DOYidx( 67 ) : DOYidx( 150 ) ) = 8.0;
                DOY_co2_max( DOYidx( 300 ) : end ) = 10.0;
                
            case 2011
                std_exc_flag( DOYidx( 171 ) : DOYidx( 172 ) ) = true;
                DOY_co2_min( DOYidx( 291.4 ) : DOYidx( 291.6 ) ) = -20.0;
                
            case 2012
                DOY_co2_min( DOYidx( 90 ) : DOYidx( 140 ) ) = -20.0;
                DOY_co2_max( DOYidx( 353 ) : DOYidx( 355 ) ) = 4.0;
                
            case 2013 %Added by RJL based on Marcy request 11/22/2013
                DOY_co2_min( DOYidx( 220 ) : end ) = -18.0;
        end
        
    case UNM_sites.MCon
        switch year
            case 2007
                idx = DOYidx( 120.35 ) : DOYidx( 120.55 );
                std_exc_flag( idx ) = true;
                DOY_co2_min( idx ) = -15;
                std_exc_flag( DOYidx( 292.4 ) : DOYidx( 294.5 ) ) = true;
                std_exc_flag( DOYidx( 293.5 ) : DOYidx( 293.6 ) ) = true;
                std_exc_flag( DOYidx( 301.5 ) : DOYidx( 301.7 ) ) = true;
                
                DOY_co2_max( DOYidx( 75 ) : DOYidx( 86 ) ) = 2.0;
                DOY_co2_max( DOYidx( 176 ) : DOYidx( 206 ) ) = 3.5;
                DOY_co2_max( DOYidx( 207 ) : DOYidx( 297 ) ) = 4.0;
                DOY_co2_min( DOYidx( 327 ) : end ) = -2.0;
                
            case 2008
                std_exc_flag( DOYidx( 43.5 ) : DOYidx( 43.6 ) ) = true;
                std_exc_flag( DOYidx( 88 ) : DOYidx( 93 ) ) = true;
                std_exc_flag( DOYidx( 121 ) : DOYidx( 122 ) ) = true;
                
                DOY_co2_min( 1 : DOYidx( 106 ) ) = -2.0;
                DOY_co2_max( DOYidx( 125 ) : DOYidx( 155 ) ) = 3.0;
                
            case 2009
                DOY_co2_min( DOYidx( 83 ) : DOYidx( 100 ) ) = -3.0;
                DOY_co2_max( DOYidx( 83 ) : DOYidx( 100 ) ) = 4.0;
                DOY_co2_max( DOYidx( 156 ) : DOYidx( 305 ) ) = 4.0;
                DOY_co2_max( DOYidx( 311 ) : end ) = 3.0;
                
            case 2010
                DOY_co2_max( DOYidx( 200 ) : DOYidx( 244 ) ) = 4.0;
                DOY_co2_max( DOYidx( 246 ) : DOYidx( 300 ) ) = 3.0;
                
            case 2011
                
                DOY_co2_max( DOYidx( 95 ) : DOYidx( 166 ) ) = 4.0;
                DOY_co2_max( DOYidx( 180 ) : end ) = 4.0;
                
            case 2012
                DOY_co2_max( DOYidx( 344 ) : end ) = 2.0;
                
            case 2013
                DOY_co2_max( 1 : DOYidx( 18 ) ) = 1.0;
                DOY_co2_max( DOYidx( 27 ) : DOYidx( 31 ) ) = 0.8;
                DOY_co2_min( DOYidx( 27 ) : DOYidx( 31 ) ) = -1.5;
                DOY_co2_max( DOYidx( 67.5 ) : DOYidx( 69.55 ) ) = 1.0;
                DOY_co2_min( DOYidx( 67.5 ) : DOYidx( 69.55 ) ) = -2.0;
                DOY_co2_max( DOYidx( 76 ) : DOYidx( 76.6 ) ) = 1.0;
                DOY_co2_min( DOYidx( 76 ) : DOYidx( 76.6 ) ) = -2.0;
        end  % MCon
        
    case UNM_sites.TX
        switch year
            case 2009
                DOY_co2_max( DOYidx( 163 ) : DOYidx( 163.5 ) ) = 9.0;
                DOY_co2_max( DOYidx( 265 ) : DOYidx( 305 ) ) = 12.0;
                
            case 2011
                DOY_co2_max( 1 : DOYidx( 31 ) ) = 3.0;
                DOY_co2_max( DOYidx( 33 ) : DOYidx( 45 ) ) = 3.0;
                DOY_co2_max( DOYidx( 33 ) : DOYidx( 45 ) ) = 3.0;
                
            case 2012
                DOY_co2_max( 1 : DOYidx( 30 ) ) = 3.0;
                DOY_co2_max( DOYidx( 152 ) : DOYidx( 160 ) ) = 5.0;
                DOY_co2_max( DOYidx( 318 ) : DOYidx( 326 ) ) = 4.0;
                DOY_co2_max( DOYidx( 345 ) : end ) = 2.1;
        end % TX
        
    case UNM_sites.PJ_girdle
        switch year
            case 2009
                DOY_co2_max( 1 : DOYidx( 100 ) ) = 1.5;
                DOY_co2_max( DOYidx( 100 ) : DOYidx( 140 ) ) = 2.5;
                DOY_co2_max( DOYidx( 140 ) : DOYidx( 176 ) ) = 2.0;
                DOY_co2_max( DOYidx( 177 ) : DOYidx( 191 ) ) = 4.0;
                DOY_co2_max( DOYidx( 244 ) : DOYidx( 267 ) ) = 3.2;
                DOY_co2_max( DOYidx( 275 ) : DOYidx( 299 ) ) = 3.0;
                DOY_co2_max( DOYidx( 300 ) : end ) = 2.0;
                
            case 2011
                idx = DOYidx( 192.2 ) : DOYidx( 192.6 );
                std_exc_flag( idx ) = true;
                DOY_co2_max( idx ) = 6.5;
                DOY_co2_min( DOYidx( 350 ) : end ) = -1.0;
                
            case 2012
                DOY_co2_max( DOYidx( 260 ) : DOYidx( 280 ) ) = 2.0;
                DOY_co2_max( DOYidx( 285 ) : DOYidx( 290 ) ) = 1.5;
                
            case 2013
                DOY_co2_max( DOYidx( 213 ) : DOYidx( 214  ) ) = 3.0;
                DOY_co2_max( DOYidx( 222 ) : DOYidx( 226  ) ) = 4.0;
        end
        
    case UNM_sites.New_GLand
        switch year
            case 2011
                std_exc_flag( DOYidx( 39.5 ) : DOYidx( 39.7 ) ) = true;
                std_exc_flag( DOYidx( 50.5 ) : DOYidx( 50.7 ) ) = true;
                std_exc_flag( DOYidx( 58.5 ) : DOYidx( 58.7 ) ) = true;
                std_exc_flag( DOYidx( 66.6 ) : DOYidx( 66.8 ) ) = true;
                std_exc_flag( DOYidx( 72.5 ) : DOYidx( 72.6 ) ) = true;
                std_exc_flag( DOYidx( 89.55 ) : DOYidx( 89.65 ) ) = true;
                std_exc_flag( DOYidx( 104.48 ) : DOYidx( 104.52 ) ) = true;
                std_exc_flag( DOYidx( 107.52 ) : DOYidx( 107.58 ) ) = true;
                std_exc_flag( DOYidx( 129.48 ) : DOYidx( 129.56 ) ) = true;
                
                idx = DOYidx( 80.5 ) : DOYidx( 80.65 );
                std_exc_flag( idx ) = true;
                DOY_co2_max( idx ) = 6.9;
                
                
                idx = DOYidx( 99.45 ) : DOYidx( 99.6 );
                std_exc_flag( idx ) = true;
                DOY_co2_max( idx ) = 7.4;
                
                idx = DOYidx( 116.5 ) : DOYidx( 116.6 );
                std_exc_flag( idx ) = true;
                DOY_co2_max( idx ) = 7.2;
                
                DOY_co2_max( DOYidx( 194 ) : DOYidx( 195 ) ) = 2.3;
                std_exc_flag( DOYidx( 201 ) : DOYidx( 203 ) ) = true;
                std_exc_flag( DOYidx( 225.6 ) : DOYidx( 225.7 ) ) = true;
                std_exc_flag( DOYidx( 290.4 ) : DOYidx( 290.6 ) ) = true;
                std_exc_flag( DOYidx( 335.45 ) : DOYidx( 335.6 ) ) = true;
                DOY_co2_max( DOYidx( 344.5 ) : DOYidx( 344.7 ) ) = 9.0;
                DOY_co2_max( DOYidx( 345.48 ) : DOYidx( 345.56 ) ) = 9.0;
                
            case 2012
                DOY_co2_max( DOYidx( 215 ) : DOYidx( 285 ) ) = 2.0;
                DOY_co2_max( DOYidx( 306 ) : DOYidx( 312 ) ) = 1.5;
                DOY_co2_max( DOYidx( 312 ) : DOYidx( 347 ) ) = 1.5;
                DOY_co2_max( DOYidx( 348 ) : end ) = 0.75;
                
            case 2013 %Added by RJL based on Marcy request 11/22/2013
                DOY_co2_min( DOYidx( 160 ) : DOYidx( 190 ) ) = -3.0;
%                 DOY_co2_min( DOYidx( 190 ) : DOYidx( 200 ) ) = -4.0;
%                 DOY_co2_min( DOYidx( 200 ) : DOYidx( 208 ) ) = -9.0;
%                 DOY_co2_min( DOYidx( 208 ) : DOYidx( 210 ) ) = -10.0;
%                 DOY_co2_min( DOYidx( 210 ) : DOYidx( 233 ) ) = -15.0;
%                 DOY_co2_min( DOYidx( 233 ) : DOYidx( 238 ) ) = -8.0;
%                 DOY_co2_min( DOYidx( 238 ) : DOYidx( 255 ) ) = -4.0;
%                 DOY_co2_min( DOYidx( 255 ) : DOYidx( 264 ) ) = -6.0;
%                 DOY_co2_min( DOYidx( 264 ) : DOYidx( 272 ) ) = -7.0;
                DOY_co2_min( DOYidx( 292 ) : end ) = -6.0;
        end  % New_GLand
end

%------------------------------------------------------------

function co2_conc_filter_exceptions = ...
    specify_siteyear_co2_conc_filter_exceptions( ...
    sitecode, year, co2_conc_filter_exceptions )
% Helper function for UNM_RemoveBadData (RBD for short).  Disables the high and
% low CO2 concentration filters for specified time periods (noted in the code
% below).  There are periods of incorrect [CO2] observations from the IRGA which
% nonetheless contain reasonable CO2 NEE.  This allows us to keep those NEE
% measurements.

if ( sitecode == 1 ) & ( year(1) == 2007 )
    co2_conc_filter_exceptions( DOYidx( 214 ) : DOYidx( 218 ) ) = true;
end

% keep index 5084 to 5764 in 2010 - these CO2 obs are bogus but the
% fluxes look OK.  TWH 27 Mar 2012
if ( sitecode == 1 ) & ( year(1) == 2010 )
    % keep index 4128 to 5084, 7296-8064 (days 152:168) in 2010 -
    % these CO2 obs are bogus but the datalogger 30-min fluxes look OK.  TWH 27
    % Mar 2012
    co2_conc_filter_exceptions( 4128:5764 ) = true;
    co2_conc_filter_exceptions( 7296:8064 ) = true;
    % days 253:257 -- bogus [CO2] but fluxes look ok
    co2_conc_filter_exceptions( DOYidx( 218 ) : DOYidx( 223 ) ) = true;
    %co2_conc_filter_exceptions( DOYidx( 271 ) : DOYidx( 278 ) ) = true;
end
if ( sitecode == 1 ) & ( year(1) == 2011 )
    co2_conc_filter_exceptions( DOYidx( 153 ) : DOYidx( 160 ) ) = true;
end
if ( sitecode == 1 ) & ( year == 2012 )
    co2_conc_filter_exceptions( DOYidx( 78 ) : DOYidx( 94 ) ) = true;
end
if ( sitecode == 2 ) & ( year == 2007 )
    % days 253:257 -- bogus [CO2] but fluxes look ok
    co2_conc_filter_exceptions( DOYidx( 253 ) : DOYidx( 257 ) ) = true;
end
if ( sitecode == 2 ) & ( year == 2012 )
    co2_conc_filter_exceptions( DOYidx( 323.2 ) : DOYidx( 323.8 ) ) = true;
end
if ( sitecode == 3 ) & ( year(1) == 2011 )
    co2_conc_filter_exceptions( DOYidx( 41.6 ) : DOYidx( 52.7 ) ) = true;
end
if ( sitecode == 4 ) & ( year(1) == 2011 )
    co2_conc_filter_exceptions( DOYidx( 358  ) : end ) = true;
end
if ( sitecode == 4 ) & ( year(1) == 2012 )
    co2_conc_filter_exceptions( 1 : DOYidx( 10 ) ) = true;
end
if (sitecode == 5 ) & ( year == 2007 )
    % days 290:335 -- bogus [CO2] but fluxes look ok
    co2_conc_filter_exceptions( DOYidx( 290 ) : DOYidx( 335 ) ) = true;
end
if (sitecode == 8 ) & ( year == 2009 )
    % days 1 to 40.5 -- low [CO2] but fluxes look ok
    co2_conc_filter_exceptions( DOYidx( 1 ) : DOYidx( 40.5 ) ) = true;
end

%------------------------------------------------------------

function SHF_labels = format_SHF_labels( SHF_labels)
% FORMAT_SHF_LABELS - remove extraneous text from heat flux plate labels and
% format a common prefix of "SHF"
%

SHF_labels = regexprep( SHF_labels, 'hfp01_(.*)', 'SHF_$1'); % hfp01 -> SHF
SHF_labels = regexprep( SHF_labels, 'shf_(.*)', 'SHF_$1'); % capitalize SHF
SHF_labels = regexprep( SHF_labels, '[Aa]vg', ''); %remove "Avg" (case
%insensitive)
SHF_labels = regexprep( SHF_labels, '[()]', ''); % remove parens
SHF_labels = regexprep( SHF_labels, '_$', '');  %remove trailing _
