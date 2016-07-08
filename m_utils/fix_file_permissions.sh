#!/bin/sh

# this script fixes file permissions problems that occasionally crop
# up on Jemez.  It operates on all files and directories under the
# top-level directory C:\Research_Flux_Towers, and performs these tasks:
#
# sets ownship to LitvakLabUser
# sets group to None
# enables read/write permissions for all users for all files
# enables read/write/execute permissions for all users for all directories
#
# author: Timothy W. Hilton, UNM, Aug 2013

export FLUXROOT=/cygdrive/c/Research_Flux_Towers
export FLUXDATA=/cygdrive/c/Research_Flux_Towers/SiteData

# set the owner to LitvakLabUser and the group to None for everything under FLUXROOT
chown -Rv LitvakLabUser:None $FLUXROOT/*

# give all users read/write permissions for all files
find $FLUXROOT  -type f -exec chmod -Rv a+rw {} \;
# give all users read/write/execute permissions for all directories
find $FLUXROOT  -type d  -exec chmod -Rv a+rwx {} \;
