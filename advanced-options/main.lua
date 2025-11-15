
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

require("lua-strict")
require("latitude-longitude-grid")
require("auto-terrain-switch")

local Tacview = require("Tacview194")

----------------------------------------------------------------
-- Initialize this addon
----------------------------------------------------------------

function Initialize()

	-- Declare addon properties

	local currentAddOn = Tacview.AddOns.Current

	currentAddOn.SetTitle("Advanced Options")
	currentAddOn.SetVersion("1.9.5")
	currentAddOn.SetAuthor("BuzyBee")
	currentAddOn.SetNotes("Advanced tools and options extending Tacview beyond its built-in features.")

	-- Declare menus options

	local advancedOptionsMenuHandle =  Tacview.UI.Menus.AddMenu(nil, "Advanced Options")

	InitializeAutoTerrainSwitch(advancedOptionsMenuHandle)
	InitializeLatitudeLongitudeGrid(advancedOptionsMenuHandle)

end

Initialize()
