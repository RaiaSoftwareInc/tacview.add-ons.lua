
-- Bullseye Injector for Tacview
-- Author: Erin 'BuzyBee' O'Reilly
-- Last update: 2021-04-20 (Tacview 1.8.6)

-- Feel free to modify and improve this script!

--[[

MIT License

Copyright (c) 2021-2025 Raia Software Inc.

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

local Tacview = require("Tacview186")
local telemetry = Tacview.Telemetry

local objectId = 4100000

local beginningOfTime = Tacview.Telemetry.BeginningOfTime

function InjectBullseye1()

	local objectHandle = Tacview.Telemetry.GetOrCreateObjectHandle(objectId, beginningOfTime)

	local typePropertyIndex = telemetry.GetObjectsTextPropertyIndex("Type", true)

	telemetry.SetTextSample( objectHandle , beginningOfTime , typePropertyIndex , "Navaid+Static+Bullseye" )

	local transform =
	{
		longitude = math.rad(-81),
		latitude = math.rad(43),
		altitude = 2000,
	}

	Tacview.Telemetry.SetTransform(objectHandle, beginningOfTime, transform)

end

function InjectBullseye2()

Tacview.Log.Info("Injecting Bullseye 2")

end

local objectHandle = 0

function OnContextMenu(contextMenuId, objectHandle)

	Tacview.UI.Menus.AddCommand(contextMenuId, "Inject Bullseye 1", InjectBullseye1)

	Tacview.UI.Menus.AddCommand(contextMenuId, "Inject Bullseye 2", InjectBullseye2)

end

----------------------------------------------------------------
-- Initialize this addon
----------------------------------------------------------------

function Initialize()

	-- Declare addon properties

	local currentAddOn = Tacview.AddOns.Current

	currentAddOn.SetTitle("Bullseye Injector")
	currentAddOn.SetVersion("1.8.6")
	currentAddOn.SetAuthor("BuzyBee")
	currentAddOn.SetNotes("Quickly inject a saved bullseye.")

	-- Declare context menu for the 3D view

	Tacview.UI.Renderer.ContextMenu.RegisterListener(OnContextMenu)
end

Initialize()
