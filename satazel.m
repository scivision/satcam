function [sataer, satlla, satpix,t] = satazel(camlla,camname,tle,tstart,tend,dtSec,calfile,makeplots)
% Michael Hirsch  July 2013
% upgraded and extended by Amber Baurley Aug 2014
% GPLv3+ license
% plots az/el lla and TODO pixel indices of camera looking at satellite
%
% INPUTS:
% camlla: WGS84 camera location [ lat (deg), lon (deg), altitude (meters) ]
% camname: string with name of camera (arbitrary)
% tle: 2 element cell, containing text of TLE
% tstart: datevec of utc time to start plotting data
% tend: datevec of utc time to stop plotting data
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
% 4) plot
%
%
%% input processing
if length(tstart)==6 && length(tend) == 6 %assume datevec input
    try
        tstart = datetime(tstart);
        tend   = datetime(tend);
    catch
        tstart = datenum(tstart);
        tend   = datenum(tend);
    end
elseif length(tstart)==1 && length(tend)==1 %assume already datetime or datenum
else error('unknown input type for time')
end

if nargin<7, calfile = []; end
%% (0) (1) (2)
[t,sataer,satlla] = tle2azel(tle,camlla,tstart,tend,camname,dtSec);
%% 3) find when satellite crosses a pixel
% goal of this is to verify absolute timing of camera
if ~isempty(calfile)
    try
    %load astrometry.net plate scale file we made from github.com/scivision/astrometry_azel
    
    [azcal,elcal,xcal,ycal] = getcamcal(calfile);
    
    % because discardEdgePix is true, you will only get pixel indices that fall
    % on the image sensor (wouldn't make sense any other way)
    [nearrow,nearcol,goodInd] = findClosestAzel(azcal,elcal,sataer(:,1),sataer(:,2),true);
    sataer = sataer(goodInd,:);
    satlla = satlla(goodInd,:);
    t = t(goodInd,:);
    
    npts = length(nearrow);
    satpix = zeros(npts,2);
    for i = 1:npts
        satpix(i,1) = xcal(nearrow(i),nearcol(i));
        satpix(i,2) = ycal(nearrow(i),nearcol(i));
    end

    % Satpix should give you the expected image pixel
    % coordinates that the satellite will fall into, assuming timing, pointing, and
    % positions with sufficiently low error (ideal system).

    % We may find the satellite arrives at a pixel later than expected -- that's due
    % to camera time error (or position and pointing error).

    catch excp 
        display('oops, trouble with finding sat')
        rethrow(excp)
    end
else 
    display('no calfile specified')
end %if
%% 4) plots
if any(ismember(makeplots,'lla')) && ~isempty(satlla)
    hFd = figure(1); clf(1)
    subplot(2,1,1)
    plot(t,satlla(:,3)/1e3,'.')
    ylabel('Satellite Alitude [km]')
    xlabel('Time [UTC]')
    datetick('x')
    title(['Satellite Data, ',datestr(t(1),'yyyy-mm-dd'),'.  Epoch: ',datestr(EpochDateNum) ])
   % showTLE(gca,tle) %show the TLE used

    subplot(2,1,2)
    plot(satlla(:,1),satlla(:,2),'.')
    ylabel('Latitude [deg]')
    xlabel('Longitude [deg]')
    title(['Satellite Data, ',datestr(t(1)),' to ',datestr(t(end)),'.  Epoch: ',datestr(EpochDateNum)])
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
    title(hAxc1,{['Satellite seen from camera, dt=',num2str(dtSec),'sec., ',datestr(t(1)),' to ',datestr(t(end))],...
                   ['.  Epoch: ',datestr(EpochDateNum)]})
    %make azimuth axis be more proportional to image plane
    %set(hAxc1,'xlim',[180 225])
    legend('show')

    tlblpts(sataer(:,1),sataer(:,2),t,npts)

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

    tlblpts(satpix(:,1),satpix(:,2),t,npts)
   % legend('show','location','best')
    %set(axpix,'xlim',[-inf,nx],'ylim',[-inf,ny])
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
    case '.mat' %use HDF5 instead normally
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

function tlblpts(x,y,t,npts)
    %label a few points
    if npts>40, decimtxt = 6; %arbitrary, uncluttered plot
    elseif npts>20, decimtxt = 3;
    else decimtxt = 1;
    end
    for i = 1:decimtxt:npts
       text(x(i),y(i),datestr(t(i),'HH:MM:SS.fff'),'units','data') 
    end
end
