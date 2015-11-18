function [sataer, satLLA, satpix,tUTC] = satazel(camlla,camname,tle,tstart,tend,dtSec,calfile,makeplots)
% Michael Hirsch  July 2013
% upgraded and extended by Amber Baurley Aug 2014
% GPLv3+ license
% plots az/el lla and TODO pixel indices of camera looking at satellite
%
% INPUTS:
% camlla: WGS84 camera location [ lat (deg), lon (deg), altitude (meters) ]
% camname: string with name of camera (arbitrary)
% tle: 2 element cell, containing text of TLE
% tstart: datenum of utc time to start plotting data
% tend: datenum of utc time to stop plotting data
% dtsec: time step of simulation (too small, takes forever, too big, skips pixels)
%
% OUTPUTS:  (N is number of time steps)
% sataer = Nx3 of azimuth (deg), elevation (deg), slant range (meters)
% satLLA = Nx3 of latitude [deg], longitude [deg], altitude [meters]
% satpix = Nx2 of [x (column), y (row)]
%
% Algorithm:
% 0) load Rino toolboxes
% 1) run SGP4 for the satellite -- gives ECEF vs. time of satellite which is
% then converted to Lat Lon Alt vs. time of satellite
% 2) convert Lat Lon Alt to Azimuth/elevation for each site
% 3) find camera pixel coordinates that satellite should appear at vs. time
% (TODO)
% 4) plot
%
%
if nargin<7, calfile = []; end
%% (0) load Charles Rino's SatOrbit
addpath('SGP4') % http://www.mathworks.com/matlabcentral/fileexchange/28888-satellite-orbit-computation
addpath('GPS_CoordinateXforms') %http://www.mathworks.com/matlabcentral/fileexchange/28813-gps-coordinate-transformations

if verLessThan('matlab','8.0'), 
    error('This program requires Matlab R2012b or newer to run the geometric transforms')
end

min_per_day=60*24;
sec_per_day=60*min_per_day;

%% (1) run SGP4 for satellite
try
satrec = twoline2rvMOD(tle{1},tle{2});
catch excp, display('It looks like you need to install Charles Rino''s SatOrbit:')
    display('http://www.mathworks.com/matlabcentral/fileexchange/28888-satellite-orbit-computation')
    display('and Charles Rino''s GPS Coordinate Transforms:')
    display('www.mathworks.com/matlabcentral/fileexchange/28813-gps-coordinate-transformations')
    fclose('all');
    rethrow(excp)
end
fprintf('\n')
fprintf('Satellite ID %5i \n',satrec.satnum)
fprintf('Observer 1: %s Lat=%6.4f Lon %6.4f Alt=%3.2f m\n',...
            camname,camlla(1),camlla(2),camlla(3))

                
if (satrec.epochyr < 57)
    Eyear= satrec.epochyr + 2000;
else
    Eyear= satrec.epochyr + 1900;
end

%converts the day of the year, days, to the equivalent month, day, hour, minute and second.
[Emon,Eday,Ehr,Emin,Esec] = days2mdh(Eyear,satrec.epochdays);

EpochDateNum = datenum([Eyear,Emon,Eday,Ehr,Emin,Esec]); 
tsinceDateNum = (tstart-EpochDateNum):dtSec/sec_per_day:(tend-EpochDateNum);
npts= length(tsinceDateNum);

tsince = tsinceDateNum*min_per_day; %[minutes]
display(['Epoch time is: ',datestr(EpochDateNum)])
xsat_ecf=zeros(3,npts);
vsat_ecf=zeros(3,npts);
for n=1:npts
   [satrec, xsat_ecf(:,n), vsat_ecf(:,n)]=spg4_ecf(satrec,tsince(n));
end

%Scale state vectors to mks units
xsat_ecf=xsat_ecf*1000;  %m
vsat_ecf=vsat_ecf*1000;  %#ok<NASGU> %mps

sat_llh=ecf2llhT(xsat_ecf);            %ECF to geodetic (llh)  
%sat_tcs=llh2tcsT(sat_llh,origin_llh);  %llh to tcs at origin_llh
%sat_elev=atan2(sat_tcs(3,:),sqrt(sat_tcs(1,:).^2+sat_tcs(2,:).^2));
%Identify visible segments: 
%notVIS=find(sat_tcs(3,:)<0);
%VIS=setdiff([1:npts],notVIS);
%sat_llh(:,notVIS)=NaN;
%sat_tcs(:,notVIS)=NaN;


%% (2) convert to azimuth/elevation from a site
tUTC(:,1) = EpochDateNum+tsinceDateNum;

satLLA(:,1) = rad2deg(sat_llh(2,:));
satLLA(:,2) = rad2deg(sat_llh(1,:));
satLLA(:,3) = sat_llh(3,:);

[sataer(:,1), sataer(:,2), sataer(:,3)] = ecef2aer(xsat_ecf(1,:),xsat_ecf(2,:),xsat_ecf(3,:),...
                                                    camlla(1),camlla(2),camlla(3),...
                                                    referenceEllipsoid('wgs84'),'degrees');
%sanity check
if all(sataer(:,2)<0)
    error('The satellite is always below the horizon, something seems amiss with your time, parameters, or calibration')
end
%% 3) find when satellite crosses a pixel
% goal of this is to verify absolute timing of camera
if ~isempty(calfile)
    try
    %load astrometry.net .mat file we made from fits2azel.py
    
    [azcal,elcal,xcal,ycal] = getcamcal(calfile);
    
    % because discardEdgePix is true, you will only get pixel indices that fall
    % on the image sensor (wouldn't make sense any other way)
    [nearrow,nearcol,goodInd] = findClosestAzel(azcal,elcal,sataer(:,1),sataer(:,2),true);
    sataer = sataer(goodInd,:);
    satLLA = satLLA(goodInd,:);
    tUTC = tUTC(goodInd,:);
    
    npts = length(nearrow);
    satpix = zeros(npts,2);
    for ipx = 1:length(nearrow)
        satpix(ipx,1) = xcal(nearrow(ipx),nearcol(ipx));
        satpix(ipx,2) = ycal(nearrow(ipx),nearcol(ipx));
    end

    nx = max(max(xcal));
    ny = max(max(ycal));
    % I believe that satpix should give you the expected image pixel
    % coordinates that the satellite will fall into, assuming timing, pointing, and
    % positions with sufficiently low error (ideal system).

    % We may find the satellite arrives at a pixel later than expected -- that's due
    % to camera time error (or position and pointing error).

    catch excp 
        display('oops, trouble with finding sat')
        %satpix = [];  %in case this code part crashes
        rethrow(excp)
    end
else 
    display('no calfile specified')
end %if
%% 4) plots
if any(ismember(makeplots,'lla')) && ~isempty(satLLA)
    hFd = figure(1); clf(1)
    subplot(2,1,1)
    plot(tUTC,satLLA(:,3)/1e3,'.')
    ylabel('Satellite Alitude [km]')
    xlabel('Time [UTC]')
    datetick('x')
    title(['Satellite Data, ',datestr(tUTC(1),'yyyy-mm-dd'),'.  Epoch: ',datestr(EpochDateNum) ])
   % showTLE(gca,tle) %show the TLE used

    subplot(2,1,2)
    plot(satLLA(:,1),satLLA(:,2),'.')
    ylabel('Latitude [deg]')
    xlabel('Longitude [deg]')
    title(['Satellite Data, ',datestr(tUTC(1)),' to ',datestr(tUTC(end)),'.  Epoch: ',datestr(EpochDateNum)])
   % showTLE(gca,tle) %show the TLE used

    fcp = get(hFd,'pos');
    set(hFd,'pos',[fcp(1) fcp(2) 560 680])
end

if any(ismember(makeplots,'azel')) && ~isempty(sataer)

    %now the real interesting ones
    hFc1 = figure(2); clf(2)
    hAxc1 = axes('parent',hFc1,'nextplot','add');

    plot(sataer(2:end-1,1),sataer(2:end-1,2),'k.','parent',hAxc1,'displayname','path')

    plot(sataer(1,1), sataer(1,2),'g.','parent',hAxc1,'displayname','start') %start
    plot(sataer(end,1),sataer(end,2),'r.','parent',hAxc1,'displayname','end') %end

    ylabel(hAxc1,'elevation [deg]')
    xlabel(hAxc1,'azimuth [deg]')
    title(hAxc1,{['Satellite seen from camera, dt=',num2str(dtSec),'sec., ',datestr(tUTC(1)),' to ',datestr(tUTC(end))],...
                   ['.  Epoch: ',datestr(EpochDateNum)]})
    %make azimuth axis be more proportional to image plane
    %set(hAxc1,'xlim',[180 225])
    legend('show')

    tlblpts(sataer(:,1),sataer(:,2),tUTC,npts)

    showTLE(hAxc1,tle) %show the TLE used
end

if any(ismember(makeplots,'pix')) && ~isempty(satpix)
    figure(3),clf(3)
    axpix = axes('parent',3);
    line(satpix(:,1),satpix(:,2),'color','k','marker','.','parent',axpix,'displayname','path')
    grid('on')
    % data cursor doesn't work properly when these are labels (sticks to this point)
    %line(satpix(1,2), satpix(1,1),'color','g','marker','.','parent',axpix,'displayname','start')
    %line(satpix(end,2),satpix(end,1),'color','r','marker','.','parent',axpix,'displayname','end') 

    title(['pixels identified as corresponding to satellite for camera ',camname])
    xlabel('x-pixel')
    ylabel('y-pixel')

    tlblpts(satpix(:,1),satpix(:,2),tUTC,npts)
   % legend('show','location','best')
    set(axpix,'xlim',[1,nx],'ylim',[1,ny])
end
%% no outputs?
if ~nargout, clear, end

end

function showTLE(ax,TLE)
setappdata(ax,'TLE',TLE)
%text(0.025,0.025,TLE{1},'units','normalized','parent',ax,'fontsize',4,'fontname','courier new')
%text(0.025,0.025,TLE{2},'units','normalized','parent',ax,'fontsize',4,'fontname','FixedWidth')
end

function [azcal,elcal,xcal,ycal] = getcamcal(calfile)

[~,~,ext] = fileparts(calfile);

switch lower(ext)
    case '.mat'
       s = load(calfile,'az','el','x','y');
       azcal = s.az; 
       elcal = s.el; 
       %plus one since matlab is one-based indexing and python is zero-based indexing
       xcal = s.x +1;
       ycal = s.y +1;
    case '.h5'
       azcal = transpose(h5read(calfile,'/az')); %row-major
       elcal = transpose(h5read(calfile,'/el')); %row-major
       xcal = transpose(h5read(calfile,'/x')) + 1;
       ycal = transpose(h5read(calfile,'/y')) + 1;
        
    otherwise, error(['i don''t yet know how to load ',ext,' files'])
end

end

function tlblpts(x,y,tUTC,npts)
    %label a few points
    if npts>40, decimtxt = 6; %arbitrary, uncluttered plot
    elseif npts>20, decimtxt = 3;
    else decimtxt = 1;
    end
    for i = 1:decimtxt:npts
       text(x(i),y(i),datestr(tUTC(i),'HH:MM:SS.fff'),'units','data') 
    end
end
