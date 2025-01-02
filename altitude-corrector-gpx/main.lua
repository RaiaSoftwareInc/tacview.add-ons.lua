
--[[
	Altitude Corrector GPX
	When using a GPX file that has no altitude, add altitude data. 

	Author: BuzyBee
	Last update: 2024-03-19

	Feel free to modify and improve this script!
--]]

--[[

	MIT License

	Copyright (c) 2024-2025 Raia Software Inc.

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

----------------------------------------------------------------
-- Request Tacview API
----------------------------------------------------------------

local Tacview = require("Tacview193")

----------------------------------------------------------------
-- UI commands and options
----------------------------------------------------------------

local autoCorrectAltitudesMenuId

function CorrectAltitudes()

	local newTransform = {}

	local telemetry = Tacview.Telemetry
	local getObjectHandleByIndex = telemetry.GetObjectHandleByIndex
	local getTransformCount = telemetry.GetTransformCount
	local getTransformFromIndex = telemetry.GetTransformFromIndex
	local getElevation = Tacview.Terrain.GetElevation
	local setTransform = telemetry.SetTransform
	local objectCount = telemetry.GetObjectCount()

	for objectIndex=0,objectCount-1 do

		local objectHandle = getObjectHandleByIndex(objectIndex)

		local transformCount = getTransformCount(objectHandle)
		
		for transformIndex=0, transformCount-1 do

			local objectTransform = getTransformFromIndex(objectHandle, transformIndex)

			local elevation = getElevation(objectTransform.longitude, objectTransform.latitude)

			local newTransform = {altitude = elevation}

			setTransform(objectHandle, objectTransform.time, newTransform) 			
		end		
	end
end
				
----------------------------------------------------------------
-- Initialize this addon
----------------------------------------------------------------

function Initialize()

	-- Declare add-on information

	Tacview.AddOns.Current.SetTitle("Altitude Corrector GPX")
	Tacview.AddOns.Current.SetVersion("0.1")
	Tacview.AddOns.Current.SetAuthor("BuzyBee")
	Tacview.AddOns.Current.SetNotes("When using a GPX file that has no altitude, add altitude data.")

	-- Declare menus

	local mainMenuHandle = Tacview.UI.Menus.AddMenu(nil, "Correct Altitudes")

	Tacview.UI.Menus.AddCommand(mainMenuHandle, "Correct Altitudes Now", CorrectAltitudes)

end

Initialize()
