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
function data = timeDMCreader(fn,reqtime,starttime,fps,trange,rowcol,playmovie)
%% parameters
% rawframereq has +1 on rhs to account for raw frame number being one-based index
if length(reqtime)==1 && length(starttime)==1 %must be datenum or datetime
    try
        rawframereq = seconds(reqtime - starttime)*fps + 1;
    catch
        rawframereq = (reqtime-starttime)*86400*fps +1; 
    end
elseif length(reqtime)==6 %must be datevec
    try
        rawframereq = seconds(datetime(reqtime) - datetime(starttime))*fps +1; %this is the "raw" frame number of the .DMCdata file
    catch
        rawframereq = (datenum(reqtime)-datenum(starttime))*86400*fps +1; 
    end
else
    error('unknown input date request format--need datetime, datenum, or datevec')
end
rawframereq = round(rawframereq);
%% compute times chosen
rawframereq = (rawframereq+(trange(1)*fps)) : (rawframereq+(trange(2)*fps)); % starts earlier incase timing wrong
disp(['interested in raw frame indices ',int2str(rawframereq(1)),' to ',int2str(rawframereq(end))])
%% call DMCreader
[~,~,ext] = fileparts(fn);
switch lower(ext)
    case '.dmcdata'
        BytesPerImage = prod(rowcol)*16/8; 
        nHeadBytes = 4; %typical
        firstRawIndex = getRawInd(fn,BytesPerImage,nHeadBytes);
        framereq = rawframereq - firstRawIndex + 1; % + 1 since first camera index is one (one-based indexing)
        data = rawDMCreader(fn,'framereq',framereq,'playmovie',playmovie);
    case '.h5', 
        rawframeind = h5read(expanduser(fn),'/rawind');
        data = h5read(expanduser(fn),'/rawimg'); %;,...
                     % rawframereq(1)-double(rawframeind(1))+1,...
                    %  [rowcol, length(rawframereq)-1]);
    otherwise, error(['unknown data file type ',ext]) 
end
