
# coding: utf-8

# In[92]:


# Import modules

import datetime as dt
import numpy as np
from netCDF4 import Dataset, num2date
import matplotlib as mpl
import matplotlib.pyplot as plt
from mpl_toolkits.basemap import Basemap, addcyclic, shiftgrid

# Open u file

nc_f = '/g/data/rr7/ERA_INT/ERA_INT/ERA_INT_uas_2010.nc'
nc_fid = Dataset(nc_f, 'r')

output_image_name='barb_map'

# Display nc_dump data

nc_dims = [dim for dim in nc_fid.dimensions]
nc_vars = [var for var in nc_fid.variables]
nc_attrs = nc_fid.ncattrs()

print("Dimensions:\n\t", nc_dims)
print("Variables:\n\t", nc_vars)
print("Attributes:\n\t", nc_attrs)

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

print("Time units:\n\t", time_units)
print("Time calendar:\n\t", time_calendar)

u = nc_fid.variables[var_net][:]

# Close file

nc_fid.close()

# Open v file

nc_f = '/g/data/rr7/ERA_INT/ERA_INT/ERA_INT_vas_2010.nc'
nc_fid = Dataset(nc_f, 'r')

# Display nc_dump data

nc_dims = [dim for dim in nc_fid.dimensions]
nc_vars = [var for var in nc_fid.variables]
nc_attrs = nc_fid.ncattrs()

print("Dimensions:\n\t", nc_dims)
print("Variables:\n\t", nc_vars)
print("Attributes:\n\t", nc_attrs)

# Extract data

var_net=nc_vars[5]

v = nc_fid.variables[var_net][:]

# Close file

nc_fid.close()

# Time conversion and picking a time

time_py = num2date(time,time_units,time_calendar)
print("Python date:\n\t", time_py)

time_index=1

# Wind magnitude (for colour)

C=np.sqrt(np.power(u[time_index, :, :],2)+np.power(v[time_index, :, :],2))

# Map domain setting

#lower_left = np.array([0,-90])
#upper_right = np.array([360,90])

lower_left = np.array([100,0])
upper_right = np.array([160,40])

#lower_left = np.array([100,-40])
#upper_right = np.array([160,0])
centre = (lower_left+upper_right)/2

# Find lat/lon index for domain limit

lower_lon_idx = np.abs(lons - lower_left[0]).argmin()
lower_lat_idx = np.abs(lats - lower_left[1]).argmin()

upper_lon_idx = np.abs(lons - upper_right[0]).argmin()
upper_lat_idx = np.abs(lats - upper_right[1]).argmin()

#print(lower_lon_idx)
#print(lower_lat_idx)
#print(upper_lon_idx)
#print(upper_lat_idx)

# Find max/min value in domain

max_speed=np.amax(C[lower_lon_idx:upper_lon_idx+1,lower_lat_idx:upper_lat_idx+1])
min_speed=np.amin(C[lower_lon_idx:upper_lon_idx+1,lower_lat_idx:upper_lat_idx+1])

print("Max speed:\n\t", max_speed)
print("Min speed:\n\t", min_speed)

# Map making

lon2d, lat2d = np.meshgrid(lons,lats)

fig = plt.figure()
map = Basemap(projection = 'cyl', lon_0 = centre[0] , lat_0 = centre[1], llcrnrlon=lower_left[0],               llcrnrlat=lower_left[1], urcrnrlon=upper_right[0], urcrnrlat=upper_right[1],               resolution = 'c')

map.drawcoastlines()

skip=2  # Spacing of wind barbs

#cs2 = map.contourf(lon2d[:,::skip], lat2d[:,::skip],C[:,::skip],5) # Contour map

cs = map.barbs(lon2d[:,::skip], lat2d[:,::skip], u[time_index, :, :][:,::skip],                v[time_index, :, :][:,::skip], C[:,::skip], length=5,              sizes=dict(emptybarb=0.1))

# For color bar

norm = mpl.colors.Normalize(0,max_speed)
c_m = mpl.cm.jet
s_m = mpl.cm.ScalarMappable(cmap=c_m, norm=norm)
s_m.set_array([])
cb=map.colorbar(s_m)
cb.set_label("Wind speed (m/s)")

# Plot touches

plt.title("Near surface wind on %s" % (time_py[time_index]))
plt.show()
fig.savefig(output_image_name)



