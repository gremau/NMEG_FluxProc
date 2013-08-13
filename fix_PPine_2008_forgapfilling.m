function changed_idx = fix_PPine_2008_forgapfilling()
% FIX_PPINE_2008_FORGAPFILLING - fix some problems in MCon NEE for 2008.
%
% The gapfiller/partitioner places several large spikes in NEE in late in early
% 2008.  This function scales the NEE spikes down to more reasonable peaks and
% writes a new for_gapfilling file.
%
% USAGE
%    changed_idx = fix_PPine_2008_forgapfilling()
%
% OUTPUT
%    changed_idx: 1xN vector; true where fluxes were manipulated, false
%        elsewhere 
%
% author: Timothy W. Hilton, UNM, Apr 2013

fgf = parse_forgapfilling_file( UNM_sites.PPine, 2008 );
aflx_gf = parse_ameriflux_file( fullfile( getenv( 'FLUXROOT' ), ...
                                          'FluxOut', ...
                                          'US-Vcp_2008_gapfilled.txt' ) );

% "before" plot
figure();
h_orig = plot( aflx_gf.DTIME, aflx_gf.FC, 'ok' );
hold on

changed_idx = repmat( false, size( fgf, 1 ), 1 );

% scale DOY 1-80 down to max of 4.0 (as per 18 Apr 2013 conversation with
% Marcy)
[ fgf, spike_idx ] = despike_for_gapfilling_NEE( aflx_gf, fgf, 1, 80, 4.0 );

changed_idx( spike_idx ) = true;

% "after" plot
h_fixed = plot( aflx_gf.DTIME( 1:size( fgf, 1 ) ), fgf.NEE, '.' );
h_idx = plot( aflx_gf.DTIME( 1:size( fgf, 1 ) ), changed_idx, '.r' );
legend( [ h_orig, h_fixed, h_idx ], ...
        { 'original', 'fixed NEE', 'fixed idx' }, ...
        'location', 'best' );

% write a new for-gapfilling file
fgf.timestamp = [];
fname = fullfile( get_site_directory( UNM_sites.PPine ),...
                  'processed_flux', ...
                  'PPine_flux_all_2008_for_gap_filling_filled_despiked.txt' );
export_dataset_tim( fname, fgf, ...
                    'replace_nans', -9999, ...
                    'write_units', true ); 
fprintf( 'wrote %s\n', fname );

