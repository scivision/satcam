from pathlib import Path
import h5py
from datetime import timedelta,datetime
import logging
#
from histutils.fortrandates import forceutc
from histutils.findnearest import find_nearest
#from histutils.rawDMCreader import goRead

def optical(vidfn,calfn,treq,terror_cam):
    """
    quick-n-dirty load of optical data to corroborate with other tle and ncdf data
    """
    #data, rawFrameInd,finf = goRead(vidfn,xyPix=(512,512),xyBin=(1,1), ut1Req=T,kineticraw=1/fps,startUTC=tstart)
    treq -= timedelta(seconds=terror_cam)

    treq = forceutc(treq)
    treq = treq.timestamp()

    vidfn = Path(vidfn).expanduser()
    if not vidfn.suffix == '.h5':
        raise IOError('{} needs to be HST HDF5 file'.format(vidfn))

    with h5py.File(str(vidfn),'r',libver='latest') as f:
        tcam = f['ut1_unix']
        i = find_nearest(tcam,treq)[0]
        if i==0 or i==tcam.size-1:
            logging.critical('requested time {} at or past edge of camera time {}'.format(datetime.utcfromtimestamp(treq),datetime.utcfromtimestamp(tcam[i])))

        tcam = f['ut1_unix'][i]
        img = f['rawimg'][i,...]
        llacam = f['sensorloc'].value
#%% map pixels to sky
    calfn = Path(calfn).expanduser()
    with h5py.File(str(calfn),'r',libver='latest') as f:
        az = f['/az'].value
        el = f['/el'].value

    return img, tcam, llacam, az,el
