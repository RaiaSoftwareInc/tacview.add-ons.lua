# Display Radar

Displays a customizable radar cone on selected aircraft.

## Customize the radar

In radar-range-list.lua add your aircraft and their engagement range in meters. Check in the debug log (Add-ons → Debug Log) after selecting an object to see the exact name that you need to add in order for it to work. 

In main.lua adjust the properties RADAR_AZIMUTH, etc. as needed. See https://tacview.net/documentation/acmi/ for details about these properties.

#Limitations

This add-on will interfere with existing radar telemetry in the file in that it will delete all instances of the property RadarMode when an object is deselected. 