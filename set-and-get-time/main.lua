
--[[
	Set and Get Time

	Author: BuzyBee
	Last update: 2023-01-11 (Tacview 1.8.8)

	Feel free to modify and improve this script!
--]]

--[[

	MIT License

	Copyright (c) 2022-2024 Raia Software Inc.

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

-- Request Tacview API

local Tacview = require("Tacview188")

function OnGetTime()

	local t = Tacview.Context.GetAbsoluteTime() 
	
	Tacview.Log.Info("Absolute Time in epoch time: " .. t)
	
	Tacview.Log.Info("Absolute Time ISO: " .. Tacview.UI.Format.AbsoluteTimeToISOText(t))
	
	
end

function OnSetTime()

	local t = Tacview.Context.GetAbsoluteTime() 
	
	Tacview.Log.Info("Current absolute Time: " .. Tacview.UI.Format.AbsoluteTimeToISOText(t))

	Tacview.Log.Info("Attempting to set time 60 seconds in the future")

	Tacview.Context.SetAbsoluteTime(t+60) 
	
end

----------------------------------------------------------------
-- Add-on initialization
----------------------------------------------------------------

function Initialize()

	-- Declare add-on information

	Tacview.AddOns.Current.SetTitle("Set and Get Time")
	Tacview.AddOns.Current.SetVersion("0.0.1")
	Tacview.AddOns.Current.SetAuthor("BuzyBee")
	Tacview.AddOns.Current.SetNotes("Tutorial on how to set and get time")

	local mainMenuHandle = Tacview.UI.Menus.AddMenu(nil, "Set and Get Time")
	
	Tacview.UI.Menus.AddCommand(mainMenuHandle, "Get Time", OnGetTime)
	Tacview.UI.Menus.AddCommand(mainMenuHandle, "Set Time", OnSetTime)


end

Initialize()


