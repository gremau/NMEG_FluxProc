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
% Extracts variables from inut argument data whose names match one of:
%     soilT_COVER_NUMBER_DEPTH
%     SHF*, soil_heat_flux*, shf*
%     cs616SWC_COVER_NUMBER_DEPTH
%   
% USAGE
%    ds_out =  UNM_Ameriflux_prepare_soil_met( sitecode, year, data, precip );
%
% INPUTS:
%    sitecode: UNM_sites object; specifies the site
%    year: four-digit year: specifies the year
%    data: dataset array; parsed fluxall data.  Generally will be the output
%        of UNM_parse_fluxall_txt_file or UNM_parse_fluxall_xls_file
%    ds_qc: dataset array; parsed qc file data. Generally will be the output
%        of UNM_parse_QC_txt_file
%
% OUTPUTS
%    ds_out: dataset array: soil variables extracted from data
%
% SEE ALSO
%    dataset, UNM_parse_fluxall_txt_file, UNM_parse_fluxall_xls_file
%
% author: Timothy W. Hilton, UNM, January 2012

warning('deprecated - this is being replaced by "soil_met_correct.m"');

[ last_obs_row_data, ~, ~ ] = find( not( isnan( double( data( :, 2:end ) ) ) ) );
[ last_obs_row_qc, ~, ~ ] = find( not( isnan( double( ds_qc( :, 2:end ) ) ) ) );
last_obs_row = max( [ reshape( last_obs_row_data, 1, [] ), ...
                    reshape( last_obs_row_qc, 1, [] ) ] );

sitecode = UNM_sites( sitecode );
SWC_smoothed = false; % will set to true after SWC data have been smoothed

t0 = now();
fprintf( 1, 'Begin soil met properties...\n' );

% some site-years have non-descriptive labels for soil data columns.  Replace
% these with descriptive labels.
data = UNM_assign_soil_data_labels( sitecode, year, data );

% create a column of -9999s to place in the dataset where a site does not
% record a particular variable
dummy = repmat( -9999, size( data, 1 ), 1 );

% find any soil heat flux columns within QC data
shf_vars = regexp_header_vars( data, '(SHF|soil_heat_flux|shf).*' );
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

    re_Tsoil = '[Ss]oilT_[A-Za-z]+_[0-9]+_[0-9]+.*'; %regexp to identify
                                                  %"soilT_COVER_NUMBER_DEPTH"
    Tsoil = data( :, regexp_header_vars( data, re_Tsoil ) );
    if isempty( Tsoil )
        re_Tsoil_form2 = 'Tsoil_avg'; 
        Tsoil = data( :, regexp_header_vars( data, re_Tsoil_form2 ) );
    end

    if ( sitecode == UNM_sites.JSav ) & ( year == 2008 )
        % Jsav 2008 has more Tsoil observations than SWC observations.
        % Remove the observations that don't correspond to a SWC observation.
        Tsoil = JSav_match_soilT_SWC( Tsoil );
    end
    fprintf( 'Tsoil probes detected: %d\n', size( Tsoil, 2 ) );        
    
    cs616_pd = data( :, regexp_header_vars( data, ...
                                        'cs616SWC_[A-Za-z]+_[0-9]+_[0-9]+.*' ) );   

    t0 = now();
    cs616_pd_smoothed = UNM_soil_data_smoother( cs616_pd, 6, false );
    SWC_smoothed = true;
    fprintf( 'smooth cs616: %0.2f mins\n', ( now() - t0 ) * 24 * 60 );
    
    if ( sitecode == UNM_sites.GLand ) & ( year == 2011 )
        % GLand SWC probes were reinstalled on 22 Mar 2011, introducing an
        % artificial discontinuity in most of the probes.  Correct that by
        % raising signal after 22 Mar to its pre-22 Mar level.
        draw_plots = false;  % set to true to see the corrections
        cs616_pd_smoothed = GLand_2011_correct_22Mar( cs616_pd_smoothed, ...
                                                      draw_plots );
    end

    
    if ( sitecode == UNM_sites.JSav ) & ( year == 2009 )
        cs616_pd = data( :, regexp_header_vars( data, ...
                                            'cs616SWC_[A-Za-z]+_[0-9]+_[0-9]+.*' ) );   
        
        t0 = now();
        cs616_pd_smoothed = UNM_soil_data_smoother( cs616_pd, 6, false );
        SWC_smoothed = true;
        fprintf( 'smooth cs616: %0.2f mins\n', ( now() - t0 ) * 24 * 60 );
    end
        
    if ( sitecode == UNM_sites.JSav ) & ( year == 2012 )
        draw_plots = false;  % set to true to see the corrections
        cs616_pd_smoothed = ...
            JSav_2012_datalogger_transition( cs616_pd, ...
                                             6, ...
                                             draw_plots );
    end

    % if necessary, convert CS616 periods to volumetric water content
    [ cs616_smoothed, ...
      cs616_Tc_smoothed ] = cs616_period2vwc( cs616_pd_smoothed, ...
                                              Tsoil, ...
                                              'draw_plots', false, ...
                                              'save_plots', false, ...
                                              'sitecode', sitecode, ...
                                              'year', year );
    
    % t0 = now();
    % cs616_Tc_smoothed = UNM_soil_data_smoother( cs616_Tc, 6, false );
    % fprintf( 'smooth T-corrected SWC: %0.2f mins\n', ( now() - t0 ) * 24 * 60 );
    
    if ( year == 2011 ) & sitecode == ( UNM_sites.SLand )
        cs616_Tc_smoothed = fix_2011_SLand_SWC( cs616_Tc_smoothed );
    end
    
    TCAV = data( :, regexp_header_vars( data, ...
                                     'TCAV_[A-Za-z]+.*' ) );
  case { UNM_sites.PPine }
    cs616 = preprocess_PPine_soil_data( year );
    two_mins = 2;
    [ ~, cs616 ] = merge_datasets_by_datenum( data, cs616, ...
                                              'timestamp', 'timestamp', ...
                                              two_mins, ...
                                              min( data.timestamp ), ...
                                              max( data.timestamp ) );
    % cs616 = cs616( find_unique( cs616.timestamp ), : );
    cs616.timestamp = [];
    cs616_Tc = cs616;  % PPine SWC data are already in VWC form

    
    re_Tsoil = 'soilT.*';
    Tsoil = data( :, regexp_header_vars( data, re_Tsoil ) );
    
    TCAV = data( :, regexp_header_vars( data, ...
                                    'TCAV_[A-Za-z]+.*' ) );
    
  case { UNM_sites.MCon }
    cs616 = preprocess_MCon_soil_data( year, data.timestamp );
    cs616.timestamp = [];
    cs616_Tc = cs616;  % MCon SWC data are already in VWC form

    re_Tsoil = 'soilT.*';
    Tsoil = data( :, regexp_header_vars( data, re_Tsoil ) );
    
    TCAV = data( :, regexp_header_vars( data, ...
                                    'TCAV_[A-Za-z]+.*' ) );
        
  case { UNM_sites.PJ, UNM_sites.PJ_girdle, UNM_sites.TestSite }
    % PJ and PJ_girdle store their soil data outside of FluxAll.
    % These data are already converted to VWC.
    
    [ Tsoil, cs616, SHF ] = preprocess_PJ_soil_data( sitecode, year );
%         preprocess_PJ_soil_data( sitecode, ...
%                                  year, ...
%                                  't_min', min( data.timestamp ), ...
%                                  't_max', max( data.timestamp ) );
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
Tsoil_smoothed = UNM_soil_data_smoother( Tsoil, 12, false );
if not( SWC_smoothed )
    fprintf( 'smoothing soil water\n' );
    cs616_Tc_smoothed = UNM_soil_data_smoother( cs616_Tc, 12, false );
end
draw_plots = false;
Tsoil_smoothed = fill_soil_temperature_gaps( Tsoil_smoothed, ...
                                             ds_qc.precip, ...
                                             draw_plots );
cs616_Tc_smoothed = fill_soil_water_gaps( cs616_Tc_smoothed, ...
                                          ds_qc.precip, ...
                                          draw_plots );

% remove data from specific periods at specific probes that are obviously bogus
[ Tsoil_smoothed, cs616_Tc_smoothed ] = ...
    remove_problematic_soil_probe_data( sitecode, ...
                                        year, ...
                                        Tsoil_smoothed, ...
                                        cs616_Tc_smoothed );

% calculate averages by cover type, depth
[ Tsoil_cover_depth_avg, ...
  Tsoil_cover_avg, ...
  Tsoil_depth_avg ] = soil_data_averager( Tsoil_smoothed, ...
                                          'draw_plots', false, ...
                                          'fill_type', 'interp' );
[ VWC_cover_depth_avg, ...
  VWC_cover_avg, ...
  VWC_depth_avg ] = soil_data_averager( cs616_Tc_smoothed, ...
                                        'draw_plots', false, ...
                                        'fill_type', 'interp' );

if ( sitecode == UNM_sites.GLand ) & ( year == 2011 )
    [ VWC_depth_avg, VWC_cover_depth_avg ] = ...
        fill_JunJul_2011_GLand_SWC_gap( VWC_depth_avg, VWC_cover_depth_avg );
end

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

fprintf( 'second smoothing pass\n' );
Tsoil_smoothed = UNM_soil_data_smoother( Tsoil_smoothed, 12, false );
cs616_Tc_smoothed = UNM_soil_data_smoother( cs616_Tc_smoothed, 12, false );

% -----
% -----
% now we have T-corrected VWC and soil T. Calculate heat flux with storage.
% -----
% -----

SHF_pars = define_SHF_pars( sitecode, year );
if not( ismember( sitecode, [ UNM_sites.PJ, UNM_sites.PJ_girdle, UNM_sites.TestSite ] ) )
    SHF = data( :, shf_vars );
    shf_vars = cellfun( @(x) [ x, '_0' ], shf_vars, 'UniformOutput', false );
    SHF.Properties.VarNames = shf_vars; 
end
if not( isempty( SHF ) )
    [ SHF_cover_depth_avg, ...
      SHF_cover_avg, ...
      SHF_depth_avg ] = soil_data_averager( SHF, ...
                                            'draw_plots', false, ...
                                            'fill_type', 'interp' );
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
    [ ~, SHF_grass_idx ] = regexp_header_vars( SHF_cover_avg, 'grass' );
    SHF_cover_avg( :, SHF_grass_idx ) = [];
  case UNM_sites.JSav
    if year >= 2009
        % similarly, ignore "edge" pits at JSav
        [ ~, JSav_edge_idx ] = regexp_header_vars( SHF_cover_avg, 'edge' );
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
    SHF = dataset( { repmat( NaN, size( data, 1 ), 1 ), ...
                     sprintf( 'SHF_%s', char( sitecode ) ) } );
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
out_names = genvarname( [ Tsoil_smoothed.Properties.VarNames, ...
                    Tsoil_depth_avg.Properties.VarNames, ...
                    Tsoil_cover_depth_avg.Properties.VarNames, ...
                    cs616_Tc_smoothed.Properties.VarNames, ...
                    VWC_depth_avg.Properties.VarNames, ...
                    VWC_cover_depth_avg.Properties.VarNames, ...
                    SHF.Properties.VarNames ] );
out_data = [ double( Tsoil_smoothed ), ...
             double( Tsoil_depth_avg ), ...
             double( Tsoil_cover_depth_avg ), ...
             double( cs616_Tc_smoothed ), ...
             double( VWC_depth_avg ), ...
             double( VWC_cover_depth_avg ), ...
             double( SHF ) ];
% out_names = genvarname( [ cs616_Tc_smoothed.Properties.VarNames, ...
%                     VWC_depth_avg.Properties.VarNames, ...
%                     VWC_cover_depth_avg.Properties.VarNames, ...
%                     SHF.Properties.VarNames ] );
% out_data = [ double( cs616_Tc_smoothed ), ...
%              double( VWC_depth_avg ), ...
%              double( VWC_cover_depth_avg ), ...
%              double( SHF ) ];

% the soil data smoothing/averaging routine is setup to fill constant values
% past the last valid observation in cases where there is a gap at the end of
% the record, and there is no precipitation during that gap.  However, we
% don't want to fill past the end of the most recent data collected from the
% field (or, worse, into the future!).  So, make sure the soil data contain
% only NaNs after the end of the most recent set of observations.
out_data( (last_obs_row + 1) : end, : ) = NaN;

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
% author: Timothy W. Hilton, UNM, April 2012

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
  case UNM_sites.PJ | UNM_sites.TestSite
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

[ ~, discard_idx ] = regexp_header_vars( Tsoil, '62' );
Tsoil( :, discard_idx ) = [];

%--------------------------------------------------

function swc_smooth = JSav_2012_datalogger_transition( swc_raw, win, draw_plots )
% JSAV_2012_DATALOGGER_TRANSITION - The JSav soil water content probes were
%   moved to a CR1000 datalogger on 1 May 2012.  After the switch the datalogger
%   recorded volumetric water content, not cs616 period in microseconds as
%   before the switch.  Smoothing the data across that transition messes things
%   up, so smooth the two halves of the record separately here

may1 = datenum( 2012, 5, 1 ) - datenum( 2012, 1, 0 ); 
may1 = DOYidx( may1 );

swc_smooth1 = UNM_soil_data_smoother( swc_raw( 1:may1-1, : ), win, draw_plots ); 
swc_smooth2 = UNM_soil_data_smoother( swc_raw( may1:end, : ), win, draw_plots ); 

swc_smooth = vertcat( swc_smooth1, swc_smooth2 );



%--------------------------------------------------

function VWC = GLand_2011_correct_22Mar( VWC, draw_plots )
% GLAND_2011_CORRECT_22MAR - GLand SWC probes were reinstalled on 22 Mar 2011,
% introducing an artificial discontinuity in most of the probes.  Correct that
% by raising signal after 22 Mar to its pre-22 Mar level.
%   

if draw_plots
    figure();
    plot( VWC, '.-' );
    xlim( [ 3800, 4000 ] );
    ylim( [ 0, 0.1 ] );
    ylabel( 'VWC (m^3 m^{-3})');
    xlabel( '30-minute array index' );
    title( 'before' );
end

% index for 14 Jun 00:00
jun_14 = DOYidx( datenum( 2011, 6, 14 ) - datenum( 2011, 1, 0 ) );

delta_22mar = ( nanmean( double( VWC( 3812:3912, : ) ) ) - ...
                nanmean( double( VWC( 3920:4020, : ) ) ) );

% shift the post-22 Mar data to make them continuous with the pre-22 Mar data
temp = double( VWC( 3920 : jun_14, : ) );
temp = temp + repmat( delta_22mar, size( temp, 1 ), 1 );
VWC( 3920 : jun_14, : )  = ...
    replacedata( VWC( 3920 : jun_14, : ), temp );

% remove and fill by interpolation two periods of two and four hours,
% respectively, where all the probes were going haywire
temp = double( VWC( 1 : 4000, : ) );
temp( 3912:3920, : ) = NaN;
temp( 3815:3820, : ) = NaN;
temp = column_inpaint_nans( temp, 4 );
VWC( 1:4000, : )  = ...
    replacedata( VWC( 1:4000, : ), temp );

if draw_plots
    figure();
    plot( VWC, '.-' );
    xlim( [ 3800, 4000 ] );
    ylim( [ 0, 0.1 ] );
    ylabel( 'VWC (m^3 m^{-3})');
    xlabel( '30-minute array index' );
    title( 'after' );
end

%--------------------------------------------------

function [ VWC_depth_avg, VWC_cover_depth_avg ] = ...
    fill_JunJul_2011_GLand_SWC_gap( VWC_depth_avg, VWC_cover_depth_avg )
% FILL_JUNJUL_2011G_LAND_SWC_GAP - there was a datalogger malfunction at GLand
% from 13 June to 27 July 2011 that resulted in the loss of all data.  Here
% we fill the cover--depth average volumetric water content using the same
% averages from New_GLand.

varnames = { 'VWC_grass_2p5cm_Avg', 'VWC_grass_12p5cm_Avg', ...
             'VWC_grass_22p5cm_Avg', 'VWC_grass_37p5cm_Avg', ...
             'VWC_grass_52p5cm_Avg', ...
             'VWC_open_2p5cm_Avg', 'VWC_open_12p5cm_Avg', ... 
             'VWC_open_22p5cm_Avg', 'VWC_open_37p5cm_Avg' };

VWC = VWC_cover_depth_avg;

temp = double( VWC( 7401:10201, varnames ) );
temp(:) = NaN;
VWC( 7401:10201, varnames ) = replacedata( VWC( 7401:10201, varnames ), temp );

%-----
% grass pit adjustments

% grass 2.5cm
VWC.VWC_grass_2p5cm_Avg( 8670 ) = VWC.VWC_grass_2p5cm_Avg( 7400 );
VWC.VWC_grass_2p5cm_Avg( 8676 ) = VWC.VWC_grass_2p5cm_Avg( 8670 ) + 0.025;
VWC.VWC_grass_2p5cm_Avg( 8880 ) = VWC.VWC_grass_2p5cm_Avg( 8670 ) + 0.024;
VWC.VWC_grass_2p5cm_Avg( 9198 ) = VWC.VWC_grass_2p5cm_Avg( 8670 ) + 0.007;
VWC.VWC_grass_2p5cm_Avg( 9300 ) = VWC.VWC_grass_2p5cm_Avg( 8670 ) + 0.014;
VWC.VWC_grass_2p5cm_Avg( 10000 ) = VWC.VWC_grass_2p5cm_Avg( 8670 ) + 0.0075;

% grass 12.5 cm
VWC.VWC_grass_12p5cm_Avg( 8670 ) = VWC.VWC_grass_12p5cm_Avg( 7400 ) - 0.003;
VWC.VWC_grass_12p5cm_Avg( 8920 ) = VWC.VWC_grass_12p5cm_Avg( 8670 ) + 0.004;
VWC.VWC_grass_12p5cm_Avg( 10190 ) = VWC.VWC_grass_12p5cm_Avg( 8670 ) - 0.002;

% grass 22.5 cm
VWC.VWC_grass_22p5cm_Avg( 8700 ) = VWC.VWC_grass_22p5cm_Avg( 7395 ) - 0.01;
VWC.VWC_grass_22p5cm_Avg( 9500 ) = VWC.VWC_grass_22p5cm_Avg( 8700 ) + 0.001;
VWC.VWC_grass_22p5cm_Avg( 10200 ) = VWC.VWC_grass_22p5cm_Avg( 7395 ) - 0.015;

% grass 37.5 cm
VWC.VWC_grass_37p5cm_Avg( 8670 ) = VWC.VWC_grass_37p5cm_Avg( 7395 ) - 0.008;
VWC.VWC_grass_37p5cm_Avg( 9100 ) = VWC.VWC_grass_37p5cm_Avg( 8670 ) + 0.001;
VWC.VWC_grass_37p5cm_Avg( 10200 ) = VWC.VWC_grass_37p5cm_Avg( 10300 );

% grass 52.5 cm


%-----
% open pits

% open 2.5 cm
VWC.VWC_open_2p5cm_Avg( 8670 ) = VWC.VWC_open_2p5cm_Avg( 7400 );
VWC.VWC_open_2p5cm_Avg( 8775 ) = VWC.VWC_open_2p5cm_Avg( 8670 ) + 0.0175;
VWC.VWC_open_2p5cm_Avg( 8925 ) = VWC.VWC_open_2p5cm_Avg( 8670 ) + 0.0175;
VWC.VWC_open_2p5cm_Avg( 9200 ) = VWC.VWC_open_2p5cm_Avg( 8670 ) + 0.003;
VWC.VWC_open_2p5cm_Avg( 9300 ) = VWC.VWC_open_2p5cm_Avg( 8670 ) + 0.015;
VWC.VWC_open_2p5cm_Avg( 10000 ) = VWC.VWC_open_2p5cm_Avg( 8670 ) + 0.004;

% open 12.5 cm
VWC.VWC_open_12p5cm_Avg( 8670 ) = VWC.VWC_open_12p5cm_Avg( 7400 ) - 0.002;
VWC.VWC_open_12p5cm_Avg( 9100 ) = VWC.VWC_open_12p5cm_Avg( 8670 ) + 0.009;
VWC.VWC_open_12p5cm_Avg( 10200 ) = VWC.VWC_open_12p5cm_Avg( 8670 );

% open 22.5 cm
VWC.VWC_open_22p5cm_Avg( 8670 ) = VWC.VWC_open_22p5cm_Avg( 7400 ) - 0.008;
VWC.VWC_open_22p5cm_Avg( 9100 ) = VWC.VWC_open_22p5cm_Avg( 7400 );
VWC.VWC_open_22p5cm_Avg( 9600 ) = VWC.VWC_open_22p5cm_Avg( 9100 );
VWC.VWC_open_22p5cm_Avg( 10200 ) = VWC.VWC_open_22p5cm_Avg( 9600 ) - 0.008;

% open 37.5 cm
% linear interpolation of entire gap should be ok here

% open 52.5 cm
New_GLand11 = parse_ameriflux_file( ...
    get_ameriflux_filename( UNM_sites.New_GLand, 2011, 'soil' ) );
offset = New_GLand11.VWC_open_520x2E5_Avg( 10000 ) - ...
         VWC.VWC_open_52p5cm_Avg( 10000 );

VWC.VWC_open_52p5cm_Avg( 1:10000 ) = ...
    New_GLand11.VWC_open_520x2E5_Avg( 1:10000 ) - offset;

% fill the gap by linear interpolation between the inflection points
% specified above
temp = VWC( 7400:10202, varnames );
temp = double( temp );
temp = column_inpaint_nans( temp, 4 );

% replace the gap in the input dataset with the interpolated data
VWC( 7400:10202, varnames ) = ...
    replacedata( VWC( 7400:10202, varnames ),  temp );

VWC_cover_depth_avg = VWC;

% recalculate the site-wide-by-depth averages with the filled data
VWC_depth_avg( :, 'VWC_2p5cm_Avg' ) = replacedata( ...
    VWC_depth_avg( :, 'VWC_2p5cm_Avg' ), ...
    mean( [ double( VWC_cover_depth_avg( :, 'VWC_grass_2p5cm_Avg' ) ), ...
            double( VWC_cover_depth_avg( :, 'VWC_open_2p5cm_Avg' ) ) ], 2 ) );
VWC_depth_avg( :, 'VWC_12p5cm_Avg' ) = replacedata( ...
    VWC_depth_avg( :, 'VWC_12p5cm_Avg' ), ...
    mean( [ double( VWC_cover_depth_avg( :, 'VWC_grass_12p5cm_Avg' ) ), ...
            double( VWC_cover_depth_avg( :, 'VWC_open_12p5cm_Avg' ) ) ], 2 ) );
VWC_depth_avg( :, 'VWC_37p5cm_Avg' ) = replacedata( ...
    VWC_depth_avg( :, 'VWC_37p5cm_Avg' ), ...
    mean( [ double( VWC_cover_depth_avg( :, 'VWC_grass_37p5cm_Avg' ) ),...
            double( VWC_cover_depth_avg( :, 'VWC_open_37p5cm_Avg' ) ) ], 2 ) );
VWC_depth_avg( :, 'VWC_52p5cm_Avg' ) = replacedata( ...
    VWC_depth_avg( :, 'VWC_52p5cm_Avg' ), ...
    mean( [ double( VWC_cover_depth_avg( :, 'VWC_grass_52p5cm_Avg' ) ), ...
            double( VWC_cover_depth_avg( :, 'VWC_open_52p5cm_Avg' ) ) ], 2 ) );


%--------------------------------------------------

function VWC = fix_2011_SLand_SWC( VWC )
% FIX_2011_SLAND_SWC - there is an obviously-incorrect step change in many of
%   the SLand 2011 soil water probes around 22 May, perhaps from a lightnig
%   strike or other electrical anomaly.  Using GLand and New_GLand as guides,
%   here we implement best-approximation fixes to the SWC records for SLand
%   2011.

figure(); h0 = plot( VWC.cs616SWC_open_1_2p5, '.k' );
VWC.cs616SWC_open_1_2p5( 6800:7200 ) = NaN;
idx = 7200:9500;
VWC.cs616SWC_open_1_2p5( idx ) = VWC.cs616SWC_open_1_2p5( idx ) - 0.0125;
hold on; h1 = plot( VWC.cs616SWC_open_1_2p5, '-ob' ); 
title( 'open\_1\_2.5' ); legend( [ h0, h1 ], 'before', 'after' );

figure(); h0 = plot( VWC.cs616SWC_open_1_12p5, '.k' );
VWC.cs616SWC_open_1_12p5( 6800:7200 ) = NaN;
idx = 7200:10063;
VWC.cs616SWC_open_1_12p5( idx ) = VWC.cs616SWC_open_1_12p5( idx ) - 0.01;
hold on; h1 = plot( VWC.cs616SWC_open_1_12p5, '-ob' ); 
title( 'open\_1\_12.5' ); legend( [ h0, h1 ], 'before', 'after' );

figure(); h0 = plot( VWC.cs616SWC_open_1_22p5, '.k' );
idx = 6800:13276;
VWC.cs616SWC_open_1_22p5( idx ) = VWC.cs616SWC_open_1_22p5( idx ) + 0.01;
hold on; h1 = plot( VWC.cs616SWC_open_1_22p5, '-ob' ); 
title( 'open\_1\_22.5' ); legend( [ h0, h1 ], 'before', 'after' );

figure(); h0 = plot( VWC.cs616SWC_open_1_37p5, '.k' );
VWC.cs616SWC_open_1_37p5( 6800:end ) = ...
    VWC.cs616SWC_open_1_37p5( 6800:end ) + 0.065;
VWC.cs616SWC_open_1_37p5( 6750:6910 ) = NaN;
hold on; h1 = plot( VWC.cs616SWC_open_1_37p5, '-ob' ); 
title( 'open\_1\_37.5' );legend( [ h0, h1 ], 'before', 'after' );

figure(); h0 = plot( VWC.cs616SWC_open_1_52p5, '.k' );
idx = 6891:size( VWC, 1 );
VWC.cs616SWC_open_1_52p5( idx ) = VWC.cs616SWC_open_1_52p5( idx ) + 0.032;
hold on; h1 = plot( VWC.cs616SWC_open_1_52p5, '-ob' ); 
title( 'open\_1\_52.5' ); legend( [ h0, h1 ], 'before', 'after' );

figure(); h0 = plot( VWC.cs616SWC_cover_1_2p5, '.k' );
VWC.cs616SWC_cover_1_2p5( 6800:7200 ) = NaN;
idx = 6890:9140;
VWC.cs616SWC_cover_1_2p5( idx ) = VWC.cs616SWC_cover_1_2p5( idx ) + 0.0137;
hold on; h1 = plot( VWC.cs616SWC_cover_1_2p5, '-ob' ); 
title( 'cover\_1\_2.5' ); legend( [ h0, h1 ], 'before', 'after' );

figure(); h0 = plot( VWC.cs616SWC_cover_1_12p5, '.k' );
VWC.cs616SWC_cover_1_12p5( 6800:7200 ) = NaN;
idx = 6890:10034;
VWC.cs616SWC_cover_1_12p5( idx ) = VWC.cs616SWC_cover_1_12p5( idx ) + 0.0388;
hold on; h1 = plot( VWC.cs616SWC_cover_1_12p5, '-ob' ); 
title( 'cover\_1\_12.5' ); legend( [ h0, h1 ], 'before', 'after' );

figure(); h0 = plot( VWC.cs616SWC_cover_1_22p5, '.k' );
VWC.cs616SWC_cover_1_22p5( 6800:7200 ) = NaN;
idx = 6890:16903;
VWC.cs616SWC_cover_1_22p5( idx ) = VWC.cs616SWC_cover_1_22p5( idx ) + 0.0388;
hold on; h1 = plot( VWC.cs616SWC_cover_1_22p5, '-ob' ); 
title( 'cover\_1\_22.5' ); legend( [ h0, h1 ], 'before', 'after' );

figure(); h0 = plot( VWC.cs616SWC_cover_1_37p5, '.k' );
VWC.cs616SWC_cover_1_37p5( 6800:end ) = ...
    VWC.cs616SWC_cover_1_37p5( 6800:end ) + 0.045;
VWC.cs616SWC_cover_1_37p5( 6750:6910 ) = NaN;
hold on; h1 = plot( VWC.cs616SWC_cover_1_37p5, '-ob' ); 
title( 'cover\_1\_37.5' );legend( [ h0, h1 ], 'before', 'after' );

figure(); h0 = plot( VWC.cs616SWC_cover_1_52p5, '.k' );
VWC.cs616SWC_cover_1_52p5( 6800:end ) = ...
    VWC.cs616SWC_cover_1_52p5( 6800:end ) + 0.0225;
VWC.cs616SWC_cover_1_52p5( 6750:6910 ) = NaN;
hold on; h1 = plot( VWC.cs616SWC_cover_1_52p5, '-ob' ); 
title( 'cover\_1\_52.5' );legend( [ h0, h1 ], 'before', 'after' );

figure(); h0 = plot( VWC.cs616SWC_open_2_2p5, '.k' );
idx = 7156:7848;
VWC.cs616SWC_open_2_2p5( idx ) = VWC.cs616SWC_open_2_2p5( idx ) - 0.02;
hold on; h1 = plot( VWC.cs616SWC_open_2_2p5, '-ob' ); 
title( 'open\_1\_2.5' ); legend( [ h0, h1 ], 'before', 'after' );

figure(); h0 = plot( VWC.cs616SWC_open_2_12p5, '.k' );
idx = 7172:7995;
VWC.cs616SWC_open_2_12p5( idx ) = VWC.cs616SWC_open_2_12p5( idx ) + 0.02057;
hold on; h1 = plot( VWC.cs616SWC_open_2_12p5, '-ob' ); 
title( 'open\_1\_12.5' ); legend( [ h0, h1 ], 'before', 'after' );

figure(); h0 = plot( VWC.cs616SWC_open_2_22p5, '.k' );
VWC.cs616SWC_open_2_22p5( 6900:end ) = ...
    VWC.cs616SWC_open_2_22p5( 6900:end ) + 0.019027;
hold on; h1 = plot( VWC.cs616SWC_open_2_22p5, '-ob' ); 
title( 'cover\_1\_22.5' ); legend( [ h0, h1 ], 'before', 'after' );

figure(); h0 = plot( VWC.cs616SWC_open_2_37p5, '.k' );
VWC.cs616SWC_open_2_37p5( 6901:end ) = ...
    VWC.cs616SWC_open_2_37p5( 6901:end ) + 0.035248;
hold on; h1 = plot( VWC.cs616SWC_open_2_37p5, '-ob' ); 
title( 'cover\_1\_37.5' ); legend( [ h0, h1 ], 'before', 'after' );

figure(); h0 = plot( VWC.cs616SWC_open_2_52p5, '.k' );
VWC.cs616SWC_open_2_52p5( 6683:8600 ) = NaN;
VWC.cs616SWC_open_2_52p5( 8601:end ) = ...
    VWC.cs616SWC_open_2_52p5( 8601:end ) + 0.026436;
hold on; h1 = plot( VWC.cs616SWC_open_2_52p5, '-ob' ); 
title( 'cover\_1\_52.5' ); legend( [ h0, h1 ], 'before', 'after' );


figure(); h0 = plot( VWC.cs616SWC_cover_2_2p5, '.k' );
idx = 6982:9200;
VWC.cs616SWC_cover_2_2p5( idx ) = VWC.cs616SWC_cover_2_2p5( idx ) - 0.083827;
hold on; h1 = plot( VWC.cs616SWC_cover_2_2p5, '-ob' ); 
title( 'open\_1\_2.5' ); legend( [ h0, h1 ], 'before', 'after' );

% cover_2_12.5 actually looks ok

figure(); h0 = plot( VWC.cs616SWC_cover_2_22p5, '.k' );
VWC.cs616SWC_cover_2_22p5( 6741:end ) = ...
    VWC.cs616SWC_cover_2_22p5( 6741:end ) + 0.028255;
hold on; h1 = plot( VWC.cs616SWC_cover_2_22p5, '-ob' ); 
title( 'cover\_1\_22.5' ); legend( [ h0, h1 ], 'before', 'after' );

figure(); h0 = plot( VWC.cs616SWC_cover_2_37p5, '.k' );
VWC.cs616SWC_cover_2_37p5( 6901:end ) = ...
    VWC.cs616SWC_cover_2_37p5( 6901:end ) + 0.054706;
hold on; h1 = plot( VWC.cs616SWC_cover_2_37p5, '-ob' ); 
title( 'cover\_1\_37.5' ); legend( [ h0, h1 ], 'before', 'after' );


figure(); h0 = plot( VWC.cs616SWC_cover_2_52p5, '.k' );
VWC.cs616SWC_cover_2_52p5( 6683:8600 ) = NaN;
VWC.cs616SWC_cover_2_52p5( 8601:end ) = ...
    VWC.cs616SWC_cover_2_52p5( 8601:end ) + 0.027;
hold on; h1 = plot( VWC.cs616SWC_cover_2_52p5, '-ob' ); 
title( 'cover\_1\_52.5' ); legend( [ h0, h1 ], 'before', 'after' );

