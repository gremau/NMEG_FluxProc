function success = fix_PPine_2009_forgapfilling()
% FIX_PPINE_2012_FORGAPFILLING - The gapfiller/partitioner places three large
%   spikes in NEE from days 150 to 250.  This function scales the NEE spikes
%   down to more reasonable peaks and writes a new for_gapfilling file.  The
%   range of NEE is scaled to [-15,15].  This makes the maximum respiration
%   consistent with the maximum respiration from other years, and preserved
%   the daily cycle.  Some amount of NEE spike in days 150 to 195 is probably
%   reasobable -- this period corresponds to the first liquid precip of the
%   year (judging by precip and Rg_outgoing observations) as well as the
%   onset of nighttime low temperatures above zero.
%
% Returns 0 on success.
%
% USAGE
%    success = fix_PPine_2012_forgapfilling()
%
% (c) Timothy W. Hilton, UNM, Oct 2012

fgf = parse_forgapfilling_file( UNM_sites.PPine, 2009, true );
aflx_gf = parse_ameriflux_file( fullfile( getenv( 'FLUXROOT' ), ...
                                          'FluxOut', ...
                                          'US-Vcp_2009_gapfilled.txt' ) );

spike_idx = find( aflx_gf.FC_flag & ...
                  ( aflx_gf.DTIME >= 150 ) & ...
                  ( aflx_gf.DTIME <= 250 ) &...
                  ( aflx_gf.FC > -10000 ) );

figure();
plot( aflx_gf.DTIME, aflx_gf.FC, 'ok' );
hold on

x = aflx_gf.FC( spike_idx );
x_adj = normalize_vector( x, -15, 15 );
fgf.NEE( spike_idx ) = x_adj;

plot( aflx_gf.DTIME( 1:size( fgf, 1 ) ), fgf.NEE, '.' );

fgf.timestamp = [];

fname = fullfile( get_site_directory( UNM_sites.PPine ),...
                  'processed_flux', ...
                  'PPine_flux_all_2009_for_gap_filling_filled_despiked.txt' );
export_dataset_tim( fname, fgf, 'replace_nans', -9999); 
fprintf( 'wrote %s\n', fname );

success = 0;