#!/usr/bin/env python
from setuptools import setup

req = ['histutils','nose','ephem','numpy','astropy','netCDF4','matplotlib','python-dateutil','pytz']

#%% install
setup(name='satcam',
      packages=['satcam'],
      author='Michael Hirsch, Ph.D.',
      url='https://github.com/scienceopen/satcam',
      description='intersection of camera FOV and satellite passes',
      classifiers=[
        'Programming Language :: Python :: 3.6',
      ],
      install_requires=req,
      )
