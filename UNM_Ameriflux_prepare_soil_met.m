function ds_out =  UNM_Ameriflux_prepare_soil_met( sitecode, year, ...
                                                  data, ds_qc )
% UNM_AMERIFLUX_PREPARE_SOIL_MET - 
%   
% contains the section of UNM_Ameriflux_file_maker.m as of 15 Aug 2011 that
% gathers/calculates all the soil met properties.  By modularizing it here it
% should make it easier to streamline this going into the future.  I have gone
% through and replaced QC columns with ds_qc -- the dataset created by
% fluxallqc_2_dataset.m.  Abbreviations: SWC: soil water content; VWC:
% volumetric water content.
%   
%

sitecode = UNM_sites( sitecode );
SWC_smoothed = false; % will set to true after SWC data have been smoothed

t0 = now();
fprintf( 1, 'Begin soil met properties...' );

% some site-years have non-descriptive labels for soil data columns.  Replace
% these with descriptive labels.
data = UNM_assign_soil_data_labels( sitecode, year, data );

% create a column of -9999s to place in the dataset where a site does not
% record a particular variable
dummy = repmat( -9999, size( data, 1 ), 1 );

% find any soil heat flux columns within QC data
shf_vars = regexp_ds_vars( data, '(SHF|soil_heat_flux|shf).*' );
SHF = [];
n_shf_vars = numel( shf_vars );  % how many SHF columns are there?    

% -----
% get soil water content and soil temperature data
% -----

switch sitecode
  case { UNM_sites.GLand, UNM_sites.SLand, UNM_sites.JSav, ...
         UNM_sites.TX, UNM_sites.TX_forest, UNM_sites.TX_grass, ...
         UNM_sites.New_GLand }
    % all sites except PJ and PJ_girdle store their soil data in the
    % FluxAll file

    % pull soil water content (SWC), soil temperature (T), and TCAV soil T
    % measurements out of the FluxAll data.

    % get the soil water content and soil T columns and labels

    re_Tsoil = 'soilT_[A-Za-z]+_[0-9]+_[0-9]+.*'; %regexp to identify
                                                  %"soilT_COVER_NUMBER_DEPTH"
    Tsoil = data( :, regexp_ds_vars( data, re_Tsoil ) );
    if isempty( Tsoil )
        re_Tsoil_form2 = 'Tsoil_avg'; 
        Tsoil = data( :, regexp_ds_vars( data, re_Tsoil_form2 ) );
    end

    if ( sitecode == UNM_sites.JSav ) & ( year == 2008 )
        % Jsav 2008 has more Tsoil observations than SWC observations.
        % Remove the observations that don't correspond to a SWC observation.
        Tsoil = JSav_match_soilT_SWC( Tsoil );
    end
    
    cs616_pd = data( :, regexp_ds_vars( data, ...
                                        'cs616SWC_[A-Za-z]+_[0-9]+_[0-9]+.*' ) );
    
    win = 25;
    cs616_pd = UNM_soil_data_smoother( cs616_pd, ...
                                       win, ...
                                       [ 15, 40 ], ...
                                       [ -0.1, 0.07 ] );
    SWC_smoothed = true;
    %dataset_viewer( cs616_pd );
    Tsoil_smoothed = UNM_soil_data_smoother( cs616_pd, ...
                                             win, ...
                                             [ -100, 100 ], ...
                                             [ NaN, NaN ] );
    
    % plot_soil_pit_data( Tsoil_smoothed, ds_qc.precip );
    % plot_soil_pit_data( cs616_pd, ds_qc.precip );
    
    % if necessary, convert CS616 periods to volumetric water content
    [ cs616_hilo_removed, ...
      cs616_Tc_hilo_removed ] = cs616_period2vwc( cs616_pd, Tsoil_smoothed, ...
                                                  sitecode, year, ...
                                                  'draw_plots', false, ...
                                                  'save_plots', false );
    fprintf( 'Tsoil probes detected: %d\n', size( Tsoil, 2 ) );

    TCAV = data( :, regexp_ds_vars( data, ...
                                     'TCAV_[A-Za-z]+.*' ) );
  case { UNM_sites.PPine }
    cs616 = preprocess_PPine_soil_data( sitecode, year );
    cs616 = cs616( find_unique( cs616.timestamp ), : );
    cs616.timestamp = [];
    cs616_Tc = cs616;  % PPine SWC data are already in VWC form

    re_Tsoil = 'soilT.*';
    Tsoil = data( :, regexp_ds_vars( data, re_Tsoil ) );
    
    TCAV = data( :, regexp_ds_vars( data, ...
                                    'TCAV_[A-Za-z]+.*' ) );
    
  case { UNM_sites.MCon }
    cs616 = preprocess_MCon_soil_data( sitecode, year );
    cs616.timestamp = [];
    cs616_Tc = cs616;  % MCon SWC data are already in VWC form

    re_Tsoil = 'soilT.*';
    Tsoil = data( :, regexp_ds_vars( data, re_Tsoil ) );
    
    TCAV = data( :, regexp_ds_vars( data, ...
                                    'TCAV_[A-Za-z]+.*' ) );
        
  case { UNM_sites.PJ, UNM_sites.PJ_girdle }
    % PJ and PJ_girdle store their soil data outside of FluxAll.
    % These data are already converted to VWC.
    
    [ Tsoil, cs616, SHF ] = preprocess_PJ_soil_data( sitecode, year );
    if any( ( Tsoil.tstamps - data.timestamp ) > 1e-10 )
        error( 'soil data timestamps do not match fluxall timestamps' );
    end
    Tsoil.tstamps = [];
    cs616.tstamps = [];
    SHF.tstamps = [];
    cs616_Tc = cs616; %replacedata( cs616, repmat( NaN, size( cs616 ) ) );
    TCAV = [];
    
end

switch sitecode
  case UNM_sites.SLand
    switch year
      case 2009
        temp = double( Tsoil );
        temp( 1:DOYidx( 201.5 ), : ) = NaN;
        Tsoil = replacedata( Tsoil, temp );
    end
end

% these sensors have problems with electrical noise -- remove noisy points
win = 7;  % moving average window of six elements => six hours total window
T_min_max = [ -100, 100 ];
T_delta_filter = [ NaN, NaN ];  %do not filter soil T on delta(T)
Tsoil_hilo_removed = UNM_soil_data_smoother( Tsoil, ...
                                             win, ...
                                             T_min_max, ...
                                             T_delta_filter );
if not( SWC_smoothed )
    fprintf( 'smoothing soil water\n' );
    SWC_delta_filter = [ -0.1, 0.07 ];
    SWC_min_max = [ 0, 1 ];
    cs616_hilo_removed = UNM_soil_data_smoother( cs616, ...
                                                 win, ...
                                                 SWC_min_max, ...
                                                 SWC_delta_filter );
    cs616_Tc_hilo_removed = UNM_soil_data_smoother( cs616_Tc, ...
                                                    win, ...
                                                    SWC_min_max, ...
                                                    SWC_delta_filter );
end

draw_plots = false;
Tsoil_hilo_removed = fill_soil_temperature_gaps( Tsoil_hilo_removed, ...
                                                 ds_qc.precip, ...
                                                 draw_plots );
cs616_Tc_hilo_removed = fill_soil_water_gaps( cs616_hilo_removed, ...
                                           ds_qc.precip, ...
                                           draw_plots );


% calculate averages by cover type, depth
[ Tsoil_cover_depth_avg, ...
  Tsoil_cover_avg, ...
  Tsoil_depth_avg ] = soil_data_averager( Tsoil_hilo_removed, ...
                                          'draw_plots', false, ...
                                          'fill_type', 'interp' );
[ VWC_cover_depth_avg, ...
  VWC_cover_avg, ...
  VWC_depth_avg ] = soil_data_averager( cs616_Tc_hilo_removed, ...
                                        'draw_plots', false, ...
                                        'fill_type', 'interp' );

if not( isempty( TCAV ) )
    soil_surface_T = TCAV;
else
    soil_surface_T = Tsoil_cover_avg;
end

if sitecode == UNM_sites.JSav
    soil_surface_T = Tsoil_cover_avg;
end

% if there's only one soil temp measurement, use it for all SWC measurements
if size( soil_surface_T, 2 ) == 1
    soil_surface_T = ...
        repmat( soil_surface_T, 1, size( VWC_cover_avg, 2 ) );
    % give the replicated T values descriptive names
    soil_surface_T.Properties.VarNames = ...
        regexprep( VWC_cover_avg.Properties.VarNames, ...
                   'VWC', ...
                   'soilT' );
end

% -----
% -----
% now we have T-corrected VWC and soil T. Calculate heat flux with storage.
% -----
% -----

SHF_pars = define_SHF_pars( sitecode, year );
if not( ismember( sitecode, [ UNM_sites.PJ, UNM_sites.PJ_girdle ] ) )
    SHF = data( :, shf_vars );
    shf_vars = cellfun( @(x) [ x, '_0' ], shf_vars, 'UniformOutput', false );
    SHF.Properties.VarNames = shf_vars; 
end
if not( isempty( SHF ) )
    [ SHF_cover_depth_avg, ...
      SHF_cover_avg, ...
      SHF_depth_avg ] = soil_data_averager( SHF );
else
    SHF_cover_depth_avg = [];
    SHF_cover_avg = [];
    SHF_depth_avg = [];
end

switch sitecode
  case UNM_sites.SLand
    % do not calculate SHF with storage at the "grass" pits -- we don't have
    % SWC and soil T observations for SLand grass, and there isn't much grass
    % there anyway (as per conversation with Marcy 6 Aug 2012).
    [ ~, SHF_grass_idx ] = regexp_ds_vars( SHF_cover_avg, 'grass' );
    SHF_cover_avg( :, SHF_grass_idx ) = [];
  case UNM_sites.JSav
    if year > 2009
        % similarly, ignore "edge" pits at JSav
        [ ~, JSav_edge_idx ] = regexp_ds_vars( SHF_cover_avg, 'edge' );
        SHF_cover_avg( :, JSav_edge_idx ) = [];
    end
  case UNM_sites.MCon
    % here there is only one soil heat flux plate, so use the average T and
    % VWC of all soil covers for calculating storage
    VWC_cover_avg_out = VWC_cover_avg;...
    VWC_cover_avg = dataset( { nanmean( double( VWC_cover_avg ), 2 ), ...
                        'VWC_mcon_1' } );
    soil_surface_T = dataset( { nanmean( double( soil_surface_T ), 2 ), ...
                        'soilT_mcon_1' } );
end

% %----- soil data for Matt -- remove this later -----
% soil_data_for_matt = horzcat( Tsoil_runmean, cs616_runmean );
% fname = fullfile( getenv( 'FLUXROOT' ), 'FluxOut', 'SoilForMatt', ...
%                   sprintf( '%s_%d_soil.mat', char( sitecode ), year ) );
% fprintf( 'saving %s\n', fname );
% save( fname, 'soil_data_for_matt' );
% %----- soil data for Matt -- remove this later -----

if not( isempty( SHF_cover_avg ) )
    SHF = calculate_heat_flux( soil_surface_T, ...
                               VWC_cover_avg, ...
                               SHF_pars, ...
                               SHF_cover_avg, ...
                               1.0 );
else
    SHF = dataset( { repmat( NaN, size( data, 1 ), 1 ), 'SHF_MCon' } );
end

%======================================================================
% assign all the variables created above to a dataset to be returned to
% the caller
%======================================================================

switch sitecode
  case UNM_sites.MCon
    VWC_cover_avg = VWC_cover_avg_out;
end

% create output dataset with attention to any duplicated data names
out_names = genvarname( [ Tsoil_hilo_removed.Properties.VarNames, ...
                        Tsoil_depth_avg.Properties.VarNames, ...
                        cs616_Tc_hilo_removed.Properties.VarNames, ...
                        VWC_depth_avg.Properties.VarNames, ...
                        VWC_cover_avg.Properties.VarNames, ...
                        SHF.Properties.VarNames ] );
out_data = [ double( Tsoil_hilo_removed ), ...
             double( Tsoil_depth_avg ), ...
             double( cs616_Tc_hilo_removed ), ...
             double( VWC_depth_avg ), ...
             double( VWC_cover_avg ), ...
             double( SHF ) ];
ds_out = dataset( { out_data, out_names{ : } } );

% add timestamp columns
[ YEAR, ~, ~, ~, ~, ~ ] = datevec( data.timestamp );
DTIME = data.timestamp - datenum( YEAR, 1, 0, 0, 0, 0 );
DOY = floor( DTIME );
HRMIN = str2num( datestr( data.timestamp, 'HHMM' ) );
ds_out = [ dataset( YEAR, DOY, HRMIN, DTIME ), ds_out ];

% calculate execution time and write status message
t_tot = ( now() - t0 ) * 24 * 60 * 60;
fprintf( 1, ' Done (%.0f secs)\n', t_tot );




%----------------------------------------------------------------------    
%----------------------------------------------------------------------    
% helper functions start here
%----------------------------------------------------------------------    
%----------------------------------------------------------------------    

function [ ds ] = soildata_2_dataset(fluxall, columns, labels)

% SOILDATA_2_DATASET - pulls soil data from parsed Fluxall data into matlab
% dataset.  Helper function for UNM_Ameriflux_prepare_soil_met.
%   

% '.' is not a legal character for matlab variable names -- replace '.' in depth
% labels (now in format e.g. 12.5) with p (e.g. 12p5)
varnames = regexprep( labels, '([0-9])\.([0-9])', '$1p$2' );

ds = dataset( { fluxall( : ,columns ), varnames{ : } } );

%----------------------------------------------------------------------

function SHF_pars = define_SHF_pars( sitecode, year )
% DEFINE_SHF_PARS - specifies parameters for calculating soil heat flux.
% Helper function for UNM_Ameriflux_prepare_soil_met
%   
% (c) Timothy W. Hilton, UNM, April 2012

% set parameter values for soil heat flux
% scap and wcap do not vary among sites
SHF_pars.scap = 837; 
SHF_pars.wcap = 4.19e6; 
SHF_pars.depth = 0.05;

switch sitecode
    % bulk and depth vary across site-year
  case UNM_sites.GLand
    SHF_pars.bulk = 1398; 
  case UNM_sites.SLand
    SHF_pars.bulk=1327; 
  case UNM_sites.JSav
    SHF_pars.bulk=1720; 
  case UNM_sites.PJ
    SHF_pars.bulk=1437; 
  case UNM_sites.PPine
    warning( 'check PPine SHF parameters' );
    SHF_pars.bulk = 1071;
  case UNM_sites.MCon
    warning( 'check MCon SHF parameters' );
    SHF_pars.bulk = 1071;
  case UNM_sites.TX
    SHF_pars.bulk = 1114;
  case UNM_sites.TX_forest
    warning( 'check TX_forest SHF parameters -- bulk is currently NaN' );
    SHF_pars.bulk = NaN;
  case UNM_sites.TX_grass
    warning( 'check TX_grass SHF parameters -- bulk is currently NaN' );
    SHF_pars.bulk = NaN;
  case UNM_sites.PJ_girdle
    SHF_pars.bulk = NaN;
    SHF_pars.bulk=1437; 
    warning( ['check PJ_girdle SHF parameters -- bulk is currently set to PJ ' ...
              'value (1437)'] );
  case UNM_sites.New_GLand
    SHF_pars.bulk = 1398;
end %switch sitecode -- soil heat flux parameters

%----------------------------------------------------------------------
% Jsav 2008 has more Tsoil observations than SWC observations.  Remove the
% observations that don't correspond to a SWC observation.
function Tsoil = JSav_match_soilT_SWC( Tsoil )

[ ~, discard_idx ] = regexp_ds_vars( Tsoil, '62' );
Tsoil( :, discard_idx ) = [];

%--------------------------------------------------
