
-- Display AoA in units (tutorial for 2D UI rendering)
-- Author: Erin O'Reilly
-- Last update: 2019-06-07 (Tacview 1.7.6)

-- Feel free to modify and improve this script!

--[[

MIT License

Copyright (c) 2018 Raia Software Inc.

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

require("lua-strict")

local Tacview = require("Tacview176")

----------------------------------------------------------------
-- Constants
----------------------------------------------------------------

local AddOnEnabledSettingName = "Enabled"

local scale = 1/4

local IndicatorWidth = 355 * scale
local IndicatorHeight = 975 * scale
local BarWidth = 12 * scale
local BarHeight = 130

----------------------------------------------------------------
-- "Members"
----------------------------------------------------------------

local currentAoA

local IndicatorTextureHandle
local BarTextureHandle

local IndicatorRenderStateHandle
local BarRenderStateHandle

local IndicatorVertexArrayHandle
local BarVertexArrayHandle

local IndicatorTextureCoordinateArrayHandle
local BarTextureCoordinateArrayHandle

----------------------------------------------------------------
-- UI commands and options
----------------------------------------------------------------

local addOnEnabledMenuId
local addOnEnabledOption = false

function OnMenuEnableAddOn()

	-- Change and save option

	addOnEnabledOption = not addOnEnabledOption

	Tacview.AddOns.Current.Settings.SetBoolean(AddOnEnabledSettingName, addOnEnabledOption)

	-- Update menu

	Tacview.UI.Menus.SetOption(addOnEnabledMenuId, addOnEnabledOption)

end

----------------------------------------------------------------
-- 2D Rendering
----------------------------------------------------------------

function DeclareRenderData()

	-- Only one texture is used, it contains all the different states.

	if not IndicatorTextureHandle then

		IndicatorTextureHandle = Tacview.UI.Renderer.LoadTexture("AddOns/f14-aoa-indicator/textures/indicator-bar.png", false)
		
		Tacview.Log.Debug("IndicatorTextureHandle: ", IndicatorTextureHandle)

	end
	
	if not BarTextureHandle then

		BarTextureHandle = Tacview.UI.Renderer.LoadTexture("AddOns/f14-aoa-indicator/textures/indicator-background.png", false)
		
		Tacview.Log.Debug("BarTextureHandle: ", BarTextureHandle)

	end

	-- The render state is used to define how to draw the instrument.
	-- We only need to specify the texture in our case.

	if not IndicatorRenderStateHandle then

		local renderState =
		{
			texture = IndicatorTextureHandle,
		}

		IndicatorRenderStateHandle = Tacview.UI.Renderer.CreateRenderState(renderState)

	end
	
	if not BarRenderStateHandle then

		local renderState =
		{
			texture = BarTextureHandle,
		}

		BarRenderStateHandle = Tacview.UI.Renderer.CreateRenderState(renderState)

	end

	-- The following list of vertices is used to define the square shape of the instrument using two triangles.

	if not IndicatorVertexArrayHandle then

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

		IndicatorVertexArrayHandle = Tacview.UI.Renderer.CreateVertexArray(vertexArray)

	end

	if not BarVertexArrayHandle then

		local HalfWidth = BarWidth / 2
		local HalfHeight = BarHeight / 2

		local vertexArray =
		{
			-HalfWidth, BarHeight, 0.0,
			-HalfWidth, 0.0, 0.0,
			HalfWidth, 0.0, 0.0,
			-HalfWidth, BarHeight, 0.0,
			HalfWidth, BarHeight, 0.0,
			HalfWidth, 0.0, 0.0,
		}

		BarVertexArrayHandle = Tacview.UI.Renderer.CreateVertexArray(vertexArray)

	end

	-- We animate the instrument by changing the textures coordinates
	-- to display another portion of the texture.

	if not IndicatorTextureCoordinateArrayHandle then

		local baseTextureArray =
		{
			0.0, 0.0,
			0.0, 1.0,
			1.0, 1.0,
			0.0, 0.0,
			1.0, 0.0,
			1.0, 1.0,
		}

		IndicatorTextureCoordinateArrayHandle = Tacview.UI.Renderer.CreateTextureCoordinateArray(baseTextureArray)
	
	end
	
	if not BarTextureCoordinateArrayHandle then

		local baseTextureArray =
		{
			0.0, 0.0,
			0.0, 1.0,
			1.0, 1.0,
			0.0, 0.0,
			1.0, 0.0,
			1.0, 1.0,
		}

		BarTextureCoordinateArrayHandle = Tacview.UI.Renderer.CreateTextureCoordinateArray(baseTextureArray)
	
	end
end

function OnDrawTransparentUI()

	-- Data available?
	
	
	if not currentAoA then
		return
	end

	-- Calculate AoA index
	-- NOTE: Tacview return an AoA in radian

	-- The following values are based on DCS World F/A-18C documentation for demonstration purpose.
	-- Possible addon improvement:
	-- These values could be dynamically adjusted depending on the plane type/designation (F-16, F-14...)
	
	-- http://www.heatblur.se/F-14Manual/cockpit.html#angle-of-attack-indicator
	
	local currentAoAUnits = (30/50)*(math.deg(currentAoA)+10) 
	
	if currentAoAUnits < 0 then currentAoAUnits=0 end
	
	if currentAoAUnits>30 then currentAoAUnits=30 end
	
	print("currentAoaUnits:",currentAoAUnits, ", currentAoA: ", math.deg(currentAoA))

	-- Make sure rendering data are declared (only once, during the first OnDrawTransparentUI call)

	DeclareRenderData()

	-- Draw Indicator

	-- Possible improvement:
	-- We could display the AoA value only when the gear is down

	local rendererHeight = Tacview.UI.Renderer.GetHeight()
	local rendererWidth = Tacview.UI.Renderer.GetWidth()
	
	print("rendererHeight, rendererWidth: ", rendererHeight, ", ", rendererWidth)

	local transformIndicator =
	{
		x = 32 + IndicatorWidth / 2,
		y = rendererHeight / 2,
		scale = 1,
	}
	
	Tacview.UI.Renderer.DrawUIVertexArray(transformIndicator, IndicatorRenderStateHandle, IndicatorVertexArrayHandle, IndicatorTextureCoordinateArrayHandle)

	local transformBar =
	{
		x = IndicatorWidth / 2 + 36,  
		y = rendererHeight / 2 - 70,
		scaleY = currentAoAUnits/30,
		
	}
	
	Tacview.UI.Renderer.DrawUIVertexArray(transformBar, BarRenderStateHandle, BarVertexArrayHandle, BarTextureCoordinateArrayHandle)

end

----------------------------------------------------------------
-- Main loop
----------------------------------------------------------------

-- Update is called once a frame by Tacview

function OnUpdate(dt, absoluteTime)

	-- Add-on enabled?
	
	currentAoA = nil

	if not addOnEnabledOption then

		return

	end

	-- This add-on is active only when one of the selected objects is a plane

	local objectHandle = Tacview.Context.GetSelectedObject(0)

	if not objectHandle or (Tacview.Telemetry.GetCurrentTags(objectHandle) & Tacview.Telemetry.Tags.FixedWing) == 0 then

		objectHandle = Tacview.Context.GetSelectedObject(1)

		if not objectHandle or (Tacview.Telemetry.GetCurrentTags(objectHandle) & Tacview.Telemetry.Tags.FixedWing) == 0 then

			return

		end

	end
	
	local objectName = Tacview.Telemetry.GetCurrentShortName( objectHandle )
	
	local function starts_with(str, start)
		return str:sub(1, #start) == start
	end

	
	if not starts_with(objectName,"F-14") then return end
	
	-- Retrieve AoA if available

	currentAoA = Tacview.Telemetry.GetCurrentAngleOfAttack(objectHandle)
	

end

----------------------------------------------------------------
-- Initialize this addon
----------------------------------------------------------------

function Initialize()

	-- Declare addon properties

	local currentAddOn = Tacview.AddOns.Current

	currentAddOn.SetTitle("Display AOA in Units")
	currentAddOn.SetVersion("1.8.0")
	currentAddOn.SetAuthor("BuzyBee")
	currentAddOn.SetNotes("Displays AoA in units instead of degrees.")

	-- Load preferences
	-- Use current addOnEnabledOption value as the default setting

	addOnEnabledOption = Tacview.AddOns.Current.Settings.GetBoolean(AddOnEnabledSettingName, addOnEnabledOption)

	-- Declare menus

	local addOnMenuId = Tacview.UI.Menus.AddMenu(nil, "AoA in Units")
	addOnEnabledMenuId = Tacview.UI.Menus.AddOption(addOnMenuId, "Display AoA in Units", addOnEnabledOption, OnMenuEnableAddOn)

	-- Register callbacks

	Tacview.Events.Update.RegisterListener(OnUpdate)

	Tacview.Events.DrawTransparentUI.RegisterListener(OnDrawTransparentUI)

end

Initialize()
