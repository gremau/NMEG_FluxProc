function tbl = parse_fluxall_qc_file( sitecode, year )
% PARSE_FLUXALL_QC_FILE - parse tab-delimited ASCII QC file to matlab dataset
%
%   
% The QC file is created by UNM_RemoveBadData (or UNM_RemoveBadData_pre2012).
%
% USAGE:
%     tbl = UNM_parse_QC_txt_file( sitecode, year );
% 
% INPUTS
%    sitecode: UNM_sites object; specifies the site to show
%    year: four-digit year: specifies the year to show
%
% OUTPUTS:
%    tbl: dataset array; the data from the QC file
%
% SEE ALSO
%    dataset, UNM_RemoveBadData, UNM_RemoveBadData_pre2012
%
% author: Timothy W. Hilton, UNM, April 2012

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
tbl = readtable(  qcfile, ...
                 'Delimiter', '\t', ...
                 'Format', fmt );

tbl = replace_badvals( tbl, [-9999], 1e-6 );

tbl.timestamp = datenum( tbl.year, tbl.month, tbl.day, ...
    tbl.hour, tbl.minute, tbl.second );


fprintf( 'done\n');