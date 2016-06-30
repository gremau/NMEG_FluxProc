# NMEG_FluxProc

This is the repository for code used to process data from the New Mexico
Elevation Gradient.


## To use:

This code is primarily written in and called from MATLAB and it performs
operations on data in a designated directory ("FLUXROOT"). A testing
directory with example data from an imaginary test site can be found on
the socorro ftp.

Site specific configuration files must also be present in a designated
directory ("FLUXROOT/FluxProcConfig"). Configuration files for NMEG can be found
[here](https://github.com/gremau/NMEG_FluxProcConfig).

An environment variables must be set for MATLAB to find the data and
configuration files on the local file structure. In the `startup.m` 
file, add these lines:

    setenv('FLUXROOT', '/.../')

where "/.../" is the path to each folder.

FUTURE WARNING: Configuration files will soon be placed in an independent
location with a separate environmental variable. This will allow separation
of data and software configuration.

