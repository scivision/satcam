#!/usr/bin/env python3
from pathlib2 import Path
from netCDF4 import Dataset
import matplotlib.pyplot as plt
from dateutil.relativedelta import relativedelta
from dateutil.parser import parse
#
from pymap3d.coordconv3d import eci2geodetic

def iridiumread(fn,day):
    fn = Path(fn).expanduser()
    with Dataset(str(fn),'r') as f:
        time = f.variables['time'][:25000].astype(float)
        eci = f.variables['pos_eci'][:25000]
    '''
    https://github.com/dinkelk/astrodynamics/blob/master/ECI2ECEF.m
    '''

    t = [parse(day) + relativedelta(hours=h) for h in time]
    print(t[0].strftime('%Y-%m-%dT%H:%M:%S'))
    print(t[-1].strftime('%Y-%m-%dT%H:%M:%S'))
    lat,lon,alt = eci2geodetic(eci,t)

    ax = plt.figure().gca()
    ax.plot(lon,lat)#,marker='.')
    ax.set_ylabel('lat')
    ax.set_xlabel('long')
    ax.set_title('WGS84 vs. time')
    ax.set_ylim((-90,90))
    ax.set_xlim((-180,180))
    ax.grid(True)

    ax = plt.figure().gca()
    ax.plot(t,alt/1e3)
    ax.set_ylabel('altitude [km]')
    ax.set_xlabel('time')

    ax= plt.figure().gca()
    ax.plot([d.timestamp() for d in t])
    ax.set_ylabel('POSIX timestamp [sec]')
    #TODO WHY does the time seem to keep repeating?


    plt.show()

if __name__ == '__main__':
    from argparse import ArgumentParser
    p = ArgumentParser(description='load and plot position data')
    p.add_argument('file',help='file to process')
    p.add_argument('date',help='date to process yyyy-mm-dd')
    p = p.parse_args()

    iridiumread(p.file,p.date)
