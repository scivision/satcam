======
satcam
======

Using known satellite positions to verify camera timing.

===================    ==============
program                description
===================    ==============
RunIridium91Apr11       plot where satellites exist vs. time on x,y pixel map
RunSatCrossTime         plot when satellite crossed expected pixel (for fine absolute timing verification)
===================    ==============



Algorithm:
----------
  1. Using TLE and SGP4 propagator, get az/el for satellite from an observer vs. time
  2. Load video frames from the selected times. 
  3. Pick a pixel to plot w.r.t. time. Variable "satpix" is an Nx2 matrix of x,y pixel coordinates, and N is the number of time steps.
  4. You will get a 1-D plot of intensity vs. time for that pixel. Did the satellite pixel-crossing correspond to the maximum intensity? If not, there is a timing error that you can quantify by how far in time the maximum intensity was from the TLE/SGP4 prediction.

This code was a quick one-off, if you are actually interested in this let's talk and fix the codebase.
