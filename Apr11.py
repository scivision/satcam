#!/usr/bin/env python
"""
particular test scenario
"""
from datetime import datetime,timedelta
from pytz import UTC
from numpy import radians, degrees
from astropy.coordinates.angle_utilities import angular_separation
#
from iridium import iridium_ncdf, iridium_tle, optical,plots
from histutils.findnearest import findClosestAzel
#%% scenario parameters
ncfn='~/iridium/20130411Amp_invert.ncdf'
tlefn='../satcam-data/stkAllComm_2013-04-10.tle'
t0=datetime(2013,4,11,10,45,29,288864,tzinfo=UTC)
tlim=(datetime(2013,4,11,10,45,tzinfo=UTC),
      datetime(2013,4,11,10,46,tzinfo=UTC))
sitella=(65.12657, -147.496908333, 208)
svn=27372
ellim=(73,82)
# optical
vidfn = '~/data/2013-04-11/HST/2013-04-11T07-00-CamSer1387_frames_403709-1-405509.DMCdata'
calfn = '~/code/histfeas/precompute/hst1cal.h5'
tstart=datetime(2013,4,11,7,0,8,tzinfo=UTC)
fps=30
terror_sec = 6
#%% run scenario
date = datetime(t0.year,t0.month,t0.day,tzinfo=UTC)
# ncdf
ecef,lla,aer,eci = iridium_ncdf(ncfn,date,tlim,ellim,sitella)
# TLE
eceftle,llatle,aertle = iridium_tle(tlefn,lla.index,sitella,svn)

angdist = degrees(angular_separation(radians(aer['az'].values),radians(aer['el'].values),
                                     radians(aertle['az'].astype(float)),radians(aertle['el'].astype(float))))
# optical
tstart = tstart + timedelta(seconds=terror_sec)
data, az,el = optical(vidfn,calfn,lla.index,tstart,fps)
nr,nc = findClosestAzel(az,el,aer['az'],aer['el'])

plots(lla,llatle,data)
