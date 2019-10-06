#!/usr/bin/env python
# work in progress, may be not altogether correct
from pathlib import Path
import h5py
import argparse


def fov2eci(ll, ur):
    """
    input:
    ------
    ll: lower left of az,el bounding box [deg]
    ur: upper right of az,el bounding box [deg]
    """


def loadfov(fn):
    fn = Path(fn).expanduser()
    with h5py.File(fn, 'r') as f:
        az = f['az'].value
        el = f['el'].value

    return az, el


if __name__ == '__main__':
    p = argparse.ArgumentParser()
    p.add_argument('fn', help='fov filename to load')
    p.add_argument('--alt', help='scalar altitude to use [km]', type=float, default=781.0)
    P = p.parse_args()

    az, el = loadfov(P.fn)
