
--[[
	AGL to ASL
	Convert AGL to ASL.

	Author: BuzyBee
	Last update: 2023-11-21 (Tacview 1.9.0)

	Feel free to modify and improve this script!
--]]

--[[

	MIT License

	Copyright (c) 2023-2025 Raia Software Inc.

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

local Tacview = require("Tacview190")

----------------------------------------------------------------
-- UI commands and options
----------------------------------------------------------------

local telemetry = Tacview.Telemetry
local getObjectHandleByIndex = telemetry.GetObjectHandleByIndex
local getTransformCount = telemetry.GetTransformCount
local getTransformFromIndex = telemetry.GetTransformFromIndex
local getElevation = Tacview.Terrain.GetElevation
local setTransform = telemetry.SetTransform
local getCurrentShortName = telemetry.GetCurrentShortName

local objectCount = telemetry.GetObjectCount()

local data = {}

function CorrectAltitudes()

	for objectIndex=0,objectCount-1 do
	
		local objectHandle = getObjectHandleByIndex(objectIndex)

		local shortName = getCurrentShortName(objectHandle)

		local transformCount = getTransformCount(objectHandle)
		
		for transformIndex=0, transformCount-1 do

			local objectTransform = getTransformFromIndex(objectHandle, transformIndex)
			
			local elevation = getElevation(objectTransform.longitude, objectTransform.latitude)
			
			objectTransform.altitude = objectTransform.altitude + elevation
			
			data[#data+1] = {tostring(objectTransform.time), objectTransform.longitude, objectTransform.latitude, objectTransform.altitude}

			setTransform(objectHandle, objectTransform.time, objectTransform )
			
		end				
	end	
		
	local file = io.open(Tacview.AddOns.Current.GetPath() .. "data.csv", "w")
	
	file:write("time,longitude, latitude, altitude\n")
	
	for i=1,#data do
		file:write(string.format("%2f",data[i][1]) .. ", " .. math.deg(data[i][2]) .. ", "..math.deg(data[i][3])..", "..string.format("%2f",data[i][4]) .. "\n")
		--print(string.format("%2f",data[i][1]) .. ", " .. math.deg(data[i][2]) .. ", "..math.deg(data[i][3])..", "..string.format("%2f",data[i][4]) .. "\n")

	end
	
	file:close()

end

----------------------------------------------------------------
-- Initialize this addon
----------------------------------------------------------------

function Initialize()

	-- Declare add-on information

	Tacview.AddOns.Current.SetTitle("AGL to ASL")
	Tacview.AddOns.Current.SetVersion("0.1")
	Tacview.AddOns.Current.SetAuthor("BuzyBee")
	Tacview.AddOns.Current.SetNotes("Convert AGL to ASL.")

	-- Declare menus

	Tacview.UI.Menus.AddCommand(nil, "AGL to ASL", CorrectAltitudes)

end

Initialize()
