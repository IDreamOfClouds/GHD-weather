import urllib2
import urlparse
import sys

# Define station number wanted.

station_wanted=raw_input("What is station number desired? ")

ETX = chr(3)    # Used for determining when new reading occurs

# Read in data.

url = 'http://weather.rap.ucar.edu/upper/Current.rawins'
response  = urllib2.urlopen(url)
response.readline()

# Split the data up into separate readings.

entries = []
curr_entry = ""
for line in response.readlines():
    if ETX in line:
        # Reached the end of the entry.
        # The replace gets rid of the carriage returns.
        entries.append(curr_entry.replace('\r', ''))
        curr_entry = ""
    else:
        curr_entry += line

# Grab only the TTAA data.

TTAA_data = [s for s in entries if "TTAA" in s]

# Find the entry in TTAA_data that corresponds to the desired weather station.

station_found=0

for entry in TTAA_data:
    full_list_of_data=[]
    TTAA_data_lines = entry.split("\n")
    for line in TTAA_data_lines:
    # split the line apart
        for point in line.split():
        # and add each data point individually
            full_list_of_data.append(point)
    TTAA_index=full_list_of_data.index("TTAA")
    if full_list_of_data[TTAA_index+2]==station_wanted:
        specific_TTAA_data=full_list_of_data
        station_found=1
        break

if station_found!=1:
    print "ERROR: Station number not found"
    sys.exit()

print "String data: "
print specific_TTAA_data


# specific_TTAA_data= """539
# USJD01 OJAM 280000
# TTAA  77221 40265
# 99943 12049 00000 00663 ///// ///// 92849 16057 01504
# 85564 11650 24509 70161 03273 26528 50583 10388 27546
# 40752 20750 27584 30957 36558 28089 25081 46350 28099
# 20225 56356 ///// 15405 61358 27592 10650 71757 26571
# 88999
# 77180 28109 40719
# 31313 41708 82112="""

# Find index of TTAA.

TTAA_index=specific_TTAA_data.index("TTAA")

# Remove the entries before the TTAA and after the end code.

short_list_of_data=[]

for entry in specific_TTAA_data[TTAA_index:len(specific_TTAA_data)]:
    if entry not in ['31313', '51515', '21212']:
        short_list_of_data.append(entry)
    else:
        break

print "\nWeather string"
print short_list_of_data

# Station id.

station_id=short_list_of_data[2]
print "\nWeather staion: %s" % station_id

# sounding details

print "Sounding section: %s" % short_list_of_data[0]
print "Day: %s" % (int(short_list_of_data[1][:2])-50)
print "Time (hour GMT): %s" % short_list_of_data[1][2:4]
flag_last_group=int(short_list_of_data[1][4])
print "Level of last group: %s\n" % flag_last_group

# Remove sounding details from list.

weather_data=short_list_of_data[3:]

# Create a list with only the pressure layer data.

layer_data=[]

for entry in range(0, len(weather_data)/3):
    starting_point = entry * 3
    chunk = weather_data[starting_point:starting_point+3]
    if int(chunk[0][:2]) in [99, 00,92,85,70,50,40,30,25,20,15,10]:
        layer_data=layer_data+chunk

# Output the pressure layer data.

# Now iterate over every 3 points in pressure layer data.
for i in range(0, len(layer_data)/3):
    starting_point = i * 3
    chunk = layer_data[starting_point:starting_point+3]

# Output pressure

    if int(chunk[0][:2]) == 99:     # Check to see if surface layer
        print "Height: At surface"
        if chunk[0][2] == 0:
            print "Pressure: %s mb" % (1000+int(chunk[0][3:5]))
        else:
            print "Pressure: %s mb" % int(chunk[0][2:5])
    elif int(chunk[0][:2]) in [00,92,85,70,50,40,30,25,20,15,10]:       # For the rest of the pressure layers. Need to seperate into 11 cases!
        if int(chunk[0][:2]) in [85,70,50,40,30,25,20,15,10]:
            print "Pressure layer: %s mb" % (int(chunk[0][:2])*10)
            if int(chunk[0][:2])==85:
                print "Height: %s m" % (int(chunk[0][2:5])+1000)
            if int(chunk[0][:2])==70:
                print "Height: %s m" % (int(chunk[0][2:5])+3000)
            if int(chunk[0][:2]) in [50,40,30]: 
                print "Height: %s m" % (int(chunk[0][2:5])*10)
            if int(chunk[0][:2]) in [25,20,15,10]: 
                print "Height: %s m" % (int(chunk[0][2:5])*10+10000)
        if int(chunk[0][:2])==92:
            print "Pressure layer: 925 mb"
            print "Height: %s m" % chunk[0][2:5]
        if int(chunk[0][:2])==00:
            print "Pressure layer: 1000 mb"
            print "Height: %s m" % chunk[0][2:5]        
    else:
        print "Not a pressure level"

# Output temperature and dewpoint

    if chunk[1][2].isdigit():
        if (int(chunk[1][2])%2)==0:         # Even means positive temp, odd means negative
            print "Temperature: +%s C" % (float(chunk[1][:3])/10)
        else:
            print "Temperature: -%s C" % (float(chunk[1][:3])/10)
        if int(chunk[1][3:5])<55:
            print "Dewpoint: %s C" % (float(chunk[1][3:5])/10)
        else:
            print "Dewpoint: %s C" % (float(chunk[1][3:5])-50)
    else:
        print "No temperature data"

# Output wind speed and direction

    if chunk[2].isdigit():
        if int(chunk[2][0:3])%5==0:
            print "Wind direction: %s degrees" % int(chunk[2][0:3])
            print "Wind speed: %s knots\n" % int(chunk[2][3:5])
        else:
            print "Wind direction: %s degrees" % (int(chunk[2][0:3])-1)
            print "Wind speed: %s knots\n" % (100+int(chunk[2][3:5]))
    else:
        print "No wind data\n"

# Tropopause

for entry in weather_data:
    if entry[:2]== '88':
        index_88=weather_data.index(entry)

print 'Tropopause pressure: %s mb\n' % weather_data[index_88][2:5]

# Max wind

for entry in weather_data:
    if entry[:2]== '77':
        index_77=weather_data.index(entry)

print 'Max wind level: %s mb' % weather_data[index_77][2:5]

#if int(weather_data[index_77+1][0:3])%5==0:
#    print "Wind direction: %s degrees" % weather_data[index_77+1][0:3]
#    print "Wind speed: %s knots" % weather_data[index_77+1][3:5]
#else:
#    print "Wind direction: %s degrees" % (int(weather_data[index_77+1][0:3])-1)
#    print "Wind speed: %s knots" % (100+int(weather_data[index_77+1][3:5]))
    
#raw_input("Press enter to exit")