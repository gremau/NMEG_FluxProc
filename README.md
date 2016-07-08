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

## Further documentation

Below is the old UNM New Mexico Elevation Gradient data processing manual,
by Timothy W. Hilton (hilton@unm.edu) from around July 2012. It is very
out of date. We will begin updating the documentation in the near future.

### OVERVIEW


This README presents Matlab functions we have developed to process and
view data collected from the New Mexico Elevation Gradient (NMEG) eddy
covariance sites and their associated data.

In general, user-level main functions (things that are intended to be
called from a Matlab command line) are named UNM_*.m, and helper
functions do not have the "UNM_" prefix.

#### Documentation

I have tried to consistently include in each m-file descriptive
documentation immediately following the function definition so that
calling 'help' or 'doc' on the function from the Matlab prompt will
display self-contained documentation.  Thus, this readme document will
not discuss function usage and interfaces in detail -- use the Matlab
help!


#### Source control management

The code is version-controlled in a Mercurial
(http://mercurial.selenic.com/) repository.  It is not necessary to
use the version control; you may simply ignore the .hg subdirectory,
or delete it to permanently disable version control.  There is a very
good tutorial at http://hginit.com/ if you are unfamiliar with
Mercurial (or source control management tools in general) and wish to
learn how to use it.  The revision history steps sequentially back to
15 August 2011.


### USER-LEVEL FUNCTION SUMMARY

There are four main user-level data processing matlab functions:

* UNM_retrieve_card_data_GUI.m
* UNM_RemoveBadData.m
* UNM_fill_met_gaps_from_nearby_site.m
* UNM_Ameriflux_file_maker_TWH.m

There are several functions to parse data files from various stages of
the data processing pipeline into Matlab:

* UNM_parse_QC_txt_file.m
* UNM_parse_QC_xls_file.m
* UNM_parse_fluxall_txt_file.m
* UNM_parse_fluxall_xls_file.m
* UNM_parse_gapfilled_partitioned_output.m
* UNM_parse_sev_met_data.m
* UNM_parse_valles_met_data.m
* parse_forgapfilling_file.m
* parse_ameriflux_file.m

There are also a number of functions to visualize flux data.  Some are
called from within the processing functions listed above; some of
these are sometimes independently useful.

* plot_fingerprint.m
* UNM_site_plot_doy_time_offsets.m
* UNM_site_plot_fullyear_time_offsets.m
* plot_siteyear_fingerprint_2x3array.m
* plot_siteyear_fingerprint_single.m


### DATA PROCESSING PIPELINE SUMMARY

The steps for processing incoming data from the field sites.  I have
attempted to make the processing routines somewhat robust to data
glitches: missing data, mangled text, mangled file names, etc.  There
is (as always) more work that could be done in that arena; for now, if
something breaks, the best bet is to step into the Matlab code and
debug.

1. Insert the datalogger flash card into the computer.  
2. Within Matlab, call UNM_retrieve_card_data_GUI.  This copies the
   data to disk and displays a figure that plots each 30-minute data
   field sequentially.  Step through each field and scan the plot to
   make sure it looks reasonable!  When done, close the plot figure.
   Matlab will now openCampbell Scientific's CardConvert to process
   the raw data into TOA5 files and daily TOB1 10-hz files, copy those
   files to their backup locations, compress the raw data, and copy
   the compressed and uncompressed raw data to their backup locations.
   The final step will require the user to manually enter a password
   to transfer the data to the EDAC FTP server.
3. Run UNM_RemoveBadData.  Scan the resulting plots for problems in
   the data and fix any problems that arise.
4. Run UNM_fill_met_gaps_from_nearby_site.
5. Send the SITE_YEAR_for_gapfilling_filled.txt through the online
   flux gapfiller/flux partitioner:
   http://www.bgc-jena.mpg.de/~MDIwork/eddyproc/upload.php.
6. From bash, call download_partitioned_data to download the gapfilled
   partitioned data.
7. Call UNM_Ameriflux_file_maker_TWH.m
8. Upload the Ameriflux files to soccoro.unm.edu.
