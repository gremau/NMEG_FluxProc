function qc_ds = UNM_parse_QC_txt_file( sitecode, year )
% UNM_PARSE_QC_TXT_FILE - parse tab-delimited ASCII QC file to matlab dataset
%   
% USAGE:
%     qc_ds = UNM_parse_QC_txt_file( sitecode, year )
%
% (c) Timothy W. Hilton, UNM, April 2012

site = get_site_name( sitecode );

qcfile = fullfile( get_site_directory( sitecode ), ...
                   'processed_flux', ...
                   sprintf( '%s_flux_all_%d_qc.txt', site, year ) );

[ ~, fname, ext ] = fileparts( qcfile );
fprintf( 'reading %s... ', qcfile );

% count the number of columns in the file - this varies between sites
fid = fopen( qcfile, 'r' );
header_line = fgetl( fid );
n_cols = numel( regexp( header_line, '\t', 'split' ) );

fmt = repmat( '%f', 1, n_cols );
%fmt = '%f';
qc_ds = dataset( 'File', qcfile, ...
                 'Delimiter', '\t', ...
                 'format', fmt );

qc_ds.timestamp = datenum( qc_ds.year, qc_ds.month, qc_ds.day, ...
                           qc_ds.hour, qc_ds.minute, qc_ds.second );


fprintf( 'done\n');