function vals = extractmaskedvals(data,rc)

%se = strel('square',3);
%mask = getnhood(translate(se,rc));

vals = data(rc(1)-1:rc(1)+1,rc(2)-1:rc(2)+1,:);

vals = squeeze(mean(mean(vals,1),2));

end