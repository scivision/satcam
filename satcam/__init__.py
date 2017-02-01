from pathlib import Path
from datetime import timedelta, datetime
from pandas import DataFrame
from numpy import arange,diff,array,column_stack,degrees
from ephem import readtle,Observer
from netCDF4 import Dataset
#
from histutils.fortrandates import forceutc
from pymap3d import eci2aer,eci2geodetic,eci2ecef,geodetic2ecef


def iridium_ncdf(fn,day,tlim,ellim, camlla):
    assert len(ellim) == 2,'must specify elevation limits'
    fn = Path(fn).expanduser()
    day = forceutc(day)
#%% get all sats psuedo SV number
    with Dataset(str(fn),'r') as f:
        #psv_border = nonzero(diff(f['pseudo_sv_num'])!=0)[0] #didn't work because of consequtively reused psv #unique doesn't work because psv's can be recycled
        psv_border = (diff(f['time'])<0).nonzero()[0] + 1 #note unequal number of samples per satellite, +1 for how diff() is defined
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
            az,el,r = eci2aer(f['pos_eci'][cind,:], camlla[0], camlla[1], camlla[2],t)
            if ellim and ((ellim[0] <= el) & (el <= ellim[1])).any():
               # print(t)
                #print('sat psv {}'.format(f['pseudo_sv_num'][i]))
                eci = f['pos_eci'][cind,:]
                lat,lon,alt = eci2geodetic(eci,t)
                x,y,z = eci2ecef(eci,t)
                #print('ecef {} {} {}'.format(x,y,z))

                ecef = DataFrame(index=t, columns=['x','y','z'], data=column_stack((x,y,z)))
                lla  = DataFrame(index=t, columns=['lat','lon','alt'], data=column_stack((lat,lon,alt)))
                aer  = DataFrame(index=t, columns=['az','el','srng'], data=column_stack((az,el,r)))
                return ecef,lla,aer,eci

    print('no FOV crossings for your time span were found.')
    return (None,None)

def iridium_tle(fn,T,sitella,svn):
    assert isinstance(svn,int)
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
    aer  = DataFrame(index=T,columns=['az','el','srng'])
    for t in T:
        obs.date = t
        sat.compute(obs)
        lat,lon,alt = degrees(sat.sublat), degrees(sat.sublong), sat.elevation
        az,el,srng = degrees(sat.az), degrees(sat.alt), sat.range
        x,y,z = geodetic2ecef(lat,lon,alt)
        ecef.loc[t,:] = column_stack((x,y,z))
        lla.loc[t,:]  = column_stack((lat,lon,alt))
        aer.loc[t,:]  = column_stack((az,el,srng))

    return ecef,lla,aer
