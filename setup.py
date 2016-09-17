#!/usr/bin/env python
from setuptools import setup
import subprocess

try:
    subprocess.call(['conda','install','--file','requirements.txt'])
except Exception as e:
    pass

#%% install
setup(name='satcam',
      description='Discover times and pixels of satellite crossings with camera',
      url='https://github.com/scienceopen/satcam',
      dependency_links = [
        'https://github.com/scienceopen/histutils/tarball/master#egg=histutils',
        ],
      install_requires=['pathlib2',
                        #'histutils'
                        ],
      packages=['satcam']
      )
