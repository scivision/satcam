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
%% frames per pixel
% for 53 and 30 fps respectively we get the following frames per pixel displacement of the satellite in the image frame.
% so by inspection we can't just use a simple intensity threshold, but must consider the peak intensity of the pixel to determine
% when the satellite is closest to the center of the pixel, for any pixel traversal.
framespix53 = 53/pixelsPerSec
framespix30 = 30/pixelsPerSec
%% getting absolute time from pixel crossing
% consider the pixel crossed could have a maximum error of about four pixels assuming 1km TLE accuracy
% and 781km satellite altitude.
% peak time error comes from
% 1) TLE position accuracy
% 2) non-constant satellite intensity (Iridium flare)
%
% #2 can be worked around by sampling peak intensity at each pixel as it's crossed.
% For #1, it is observed that along-track error (ATE) is much worse than cross-track or normal to orbital plane error.
%   a number of references have shown that within 1 day of epoch, along-track error for LEO >400km can be less than 1km, or at least order 1km
%   it is the nano-sats tossed from ISS at 250km that can accumulate very high along-track error in a couple days,but they're well under 400km.
% 