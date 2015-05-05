% allows you to input time instead of frame number for rawDMCreader
% Michael Hirsch
% this code need improvement.
% 
% inputs: 
% fn = .DMCdata file to read
% reqtime = time desired to start reading, form: [yyyy mon day hr min second]
% starttime = time from .nmea file, form: [yyyy mon day hr min second]
% fps = frames per second from .xml file
% 


function [startframe,endframe,data] = timeDMCreader(fn,reqtime,starttime,fps,trange)
%% parameters
if nargin<1 || isempty(fn)
    fn = '/media/aurora1/HST2014image/2014-03-31/2014-03-31T06-12-CamSer7196.DMCdata';
end

if nargin<2
    reqtime = datenum([2014 3 31 7 57 0.504])*86400;
else
    reqtime = datenum(reqtime)*86400;
end

if nargin<3
    starttime = datenum([2014 3 31 6 12 23])*86400;
else
    starttime = datenum(starttime)*86400;
end

if nargin<4
    fps = 53;
end

if nargin<5
    trange = [-5 20];
end

%trange
%% compute times chosen
suggestedframe = round((reqtime-starttime)*fps); %this is the "raw" frame number of the .DMCdata file
framerange = (suggestedframe+(trange(1)*fps)) : (suggestedframe+(trange(2)*fps)); % starts earlier incase timing wrong
startframe = framerange(1);
endframe = framerange(end);
%% considering that our data file might be a small slice from the whole-night file, correct indices
BytesPerImage = 512*512*16/8; %typical
nHeadBytes = 4; %typical
[firstRawIndex, lastRawIndex] = getRawInd(fn,BytesPerImage,nHeadBytes);

shiftedframerange = framerange - firstRawIndex + 1; 
%% call DMCreader
data = rawDMCreader(fn,512,512,1,1,shiftedframerange,0,[0,900]);

end
