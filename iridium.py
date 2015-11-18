#!/usr/bin/env python3
#from scipy.io import netcdf No, can't handle netcdf4 only 3
import sys
from pymap3d.coordconv3d import ecef2geodetic,eci2ecef,ecef2eci
from astrometry_azel.datetime2hourangle import datetime2sidereal
from netCDF4 import Dataset
import matplotlib.pyplot as plt
from dateutil.relativedelta import relativedelta
from dateutil.parser import parse

def iridumread(fn,day):
    with Dataset(fn,'r') as f:
        time = f.variables['time'][:25000].astype(float)
        eci = f.variables['pos_eci'][:25000]
    '''
    https://github.com/dinkelk/astrodynamics/blob/master/ECI2ECEF.m
    '''

    dtime = [parse(day) + relativedelta(hours=h) for h in time]
    print(dtime[0].strftime('%Y-%m-%dT%H:%M:%S'))
    print(dtime[-1].strftime('%Y-%m-%dT%H:%M:%S'))
    lst = datetime2sidereal(dtime)
    ecef = eci2ecef(eci,lst)
    lat,lon,alt = ecef2geodetic(ecef)

    ax = plt.figure().gca()
    ax.plot(lon,lat)#,marker='.')
    ax.set_ylabel('lat')
    ax.set_xlabel('long')
    ax.set_title('WGS84 vs. time')
    ax.set_ylim((-90,90))
    ax.set_xlim((-180,180))
    ax.grid(True)

    ax = plt.figure().gca()
    ax.plot(dtime,alt/1e3)
    ax.set_ylabel('altitude [km]')
    ax.set_xlabel('time')

    ax= plt.figure().gca()
    ax.plot([d.timestamp() for d in dtime])
    ax.set_ylabel('POSIX timestamp [sec]')
    print(' WHY does the time seem to keep repeating?')


    plt.show()

if __name__ == '__main__':
    from numpy import isclose
    from sys import argv
    iridumread(argv[1],argv[2])

    ecef = [5e6,2e6,3e6]
    lst = datetime2sidereal(parse('2013-04-14'))
    eci = ecef2eci(ecef,lst)
    ecefhat = eci2ecef(eci,lst)

    assert isclose(ecef, ecefhat).all()

