#!/usr/bin/env python3
from __future__ import division
from six import integer_types,string_types
from pathlib2 import Path
from ephem import readtle,Observer
from netCDF4 import Dataset
import matplotlib.pyplot as plt
from dateutil.parser import parse
from datetime import timedelta,datetime
from pytz import UTC
from numpy import arange,diff,nonzero,array,column_stack,degrees
from pandas import DataFrame
#
from pymap3d.coordconv3d import eci2aer,eci2geodetic,eci2ecef,geodetic2ecef

def iridium_ncdf(fn,day,tlim,ellim,sitella):
    assert isinstance(fn,(string_types,Path)),'must specify filename to load'
    assert len(ellim) == 2,'must specify elevation limits'
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
#TODO assumes only one satellite meets elevation and time criteria
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
            if ellim and ((ellim[0] <= el) & (el <= ellim[1])).any():
                print(t)
                print('sat psv {}'.format(f['pseudo_sv_num'][i]))
                eci = f['pos_eci'][cind,:]
                lat,lon,alt = eci2geodetic(eci,t)
                x,y,z = eci2ecef(eci,t)
                print('ecef {} {} {}'.format(x,y,z))

                ecef = DataFrame(index=t,columns=['x','y','z'],data=column_stack((x,y,z)))
                lla  = DataFrame(index=t,columns=['lat','lon','alt'],data=column_stack((lat,lon,alt)))
                return ecef,lla

    return (None,None)

def iridium_tle(fn,T,sitella,svn):
    assert isinstance(svn,integer_types)
    assert len(sitella)==3
    assert isinstance(T[0],datetime),'parse your date'

    fn = Path(fn).expanduser()
#%% read tle
    with fn.open('r') as f:
        for l1 in f:
            if int(l1[2:7]) == svn:
                l2 = f.readline()
                break
    sat = readtle('n/a',l1,l2)
#%% comp sat position
    obs = Observer()
    obs.lat = str(sitella[0]); obs.lon = str(sitella[1]); obs.elevation=float(sitella[2])

    ecef = DataFrame(index=T,columns=['x','y','z'])
    lla  = DataFrame(index=T,columns=['lat','lon','alt'])
    for t in T:
        obs.date = t
        sat.compute(obs)
        lat,lon,alt = degrees(sat.sublat), degrees(sat.sublong), sat.elevation
        az,el,srng = degrees(sat.az), degrees(sat.alt), sat.range
        x,y,z = geodetic2ecef(lat,lon,alt)
        ecef.loc[t,:] = column_stack((x,y,z))
        lla.loc[t,:]  = column_stack((lat,lon,alt))

    return ecef,lla
#%% plots

def plots(lla,llatle):
    if not isinstance(lla,DataFrame):
        return

    if lla.shape[0]<200:
        marker='.'
    else:
        marker=None

    ax = plt.figure().gca()
    ax.plot(lla['lon'],lla['lat'],color='b',marker=marker,label='nc')
    ax.plot(llatle['lon'],llatle['lat'],color='r',marker=marker,label='tle')
    ax.set_ylabel('lat')
    ax.set_xlabel('long')
    ax.set_title('WGS84 vs. time')
#    ax.set_ylim((-90,90))
#    ax.set_xlim((-180,180))
    ax.grid(True)

    ax = plt.figure().gca()
    ax.plot(lla.index,lla['alt']/1e3,marker=marker)
    ax.set_ylabel('altitude [km]')
    ax.set_xlabel('time')

    plt.show()


if __name__ == '__main__':
    from argparse import ArgumentParser
    p = ArgumentParser(description='load and plot position data')
    p.add_argument('--ncfn',help='.ncdf file to process')
    p.add_argument('--tlefn',help='.tle file to process')
    p.add_argument('-t','--date',help='date to process yyyy-mm-dd')
    p.add_argument('-l','--tlim',help='start stop time',nargs=2)
    p.add_argument('-e','--ellim',help='el limits [deg]',nargs=2,type=float)
    p.add_argument('-c','--lla',help='lat,lon,alt of site [deg,deg,meters]',nargs=3,type=float)
    p.add_argument('-s','--svn',help='TLE number of satellite (5 digit int)',type=int)
    p = p.parse_args()

    if p.tlim:
        tlim = (parse(p.tlim[0]), parse(p.tlim[1]))
    else:
        tlim = None

    t0 = parse(p.date)
    date = datetime(t0.year,t0.month,t0.day,tzinfo=UTC)

    ecef,lla = iridium_ncdf(p.ncfn,date,tlim,p.ellim,p.lla)

    eceftle,llatle = iridium_tle(p.tlefn,lla.index,p.lla,p.svn)

    plots(lla,llatle)