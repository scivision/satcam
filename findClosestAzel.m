function [NearestRow, NearestCol,goodBool] = findClosestAzel(AzImg,ElImg,AzVec,ElVec,doDiscardEdgePix)
% Amber Baurley and Michael Hirsch
% given a discrete sensor array (camera) with known az/el at each pixel, and
% given az/el requests, find the pixels closest to those requests
% E.g. you have a satellite with known az/el for several seconds, find the
% pixels that the satellite is on for those times
% Note: we don't care what kind of data az and el are, degrees, radians, whatever
%
% Inputs:
% AzImg: MxN array of azimuth data (e.g. from astrometry.net fits2azel.py program .mat output)
% ElImg: MxN array of elevation data
% AzVec: Px1 vector of azimuth requests
% ElVec: Px1 vector of elevation requests
%
% Outputs:
% nearestRow: Px1 vector of rows of closest pixel to az/el for each element in AzVec,Elvec
% NearestCol: Px1 vector of columns of closest pixel to az/el for each element in AzVec,ElVec
if nargin<5, 
    doDiscardEdgePix = false; 
end

keeplastpixel = false;

[nyPixel,nxPixel] = size(AzImg); 
%% error check
assert(all(size(AzVec) == size(ElVec)), 'AzVec and ElVec must be equal-sized vectors')
assert(all(size(AzImg) == size(ElImg)) && ismatrix(AzImg),'AzImg and ElImg must be equal-sized 2D matrix')
%% setup
NptsVec = numel(AzVec);
%mask = zeros(size(AzImg));
NearestRow = nan(NptsVec,1); 
NearestCol = nan(NptsVec,1);
%% do work
for i = 1:NptsVec
    errorDist = hypot(AzImg-AzVec(i),...
                      ElImg-ElVec(i));

    [NearestRow(i), NearestCol(i)] = find(errorDist==min(min(errorDist))); %finds row,col index in 2D array

end %for
%% discard pixels at edges of images 

if doDiscardEdgePix
    %discard all edge pixels, leaving first and last elements
    mincolBool = NearestCol == 1;
    maxcolBool = NearestCol == nxPixel;
    minrowBool = NearestRow == 1;
    maxrowBool = NearestRow == nyPixel;
    
    %this is a dangerous option, you don't know how far inside or outside the last pixel was
    if keeplastpixel 
        mincolBool = firstorlast(mincolBool);
        maxcolBool = firstorlast(maxcolBool);
        minrowBool = firstorlast(minrowBool);
        maxrowBool = firstorlast(maxrowBool);
    end

    discardBool = mincolBool | maxcolBool | minrowBool | maxrowBool;
    if all(discardBool)
        warning('All values were discarded, your target is completely outside FOV for all times considered')
    end
    
    %discardInd = find(discardBool);
    NearestRow(discardBool) = [];
    NearestCol(discardBool) = [];
    display(['Discarded ',int2str(sum(discardBool)),' instances'])
    goodBool = ~discardBool;
    

end %if

end

function bool = firstorlast(bool)
    ind = find(bool);

    if ~isempty(ind)
        if ind(1) == 1
            bool(ind(end)) = false;
        else
            bool(ind(1)) = false;
        end
    else
        %do nothing
    end

end
