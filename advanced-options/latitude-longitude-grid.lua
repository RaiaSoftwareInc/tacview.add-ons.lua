
-- Advanced Options
-- Author: Erin 'BuzyBee' O'REILLY
-- Last update: 2025-07-16 (Tacview 1.9.5)

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

local Tacview = require("Tacview194")

----------------------------------------------------------------
-- Longitude / Latitude Grid Visibility
--
-- Tacview resets the grid visibility at startup,
-- so we track the desired state internally and reapply it as needed.
----------------------------------------------------------------

local TacviewGridVisibleSettingName = "UI.View.Grid.Visible"
local GridVisibleSettingName = "GridVisible"

function IsGridVisible()

	local currentTacviewSetting = Tacview.Settings.GetBoolean(TacviewGridVisibleSettingName)

	return Tacview.AddOns.Current.Settings.GetBoolean(GridVisibleSettingName, currentTacviewSetting)

end

function SetGridVisible(visiblity)

	Tacview.Settings.SetBoolean(TacviewGridVisibleSettingName, visiblity)
	Tacview.AddOns.Current.Settings.SetBoolean(GridVisibleSettingName, visiblity)

end

----------------------------------------------------------------
-- Menu callback
----------------------------------------------------------------

local showLatLonGridMenuHandle

function OnShowLatitudeLongitudeGrid()

	local isGridVisible = not IsGridVisible()

	SetGridVisible(isGridVisible)

	Tacview.UI.Menus.SetOption(showLatLonGridMenuHandle, isGridVisible)
		
end

----------------------------------------------------------------
-- Initialize this addon
----------------------------------------------------------------

function InitializeLatitudeLongitudeGrid(advancedOptionsMenuHandle)

	-- Make sure previous setting is applied on startup.

	Tacview.Settings.SetBoolean(TacviewGridVisibleSettingName, IsGridVisible())

	-- Add option to the menu.

	showLatLonGridMenuHandle = Tacview.UI.Menus.AddOption(advancedOptionsMenuHandle, "Show Latitude/Longitude Grid", IsGridVisible(), OnShowLatitudeLongitudeGrid)

end
