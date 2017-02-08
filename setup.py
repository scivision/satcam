#!/usr/bin/env python
from setuptools import setup
import subprocess

try:
    import conda.cli
    conda.cli.main('install','--file','requirements.txt')
except Exception as e:
    print(e)
    import pip
    pip.main(['install','-r','requirements.txt'])

#%% install
setup(name='satcam',
      author='Michael Hirsch, Ph.D.',
      url='https://github.com/scienceopen/satcam',
      description='intersection of camera FOV and satellite passes',
      classifiers=[
        'Programming Language :: Python :: 3.6',
      ],
      dependency_links = [
        'https://github.com/scienceopen/histutils/tarball/master#egg=histutils',
        ],
      install_requires=[ 'histutils'
                        ],
      packages=['satcam']
      )
