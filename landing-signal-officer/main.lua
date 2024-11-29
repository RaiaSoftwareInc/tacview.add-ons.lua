
-- Landing Signal Officer for Tacview
-- Author: Frantz 'Vyrtuoz' RAIA
-- Last update: 2018-09-20 (Tacview 1.7.3)

-- IMPORTANT: This script act both as a tutorial and as a real addon for Tacview.
-- Feel free to modify and improve this script!

--[[

MIT License

Copyright (c) 2018-2024 Raia Software Inc.

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
require("AircraftCarrierList")

local Tacview = require("Tacview173")

----------------------------------------------------------------
-- Constants
----------------------------------------------------------------

local HalfPi = math.pi / 2.0
local VoiceOverSettingName = "Voice-over"
local FrontVector = {x = 0, y = 1, z = 0}
local RightVector = {x = 1, y = 0, z = 0}
local UpVector = {x = 0, y = 0, z = 1}

----------------------------------------------------------------
-- "Members"
----------------------------------------------------------------

local isActive = false

-- Deviation from glide in radian

local horizontalDeviation = 0.0
local verticalDeviation = 0.0

-- Drawing data

local innerSightRenderStateHandle
local outerSightRenderStateHandle

local innerSightVertexArrayHandle
local outerSightVertexArrayHandle

----------------------------------------------------------------
-- UI commands and options
----------------------------------------------------------------

local voiceOverMenuId
local voiceOverOption = true

function OnVoiceOver()

	-- Change and save option

	voiceOverOption = not voiceOverOption

	Tacview.AddOns.Current.Settings.SetBoolean(VoiceOverSettingName, voiceOverOption)

	-- Update menu

	Tacview.UI.Menus.SetOption(voiceOverMenuId, voiceOverOption)

end

----------------------------------------------------------------
-- 3D Rendering
----------------------------------------------------------------

local testRenderStateHandle
local testVertexArrayHandle

local testVertexArray =
{
-1.0,-1.0,-1.0,
    -1.0,-1.0, 1.0,
    -1.0, 1.0, 1.0,
    1.0, 1.0,-1.0,
    -1.0,-1.0,-1.0,
    -1.0, 1.0,-1.0,
    1.0,-1.0, 1.0,
    -1.0,-1.0,-1.0,
    1.0,-1.0,-1.0,
    1.0, 1.0,-1.0,
    1.0,-1.0,-1.0,
    -1.0,-1.0,-1.0,
    -1.0,-1.0,-1.0,
    -1.0, 1.0, 1.0,
    -1.0, 1.0,-1.0,
    1.0,-1.0, 1.0,
    -1.0,-1.0, 1.0,
    -1.0,-1.0,-1.0,
    -1.0, 1.0, 1.0,
    -1.0,-1.0, 1.0,
    1.0,-1.0, 1.0,
    1.0, 1.0, 1.0,
    1.0,-1.0,-1.0,
    1.0, 1.0,-1.0,
    1.0,-1.0,-1.0,
    1.0, 1.0, 1.0,
    1.0,-1.0, 1.0,
    1.0, 1.0, 1.0,
    1.0, 1.0,-1.0,
    -1.0, 1.0,-1.0,
    1.0, 1.0, 1.0,
    -1.0, 1.0,-1.0,
    -1.0, 1.0, 1.0,
    1.0, 1.0, 1.0,
    -1.0, 1.0, 1.0,
    1.0,-1.0, 1.0
}

local testRenderState =
{
	color = 0xFF8000FF,					-- Black
}

function OnDrawOpaqueObjects()

	-- LSO mode active?

	if not isActive then
		return
	end

	-- Because Tacview does not display the current object in cockpit mode,
	-- we must draw the aircraft carrier deck manually.

	local camera = Tacview.Context.Camera

	if camera.GetMode() == camera.Cockpit then

		local carrierHandle = Tacview.Context.GetSelectedObject(0)
		local carrierTransform = Tacview.Telemetry.GetCurrentTransform(carrierHandle)

		-- Force object scale to 1.0 to avoid any possible distortion while in cockpit

		carrierTransform.scale = 1.0

		Tacview.UI.Renderer.DrawOpaqueObject(carrierHandle, carrierTransform, 1.0)
	end


--[[

	local primaryObjectName = Tacview.Telemetry.GetCurrentShortName(carrierHandle)
	local carrierInfo = AircraftCarrierList[primaryObjectName]

	local carrierTransform = Tacview.Telemetry.GetCurrentTransform(carrierHandle)
	local targetPointPositionOnCarrier = Tacview.Math.Vector.LocalToGlobal(carrierTransform, {x = carrierInfo.LateralOffset, y = carrierInfo.LongitudinalOffset, z = carrierInfo.VerticalOffset+50})

local testTransform =
{
x = targetPointPositionOnCarrier.x,
y =targetPointPositionOnCarrier.y,
z =targetPointPositionOnCarrier.z,

yaw = carrierTransform.yaw + carrierInfo.GlideYaw,

scale= 10
}

		if not testRenderStateHandle then

			testRenderStateHandle = Tacview.UI.Renderer.CreateRenderState(testRenderState)
			testVertexArrayHandle = Tacview.UI.Renderer.CreateVertexArray(testVertexArray)

		end

		Tacview.UI.Renderer.DrawObjectVertexArray(testTransform, testRenderStateHandle, testVertexArrayHandle)
--]]

end

function OnDrawTransparentObjects()

	-- LSO mode active?

	if not isActive then
		return
	end

	-- Draw glide funnel when in 3D view

	local camera = Tacview.Context.Camera

	if camera.GetMode() ~= camera.Cockpit then

	end
end

----------------------------------------------------------------
-- 2D Rendering
----------------------------------------------------------------

local SightThickness = 0.01

local InnerSightTop = 0.25
local InnerSightBottom = -InnerSightTop
local InnerSightLeft = InnerSightBottom
local InnerSightRight = -InnerSightLeft

local InnerSightRenderState =
{
	color = 0xFF000000,					-- Black
}

local InnerSightVertexArray =
{
	InnerSightLeft, InnerSightTop, 0.0,
	InnerSightLeft + SightThickness, InnerSightTop - SightThickness, 0.0,
	InnerSightRight, InnerSightTop, 0.0,
	InnerSightRight - SightThickness, InnerSightTop - SightThickness, 0.0,
	InnerSightRight, InnerSightBottom, 0.0,
	InnerSightRight - SightThickness, InnerSightBottom + SightThickness, 0.0,
	InnerSightLeft, InnerSightBottom, 0.0,
	InnerSightLeft + SightThickness, InnerSightBottom + SightThickness, 0.0,
	InnerSightLeft, InnerSightTop, 0.0,
	InnerSightLeft + SightThickness, InnerSightTop - SightThickness, 0.0,
}

local OuterSightTop = 2 * InnerSightTop
local OuterSightBottom = -0.75 * OuterSightTop
local OuterSightLeft = -OuterSightTop
local OuterSightRight = -OuterSightLeft

local OuterSightRenderState =
{
	color = 0xFF0000FF,					-- Red
}

local OuterSightVertexArray =
{
	OuterSightLeft, OuterSightTop, 0.0,
	OuterSightLeft + SightThickness, OuterSightTop - SightThickness, 0.0,
	OuterSightRight, OuterSightTop, 0.0,
	OuterSightRight - SightThickness, OuterSightTop - SightThickness, 0.0,
	OuterSightRight, OuterSightBottom, 0.0,
	OuterSightRight - SightThickness, OuterSightBottom + SightThickness, 0.0,
	OuterSightLeft, OuterSightBottom, 0.0,
	OuterSightLeft + SightThickness, OuterSightBottom + SightThickness, 0.0,
	OuterSightLeft, OuterSightTop, 0.0,
	OuterSightLeft + SightThickness, OuterSightTop - SightThickness, 0.0,
}

function OnDrawTransparentUI()

	-- LSO mode active?

	if not isActive then
		return
	end

	-- Draw glide limits in cockpit view

	local camera = Tacview.Context.Camera

	if camera.GetMode() == camera.Cockpit then

		local rendererWidth = Tacview.UI.Renderer.GetWidth()
		local rendererHeight = Tacview.UI.Renderer.GetHeight()

		-- Register drawing data only during the draw call

		if not innerSightRenderStateHandle then

			innerSightRenderStateHandle = Tacview.UI.Renderer.CreateRenderState(InnerSightRenderState)
			outerSightRenderStateHandle = Tacview.UI.Renderer.CreateRenderState(OuterSightRenderState)

			innerSightVertexArrayHandle = Tacview.UI.Renderer.CreateVertexArray(InnerSightVertexArray)
			outerSightVertexArrayHandle = Tacview.UI.Renderer.CreateVertexArray(OuterSightVertexArray)

		end

		-- Our vertex array goes from -1 to +1,
		-- so we must multiply it by half the renderer height (scale) to fully cover the viewport vertically.

		local sightTransform =
		{
			x = rendererWidth / 2,
			y = rendererHeight / 2,
			scale = rendererHeight,
		}

		-- Draw sight

		Tacview.UI.Renderer.DrawUIVertexArray(sightTransform, innerSightRenderStateHandle, innerSightVertexArrayHandle)
		Tacview.UI.Renderer.DrawUIVertexArray(sightTransform, outerSightRenderStateHandle, outerSightVertexArrayHandle)
	end
end

----------------------------------------------------------------
-- Calculate aircraft position
----------------------------------------------------------------

-- Position the camera view on the deck if the current view is in Cockipt mode

function RepositionCamera(carrierInfo)

	local camera = Tacview.Context.Camera

	-- Cockpit view selected?

	if camera.GetMode() ~= camera.Cockpit then
		return
	end

	-- Move the camera in LSO position

	local cameraOffset =
	{
		lateral = carrierInfo.LateralOffset,
		longitudinal = carrierInfo.LongitudinalOffset,
		vertical = carrierInfo.VerticalOffset,
		pitch = math.rad(carrierInfo.GlidePitch),
		yaw = math.rad(carrierInfo.GlideYaw),
	}

	camera.SetOffset(cameraOffset)
	camera.SetFieldOfView(math.rad(30))
end

-- Calculate deviation between glide and give aircraft position

function CalculateDeviation(carrierHandle, carrierInfo, aircraftObjectHandle)

	-- Calculate reference points in cartesian space

	local carrierTransform = Tacview.Telemetry.GetCurrentTransform(carrierHandle)
	local targetPointPositionOnCarrier = Tacview.Math.Vector.LocalToGlobal(carrierTransform, {x = carrierInfo.LateralOffset, y = carrierInfo.LongitudinalOffset, z = carrierInfo.VerticalOffset})

	local aircraftTransform = Tacview.Telemetry.GetCurrentTransform(aircraftObjectHandle)
	local aircraftPosition = aircraftTransform
	local aircraftPositionOnGround = Tacview.Math.Vector.LongitudeLatitudeToCartesian({longitude = aircraftTransform.longitude, latitude = aircraftTransform.latitude, 0.0})

	local carrierToAircraft = Tacview.Math.Vector.Subtract(aircraftPosition, targetPointPositionOnCarrier)
	local carrierToAircraftNormalized = Tacview.Math.Vector.Normalize(carrierToAircraft)

	local carrierToAircraftOnGround = Tacview.Math.Vector.Subtract(aircraftPositionOnGround, targetPointPositionOnCarrier)
	local carrierToAircraftOnGroundNormalized = Tacview.Math.Vector.Normalize(carrierToAircraftOnGround)

	-- Calculate direction vectors
	-- Ignore carrier roll and pich because, like in real-life, the glide must be static!
	-- Set xyz to 0 to get a vector instead of a global position

	local localCarrierTransform =
	{
		x = 0,
		y = 0,
		z = 0,

		longitude = carrierTransform.longitude,
		latitude = carrierTransform.latitude,
		altitude = carrierTransform.altitude,

		yaw = carrierTransform.yaw,
	}

	local frontOfCarrier = Tacview.Math.Vector.LocalToGlobal(localCarrierTransform, FrontVector)
	local rightOfCarrier = Tacview.Math.Vector.LocalToGlobal(localCarrierTransform, RightVector)
	local upOfCarrier = Tacview.Math.Vector.LocalToGlobal(localCarrierTransform, UpVector)

	-- Calculate horizontal deviation from glide

	local horizontalAngle = Tacview.Math.Angle.Subtract(HalfPi, Tacview.Math.Vector.AngleBetween(carrierToAircraftOnGroundNormalized, frontOfCarrier, rightOfCarrier))

	-- Calculate vertical deviation from glide

	local verticalAngle = Tacview.Math.Vector.AngleBetween(carrierToAircraftNormalized, upOfCarrier, carrierToAircraftOnGroundNormalized)

	-- Store deviation in radian

	horizontalDeviation = Tacview.Math.Angle.Subtract(horizontalAngle, math.rad(carrierInfo.GlideYaw))
	verticalDeviation = Tacview.Math.Angle.Subtract(verticalAngle, math.rad(carrierInfo.GlidePitch))

end

----------------------------------------------------------------
-- Main loop
----------------------------------------------------------------

-- Update is called once a frame by Tacview

function OnUpdate(dt, absoluteTime)

	-- This add-on is active only when a known aircraft carrier is selected as the primary object

	isActive = false

	local primaryObject = Tacview.Context.GetSelectedObject(0)

	if not primaryObject then
		return
	end

	local primaryObjectName = Tacview.Telemetry.GetCurrentShortName(primaryObject)
	local carrierInfo = AircraftCarrierList[primaryObjectName]

	if not carrierInfo then
		return
	end

	isActive = true

	-- Position camera on the carrier deck when in cockpit view is selected

	RepositionCamera(carrierInfo)

	-- Calculate deviation from glide

	local secondaryObject = Tacview.Context.GetSelectedObject(1)

	if secondaryObject then

		CalculateDeviation(primaryObject, carrierInfo, secondaryObject)

--		Tacview.Log.Debug("Deviation horizontal:", math.deg(horizontalDeviation), "vertical:", math.deg(verticalDeviation))

	end

end

----------------------------------------------------------------
-- Initialize this addon
----------------------------------------------------------------

function Initialize()

	-- Declare addon properties

	local currentAddOn = Tacview.AddOns.Current

	currentAddOn.SetTitle("Landing Signal Officer")
	currentAddOn.SetVersion("1.7.3")
	currentAddOn.SetAuthor("Vyrtuoz")
	currentAddOn.SetNotes("Select an aircraft carrier as primary object, a plane as secondary object, then switch to cockpit view!")

	-- Load preferences

	voiceOverOption = Tacview.AddOns.Current.Settings.GetBoolean(VoiceOverSettingName, voiceOverOption)

	-- Declare menus

	local addOnMenuId = Tacview.UI.Menus.AddMenu(nil, "Landing Signal Officer (LSO)")
	voiceOverMenuId = Tacview.UI.Menus.AddOption(addOnMenuId, "Enable Voice-over", voiceOverOption, OnVoiceOver)

	-- Register callbacks

	Tacview.Events.Update.RegisterListener(OnUpdate)

	Tacview.Events.DrawOpaqueObjects.RegisterListener(OnDrawOpaqueObjects)
	Tacview.Events.DrawTransparentObjects.RegisterListener(OnDrawTransparentObjects)
	Tacview.Events.DrawTransparentUI.RegisterListener(OnDrawTransparentUI)

end

Initialize()
