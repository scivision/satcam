function tle = gettle(fn,num) 

 if ~ischar(num)
    num = int2str(num); 
 end
 pat = ['1 ',num];
 
 f = fopen(fn);
 
 while ~feof(f)
 c = fgetl(f);
 if strcmp(c(1:7),pat)
     tle{1} = c;
     tle{2} = fgetl(f);
     break
 end
 
 end %while
 
 fclose(f);
 
end 