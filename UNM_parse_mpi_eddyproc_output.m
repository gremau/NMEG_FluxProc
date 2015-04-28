function [ pt_in_MR, pt_in_GL ] = ...
    UNM_parse_mpi_eddyproc_output( sitecode, year )
% UNM_PARSE_MPI_EDDYPROC_OUTPUT - parse the output of MPI Jena's online
% gapfilling/partitioning tool into Matlab tables.  In January 2012 Jena
% updated the tool to merge the old DatasetAfterGapfill.txt into
% DataSetAfterPartition_GL2010.txt for jobs that requested partitioning.
% This version of the function expects to find two partitioned output 
% files:
% DataSetAfterPartition_GL2010.txt and DataSetAfterPartition.txt.
%
% [ pt_in_MR, pt_in_GL ] = ...
%     UNM_parse_mpi_eddyproc_output( sitecode, year )
%
% OUTPUT:
%   pt_in_MR: Matlab table containing data from DataSetAfterPartition.txt
%             (partitioning algorithm of Markus Reichstein 2005)
%   pt_in_GL: Matlab table containing data from
%             DataSetAfterPartition_GL2010.txt (partitioning algorithm of
%             Gita Lasslop 2010)
%
% author: Gregory E. Maurer, UNM, April 2015
% Modified from: UNM_parse_gapfilled_partitioned_output_TWH and 
%                parse_jena_output by Timothy Hilton.

% Parse the Lasslop 2010 partitioned file
fname = fullfile( get_site_directory( sitecode ), ...
    'processed_flux', ...
    sprintf( 'DataSetafterFluxpartGL2010_%d.txt', year ) );

[ ~, fname_short, ext ] = fileparts( fname );
fprintf( 'reading %s%s... ', fname_short, ext );

% Exception handling
try
    pt_in_GL = parse_eddyproc_output( fname );  %GL == Gita Lasslop
catch err
    error( sprintf( 'error parsing %s', fname) );
end
fprintf( 'done\n');

% Parse the Reichstein 2005 partitioned file
fname = fullfile( get_site_directory( sitecode ), ...
    'processed_flux', ...
    sprintf( 'DataSetafterFluxpart_%d.txt', year ) );

[ ~, fname_short, ext ] = fileparts( fname );
fprintf( 'reading %s%s... ', fname_short, ext );

try
    pt_in_MR = parse_eddyproc_output( fname );  %MR == Markus Reichstein
catch err
    error( sprintf( 'error parsing %s', fname ) );
end
fprintf( 'done\n');

    function out = parse_eddyproc_output( fname )
        % PARSE_EDDYPROC_OUTPUT - parses an output file from the MPI online
        % gapfilling/partitioning tool (used to be parse_jena_output).
        %
        % The online tool places some leading whitespace on each data line;
        % this parser does not require that whitespace to be removed.  
        % Likewise, this parser does not require the second header line of
        % the data file to be removed.
        %
        % Missing values (-9999) are replaced with NaNs
        %
        % USAGE
        %      out = parse_eddyproc_output(fname);
        %
        % INPUTS
        %     fname: string; full path to the data file to be parsed
        % OUTPUTS
        %     out: matlab table array; the data in the file
        %
        % SEE ALSO
        %     table, replace_badvals

        
        fid = fopen(fname, 'r');
        line1 = fgetl(fid);
        
        % split line1 by consecutive whitespace
        vars = regexp( line1, '\s*', 'split' );
        vars = vars(not( cellfun( @isempty, vars )));
        vars = genvarname( vars );  %make sure vars are valid matlab names
        nvars = numel( vars );
        
        % throw out the second header line (units)
        line2 = fgetl( fid );
        units = regexp( line2, '\s*', 'split' );
        
        % Read data from the file
        fmt = repmat( '%f', 1, nvars );
        arr = cell2mat( textscan( fid, fmt, 'CollectOutput', true ));
        
        % Create table
        out = array2table( arr, 'VariableNames', vars );
        % Replace -9999 with matlab NaNs
        out = replace_badvals( out, [-9999], 1e-6 );
        % Add a timestamp
        seconds = zeros( size( out.Year ) );
        out.timestamp = datenum( out.Year, ...
            out.Month, ...
            out.Day, ...
            out.Hour, ...
            out.Minute, ...
            seconds );
        
    end
end