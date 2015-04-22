function changed_idx = fix_PPine_2012_forgapfilling()
% FIX_PPINE_2012_FORGAPFILLING - fix some problems in PPine NEE for 2012.
%
% The gapfiller/partitioner places two large spikes in NEE in late July/early
% August and Dec 2012.  This function scales the NEE spikes down to more
% reasonable peaks and writes a new for_gapfilling file.  Returns 0 on success.
%
% USAGE
%    changed_idx = fix_PPine_2012_forgapfilling()
%
% OUTPUT
%    changed_idx: 1xN vector; true where fluxes were manipulated, false
%        elsewhere 
%
% author: Timothy W. Hilton, UNM, Oct 2012

error('Should this script be running????');

fgf = parse_forgapfilling_file( UNM_sites.PPine, 2012 );
aflx_gf = parse_ameriflux_file( fullfile( getenv( 'FLUXROOT' ), ...
                                          'FluxOut', ...
                                          'US-Vcp_2012_gapfilled.txt' ) );

changed_idx = repmat( false, size( fgf, 1 ), 1 );
% scale DOY 1-80 down to max of 4.0 (as per 18 Apr 2013 conversation with
% Marcy)
[ fgf, spike_idx ] = despike_for_gapfilling_NEE( aflx_gf, fgf, 200, 225, 12.0 );
changed_idx( spike_idx ) = true;

[ fgf, spike_idx ] = despike_for_gapfilling_NEE( aflx_gf, fgf, 261, 269, 8.0 );
changed_idx( spike_idx ) = true;

[ fgf, spike_idx ] = despike_for_gapfilling_NEE( aflx_gf, fgf, 342, 349, 4.0 );
changed_idx( spike_idx ) = true;

figure();
plot( aflx_gf.DTIME, aflx_gf.FC, 'ok' );
hold on

% set QC to "good" so that gapfiller does not  overwrite
fgf.qcNEE( spike_idx ) = 1;  

plot( aflx_gf.DTIME( 1:size( fgf, 1 ) ), fgf.NEE, '.' );

fgf.timestamp = [];

fname = fullfile( get_site_directory( UNM_sites.PPine ),...
                  'processed_flux', ...
                  'PPine_flux_all_2012_for_gap_filling_filled_despiked.txt' );
export_dataset_tim( fname, fgf, 'replace_nans', -9999); 
fprintf( 'wrote %s\n', fname );

