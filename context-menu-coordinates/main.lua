
-- Context menu tutorial for Tacview
-- Author: Frantz 'Vyrtuoz' RAIA
-- Last update: 2019-02-06 (Tacview 1.7.6)

-- Feel free to modify and improve this script!

--[[

MIT License

Copyright (c) 2018-2025 Raia Software Inc.

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

local Tacview = require("Tacview176")

----------------------------------------------------------------
-- Playback control
----------------------------------------------------------------

function OnPlay()

	Tacview.Context.Playback.Play()

end

function OnPause()

	Tacview.Context.Playback.Pause()

end

----------------------------------------------------------------
-- Change time to first appearance of selected object
----------------------------------------------------------------

local selectedObjectHandle = 0

function OnGoToObjectBegin()

	local lifeTimeBegin, lifeTimeEnd = Tacview.Telemetry.GetLifeTime(selectedObjectHandle)

	Tacview.Context.SetAbsoluteTime(lifeTimeBegin)

end

----------------------------------------------------------------
-- Menu option to purge all loaded telemetry
----------------------------------------------------------------

function OnContextMenu(contextMenuId, objectHandle)

	-- Add general options

	if Tacview.Context.Playback.IsPlaying() == true then

		Tacview.UI.Menus.AddCommand(contextMenuId, "Pause", OnPause)

	else

		Tacview.UI.Menus.AddCommand(contextMenuId, "Play", OnPlay)

	end

	-- Add options specific to selected object

	if objectHandle ~= 0 then

		Tacview.UI.Menus.AddCommand(contextMenuId, "Go to first appearance", OnGoToObjectBegin)
	end

	selectedObjectHandle = objectHandle
end

----------------------------------------------------------------
-- Initialize this addon
----------------------------------------------------------------

function Initialize()

	-- Declare addon properties

	local currentAddOn = Tacview.AddOns.Current

	currentAddOn.SetTitle("Lua Tutorial 9 - Context Menu")
	currentAddOn.SetVersion("1.7.6")
	currentAddOn.SetAuthor("Vyrtuoz")
	currentAddOn.SetNotes("Shows how to create a context menu and to control the timeline.")

	-- Declare context menu for the 3D view

	Tacview.UI.Renderer.ContextMenu.RegisterListener(OnContextMenu)
end

Initialize()
