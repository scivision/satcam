#!/usr/bin/env python
req = ['nose','ephem','numpy','astropy','netCDF4','matplotlib','python-dateutil','pytz']
pipreq= ['histutils']

# %%
import pip
try:
    import conda.cli
    conda.cli.main('install',*req)
except Exception as e:
    pip.main(['install'] +req)
pip.main(['install']+pipreq)

# %%
from setuptools import setup

setup(name='satcam',
      packages=['satcam'],
      author='Michael Hirsch, Ph.D.',
      url='https://github.com/scivision/satcam',
      description='intersection of camera FOV and satellite passes',
      classifiers=[
        'Programming Language :: Python :: 3',
      ],
      install_requires=req+pipreq,
      )
