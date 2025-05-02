
--[[
	One File Per Client

	Author: BuzyBee
	Last update: 2025-04-10 (Tacview 1.9.4)

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

local PilotToTrack = "New callsign"

-- Request Tacview API

local Tacview = require("Tacview195")

local previousObjectHandle = nil

function OnUpdate(dt, absoluteTime)

	local pilotPropertyIndex = Tacview.Telemetry.GetObjectsTextPropertyIndex("Pilot", false)
	
	if pilotPropertyIndex == Tacview.Telemetry.InvalidPropertyIndex then
		return
	end

	local activeObjects = Tacview.Context.GetActiveObjectList()

	for _,objectHandle in ipairs(activeObjects) do

		local pilot, sampleIsValid = Tacview.Telemetry.GetTextSample(objectHandle, absoluteTime, pilotPropertyIndex) 

		if not sampleIsValid then
			goto continue
		end

		if pilot == PilotToTrack then
			if previousObjectHandle == nil then
				previousObjectHandle = objectHandle
			elseif previousObjectHandle ~= objectHandle then
				Tacview.Telemetry.Save("C:/Downloads/"..PilotToTrack.."_"..math.floor(absoluteTime)..".zip.acmi")
				Tacview.Telemetry.Clear()
				previousObjectHandle = nil
				return
			end
		end

		::continue::
	end
end


----------------------------------------------------------------
-- Add-on initialization
----------------------------------------------------------------

function Initialize()

	-- Declare add-on information

	Tacview.AddOns.Current.SetTitle("One File Per Client")
	Tacview.AddOns.Current.SetVersion("1.9.4")
	Tacview.AddOns.Current.SetAuthor("BuzyBee")
	Tacview.AddOns.Current.SetNotes("Save a file whenever the pilot changes slots.")

	Tacview.Events.Update.RegisterListener(OnUpdate) 	

end

Initialize()


