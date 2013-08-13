function success = fix_PPine_2010_forgapfilling()
% FIX_PPINE_2010_FORGAPFILLING - fix some problems in MCon NEE for 2010.
%
% The gapfiller/partitioner places two large spikes in NEE in late July and Nov
% 2010.  This function scales the NEE spikes down to more reasonable peaks and
% writes a new for_gapfilling file.  Returns 0 on success.
%
% USAGE
%    success = fix_PPine_2012_forgapfilling()
%
% author: Timothy W. Hilton, UNM, Oct 2012

fgf = parse_forgapfilling_file( UNM_sites.PPine, 2010 );
aflx_gf = parse_ameriflux_file( fullfile( getenv( 'FLUXROOT' ), ...
                                          'FluxOut', ...
                                          'US-Vcp_2010_gapfilled.txt' ) );

% "before" plot
figure();
plot( aflx_gf.DTIME, aflx_gf.FC, 'ok' );
hold on

% scale DOY 314-330 down to max of 8
fgf = despike_for_gapfilling_NEE( aflux_gf, fgf, 314, 330, 8.0 );
% scale DOY 330-350 down to max of 2 (as per 18 Apr 2013 conversation with
% Marcy)
fgf = despike_for_gapfilling_NEE( aflux_gf, fgf, 330, 350, 2.0 );
% scale DOY 197-203 down to max of 8 (as per 18 Apr 2013 conversation with
% Marcy)
fgf = despike_for_gapfilling_NEE( aflux_gf, fgf, 197, 203, 8.0 );

% "after" plot
plot( aflx_gf.DTIME( 1:size( fgf, 1 ) ), fgf.NEE, '.' );

% write a new for-gapfilling file
fgf.timestamp = [];
fname = fullfile( get_site_directory( UNM_sites.PPine ),...
                  'processed_flux', ...
                  'PPine_flux_all_2010_for_gap_filling_filled_despiked.txt' );
export_dataset_tim( fname, fgf, 'replace_nans', -9999); 
fprintf( 'wrote %s\n', fname );

success = 0;