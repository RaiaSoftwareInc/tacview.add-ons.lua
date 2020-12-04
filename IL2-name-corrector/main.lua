
--[[
	IL-2 Name Corrector
	Correct the way IL-2 displays names

	Author: BuzyBee
	Last update: 2019-12-17 (Tacview 1.8.2)

	Feel free to modify and improve this script!
--]]

--[[

	MIT License

	Copyright (c) 2019 Raia Software Inc.

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

local Tacview = require("Tacview183")

----------------------------------------------------------------
-- Constants
----------------------------------------------------------------

local automaticallyFixIL2PilotNamesSettingName = "automaticallyFixIL2PilotNames"

----------------------------------------------------------------
-- UI commands and options
----------------------------------------------------------------

local automaticallyFixPilotNamesMenuId
local automaticallyFixIL2PilotNames = true
local oneTimeFixIL2PilotNames=false

function FixPilotNamesNow()

	if not IsIL2Flight() then
		return
	end
	
	-- Cache Tacview API (optimization)

	local telemetry = Tacview.Telemetry
	local tags = telemetry.Tags
	local getCurrentTags = telemetry.GetCurrentTags

	-- Retrieve the list of currently active (alive) objects

	local numberOfObjects = Tacview.Telemetry.GetObjectCount()

	local pilotPropertyIndex = telemetry.GetObjectsTextPropertyIndex( "Pilot" , false )

	if pilotPropertyIndex == telemetry.InvalidPropertyIndex then
		Tacview.Log.Debug("IL-2 NAME CORRECTOR: Pilot property index is invalid - unable to proceed with fixing any pilot names")
		return
	end	

	local namePropertyIndex = telemetry.GetObjectsTextPropertyIndex("Name",false)

	if namePropertyIndex == telemetry.InvalidPropertyIndex then
		Tacview.Log.Debug("IL-2 NAME CORRECTOR: Name property index is invalid - unable to proceed with fixing any pilot names")
		return
	end	

	for i=0,numberOfObjects-1 do

		local objectHandle = Tacview.Telemetry.GetObjectHandleByIndex(i)

		-- If pilot name exists, do nothing.

		local existingPilotName, sampleIsValid = telemetry.GetTextSample(objectHandle, Tacview.Telemetry.BeginningOfTime, pilotPropertyIndex)

		if not sampleIsValid then

			-- Parse out the pilot name for Fixed Wing or Tank objects

			local objectTags = getCurrentTags(objectHandle)

			if (objectTags & tags.FixedWing) ~= 0 or (objectTags & tags.Tank) ~= 0 then
							
				-- Retrieve IL-2 Generated Name

				local IL2GeneratedName, sampleIsValid = telemetry.GetTextSample(objectHandle, Tacview.Telemetry.BeginningOfTime, namePropertyIndex)

				if sampleIsValid then

					--------------------------------------------------------------------
					-- Determine which part of the IL2 Generated Name is the pilot name,
					-- and set Pilot Text Sample accordingly.
					--------------------------------------------------------------------


					if IL2GeneratedName:reverse():find("%s+%-+%s+") then

						local startChar = #IL2GeneratedName - IL2GeneratedName:reverse():find("%s+%-+%s+") + 2

						if startChar then

							local pilotName = string.sub(IL2GeneratedName,startChar)

							pilotName = trim(pilotName)

							telemetry.SetTextSample( objectHandle , Tacview.Telemetry.BeginningOfTime , pilotPropertyIndex , pilotName ) 
							
						end
					end
				end
				

				
			end
		end
	end
	
	Tacview.UI.Update()

end

function OnMenuAutomaticallyFixPilotNames()

	-- Enable/disable add-on

	automaticallyFixIL2PilotNames = not automaticallyFixIL2PilotNames

	-- Save option value in registry

	Tacview.AddOns.Current.Settings.SetBoolean(automaticallyFixIL2PilotNamesSettingName, automaticallyFixIL2PilotNames)

	-- Update menu with the new option value

	Tacview.UI.Menus.SetOption(automaticallyFixPilotNamesMenuId, automaticallyFixIL2PilotNames)

	-- Fix pilot names if user has indicated to do so automatically

	if automaticallyFixIL2PilotNames then

		Tacview.Log.Info("IL-2 NAME CORRECTOR: Automatically fixing pilot names");

		FixPilotNamesNow()

	end

end

-- OnDocumetLoaded is called by Tacview when a document is loaded

function OnDocumentLoaded()

	if not IsIL2Flight() then

		return
	end

	Tacview.Log.Info("IL-2 NAME CORRECTOR: New document has been loaded")

	-- Check if the user wants to correct IL2 names automatically

	if automaticallyFixIL2PilotNames then

		Tacview.Log.Info("IL-2 NAME CORRECTOR: Automatically fixing pilot names")

		FixPilotNamesNow()

	end
end

function IsIL2Flight()

	-- Check if this is an IL-2 flight

	local sourcePropertyIndex = Tacview.Telemetry.GetGlobalTextPropertyIndex( "DataSource" , false )

	if sourcePropertyIndex == Tacview.Telemetry.InvalidPropertyIndex then
		return false
	end

	local simulator, sampleIsValid = Tacview.Telemetry.GetTextSample( 0, Tacview.Telemetry.BeginningOfTime , sourcePropertyIndex) 

	if simulator == "IL-2 Sturmovik" then

		return true

	end

	return false

end

--[[	
function StartsWith(str, start)

	str = str.toLowerCase()
	start = start.toLowerCase

	return str:sub(1, #start) == start

end	
--]]

function trim(s)

  return (s:gsub("^%s*(.-)%s*$", "%1"))

end

----------------------------------------------------------------
-- Initialize this addon
----------------------------------------------------------------

function Initialize()

	-- Declare add-on information

	Tacview.AddOns.Current.SetTitle("IL-2 Name Corrector")
	Tacview.AddOns.Current.SetVersion("1.0")
	Tacview.AddOns.Current.SetAuthor("BuzyBee")
	Tacview.AddOns.Current.SetNotes("Correct the way IL-2 displays names.")

	-- Load user preferences 

	automaticallyFixIL2PilotNames = Tacview.AddOns.Current.Settings.GetBoolean(automaticallyFixIL2PilotNamesSettingName, automaticallyFixIL2PilotNames)

	-- Declare menus

	local mainMenuHandle = Tacview.UI.Menus.AddMenu(nil, "Correct IL2 Names")

	Tacview.UI.Menus.AddCommand(mainMenuHandle, "Fix Pilot Names Now", FixPilotNamesNow)

	automaticallyFixPilotNamesMenuId = Tacview.UI.Menus.AddOption(mainMenuHandle, "Automatically Fix Pilot Names", automaticallyFixIL2PilotNames, OnMenuAutomaticallyFixPilotNames)

	-- Register callbacks

	Tacview.Events.DocumentLoaded.RegisterListener(OnDocumentLoaded)

end

Initialize()
