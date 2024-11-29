
-- Lat-Lon Grid Visibility
-- Author: Erin 'BuzyBee' O'REILLY
-- Last update: 2021-10-27 (Tacview 1.8.7)

-- Feel free to modify and improve this script!

--[[

MIT License

Copyright (c) 2021-2024 Raia Software Inc.

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

local Tacview = require("Tacview187")

----------------------------------------------------------------
-- Playback control
----------------------------------------------------------------

function OnShow()

	Tacview.Settings.SetBoolean( "UI.View.Grid.Visible", true )

end

function OnHide()

	Tacview.Settings.SetBoolean( "UI.View.Grid.Visible", false )

end

function OnContextMenu(contextMenuId, objectHandle)

	-- Add general options

	if 	Tacview.Settings.GetBoolean("UI.View.Grid.Visible") == true then

		Tacview.UI.Menus.AddCommand(contextMenuId, "Set Lat/Long Grid Invisible", OnHide)

	else

		Tacview.UI.Menus.AddCommand(contextMenuId, "MakSete Lat/Long Grid Visible", OnShow)

	end
end

----------------------------------------------------------------
-- Initialize this addon
----------------------------------------------------------------

function Initialize()

	-- Declare addon properties

	local currentAddOn = Tacview.AddOns.Current

	currentAddOn.SetTitle("Lat-Lon Grid Visibility")
	currentAddOn.SetVersion("1.8.7")
	currentAddOn.SetAuthor("BuzyBee")
	currentAddOn.SetNotes("Show or hide the latitude / longitude grid marks.")

	-- Declare context menu for the 3D view

	Tacview.UI.Renderer.ContextMenu.RegisterListener(OnContextMenu)
end

Initialize()
