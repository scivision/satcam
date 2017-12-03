#!/usr/bin/env python
install_requires = ['ephem','numpy','astropy','netCDF4','matplotlib','python-dateutil','pytz',
'histutils']
tests_require=['nose','coveralls']
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
      install_requires=install_requires,
      tests_require=tests_require,
      extras_require={'tests':tests_require},
      python_requires='>=3.6',
      )
