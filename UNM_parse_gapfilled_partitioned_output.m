function ds_gf_pt = UNM_parse_gapfilled_partitioned_output( sitecode, year )
% UNM_PARSE_GAPFILLED_PARTITIONED_OUTPUT - parse the output of Jena's online
% gapfilling/partitioning tool into Matlab dataset array.  
%
% In January 2012 Jena updated the online tool to merge the old
% DatasetAfterGapfill.txt into DataSetAfterPartition_GL2010.txt for jobs that
% requested partitioning.  In July 2013 Jena released REddyProc, an R package
% for gapfilling and partitioning.  REddyProc allows local gapfilling and
% partitioning.  As of 7 Aug 2013, the partitioning component of REddyProc is in
% a testing phase and is not activated in the publicly released package.
%
% This version of UNM_parse_gapfilled_partitioned_output expects to find the
% gapfilled and partitioned output in a single file:
% data_gapfilled_partitioned_SITE_YEAR.txt.  This file may be created using
% UNM_run_gapfiller.
%
% data_gapfilled_partitioned_SITE_YEAR.txt must contain columns for year, month,
% day, hour, and minute.  This function converts these to Matlab serial
% datenumbers and appends these to the output in a column labeled "timestamp".
% 
% USAGE
%    ds_gf_pt = UNM_parse_gapfilled_partitioned_output( sitecode, year )
%
% INPUTS:
%    sitecode: UNM_sites object; specifies the UNM site
%    year: integer; specifies the four-digit year
%
% OUTPUT:
%    df_gf_pt: dataset array; the gapfilled and (hopefully soon) partitioned
%        data
%
% SEE ALSO
%   dataset, UNM_sites, datenum, UNM_run_gapfiller
%
% (c) Timothy W. Hilton, UNM, Feb 2012

% parse the gapfilled and partitioned data
fname = fullfile( get_site_directory( sitecode ), ...
                  'processed_flux', ...
                  sprintf( 'data_gapfilled_partitioned_%s_%d.txt', ...
                           char( sitecode ), ...
                           year ) );

[ ~, fname_short, ext ] = fileparts( fname );
fprintf( 'reading %s.%s... ', fname_short, ext );

try
    ds_gf_pt = parse_jena_output( fname );  %GL == Gita Lasslop
catch err
    error( sprintf( 'error parsing %s', fname) );
end

seconds = 0;
ds_gf_pt.timestamp = datenum( ds_gf_pt.year, ...
                              ds_gf_pt.month, ...
                              ds_gf_pt.day, ...
                              ds_gf_pt.hour, ...
                              ds_gf_pt.minute, ...
                              seconds );

fprintf( 'done\n');    




