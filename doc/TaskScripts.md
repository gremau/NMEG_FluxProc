# Scripts for common tasks

## Task scripts

Common tasks have scripts that can be run with common configurations, and are easily modified. These scripts can be found in the [scripts](scripts/) directory. Each of these scripts can be set to run for a list of sites and years and to overwrite existing output files or not.

### Create new "fluxall" files

Fluxall files (`{site}_{year}_fluxall.txt`) should contain raw data from all sensors at a site for one year. The [script_make_fluxall.m](/scripts/script_make_fluxall.m) script will make these files, primarily by calling [card_data_processor.m](card_data_processor.m) in various configurations and reading the raw data in 'toa5' and 'ts_data' directories. Though these files should contain all sensor data, in practice there are some sites with dataloggers that have not been configured to be merged into the fluxall file (namely the Valles Caldera sites).

### Create new "qc", "for_gapfilling", and "for_gapfilling_filled" files

There are several files created from the NMEG quality control pipeline, all output to the "processed_flux" directory. These are:

1. "qc" files (`{site}_{years}_fluxall_qc.txt`): Contain all variables that are quality-controlled and then output by the [UNM_RemoveBadData.m](UNM_RemoveBadData.m) script.

2. "for_gapfilling" files (`{site}_flux_all_{year}_for_gap_filling.txt`): Also output by [UNM_RemoveBadData.m](UNM_RemoveBadData.m) script and contain a subset of quality-controlled variables in a format ready to be filled with ancillary met data.

3. "for_gapfilling_filled" files (`{site}_flux_all_{year}_for_gap_filling_filled.txt`): Same as the file above, but gaps in the met variables have been filled with ancillary met data by the [UNM_fill_met_gaps_from_nearby_site.m](UNM_fill_met_gaps_from_nearby_site.m) script.

To make these files, run the [script_make_qc_gf.m](/scripts/script_make_qc_gf.m). This script may also run the REddyProc gapfilling tool by calling on the [R code from the Max Planck institute](https://www.bgc-jena.mpg.de/bgi/index.php/Services/REddyProcWebRPackage), and the output (also in 'processed_flux') can be used to make AmeriFlux files, below, if desired.

### Create new AmeriFlux files

AmeriFlux files (`{af-site}_{year}_gapfilled.txt` and `{af-site}_{year}_with_gaps.txt`) contain quality controlled sensor data, gapfilled met data, gapfilled fluxes, and partitioned C fluxes. There are several steps currently needed to create them.

1. Send the "for_gapfilling_filled" file for each site/year to the [MPI EddyProc web service](http://www.bgc-jena.mpg.de/~MDIwork/eddyproc/upload.php). This service provides gapfilled and partitioned flux data, and is the way we currently have to get Lasslop partitioned fluxes used for the lower elevation NMEG sites.

2. Once you receive notification that the partitioner has finished (by email), copy the job number and run [download_gapfilled_partitioned_flux.m](/retrieve_card_data/download_gapfilled_partitioned_flux.m) with the job number as an argument. This will download the resulting files to the "processed_flux" directory.

3. Run [script_make_ameriflux.m](/scripts/script_make_ameriflux.m), which will call the `UNM_Ameriflux_File_Maker.m` with the specified configuration options and output the new AmeriFlux files to "FLUXROOT/FluxOut/".

### Create soil "qc" and "qc_rbd" files

Running the [script_make_soilmet_qc.m](/scripts/script_make_soilmet_qc.m) script for a site/year runs [soil_met_correct.m](soil_met_correct.m), which assembles all soil temperature, water content, heat flux, and TCAV sensor outputs, applies temperature corrections to VWC, and then removes bad data. The two output files, which are placed in "processed_soil", are:

1. "qc" files (`{site}_{year}_soilmet_qc.txt`): Contains all sensor outputs, with raw outputs converted to VWC and temperature corrected (if applicable), for a site/year.

2. "qc_rbd" files (`{site}_{year}_soilmet_qc.txt`): Same as above, but with outliers, level shifts, and other bad data removed on a site/year basis (see [soil_met_correct.m](soil_met_correct.m) for details.
