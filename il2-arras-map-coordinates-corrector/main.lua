
--[[
	IL2 Arras Map EW Swapper

	Author: BuzyBee
	Last update: 2021-09-27 (Tacview 1.8.7)

	Feel free to modify and improve this script!
--]]

--[[

	MIT License

	Copyright (c) 2021 Raia Software Inc.

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

local Tacview = require("Tacview187")

----------------------------------------------------------------
-- Constants
----------------------------------------------------------------

local automaticallyCorrectCoordinatesSettingName = "automaticallyCorrectCoordinates"

----------------------------------------------------------------
-- UI commands and options
----------------------------------------------------------------

local automaticallyCorrectCoordinatesMenuId
local automaticallyCorrectCoordinates = true

local ArrasMapNW			=	{ latitude = 51.054814, longitude = 1.664433	}
local ArrasMapNE			=	{ latitude = 51.057829, longitude = 4.038734 	}
local ArrasMapSE			=	{ latitude = 49.561537, longitude = 4.006636	}
local ArrasMapSW			=	{ latitude = 49.558677, longitude = 1.705698	}

local East = (ArrasMapNE.longitude + ArrasMapSE.longitude) / 2
local West = (ArrasMapNW.longitude + ArrasMapSW.longitude) / 2 

local map

local Telemetry = Tacview.Telemetry

function IsIL2Flight()

	-- Check if this is an IL-2 flight

	local sourcePropertyIndex = Telemetry.GetGlobalTextPropertyIndex( "DataSource" , false )

	if sourcePropertyIndex == Telemetry.InvalidPropertyIndex then
		return false
	end

	local simulator, sampleIsValid = Telemetry.GetTextSample( 0, Telemetry.BeginningOfTime , sourcePropertyIndex) 

	if simulator == "IL-2 Sturmovik" then

		return true

	end

	return false

end

function IsArrasMap()

	-- Determine if Arras Map is being used.

	if not IsIL2Flight() then
		Tacview.Log.Info("Not an IL_2 flight")
		return false
	end

	local objectHandle = Telemetry.GetObjectHandleByIndex(0)

	if not objectHandle then
		Tacview.Log.Debug("No object found")
		return false
	end

	local transform = Telemetry.GetTransformFromIndex(objectHandle, 0)

	if not transform then
		Tacview.Log.Debug("No position data found found")
		return false
	end

	if (	math.deg(transform.latitude) <= ArrasMapNW.latitude and 
			math.deg(transform.latitude) >= ArrasMapSW.latitude and
			math.deg(transform.longitude) <= ArrasMapSE.longitude and
			math.deg(transform.longitude) >= ArrasMapSW.longitude) then

		Tacview.Log.Info("Arras map detected")

		return true
	end

	return false
end

function CorrectCoordinatesNow()

	if not IsArrasMap() then
		return 
	end

	-- Check each transform of each object. If it is off the map, remove it.

	local objectCount = Telemetry.GetObjectCount()

	local GetTransformCount = Telemetry.GetTransformCount
	local GetTransformFromIndex  = Telemetry.GetTransformFromIndex
	local RemoveTransformSample = Telemetry.RemoveTransformSample
	local GetCurrentShortName = Telemetry.GetCurrentShortName
	local GetObjectHandleByIndex = Telemetry.GetObjectHandleByIndex 
	local SetTransform = Telemetry.SetTransform

	local count = objectCount-1

	for objectIndex=count,0,-1 do

		local objectHandle = GetObjectHandleByIndex(objectIndex)

		if not objectHandle then
			goto nextObject
		end		

		local transformCount = GetTransformCount(objectHandle)

		local tcount = transformCount-1

		for transformCountIndex = tcount,0,-1 do

			local transform = GetTransformFromIndex(objectHandle,transformCountIndex)

			if not transform.longitude then
				goto nextTransform		
			end

			local correctedLongitude = math.rad(West) - (transform.longitude - math.rad(East))

			local newTransform = {longitude = correctedLongitude}

			SetTransform(objectHandle, transform.time, newTransform) 

			::nextTransform::
		end

		::nextObject::
	end
end

----------------------------------------------------------------
-- Add-on initialization
----------------------------------------------------------------

function Initialize()

	-- Declare add-on information

	Tacview.AddOns.Current.SetTitle("IL-2 Arras Map Coordinates Corrector")
	Tacview.AddOns.Current.SetVersion("1.8.7")
	Tacview.AddOns.Current.SetAuthor("BuzyBee")
	Tacview.AddOns.Current.SetNotes("Swap East and West Coordinates in IL-2 Arras Map")

	-- Declare menus

	local mainMenuHandle = Tacview.UI.Menus.AddMenu(nil, "IL-2 Arras Map Coordinates Corrector")

	Tacview.UI.Menus.AddCommand(mainMenuHandle, "Correct Coordinates Now", CorrectCoordinatesNow)
end

Initialize()


