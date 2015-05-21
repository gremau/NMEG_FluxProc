function [ amflux_gaps, amflux_gf ] = ...
    UNM_Ameriflux_prepare_output_data( sitecode, ...
    year, ...
    qc_tbl, ...
    pt_tbl, ...
    soil_tbl, ...
    keenan )
% UNM_AMERIFLUX_PREPARE_FLUXES - prepare observed fluxes for writing to
%   Ameriflux files.  Mostly creates QC flags and gives various observations the
%   names they should have for Ameriflux.
% This code is largely taken from UNM_Ameriflux_file_maker_011211.m
%
% FIXME: the workflow in this is confusing (though I've cleaned it up a
% bit) because it generates a ton of arrays using repetetive methods and
% then some template tables get filled in. It would be smarter to build 1
% table and then split it into with/without gaps tables using the flags in
% a smart way.
%
% FIXME - Deprecated. This function is being superseded by
% prepare_AF_output_data.m
%
% USAGE
%    [ amflux_gaps, amflux_gf ] = ...
%        UNM_Ameriflux_prepare_output_data( sitecode, ...
%                                           year, ...
%                                           qc_tbl, ...
%                                           pt_tbl, ...
%                                           soil_tbl )
% INPUTS
%    sitecode: UNM_sites object; specifies the site
%    year: four-digit year: specifies the year
%    qc_tbl: table array; data from fluxall_QC file
%    pt_tbl: table array; output from MPI gapfiller/flux partitioner output
%    soil_tbl: table array; soil data.  Unused for now -- specify as NaN.
%
% OUTPUTS
%    amflux_gaps: table array; with-gaps Ameriflux data
%    amflux_gf: table array; gap-filled Ameriflux data
%
% SEE ALSO
%    UNM_sites, table, UNM_Ameriflux_File_Maker,
%    UNM_parse_gapfilled_partitioned_output, UNM_parse_QC_txt_file
%
% (c) Timothy W. Hilton, UNM, January 2012

warning( 'This function (UNM_Ameriflux_prepare_output_data) is deprecated!' );

[ this_year, ~, ~ ] = datevec( now );

args = inputParser;
args.addRequired( 'sitecode', @(x) ( isintval( x ) | isa( x, 'UNM_sites' ) ) );
args.addRequired( 'year', ...
    @(x) ( isintval( x ) & ( x >= 2006 ) & ( x <= this_year ) ) );
args.addRequired( 'qc_tbl', @(x) ( isa( x, 'table' ) ) );
args.addRequired( 'pt_tbl', @(x) ( isa( x, 'table' ) ) );
args.addRequired( 'soil_tbl', @(x) ( isa( x, 'table' ) ) );

% parse optional inputs
args.parse( sitecode, year, qc_tbl, pt_tbl, soil_tbl );

% place user arguments into variables
sitecode = args.Results.sitecode;
year_arg = args.Results.year;
qc_tbl = args.Results.qc_tbl;
pt_tbl = args.Results.pt_tbl;
soil_tbl = args.Results.soil_tbl;

% Including filled precip in AF files for now!
gf_met_tbl = parse_forgapfilling_file( sitecode, year, 'use_filled', true );
Pidx = isnan( gf_met_tbl.Precip );
gf_met_tbl.Precip( Pidx ) = 0; % Change NaN values to 0

soil_moisture = false; % turn off soil moisture processing for now

% create a column of -9999s to place in the table where a site does not record
% a particular variable
dummy = repmat( -9999, size( qc_tbl, 1 ), 1 );

% A little cleaning - very basic high/low filtering
% anon function to find values in x outside of [L H]
HL = @( x, L, H )  (x < L) | (x > H);

% initialize flags to 1
% f_flag = int8( repmat( 1, size( qc_tbl, 1 ), 1 ) );
% Double data type works better for data export
f_flag = repmat( 1, size( qc_tbl, 1 ), 1 );
NEE_flag = f_flag;
LE_flag = f_flag;
H_flag = f_flag;
TA_flag = f_flag;
Rg_flag = f_flag;
VPD_flag = f_flag;
rH_flag = f_flag;

% Get VPD from MPI output
VPD_f = pt_tbl.VPD_f ./ 10; % convert to kPa

% Seems to be trying to put calculated values of VPD in the AF with_gaps
% file from periods where we actually have rH (though we didn't calculate
% this VPD value).
VPD_g = dummy;
VPD_g( ~isnan( qc_tbl.rH ) ) = VPD_f( ~isnan( qc_tbl.rH ) );

%RJL 02/21/2014 converted the MPI online GF/P output from percent
%    to 0-1 to be consistent with qc input. Gets multiplied by 100
%    in this script.
%RH_pt_scaled = ds_pt.rH .* 0.01;

% FIXME - this is sonic temperature (filled in by MPI), not HMP
% see issue # 12
Tair_f = pt_tbl.Tair_f;
Rg_f = pt_tbl.Rg_f;
%Rg_f( pt_tbl.Rg_fqcOK == 0 ) = NaN;
Rg_f( HL( Rg_f, -50, Inf ) ) = NaN;

% set met flags to zero where observations exist
% TA_flag( ~isnan( qc_tbl.air_temp_hmp ) ) = int8( 0 );
% Rg_flag( ~isnan( qc_tbl.sw_incoming ) ) = int8( 0 );
% VPD_flag( ~isnan( qc_tbl.rH ) ) = int8( 0 );
% rH_flag( ~isnan( qc_tbl.rH ) ) = int8( 0 );

TA_flag( ~isnan( qc_tbl.air_temp_hmp ) ) = 0 ;
Rg_flag( ~isnan( qc_tbl.sw_incoming ) ) = 0 ;
VPD_flag( ~isnan( qc_tbl.rH ) ) = 0 ;
rH_flag( ~isnan( qc_tbl.rH ) ) = 0 ;

% make vector containing only observed temperature
Tair_obs = Tair_f;
Tair_obs( TA_flag == 1 ) = NaN;

% initialize observed fluxes to NaNs
NEE_obs = dummy;
LE_obs = dummy;
H_obs = dummy;

% fill in valid flux obs. and set corresponding flags to zero for...
% NEE,
idx = ~isnan( qc_tbl.fc_raw_massman_wpl );
NEE_obs( idx ) =   qc_tbl.fc_raw_massman_wpl( idx );
NEE_flag( idx ) = 0;
% LE,
idx = ~isnan( qc_tbl.HL_wpl_massman );
LE_obs( idx ) = qc_tbl.HL_wpl_massman( idx );
LE_flag( idx ) = 0;
% and H
idx = ~isnan( qc_tbl.HSdry_massman );
H_obs( idx ) = qc_tbl.HSdry_massman( idx );
H_flag( idx ) = 0;

% set NEE_flag to 1 where local gapfilling was performed
%idx_filled = UNM_gapfill_from_local_data( sitecode, year, table( [] ) );
%NEE_flag( idx_filled ) = 1;

% Reichstein filled NEE
NEE_f = pt_tbl.NEE_f;

% Select partitioning columns to use
% Lasslop 2010: 
RE_f_GL2010  = pt_tbl.Reco_HBLR;
GPP_f_GL2010 = pt_tbl.GPP_HBLR;
% Reichstein 2005
RE_f_MR2005  = pt_tbl.Reco;
GPP_f_MR2005 = pt_tbl.GPP_f;
% Keenan
if keenan
    RE_f_TK201X  = pt_tbl.RE_f_TK201X;
    GPP_f_TK201X = pt_tbl.GPP_f_TK201X;
end

% Latent and sensible heat fluxes
LE_f = pt_tbl.LE_f;
H_f = pt_tbl.H_f;

% Make sure fluxes contains observations where available
NEE_f2 = NEE_f;
NEE_f2( ~NEE_flag ) = NEE_obs( ~NEE_flag );
% and LE
LE_f2 = LE_f;
LE_f2( ~LE_flag ) = qc_tbl.HL_wpl_massman( ~LE_flag );
% and H
H_f2 = H_f;
H_f2( ~H_flag ) = qc_tbl.HSdry_massman( ~H_flag );

% Do the observations in qc_pt and the filled files match?
test = sum( [ NEE_f - NEE_f2 ; H_f - H_f2 ; LE_f - LE_f2 ] );
if abs( test ) > 0.1
    error( 'Gapfilled and non-gapfilled data are different!' );
    NEE_f = NEE_f2;
    H_f = H_f2;
    LE_f = LE_f2;
end

% To ensure carbon balance, calculate GPP as remainder when NEE is
% subtracted from RE. This will give negative GPP when NEE exceeds
% modelled RE. So set GPP to zero and add difference to RE.

% _ecb fluxes are what were in AF files before the change
fix_night = true;
% Lasslop
[ GPP_f_GL2010_ecb, RE_f_GL2010_ecb, NEE_f_GL2010_ecb ] = ...
    ensure_carbon_balance( sitecode, qc_tbl.timestamp, ...
    RE_f_GL2010, NEE_f, ...
    Rg_f, fix_night );
% Reichstein
[ GPP_f_MR2005_ecb, RE_f_MR2005_ecb, NEE_f_MR2005_ecb ] = ...
    ensure_carbon_balance( sitecode, qc_tbl.timestamp, ...
    RE_f_MR2005, NEE_f, ...
    Rg_f, fix_night );
% Keenan
if keenan
    [ GPP_f_TK201X_ecb, RE_f_TK201X_ecb, NEE_f_TK201X_ecb ] = ...
        ensure_carbon_balance( sitecode, qc_tbl.timestamp, ...
        RE_f_TK201X, NEE_f, ...
        Rg_f, fix_night );
end
% This is without nighttime GPP correction (?)
fix_night = false;
[ GPP_f_GL2010_oldecb, RE_f_GL2010_oldecb, NEE_f_GL2010_oldecb ] = ...
    ensure_carbon_balance( sitecode, qc_tbl.timestamp, ...
    RE_f_GL2010, NEE_f, ...
    Rg_f, fix_night );
% Reichstein
[ GPP_f_MR2005_oldecb, RE_f_MR2005_oldecb, NEE_f_MR2005_oldecb ] = ...
    ensure_carbon_balance( sitecode, qc_tbl.timestamp, ...
    RE_f_MR2005, NEE_f, ...
    Rg_f, fix_night );
% Keenan
if keenan
    [ GPP_f_TK201X_oldecb, RE_f_TK201X_oldecb, NEE_f_TK201X_oldecb ] = ...
        ensure_carbon_balance( sitecode, qc_tbl.timestamp, ...
        RE_f_TK201X, NEE_f, ...
        Rg_f, fix_night );
end

% Make GPP and RE "obs" for output to file with gaps using modeled RE
% and GPP as remainder
% Commenting out - GEM - will add GPP/RE columns above to with_gaps and
% then remove modeled periods with NEE_flag
% GPP_obs = dummy;
% idx = ~isnan( qc_tbl.fc_raw_massman_wpl );
% GPP_obs( idx ) = GPP_2( idx );
% RE_obs = dummy;
% RE_obs( idx ) = RE_2( idx );

% FIXME??? - not sure I get the difference between E and HL yet GEM
qc_tbl.HL_wpl_massman( isnan( qc_tbl.E_wpl_massman ) ) = NaN;

%get the names of the soil heat flux variables (how many there are varies
%site to site)
if soil_moisture
    shf_vars = regexp_header_vars( soil_tbl, 'SHF.*' );
    
    soil_tbl.Tsoil_1( HL( soil_tbl.Tsoil_1, -10, 50 ) ) = NaN;
    soil_tbl.SWC_1( HL( soil_tbl.SWC_1, 0, 1 ) ) = NaN;
end

% FIXME - this kind of filtering does not belong here
qc_tbl.lw_incoming( HL( qc_tbl.lw_incoming, 120, 600 ) ) = NaN;
qc_tbl.lw_outgoing( HL( qc_tbl.lw_outgoing, 120, 650 ) ) = NaN;
qc_tbl.E_wpl_massman( HL( qc_tbl.E_wpl_massman .* 18, -5, 500 ) ) = NaN;
if ( sitecode == 1 ) & ( year == 2007 )
    qc_tbl.CO2_mean( HL( qc_tbl.CO2_mean, 344, Inf ) ) = NaN;
else
    qc_tbl.CO2_mean( HL( qc_tbl.CO2_mean, 350, Inf ) ) = NaN;
end
qc_tbl.wnd_spd( HL( qc_tbl.wnd_spd, -Inf, 25  ) ) = NaN;
qc_tbl.atm_press( HL( qc_tbl.atm_press, 20, 150 ) ) = NaN;
qc_tbl.Par_Avg( HL( qc_tbl.Par_Avg, -100, 5000 ) ) = NaN;
%RH_pt_scaled( HL( RH_pt_scaled, 0, 1 ) ) = NaN; %RJL added 02/21/2014
%Original    pt_tbl.rH( HL( pt_tbl.rH, 0, 1 ) ) = NaN;
if soil_moisture
    for i = 1:numel( shf_vars )
        this_shf = soil_tbl.( shf_vars{ i } );
        this_shf( HL( this_shf, -150, 150 ) ) = NaN;
        soil_tbl.( shf_vars{ i } ) = this_shf;
    end
end
% FIXME - GEM
% This shouldn't be here - commenting and if needed we can do this
% somewhere else.
% NEE_f( HL( NEE_f, -50, 50 ) ) = NaN;
% RE_f( HL( RE_f, -50, 50) ) = NaN;
% GPP_f( HL( GPP_f, -50, 50 ) ) = NaN;
% NEE_obs( HL( NEE_obs, -50, 50 ) ) = NaN;
% RE_obs( HL( RE_obs, -50, 50 ) ) = NaN;
% GPP_obs( HL( GPP_obs, -50, 50 ) ) = NaN;
% NEE_f( HL( NEE_f, -50, 50 ) ) = NaN;
% RE_2( HL( RE_2, -50, 50 ) ) = NaN;
% GPP_2( HL( GPP_2, -50, 50 ) ) = NaN;

if sitecode == 6 && year == 2008
    error( 'Put this data removal somewhere else');
    qc_tbl.lw_incoming( ~isnan( qc_tbl.lw_incoming ) ) = NaN;
    qc_tbl.lw_outgoing( ~isnan( qc_tbl.lw_outgoing ) ) = NaN;
    qc_tbl.NR_tot( ~isnan( qc_tbl.NR_tot ) ) = NaN;
end

% Moving this down to deal with exported tables directly - GEM

% replace 9999s with matlab NaNs
% fp_tol = 0.0001;  % tolerance for floating point comparison
% NEE_obs = replace_badvals( NEE_obs, -9999, fp_tol );
% GPP_obs = replace_badvals( GPP_obs, -9999, fp_tol );
% RE_obs = replace_badvals( RE_obs, -9999, fp_tol );
% H_obs = replace_badvals( H_obs, -9999, fp_tol );
% LE_obs = replace_badvals( LE_obs, -9999, fp_tol );
% VPD_f = replace_badvals( VPD_f, -999.9, fp_tol );

% calculate mean soil heat flux across all pits
if soil_moisture
    SHF_vars = soil_tbl( :, regexp_header_vars( soil_tbl, 'SHF.*' ) );
    SHF_mean = nanmean( double( SHF_vars ), 2 );
end

% Hide [CO2] for GLand 2009, 2010 -- the calibrations are
% really bad. FIXME - should we unhide this?
if ( sitecode == 1 ) & ismember( year, [ 2009, 2010 ] )
    qc_tbl.CO2_mean( : ) = dummy;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% place calculated values into Matlab tables
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    function w_gaps = insert_gaps( coldata, gaps )
        w_gaps = dummy;
        w_gaps( ~gaps ) = coldata( ~gaps );
    end

% initialize variable names, units, etc.
[amflux_gaps, amflux_gf] = ...
    make_AF_output_tables( sitecode, size( qc_tbl, 1 ) );

amflux_gaps.timestamp = qc_tbl.timestamp;
amflux_gf.timestamp = qc_tbl.timestamp;

% assign values to aflx1
amflux_gaps.YEAR = str2num( datestr( amflux_gaps.timestamp, 'YYYY' ) );
amflux_gaps.DTIME = amflux_gaps.timestamp - datenum( amflux_gaps.YEAR, 1, 1 ) + 1;
amflux_gaps.DOY = floor( amflux_gaps.DTIME );
amflux_gaps.HRMIN = str2num( datestr( amflux_gaps.timestamp, 'HHMM' ) );
amflux_gaps.UST = qc_tbl.u_star;
amflux_gaps.TA = Tair_obs; %FIXME - evaluate this!
amflux_gaps.WD = qc_tbl.wnd_dir_compass;
amflux_gaps.WS = qc_tbl.wnd_spd;
amflux_gaps.NEE = dummy;
amflux_gaps.FC = NEE_obs;
%amflux_gaps.FC_ecb = insert_gaps( NEE_f_ecb, NEE_flag );
%amflux_gaps.FC_oldecb = insert_gaps( NEE_f_oldecb, NEE_flag );
amflux_gaps.SFC = dummy;
amflux_gaps.H = H_obs;
amflux_gaps.SSA = dummy;
amflux_gaps.LE = LE_obs;
amflux_gaps.SLE = dummy;
amflux_gaps.G1 = dummy; %SHF_mean;
%amflux_gaps.TS_2p5cm = dummy; %soil_tbl.Tsoil_1;
amflux_gaps.PRECIP = qc_tbl.precip;
amflux_gaps.RH = qc_tbl.rH .* 100;
amflux_gaps.PA = qc_tbl.atm_press;
amflux_gaps.CO2 = qc_tbl.CO2_mean;
amflux_gaps.VPD = VPD_g;
%amflux_gaps.SWC_2p5cm = dummy; %soil_tbl.SWC_1;
amflux_gaps.RNET = qc_tbl.NR_tot;
amflux_gaps.PAR = qc_tbl.Par_Avg;
amflux_gaps.PAR_DIFF = dummy;
amflux_gaps.PAR_out = dummy;
amflux_gaps.Rg = qc_tbl.sw_incoming;
amflux_gaps.Rg_DIFF = dummy;
amflux_gaps.Rg_out = qc_tbl.sw_outgoing;
amflux_gaps.Rlong_in = qc_tbl.lw_incoming;
amflux_gaps.Rlong_out = qc_tbl.lw_outgoing;
amflux_gaps.FH2O = qc_tbl.E_wpl_massman .* 18;
amflux_gaps.H20 = qc_tbl.H2O_mean;
% Lasslop
amflux_gaps.RE_f_GL2010  = insert_gaps( RE_f_GL2010, NEE_flag );
amflux_gaps.GPP_f_GL2010 = insert_gaps( GPP_f_GL2010, NEE_flag );
% Reichstein 2005
amflux_gaps.RE_f_MR2005  = insert_gaps( RE_f_MR2005, NEE_flag );
amflux_gaps.GPP_f_MR2005 = insert_gaps( GPP_f_MR2005, NEE_flag );
% Keenan
if keenan
    amflux_gaps.RE_f_TK201X  = insert_gaps( RE_f_TK201X, NEE_flag );
    amflux_gaps.GPP_f_TK201X = insert_gaps( GPP_f_TK201X, NEE_flag );
end
% ecb versions
amflux_gaps.NEE_f_GL2010_ecb = insert_gaps( NEE_f_GL2010_ecb, NEE_flag );
amflux_gaps.RE_f_GL2010_ecb  = insert_gaps( RE_f_GL2010_ecb, NEE_flag );
amflux_gaps.GPP_f_GL2010_ecb = insert_gaps( GPP_f_GL2010_ecb, NEE_flag );
amflux_gaps.NEE_f_MR2005_ecb = insert_gaps( NEE_f_MR2005_ecb, NEE_flag );
amflux_gaps.RE_f_MR2005_ecb  = insert_gaps( RE_f_MR2005_ecb, NEE_flag );
amflux_gaps.GPP_f_MR2005_ecb = insert_gaps( GPP_f_MR2005_ecb, NEE_flag );
if keenan
    amflux_gaps.NEE_f_TK201X_ecb = insert_gaps( NEE_f_TK201X_ecb, NEE_flag );
    amflux_gaps.RE_f_TK201X_ecb  = insert_gaps( RE_f_TK201X_ecb, NEE_flag );
    amflux_gaps.GPP_f_TK201X_ecb = insert_gaps( GPP_f_TK201X_ecb, NEE_flag );
end
% oldecb versions
amflux_gaps.NEE_f_GL2010_oldecb = insert_gaps( NEE_f_GL2010_oldecb, NEE_flag );
amflux_gaps.RE_f_GL2010_oldecb  = insert_gaps( RE_f_GL2010_oldecb, NEE_flag );
amflux_gaps.GPP_f_GL2010_oldecb = insert_gaps( GPP_f_GL2010_oldecb, NEE_flag );
amflux_gaps.NEE_f_MR2005_oldecb = insert_gaps( NEE_f_MR2005_oldecb, NEE_flag );
amflux_gaps.RE_f_MR2005_oldecb  = insert_gaps( RE_f_MR2005_oldecb, NEE_flag );
amflux_gaps.GPP_f_MR2005_oldecb = insert_gaps( GPP_f_MR2005_oldecb, NEE_flag );
if keenan
    amflux_gaps.NEE_f_TK201X_oldecb = insert_gaps( NEE_f_TK201X_oldecb, NEE_flag );
    amflux_gaps.RE_f_TK201X_oldecb  = insert_gaps( RE_f_TK201X_oldecb, NEE_flag );
    amflux_gaps.GPP_f_TK201X_oldecb = insert_gaps( GPP_f_TK201X_oldecb, NEE_flag );
end
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
amflux_gf.UST = qc_tbl.u_star;
amflux_gf.TA = Tair_f;
amflux_gf.TA_flag = TA_flag;
amflux_gf.WD = qc_tbl.wnd_dir_compass;
amflux_gf.WS = qc_tbl.wnd_spd;
amflux_gf.NEE = dummy;
amflux_gf.FC = NEE_f;
amflux_gf.FC_flag = NEE_flag;
amflux_gf.SFC = dummy;
amflux_gf.H = H_f;
amflux_gf.H_flag = H_flag;
amflux_gf.SSA = dummy;
amflux_gf.LE = LE_f;
amflux_gf.LE_flag = LE_flag;
amflux_gf.SLE = dummy;
amflux_gf.G1 = dummy; %SHF_mean;
%amflux_gf.TS_2p5cm = dummy; %soil_tbl.Tsoil_1;
amflux_gf.PRECIP = gf_met_tbl.Precip;
%amflux_gf.RH = RH_pt_scaled .* 100; %RJL 02/21/2014 added
%original    amflux_gf.RH = pt_tbl.rH .* 100;
amflux_gf.RH_flag = rH_flag;
amflux_gf.PA = qc_tbl.atm_press;
amflux_gf.CO2 = qc_tbl.CO2_mean;
amflux_gf.VPD = VPD_f;
amflux_gf.VPD_flag = VPD_flag;
%amflux_gf.SWC_2p5cm = dummy; %soil_tbl.SWC_1;
amflux_gf.RNET = qc_tbl.NR_tot;
amflux_gf.PAR = qc_tbl.Par_Avg;
amflux_gf.PAR_DIFF = dummy;
amflux_gf.PAR_out = dummy;
amflux_gf.Rg = Rg_f;
amflux_gf.Rg_flag = Rg_flag;
amflux_gf.Rg_DIFF = dummy;
amflux_gf.Rg_out = qc_tbl.sw_outgoing;
amflux_gf.Rlong_in = qc_tbl.lw_incoming;
amflux_gf.Rlong_out = qc_tbl.lw_outgoing;
amflux_gf.FH2O = qc_tbl.E_wpl_massman .* 18;
amflux_gf.H20 = qc_tbl.H2O_mean;
% Lasslop
amflux_gf.RE_f_GL2010  = RE_f_GL2010;
amflux_gf.GPP_f_GL2010 = GPP_f_GL2010;
% Reichstein 2005
amflux_gf.RE_f_MR2005  = RE_f_MR2005;
amflux_gf.GPP_f_MR2005 = GPP_f_MR2005;
% Keenan
if keenan
    amflux_gf.RE_f_TK201X  = RE_f_TK201X;
    amflux_gf.GPP_f_TK201X = GPP_f_TK201X;
end
% ecb versions
amflux_gf.NEE_f_GL2010_ecb = NEE_f_GL2010_ecb;
amflux_gf.RE_f_GL2010_ecb  = RE_f_GL2010_ecb;
amflux_gf.GPP_f_GL2010_ecb = GPP_f_GL2010_ecb;
amflux_gf.NEE_f_MR2005_ecb = NEE_f_MR2005_ecb;
amflux_gf.RE_f_MR2005_ecb  = RE_f_MR2005_ecb;
amflux_gf.GPP_f_MR2005_ecb = GPP_f_MR2005_ecb;
if keenan
    amflux_gf.NEE_f_TK201X_ecb = NEE_f_TK201X_ecb;
    amflux_gf.RE_f_TK201X_ecb  = RE_f_TK201X_ecb;
    amflux_gf.GPP_f_TK201X_ecb = GPP_f_TK201X_ecb;
end
% oldecb versions
amflux_gf.NEE_f_GL2010_oldecb = NEE_f_GL2010_oldecb;
amflux_gf.RE_f_GL2010_oldecb  = RE_f_GL2010_oldecb;
amflux_gf.GPP_f_GL2010_oldecb = GPP_f_GL2010_oldecb;
amflux_gf.NEE_f_MR2005_oldecb = NEE_f_MR2005_oldecb;
amflux_gf.RE_f_MR2005_oldecb  = RE_f_MR2005_oldecb;
amflux_gf.GPP_f_MR2005_oldecb = GPP_f_MR2005_oldecb;
if keenan
    amflux_gf.NEE_f_TK201X_oldecb = NEE_f_TK201X_oldecb;
    amflux_gf.RE_f_TK201X_oldecb  = RE_f_TK201X_oldecb;
    amflux_gf.GPP_f_TK201X_oldecb = GPP_f_TK201X_oldecb;
end
amflux_gf.GPP_flag = NEE_flag;
amflux_gf.APAR = dummy;
%amflux_gf.SWC_2 = []; %dummy; %soil_tbl.SWC_2;
%amflux_gf.SWC_3 = []; %dummy; %soil_tbl.SWC_3;

amflux_gaps.timestamp = [];
amflux_gf.timestamp = [];

% Change error values to NaN
fp_tol = 0.0001;  % tolerance for floating point comparison
amflux_gaps = replace_badvals( amflux_gaps, -9999, fp_tol );
amflux_gf = replace_badvals( amflux_gf, -9999, fp_tol );
%----------------------------------------------------------------------
    function [ GPPout, REout, NEEout ] = ensure_carbon_balance( ...
            sitecode, tstamp, REin, NEEin, Rg, fix_night_GPP )
        % ENSURE_CARBON_BALANCE - To ensure carbon balance, calculate GPP as remainder
        % when NEE is subtracted from RE. This will give negative GPP when NEE exceeds
        % modelled RE. So set GPP to zero and add difference to RE.  Beause it is not
        % physically realistic to report positive GPP at night, also make sure that
        % nighttime GPP is < 0.1.
        
        GPPout = REin - NEEin;
        REout = REin;
        NEEout = NEEin;
        
        sitecode = UNM_sites( sitecode );
        % define an observed Rg threshold, below which we will consider
        % it to be night.
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
        Rg_threshold = Rg_threshold + 1e-6;  %% compare to threshold plus
        % epsilon to allow for floating point error
        
        if fix_night_GPP
            % fix positive GPP at night -- define night as 
            % radiation < 20 umol/m2/s set positive nighttime GPP to 
            % zero and reduce corresponding respiration accordingly
            sol = get_solar_elevation( UNM_sites( sitecode ), tstamp );
            idx = ( sol < -10 ) & ( Rg < Rg_threshold ) & ( GPPout > 0.1 );
            fprintf( '# of positive nighttime GPP: %d\n', numel( find( idx ) ) );
            % Subtract nighttime positive GPP from RE
            REout( idx ) = REout( idx ) - GPPout( idx );
            GPPout( idx ) = 0.0;
            % Change NEE and RE to zero any time there are 
            % negative RE values
            idx_RE_negative = REout < 0.0;
            REout( idx_RE_negative ) = 0.0;
            NEEout( idx_RE_negative ) = 0.0;
        end
        
        % fix negative GPP
        idx_neg_GPP = find( GPPout < 0 );
        REout( idx_neg_GPP ) = REin( idx_neg_GPP ) - GPPout( idx_neg_GPP );
        GPPout( idx_neg_GPP ) = 0;
        
    end
end
