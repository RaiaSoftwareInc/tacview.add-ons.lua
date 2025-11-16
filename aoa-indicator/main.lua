
--[[
	AoA Indicator
	Displays an AoA indicator in the 3D view

	Author: BuzyBee
	Last update: 2023-05-12 (Tacview 1.9.0)

	Feel free to modify and improve this script!
--]]

--[[

	MIT License

	Copyright (c) 2023-2025 Raia Software Inc.

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

local Tacview = require("Tacview190")

----------------------------------------------------------------
-- Constants
----------------------------------------------------------------

local settingName = "displayIndicator"

local GlobalScale = 1

local IndicatorWidth = 128 * GlobalScale
local IndicatorHeight = 256 * GlobalScale

local Margin = 32

local TapeWidth = 8 * GlobalScale
local MaximumTapeHeight = 130 * GlobalScale

----------------------------------------------------------------
-- "Members"
----------------------------------------------------------------

local currentAOA
local previousAOA

local indicatorTextureHandle
local indicatorRenderStateHandle
local indicatorVertexArrayHandle
local indicatorTextureCoordinateArrayHandle

local tapeRenderStateHandle
local tapeVertexArrayHandle

----------------------------------------------------------------
-- UI commands and options
----------------------------------------------------------------

local displayAOAIndicatorMenuId
local addOnEnabled = true

function OnMenuEnableAddOn()

	-- Enable/disable add-on

	addOnEnabled = not addOnEnabled

	-- Save option value in registry

	Tacview.AddOns.Current.Settings.SetBoolean(settingName, addOnEnabled)

	-- Update menu with the new option value

	Tacview.UI.Menus.SetOption(displayAOAIndicatorMenuId, addOnEnabled)

end

----------------------------------------------------------------
-- Load and compile any resource required to draw the instrument
----------------------------------------------------------------

function DeclareRenderData()

	local renderer = Tacview.UI.Renderer

	if not Tacview.Context.GetSelectedObject(0) then
		return
	end

	-- Load the instrument background texture as required
	
	if not indicatorTextureHandle then

		local addOnPath = Tacview.AddOns.Current.GetPath()
		indicatorTextureHandle = renderer.LoadTexture(addOnPath.."textures/indicator-background-degrees-negative.png", false)

	end

	-- Declare the render states for the instrument indicator and tape.
	-- The render state is used to define how to draw our 2D models.
	
	if not indicatorRenderStateHandle then

		local renderState =
		{
			texture = indicatorTextureHandle,
		}

		indicatorRenderStateHandle = renderer.CreateRenderState(renderState)

	end
	
	if not tapeRenderStateHandle then

		-- Display the tape with a HUD green or red like color.
		-- No texture is required for the tape.

		local renderState
		
		if currentAOA then

		
			if currentAOA >=0 then
			
				renderState =
				{
					color = 0xFFA0FF46,		-- Green AABBGGRR Green
				}		
			else
				renderState =
				{
					color = 0xFF0000F3,		-- Red AABBGGRR 
				}
			end		
	
			tapeRenderStateHandle = renderer.CreateRenderState(renderState)
		end
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
		
		indicatorVertexArrayHandle = renderer.CreateVertexArray(vertexArray)

	end

	-- Same for the instrument tape.

	if not tapeVertexArrayHandle then

		local HalfWidth = TapeWidth / 2

		local vertexArray =
		{
			-HalfWidth, MaximumTapeHeight, 0.0,
			-HalfWidth, 0.0, 0.0,
			HalfWidth, 0.0, 0.0,
			-HalfWidth, MaximumTapeHeight, 0.0,
			HalfWidth, MaximumTapeHeight, 0.0,
			HalfWidth, 0.0, 0.0,
		}

		tapeVertexArrayHandle = renderer.CreateVertexArray(vertexArray)

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

		indicatorTextureCoordinateArrayHandle = renderer.CreateTextureCoordinateArray(baseTextureArray)

	end
end

----------------------------------------------------------------
-- Draw the instrument during transparent UI rendering pass
----------------------------------------------------------------

function OnDrawTransparentUI()

	-- Any AOA Units to display?

	if not addOnEnabled then
		return
	end	
	
	if not Tacview.Context.GetSelectedObject(0) then
		return
	end
	
	DeclareRenderData()
	
	local renderer = Tacview.UI.Renderer

	-- Draw Indicator

	local rendererHeight = renderer.GetHeight()

	local indicatorTransform =
	{
		x = Margin + IndicatorWidth/2,
		y = rendererHeight / 2,
		scale = 1,
	}

	renderer.DrawUIVertexArray(indicatorTransform, indicatorRenderStateHandle, indicatorVertexArrayHandle, indicatorTextureCoordinateArrayHandle)
	
	if not currentAOA then
		return
	end
	
	local tapeTransform =
	{
		x = Margin + IndicatorWidth/2 + TapeWidth / 4,
		y = rendererHeight / 2 - 29,
		scaleY = currentAOA * .0245,
	}

	renderer.DrawUIVertexArray(tapeTransform, tapeRenderStateHandle, tapeVertexArrayHandle, nil)

end

----------------------------------------------------------------
-- Main loop
----------------------------------------------------------------

-- Update is called once a frame by Tacview
-- Here we retrieve current aircraft AOA unit value which will be displayed by OnDrawTransparentUI()

function OnUpdate(dt, absoluteTime)

	local telemetry = Tacview.Telemetry

	-- Verify that the user wants to display AOA Indicator

	if not addOnEnabled then
		return
	end
	
	-- Indicator will be displayed only when the primary selected object is a fixed wing aircraft

	local objectHandle = Tacview.Context.GetSelectedObject(0)

	if not objectHandle then 
		return 
	end

	local tags = telemetry.GetCurrentTags(objectHandle)

	if not tags then 
		return 
	end

	if not telemetry.AnyGivenTagActive(tags, telemetry.Tags.FixedWing) then 
		return 
	end
	
	currentAOA = Tacview.Telemetry.GetCurrentAngleOfAttack( objectHandle )
	
	if not currentAOA then 
		return
	end
	
	if currentAOA and previousAOA and 
		(	
			(currentAOA >= 0 and previousAOA < 0) or 
			(previousAOA >= 0 and currentAOA < 0) 
		)then
		
		Tacview.UI.Renderer.ReleaseRenderState(tapeRenderStateHandle)
		tapeRenderStateHandle = nil
		
	end	
	
	currentAOA = math.deg(currentAOA)
	currentAOA = math.min(math.max(currentAOA,-20),30)
	
	previousAOA = currentAOA
	
end

----------------------------------------------------------------
-- Initialize this addon
----------------------------------------------------------------

function Initialize()

	-- Declare add-on information

	Tacview.AddOns.Current.SetTitle("AOA Indicator")
	Tacview.AddOns.Current.SetVersion("1.2")
	Tacview.AddOns.Current.SetAuthor("BuzyBee")
	Tacview.AddOns.Current.SetNotes("Displays AOA indicator in the 3D view.")

	-- Load user preferences
	-- The variable addOnEnabled already contain the default setting

	addOnEnabled = Tacview.AddOns.Current.Settings.GetBoolean(settingName, addOnEnabled)

	-- Declare menus
	-- Create a main menu "AoA Indicator"
	-- Then insert in it an option to display or not the indicator

	local mainMenuId = Tacview.UI.Menus.AddMenu(nil, "AoA Indicator")
	displayAOAIndicatorMenuId = Tacview.UI.Menus.AddOption(mainMenuId, "Display AOA Indicator", addOnEnabled, OnMenuEnableAddOn)

	-- Register callbacks

	Tacview.Events.Update.RegisterListener(OnUpdate)
	Tacview.Events.DrawTransparentUI.RegisterListener(OnDrawTransparentUI)

end

Initialize()
