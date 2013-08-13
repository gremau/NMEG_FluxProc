function [ amflux_gaps, amflux_gf ] = ...
    UNM_Ameriflux_prepare_output_data( sitecode, ...
                                       year, ...
                                       ds_qc, ...
                                       ds_pt, ...
                                       ds_soil )
% UNM_AMERIFLUX_PREPARE_FLUXES - prepare observed data for writing to Ameriflux
%   files.
%
% UNM_Ameriflux_prepare_output_data creates QC flags and gives various
% observations the names they should have for Ameriflux.  This is a helper
% function called from UNM_Ameriflux_File_Maker.
%
% Usually ds_qc will be the output of UNM_parse_QC_txt_file, and ds_pt will
% be the output of UNM_parse_gapfilled_partitioned_output.
%
% This code is largely taken from UNM_Ameriflux_file_maker_011211.m
%
% USAGE
%    [ amflux_gaps, amflux_gf ] = ...
%        UNM_Ameriflux_prepare_output_data( sitecode, ...
%                                           year, ...
%                                           ds_qc, ...
%                                           ds_pt, ...
%                                           ds_soil )
% INPUTS
%    sitecode: UNM_sites object; specifies the site
%    year: four-digit year: specifies the year
%    ds_qc: dataset array; data from fluxall_QC file
%    ds_pt: dataset array; output from MPI gapfiller/flux partitioner output
%    ds_soil: dataset array; soil data.  Unused for now -- specify as NaN.
%
% OUTPUTS
%    amflux_gaps: dataset array; with-gaps Ameriflux data
%    amflux_gf: dataset array; gap-filled Ameriflux data
%
% SEE ALSO
%    UNM_sites, dataset, UNM_Ameriflux_File_Maker,
%    UNM_parse_gapfilled_partitioned_output, UNM_parse_QC_txt_file
%
% author: Timothy W. Hilton, UNM, January 2012

soil_moisture = false; % turn off soil moisture processing for now

% create a column of -9999s to place in the dataset where a site does not record
% a particular variable
dummy = repmat( -9999, size( ds_qc, 1 ), 1 );

% A little cleaning - very basic high/low filtering
% anon function to find values in x outside of [L H]
HL = @( x, L, H )  (x < L) | (x > H);

% initialize flags to 1
f_flag = int8( repmat( 1, size( ds_qc, 1 ), 1 ) );
NEE_flag = f_flag;
LE_flag = f_flag;
H_flag = f_flag;
TA_flag = f_flag;
Rg_flag=f_flag;
VPD_flag = f_flag;
rH_flag = f_flag;

if ismember( 'VPD_f', ds_pt.Properties.VarNames )
    VPD_f = ds_pt.VPD_f ./ 10; % convert to kPa
                               % what is "_g"?  "good" values?  --TWH
else
    VPD_f = dummy;
end
VPD_g = dummy;
VPD_g( ~isnan( ds_qc.rH ) ) = VPD_f( ~isnan( ds_qc.rH ) );
Tair_f = ds_pt.Tair_f;
Rg_f = ds_pt.Rg_f;
%Rg_f( ds_pt.Rg_fqcOK == 0 ) = NaN;
Rg_f( HL( Rg_f, -50, Inf ) ) = NaN;

% set met flags to zero where observations exist
TA_flag( ~isnan( ds_qc.air_temp_hmp ) ) = int8( 0 );
Rg_flag( ~isnan( ds_qc.sw_incoming ) ) = int8( 0 );
VPD_flag( ~isnan( ds_qc.rH ) ) = int8( 0 );
rH_flag( ~isnan( ds_qc.rH ) ) = int8( 0 );

% make vector containing only observed temperature 
Tair_obs = Tair_f;
Tair_obs( TA_flag == 1 ) = NaN;

% the following taken care of in RemoveBadData now
% % Take out some extra uptake values at Grassland premonsoon.
% if sitecode ==1
%     to_remove = find( ds_qc.fc_raw_massman_wpl( 1:7000 ) < -1.5 );
%     ds_qc.fc_raw_massman_wpl( to_remove ) = NaN;
%     to_remove = find( ds_qc.fc_raw_massman_wpl( 1:5000 ) < -0.75 );
%     ds_qc.fc_raw_massman_wpl( to_remove ) = NaN;
% end
% % Take out some extra uptake values at Ponderosa respiration.
% if sitecode == 5
%     to_remove= find( ds_qc.fc_raw_massman_wpl > 8 );
%     ds_qc.fc_raw_massman_wpl( to_remove ) = NaN;
% end

% initialize observed fluxes to NaNs
NEE_obs = dummy;
LE_obs = dummy;
H_obs = dummy;

% fill in valid flux obs. and set corresponding flags to zero for...
% NEE,
idx = ~isnan( ds_qc.fc_raw_massman_wpl );
NEE_obs( idx ) =   ds_qc.fc_raw_massman_wpl( idx );
NEE_flag( idx ) = 0;
% set NEE_flag to 1 where local gapfilling was performed
%idx_filled = repmat( 1, size( dummy ) ); 
idx_filled = UNM_gapfill_from_local_data( sitecode, year, dataset( [] ) );
NEE_flag( idx_filled ) = 1;
% LE,
idx = ~isnan( ds_qc.HL_wpl_massman );
LE_obs( idx ) = ds_qc.HL_wpl_massman( idx );
LE_flag( ~isnan(ds_qc.HL_wpl_massman) ) = 0;
% and H
idx = ~isnan( ds_qc.HSdry_massman );
H_obs( idx ) = ds_qc.HSdry_massman( idx );
H_flag( idx ) = 0;

% if sitecode == 5
%     NEE_f = ds_pt.NEE_HBLR;  % Lasslop filled NEE
% else
% NEE_f = ds_pt.NEE_f;  % Reichstein filled NEE
% end
NEE_f = ds_pt.NEE_f;  % Reichstein filled NEE
RE_f  = ds_pt.Reco_HBLR;
GPP_f = ds_pt.GPP_HBLR;
LE_f = ds_pt.LE_f;
H_f = ds_pt.H_f;

% Make sure NEE contain observations where available
NEE_2 = NEE_f;
idx = ~isnan( ds_qc.fc_raw_massman_wpl );
NEE_2( idx ) = NEE_obs( idx );

% To ensure carbon balance, calculate GPP as remainder when NEE is
% subtracted from RE. This will give negative GPP when NEE exceeds
% modelled RE. So set GPP to zero and add difference to RE.
fix_night = true;
[ GPP_2, RE_2, NEE_2 ] = ...
    ensure_carbon_balance( sitecode, ds_qc.timestamp, ...
                           RE_f, NEE_2, ...
                           Rg_f, fix_night );
fix_night = false;
[ GPP_old, RE_old, NEE_old ] = ...
    ensure_carbon_balance( sitecode, ds_qc.timestamp, ...
                           RE_f, NEE_2, ...
                           Rg_f, fix_night );


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
if soil_moisture
    shf_vars = regexp_ds_vars( ds_soil, 'SHF.*' );
    
    ds_soil.Tsoil_1( HL(ds_soil.Tsoil_1, -10, 50 ) ) = NaN;    
    ds_soil.SWC_1( HL( ds_soil.SWC_1, 0, 1 ) ) = NaN;
end

ds_qc.lw_incoming( HL( ds_qc.lw_incoming, 120, 600 ) ) = NaN;
ds_qc.lw_outgoing( HL( ds_qc.lw_outgoing, 120, 650 ) ) = NaN;
ds_qc.E_wpl_massman( HL( ds_qc.E_wpl_massman .* 18, -5, 500 ) ) = NaN;
if ( sitecode == 1 ) & ( year == 2007 )
    ds_qc.CO2_mean( HL( ds_qc.CO2_mean, 344, Inf ) ) = NaN;
else
    ds_qc.CO2_mean( HL( ds_qc.CO2_mean, 350, Inf ) ) = NaN;
end
ds_qc.wnd_spd( HL( ds_qc.wnd_spd, -Inf, 25  ) ) = NaN;
ds_qc.atm_press( HL( ds_qc.atm_press, 20, 150 ) ) = NaN;
ds_qc.Par_Avg( HL( ds_qc.Par_Avg, -100, 5000 ) ) = NaN;
ds_pt.rH( HL( ds_pt.rH, 0, 1 ) ) = NaN;
if soil_moisture
    for i = 1:numel( shf_vars )
        this_shf = ds_soil.( shf_vars{ i } );
        this_shf( HL( this_shf, -150, 150 ) ) = NaN;
        ds_soil.( shf_vars{ i } ) = this_shf;
    end
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
if soil_moisture
    SHF_vars = ds_soil( :, regexp_ds_vars( ds_soil, 'SHF.*' ) );    
    SHF_mean = nanmean( double( SHF_vars ), 2 );
end

% do not include [CO2] for GLand 2009, 2010 -- the calibrations are
% really bad.
if ( sitecode == 1 ) & ismember( year, [ 2009, 2010 ] )
    ds_qc.CO2_mean( : ) = dummy;
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% place calculated values into Matlab datasets 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% initialize variable names, units, etc.
[amflux_gaps, amflux_gf] = ...
    UNM_Ameriflux_create_output_datasets( sitecode, size( ds_qc, 1 ) );

amflux_gaps.timestamp = ds_qc.timestamp;
amflux_gf.timestamp = ds_qc.timestamp;

% assign values to aflx1
amflux_gaps.YEAR = str2num( datestr( amflux_gaps.timestamp, 'YYYY' ) );
amflux_gaps.DTIME = amflux_gaps.timestamp - datenum( amflux_gaps.YEAR, 1, 1 ) + 1;
amflux_gaps.DOY = floor( amflux_gaps.DTIME );
amflux_gaps.HRMIN = str2num( datestr( amflux_gaps.timestamp, 'HHMM' ) ); 
amflux_gaps.UST = ds_qc.u_star;
amflux_gaps.TA = ds_qc.Tdry - 273.15;
amflux_gaps.WD = ds_qc.wnd_dir_compass;
amflux_gaps.WS = ds_qc.wnd_spd;
amflux_gaps.NEE = dummy;
amflux_gaps.FC = NEE_obs;
amflux_gaps.SFC = dummy;
amflux_gaps.H = H_obs;
amflux_gaps.SSA = dummy;
amflux_gaps.LE = LE_obs;
amflux_gaps.SLE = dummy;
amflux_gaps.G1 = dummy; %SHF_mean;
                        %amflux_gaps.TS_2p5cm = dummy; %ds_soil.Tsoil_1;
amflux_gaps.PRECIP = ds_qc.precip;
amflux_gaps.RH = ds_qc.rH .* 100;
amflux_gaps.PA = ds_qc.atm_press;
amflux_gaps.CO2 = ds_qc.CO2_mean;
amflux_gaps.VPD = VPD_g;
%amflux_gaps.SWC_2p5cm = dummy; %ds_soil.SWC_1;
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
amflux_gf.YEAR = str2num( datestr( amflux_gf.timestamp, 'YYYY' ) );
amflux_gf.DTIME = amflux_gf.timestamp - datenum( amflux_gf.YEAR, 1, 1 ) + 1;
amflux_gf.DOY = floor( amflux_gf.DTIME );
amflux_gf.HRMIN = str2num( datestr( amflux_gf.timestamp, 'HHMM' ) ); 
% amflux_gf.YEAR = amflux_gaps.YEAR;
% amflux_gf.DOY = amflux_gaps.DOY;
% amflux_gf.HRMIN = amflux_gaps.HRMIN;
% amflux_gf.DTIME = amflux_gaps.DTIME;
amflux_gf.UST = ds_qc.u_star;
amflux_gf.TA = Tair_f;
amflux_gf.TA_flag = TA_flag;
amflux_gf.WD = ds_qc.wnd_dir_compass;
amflux_gf.WS = ds_qc.wnd_spd;
amflux_gf.NEE = dummy;
amflux_gf.FC = NEE_2;
%amflux_gf.FC_old = NEE_old;
amflux_gf.FC_flag = NEE_flag;
amflux_gf.SFC = dummy;
amflux_gf.H = H_2;
amflux_gf.H_flag = H_flag;
amflux_gf.SSA = dummy;
amflux_gf.LE = LE_2;
amflux_gf.LE_flag = LE_flag;
amflux_gf.SLE = dummy;
amflux_gf.G1 = dummy; %SHF_mean;
                      %amflux_gf.TS_2p5cm = dummy; %ds_soil.Tsoil_1;
amflux_gf.PRECIP = ds_qc.precip;
amflux_gf.RH = ds_pt.rH .* 100;
amflux_gf.RH_flag = rH_flag;
amflux_gf.PA = ds_qc.atm_press;
amflux_gf.CO2 = ds_qc.CO2_mean;
amflux_gf.VPD = VPD_f;
amflux_gf.VPD_flag = VPD_flag;
%amflux_gf.SWC_2p5cm = dummy; %ds_soil.SWC_1;
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
%amflux_gf.RE_old = RE_old;
amflux_gf.RE_flag = NEE_flag;
amflux_gf.GPP = GPP_2;
%amflux_gf.GPP_old = GPP_old;
amflux_gf.GPP_flag = NEE_flag;
amflux_gf.APAR = dummy;    
%amflux_gf.SWC_2 = []; %dummy; %ds_soil.SWC_2;
%amflux_gf.SWC_3 = []; %dummy; %ds_soil.SWC_3;

amflux_gaps.timestamp = [];
amflux_gf.timestamp = [];

%----------------------------------------------------------------------
function [ GPPout, REout, NEEout ] = ...
    ensure_carbon_balance( sitecode, tstamp, REin, NEEin, Rg, fix_night_GPP )
% ENSURE_CARBON_BALANCE - To ensure carbon balance, calculate GPP as remainder
% when NEE is subtracted from RE. This will give negative GPP when NEE exceeds
% modelled RE. So set GPP to zero and add difference to RE.  Beause it is not
% physically realistic to report positive GPP at night, also make sure that
% nighttime GPP is < 0.1.

GPPout = REin - NEEin;
REout = REin;
NEEout = NEEin;

sitecode = UNM_sites( sitecode );
% define an observed Rg threshold, below which we will consider it to be night.
switch sitecode
  case { UNM_sites.GLand, UNM_sites.SLand, UNM_sites.New_GLand }
    Rg_threshold = 1.0;
  case UNM_sites.JSav
    Rg_threshold = -1.0;
  case UNM_sites.PJ
    Rg_threshold = 0.6;
  case UNM_sites.MCon
    Rg_threshold = 0.0;
  case UNM_sites.PPine
    Rg_threshold = 0.1;
  case UNM_sites.TX
    Rg_threshold = 4.0;
  case UNM_sites.PJ_girdle
    Rg_threshold = 5.0;
  otherwise
    error( sprintf( 'Rg threshold not implemented for site %s', ...
                    char( sitecode ) ) );
end
Rg_threshold = Rg_threshold + 1e-6;  %% compare to threshold plus epsilon to
%% allow for floating point error

if fix_night_GPP
    % fix positive GPP at night -- define night as radiation < 20 umol/m2/s set
    % positive nighttime GPP to zero and reduce corresponding respiration
    % accordingly
    sol = get_solar_elevation( UNM_sites( sitecode ), tstamp );
    idx = ( sol < -10 ) & ( Rg < Rg_threshold ) & ( GPPout > 0.1 );
    fprintf( '# of positive nighttime GPP: %d\n', numel( find( idx ) ) );
    % take nighttime positive GPP out of RE 
    REout( idx ) = REout( idx ) - GPPout( idx );
    GPPout( idx ) = 0.0;
    
    idx_RE_negative = REout < 0.0;
    REout( idx_RE_negative ) = 0.0;
    NEEout( idx_RE_negative ) = 0.0;
end

% fix negative GPP
idx_neg_GPP = find( GPPout < 0 );
REout( idx_neg_GPP ) = REin( idx_neg_GPP ) - GPPout( idx_neg_GPP );
GPPout( idx_neg_GPP ) = 0;
