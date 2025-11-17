
-- Lua Tutorial 12 - IsPlaneInside
-- Author: Frantz 'Vyrtuoz' RAIA
-- Last update: 2022-10-11 (Tacview 1.9.0)

--[[

	This little addon shows how to use the static objects function IsPointInside()
	to know if an object is in a specified zone. This can be used to know in real-time
	if a plane enters a prohibited area. As well as to estimate the total time in a given area.

	This example is not optimal, we should cache the time on zone calculation.
	With a proper cache, we could increase the resolution on time on zone to 1 second for example.

--]]

--[[

MIT License

Copyright (c) 2018-2025 Raia Software Inc.

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

----------------------------------------------------------------
-- Setup
----------------------------------------------------------------

require("LuaStrict")

local Tacview = require("Tacview190")

----------------------------------------------------------------
-- Constants
----------------------------------------------------------------

local RegionName1 = "ZONE01"
local RegionName2 = "ZONE02"
local SumResolution = 10.0		-- resolution of total time in region, in seconds

-- Special control characters to change the text color on the fly

local OrangeColor = string.char(2)
local DefaultColor = string.char(1)

local Margin = 16
local FontSize = 32
local FontColor = 0xFFA0FF46		-- HUD style green

local StatisticsRenderState =
{
	color = FontColor,
	blendMode = Tacview.UI.Renderer.BlendMode.Additive,
}

----------------------------------------------------------------
-- "Members"
----------------------------------------------------------------

local regionObjectFound = false
local selectedObjectIsValid = false
local selectedObjectIsInRegion1 = false
local selectedObjectIsInRegion2 = false

local totalTimeInRegion1 = 0.0
local totalTimeInRegion2 = 0.0

-- Drawing data

local statisticsRenderStateHandle

----------------------------------------------------------------
-- 2D Rendering
----------------------------------------------------------------

function OnDrawTransparentUI()

	local renderer = Tacview.UI.Renderer

	-- Compile render state

	if not statisticsRenderStateHandle then

		statisticsRenderStateHandle = renderer.CreateRenderState(StatisticsRenderState)

	end

	-- Display active objects statistics

	local text

	if not regionObjectFound then

		text = "Please load a static object\nwith the name "..OrangeColor..RegionName1..DefaultColor.." or "..OrangeColor..RegionName2

	elseif not selectedObjectIsValid then

		text = "Please select the object you want\nto check if in "..OrangeColor..RegionName1..DefaultColor.." or "..OrangeColor..RegionName2

	else

		text = "Primary object is "

		if selectedObjectIsInRegion1 then

			text = text.."in "..OrangeColor..RegionName1

		elseif selectedObjectIsInRegion2 then

			text = text.."in "..OrangeColor..RegionName2

		else

			text = text.."outside of loaded regions."

		end

		text = text.."\n"..DefaultColor
		text = text.."\nTotal time in "..OrangeColor..RegionName1..DefaultColor..": "..totalTimeInRegion1.."s"
		text = text.."\nTotal time in "..OrangeColor..RegionName2..DefaultColor..": "..totalTimeInRegion2.."s"
	end

	local transform =
	{
		x = Margin,
		y = (renderer.GetHeight() + 4 * FontSize) / 2,
		scale = FontSize,
	}

	renderer.Print(transform, statisticsRenderStateHandle, text)

end

----------------------------------------------------------------
-- Main loop
----------------------------------------------------------------

-- Retrieve total zone in specified region

function GetTotalTimeInRegion( regionHandle, objectHandle )

	local GetTransform = Tacview.Telemetry.GetTransform
	local IsPointInside = Tacview.StaticObjects.IsPointInside

	-- TODO: check parameters
	-- TODO: cache by checking if object and lifespawn has changed for example

	local firstTransformSampleTime, lastTransformSampleTime = Tacview.Telemetry.GetTransformTimeRange( objectHandle )

	if firstTransformSampleTime <= Tacview.Telemetry.BeginningOfTime or lastTransformSampleTime >= Tacview.Telemetry.EndOfTime then

		-- Intemporal objects (such as bullseye) are not supported
		return 0.0
	end

	local timeInRegion = 0.0

	for currentTime = firstTransformSampleTime, lastTransformSampleTime, SumResolution do

		local objectTransform = GetTransform( objectHandle, currentTime )

		if objectTransform then

			if IsPointInside( regionHandle, objectTransform.longitude, objectTransform.latitude, objectTransform.altitude) == true then
				
				timeInRegion = timeInRegion + SumResolution

			end
		end
	end

	return timeInRegion
end

-- Update is called once a frame by Tacview

function OnUpdate(dt, absoluteTime)

	-- Retrieve region object

	regionObjectFound = false

	local region1Handle = Tacview.StaticObjects.GetObjectHandleByName( RegionName1 )
	local region2Handle = Tacview.StaticObjects.GetObjectHandleByName( RegionName2 )

	if not region1Handle and not region2Handle then
		return
	end

	regionObjectFound = true

	-- Retrieve currently selected object position

	selectedObjectIsValid = false

	local selectedObjectHandle = Tacview.Context.GetSelectedObject(0)

	if not selectedObjectHandle then 
		return
	end

	local selectedObjectTransform = Tacview.Telemetry.GetCurrentTransform( selectedObjectHandle )

	if not selectedObjectTransform then
		return
	end

	selectedObjectIsValid = true

	-- Check if object is in region

	selectedObjectIsInRegion1 = false

	if region1Handle then
		selectedObjectIsInRegion1 = Tacview.StaticObjects.IsPointInside( region1Handle, selectedObjectTransform.longitude, selectedObjectTransform.latitude, selectedObjectTransform.altitude)
		totalTimeInRegion1 = GetTotalTimeInRegion( region1Handle, selectedObjectHandle )
	end

	selectedObjectIsInRegion2 = false

	if region2Handle then
		selectedObjectIsInRegion2 = Tacview.StaticObjects.IsPointInside( region2Handle, selectedObjectTransform.longitude, selectedObjectTransform.latitude, selectedObjectTransform.altitude)
		totalTimeInRegion2 = GetTotalTimeInRegion( region2Handle, selectedObjectHandle )
	end
end

----------------------------------------------------------------
-- Initialize this addon
----------------------------------------------------------------

function Initialize()

	-- Declare addon properties

	local currentAddOn = Tacview.AddOns.Current

	currentAddOn.SetTitle("Lua Tutorial 12 - IsPlaneInside")
	currentAddOn.SetVersion("1.9.0")
	currentAddOn.SetAuthor("Vyrtuoz")
	currentAddOn.SetNotes("Check is primary object is inside ZONE01 static object1.")

	-- Register callbacks

	Tacview.Events.Update.RegisterListener(OnUpdate)

	Tacview.Events.DrawTransparentUI.RegisterListener(OnDrawTransparentUI)

end

Initialize()
