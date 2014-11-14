function [ pt_in_MR, pt_in_GL ] = ...
        UNM_parse_gapfilled_partitioned_output_TWH( sitecode, year )
% UNM_PARSE_GAPFILLED_PARTITIONED_OUTPUT - parse the output of Jena's online
% gapfilling/partitioning tool into Matlab Datasets.  In January 2012 Jena
% updated the tool to merge the old DatasetAfterGapfill.txt into
% DataSetAfterPartition_GL2010.txt for jobs that requested partitioning.  This
% version of this function expects to find two partitioned output files:
% DataSetAfterPartition_GL2010.txt and DataSetAfterPartition.txt.
%   
% [ pt_in_MR, pt_in_GL ] = ...
%     UNM_parse_gapfilled_partitioned_output_TWH( sitecode, year )
%
% OUTPUT:
%   pt_in_MR: Matlab dataset containing data from DataSetAfterPartition.txt
%             (partitioning algorithm of Markus Reichstein 2005)
%   pt_in_GL: Matlab dataset containing data from 
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
        pt_in_GL = parse_jena_output( fname );  %GL == Gita Lasslop
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
        pt_in_MR = parse_jena_output( fname );  %MR == Markus Reichstein
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
    



