# Installation and configuration

The source code can be downloaded from [the GitHub repository](https://github.com/gremau/NMEG_FluxProc). MATLAB should be installed, and some tasks will requre cygwin (for the bash shell), Campbell Scientific's CardConvert utility, and R tobe installed and on the path.


## Local machine setup

### Data and configuration directories

NMEG_Fluxproc scripts and functions reqire access to a local data 
directory (`FLUXROOT`) and a configuration file directory (`FluxProcConfig`).
On the local machine, MATLAB must be able to find these two directories.

#### FLUXROOT

The NMEG_FluxProc scripts and functions performs operations on data in a
designated path (termed `FLUXROOT`). An example FLUXROOT directory with data
from an imaginary site can be downloaded from the socorro ftp and used to
test the NMEG_FluxProc code.

#### FluxProcConfig

Site specific configuration files must also be present in the `FLUXROOT`
path, and NMEG_FluxProc is currently set to look for them in
`FLUXROOT/FluxProcConfig`. Configuration files for NMEG sites, including
the test site mentioned above can be found [here]
(https://github.com/gremau/NMEG_FluxProcConfig).

### Paths and environment variables.

An environment variable must be set for MATLAB to find the FLUXROOT
(and FluxProcConfig) directory on the local machine's file structure. In your
`startup.m` file, add these lines:

    setenv('FLUXROOT', '/.../')

where "/.../" is the path to the FLUXROOT directory. This will add the
needed environment variable each time you start MATLAB.

Once this is done, start MATLAB, add the NMEG_FluxProc to your path:

    addpath('path/to/FluxProc')

Enter the directory:

    cd 'path/to/FluxProc'

The rest of the paths needed for FluxProc can be set using

    fluxproc_setpaths

Now NMEG_FluxProc code should be initialized and ready to use the data and
configuration files in the FLUXROOT directory.
