function [ pt_in_MR, pt_in_GL ] = ...
        UNM_parse_mpi_eddyproc_output( sitecode, year )
% UNM_PARSE_MPI_EDDYPROC_OUTPUT - parse the output of Jena's online
% gapfilling/partitioning tool into Matlab Datasets.  In January 2012 Jena
% updated the tool to merge the old DatasetAfterGapfill.txt into
% DataSetAfterPartition_GL2010.txt for jobs that requested partitioning.  This
% version of this function expects to find two partitioned output files:
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
% (c) Timothy W. Hilton, UNM, Feb 2012
    
%% parse the Lasslop 2010 partitioned file
    fname = fullfile( get_site_directory( sitecode ), ...
                      'processed_flux', ...
                      sprintf( 'DataSetafterFluxpartGL2010_%d.txt', year ) );

    [ ~, fname_short, ext ] = fileparts( fname );
    fprintf( 'reading %s.%s... ', fname_short, ext );

    % exception handling added by MF, modified by TWH
    try
        pt_in_GL = parse_eddyproc_output( fname );  %GL == Gita Lasslop
    catch err
        error( sprintf( 'error parsing %s', fname) );
    end
    seconds = zeros( size( pt_in_GL.Year ) );
    pt_in_GL.timestamp = datenum( pt_in_GL.Year, ...
                                  pt_in_GL.Month, ...
                                  pt_in_GL.Day, ...
                                  pt_in_GL.Hour, ...
                                  pt_in_GL.Minute, ...
                                  seconds );

    %% parse the Reichstein 2005 partitioned file
    fname = fullfile( get_site_directory( sitecode ), ...
                      'processed_flux', ...
                      sprintf( 'DataSetafterFluxpart_%d.txt', year ) );
    % exception handling added by MF, modified by TWH
    try
        pt_in_MR = parse_eddyproc_output( fname );  %MR == Markus Reichstein
    catch err
        error( sprintf( 'error parsing %s', fname ) );
    end
    seconds = zeros( size( pt_in_MR.Year ) );
    pt_in_MR.timestamp = datenum( pt_in_MR.Year, ...
                                  pt_in_MR.Month, ...
                                  pt_in_MR.Day, ...
                                  pt_in_MR.Hour, ...
                                  pt_in_MR.Minute, ...
                                  seconds );
    
    fprintf( 'done\n');
    
    function out = parse_eddyproc_output( fname )
        % PARSE_EDDYPROC_OUTPUT - parses an output file from the MPI online
        % gapfilling/partitioning tool (used to be parse_jena_output).
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
        % The output is a matlab table array.  The dataset may be converted to a
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
        %     out: matlab table array; the data in the file
        %
        % SEE ALSO
        %     dataset, replace_badvals
        %
        % author: Timothy W. Hilton, UNM
        
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
        
        fmt = repmat( '%f', 1, nvars );
        arr = cell2mat( textscan( fid, fmt, 'CollectOutput', true ));
        
        out = array2table( arr, 'VariableNames', vars );
    end
end
    



