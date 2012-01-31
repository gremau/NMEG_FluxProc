function amflux_ds = ameriflux_2_dataset()
% AMERIFLUX_2_DATASET - 
%   


filter_spec = fullfile( getenv( 'FLUXROOT' ), 'Ameriflux_Files', '*.txt' );
[ fname, fpath ] = uigetfile( filter_spec, 'Select an Ameriflux file' );
amflux_ds = parse_ameriflux_file( fullfile( fpath, fname ) );
