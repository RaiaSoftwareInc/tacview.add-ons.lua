
--[[
	IL2 Off-Map Objects Corrector

	Author: BuzyBee
	Last update: 2021-06-10 (Tacview 1.8.7)

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

local automaticallyCorrectOffMapObjectsSettingName = "automaticallyCorrectOffMapObjects"

----------------------------------------------------------------
-- UI commands and options
----------------------------------------------------------------

local automaticallyCorrectOffMapObjectsMenuId
local automaticallyCorrectOffMapObjects = true

local NE = { latitude = 0, longitude = 0 }
local NW = { latitude = 0, longitude = 0 }
local SW = { latitude = 0, longitude = 0 }
local SE = { latitude = 0, longitude = 0 }

--Latitude, Longitude

local KubanMapNE			=	{ latitude = 46.117088, longitude = 40.886095	}
local KubanMapNW			=	{ latitude = 46.112218, longitude = 34.925498	}
local KubanMapSW			=	{ latitude = 42.891473, longitude = 35.090271	}
local KubanMapSE			=	{ latitude = 42.895984, longitude = 40.731265	}
local LapinoMapNE			=	{ latitude = 49.577723, longitude = 43.794728	}
local LapinoMapNW			=	{ latitude = 49.568239, longitude = 43.087967	}
local LapinoMapSW			=	{ latitude = 49.116643, longitude = 43.102813	}
local LapinoMapSE			=	{ latitude = 49.123635, longitude = 43.809349	}
local MoscowMapNE			=	{ latitude = 57.047932, longitude = 38.282119	}
local MoscowMapNW			=	{ latitude = 57.154761, longitude = 33.636291	}
local MoscowMapSW			=	{ latitude = 54.624168, longitude = 33.599982	}
local MoscowMapSE			=	{ latitude = 54.533885, longitude = 37.941891	}
local StalingradMapNE		=	{ latitude = 49.602237, longitude = 45.953233	}
local StalingradMapNW		=	{ latitude = 49.530973, longitude = 40.996637	}
local StalingradMapSW		=	{ latitude = 47.473298, longitude = 41.159367	}
local StalingradMapSE		=	{ latitude = 47.362923, longitude = 45.912041	}
local VelikieLukiMapNE		=	{ latitude = 56.806699, longitude = 32.145355	}
local VelikieLukiMapNW		=	{ latitude = 56.757228, longitude = 29.422955	}
local VelikieLukiMapSW		=	{ latitude = 55.844423, longitude = 29.509774	}
local VelikieLukiMapSE		=	{ latitude = 55.884366, longitude = 32.164108	}
local NovosokolnikiMapNE	=	{ latitude = 56.710744, longitude = 30.290218	}
local NovosokolnikiMapNW	=	{ latitude = 56.693419, longitude = 29.458388	}
local NovosokolnikiMapSW	=	{ latitude = 56.236752, longitude = 29.495079	}
local NovosokolnikiMapSE	=	{ latitude = 56.252849, longitude = 30.324977	}
local RheinlandMapNE		=	{ latitude = 53.015184, longitude = 9.76978  	}
local RheinlandMapNW		=	{ latitude = 52.927625, longitude = 2.929092 	}
local RheinlandMapSW		=	{ latitude = 49.486400, longitude = 3.276128 	}
local RheinlandMapSE		=	{ latitude = 49.571031, longitude = 9.66031  	}
local ProkhorovkaMapNE		=	{ latitude = 51.536902, longitude = 37.63975	}
local ProkhorovkaMapNW		=	{ latitude = 51.525432, longitude = 35.241902	}
local ProkhorovkaMapSE		=	{ latitude = 50.041191, longitude = 37.619654	}	--	Swapped SW and SE
local ProkhorovkaMapSW		=	{ latitude = 50.030331, longitude = 35.297094	}	--	Swapped SW and SE
local ArrasMapNW			=	{ latitude = 51.054814, longitude = 1.664433	}	--	Swapped NE and NW
local ArrasMapNE			=	{ latitude = 51.057829, longitude = 4.038734 	} 	--	Swapped NE and NW
local ArrasMapSE			=	{ latitude = 49.561537, longitude = 4.006636	}
local ArrasMapSW			=	{ latitude = 49.558677, longitude = 1.705698	}

local map

local telemetry = Tacview.Telemetry

function IsIL2Flight()

	-- Check if this is an IL-2 flight

	local sourcePropertyIndex = telemetry.GetGlobalTextPropertyIndex( "DataSource" , false )

	if sourcePropertyIndex == telemetry.InvalidPropertyIndex then
		return false
	end

	local simulator, sampleIsValid = telemetry.GetTextSample( 0, telemetry.BeginningOfTime , sourcePropertyIndex) 

	if simulator == "IL-2 Sturmovik" then

		return true

	end

	return false

end

function DetermineMap()

	-- Determine which IL-2 map is being used and load the appropriate coordinates.

	if not IsIL2Flight() then
		Tacview.Log.Info("Not an IL_2 flight")
		return false
	end


	local objectHandle = telemetry.GetObjectHandleByIndex(0)

	if not objectHandle then
		Tacview.Log.Debug("No object found")
		return false
	end

	local transform = telemetry.GetTransformFromIndex(objectHandle, 0)

	if not transform then
		Tacview.Log.Debug("No position data found found")
		return false
	end

	-- All IL-2 maps are north of 0 and east of 0 so we do not have to worry about negative numbers.

	-- Be sure to compare against both SW coordinates since objects seem to spawn in bottom-left corner at exactly those coordinates.

	if(	math.deg(transform.latitude) <= KubanMapNW.latitude and 
		math.deg(transform.latitude) >= KubanMapSW.latitude and
		math.deg(transform.longitude) <= KubanMapSE.longitude and
		math.deg(transform.longitude) >= KubanMapSW.longitude) then

		NE = KubanMapNE
        NW = KubanMapNW
		SW = KubanMapSW
        SE = KubanMapSE

		Tacview.Log.Info("Kuban map detected")

		return true

	elseif (	math.deg(transform.latitude) <= LapinoMapNW.latitude and 
				math.deg(transform.latitude) >= LapinoMapSW.latitude and
				math.deg(transform.longitude) <= LapinoMapSE.longitude and
				math.deg(transform.longitude) >= LapinoMapSW.longitude) then

		NE = LapinoMapNE
        NW = LapinoMapNW
		SW = LapinoMapSW
        SE = LapinoMapSE

		Tacview.Log.Info("Lapino map detected")

		return true

	elseif (	math.deg(transform.latitude) <= MoscowMapNW.latitude and 
				math.deg(transform.latitude) >= MoscowMapSW.latitude and
				math.deg(transform.longitude) <= MoscowMapSE.longitude and
				math.deg(transform.longitude) >= MoscowMapSW.longitude) then

		NE = MoscowMapNE
        NW = MoscowMapNW
		SW = MoscowMapSW
        SE = MoscowMapSE

		Tacview.Log.Info("Moscow map detected")

		return true

	elseif (	math.deg(transform.latitude) <= StalingradMapNW.latitude and 
				math.deg(transform.latitude) >= StalingradMapSW.latitude and
				math.deg(transform.longitude) <= StalingradMapSE.longitude and
				math.deg(transform.longitude) >= StalingradMapSW.longitude) then

		NE = StalingradMapNE
        NW = StalingradMapNW
		SW = StalingradMapSW
        SE = StalingradMapSE

		Tacview.Log.Info("Stalingrad map detected")

		return true

	elseif (	math.deg(transform.latitude) <= VelikieLukiMapNW.latitude and 
				math.deg(transform.latitude) >= VelikieLukiMapSW.latitude and
				math.deg(transform.longitude) <= VelikieLukiMapSE.longitude and
				math.deg(transform.longitude) >= VelikieLukiMapSW.longitude) then

		NE = VelikieLukiMapNE
        NW = VelikieLukiMapNW
		SW = VelikieLukiMapSW
        SE = VelikieLukiMapSE

		Tacview.Log.Info("Velikie Luki map detected")

		return true

	elseif (	math.deg(transform.latitude) <= NovosokolnikiMapNW.latitude and 
				math.deg(transform.latitude) >= NovosokolnikiMapSW.latitude and
				math.deg(transform.longitude) <= NovosokolnikiMapSE.longitude and
				math.deg(transform.longitude) >= NovosokolnikiMapSW.longitude) then

		NE = NovosokolnikiMapNE
        NW = NovosokolnikiMapNW
		SW = NovosokolnikiMapSW
        SE = NovosokolnikiMapSE

		Tacview.Log.Info("Novosokolniki map detected")

		return true

	elseif (	math.deg(transform.latitude) <= RheinlandMapNW.latitude and 
				math.deg(transform.latitude) >= RheinlandMapSW.latitude and
				math.deg(transform.longitude) <= RheinlandMapSE.longitude and
				math.deg(transform.longitude) >= RheinlandMapSW.longitude) then

		NE = RheinlandMapNE
        NW = RheinlandMapNW
		SW = RheinlandMapSW
        SE = RheinlandMapSE

		Tacview.Log.Info("Rheinland map detected")

		return true

	elseif (	math.deg(transform.latitude) <= ProkhorovkaMapNW.latitude and 
				math.deg(transform.latitude) >= ProkhorovkaMapSW.latitude and
				math.deg(transform.longitude) <= ProkhorovkaMapSE.longitude and
				math.deg(transform.longitude) >= ProkhorovkaMapSW.longitude) then

		NE = ProkhorovkaMapNE
        NW = ProkhorovkaMapNW
		SW = ProkhorovkaMapSW
        SE = ProkhorovkaMapSE

		Tacview.Log.Info("Prokhorovka map detected")

		return true

	elseif (	math.deg(transform.latitude) <= ArrasMapNW.latitude and 
				math.deg(transform.latitude) >= ArrasMapSW.latitude and
				math.deg(transform.longitude) <= ArrasMapSE.longitude and
				math.deg(transform.longitude) >= ArrasMapSW.longitude) then

		NE = ArrasMapNE
        NW = ArrasMapNW
		SW = ArrasMapSW
        SE = ArrasMapSE

		Tacview.Log.Info("Arras map detected")

		return true

	end

	Tacview.Log.Info("No IL-2 map detected")

	return false
end

function CorrectOffMapObjectsNow()

	if not DetermineMap() then
		return 
	end

	-- Check each transform of each object. If it is off the map, remove it.

	local objectCount = telemetry.GetObjectCount()

	local GetTransformCount = telemetry.GetTransformCount
	local GetTransformFromIndex  = telemetry.GetTransformFromIndex
	local RemoveTransformSample = telemetry.RemoveTransformSample
	local GetCurrentShortName = telemetry.GetCurrentShortName
	local GetObjectHandleByIndex = telemetry.GetObjectHandleByIndex 
	local DeleteObject = telemetry.DeleteObject
	local RemoveTransformSampleFromIndex = telemetry.RemoveTransformSampleFromIndex

	local numberOfObjectDeleted = 0
	local totalNumberOfTransformSamplesDeleted = 0

	local count = objectCount-1

	for objectIndex=count,0,-1 do

		local objectHandle = GetObjectHandleByIndex(objectIndex)

		if not objectHandle then
			goto nextObject
		end		

		local transformCount = GetTransformCount(objectHandle)

		local currentNumberOfTransformSamplesDeleted = 0

		local tcount = transformCount-1

		for transformCountIndex = tcount,0,-1 do

			local transform = GetTransformFromIndex(objectHandle,transformCountIndex)

			if not transform.latitude then
				goto nextTransform
			end

			if not transform.longitude then
				goto nextTransform		
			end

			if	math.deg(transform.latitude) - SW.latitude < 0.1 or
				math.deg(transform.longitude) - SW.longitude < 0.1 then

				RemoveTransformSampleFromIndex(objectHandle, transformCountIndex)

				currentNumberOfTransformSamplesDeleted = currentNumberOfTransformSamplesDeleted + 1

				totalNumberOfTransformSamplesDeleted = totalNumberOfTransformSamplesDeleted + 1

			end

			::nextTransform::
		end

		if currentNumberOfTransformSamplesDeleted == transformCount then

			DeleteObject(objectHandle)

			numberOfObjectDeleted = numberOfObjectDeleted + 1
		
		end

		::nextObject::
	end

	Tacview.UI.Update()

	Tacview.Log.Info("Deleted " .. totalNumberOfTransformSamplesDeleted .. " transform samples and " .. numberOfObjectDeleted .. " objects.")

end

function AutomaticallyCorrectOffMapObjects()

	-- Enable/disable add-on

	automaticallyCorrectOffMapObjects = not automaticallyCorrectOffMapObjects

	-- Save option value in registry

	Tacview.AddOns.Current.Settings.SetBoolean(automaticallyCorrectOffMapObjectsSettingName, automaticallyCorrectOffMapObjects)

	-- Update menu with the new option value

	Tacview.UI.Menus.SetOption(automaticallyCorrectOffMapObjectsMenuId, automaticallyCorrectOffMapObjects)

	-- Fix pilot names if user has indicated to do so automatically

	if automaticallyCorrectOffMapObjects then

		Tacview.Log.Info("Automatically correcting off-map objects pilot names");

		CorrectOffMapObjectsNow()

	end

end

function OnDocumentLoaded()

	if not IsIL2Flight() then

		return
	end

	Tacview.Log.Debug("New document has been loaded")

	--Check if the user wants to correct off-map objects automatically

	if automaticallyCorrectOffMapObjects then

		Tacview.Log.Info("Automatically correcting off-map objects")

		CorrectOffMapObjectsNow()

	end
end

----------------------------------------------------------------
-- Add-on initialization
----------------------------------------------------------------

function Initialize()

	-- Declare add-on information

	Tacview.AddOns.Current.SetTitle("IL-2 Off-Map Objects Corrector")
	Tacview.AddOns.Current.SetVersion("1.8.7")
	Tacview.AddOns.Current.SetAuthor("BuzyBee")
	Tacview.AddOns.Current.SetNotes("Correct errors caused by objects spawning off-map")

	-- Load user preferences 

	automaticallyCorrectOffMapObjects = Tacview.AddOns.Current.Settings.GetBoolean(automaticallyCorrectOffMapObjectsSettingName, automaticallyCorrectOffMapObjects)

	-- Declare menus

	local mainMenuHandle = Tacview.UI.Menus.AddMenu(nil, "IL-2 Off-Map Objects Corrector")

	Tacview.UI.Menus.AddCommand(mainMenuHandle, "Correct Off-Map Objects Now", CorrectOffMapObjectsNow)

	Tacview.UI.Menus.AddSeparator(mainMenuHandle)

	automaticallyCorrectOffMapObjectsMenuId = Tacview.UI.Menus.AddOption(mainMenuHandle, "Automatically Correct Off-Map Objects", automaticallyCorrectOffMapObjects, AutomaticallyCorrectOffMapObjects)

	-- Register callbacks

	Tacview.Events.DocumentLoaded.RegisterListener(OnDocumentLoaded)

end

Initialize()


