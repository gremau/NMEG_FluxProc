function result = UNM_Ameriflux_file_maker_TWH( sitecode, year )
% UNM_AMERIFLUX_FILE_MAKER_TWH
%
% UNM_Ameriflux_file_maker_TWH( sitecode, year )
% This code reads in the QC file, the original annual flux all file for
% soil data and the gap filled and flux partitioned files and generates
% output in a format for submission to Ameriflux
%
% based on code created by Krista Anderson Teixeira in July 2007 and modified by
% John DeLong 2008 through 2009.  Extensively modified by Timothy W. Hilton 2011
% to 2012.
%
% Timothy W. Hilton, UNM, Dec 2011 - Jan 2012


    site = get_site_name( sitecode );

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % parse Flux_All, Flux_All_qc, gapfilled fluxes, and partitioned fluxes
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    %% parse the annual Flux_All file
    data = UNM_parse_fluxall_xls_file( sitecode, year );

    %% parse the QC file
    qc_num = UNM_parse_QC_xls_file( sitecode, year );
    ds_qc = fluxallqc_2_dataset( qc_num, sitecode, year );
    
    %% parse gapfilled and partitioned fluxes
    [ ds_gf, ds_pt ] = UNM_parse_gapfilled_partitioned_output( sitecode, year );
    
    % make sure that QC, FluxAll, gapfilled, and partitioned have identical,
    % complete 30 minute timeseries
    [ ds_qc, data ] = merge_datasets_by_datenum( ds_qc, data, ...
                                                 'timestamp', 'timestamp', 3 );
    [ ds_gf, data ] = merge_datasets_by_datenum( ds_gf, data, ...
                                                 'timestamp', 'timestamp', 3 );
    [ ds_pt, data ] = merge_datasets_by_datenum( ds_pt, data, ...
                                                 'timestamp', 'timestamp', 3 );

    %% parsing the excel files is slow -- this loads parsed data for testing
    %%load( '/media/OS/Users/Tim/DataSandbox/GLand_2010_fluxall.mat' );

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % do some bookkeeping
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    % create a column of -9999s to place in the dataset where a site does not record
    % a particular variable
    dummy = repmat( -9999, size( ds_qc, 1 ), 1 );

    %% calculate fractional day of year (i.e. 3 Jan at 12:00 would be 3.5)
    ds_qc.fjday = ( ds_qc.jday + ...
                    ( ds_qc.hour / 24.0 ) + ...
                    ( ds_qc.minute / ( 24.0 * 60.0) ) );
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % data processing and fixing datalogger & instrument errors 
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    %% fix incorrect precipitation values
    ds_qc.precip = fix_incorrect_precip_factors( sitecode, year, ...
                                                 ds_qc.fjday, ds_qc.precip );

    % create dataset of soil properties.
    ds_soil = UNM_Ameriflux_prepare_soil_met( sitecode, year, data, ds_qc );
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % create Ameriflux output dataset and write to ASCII files
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    % create the variables to be written to the output files
    [ amflux_gf, amflux_gaps ] = ...
        UNM_Ameriflux_prepare_output_data( sitecode, year, ...
                                           data, ds_qc, ...
                                           ds_gf, ds_pt, ds_soil );

    save test_restart.mat
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % plot the data before writing out to files
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % plot_handles = UNM_Ameriflux_make_plots( aflx1, aflx2 );

    UNM_Ameriflux_write_file( sitecode, year, amflux_gf, ...
                              'mlitvak@unm.edu', 'gapfilled' );
    
    UNM_Ameriflux_write_file( sitecode, year, amflux_gaps, ...
                              'mlitvak@unm.edu', 'with_gaps' );
    
    result = 1;