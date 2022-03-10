
--[[
	AoA unit cockpit indicator
	Displays AoA in units like in the F-14B cockpit

	Author: BuzyBee
	Last update: 2019-06-17 (Tacview 1.8.0)

	Feel free to modify and improve this script!
--]]

--[[

	MIT License

	Copyright (c) 2019 Raia Software Inc.

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

local Tacview = require("Tacview180")

----------------------------------------------------------------
-- Constants
----------------------------------------------------------------

local DisplayAOAUnitsSettingName = "DisplayAOAUnits"

local GlobalScale = 1

local IndicatorWidth = 128 * GlobalScale
local IndicatorHeight = 256 * GlobalScale

local TapeWidth = 8 * GlobalScale
local TapeHeight = 130 * GlobalScale

----------------------------------------------------------------
-- "Members"
----------------------------------------------------------------

local currentAoAUnits

local indicatorTextureHandle
local indicatorRenderStateHandle
local indicatorVertexArrayHandle
local indicatorTextureCoordinateArrayHandle

local tapeRenderStateHandle
local tapeVertexArrayHandle

local telemetry = Tacview.Telemetry

----------------------------------------------------------------
-- UI commands and options
----------------------------------------------------------------

local displayAOAUnitsMenuId
local displayAOAUnits = true

function OnMenuEnableAddOn()

	-- Enable/disable add-on

	displayAOAUnits = not displayAOAUnits

	-- Save option value in registry

	Tacview.AddOns.Current.Settings.SetBoolean(DisplayAOAUnitsSettingName, displayAOAUnits)

	-- Update menu with the new option value

	Tacview.UI.Menus.SetOption(displayAOAUnitsMenuId, displayAOAUnits)

end

----------------------------------------------------------------
-- Load and compile any resource required to draw the instrument
----------------------------------------------------------------

function DeclareRenderData()

	-- Load the instrument background texture as required

	if not indicatorTextureHandle then

		local addOnPath = Tacview.AddOns.Current.GetPath()
		indicatorTextureHandle = Tacview.UI.Renderer.LoadTexture(addOnPath.."textures/indicator-background.png", false)

	end

	-- Declare the render states for the instrument indicator and tape.
	-- The render state is used to define how to draw our 2D models.

	if not indicatorRenderStateHandle then

		local renderState =
		{
			texture = indicatorTextureHandle,
		}

		indicatorRenderStateHandle = Tacview.UI.Renderer.CreateRenderState(renderState)

	end

	if not tapeRenderStateHandle then

		-- Display the tape with a HUD green like color.
		-- No texture is required for the tape.

		local renderState =
		{
			color = 0xFFA0FF46,		-- AABBGGRR
		}

		tapeRenderStateHandle = Tacview.UI.Renderer.CreateRenderState(renderState)

	end

	-- The following list of vertices is used to define the square shape of the instrument using two triangles.

	if not indicatorVertexArrayHandle then

		local HalfWidth = IndicatorWidth / 2
		local HalfHeight = IndicatorHeight / 2

		local vertexArray =
		{
			-HalfWidth, HalfHeight, 0.0,
			-HalfWidth, -HalfHeight, 0.0,
			HalfWidth, -HalfHeight, 0.0,
			-HalfWidth, HalfHeight, 0.0,
			HalfWidth, HalfHeight, 0.0,
			HalfWidth, -HalfHeight, 0.0,
		}

		indicatorVertexArrayHandle = Tacview.UI.Renderer.CreateVertexArray(vertexArray)

	end

	-- Same for the instrument tape.
	-- TapeHeight is the maximum tape height (in pixels) for when the AOA Units will be 30

	if not tapeVertexArrayHandle then

		local HalfWidth = TapeWidth / 2

		local vertexArray =
		{
			-HalfWidth, TapeHeight, 0.0,
			-HalfWidth, 0.0, 0.0,
			HalfWidth, 0.0, 0.0,
			-HalfWidth, TapeHeight, 0.0,
			HalfWidth, TapeHeight, 0.0,
			HalfWidth, 0.0, 0.0,
		}

		tapeVertexArrayHandle = Tacview.UI.Renderer.CreateVertexArray(vertexArray)

	end

	-- Declare the textures coordinates to project the instrument image on a rectangle made of two triangles.

	if not indicatorTextureCoordinateArrayHandle then

		local baseTextureArray =
		{
			0.0, 0.0,
			0.0, 1.0,
			1.0, 1.0,
			0.0, 0.0,
			1.0, 0.0,
			1.0, 1.0,
		}

		indicatorTextureCoordinateArrayHandle = Tacview.UI.Renderer.CreateTextureCoordinateArray(baseTextureArray)

	end
end

----------------------------------------------------------------
-- Draw the instrument during transparent UI rendering pass
----------------------------------------------------------------

function OnDrawTransparentUI()

	-- Any AOA Units to display?

	if not currentAoAUnits then
		return
	end

	-- More about the F-14B AOA Unit indicator in DCS World documentation:

	-- http://www.heatblur.se/F-14Manual/cockpit.html#angle-of-attack-indicator
	-- Tape indicating angle of attack (AOA) on a scale of 0 to 30 units. (Equivalent to -10° to +40° rotation of the AoA probe.)

	-- Clamp AOA Units

	if currentAoAUnits < 0 then

		currentAoAUnits = 0

	elseif currentAoAUnits > 30 then

		currentAoAUnits = 30

	end

	-- Make sure rendering data are declared
	-- This includes textures, 3d models, ...

	DeclareRenderData()

	-- Draw Indicator

	local rendererHeight = Tacview.UI.Renderer.GetHeight()

	local indicatorTransform =
	{
		x = 32 + IndicatorWidth / 2,
		y = rendererHeight / 2,
		scale = 1,
	}

	Tacview.UI.Renderer.DrawUIVertexArray(indicatorTransform, indicatorRenderStateHandle, indicatorVertexArrayHandle, indicatorTextureCoordinateArrayHandle)

	local tapeTransform =
	{
		x = 32 + IndicatorWidth / 2 + 2,
		y = rendererHeight / 2 - IndicatorHeight / 2 + 29,
		scaleY = 174 / TapeHeight / GlobalScale * currentAoAUnits / 30,
	}

	Tacview.UI.Renderer.DrawUIVertexArray(tapeTransform, tapeRenderStateHandle, tapeVertexArrayHandle, nil)

end

----------------------------------------------------------------
-- Main loop
----------------------------------------------------------------

-- Update is called once a frame by Tacview
-- Here we retrieve current aircraft AOA unit value which will be displayed by OnDrawTransparentUI()

function OnUpdate(dt, absoluteTime)

	currentAoAUnits = nil

	-- Verify that the user wants to display AOA Units

	if not displayAOAUnits then

		return

	end

	-- Indicator will be displayed only when one of the selected objects is a plane

	local objectHandle = Tacview.Context.GetSelectedObject(0)

	if not objectHandle then return end

	local tags = telemetry.GetCurrentTags(objectHandle)

	if not tags then return end

	if not telemetry.AnyGivenTagActive(tags, telemetry.Tags.FixedWing) then return end

	-- Check if the aircraft is a F-14
	-- This add-on would work for other aircraft, but we would probably need to update our instrument scale.

	local objectName = telemetry.GetCurrentShortName( objectHandle )

	local function StartsWith(str, start)

		return str:sub(1, #start) == start

	end

	if not StartsWith(objectName,"F-14") then

		return

	end

	-- Retrieve AoA Units property index

	local aoaUnitsPropertyIndex = telemetry.GetObjectsNumericPropertyIndex("AOAUnits", false)

	if aoaUnitsPropertyIndex == telemetry.InvalidPropertyIndex then

		-- no AOAUnits available for this aircraft
		return

	end

	-- Retrieve AoA Units sample for that aircraft at that time

	local sampleIsValid

	currentAoAUnits, sampleIsValid = telemetry.GetNumericSample(objectHandle, absoluteTime, aoaUnitsPropertyIndex)

	if not sampleIsValid then

		-- If there is no real sample available at that time,
		-- then ignore the extrapolated value provided by Tacview.

		currentAoAUnits = nil
		return

	end

end

----------------------------------------------------------------
-- Initialize this addon
----------------------------------------------------------------

function Initialize()

	-- Declare add-on information

	Tacview.AddOns.Current.SetTitle("Display AOA in Units")
	Tacview.AddOns.Current.SetVersion("1.8.0")
	Tacview.AddOns.Current.SetAuthor("BuzyBee")
	Tacview.AddOns.Current.SetNotes("Displays AoA in units instead of degrees.")

	-- Load user preferences
	-- The variable displayAOAUnits already contain the default setting

	displayAOAUnits = Tacview.AddOns.Current.Settings.GetBoolean(DisplayAOAUnitsSettingName, displayAOAUnits)

	-- Declare menus
	-- Create a main menu "AoA Indicator"
	-- Then insert in it an option to display or not the indicator

	local mainMenuId = Tacview.UI.Menus.AddMenu(nil, "AoA Indicator")
	displayAOAUnitsMenuId = Tacview.UI.Menus.AddOption(mainMenuId, "Display AoA in Units", displayAOAUnits, OnMenuEnableAddOn)

	-- Register callbacks

	Tacview.Events.Update.RegisterListener(OnUpdate)
	Tacview.Events.DrawTransparentUI.RegisterListener(OnDrawTransparentUI)

end

Initialize()
