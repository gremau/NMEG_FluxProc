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
    % Specify some details about sites and years
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    
    
    % sitecode key
    afnames(1,:) = 'US-Seg'; % 1-GLand
    afnames(2,:) = 'US-Ses'; % 2-SLand
    afnames(3,:) = 'US-Wjs'; % 3-JSav
    afnames(4,:)='US-Mpj'; % 4-PJ
    afnames(5,:)='US-Vcp'; % 5-PPine
    afnames(6,:)='US-Vcm'; % 6-MCon
    afnames(7,:)='US-FR2'; % 7-TX_savanna
    afnames(8,:)='US-FR3'; % 8-TX_forest
    afnames(9,:)='US-FR1'; % 9-TX_grassland
    afnames(10,:)='US-Mpg'; % 4-PJ
    afnames(11,:)='US-Sen'; % 11-N4611 Montbel Place New_GLand

    year_s=num2str(year);

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

    save test_restart.mat
    
    % create the variables to be written to the output files
    [ aflx1, aflx2 ] = UNM_Ameriflux_prepare_output_data( sitecode, year, ...
                                                      data, ds_qc, ...
                                                      ds_gf, ds_pt, ds_soil );
    
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % plot the data before writing out to files
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % plot_handles = UNM_Ameriflux_make_plots( aflx1, aflx2 );


    datamatrix1 = [year,intjday,(hour.*100)+minute, ds.fjdayday,u_star,air_temp_hmp, ...
                   wnd_dir_compass,wnd_spd, dummy,NEE_obs,dummy,H_obs,dummy, ...
                   LE_obs,dummy,ground, Tsoil_1,precip,rH.*100,atm_press, ...
                   CO2_mean,VPD_g,SWC_1,NR_tot,Par_Avg,dummy,dummy,sw_incoming, ...
                   dummy,sw_outgoing,lw_incoming,lw_outgoing,E_wpl_massman.*18, ...
                   H2O_mean,RE_obs,GPP_obs,dummy]; % E_wpl_massman.*18 = water
                                                   % flux in mg/m2/s

    %create a dataset from the non-gapfilled data
    vnames = genvarname(header1);
    ds_notfilled = dataset({datamatrix1, vnames{:}});

    datamatrix1(isnan(datamatrix1))=-9999;

    filename = strcat(outfolder,afnames(sitecode,:),'_',year_s,'_with_gaps.txt');

    time_out=fix(clock);
    time_out=datestr(time_out);
    sname={'Site name: ',afnames(sitecode,:)};
    email={'Email: mlitvak@unm.edu'};
    timeo={'Created: ',time_out};

    dlmwrite(filename,sname,'');
    dlmwrite(filename,email,'-append','delimiter','');
    dlmwrite(filename,timeo,'-append','delimiter','');

    txt=sprintf('%s\t',header1{:});
    txt(end)='';
    dlmwrite(filename,txt,'-append','delimiter','');

    txt=sprintf('%s\t',units1{:});
    txt(end)='';
    dlmwrite(filename,txt,'-append','delimiter','');
    dlmwrite(filename,datamatrix1,'-append','delimiter','\t');


    datamatrix2 = [year,intjday,(hour.*100)+minute, ds.fjday,u_star,Tair_f,TA_flag, ...
                   wnd_dir_compass,wnd_spd, dummy,NEE_2,NEE_flag,dummy,H_2, ...
                   H_flag,dummy,LE_2,LE_flag,dummy,ground, Tsoil_1,precip,rH.* ...
                   100,atm_press,CO2_mean,VPD_f,VPD_flag,SWC_1,NR_tot,Par_Avg, ...
                   dummy,dummy,Rg_f,Rg_flag, dummy,sw_outgoing,lw_incoming, ...
                   lw_outgoing,E_wpl_massman.*18,H2O_mean,RE_2,NEE_flag,GPP_2, ...
                   NEE_flag,dummy,SWC_2,SWC_3];


    vnames = genvarname(header2);
    ds_gapfilled = dataset({datamatrix2, vnames{:}});

    datamatrix2(isnan(datamatrix2))=-9999;

    filename = strcat(outfolder,afnames(sitecode,:),'_',year_s,'_gapfilled.txt');


    time_out=fix(clock);
    time_out=datestr(time_out);
    sname={'Site name: ',afnames(sitecode,:)};
    email={'Email: mlitvak@unm.edu'};
    timeo={'Created: ',time_out};

    dlmwrite(filename,sname,'');
    dlmwrite(filename,email,'-append','delimiter','');
    dlmwrite(filename,timeo,'-append','delimiter','');

    txt=sprintf('%s\t',header2{:});
    txt(end)='';
    dlmwrite(filename,txt,'-append','delimiter','');

    txt=sprintf('%s\t',units2{:});
    txt(end)='';
    dlmwrite(filename,txt,'-append','delimiter','');

    dlmwrite(filename,datamatrix2,'-append','delimiter','\t');

