
--[[
	Clean Up

	Author: BuzyBee
	Last update: 2021-03-29 (Tacview 1.8.5)

	Feel free to modify and improve this script!
--]]

--[[

	MIT License

	Copyright (c) 2020-2025 Raia Software Inc.

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

local Tacview = require("Tacview185")

function OnCleanUp()

	local count = Tacview.Telemetry.GetObjectCount()
	
	for index=0,count-1 do
		
		local objectHandle = Tacview.Telemetry.GetObjectHandleByIndex(index) 

		if not objectHandle then 
			return 
		end

		local tags = Tacview.Telemetry.GetCurrentTags(objectHandle)

		if not tags then 
			return 
		end

		if Tacview.Telemetry.AnyGivenTagActive(tags, Tacview.Telemetry.Tags.Parachutist|Tacview.Telemetry.Tags.Ground|Tacview.Telemetry.Tags.Static) then -- amend tags here as desired
			Tacview.Telemetry.DeleteObject(objectHandle)
		end

	end
end


----------------------------------------------------------------
-- Add-on initialization
----------------------------------------------------------------

function Initialize()

	-- Declare add-on information

	Tacview.AddOns.Current.SetTitle("Clean Up")
	Tacview.AddOns.Current.SetVersion("0.0.1")
	Tacview.AddOns.Current.SetAuthor("BuzyBee")
	Tacview.AddOns.Current.SetNotes("Remove parachutes, static objects and other ground objects")

	Tacview.UI.Menus.AddCommand(nil, "Clean Up", OnCleanUp)

end

Initialize()


