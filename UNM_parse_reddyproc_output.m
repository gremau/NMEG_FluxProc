function tbl_gf_pt = UNM_parse_reddyproc_output( sitecode, year )
% UNM_PARSE_REDDYPROC_OUTPUT - parse the output of ReddyProc
% gapfilling/partitioning tool (local) into Matlab dataset array.  
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
%    ds_gf_pt = UNM_parse_reddyproc_output( sitecode, year )
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
% author: Timothy W. Hilton, UNM, Feb 2012

% parse the gapfilled and partitioned data
fname = fullfile( get_site_directory( sitecode ), ...
                  'processed_flux', ...
                  sprintf( 'data_gapfilled_partitioned_%s_%d.txt', ...
                           get_site_name( sitecode ), year ) );

[ ~, fname_short, ext ] = fileparts( fname );
fprintf( 'reading %s.%s... ', fname_short, ext );

try
    tbl_gf_pt = parse_reddyproc( fname );  %GL == Gita Lasslop
catch err
    error( sprintf( 'error parsing %s', fname) );
end

tbl_gf_pt = replace_badvals( tbl_gf_pt, [-9999], 1e-6 );

seconds = 0;
tbl_gf_pt.timestamp = datenum( tbl_gf_pt.year, ...
                              tbl_gf_pt.month, ...
                              tbl_gf_pt.day, ...
                              tbl_gf_pt.hour, ...
                              tbl_gf_pt.minute, ...
                              seconds );

fprintf( 'done\n');   

function out = parse_reddyproc(fname)
% PARSE_REDDYPROC - parses an output file from the Jena local (or online?)
% gapfilling/partitioning tool.  
%
% The online tool places some leading whitespace on each data line; this parser
% does not require that whitespace to be removed.  Likewise, this parser does
% not require the second header line of the data file to be removed.
%
% Though it was written for parsing output of the Jena gapfilling/partitioning
% tool, it should in theory work for any whitespace-delimited ASCII data file
% where the first row contains the variable names, the second row contains
% units, and rows three to EOF contain data.
%
% The output is a matlab dataset array.  The dataset may be converted to a
% matrix of doubles using double(out).
%
% Missing values (-9999, -999, etc) are kept.  They may be replace with NaNs
% using replace_badvals.
%
% USAGE
%      out = parse_jena_output(fname);
%
% INPUTS
%     fname: string; full path to the data file to be parsed
% OUTPUTS
%     out: matlab dataset array; the data in the file
%
% SEE ALSO
%     dataset, replace_badvals
%
% author: Timothy W. Hilton, UNM

fid = fopen(fname, 'r');
line1 = fgetl(fid);

% split line1 by consecutive whitespace
vars = regexp(line1, '\s*', 'split');
vars = vars(not(cellfun(@isempty, vars)));
vars = genvarname(vars);  %make sure vars are valid matlab names
nvars = numel(vars);

% throw out the second header line (units)
line2 = fgetl(fid);
units = regexp(line2, '\s*', 'split');

fmt = repmat('%f', 1, nvars);
arr = cell2mat(textscan(fid, fmt, 'CollectOutput', true));

%out = dataset({arr, vars{:}});
out = array2table( arr, 'VariableNames', vars );




