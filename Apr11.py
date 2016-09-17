#!/usr/bin/env python
"""
particular test scenario
"""
from datetime import datetime
from pytz import UTC
from numpy import radians, degrees
from astropy.coordinates.angle_utilities import angular_separation
#
from satcam import iridium_ncdf, iridium_tle
from satcam.io import optical
from satcam.plots import plots
from histutils.findnearest import findClosestAzel

def fovcross(ncfn,tlefn,svn,vidfn,calfn,t0,tlim):
    """
    t0 is time of interest (intersection)
    tlim is time range to plot
    """
#%% optical
    terror_cam = 6 #sec
    img,tcam,llacam, azcam,elcam = optical(vidfn, calfn, t0, terror_cam)
#%% run scenario
    date = datetime(t0.year,t0.month,t0.day,tzinfo=UTC)

    ecef,lla,aer,eci = iridium_ncdf(ncfn,date,tlim,ellim,llacam)

    eceftle,llatle,aertle = iridium_tle(tlefn,lla.index,llacam,svn)

    angdist = degrees(angular_separation(radians(aer['az'].values),
                                         radians(aer['el'].values),
                                         radians(aertle['az'].astype(float)),
                                         radians(aertle['el'].astype(float))))

    nr,nc = findClosestAzel(azcam,elcam,
                            aer['az'].values, aer['el'].values)
#%%
    plots(lla,llatle,img,nr,nc)

if __name__ == '__main__':
    ncfn='~/iridium/20130411Amp_invert.ncdf'
    tlefn='../satcam-data/stkAllComm_2013-04-10.tle'

    t0=datetime(2013,4,11,10,45,29,288864,tzinfo=UTC)

    tlim=(datetime(2013,4,11,10,45,tzinfo=UTC),
          datetime(2013,4,11,10,46,tzinfo=UTC))

    svn=27372
    ellim=(73,82)
#%% optical
    vidfn = '~/data/2013-04-11/hst/2013-04-11T1044_hst1.h5'
    calfn = '~/code/histfeas/precompute/hst1cal.h5'

    fovcross(ncfn,tlefn,svn,vidfn,calfn,t0,tlim)