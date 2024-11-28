
--[[
	ENL Indicator
	Displays current ENL

	Author: BuzyBee
	Last update: 2020-02-04 (Tacview 1.8.6)

	Feel free to modify and improve this script!
--]]

--[[

	MIT License

	Copyright (c) 2020 Raia Software Inc.

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

local Tacview = require("Tacview186")

----------------------------------------------------------------
-- Constants
----------------------------------------------------------------

local DisplayENLSettingName = "DisplayENL"

----------------------------------------------------------------
-- UI commands and options
----------------------------------------------------------------

local displayENLMenuId
local displayENL = true
local currentENL
local currentAltitude


function OnMenuEnableAddOn()

	-- Enable/disable add-on

	displayENL = not displayENL

	-- Save option value in registry

	Tacview.AddOns.Current.Settings.SetBoolean(DisplayENLSettingName, displayENL)

	-- Update menu with the new option value

	Tacview.UI.Menus.SetOption(displayENLMenuId, displayENL)

end

local Margin = 16
local FontSize = 36
local FontColor = 0xff0000ff		-- Opaque Red

local StatisticsRenderState =
{
	color = FontColor,
	blendMode = Tacview.UI.Renderer.BlendMode.Normal,
}

local statisticsRenderStateHandle

function OnDrawTransparentUI()

	if not displayENL then
		return
	end

	-- Compile render state

	if not statisticsRenderStateHandle then

		statisticsRenderStateHandle = Tacview.UI.Renderer.CreateRenderState(StatisticsRenderState)

	end

	local renderer = Tacview.UI.Renderer

	local transform =
	{
		x = renderer.GetWidth() / 2,
		y = renderer.GetHeight() / 15,
		scale = FontSize,
	}

	if not currentENL and not currentAltitude then
				
		renderer.Print(transform, statisticsRenderStateHandle, "ENL:          ALT:")

	elseif not currentENL then

		renderer.Print(transform, statisticsRenderStateHandle, "ENL:          ALT: "..currentAltitude.." m")

	elseif not currentAltitude then 

		renderer.Print(transform, statisticsRenderStateHandle, "ENL: "..currentENL.."     ALT:" )

	else

		renderer.Print(transform, statisticsRenderStateHandle, "ENL: "..currentENL.."     ALT: "..currentAltitude.." m" )
	end

end

----------------------------------------------------------------
-- Main loop
----------------------------------------------------------------

-- Update is called once a frame by Tacview
-- Here we retrieve current ENL which will be displayed by OnDrawTransparentUI()

function OnUpdate(dt, absoluteTime)

	currentENL = nil
	currentAltitude = nil

	-- Verify that the user wants to display ENL

	if not displayENL then

		return

	end

	-- Indicator will be displayed only when one of the selected objects is a plane

	local objectHandle = Tacview.Context.GetSelectedObject(0)

	if not objectHandle or not Tacview.Telemetry.AnyGivenTagActive(Tacview.Telemetry.GetCurrentTags(objectHandle), Tacview.Telemetry.Tags.FixedWing) then

		objectHandle = Tacview.Context.GetSelectedObject(1)

		if not objectHandle or not Tacview.Telemetry.AnyGivenTagActive(Tacview.Telemetry.GetCurrentTags(objectHandle), Tacview.Telemetry.Tags.FixedWing) then

			return

		end

	end

	-- Retrieve ENL property index

	local enlPropertyIndex = Tacview.Telemetry.GetObjectsNumericPropertyIndex("ENL", false)

	if enlPropertyIndex == Tacview.Telemetry.InvalidPropertyIndex then

		-- no ENL available for this aircraft
		--return

	end

	-- Retrieve ENL for that aircraft at that time

	local sampleIsValid

	currentENL, sampleIsValid = Tacview.Telemetry.GetNumericSample(objectHandle, absoluteTime, enlPropertyIndex)

	if not sampleIsValid then

		-- If there is no real sample available at that time,
		-- then ignore the extrapolated value provided by Tacview.

		currentENL = nil
		--return

	end

	if currentENL then

		currentENL = math.floor( ((999-10) * currentENL + 10) + 0.5)
	end

	local transform = Tacview.Telemetry.GetCurrentTransform(objectHandle)

	currentAltitude = math.floor(transform.altitude + 0.5)
	

end

----------------------------------------------------------------
-- Initialize this addon
----------------------------------------------------------------

function Initialize()

	-- Declare add-on information

	Tacview.AddOns.Current.SetTitle("Display ENL")
	Tacview.AddOns.Current.SetVersion("1.8.6")
	Tacview.AddOns.Current.SetAuthor("BuzyBee")
	Tacview.AddOns.Current.SetNotes("Displays ENL.")

	-- Load user preferences
	-- The variable displayENL already contain the default setting

	displayENL = Tacview.AddOns.Current.Settings.GetBoolean(DisplayENLSettingName, displayENL)

	-- Declare menus

	local mainMenuId = Tacview.UI.Menus.AddMenu(nil, "ENL Indicator")
	displayENLMenuId = Tacview.UI.Menus.AddOption(mainMenuId, "Display ENL", displayENL, OnMenuEnableAddOn)

	-- Register callbacks

	Tacview.Events.Update.RegisterListener(OnUpdate)
	Tacview.Events.DrawTransparentUI.RegisterListener(OnDrawTransparentUI)

end

Initialize()
