
--[[
	Additional Gauges
	Displays more gauges, currently: RPM

	Author: BuzyBee
	Last update: 2023-04-26 (Tacview 1.9.0)

	Feel free to modify and improve this script!
--]]

--[[

	MIT License

	Copyright (c) 2023-2024 Raia Software Inc.

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

local LeftMargin = 60
local BottomMargin = 16

local settingName = "addOnEnabled"

local GlobalScale = 1

local NominalInstrumentWidth = 256.0 - 64.0
local NominalInstrumentHeight = 256.0 - 64.0

local NominalRendererWidth = 1280.0
local NominalRendererHeight = 1080.0

local MinimumWidth = 96.0

local instrumentWidth = NominalInstrumentWidth
local instrumentHeight = NominalInstrumentHeight

----------------------------------------------------------------
-- "Members"
----------------------------------------------------------------

local rpmNeedleRoll
local rpmNeedleRoll2 = 0


local RPMGaugeTextureHandle
local RPMGaugeRenderStateHandle
local RPMGaugeVertexArrayHandle
local RPMGaugeTextureCoordinateArrayHandle

local RPMNeedleTextureHandle
local RPMNeedleTextureHandle2
local RPMNeedleRenderStateHandle
local RPMNeedleRenderStateHandle2
local RPMNeedleVertexArrayHandle
local RPMNeedleTextureCoordinateArrayHandle



----------------------------------------------------------------
-- UI commands and options
----------------------------------------------------------------

local displayAdditionalGauges
local addOnEnabled = true

function OnMenuEnableAddOn()

	-- Enable/disable add-on

	addOnEnabled = not addOnEnabled

	-- Save option value in registry

	Tacview.AddOns.Current.Settings.SetBoolean(settingName, addOnEnabled)

	-- Update menu with the new option value

	Tacview.UI.Menus.SetOption(displayAdditionalGauges, addOnEnabled)

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

	if not RPMGaugeTextureHandle then

		local addOnPath = Tacview.AddOns.Current.GetPath()
		RPMGaugeTextureHandle = renderer.LoadTexture(addOnPath.."textures/RPM Gauge.png", false)

	end
	
	if not RPMNeedleTextureHandle then

		local addOnPath = Tacview.AddOns.Current.GetPath()
		RPMNeedleTextureHandle = renderer.LoadTexture(addOnPath.."textures/RPM Needle 1.png", false)

	end
	
	if not RPMNeedleTextureHandle2 then

		local addOnPath = Tacview.AddOns.Current.GetPath()
		RPMNeedleTextureHandle2 = renderer.LoadTexture(addOnPath.."textures/RPM Needle 2.png", false)

	end

	-- Declare the render states for the instrument indicator and needle.
	-- The render state is used to define how to draw our 2D models.

	if not RPMGaugeRenderStateHandle then

		local RPMGaugeRenderState =
		{
			texture = RPMGaugeTextureHandle,
		}

		RPMGaugeRenderStateHandle = renderer.CreateRenderState(RPMGaugeRenderState)

	end
	
	if not RPMNeedleRenderStateHandle then

		local RPMNeedleRenderState =
		{
			texture = RPMNeedleTextureHandle,		
		}

		RPMNeedleRenderStateHandle = renderer.CreateRenderState(RPMNeedleRenderState)

	end
	
	if not RPMNeedleRenderStateHandle2 then

		local RPMNeedleRenderState2 =
		{
			texture = RPMNeedleTextureHandle2,		
		}

		RPMNeedleRenderStateHandle2 = renderer.CreateRenderState(RPMNeedleRenderState2)

	end

	-- The following list of vertices is used to define the square shape of the instrument using two triangles.
	
	if not RPMGaugeVertexArrayHandle then

		local halfWidth = NominalInstrumentWidth / 2
		
		local RPMGaugeVertexArray =
		{
			-halfWidth, halfWidth, 0.0,
			-halfWidth, -halfWidth, 0.0,
			halfWidth, -halfWidth, 0.0,
			-halfWidth, halfWidth, 0.0,
			halfWidth, halfWidth, 0.0,
			halfWidth, -halfWidth, 0.0,
		}

		RPMGaugeVertexArrayHandle = renderer.CreateVertexArray(RPMGaugeVertexArray)

	end
	
	-- Same for the needle.

	if not RPMNeedleVertexArrayHandle then

		local halfWidth = NominalInstrumentWidth / 2

		local RPMNeedleVertexArray =
		{
			-halfWidth, halfWidth, 0.0,
			-halfWidth, -halfWidth, 0.0,
			halfWidth, -halfWidth, 0.0,
			-halfWidth, halfWidth, 0.0,
			halfWidth, halfWidth, 0.0,
			halfWidth, -halfWidth, 0.0,
		}

		RPMNeedleVertexArrayHandle = renderer.CreateVertexArray(RPMNeedleVertexArray)

	end

	-- Declare the textures coordinates to project the instrument image on a rectangle made of two triangles.

	if not RPMGaugeTextureCoordinateArrayHandle then
	
		local RMPGaugeBaseTextureArray =
		{
			0.0, 0.0,
			0.0, 1.0,
			1.0, 1.0,
			0.0, 0.0,
			1.0, 0.0,
			1.0, 1.0,
		}
		
		RPMGaugeTextureCoordinateArrayHandle = renderer.CreateTextureCoordinateArray(RMPGaugeBaseTextureArray)

	end
	
	if not RPMNeedleTextureCoordinateArrayHandle then
	
		local RPMNeedleBaseTextureArray =
		{
			0.0, 0.0,
			0.0, 1.0,
			1.0, 1.0,
			0.0, 0.0,
			1.0, 0.0,
			1.0, 1.0,
		}
		
		RPMNeedleTextureCoordinateArrayHandle = renderer.CreateTextureCoordinateArray(RPMNeedleBaseTextureArray)

	end
end

----------------------------------------------------------------
-- Draw the instrument during transparent UI rendering pass
----------------------------------------------------------------

function OnDrawTransparentUI()

	if not addOnEnabled then
		return
	end	

	if not Tacview.Context.GetSelectedObject(0) then
		return
	end

	-- Draw Indicator and Needle
	
	local renderer = Tacview.UI.Renderer

	local rendererHeight = renderer.GetHeight()
	local rendererWidth = renderer.GetWidth()
	
	local desiredWidth =  rendererWidth / NominalRendererWidth * NominalInstrumentWidth
	local desiredHeight = rendererHeight / NominalRendererHeight * NominalInstrumentHeight
	
	instrumentWidth = math.min(desiredWidth, desiredHeight)
	instrumentWidth = math.max(instrumentWidth, MinimumWidth)
	instrumentHeight = instrumentWidth	
	
	local RPMGaugeTransform  =
	{
		x = LeftMargin + instrumentWidth/2,
		y = BottomMargin + instrumentHeight / 2,
		scale = instrumentHeight/NominalInstrumentHeight,
	}
	
	local RPMNeedleTransform  =
	{
		x = LeftMargin + instrumentWidth/2,
		y = BottomMargin + instrumentHeight / 2,
		scale = instrumentHeight/NominalInstrumentHeight,
		roll = rpmNeedleRoll,
	}
	
	local RPMNeedleTransform2  =
	{
		x = LeftMargin + instrumentWidth/2,
		y = BottomMargin + instrumentHeight / 2,
		scale = instrumentHeight/NominalInstrumentHeight,
		roll = rpmNeedleRoll2,
	}
	
	DeclareRenderData()
	
	renderer.DrawUIVertexArray(RPMGaugeTransform, RPMGaugeRenderStateHandle, RPMGaugeVertexArrayHandle, RPMGaugeTextureCoordinateArrayHandle)

	renderer.DrawUIVertexArray(RPMNeedleTransform, RPMNeedleRenderStateHandle, RPMNeedleVertexArrayHandle, RPMNeedleTextureCoordinateArrayHandle)
	renderer.DrawUIVertexArray(RPMNeedleTransform2, RPMNeedleRenderStateHandle2, RPMNeedleVertexArrayHandle, RPMNeedleTextureCoordinateArrayHandle)
	

end

----------------------------------------------------------------
-- Main loop
----------------------------------------------------------------

-- Update is called once a frame by Tacview
-- Here we retrieve current aircraft AOA value which will be displayed by OnDrawTransparentUI()

function OnUpdate(dt, absoluteTime)

	local telemetry = Tacview.Telemetry

	rpmNeedleRoll = 0
	
	-- Verify that the user wants to display RPM Gauge

	if not addOnEnabled then
		return
	end

	-- Indicator will be displayed only when one of the selected objects is a plane

	local objectHandle = Tacview.Context.GetSelectedObject(0)

	if not objectHandle then 
		return 
	end

	local tags = telemetry.GetCurrentTags(objectHandle)

	if not tags then 
		return 
	end

	if not telemetry.AnyGivenTagActive(tags, telemetry.Tags.FixedWing|telemetry.Tags.Rotorcraft) then 
		return 
	end
	
	-- Use GetObjectsTextPropertyIndex for any unknown property
	
	local rpmPropertyIndex = telemetry.GetObjectsNumericPropertyIndex("EngineRPM", false)
	
	if rpmPropertyIndex == telemetry.InvalidPropertyIndex then
		return
	end
	
	local rpm, sampleIsValid = telemetry.GetNumericSample(objectHandle, Tacview.Context.GetAbsoluteTime(), rpmPropertyIndex)
	
	if sampleIsValid then
		rpm = tonumber(rpm) / 100
		rpmNeedleRoll = (rpm / 35) * (3 * math.pi / 2) - math.rad(3)
	else
		rpmNeedleRoll = nil
	end	
	
	local rpmPropertyIndex2 = telemetry.GetObjectsNumericPropertyIndex("EngineRPM2", false)
	
	if rpmPropertyIndex2 == telemetry.InvalidPropertyIndex then
		return
	end
	
	local rpm2, sampleIsValid = telemetry.GetNumericSample(objectHandle, Tacview.Context.GetAbsoluteTime(), rpmPropertyIndex2)
	
	if sampleIsValid then
		rpm2 = tonumber(rpm2) / 100
		rpmNeedleRoll2 = (rpm2 / 35) * (3 * math.pi / 2) - math.rad(3)
	else
		rpmNeedleRoll2 = nil
	end	
end

----------------------------------------------------------------
-- Initialize this addon
----------------------------------------------------------------

function Initialize()

	-- Declare add-on information

	Tacview.AddOns.Current.SetTitle("Additional Gauges")
	Tacview.AddOns.Current.SetVersion("1.1")
	Tacview.AddOns.Current.SetAuthor("BuzyBee")
	Tacview.AddOns.Current.SetNotes("Displays additional gauges: RPM")

	-- Load user preferences (the variable addOnEnabled already contain the default setting)

	addOnEnabled = Tacview.AddOns.Current.Settings.GetBoolean(settingName, addOnEnabled)

	-- Declare menus

	local mainMenuId = Tacview.UI.Menus.AddMenu(nil, "Additional Gauges")
	displayAdditionalGauges = Tacview.UI.Menus.AddOption(mainMenuId, "Display RPM Gauge", addOnEnabled, OnMenuEnableAddOn)

	-- Register callbacks

	Tacview.Events.Update.RegisterListener(OnUpdate)
	Tacview.Events.DrawTransparentUI.RegisterListener(OnDrawTransparentUI)

end

Initialize()
