
# coding: utf-8

# In[84]:


# Import modules

import datetime as dt
import numpy as np
from netCDF4 import Dataset, num2date
import matplotlib.pyplot as plt
from mpl_toolkits.basemap import Basemap, addcyclic, shiftgrid

# Open file

nc_f = '/g/data/rr7/ERA_INT/ERA_INT/ERA_INT_atas_2010.nc'
nc_fid = Dataset(nc_f, 'r')

output_image_name='temp_map'

# Display nc_dump data

nc_dims = [dim for dim in nc_fid.dimensions]
nc_vars = [var for var in nc_fid.variables]
nc_attrs = nc_fid.ncattrs()

print("Dimensions:\n", nc_dims)
print("Variables:\n", nc_vars)
print("Attributes:\n", nc_attrs)

# Extract data

lons_net=nc_dims[0]
lats_net=nc_dims[2]
time_net=nc_dims[3]
var_net=nc_vars[5]

lons = nc_fid.variables[lons_net][:]
lats = nc_fid.variables[lats_net][:]
time = nc_fid.variables[time_net][:]
time_units = nc_fid.variables[time_net].units
time_calendar = nc_fid.variables[time_net].calendar

print("Time units:\n", time_units)
print("Time calendar:\n", time_calendar)

atas = nc_fid.variables[var_net][:]

# Time conversion

time_py = num2date(time,time_units,time_calendar)
print(time_py)
time_index=1


# Map domain setting

#lower_left = np.array([0,-90])
#upper_right = np.array([360,90])

lower_left = np.array([100,-40])
upper_right = np.array([160,0])
centre = (lower_left+upper_right)/2

# Map making

fig = plt.figure()
map = Basemap(projection = 'cyl', lon_0 = centre[0] , lat_0 = centre[1], llcrnrlon=lower_left[0],               llcrnrlat=lower_left[1], urcrnrlon=upper_right[0], urcrnrlat=upper_right[1], resolution = 'c')
lon2d, lat2d = np.meshgrid(lons,lats)
cs = map.contourf(lon2d, lat2d, atas[time_index, :, :], 11, cmap=plt.cm.Spectral_r)

map.drawcoastlines()
cbar = plt.colorbar(cs, orientation='horizontal', shrink=0.5)
cbar.set_label("%s (%s)" % (nc_fid.variables[var_net].long_name,                            nc_fid.variables[var_net].units))
plt.title("%s on %s" % (nc_fid.variables[var_net].long_name, time_py[time_index]))
plt.show()
fig.savefig(output_image_name)

# Close file

nc_fid.close()

