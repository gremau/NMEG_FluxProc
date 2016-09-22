# AncillaryMetData

This file contains instructions for downloading ancillary data used to fill
missing NMEG site meteorology data. Unless otherwise specified, this information
applies to the `FLUXROOT/Ancillary_met_data` directory, and new data files
should be put inside that directory.


## Valles Caldera met stations ( MCon and PPine )

There is a network of stations in the Valles that have been managed by different entities over the years. NPS staff now maintain the stations, but data are available through the Desert Research Institute (DRI) Western Regional Climate Center (WRCC).

All sites at VCNP can be seen here [here](http://www.wrcc.dri.edu/vallescaldera/). You can click on the site or...

Data for Jemez, the closest to PPine, can be accessed from:

<http://www.wrcc.dri.edu/cgi-bin/rawMAIN3.pl?nmxjem>

Data for Redondo, the closest to MCon, can be accessed from:

<http://www.wrcc.dri.edu/cgi-bin/rawMAIN3.pl?nmvrdd>

Data for VC Headquarters, can be accessed from:

<http://www.wrcc.dri.edu/cgi-bin/rawMAIN3.pl?nmvhvc>

From each page select "Data Lister" and fill in the form for dates/format desired (delimited format,short headers, metric units, etc). The password needed to download data is "wrcc14" (or wrcc15 for Jemez?). The headers have changed periodically, so after downloading all data (2006-present) the files have been broken down into periods with the same header. Original files are in the "raw_DRI_VC_files" directory, and this directory contains the doctored files. The "parse_valles_met_data.m" script should do a pretty good job of stitching these back together.

### NOTE

Data from some, but not all, of these VCNP met stations are also available in different format from the Sev LTER network. There was once a parser (see git history) for these files and in some ways they are a little easier to use. They can be found here:

<http://tierra.unm.edu:8080/research/climate/meteorology/VCNP/index>

using username:sevuser and password:mes4paje . In the past these same files were
at:

<http://sev.lternet.edu/research/climate/meteorology/VCNP/index.html>


## SNOTEL Stations ( MCon and PPine ) 

Can be navigated to from the interactive map at the [NRCS site](http://www.wcc.nrcs.usda.gov/snow/). Navigate to the desired site page where there is a data download interface. Select hourly or daily csv data from standard SNOTEL sensors for the desired calendar year (all days), then press the View Historic button. This should download a file with a 'XXX_STAND_YEAR=YYYY.csv' filename, where XXX is the site code and YYYY is the year. Save this in the 'SNOTEL_daily' or 'SNOTEL_hourly' directory as appropriate.

We currently use data from Quemazon (708), Senorita Divide #2 (744), and Vacas Locas (1017).


## Sevilleta sites (GLand, SLand, New_Gland)

We use the Sevilleta LTER met network to fill our sites there. These sites are managed by Doug Moore. There are several options for acquiring data.

    1. Contact Doug directly (dmoore@sevilleta.unm.edu)
    2. Raw data from all sites is posted periodically to the web at:

       http://sev.lternet.edu/research/climate/meteorology/SEV/outputXX.dat
       
       where XX is the year, OR 

       http://sev.lternet.edu/data (Meteorology data link)

    3. Get the raw wireless data from the socorro ftp server at:

       ftp://eddyflux@socorro.unm.edu/export/db/work/wireless/data/current/met


## Global Historical Climate Network data from NCDC (JSav)

GHCN data is available at <http://www.ncdc.noaa.gov/cdo-web/datasets>. Follow
the link to "Daily Summaries". Then select the time period, and search
for the sitename (ESTANCIA and PROGRESSO are near JSav and PJ sites). Once the
site is found add it to the cart and:

1. Select the desired format (Custom Daily CSV), adjust date range if needed
2. Select station metadata outputs (all - station name, location, flags) and set
   units to METRIC
3. Select data outputs (all - precip, temp, + all subcategories)
4. Enter email address and submit order

A link to the data will be sent via email. The raw datafile should be parseable
by MATLAB. Note that data outputs change over the years, so it may be wise to
always get data files for the entire period (2006/01/01-present)


## PRISM data

Daily PRISM data is downloaded as zipped archives of 1-day .bil files (a georeferenced data format). Yearly archives for the continental US can be downloaded [here](http://prism.oregonstate.edu/recent/). Note that PRISM data is provisional for 6 months. If desired, provisional data can be downloaded [here](http://prism.oregonstate.edu/6month/). Save the archives in the 'PRISM_daily/raw_bil' directory.

There are 2 python scripts and a configuration file needed to process the .bil
file archives into usable precip data. These can be found in [this
repository](http://github.com/gremau/NMEG_utils).

* `site_coords.txt` is a list of site names and lat/lon coordinates
* `bilParser.py` is defines a `BilFile` object with a method to extract a data value at a given coordinate location. It also defines some functions to extract data from particular types of bilFiles (monthly, provisional, etc)
* `getPRISMdata.py` is the master script. It sets needed parameters and then
* makes calls to the `bilParser` functions (and by extension, `BilFile` methods) to extract data for each day, year, and site, and then outputs a csv for each year.

I use the anaconda python distribution and run getPRISMdata.py with ipython, but other python distributions that include numPy, pandas, and matplotlib should work. In addition to python, [OsGeo GDAL](http://www.gdal.org/) and its python bindings need to be installed. Decent instructions for this can be found [here](http://pythongisandstuff.wordpress.com/2011/07/07/installing-gdal-and-ogr-for-python-on-windows/). For the Sandia lab computer, this has all been done.


## DayMet data

DayMet has its own single pixel extractor program (daymet_multiple_extraction.jar) that can be downloaded [here](http://daymet.ornl.gov/singlepixel.html). This currently resides in the 'DayMet' directory. 

* Sites to be extracted should be added to latlon.txt.
* Open a terminal in this directory and run `./daymet_multiple_extraction.sh`

Currently Daymet only seems to be available through 2013



