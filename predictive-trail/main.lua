
-- AoA Indexer for Tacview (tutorial for 2D UI rendering)
-- Author: Frantz 'Vyrtuoz' RAIA
-- Last update: 2020-06-25 (Tacview 1.8.4)

-- IMPORTANT: This script act both as a tutorial and as a real addon for Tacview.
-- Feel free to modify and improve this script!

--[[

MIT License

Copyright (c) 2020-2024 Raia Software Inc.

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

local Tacview = require("Tacview184")

----------------------------------------------------------------
-- Constants
----------------------------------------------------------------

local AddOnEnabledSettingName = "DisplayPredictiveTrail"

local TrailWidth = 2.0				-- pixels
local WallWidth = 1.0				-- pixels
local TrailResolution = 0.5			-- seconds
local TrailLength = 60.0			-- seconds
local TrailColor = 0xFFF3740D		-- hud style blue

----------------------------------------------------------------
-- "Members"
----------------------------------------------------------------

local vertexListTrail = nil
local vertexListWall = nil
local renderStateHandle = nil

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

	-- The render state is used to define how to draw the instrument.
	-- We only need to specify the texture in our case.

	if not renderStateHandle then

		local renderState =
		{
			color = TrailColor,
			blendMode = Tacview.UI.Renderer.BlendMode.Additive,
		}

		renderStateHandle = Tacview.UI.Renderer.CreateRenderState(renderState)

	end

end

function OnDrawTransparentObjects()

	-- Any data available?

	if not vertexListTrail or next(vertexListTrail) == nil then
		return
	end

	-- Make sure rendering data are declared (only once, during the first OnDrawTransparentUI call)

	DeclareRenderData()

	-- Draw the trail

	Tacview.UI.Renderer.DrawLines(renderStateHandle, WallWidth, vertexListWall)
	Tacview.UI.Renderer.DrawLineStrip(renderStateHandle, TrailWidth, vertexListTrail)

end

----------------------------------------------------------------
-- Main loop
----------------------------------------------------------------

-- Update is called once a frame by Tacview

function OnUpdate(dt, absoluteTime)

	vertexListTrail = nil
	vertexListWall = nil

	-- Add-on enabled?

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

	-- Retrieve trajectory data from telemetry

	vertexListTrail = {}
	vertexListWall = {}

	local trailItemIndex = 1
	local wallItemIndex = 1
 
	local Telemetry = Tacview.Telemetry
	local Math = Tacview.Math

	local firstTransformSampleTime, lastTransformSampleTime = Telemetry.GetTransformTimeRange(objectHandle)
	
	if not lastTransformSampleTime then
		return
	end

	local trailEndtime = math.min(lastTransformSampleTime + TrailResolution, absoluteTime + TrailLength)

	local GetTransform = Telemetry.GetTransform
	local LongitudeLatitudeToCartesian = Math.Vector.LongitudeLatitudeToCartesian

	for transformTime = absoluteTime, trailEndtime, TrailResolution do

		local objectTransform, isTransformValid = GetTransform( objectHandle , transformTime )

		if isTransformValid == true then

			-- "Draw" from the previous point to current point (linestrip)

			vertexListTrail[trailItemIndex] = {objectTransform.x, objectTransform.y, objectTransform.z}

			trailItemIndex = trailItemIndex + 1

			-- "Draw" from ground to current point (lines list)

			local groundPoint = LongitudeLatitudeToCartesian({longitude = objectTransform.longitude, latitude = objectTransform.latitude, altitude = 0})

			vertexListWall[wallItemIndex] = {groundPoint.x, groundPoint.y, groundPoint.z}
			vertexListWall[wallItemIndex + 1] = {objectTransform.x, objectTransform.y, objectTransform.z}

			wallItemIndex = wallItemIndex + 2
		end
	end
end

----------------------------------------------------------------
-- Initialize this addon
----------------------------------------------------------------

function Initialize()

	-- Declare addon properties

	local currentAddOn = Tacview.AddOns.Current

	currentAddOn.SetTitle("Predictive Trail")
	currentAddOn.SetVersion("1.8.4")
	currentAddOn.SetAuthor("Vyrtuoz")
	currentAddOn.SetNotes("Displays a trail in front of the selected aircraft showing its future trajectory.")

	-- Load preferences
	-- Use current addOnEnabledOption value as the default setting

	addOnEnabledOption = Tacview.AddOns.Current.Settings.GetBoolean(AddOnEnabledSettingName, addOnEnabledOption)

	-- Declare menus

	local addOnMenuId = Tacview.UI.Menus.AddMenu(nil, "Predictive Trail")
	addOnEnabledMenuId = Tacview.UI.Menus.AddOption(addOnMenuId, "Display Predictive Trail", addOnEnabledOption, OnMenuEnableAddOn)

	-- Register callbacks

	Tacview.Events.Update.RegisterListener(OnUpdate)

	Tacview.Events.DrawTransparentObjects.RegisterListener(OnDrawTransparentObjects)

end

Initialize()
