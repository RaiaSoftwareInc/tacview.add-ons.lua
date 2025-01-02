
--[[
	IL2 Distant Objects Corrector

	Author: BuzyBee
	Last update: 2022-02-17 (Tacview 1.8.8)

	Feel free to modify and improve this script!
--]]

--[[

	MIT License

	Copyright (c) 2022-2025 Raia Software Inc.

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

local automaticallyDisplayDistantObjectsSettingName = "automaticallyDisplayDistantObjects"

----------------------------------------------------------------
-- UI commands and options
----------------------------------------------------------------

local automaticallyDisplayDistantObjectsMenuId
local automaticallyDisplayDistantObjects = true

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

function DisplayDistantObjectsNow()

	local objectCount = Telemetry.GetObjectCount()

	local GetTransformCount = Telemetry.GetTransformCount
	local GetTransformFromIndex  = Telemetry.GetTransformFromIndex
	local RemoveTransformSample = Telemetry.RemoveTransformSample
	local GetCurrentShortName = Telemetry.GetCurrentShortName
	local GetObjectHandleByIndex = Telemetry.GetObjectHandleByIndex 
	local SetTransform = Telemetry.SetTransform
	local GetCurrentTags = Telemetry.GetCurrentTags
	local AnyGivenTagActive = Telemetry.AnyGivenTagActive
	local GetAbsoluteTime = Tacview.Context.GetAbsoluteTime
	local GetDistanceBetweenObjects = Tacview.Math.Vector.GetDistanceBetweenObjects
	local GetObjectId = Telemetry.GetObjectId

	local namePropertyIndex = Telemetry.GetObjectsTextPropertyIndex("Name" , true)
	
	for objectIndex=objectCount-1,0,-1 do

		local objectHandle = GetObjectHandleByIndex(objectIndex)

		if not objectHandle then
			goto nextObject
		end

		local objectTags = GetCurrentTags(objectHandle)

		if not objectTags then
			goto nextObject
		end

		if not AnyGivenTagActive(objectTags , Telemetry.Tags.FixedWing) then
			goto nextObject
		end

		local transformCount = GetTransformCount(objectHandle)

		--print(transformCount .. " transforms found for object " .. Telemetry.GetObjectId(objectHandle))

		for transformCountIndex = transformCount-1,0,-1 do

			--print(transformCountIndex)

			local transform = GetTransformFromIndex(objectHandle, transformCountIndex)
			
			-- compare to every DistantLOD to see if it is too close

			local objectComparisonCount = objectCount

			for objectComparisonIndex=objectComparisonCount-1,0,-1 do

				local objectComparisonHandle = GetObjectHandleByIndex(objectComparisonIndex)

				if not objectComparisonHandle then
					goto nextObjectComparison
				end		
				
				local name = Telemetry.GetTextSample(objectComparisonHandle, GetAbsoluteTime(), namePropertyIndex )

				print("found comparison object with name " .. name)

				if string.find(name, "DistantLOD") then

					print("Found the name DistantLOD in a comparison object")

					local transformComparisonCount = GetTransformCount(objectComparisonHandle)

					for transformComparisonIndex=transformComparisonCount,0,-1 do

						local transformComparison = GetTransformFromIndex(objectComparisonHandle,transformComparisonIndex)

						local distance = GetDistanceBetweenObjects(transformComparison,transform)

						if(distance < 100) then
							print(GetObjectId(objectHandle) .. " is too close to " .. GetObjectId(objectComparisonHandle))
						end
					end
				end
			::nextObjectComparison::
			end
		end
		::nextObject::
	end
end

----------------------------------------------------------------
-- Add-on initialization
----------------------------------------------------------------

function Initialize()

	-- Declare add-on information

	Tacview.AddOns.Current.SetTitle("IL-2 Distant Object Display")
	Tacview.AddOns.Current.SetVersion("1.8.8")
	Tacview.AddOns.Current.SetAuthor("BuzyBee")
	Tacview.AddOns.Current.SetNotes("Display distant objects where data is available")

	-- Declare menus

	local mainMenuHandle = Tacview.UI.Menus.AddMenu(nil, "IL-2 Distant Object Display")

	Tacview.UI.Menus.AddCommand(mainMenuHandle, "Display Distant Objects Now", DisplayDistantObjectsNow)
end

Initialize()


