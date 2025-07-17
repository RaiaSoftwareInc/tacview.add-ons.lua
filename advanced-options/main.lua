
-- Advanced Options
-- Author: Erin 'BuzyBee' O'REILLY
-- Last update: 2025-07-16 (Tacview 1.9.4)

-- Feel free to modify and improve this script!

--[[

MIT License

Copyright (c) 2025 Raia Software Inc.

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

local Tacview = require("Tacview194")

local gridVisible = true
local latLongGridMenuHandle

----------------------------------------------------------------
-- Playback control
----------------------------------------------------------------

local latLonGridVisibilitySettingName = "Lat/Lon Grid Visibility"

function OnToggleLatLonGridVisibility()

	if gridVisible then
		Tacview.Settings.SetBoolean( "UI.View.Grid.Visible", false )
		gridVisible = false
		Tacview.AddOns.Current.Settings.SetBoolean( latLonGridVisibilitySettingName , gridVisible )
		Tacview.UI.Menus.SetOption(latLongGridMenuHandle, gridVisible)

		
	else
		Tacview.Settings.SetBoolean( "UI.View.Grid.Visible", true )
		gridVisible = true
		Tacview.AddOns.Current.Settings.SetBoolean( latLonGridVisibilitySettingName , gridVisible )
		Tacview.UI.Menus.SetOption(latLongGridMenuHandle, gridVisible)

	end

end

----------------------------------------------------------------
-- Initialize this addon
----------------------------------------------------------------

function Initialize()

	-- Declare addon properties

	local currentAddOn = Tacview.AddOns.Current

	currentAddOn.SetTitle("Advanced Options")
	currentAddOn.SetVersion("1.9.4")
	currentAddOn.SetAuthor("BuzyBee")
	currentAddOn.SetNotes("Provide access to advanced options.")

	-- Declare context menu for the 3D view

	gridVisible = Tacview.AddOns.Current.Settings.GetBoolean(latLonGridVisibilitySettingName, true)

	local mainMenuHandle = Tacview.UI.Menus.AddMenu(nil, "Advanced Options")
	latLongGridMenuHandle = Tacview.UI.Menus.AddOption( mainMenuHandle , "Lat Lon Grid Visible" , gridVisible , OnToggleLatLonGridVisibility )

end


Initialize()
