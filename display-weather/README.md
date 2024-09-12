# Display Weather

This add-on, for use with DCS, displays the following weather data in the 3D view where available:

* QNH 
* QFE, wind speed (in knots) and direction for local aircraft 
* QFE, wind speed (in knots) and direction for exportable objects labelled "WindProbe"

## How to use it?

* Build your mission in DCS Mission Editor.
** Make sure to add weather with wind - it might not be there by default.
** To add a WindProbe, add a ground vehicle or other exportable object next to the runway or wherever you want get the wind. Name it something that includes the word "WindProbe".

* Fly your mission, activate the add-on and see weather data appear in the 3D view.

## Limitations

When flying on a multiplayer server, weather data may be available for your local aircraft but not for the WindProbe objects. It seems that DCS does not export wind in multiplayer (except in close proximity of the local aircraft), probably to save bandwidth.

## FAQ: Where did you get that QFE value?

To calculate QFE from the QNH provided by DCS World, we used these formulas:
https://www.sensorsone.com/elevation-station-qfe-sea-level-qnh-pressure-calculator/		
		