function [ amflx_gaps, amflx_gf ] = prepare_AF_output_data( sitecode, ...
                                                            qc_tbl, ...
                                                            pt_tbl, ...
                                                            soil_tbl, ...
                                                            keenan )
% PREPARE_AF_OUTPUT_DATA - prepare observed fluxes for writing to
%   Ameriflux files.  Mostly creates QC flags and gives various 
%   observations the names they should have for Ameriflux.
%
% Currently NEE, H, LE, Tair, Rg, Precip, and VPD are filled by either
% the mpi gapfiller or from nearby site data
%
%
% USAGE
%    [ amflx_gaps, amflx_gf ] = prepare_AF_output_data( sitecode, ...
%                                                       qc_tbl, ...
%                                                       pt_tbl, ...
%                                                       soil_tbl, ...
%                                                       keenan )
% INPUTS
%    sitecode: UNM_sites object; specifies the site
%    qc_tbl: table array; data from fluxall_QC file
%    pt_tbl: table array; output from MPI gapfiller/flux partitioner output
%    soil_tbl: table array; soil data.  Unused for now -- specify as NaN.
%    keenan: boolean; flag indicating use of keenan partitioned fluxes
%
% OUTPUTS
%    amflx_gaps: table array; with-gaps Ameriflux data
%    amflx_gf: table array; gap-filled Ameriflux data
%
% SEE ALSO
%    UNM_sites, table, UNM_Ameriflux_File_Maker
%
% by: Gregory E. Maurer, UNM, April 2015
%
% Some code adapted from UNM_Ameriflux_prepare_output_data.m and 
% make_AF_output_tables.m by Timothy Hilton

args = inputParser;
args.addRequired( 'sitecode', @(x) ( isintval(x) | isa( x, 'UNM_sites' )));
args.addRequired( 'qc_tbl', @(x) ( isa( x, 'table' )));
args.addRequired( 'pt_tbl', @(x) ( isa( x, 'table' )));
args.addRequired( 'soil_tbl', @(x) ( isa( x, 'table' )));

% parse optional inputs
args.parse( sitecode, qc_tbl, pt_tbl, soil_tbl );

% place user arguments into variables
sitecode = args.Results.sitecode;
qc_tbl = args.Results.qc_tbl;
pt_tbl = args.Results.pt_tbl;
soil_tbl = args.Results.soil_tbl;

soil_moisture = false; % turn off soil moisture processing for now

% Create a column of -9999s to place in the table where a site does
% not record a particular variable
dummy = repmat( -9999, size( qc_tbl, 1 ), 1 );

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Create basic output tables
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

timestamp = qc_tbl.timestamp; % Will be stripped later
% Create an ISO standardized timestamp and convert to numeric.
% Need to use hig precision when writing this to file.
TIMESTAMP = str2num( datestr( timestamp, 'YYYYmmDDHHMMSS' ));
[ YEAR, ~, ~ ] = datevec( timestamp );
DTIME = timestamp - datenum( YEAR, 1, 1 ) + 1;
amflx_gf = table( timestamp, TIMESTAMP, YEAR, DTIME );
amflx_gf.Properties.VariableUnits = { '--', 'YYYYMMDDHHMMSS', ...
    'YYYY', 'DDD.D' };

amflx_gaps = amflx_gf;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Add GAPFILLED met and radiation variables
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Only Tair, VPD, and Rg are filled by the MPI gapfiller
% These + RH and precip are filled with nearby met data
% The verify gapfilling step checks all these.

% Tair
% FIXME - this is sonic temperature (Tdry - 273.15), not hmp
% temperature. See issue 12
TA_flag = verify_gapfilling( pt_tbl.Tair_f, qc_tbl.Tdry - 273.15, 1e-3 );
amflx_gf = add_cols( amflx_gf, pt_tbl.Tair_f, ...
                     { 'TA_F' }, { 'deg C' }, TA_flag );
amflx_gaps = add_cols( amflx_gaps, qc_tbl.Tdry - 273.15, ...
                       { 'TA' }, { 'deg C' } );

% RH
rH_flag = verify_gapfilling( pt_tbl.rH, qc_tbl.rH, 1e-3 );
amflx_gf = add_cols( amflx_gf, pt_tbl.rH, { 'RH_F' }, { '%' }, rH_flag );
amflx_gaps = add_cols( amflx_gaps, qc_tbl.rH, { 'RH' }, { '%' } );

% VPD
VPD_flag = verify_gapfilling( pt_tbl.VPD_f, qc_tbl.VPD, 1e-3 );
% Convert to kPa
VPD = qc_tbl.VPD ./ 10;
VPD_f = pt_tbl.VPD_f ./ 10;
amflx_gf = add_cols( amflx_gf, VPD_f, { 'VPD_F' }, { 'kPa' }, VPD_flag );
amflx_gaps = add_cols( amflx_gaps, VPD, { 'VPD' }, { 'kPa' } );

% Rg - pyrranometer
Rg_flag = verify_gapfilling( pt_tbl.Rg_f, qc_tbl.sw_incoming, 1e-1 );
amflx_gf = add_cols( amflx_gf, pt_tbl.Rg_f, ...
                     { 'SW_IN_F' }, { 'W/m2' }, Rg_flag ); %SW_IN_F
amflx_gaps = add_cols( amflx_gaps, qc_tbl.sw_incoming, ...
                       { 'SW_IN' }, { 'W/m2' } );
% Make sure original RNET is nan in these locations also
qc_tbl.NR_tot( Rg_flag ) = nan;

% Precip
% Gapfilled precip should be found in MPI files
P_flag = verify_gapfilling( pt_tbl.Precip, qc_tbl.precip, 1e-4 );
amflx_gf = add_cols( amflx_gf, pt_tbl.Precip, ... % P_F
    { 'P_F' }, { 'mm' }, P_flag );
amflx_gaps = add_cols( amflx_gaps, qc_tbl.precip, { 'P' }, { 'mm' } );

%%%% % % % % % % % %
% FIXME: for now gapfilling of longwave occurs here

Lio = model_rad_in( sitecode, timestamp, amflx_gf.TA_F, ...
    qc_tbl.atm_press * 10, amflx_gf.RH_F, amflx_gf.SW_IN_F );
lw_in_gf = qc_tbl.lw_incoming;
gf_idx = isnan(lw_in_gf) & pt_tbl.Rg_f >= 25;
% Fill gaps
lw_in_gf( gf_idx ) = Lio( gf_idx, 2 );

% Longwave up - pyrgeometer
LW_IN_flag = verify_gapfilling( lw_in_gf, qc_tbl.lw_incoming, 1e-4 );
amflx_gf = add_cols( amflx_gf, lw_in_gf, ...
                     { 'LW_IN_F' }, { 'W/m2' }, LW_IN_flag ); %LW_IN_F
amflx_gaps = add_cols( amflx_gaps, qc_tbl.lw_incoming, ...
                       { 'LW_IN' }, { 'W/m2' } );
                   
figure();
plot(timestamp, amflx_gf.LW_IN_F, '.r');
hold on;
plot(timestamp, amflx_gaps.LW_IN, '.b');
title('LW_IN');
                   
% Recalculate Rnet
if (sitecode==UNM_sites.GLand || sitecode==UNM_sites.SLand) && ...
        qc_tbl.timestamp(end) < datenum(2008, 01, 01, 0, 30, 0)
    RNET_flag = false( size( amflx_gf, 1 ), 1 );
    amflx_gf = add_cols( amflx_gf, qc_tbl.NR_tot, ...
        { 'RNET_F' }, { 'W/m2' }, RNET_flag );
    amflx_gaps = add_cols( amflx_gaps, qc_tbl.NR_tot, ...
        { 'RNET' }, { 'W/m2' } );
    
else
    rnet_new = ( amflx_gf.SW_IN_F + amflx_gf.LW_IN_F ) - ...
        ( qc_tbl.sw_outgoing + qc_tbl.lw_outgoing );
    
    RNET_flag = verify_gapfilling( rnet_new, qc_tbl.NR_tot, 1e-1 );
    amflx_gf = add_cols( amflx_gf, rnet_new, ...
        { 'RNET_F' }, { 'W/m2' }, RNET_flag ); %RNET_F
    amflx_gaps = add_cols( amflx_gaps, qc_tbl.NR_tot, ...
        { 'RNET' }, { 'W/m2' } );
    
    figure();
    plot(timestamp, amflx_gf.RNET_F, '.r');
    hold on;
    plot(timestamp, amflx_gaps.RNET, '.b');
    title('RNET');
end
%%%% % % % % % % % %

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Add NON-GAPFILLED met and radiation variables
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% FIXME - Potentially missing: APAR, PAR_out, PAR_DIFF, Rg_DIFF.

met_nongf = [ qc_tbl.u_star, qc_tbl.wnd_dir_compass, qc_tbl.wnd_spd, ...
              qc_tbl.atm_press, qc_tbl.Par_Avg, ...%qc_tbl.PAR_out, qc_tbl.NR_tot, qc_tbl.lw_incoming
              qc_tbl.sw_outgoing, qc_tbl.lw_outgoing ];
headers = { 'USTAR', 'WD', 'WS', ...
            'PA', 'PAR', ...%'PAR_out', 'RNET_old', 'LW_IN'
            'SW_OUT', 'LW_OUT' };
units = { 'm/s', 'deg', 'm/s', ...
          'kPa', 'mumol/m2/s', ...% 'mumol/m2/s', 'W/m2', 'W/m2',...
          'W/m2', 'W/m2'};
      
% Make table
met_nongf_tbl = array2table( met_nongf, 'VariableNames', headers );
met_nongf_tbl.Properties.VariableUnits = units;

% Add to output tables
amflx_gf = [ amflx_gf, met_nongf_tbl ];
amflx_gaps = [amflx_gaps, met_nongf_tbl];

clear headers units;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Add filled C, H2O, and energy flux variables
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Since we having eddyproc conduct ustar filtering, we cannot verify the
% gapfilling - just use the flag from the eddyproc output

%FC_flag = verify_gapfilling( pt_tbl.NEE_f, qc_tbl.fc_raw_massman_wpl, ...
%    1e-3 );
FC_flag = pt_tbl.NEE_fqc > 0;
amflx_gf = add_cols( amflx_gf, pt_tbl.NEE_f, ...
    { 'FC_F' }, { 'mumol/m2/s' }, FC_flag );
amflx_gaps = add_cols( amflx_gaps, pt_tbl.NEEorig, ...
    { 'FC' }, { 'mumol/m2/s' } );

%LE_flag = verify_gapfilling( pt_tbl.LE_f, qc_tbl.HL_wpl_massman, 1e-2 );
LE_flag = pt_tbl.LE_fqc > 0;
amflx_gf = add_cols( amflx_gf, pt_tbl.LE_f, ...
    { 'LE_F' }, { 'W/m2' }, LE_flag );
amflx_gaps = add_cols( amflx_gaps, qc_tbl.HL_wpl_massman, ...
    { 'LE' }, { 'W/m2' } );

%H_flag = verify_gapfilling( pt_tbl.H_f, qc_tbl.HSdry_massman, 1e-2 );
H_flag = pt_tbl.H_fqc > 0;
amflx_gf = add_cols( amflx_gf, pt_tbl.H_f, ...
    { 'H_F' }, { 'W/m2' }, H_flag );
amflx_gaps = add_cols( amflx_gaps, qc_tbl.HSdry_massman, ...
    { 'H' }, { 'W/m2' } );

% FIXME??? - not sure I get the difference between E and HL yet - GEM
% qc_tbl.HL_wpl_massman( isnan( qc_tbl.E_wpl_massman ) ) = NaN;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Add NON-FILLED flux variables
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% FIXME - Potentially missing: G1 (SHF_mean), FH2O (E_wpl_massman * .18), 
%         GPP_flag (should be same as FC_flag?).
%         These have been added to prior Ameriflux tables.

flux_nongf = [ qc_tbl.CO2_mean, qc_tbl.H2O_mean ];
headers = { 'CO2', 'H2O' };
units = { 'mumol/mol', 'mmol/mol' };

% Make table
flux_nongf_tbl = array2table( flux_nongf, 'VariableNames', headers );
flux_nongf_tbl.Properties.VariableUnits = units;

% Add to output tables
amflx_gf = [ amflx_gf, flux_nongf_tbl ];
amflx_gaps = [ amflx_gaps, flux_nongf_tbl ];

clear headers units;
      
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Add PARTITIONED C flux variables
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Make a large table of partitioned values first
part_mat = [ pt_tbl.GPP_f, pt_tbl.Reco, ...
             pt_tbl.GPP_HBLR, pt_tbl.Reco_HBLR, ...
             pt_tbl.Reco_HBLR_amended, pt_tbl.amended_flag ];
headers =  {'GPP_F_MR2005', 'RECO_MR2005', ...
            'GPP_GL2010', 'RECO_GL2010', ...
            'RECO_GL2010_amended', 'amended_FLAG' };
units =    { 'mumol/m2/s', 'mumol/m2/s', ...
             'mumol/m2/s', 'mumol/m2/s', 'mumol/m2/s', '--' };

% Keenan 201X partitioning
if keenan
    part_mat = [ part_mat, pt_tbl.GPP_f_TK201X, pt_tbl.RE_f_TK201X ];
    headers = [ headers, 'GPP_F_TK201X', 'RECO_F_TK201X' ];
    units = [ units, 'mumol/m2/s', 'mumol/m2/s' ];
end

% Add partitioned fluxes to output tables
amflx_gf = add_cols( amflx_gf, part_mat, headers, units, FC_flag );
% Backfill the gaps into these columns for the "with_gaps" table
part_mat( FC_flag, : ) = NaN;
amflx_gaps = add_cols( amflx_gaps, part_mat, headers, units );

clear headers units;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Add "Ensure C balance" PARTITIONED C flux variables
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% To ensure carbon balance, calculate GPP as remainder when NEE is
% subtracted from RE. This will give negative GPP when NEE exceeds
% modelled RE. So set GPP to zero and add difference to RE.

MR2005_ecb_tbl = ensure_partitioned_C_balance( sitecode, amflx_gf, ...
    'RECO_MR2005', 'FC_F', 'SW_IN_F', false );

GL2010_ecb_tbl = ensure_partitioned_C_balance( sitecode, amflx_gf, ...
    'RECO_GL2010_amended', 'FC_F', 'SW_IN_F', false );

TK201X_ecb_tbl = table(); % Intitialize empty table
if keenan
    TK201X_ecb_tbl = ensure_partitioned_C_balance( sitecode, amflx_gf, ...
        'RECO_F_TK201X', 'FC_F', 'SW_IN_F', false );
end

% Join ecb tables together
ecb_tbl = [ MR2005_ecb_tbl, GL2010_ecb_tbl, TK201X_ecb_tbl ];

% Add to main output tables
amflx_gf = [ amflx_gf, ecb_tbl ];

% Backfill the gaps into these columns for the "with_gaps" table
ecb_tbl{ FC_flag, : } = NaN; % Add gaps in
amflx_gaps = [ amflx_gaps, ecb_tbl ];

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% A bunch of filtering and bad-data removal
% FIXME - This should be removed or moved elsewhere
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% A little cleaning - very basic high/low filtering
% anon function to find values in x outside of [L H]
%HL = @( x, L, H )  (x < L) | (x > H);

% FIXME - this kind of filtering does not belong here
% qc_tbl.lw_incoming( HL( qc_tbl.lw_incoming, 120, 600 ) ) = NaN;
% qc_tbl.lw_outgoing( HL( qc_tbl.lw_outgoing, 120, 650 ) ) = NaN;
% qc_tbl.E_wpl_massman( HL( qc_tbl.E_wpl_massman .* 18, -5, 500 ) ) = NaN;
% if ( sitecode == 1 ) & ( year == 2007 )
%     qc_tbl.CO2_mean( HL( qc_tbl.CO2_mean, 344, Inf ) ) = NaN;
% else
%     qc_tbl.CO2_mean( HL( qc_tbl.CO2_mean, 350, Inf ) ) = NaN;
% end
% qc_tbl.wnd_spd( HL( qc_tbl.wnd_spd, -Inf, 25  ) ) = NaN;
% qc_tbl.atm_press( HL( qc_tbl.atm_press, 20, 150 ) ) = NaN;
% qc_tbl.Par_Avg( HL( qc_tbl.Par_Avg, -100, 5000 ) ) = NaN;
% RH_pt_scaled( HL( RH_pt_scaled, 0, 1 ) ) = NaN; %RJL added 02/21/2014
% Original    pt_tbl.rH( HL( pt_tbl.rH, 0, 1 ) ) = NaN;

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

% if sitecode == 6 && year == 2008
%     error( 'Put this data removal somewhere else');
%     qc_tbl.lw_incoming( ~isnan( qc_tbl.lw_incoming ) ) = NaN;
%     qc_tbl.lw_outgoing( ~isnan( qc_tbl.lw_outgoing ) ) = NaN;
%     qc_tbl.NR_tot( ~isnan( qc_tbl.NR_tot ) ) = NaN;
% end

% Moving this down to deal with exported tables directly - GEM

% replace 9999s with matlab NaNs
% fp_tol = 0.0001;  % tolerance for floating point comparison
% NEE_obs = replace_badvals( NEE_obs, -9999, fp_tol );
% GPP_obs = replace_badvals( GPP_obs, -9999, fp_tol );
% RE_obs = replace_badvals( RE_obs, -9999, fp_tol );
% H_obs = replace_badvals( H_obs, -9999, fp_tol );
% LE_obs = replace_badvals( LE_obs, -9999, fp_tol );
% VPD_f = replace_badvals( VPD_f, -999.9, fp_tol );

% Hide [CO2] for GLand 2009, 2010 -- the calibrations are
% really bad. FIXME - should we unhide this?
% if ( sitecode == 1 ) && ismember( year, [ 2009, 2010 ] )
%     qc_tbl.CO2_mean( : ) = dummy;
% end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Soil stuff
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Get the names of the soil heat flux variables (how many 
% there are varies site to site)
if soil_moisture
    shf_vars = regexp_header_vars( soil_tbl, 'SHF.*' );
    
    soil_tbl.Tsoil_1( HL( soil_tbl.Tsoil_1, -10, 50 ) ) = NaN;
    soil_tbl.SWC_1( HL( soil_tbl.SWC_1, 0, 1 ) ) = NaN;
end

if soil_moisture
    for i = 1:numel( shf_vars )
        this_shf = soil_tbl.( shf_vars{ i } );
        this_shf( HL( this_shf, -150, 150 ) ) = NaN;
        soil_tbl.( shf_vars{ i } ) = this_shf;
    end
end

% Calculate mean soil heat flux across all pits
if soil_moisture
    SHF_vars = soil_tbl( :, regexp_header_vars( soil_tbl, 'SHF.*' ) );
    SHF_mean = nanmean( double( SHF_vars ), 2 );
end

% Add to AF files?
%amflx_gaps.SWC_2p5cm = dummy; %soil_tbl.SWC_1;
%amflx_gaps.TS_2p5cm = dummy; %soil_tbl.Tsoil_1;

%amflx_gf.SWC_2p5cm = dummy; %soil_tbl.SWC_1;
%amflx_gf.TS_2p5cm = dummy; %soil_tbl.Tsoil_1;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Change any leftover error values to NaN
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

fp_tol = 0.0001;  % tolerance for floating point comparison
amflx_gaps = replace_badvals( amflx_gaps, -9999, fp_tol );
amflx_gf = replace_badvals( amflx_gf, -9999, fp_tol );

%----------------------------------------------------------------------
% Subfunctions

    % Function to add colums of data to a table, including headers and
    % units
    function tbl_out = add_cols( tbl_in, add_mat, ...
                                 headers, units, varargin )
        % If there is a data flag append it and give it a name indicating
        % the first column to use this flag
        if ~isempty( varargin ) && islogical( varargin{ 1 })
            gaps = varargin{ 1 };
            % and then append the flag to the end of the table
            headers{ end + 1 } = [ headers{ 1 } '_FLAG' ];
            units{ end + 1 } = '--';
            prep_add_mat = [ add_mat, gaps ];
        else
            prep_add_mat = add_mat;
        end         
        tbl_add = array2table( prep_add_mat, 'VariableNames', headers );
        tbl_add.Properties.VariableUnits = units;
        % Make the new table by concatenating the 2 tables
        tbl_out = [ tbl_in, tbl_add ];
    end

    % Function to make sure the observed data and gapfilled data don't
    % overlap - returns a flag indicating where gapfilling has occurred
    function gap_flag = verify_gapfilling( gapfilled, obs, tol )
        % Verify that gapfilled and obs are the same size
        if length( gapfilled ) ~= length( obs )
            error( 'Gapfilled and observed data have different sizes!' );
        end
        % Initialize a gapfilled data flag to true
        % ( double - old int8 flag was problematic )
        gap_flag = true( size( obs, 1 ), 1 );
        gap_flag( ~isnan( obs ) ) = false; % Mark observations with zero
        % Backfill the gapfilled column with observations when available
        gapfilled_obs = gapfilled;
        gapfilled_obs( ~gap_flag ) = obs( ~gap_flag );
        % Do the backfilled and original gapfilled columns match?
        % There are some small rounding errors when comparing mpi output
        % to our files, but otherwise the columns should be the same
        difftest = abs( gapfilled - gapfilled_obs ) > tol ;
        if sum( difftest ) > 0
            % Figure showing observations that passed the QC process
            % (in fluxall_qc_rbd) but still appear to be gapfilled.
            % This may be due to rounding error (check tolerance used),
            % different contents in the fluxall_qc_rbd and 
            % for_gapfilling_filled files (check creation dates), or 
            % perhaps the gapfiller is overfilling the data.
            figure( 'name', 'Error output' );
            plot( gapfilled_obs, '-g' );
            hold on;
            plot( gapfilled, '-b' );
            plot( find( difftest ), obs( difftest ), 'or' );
            legend( 'Gapfilled + qcOK observed', 'Gapfilled only', ...
                'Filled qcOK observations' );
            error( 'Gapfilled and fluxall_qc_rbd observations are different!' );
        end
    end
        
end
