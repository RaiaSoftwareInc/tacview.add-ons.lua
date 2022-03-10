
-- Immersive Cockpit for Tacview
-- Author: Erin 'BuzyBee' O'Reilly
-- Last update: 2020-11-12 (Tacview 1.8.5)

-- IMPORTANT: This script act both as a tutorial and as a real addon for Tacview.
-- Feel free to modify and improve this script!

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

----------------------------------------------------------------
-- Setup
----------------------------------------------------------------

require("lua-strict")

local Tacview = require("Tacview186")

local hudScale = 0.66

local fieldOfView = 40

dofile(Tacview.AddOns.Current.GetPath() .."eligible-aircraft-list.lua")

local EligibleAircraftList = EligibleAircraftList()

local defaultFileName = "FixedWing.T-38.cockpit.obj"

local DisplayVirtualCockpitMenuId
local DisplayVirtualCockpitSettingName = "Display Virual Cockpit"

local displayVirtualCockpit = true

function OnDisplayVirtualCockpit()

	-- Change and save option

	displayVirtualCockpit = not displayVirtualCockpit

	Tacview.AddOns.Current.Settings.SetBoolean(DisplayVirtualCockpitSettingName, displayVirtualCockpit)

	-- Update menu

	Tacview.UI.Menus.SetOption(DisplayVirtualCockpitMenuId, displayVirtualCockpit)

end

local telemetry = Tacview.Telemetry
local getCurrentTags = telemetry.GetCurrentTags
local tags = telemetry.Tags
local camera = Tacview.Context.Camera
local anyGivenTagActive = telemetry.AnyGivenTagActive

local isFixedWingOrRotorcraft

local function starts_with(str, start)
   return str:sub(1, #start) == start
end

function OnDrawTransparentObjectsNear()

	if not displayVirtualCockpit then
		return
	end

	if camera.GetMode() == camera.Cockpit then

		local objectHandle = Tacview.Context.GetSelectedObject(0)

		if not objectHandle then
			return
		end

		local objectTags = getCurrentTags(objectHandle)

		if anyGivenTagActive(objectTags, tags.FixedWing|tags.Rotorcraft) then

			isFixedWingOrRotorcraft = true;

			local objectTransform = telemetry.GetCurrentCalculatedTransform(objectHandle)

			objectTransform.scale = 1

			local primaryObjectName = telemetry.GetCurrentShortName(objectHandle)

			if starts_with(primaryObjectName,"M2000") then
				primaryObjectName = "M2000"
			end

			local cockpitFilename = EligibleAircraftList[primaryObjectName]

			if not cockpitFilename then
				cockpitFilename = defaultFileName
			end

			local modelHandle = Tacview.UI.Renderer.Load3DModel(Tacview.AddOns.Current.GetPath() .. cockpitFilename)

			if not modelHandle then
				return
			end	

			Tacview.UI.Renderer.DrawSemiTransparent3DModel(modelHandle, objectTransform, 0x88ffffff)

		else

			isFixedWingOrRotorcraft = false;
		end
	end
end

function OnUpdate()

	if not displayVirtualCockpit then return end
	
	if Tacview.Context.Camera.GetMode() == Tacview.Context.Camera.Cockpit and isFixedWingOrRotorcraft then

		Tacview.Context.Camera.SetFieldOfView(math.rad(fieldOfView))

		Tacview.Settings.SetNumber( "UI.View.HUD.Scale" , hudScale )

	end
end

----------------------------------------------------------------
-- Initialize this addon
----------------------------------------------------------------

function Initialize()

	-- Declare addon properties

	local currentAddOn = Tacview.AddOns.Current

	currentAddOn.SetTitle("Immersive Cockpit")
	currentAddOn.SetVersion("1.8.5")
	currentAddOn.SetAuthor("BuzyBee")
	currentAddOn.SetNotes("Display the aircraft 3D object when in cockpit view.")

	-- Load preferences

	 displayVirtualCockpit = Tacview.AddOns.Current.Settings.GetBoolean(DisplayVirtualCockpitSettingName, displayVirtualCockpit)


	-- Declare menus

	local addOnMenuId = Tacview.UI.Menus.AddMenu(nil, "Immersive Cockpit")
	DisplayVirtualCockpitMenuId = Tacview.UI.Menus.AddOption(addOnMenuId, "Display Virtual Cockpit", displayVirtualCockpit, OnDisplayVirtualCockpit)

	-- Register callbacks

	Tacview.Events.Update.RegisterListener(OnUpdate)
	--Tacview.Events.DrawOpaqueObjects.RegisterListener(OnDrawOpaqueObjects)
	Tacview.Events.DrawTransparentObjectsNear.RegisterListener(OnDrawTransparentObjectsNear)
	--Tacview.Events.DrawTransparentUI.RegisterListener(OnDrawTransparentUI)

end

Initialize()
