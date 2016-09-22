# Secondary Data Loggers

Notes on using data from secondary dataloggers at sites that have them.
Sometimes the data from these secondary loggers requires tricks to find,
convert, or otherwise get into the workflow of the rest of this processing
code. Unless otherwise noted, data and other information for these loggers can
be found in `FLUXROOT/SiteData/{SiteName}/secondary_loggers/`.

Some of these might be a tad out of date (filesystem changes).


## JSav

There was a secondary datalogger here, and its TOA5 files are in
`secondary_loggers'. They are successfully read and appended to the fluxall
files by the NMEG_FluxProc code.


## MCon

### Precipitation station

Raw files archived in `secondary_loggers/precip/`, but there is currently no
procedure to load, convert, and concatenate them into fluxall files.

### SAHRA datalogger

#### Raw data file

The most current data file from the SAHRA station located at our MCon site is `MCon_SAHRA_data_20061001_20130601.dat`. This should contain all data that the station collected. If needed, these data are available from:

<http://www.wrcc.dri.edu/cgi-bin/rawMAIN.pl?nmvcnx>
(Main top-level URL: <http://www.wrcc.dri.edu/index.html> )

The password for data older than 30 days is wrcc14.  The .dat files included in this directory were downloaded in delimited (Win/PC) format.  

Depending on your selections when exporting files from the website, there may be some HTML at the beginning and end of the file. Be sure to strip this out first.

#### Converting raw HydraProbe voltages

The soil sensors are Steven's HydraProbes. An observation from this sensor consists of 4 voltages and there are proprietary programs that convert these voltages to SWC, Tsoil, and other values. Program for converting individual observations and time-series files (`Hydra.exe` and `Hyd_file.exe`) can be downloaded from:

<http://www.stevenswater.com/software/downloads.aspx#Hydra>

Data from HydraProbe sensors must be run through `Hyde_file.exe` in a specific file format. The functions associated with the `parse_MCon_SAHRA_data.m` function in the main MATLAB pipeline should be able to create a good input file for `Hyd_file.exe` from the raw SAHRA data file.


## MCon_SS

### Precipitation station

Raw files archived in `secondary_loggers/precip/`, but there is currently no
procedure to load, convert, and concatenate them into fluxall files.

### Soil station

Raw files archived in `secondary_loggers/soil/`, and they are successfully read and appended to the fluxall files by the NMEG_FluxProc code.

### Sapflow station

Raw files archived in `secondary_loggers/sap/`, but there is currently no
procedure to load, convert, and concatenate them into fluxall files (I think
they are on 15min frequency).

## PJ

### Current soil_sap cr23x data

This data is archived in `secondary_loggers/soil_sap/` and is read by the MATLAB
code and appended into fluxall files after header changes are resolved.

### Morillas compilations from 2009-2013

These have filenames like: `cr23x_PJ_2009_01_01_0030_compilation.dat`

2009-2013 compilations are currently based on the compilations by Laura
Morillas. The original compilations used can be found in 
`soil_sap/LM_CR23xCompilations_orig/` and there are backup copies on the
socorro ftp server in the "Laura M" directory.

A couple of changes have been made to these to make them work with the header
resolution system in the processing code:

1. In some cases header names have been edited to be more usable
2. The filename has been standardized.
3. Filename includes a date so header change timing is parsed by matlab code

### Morillas QCd compilations from 2009-2013

2009-2013 QCd soil data are currently based on work of Laura
Morillas. The qc'd compilations used can be found in 
`soil_sap/LM_CR23xCompilations_qc/` and there are backup copies on the
socorro ftp server in the "Tower_sites/PJ/Data" directory

### Recent files (2014 forward)

These are simple compilations of the raw datalogger files that are appended to
as new data is retrieved by Jonathan. New data should be retrieved from
socorro at:

`/export/db/work/eddyflux/Tower sites/Tower Sites/PJ/PJ/Data/PJ_CR23X_Data`

and can then be appended to an existing file, or a new file can be created by
pasting headers into the raw datalogger file. Older datalogger files are in the
`PJC_23X_YEAR/` directories.

### "Soil Complete" files

These can be made using the `mirror_PJ_soil_to_local` bash script in the
`secondary_loggers` directory. The last time I tried this it didn't work
particularly well, perhaps due to header changes. According to Tim's former
documentation:

    The bash script `mirror_PJ_soil_to_local` mirrors the data in 
    `socorro.unm.edu:/export/db/work/eddyflux/Tower sites/Tower Sites/PJ/PJ/Data/PJ_CR23X_Data`
    to this directory.

    It then concatenates all the data files together and removes malformatted lines, creating `PJ_YYYY_soil_complete.dat`.

    The matlab code that creates the soil Ameriflux files looks in this directory for `PJ_YYYY_soil_complete.dat`.

    So, to update PJ soil data:

    1. run `mirror_PJ_soil_to_local` 
    2. process the soil data as usual in Matlab.

### Other compilations (`other_compilations`)

Assorted random compilations of cr23x data (including "soil complete" compilations) that have been used in the past. Haven't really looked at all of these very thorougly yet.


## PJ_girdle

### Current cr23x data

This data is archived in `secondary_loggers/soil_sap/` and is read by the MATLAB code and appended into fluxall files after header changes are resolved.

### Morillas compilations from 2009-2013

These have filenames like: `cr23x_PJ_girdle_2009_01_01_0030_compilation.dat`

2009-2013 compilations are currently based on the compilations by Laura
Morillas. The original compilations used can be found in 
`cr23x_files/LM_CR23xCompilations_orig/` and there are backup copies on the
socorro ftp server in the "Laura M" directory.

A couple of changes have been made to these to make them work with the header
resolution system in the processing code:

1. In some cases header names have been edited to be more usable
2. The filename has been standardized.
3. Filename includes a date so header change timing is parsed by matlab code

### Morillas QCd compilations from 2009-2013

2009-2013 QCd soil data are currently based on work of Laura
Morillas. The qc'd compilations used can be found in 
`cr23x_files/LM_CR23xCompilations_qc/` and there are backup copies on the
socorro ftp server in the "Tower_sites/PJ_girdle/Data" directory.
 
### Recent files (2014 forward)

These are simple compilations of the raw datalogger files that are appended to
as new data is retrieved by Jonathan. New data should be retrieved from
socorro at:

`/export/db/work/eddyflux/Tower sites/Tower Sites/PJ/PJ_girdle/Data/PJ_girdle_ CR23X_Data`

and can then be appended to an existing file, or a new file can be created by
pasting headers into the raw datalogger file. Older datalogger files are in the
`PJG_23X_YEAR/` directories.

### "Soil Complete" files

These can be made using the `mirror_PJ_soil_to_local` bash script in the PJ
Control directory. The last time I tried this it didn't work particularly well, perhaps due to header changes. According to Tim's former documentation:

    The bash script `mirror_PJ_soil_to_local` mirrors the data in 
    `socorro.unm.edu:/export/db/work/eddyflux/Tower sites/Tower Sites/PJ/PJ/Data/PJ_CR23X_Data`
    to this directory.

    It then concatenates all the data files together and removes malformatted lines, creating `PJ_YYYY_soil_complete.dat`.

    The matlab code that creates the soil Ameriflux files looks in this directory for `PJ_YYYY_soil_complete.dat`.

    So, to update PJ soil data:

    1. run `mirror_PJ_soil_to_local` 
    2. process the soil data as usual in Matlab.

### Other compilations (`other_compilations`)

Assorted random compilations of cr23x data (including "soil complete" compilations) that have been used in the past. Haven't really looked at all of these very thorougly yet.


## PPine

### DRI logger

in `secondary_loggers/DRI_logger/`

The zip archive `PPine_2008_2012_raw_soil_data.zip` contains all known PPine soil data files provided by the DRI team that (formerly?) ran the soil station at the site.

To the best of my knowledge, this system has four soil profiles with Steven's
HydraProbe sensors at 5", 20", and 50" (a total of 12 T/VWC measurements).

The data span 1 Jan 2008 to early 2015. These data have been concatenated into a file called `PPine_soil_data_20080101_20150128.dat`.   The concatenation was performed in Matlab using the code in `concatenate_all_PPine_soil_data.m`, a copy of which lives in this zip archive. There is also a version of this file that is run from the main MATLAB pipeline (same name).

See matlab documentation for `concatenate_all_PPine_soil_data` for more
extensive usage instructions.

The `PPine_soil_data_20080101_20150128.dat` can be parsed by the `parse_PPine_soil_data.m` function.


#### archive/

In the `archive` directory there are also some soil data files that may or may not be of interest.

