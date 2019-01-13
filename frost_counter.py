
# coding: utf-8

# In[1]:


# Import modules

import datetime as dt
import numpy as np
from netCDF4 import Dataset, num2date
import matplotlib.pyplot as plt
from mpl_toolkits.basemap import Basemap, addcyclic, shiftgrid
from dateutil.relativedelta import relativedelta
import os
import re

# Initialise arrays for counter

years=[]

n_years=40

counter=np.zeros((5,n_years))
counter[0,:]=np.arange(1979,2019)

# Open files

# Open tas

for filename in os.listdir("/g/data1/ub4/erai/netcdf/6hr/atmos/oper_an_sfc/v01/tas/"):
        
    if re.search(r'tas_6hrs_ERAI_historical_an-sfc_........_........\.nc', filename):

        nc_f = filename
        print(nc_f)
        nc_fid = Dataset('/g/data1/ub4/erai/netcdf/6hr/atmos/oper_an_sfc/v01/tas/'+filename, 'r')

        output_image_name='temp_threshold_plot'

        # Display nc_dump data

        nc_dims = [dim for dim in nc_fid.dimensions]
        nc_vars = [var for var in nc_fid.variables]
        nc_attrs = nc_fid.ncattrs()

        # Extract data

        lons_net=nc_dims[1]
        lats_net=nc_dims[0]
        time_net=nc_dims[2]
        var_net=nc_vars[2]

        lons = nc_fid.variables[lons_net][:]
        lats = nc_fid.variables[lats_net][:]
        time = nc_fid.variables[time_net][:]
        var_name=nc_fid.variables[var_net].long_name
        var_units=nc_fid.variables[var_net].units
        time_units = nc_fid.variables[time_net].units
        time_calendar = nc_fid.variables[time_net].calendar

        var = nc_fid.variables[var_net][:]

        # Time conversion

        time_py = num2date(time,time_units,time_calendar)
        
        nc_fid.close()
        
        # Load in vas
        
        wind_filename='/g/data1/ub4/erai/netcdf/6hr/atmos/oper_an_sfc/v01/vas/'+'vas_6hrs_ERAI_historical_an-sfc_'+nc_f[-20:-3]+'.nc'
        #print(wind_filename)
        nc_fid = Dataset(wind_filename, 'r')
        
        nc_dims = [dim for dim in nc_fid.dimensions]
        nc_vars = [var for var in nc_fid.variables]
        nc_attrs = nc_fid.ncattrs()

        #print("va Dimensions:\n", nc_dims)
        #print("va Variables:\n", nc_vars)
        
        var_net=nc_vars[3]
        vas=nc_fid.variables[var_net][:]
        
        # Load in uas
        
        wind_filename='/g/data1/ub4/erai/netcdf/6hr/atmos/oper_an_sfc/v01/uas/'+'uas_6hrs_ERAI_historical_an-sfc_'+nc_f[-20:-3]+'.nc'
        nc_fid = Dataset(wind_filename, 'r')
        
        nc_dims = [dim for dim in nc_fid.dimensions]
        nc_vars = [var for var in nc_fid.variables]
        nc_attrs = nc_fid.ncattrs()
        
        var_net=nc_vars[3]
        uas=nc_fid.variables[var_net][:]
        
        # Calculate wind magnitude from the two vector components
        
        wind_speed=np.sqrt(np.power(vas,2)+np.power(uas,2))
        
        # Load in low cloud

        cll_filename='/g/data1/ub4/erai/netcdf/6hr/atmos/oper_an_sfc/v01/lcc/'+'lcc_6hrs_ERAI_historical_an-sfc_'+nc_f[-20:-3]+'.nc'
        nc_fid = Dataset(cll_filename, 'r')
        
        nc_dims = [dim for dim in nc_fid.dimensions]
        nc_vars = [var for var in nc_fid.variables]
        nc_attrs = nc_fid.ncattrs()

        var_net=nc_vars[1]
        cll=nc_fid.variables[var_net][:]

        # Set lat/lon range

        lat_LLC=-33.5
        lat_URC=-30.2
        lon_LLC=116.9
        lon_URC=120.2

        LLC_lon_index=np.abs(lons-lon_LLC).argmin()
        LLC_lat_index=np.abs(lats-lat_LLC).argmin()

        URC_lon_index=np.abs(lons-lon_URC).argmin()
        URC_lat_index=np.abs(lats-lat_URC).argmin()
        
        lon_index=[LLC_lon_index,URC_lon_index]
        lon_index.sort()
        LLC_lon_index=lon_index[0]
        URC_lon_index=lon_index[1]
        
        lat_index=[LLC_lat_index,URC_lat_index]
        lat_index.sort()
        LLC_lat_index=lat_index[0]
        URC_lat_index=lat_index[1]
        
        # Set thresholds. Wind in m/s.

        temp_threshold=2
        wind_threshold_knots=5
        wind_threshold=wind_threshold_knots*0.514444
        sky_threshold=0.25
        
        # Counting code

        for year in range(n_years):
            for time_i in range(len(time)):
                if counter[0,year]==time_py[time_i].year:
                    for lat in range(LLC_lat_index,URC_lat_index+1):
                        for lon in range(LLC_lon_index,URC_lon_index+1):
                            if var[time_i,lat,lon]<(temp_threshold+273.15):
                                counter[1,year]+=1
                                if wind_speed[time_i,lat,lon]<wind_threshold:
                                    counter[2,year]+=1
                                    if cll[time_i,lat,lon]<sky_threshold:
                                        counter[4,year]+=1
                                if cll[time_i,lat,lon]<sky_threshold:
                                    counter[3,year]+=1

np.set_printoptions(suppress=True)
print(counter)

