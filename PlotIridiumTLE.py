#!/usr/bin/env python
from matplotlib.pyplot import show
from dateutil.parser import parse
from datetime import datetime
from pytz import UTC

#
from satcam import iridium_tle, iridium_ncdf
from satcam.plots import plots

if __name__ == '__main__':
    from argparse import ArgumentParser

    p = ArgumentParser(description='load and plot position data')
    p.add_argument('ncfn', help='.ncdf file to process')
    p.add_argument('tlefn', help='.tle file to process')
    p.add_argument('date', help='date to process yyyy-mm-dd')
    p.add_argument('-l', '--tlim', help='start stop time', nargs=2)
    p.add_argument('-e', '--ellim', help='el limits [deg]', nargs=2, type=float)
    p.add_argument('-c', '--lla', help='lat,lon,alt of site [deg,deg,meters]', nargs=3, type=float)
    p.add_argument('-s', '--svn', help='TLE number of satellite (5 digit int)', type=int)
    p = p.parse_args()

    if p.tlim:
        tlim = (parse(p.tlim[0]), parse(p.tlim[1]))
    else:
        tlim = None

    t0 = parse(p.date)
    date = datetime(t0.year, t0.month, t0.day, tzinfo=UTC)

    ecef, lla = iridium_ncdf(p.ncfn, date, tlim, p.ellim, p.lla)

    eceftle, llatle = iridium_tle(p.tlefn, lla.index, p.lla, p.svn)

    plots(lla, llatle)
    show()
