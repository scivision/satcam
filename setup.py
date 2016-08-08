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
      author='Michael Hirsch',
      url='https://github.com/scienceopen/satcam',
      install_requires=['pathlib2'],
      packages=['satcam']
      )
