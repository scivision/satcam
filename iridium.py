#!/usr/bin/env python3
from __future__ import division
from pathlib2 import Path
from netCDF4 import Dataset
import matplotlib.pyplot as plt
from dateutil.parser import parse
from datetime import timedelta
from pytz import UTC
from numpy import arange,diff,nonzero,array
#
from pymap3d.coordconv3d import eci2aer,eci2geodetic

def iridiumread(fn,day,tlim,ellim,sitella):
    fn = Path(fn).expanduser()
    day = day.astimezone(UTC)
#%% get all sats psuedo SV number
    with Dataset(str(fn),'r') as f:
        #psv_border = nonzero(diff(f['pseudo_sv_num'])!=0)[0] #didn't work because of consequtively reused psv #unique doesn't work because psv's can be recycled
        psv_border = nonzero(diff(f['time'])<0)[0] + 1 #note unequal number of samples per satellite, +1 for how diff() is defined
#%% iterate over psv, but remember different number of time samples for each sv.
# since we are only interested in one satellite at a time, why not just iterate one by one, throwing away uninteresting results
# qualified by crossing of FOV.

#%% consider only satellites above az,el limits for this location
        lind = [0,0] #init
        for i in psv_border:
            lind = [lind[1],i]
            cind = arange(lind[0],lind[1]-1,dtype=int) # all times for this SV
            #now handle times for this SV
            t = array([day + timedelta(hours=h) for h in f['time'][cind].astype(float)])
            if tlim:
                mask = (tlim[0] <= t) & (t <= tlim[1])
                t = t[mask]
                cind = cind[mask]
            #now filter by az,el criteria
            az,el,r = eci2aer(f['pos_eci'][cind,:],sitella[0],sitella[1],sitella[2],t)
            if ((ellim[0] <= el) & (el <= ellim[1])).any():
                print('sat psv {}'.format(f['pseudo_sv_num'][i]))
                lat,lon,alt = eci2geodetic(f['pos_eci'][cind,:],t)

#%%
    print(t[0].strftime('%Y-%m-%dT%H:%M:%S'))
    print(t[-1].strftime('%Y-%m-%dT%H:%M:%S'))
    if lon.size<200:
        marker='.'
    else:
        marker=None

    ax = plt.figure().gca()
    ax.plot(lon,lat,marker=marker)
    ax.set_ylabel('lat')
    ax.set_xlabel('long')
    ax.set_title('WGS84 vs. time')
#    ax.set_ylim((-90,90))
#    ax.set_xlim((-180,180))
    ax.grid(True)

    ax = plt.figure().gca()
    ax.plot(t,alt/1e3,marker=marker)
    ax.set_ylabel('altitude [km]')
    ax.set_xlabel('time')

    plt.show()

if __name__ == '__main__':
    from argparse import ArgumentParser
    p = ArgumentParser(description='load and plot position data')
    p.add_argument('file',help='file to process')
    p.add_argument('date',help='date to process yyyy-mm-dd')
    p.add_argument('-l','--tlim',help='start stop time',nargs=2)
    p.add_argument('-e','--ellim',help='el limits [deg]',nargs=2,type=float)
    p.add_argument('-c','--lla',help='lat,lon,alt of site [deg,deg,meters]',nargs=3,type=float)
    p = p.parse_args()

    if p.tlim:
        tlim = (parse(p.tlim[0]), parse(p.tlim[1]))
    else:
        tlim = None

    iridiumread(p.file,parse(p.date+'T00Z'),tlim,p.ellim,p.lla)
