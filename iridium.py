#!/usr/bin/env python3
from __future__ import division
from six import integer_types
from pathlib2 import Path
from netCDF4 import Dataset
import matplotlib.pyplot as plt
from datetime import timedelta
from dateutil.parser import parse
from pytz import UTC
from numpy import s_,diff,nonzero,unique,int64,array
#
from pymap3d.coordconv3d import eci2geodetic

def iridiumread(fn,day,tlim):
    fn = Path(fn).expanduser()
#%% get all sats psuedo SV number
    with Dataset(str(fn),'r') as f:
        #psv_border = nonzero(diff(f['pseudo_sv_num'])!=0)[0] #didn't work because of consequtively reused psv #unique doesn't work because psv's can be recycled
        psv_border = nonzero(diff(f['time'])<0)[0] + 1 #note unequal number of samples per satellite, +1 for how diff() is defined
#%% iterate over psv, but remember different number of time samples for each sv.
# since we are only interested in one satellite at a time, why not just iterate one by one, throwing away uninteresting results
# qualified by crossing of FOV.

#%% find times in file
    days=[day+timedelta(days=i) for i in range(len(newdayind))]
    todayind = s_[:newdayind] #FIXME just for first day for now
    #just one SV in this file?
    pseudosv = unique(psv[todayind])[0]
    assert isinstance(pseudosv,(integer_types,int64))

#%% time filtering
    dtday = day.astimezone(UTC)
    t = array([dtday + relativedelta(hours=h) for h in time]) #TODO: need to roll day over for each 24-hour period!
    if tlim:
        t = t[(tlim[0] <= t) & (t <= tlim[1])]
    ut1_unix = [d.timestamp() for d in t]

#%% read rest of data
    with Dataset(str(fn),'r') as f:
        eci = f['pos_eci'][ind,:]
        psv = f['pseudo_sv_num'][ind].astype(int)

#%%
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
    ax.plot(ut1_unix)
    ax.set_ylabel('POSIX timestamp [sec]')
    ax.set_xlabel('index #')


    plt.show()

if __name__ == '__main__':
    from argparse import ArgumentParser
    p = ArgumentParser(description='load and plot position data')
    p.add_argument('file',help='file to process')
    p.add_argument('date',help='date to process yyyy-mm-dd')
    p.add_argument('-l','--tlim',help='start stop time',nargs=2)
    p = p.parse_args()

    if p.tlim:
        tlim = (parse(p.tlim[0]), parse(p.tlim[1]))
    else:
        tlim = None

    iridiumread(p.file,parse(p.date+'T00Z'),tlim)
