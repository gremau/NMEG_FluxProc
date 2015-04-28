function tbl = parse_TK201X_output( sitecode, year )
% PARSE_TK201X_OUTPUT - parse Trevor Keenan's partitioning
% files
%
% [ pt_in_MR, pt_in_GL ] = ...
%     parse_TK201X_output( sitecode, year )
%
% OUTPUT:
%   pt_in_MR: Matlab table containing data from DataSetAfterPartition.txt
%             (partitioning algorithm of Markus Reichstein 2005)

%
% written by: Gregory E. Maurer, UNM, April 2015

site_conf = parse_yaml_site_config( 'SiteVars.yaml', sitecode );
af_name = site_conf.ameriflux_name;

% Look for the right file
dirname = fullfile( get_site_directory( sitecode ), ...
    'processed_flux', 'keenan_partition' );
files =  dir( dirname );
files = { files.name };
rexp = sprintf( 'AMF_US%s_%d', af_name( 4:end ), year );
match = cellfun( @( x ) regexpi( x, rexp ), files, ...
    'UniformOutput', false );
match = ~ cellfun( 'isempty', match.' ); % Convert to a logical array

if any( match )
    %Get filename
    filename = files{ match };
    
    % Read to table
    tbl = readtable( fullfile( dirname, filename ) );
    
    % Convert YEAR, DOY, HRMIN to a datenum
    hourminute_prepend = num2str( tbl.HRMIN, '%04i');
    [ ~, ~, ~, hour, min ] = datevec( hourminute_prepend( :, : ), 'HHMM');
    proto_dn = datenum( tbl.YEAR, 1, 1, hour, min, 0 );
    tbl.timestamp = proto_dn + tbl.DOY - 1;
else
    fprintf( 'No Keenan partitioned file \n' );
    tbl = table( [] );
end
    

