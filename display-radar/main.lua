
--[[
	Display Radar
	Display a radar on the primary selected object

	Author: BuzyBee
	Last update: 2022-08-01 (Tacview 1.8.8)

	Feel free to modify and improve this script!
--]]

--[[

	MIT License

	Copyright (c) 2022-2025 Raia Software Inc.

	Permission is hereby granted, free of charge, to any person obtaining a copy
	of this software and associated documentation files (the "Software"), to deal
	in the Software without restriction, including without limitation the rights
	to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
	copies of the Software, and to permit persons to whom the Software is
	furnished to do so, subject to the following conditions:

	The above copyright notice and this permission notice shall be included in all
	copies or substantial portions of the Software.

	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
	IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
	FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
	AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
	LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
	OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
	SOFTWARE.

--]]

require("lua-strict")

-- Request Tacview API

local Tacview = require("Tacview188")

----------------------------------------------------------------
-- Constants
----------------------------------------------------------------

local settingName = "displayRadar"

RADAR_AZIMUTH = 20
RADAR_ELEVATION = 15
RADAR_ROLL = 45
RADAR_RANGE = 296320
RADAR_HORIZONTAL_BEAMWIDTH = 40
RADAR_VERTICAL_BEAMWIDTH = 12
RANGE_GATE_MIN = 200000
RANGE_GATE_MAX = 250000

----------------------------------------------------------------
-- UI commands and options
----------------------------------------------------------------

function OnUpdate(dt, absoluteTime)

	local objectHandle = Tacview.Context.GetSelectedObject(0) or Tacview.Context.GetSelectedObject(1)
	
	if not objectHandle then
		return
	end
	
	local radarModePropertyIndex = Tacview.Telemetry.GetObjectsNumericPropertyIndex("RadarMode", true)
	
	Tacview.Telemetry.SetNumericSample(objectHandle , absoluteTime, radarModePropertyIndex , 1)
	
	local radarAzimuthPropertyIndex = Tacview.Telemetry.GetObjectsNumericPropertyIndex("RadarAzimuth", true)
	
	Tacview.Telemetry.SetNumericSample(objectHandle , absoluteTime, radarAzimuthPropertyIndex , RADAR_AZIMUTH)
	
	local radarElevationPropertyIndex = Tacview.Telemetry.GetObjectsNumericPropertyIndex("RadarElevation", true)	
	
	Tacview.Telemetry.SetNumericSample(objectHandle , absoluteTime, radarElevationPropertyIndex , RADAR_ELEVATION)
	
	local radarRollPropertyIndex = Tacview.Telemetry.GetObjectsNumericPropertyIndex("RadarRoll", true)	
	
	Tacview.Telemetry.SetNumericSample(objectHandle , absoluteTime, radarRollPropertyIndex , RADAR_ROLL)
	
	local radarRangePropertyIndex = Tacview.Telemetry.GetObjectsNumericPropertyIndex("RadarRange", true)		
	
	Tacview.Telemetry.SetNumericSample(objectHandle , absoluteTime, radarRangePropertyIndex , RADAR_RANGE)
	
	local RadarHorizontalBeamwidthPropertyIndex = Tacview.Telemetry.GetObjectsNumericPropertyIndex("RadarHorizontalBeamwidth", true)
	
	Tacview.Telemetry.SetNumericSample(objectHandle , absoluteTime, RadarHorizontalBeamwidthPropertyIndex , RADAR_HORIZONTAL_BEAMWIDTH)
	
	local RadarVerticalBeamwidthPropertyIndex = Tacview.Telemetry.GetObjectsNumericPropertyIndex("RadarVerticalBeamwidth", true)
	
	Tacview.Telemetry.SetNumericSample(objectHandle , absoluteTime, RadarVerticalBeamwidthPropertyIndex , RADAR_VERTICAL_BEAMWIDTH)
	
	local RadarRangeGateMin = Tacview.Telemetry.GetObjectsNumericPropertyIndex("RadarRangeGateMin", true)
	
	Tacview.Telemetry.SetNumericSample(objectHandle , absoluteTime, RadarRangeGateMin , RANGE_GATE_MIN)
	
	local RadarRangeGateMax = Tacview.Telemetry.GetObjectsNumericPropertyIndex("RadarRangeGateMax", true)
	
	Tacview.Telemetry.SetNumericSample(objectHandle , absoluteTime, RadarRangeGateMax , RANGE_GATE_MAX)
		
end

----------------------------------------------------------------
-- Initialize this addon
----------------------------------------------------------------

function Initialize()

	-- Declare add-on information

	Tacview.AddOns.Current.SetTitle("Display Radar")
	Tacview.AddOns.Current.SetVersion("1.8.8")
	Tacview.AddOns.Current.SetAuthor("BuzyBee")
	Tacview.AddOns.Current.SetNotes("Display a radar cone on the primary object.")

	-- Declare menus

	local mainMenuHandle = Tacview.UI.Menus.AddMenu(nil, "Display Radar")

	-- Register callbacks

	Tacview.Events.Update.RegisterListener(OnUpdate)

end

Initialize()
