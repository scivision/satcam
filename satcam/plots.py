from pandas import DataFrame
from matplotlib.pyplot import figure

def plots(lla,llatle, img):
    if not isinstance(lla,DataFrame):
        return
    assert img.ndim == 2,'one image please'
#%% don't overclutter plot
    if lla.shape[0]<200:
        marker='.'
    else:
        marker=None
#%% create figure
    ax = figure().gca()
    ax.plot(lla['lon'],lla['lat'],color='b',marker=marker,label='nc')
    ax.plot(llatle['lon'],llatle['lat'],color='r',marker=marker,label='tle')
    ax.set_ylabel('lat')
    ax.set_xlabel('long')
    ax.set_title('WGS84 vs. time')
#    ax.set_ylim((-90,90))
#    ax.set_xlim((-180,180))
    ax.grid(True)
#%% altitude
#    ax = plt.figure().gca()
#    ax.plot(lla.index,lla['alt']/1e3,marker=marker)
#    ax.set_ylabel('altitude [km]')
#    ax.set_xlabel('time')
#%% optical
    fg = figure()
    ax = fg.gca()
    hi=ax.imshow(img,cmap='gray',vmin=500,vmax=2000)
    fg.colorbar(hi,ax=ax)