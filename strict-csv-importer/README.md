# Strict CSV Importer

This add-on allows you to import CSV files that can include any object text or numeric property, unlike Tacview’s native CSV importer, which supports only a limited number of fields:  
<https://tacview.net/documentation/csv/>

- **Load**: Clears any existing telemetry and loads one or more strict CSV files.
- **Merge**: Keeps existing telemetry and merges one or more strict CSV files into it.

## Required Format

Each CSV file must contain data for **one object**.

The first line must include headers separated by commas. The headers may be in any order. 

Include time data in one of the following two formats:

`Unix time` - Unix timestamp
`ISO time` - ISO time

Include position data (mandatory):
 
`Longitude` - Longitude in degrees
`Latitude` - Latitude in degrees
`Altitude` - Altitude in meters

Include roll, pitch and yaw if you have it:

`Roll` - Roll in degrees
`Pitch` - Pitch in degrees
`Yaw` - Yaw in degrees

You can add unlimited additional columns.

- Additional column headers must exactly match an existing **text** or **numeric** object property name as defined in the documentation:  
  <https://tacview.net/documentation/acmi/>. Be sure to use the units which are specified in the documentation.
	- For **numeric properties**, add a `#` at the beginning.  
		Example: `#IAS` (in meters)
	- For **text properties**, use the property name as-is.  
		Example: `Color` (must be Red, Orange, Yellow, Green, Cyan, Blue, or Violet)

### Example

A CSV with 11 columns (7 mandatory + 4 additional):

```csv
Unix time,Longitude,Latitude,Altitude,Roll,Pitch,Yaw,Color,#TAS,Country,#Mach
```