function intensevals = pixelcrossing(fn,satpix,satappear,camstart,fps,tstart,trange,rowcol,playmovie)
%% load .DMCdata file
data = timeDMCreader(fn,satappear,camstart,fps,trange,rowcol,playmovie);
%% checkout first time step of satellite in FOV
% pixel indices of first timestep pixel crossing
%intensevals = data(satpix(1,1),satpix(1,2),:);
intensevals = extractmaskedvals(data,satpix(1,:)); % intensities of the first predicted pixel location vs. time (waiting for sat to cross this pixel)
[~,crossind] = max(intensevals);         % supposing the maximum intensity vs. time of this pixel is when the sat finally crossed it
elapsed = crossind/fps;                   % frameindex / frames/sec = elapsed seconds since req. video start
errorsec = trange(1) +  elapsed;
try
    realtime = tstart + seconds(elapsed);
catch
    realtime = tstart + elapsed/86400;
end

disp(['sat. crossing time error ',num2str(errorsec),' seconds.'])
disp(['frame crossing index ',int2str(crossind)])
disp(['approx error ',int2str(errorsec*fps),' frames.'])

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
figure
plot(squeeze(intensevals))
title(['Max Intensity found at: ',datestr(realtime),' row,col ',int2str(satpix(1,:)),' frame ', num2str(crossind)])
ylabel('Pixel Intensities')
xlabel('Frame number')

end