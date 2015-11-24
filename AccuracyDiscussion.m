%% worksheet for accuracy of timing available from satellites passing through camera FOV
% Michael Hirsch
%
%% Example system
% a 9 degree field of view (FOV) on a 512x512 pixel imaging chip
% we suspect there were times when the camera missed the GPSDO-derived trigger pulse
% train, causing a monotonic timing bias where images are taken later than claimed
% the worst case is when a satellite goes straight along a row or column (maximum pixel count error)
fov_deg = 9;
Npix = 512;
%% TLE accuracy constraint
% assume 3-D positional accuracy of 1km for TLE [citation needed, there is a citation]
% then with the given optical system, to first order:
TLEuncert_km = 1; %[citation needed]
SatelliteAltitude_km = 781; %for Iridium
pixelLateralAtAlt_km = tand(fov_deg/Npix) * SatelliteAltitude_km
pixel_uncertainty = TLEuncert_km / pixelLateralAtAlt_km
%% tangential velocity
% Given TLE uncertainties vs. camera resolution, we must consider satellite tangential 
% velocity for how long it takes to go from one pixel to another.
% Assuming small eccentricity (circular orbit), and that the satellite mass is miniscule
% compared to Earth, we may obtain using 
%
% $$v_{sat} = \sqrt\frac{\mu}{a}$$
EarthRadius_km = 6371;
mu = 3.986004418e14; %standard gravitational parameter [m^3 s^-2]
a =  (EarthRadius_km + SatelliteAltitude_km)*1e3;
vsat_mps = sqrt(mu/a) %tangential speed

wsat_degsec = rad2deg(vsat_mps / a); %[degrees/sec]
pixelsPerSec = wsat_degsec/(fov_deg/Npix)