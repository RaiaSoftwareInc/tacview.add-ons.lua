
--[[
	Bookmark Injector

	Author: BuzyBee
	Last update: 2025-04-07 (Tacview 1.8.7)

	Feel free to modify and improve this script!
--]]

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

require("lua-strict")

local Tacview = require("Tacview187")

function OnInjectBookmark()

local eventPropertyIndex = Tacview.Telemetry.GetGlobalTextPropertyIndex("Event",true)

Tacview.Telemetry.SetTextSample( 0 , Tacview.Context.GetAbsoluteTime(), eventPropertyIndex , "Bookmark|Generic Bookmark")

end

----------------------------------------------------------------
-- Initialize this addon
----------------------------------------------------------------

function Initialize()

	-- Declare add-on information

	Tacview.AddOns.Current.SetTitle("Inject Bookmarks")
	Tacview.AddOns.Current.SetVersion("1.8.7")
	Tacview.AddOns.Current.SetAuthor("BuzyBee")
	Tacview.AddOns.Current.SetNotes("Inject Bookmarks")

	-- Declare menus

	local mainMenuId = Tacview.UI.Menus.AddCommand(nil, "Inject Bookmark", OnInjectBookmark)

end

Initialize()
