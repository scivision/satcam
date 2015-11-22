function intensevals= RunSatCrossTime(event)
%%
% compares points from satazel for points satellite crosses in DMCdata
% examples:
% RunSatCrossTime('11Apr2013_irid91')
% RunSatCrossTime('1Mar2014_irid30')

makeplots = {'pix'}; %'lla','azel'
addpath('../histutils/Matlab')

%% Parameters 
switch event
    case '11Apr2013_irid91'
        dpath = '~/data/2013-04-11/2013-04-11T07-00-CamSer1387_frames_403709-1-405509.DMCdata';
        fps = 30; % camera 1387 for 11 Apr 2013
        camstart = [2013 04 11 7 0 11];
        satappear = [2013 04 11 10 45 12];
        % iridium 91, 11 March 2013
        % tle in satcam-data/sat_27372_test.txt
        usecam = 1;
        calfn = '../histfeas/precompute/hst1cal.h5'; 
        TLEfn = '../satcam-data/sat_27372_test.txt';
    case '31Mar2014_irid30'
        dpath = '/media/aurora1/HST2014image/2014-03-31/2014-03-31T06-12-CamSer7196.DMCdata';
        fps = 53; %from .xml file for 31 mar 2014 ultra
        camstart = [2014 3 31 6 12 23]; %from .nmea file
        satappear = [2014 3 31 12 29 4]; %from STK Access calcuation
        % iridium 30, 31 march 2014, TLE from STK .sa file
%        tle in sat_24949_test.txt
        usecam = 0;
        calfn = '2014-03-31T06-12-CamSer7196_cal.mat';
    otherwise, error('i don''t have this case defined')
end
    

trange = [-5 20]; %let's look from 5 seconds before satAppear to 20 seconds after satAppear

tstart = datenum([satappear(1:5) satappear(6)+trange(1)]);
tend = datenum([satappear(1:5) satappear(6)+trange(2)]);
%% camera locations

switch usecam
    case 0
        camlla = [65.1186367, -147.432975, 500]; % HST0, this is new Ultra serial number 7196 at Davis Science Operation Center
        camname = 'HST0';
    case 1
        camlla = [65.12657, -147.496908333, 208]; %HST1, this is old Ixon serial number 1387 at MF radar site
        camname='HST1';
end %switch usecam  
%% load satellite azel
% get tle (can also just cut and paste)
 fidTLE = fopen(TLEfn);
 tle{1} = fgetl(fidTLE);
 tle{2} = fgetl(fidTLE);

 dtsec = 0.5; %time step in seconds

[sataer, satlla, satpix] = satazel(camlla,camname,tle,tstart,tend,dtsec,calfn,makeplots);
%sanity check
if isempty(satpix)
    error('I can''t proceed since the satellite is not detected in the FOV. Is the az/el calibration correct for this date?')
end
%%
intensevals = getvideo(dpath,satpix,satappear,camstart,fps,tstart,trange);
%%
if ~nargout,clear,end
end %function

function intensevals = getvideo(fn,satpix,satappear,camstart,fps,tstart,trange)
   %% DMCdata 
[x, y, data] = timeDMCreader(fn,satappear,camstart,fps);

pixel = satpix(1,:) % check first

intensevals = data(pixel(1),pixel(2),:);
satellitemax = max(intensevals);
maxframe = find(intensevals == satellitemax);
maxtime = maxframe/fps
realtimenum = tstart - (datenum([2010 1 1 1 1 maxtime]) - datenum([2010 1 1 1 1 0]))
realtimestr = datestr(realtimenum); % double check legitmacy- does the first point = the start time?
timedif = trange(1) +  maxtime

% checkmat = zeros(length(checkx),length(satpix));
% count = 0;
% for i = 1:length(checkx)
%     for j = 1:length(satpix)
%         if checkx(i) == satpix(j)
%             if checky(i) == satpix(j+length(satpix))
%             checkmat(i,j) = 1;
%             end
%         end
%         count = count+1;
%     end
% end
% anyconnect = sum(sum(checkmat))
% % [x,y] = find(checkmat==1) 

%% plot
plot(squeeze(intensevals))
title(['Max Intensity ' num2str(satellitemax) ' at frame ' num2str(maxframe)])
ylabel('Pixel Intensities')
xlabel('Frame number')

end
