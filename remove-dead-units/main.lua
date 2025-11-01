
--[[
	Remove Dead Units
	Remove dead units from battlefield.

	Author: BuzyBee
	Last update: 2025-08-19

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

local Tacview = require("Tacview194")

local done = false	

----------------------------------------------------------------
-- UI commands and options
----------------------------------------------------------------

function OnUpdate(dt, absoluteTime)

	local telemetry = Tacview.Telemetry
	local getObjectHandleByIndex = telemetry.GetObjectHandleByIndex
	local getCurrentTags = telemetry.GetCurrentTags
	local anyGivenTagActive = telemetry.AnyGivenTagActive
	local getLifeTime = telemetry.GetLifeTime
	local watercraft = telemetry.Tags.Watercraft
	local antiAircraft = telemetry.Tags.AntiAircraft
	local vehicle = telemetry.Tags.Vehicle
	local setNumericSample = telemetry.SetNumericSample
	local endOfTime = telemetry.EndOfTime
	local getTransformCount = telemetry.GetTransformCount
	local getTransformFromIndex = telemetry.GetTransformFromIndex

	local visiblePropertyIndex = Tacview.Telemetry.GetObjectsNumericPropertyIndex("Visible", true)

	local objectCount = Tacview.Telemetry.GetObjectCount()

	if not done then

		for objectIndex=0,objectCount-1,1 do
	
			local objectHandle = getObjectHandleByIndex(objectIndex)
	
			if not objectHandle then
				goto continue
			end
	
			local objectTags = getCurrentTags(objectHandle)
	
			if not objectTags then
				goto continue
			end
	
			if not anyGivenTagActive( objectTags , watercraft|antiAircraft|vehicle) then
				goto continue
			end

			local _, lifeTimeEnd = getLifeTime(objectHandle)
	
			if lifeTimeEnd < endOfTime then

				setNumericSample(objectHandle, lifeTimeEnd-1.0, visiblePropertyIndex, 0)
			end

			::continue::
		end

		done = true
	end
end

function OnDocumentLoaded()

	done = false

end
				
----------------------------------------------------------------
-- Initialize this addon
----------------------------------------------------------------

function Initialize()

	-- Declare add-on information

	Tacview.AddOns.Current.SetTitle("Remove Dead Units")
	Tacview.AddOns.Current.SetVersion("1.9.5.114")
	Tacview.AddOns.Current.SetAuthor("BuzyBee")
	Tacview.AddOns.Current.SetNotes("Remove dead units from battlefield.")

	Tacview.Events.Update.RegisterListener( OnUpdate )
	Tacview.Events.DocumentLoaded.RegisterListener( OnDocumentLoaded )

end

Initialize()
