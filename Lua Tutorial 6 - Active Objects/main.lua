
-- Lua Tutorial 6 - Active Objects enumeration
-- Author: Frantz 'Vyrtuoz' RAIA
-- Last update: 2018-09-25 (Tacview 1.7.3)

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

local Tacview = require("Tacview173")

----------------------------------------------------------------
-- Constants
----------------------------------------------------------------

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

-- Statistics about currently active objects

local activeObjectCount = 0

local fixedWingCount = 0
local rotorcraftCount = 0
local antiAircraftCount = 0

-- Drawing data

local statisticsRenderStateHandle

----------------------------------------------------------------
-- 2D Rendering
----------------------------------------------------------------

function OnDrawTransparentUI()

	-- Any active object

	if activeObjectCount == 0 then
		return
	end

	-- Compile render state

	if not statisticsRenderStateHandle then

		statisticsRenderStateHandle = Tacview.UI.Renderer.CreateRenderState(StatisticsRenderState)

	end

	-- Display active objects statistics

	local renderer = Tacview.UI.Renderer

	local statisticsText = "Active objects: "..OrangeColor..activeObjectCount..DefaultColor
						.."\nFixedWing objects: "..OrangeColor..fixedWingCount..DefaultColor
						.."\nRotorcraft objects: "..OrangeColor..rotorcraftCount..DefaultColor
						.."\nAnti-Aircraft objects: "..OrangeColor..antiAircraftCount

	local transform =
	{
		x = Margin,
		y = (renderer.GetHeight() + 4 * FontSize) / 2,
		scale = FontSize,
	}

	renderer.Print(transform, statisticsRenderStateHandle, statisticsText)

end

----------------------------------------------------------------
-- Main loop
----------------------------------------------------------------

-- Update is called once a frame by Tacview

function OnUpdate(dt, absoluteTime)

	-- Cache Tacview API (optimization)

	local tags = Tacview.Telemetry.Tags
	local getCurrentTags = Tacview.Telemetry.GetCurrentTags

	-- Retrieve the list of currently active (alive) objects

	local activeObjectList = Tacview.Context.GetActiveObjectList()

	-- Calculate object count per type

	activeObjectCount = 0

	fixedWingCount = 0
	rotorcraftCount = 0
	antiAircraftCount = 0

	for objectIndex,objectHandle in pairs(activeObjectList) do

		local objectTags = getCurrentTags(objectHandle)

		activeObjectCount = activeObjectCount + 1

		-- Tacview.Telemetry.GetCurrentTags() returns a bitfield indicating all the tags associated to the given object.
		-- Use can then use bitwise operators and Tacview.Telemetry.Tags to efficiently analyze the object type.

		if (objectTags & tags.FixedWing) ~= 0 then

			fixedWingCount = fixedWingCount + 1

		elseif (objectTags & tags.Rotorcraft) ~= 0 then

			rotorcraftCount = rotorcraftCount + 1

		elseif (objectTags & tags.AntiAircraft) ~= 0 then

			antiAircraftCount = antiAircraftCount + 1

		end
	end
end

----------------------------------------------------------------
-- Initialize this addon
----------------------------------------------------------------

function Initialize()

	-- Declare addon properties

	local currentAddOn = Tacview.AddOns.Current

	currentAddOn.SetTitle("Active Objects Statistics")
	currentAddOn.SetVersion("1.7.3")
	currentAddOn.SetAuthor("Vyrtuoz")
	currentAddOn.SetNotes("Display statistics about currently active objects.")

	-- Register callbacks

	Tacview.Events.Update.RegisterListener(OnUpdate)

	Tacview.Events.DrawTransparentUI.RegisterListener(OnDrawTransparentUI)

end

Initialize()
