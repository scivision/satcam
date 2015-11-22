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
if length(reqtime)==1 %must be datenum
elseif length(reqtime)==6 %must be datevec
    reqtime = datenum(reqtime)*86400;
else
    error('unknown input date request format')
end

if length(starttime)==1 %must be datenum
elseif length(starttime)==6 %must be datevec
    starttime = datenum(starttime)*86400;
else
    error('unknown input start time format')
end

if nargin<5
    trange = [-5 20];
end

% assumed parameters FIXME
rowcol = [512,512];
rcbin = [1,1];
%% compute times chosen
suggestedframe = round((reqtime-starttime)*fps); %this is the "raw" frame number of the .DMCdata file
framerange = (suggestedframe+(trange(1)*fps)) : (suggestedframe+(trange(2)*fps)); % starts earlier incase timing wrong
startframe = framerange(1);
endframe = framerange(end);
%% considering that our data file might be a small slice from the whole-night file, correct indices
BytesPerImage = prod(rowcol)*16/8; 
nHeadBytes = 4; %typical
firstRawIndex = getRawInd(fn,BytesPerImage,nHeadBytes);

shiftedframerange = framerange - firstRawIndex + 1; 
%% call DMCreader
data = rawDMCreader(fn,'rowcol',rowcol,'rcbin',rcbin,'framereq',shiftedframerange);

end
