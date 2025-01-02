
--[[
	Scoreboard Generator
	Exports a csv file of data which can be used to create a scoreboard

	Author: BuzyBee
	Last update: 2019-10-29 (Tacview 1.8.0)

	Feel free to modify and improve this script!
--]]

--[[

	MIT License

	Copyright (c) 2019-2025 Raia Software Inc.

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

local Tacview = require("Tacview180")

local scoreboard = {}

function OnUpdate( dt , absoluteTime )

	local objectCount = Tacview.Telemetry.GetObjectCount()

	for index=0,objectCount-1 do

		local objectHandle = Tacview.Telemetry.GetObjectHandleByIndex( index )

		if not objectHandle then
			return
		end
		

		local objectTags = Tacview.Telemetry.GetCurrentTags(objectHandle)

		if not objectTags then
			return
		end

		if Tacview.Telemetry.AnyGivenTagActive( objectTags , Tacview.Telemetry.Tags.FixedWing | Tacview.Telemetry.Tags.Rotorcraft  ) then

--			local eventPropertyIndex = Tacview.Telemetry.GetObjectsTextPropertyIndex("Event", false)

--			if eventPropertyIndex == Tacview.Telemetry.InvalidPropertyIndex then
--				print("Valid Property Index - event")
--			end

--			local event, isSampleValid = Tacview.Telemetry.GetTextSample(objectHandle, absoluteTime, eventPropertyIndex)

--			if not isSampleValid then
--				event = nil
--			end

			local pilotPropertyIndex = Tacview.Telemetry.GetObjectsTextPropertyIndex("Pilot", false)

			if pilotPropertyIndex == Tacview.Telemetry.InvalidPropertyIndex then
--				print("Invalid Property Index - pilot")
				return
			end

			local pilot, isSampleValid = Tacview.Telemetry.GetTextSample(objectHandle, absoluteTime, pilotPropertyIndex)
			
			local disabledPropertyIndex = Tacview.Telemetry.GetObjectsNumericPropertyIndex(Tacview.Telemetry.Property.Numeric.Disabled, false);

			if (disabledPropertyIndex == Tacview.Telemetry.InvalidPropertyIndex) then
				return
			end

			local isDisabled, isSampleValid = Tacview.Telemetry.GetTextSample(objectHandle, absoluteTime, disabledPropertyIndex)

			if isDisabled then
--				print("Object with pilot"..pilot.." is disabled = "..isDisabled)
			end

			if not isSampleValid then
--				print("Sample not valid - pilot")
			end
	
			if event then
--				print("Event: "..event)
			end

			if pilot then
--				print("pilot: "..pilot)
			end

			local pilotExists = false

			for i=1,#scoreboard do
				if scoreboard[i].pilot == pilot then
					pilotExists = true
				end
			end

			if not pilotExists then
				scoreboard[#scoreboard+1] = {pilot = pilot}
	--			print("added "..pilot.." to list:")
			end
		end
	end
end

function GenerateScoreboard()

	-- Ask the user for the target file name

	local saveFileNameOptions =
	{
		defaultFileExtension = "csv",
		fileTypeList =
		{
			{"*.csv", "Comma-separated values"}
		}
	}

	local fileName = Tacview.UI.MessageBox.GetSaveFileName(saveFileNameOptions)

	if not fileName then
		return
	end

	-- Create the csv file

	local file = io.open(fileName, "wb")

	if not file then
		Tacview.UI.MessageBox.Error("Failed to export data.\n\nEnsure there is enough space and that you have permission to save in this location.")
		return
	end

	-- Write csv file header

	print("writing csv file header")

	file:write("pilot, timesShotDown, ...\n")
	
	for i=1,#scoreboard do
		print("writing pilots to file")
		file:write(scoreboard[i].pilot.."\n")
	end

	file:close()

end



----------------------------------------------------------------
-- Add-on initialization
----------------------------------------------------------------

function Initialize()

	-- Declare add-on information

	Tacview.AddOns.Current.SetTitle("Scoreboard")
	Tacview.AddOns.Current.SetVersion("0.1")
	Tacview.AddOns.Current.SetAuthor("BuzyBee")
	Tacview.AddOns.Current.SetNotes("Exports a csv file of data which can be used to create a scoreboard")

	-- Declare menu

	Tacview.UI.Menus.AddCommand( nil , "Scoreboard" , GenerateScoreboard )

	Tacview.Events.Update.RegisterListener( OnUpdate )

end

Initialize()
