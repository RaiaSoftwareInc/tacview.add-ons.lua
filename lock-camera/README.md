# LightWave Exporter

This add-on exports currently select object position and rotation in a straightforward csv file which can be used to animate an aircraft in [LightWave](https://www.lightwave3d.com/).

## How to use it?

* Open in Tacview a telemetry file from [DCS World](https://www.digitalcombatsimulator.com) or [Falcon 4 BMS](https://www.benchmarksims.org/forum/)
* Select the object you want to export
* From the add-ons menu, select the frequency you want to export your data
* Enter the file name where you want to export the telemetry and click OK

If you don’t get any error message, the csv file should now be ready to be imported in LightWave or any similar computer graphic software.

## Output

The csv file generated by this addon includes:
* Aircraft position (x, y, z) in meters, relative to the first position. Y is the altitude.
* Aircraft rotation (roll, pitch, yaw) in cumulative degrees (no wrap).
* One sample is generated per frame of animation, at the specified frequency (the frame number as well as the corresponding timestamp is stored for each entry).

## Limitations

Because it relies on the availability of native (flat) coordinates, this add-on currently works only with DCS World and Falcon 4 BMS telemetry data.

The code could be improved to generate flat-world coordinates (x,y,z) based on object longitude and latitude.