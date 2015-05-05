%RunIridium91 script to test satazel.m function
%michael hirsch


%camlla = [65.1186367,-147.432975,500];
camlla = [65.12657, -147.496908333, 208]; %[deg, deg, meters]
camname='';
tstart = datenum([2013 04 11 10 45 12]);
tend = datenum([2013 04 11 10 45 31]);
dtsec = 0.1; %time step in seconds
% this must contain calibration from camera pointing at time of image taking
calfile = 'hst1cal.mat'; 
%% get tle (can also just cut and paste)
 TLEpath = '../SatOrbit';
 TLEfile = 'sat_27372_test.txt';
 fidTLE = fopen([TLEpath,'/',TLEfile]);
 TLEused{1} = fgetl(fidTLE);
 TLEused{2} = fgetl(fidTLE);
%% do work
makeplots = {'pix'}; %'azel','lla'};
[sataer, satlla, satpix] = satazel(camlla,camname,tle,tstart,tend,dtsec,calfile,makeplots);
