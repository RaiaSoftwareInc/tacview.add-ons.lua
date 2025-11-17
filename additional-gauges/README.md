# Additional Gauges

Use this add-on with X-Plane (or with custom data) to display an RPM Gauge in the 3D view.  

## How to use it?

Select your desired primary object. Make sure the sub-option Display RPM Gauge is ticked.

## Limitations

This add-on should work out of the box for X-Plane (or custom data) only. 

## Troubleshooting

###Gauge not appearing? 
Make sure you have selected the aircraft you are interested in as primary object (select it from the top left drop-down menu)

###Needle remains pointed at 0? 
Remember that this add-on is for use with X-Plane (or custom data) only. For custom data, use the exact case-sensitive property names "EngineRPM" and "EngineRPM2".

###Don't like the size or position of the gauge?
Note that the gauge is responsive to changes window size. To change the position and the nominal and minimum sizes, open main.lua in a text edior and change the constants NominalInstrumentWidth, NominalInstrumentHeight and MinimumWidth.