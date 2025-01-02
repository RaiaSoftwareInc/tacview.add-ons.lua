
-- Immersive Cockpit for Tacview
-- Author: Erin 'BuzyBee' O'Reilly
-- Last update: 2023-02-28 (Tacview 1.9.0)

-- IMPORTANT: This script act both as a tutorial and as a real addon for Tacview.
-- Feel free to modify and improve this script!

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

----------------------------------------------------------------
-- Setup
----------------------------------------------------------------

require("lua-strict")

local Tacview = require("Tacview190")

local hudScale = 0.66

local fieldOfView = 30

local addOnEnabledMenuId
local AddOnEnabledSettingName = "enabled"

local addOnEnabled = true

function OnCustomizeFieldOfView()

	-- Change and save option

	addOnEnabled = not addOnEnabled

	Tacview.AddOns.Current.Settings.SetBoolean(AddOnEnabledSettingName, addOnEnabled)

	-- Update menu

	Tacview.UI.Menus.SetOption(addOnEnabledMenuId, addOnEnabled)

end

local camera = Tacview.Context.Camera

function OnUpdate()

	if not addOnEnabled then return end
	
	if Tacview.Context.Camera.GetMode() == Tacview.Context.Camera.Cockpit then

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

	currentAddOn.SetTitle("Field of View Customizer")
	currentAddOn.SetVersion("0.1")
	currentAddOn.SetAuthor("BuzyBee")
	currentAddOn.SetNotes("Customize field of view when in cockpit mode.")

	-- Load preferences

	 addOnEnabled = Tacview.AddOns.Current.Settings.GetBoolean(AddOnEnabledSettingName, addOnEnabled)

	-- Declare menus

	local mainMenuId = Tacview.UI.Menus.AddMenu(nil, "Field of View Customizer")
	addOnEnabledMenuId = Tacview.UI.Menus.AddOption(mainMenuId, "Customize Field of View", addOnEnabled, OnCustomizeFieldOfView)

	-- Register callbacks

	Tacview.Events.Update.RegisterListener(OnUpdate)

end

Initialize()
