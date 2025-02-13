
--[[
	Display Radar
	Display a radar on the primary selected object

	Author: BuzyBee
	Last update: 2025-01-28 (Tacview 1.9.4)

	Feel free to modify and improve this script!
--]]

--[[

	MIT License

	Copyright (c) 2025 Raia Software Inc.

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

local Tacview = require("Tacview194")



----------------------------------------------------------------
-- Constants
----------------------------------------------------------------

local RADAR_AZIMUTH = 0
local RADAR_ELEVATION = 0
local RADAR_ROLL = 0
local RADAR_RANGE = 0
local RADAR_HORIZONTAL_BEAMWIDTH = 60
local RADAR_VERTICAL_BEAMWIDTH = 60

local RadarRangeList = require("radar-range-list")

local previousObjectHandle0
local previousObjectHandle1

----------------------------------------------------------------
-- UI commands and options
----------------------------------------------------------------
local msgPosted = false

function OnUpdate(dt, absoluteTime)

	local objectHandle0 = Tacview.Context.GetSelectedObject(0) 
	local objectHandle1 = Tacview.Context.GetSelectedObject(1)

	if objectHandle0 then
		
		if previousObjectHandle0 and objectHandle0 ~= previousObjectHandle0 then
			ClearRadar(previousObjectHandle0)
			msgPosted = false
		end

		SetRadar(objectHandle0)
		previousObjectHandle0 = objectHandle0

	end

	if objectHandle1 then

		if previousObjectHandle1 and objectHandle1 ~= previousObjectHandle1 then
			ClearRadar(previousObjectHandle1)
			msgPosted = false
		end

		SetRadar(objectHandle1)
		previousObjectHandle1 = objectHandle1
	end
end

function SetRadar(objectHandle)

	local shortName = Tacview.Telemetry.GetCurrentShortName( objectHandle )
	
	RADAR_RANGE = RadarRangeList[shortName]

	if RADAR_RANGE then

		local absoluteTime = Tacview.Context.GetAbsoluteTime()
		
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

	else

		if not msgPosted then
			Tacview.Log.Info("Did not find any entry \"" .. shortName .. "\" in the radar-range-list.lua file")
			msgPosted = true
		end
	end
end

function ClearRadar(objectHandle)

	local radarModePropertyIndex = Tacview.Telemetry.GetObjectsNumericPropertyIndex("RadarMode", true)

	local count = Tacview.Telemetry.GetNumericSampleCount( objectHandle , radarModePropertyIndex )

	for i=count-1,0,-1 do
		Tacview.Telemetry.RemoveNumericSampleFromIndex(objectHandle , i, radarModePropertyIndex)
	end
end

function OnDocumentUnload()

previousObjectHandle0 = nil
previousObjectHandle1 = nil

end


----------------------------------------------------------------
-- Initialize this addon
----------------------------------------------------------------

function Initialize()

	-- Declare add-on information

	Tacview.AddOns.Current.SetTitle("Display Radar")
	Tacview.AddOns.Current.SetVersion("1.9.4")
	Tacview.AddOns.Current.SetAuthor("BuzyBee")
	Tacview.AddOns.Current.SetNotes("Display a radar cone.")

	-- Declare menus

	local mainMenuHandle = Tacview.UI.Menus.AddMenu(nil, "Display Radar")

	-- Register callbacks

	Tacview.Events.Update.RegisterListener(OnUpdate)
	Tacview.Events.DocumentUnload.RegisterListener(OnDocumentUnload)

end

Initialize()
