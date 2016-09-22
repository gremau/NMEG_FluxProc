# NMEG Data Releases

Data collection and quality assurance is ongoing, but QA'd data files must
periodically be "released" for submission to AmeriFlux or other collaborators.
Recently we have begun a release system in which a version of NMEG data files
is created with an associated git tag in the repository. These verisoned files
can then be submitted, and if needed, releases can be sub-versioned to fix
issues until the next release.

## Current releases

Unless otherwise noted, associated git tags with the same name will be found on
the master branch of NMEG_FluxProc

* **FLUXNET2015_a** removed the Litvak lab USTAR threshold filter from FC, H, 
  and LE, so that output data were more representative of the raw flux (rather
  than NEE or similar). In gapfilled files, a USTAR filter was applied to FC_F,
  by the MPI Eddyproc tool prior to gapfilling  (Reichstein 2005 method).

  - Note that the nighttime filter problem (USTAR filtering at night) was fixed,
    and this git tag was moved to reflect that.


* **FLUXNET2015** This release accumulates all QA improvements made by Greg (and
  some others) from 2014-2016, including calibration changes, timing shifts,
  relaxing filters, improved ancillary met gapfilling, etc. This release
  maintains the Litvak lab USTAR filtering thresholds, and no additional USTAR
  filters were applied during gapfilling.

## Upcoming release changes to be aware of

* The next release removes an incorrect 30 minute shift so that timestamps
  fall at the end of each 30 minute averaging period (as stamped by the
  datalogger). In prior releases timestamps signify the start of the averaging
  period. AmeriFlux will need to be notified of this.

