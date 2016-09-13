# NMEG_FluxProc

[This](https://github.com/gremau/NMEG_FluxProc) is the repository for
FluxProc code used to process data from the New Mexico Elevation Gradient.
It is primarily written in and called from MATLAB.


## Local setup

### Data and configuration directories

The FluxProc code performs operations on data in a designated directory
("FLUXROOT"). An example FLUXROOT directory with data from an imaginary
site can be downloaded from the socorro ftp and used to test the FluxProc
code.

Site specific configuration files must also be present in the FLUXROOT
path, and FluxProc is currently set to look for them in
"FLUXROOT/FluxProcConfig". Configuration files for NMEG sites, including
the test site mentioned above can be found [here]
(https://github.com/gremau/NMEG_FluxProcConfig).

### Paths and environment variables.

An environment variable must be set for FluxProc to find the FLUXROOT
directory on the local file structure. In your `startup.m` file, add
these lines:

    setenv('FLUXROOT', '/.../')

where "/.../" is the path to the FLUXROOT directory. This will add the
needed environment variable each time you start MATLAB.

Once this is done, start MATLAB, add the NMEG_FluxProc to your path:

    addpath('path/to/FluxProc')

Enter the directory:

    cd 'path/to/FluxProc'

The rest of the paths needed for FluxProc can be set using

    fluxproc_setpaths

Now FluxProc code should be initialized and ready to use the data and
configuration files in the FLUXROOT directory.


## Task scripts

Common tasks have scripts that can be run with common configurations, and are easily modified. These scripts can be found in the [scripts](https://github.com/gremau/NMEG_FluxProc/scripts/) directory. Each of these scripts can be set to run for a list of sites and years and to overwrite existing output files or not.

### Create new "fluxall" files

Fluxall files ({site}_{year}_fluxall.txt') should contain raw data from all sensors at a site for one year. The [script_make_fluxall.m](https://github.com/gremau/NMEG_FluxProc/scripts/script_make_fluxall.m) script will make these files, primarily by calling `card_data_processor.m` in various configurations and reading the raw data in 'toa5' and 'ts_data' directories. Though these files should contain all sensor data, in practice there are some sites with dataloggers that have not been configured to be merged into the fluxall file (namely the Valles Caldera sites).

### Create new "qc", "for_gapfilling", and "for_gapfilling_filled" files

There are several files created from the NMEG quality control pipeline, all output to the "processed_flux" directory. These are:

1. qc files ({site}_{years}_fluxall_qc.txt): Contain all variables that are quality-controlled and then output by the `RemoveBadData.m` script.

2. for_gapfilling files ({site}_flux_all_{year}_for_gap_filling.txt): Also output by `RemoveBadData.m` script and contain a subset of quality-controlled variables in a format ready to be filled with ancillary met data.

3. for_gapfilling_filled files ({site}_flux_all_{year}_for_gap_filling_filled.txt): Same as the file above, but gaps in the met variables have been filled with ancillary met data by the `UNM_fill_met_gaps_from_nearby_site.m` script.

To make these files, run the [script_make_qc_gf.m](https://github.com/gremau/NMEG_FluxProc/scripts/script_make_qc_gf.m). This script may also run the REddyProc gapfilling tool by calling on the [R code from the Max Planck institute](https://www.bgc-jena.mpg.de/bgi/index.php/Services/REddyProcWebRPackage), and the output (also in 'processed_flux') can be used to make AmeriFlux files, below, if desired.

### Create new AmeriFlux files

AmeriFlux files ({af-site}_{year}_gapfilled.txt and {af-site}_{year}_with_gaps.txt) contain quality controlled sensor data, gapfilled met data, gapfilled fluxes, and partitioned C fluxes. There are several steps currently needed to create them.

1. Send the 'for_gapfilling_filled' file for each site/year to the [MPI EddyProc web service](http://www.bgc-jena.mpg.de/~MDIwork/eddyproc/upload.php). This service provides gapfilled and partitioned flux data, and is the way we currently have to get Lasslop partitioned fluxes used for the lower elevation NMEG sites.

2. Once you receive notification that the partitioner has finished (by email), copy the job number and run `download_gapfilled_partitioned_flux(job#)`. This will download the resulting files to the 'processed_flux' directory.

3. Run [script_make_ameriflux.m](https://github.com/gremau/NMEG_FluxProc/scripts/script_make_ameriflux.m), which will call the `UNM_Ameriflux_File_Maker.m` with the specified configuration options and output the new AmeriFlux files to 'FLUXROOT/FluxOut/'.


## Additional documentation (in doc/)

* [The old README](/doc/old_README.md)
