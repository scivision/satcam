#!/usr/bin/env python
from setuptools import setup
import subprocess

try:
    import conda.cli
    conda.cli.main('install','--file','requirements.txt')
except Exception as e:
    print(e)

#%% install
setup(name='satcam',
      dependency_links = [
        'https://github.com/scienceopen/histutils/tarball/master#egg=histutils',
        ],
      install_requires=[ #'histutils'
                        ],
      packages=['satcam']
      )
