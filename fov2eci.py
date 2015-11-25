#!/usr/bin/env python3
# work in progress, may be not altogether correct
from pathlib2 import Path
import h5py

def fov2eci(ll,ur):
    """
    input:
    ------
    ll: lower left of az,el bounding box [deg]
    ur: upper right of az,el bounding box [deg]
    """

def loadfov(fn):
    fn = Path(fn).expanduser()
    with h5py.File(str(fn),'r') as f:
        az = f['az'].value
        el = f['el'].value

    return az,el


if __name__ == '__main__':
    from argparse import ArgumentParser
    p = ArgumentParser()
    p.add_argument('fn',help='fov filename to load')
    p.add_argumnet('--alt',help='scalar altitude to use [km]',type=float,default=781.)
    p = p.parse_args()

    az,el = loadfov(p.fn)
