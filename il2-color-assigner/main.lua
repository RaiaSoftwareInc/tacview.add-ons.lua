
--[[
	IL-2 Color Assigner

	Author: BuzyBee
	Last update: 2021-07-13 (Tacview 1.8.7)

	Feel free to modify and improve this script!
--]]

--[[

	MIT License

	Copyright (c) 2021-2024 Raia Software Inc.

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

local automaticallyAssignColorsSettingName = "automaticallyAssignColors"

local AxisColor = "Red"
local AlliesColor = "Blue"

----------------------------------------------------------------
-- UI commands and options
----------------------------------------------------------------

local automaticallyAssignColorsMenuId
local automaticallyAssignColors = true
local oneTimeAssignColors=false

local telemetry = Tacview.Telemetry

function AssignColorsNow()

	local colorPropertyIndex = telemetry.GetObjectsTextPropertyIndex("Color", false) 

	if colorPropertyIndex == telemetry.InvalidPropertyIndex then
		
		return
	end

	local coalitionPropertyIndex = telemetry.GetObjectsTextPropertyIndex("Coalition", false) 

	if coalitionPropertyIndex == telemetry.InvalidPropertyIndex then
		
		return
	end

	local objectCount = telemetry.GetObjectCount()
	local count = objectCount-1

	local GetObjectHandleByIndex = telemetry.GetObjectHandleByIndex
	local GetLifeTime = telemetry.GetLifeTime
	local GetTextSample = telemetry.GetTextSample
	local GetTextSampleFromIndex = telemetry.GetTextSampleFromIndex
	local GetTextSampleCount = telemetry.GetTextSampleCount
	local SetTextSample = telemetry.SetTextSample

	local colorChangeCount = 0

	for objectCountIndex=0,count do

		local objectHandle = GetObjectHandleByIndex(objectCountIndex)

		local color = "";

		local lifeTimeBegin = GetLifeTime(objectHandle)

		local coalition, coalitionIsValid = GetTextSample(objectHandle, lifeTimeBegin, coalitionPropertyIndex )

		if not coalitionIsValid or coalition == "" then
		
			goto continue

		elseif coalition == "Allies" or coalition == "Entente" then

			color = AlliesColor

		elseif coalition == "Axis" or coalition == "Central Powers" then

			color = AxisColor

		else
			
			goto continue

		end

	    local colorSampleCount = GetTextSampleCount(objectHandle, colorPropertyIndex)

		local count = colorSampleCount - 1

		for colorSampleCountIndex=0,count do

			local colorAtIndex, timeAtIndex = GetTextSampleFromIndex(objectHandle , colorSampleCountIndex , colorPropertyIndex )

			if colorAtIndex ~= color then

				SetTextSample(objectHandle , timeAtIndex , colorPropertyIndex , color)

				colorChangeCount = colorChangeCount + 1

			end
		end

		::continue::

	end

	Tacview.UI.Update()

	Tacview.Log.Info("Reassigned the colors of " .. colorChangeCount .. " objects")
end

function AutomaticallyAssignColors()

	-- Enable/disable add-on

	automaticallyAssignColors = not automaticallyAssignColors

	-- Save option value in registry

	Tacview.AddOns.Current.Settings.SetBoolean(automaticallyAssignColorsSettingName, automaticallyAssignColors)

	-- Update menu with the new option value

	Tacview.UI.Menus.SetOption(automaticallyAssignColorsMenuId, automaticallyAssignColors)

	-- Fix pilot names if user has indicated to do so automatically

	if automaticallyAssignColors then

		Tacview.Log.Info("Automatically assigning colors");

		AssignColorsNow()

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

function OnDocumentLoaded()

	if not IsIL2Flight() then

		return
	end

	Tacview.Log.Debug("New document has been loaded")

	 -- Check if the user wants to assign colors automatically

	if automaticallyAssignColors then

		Tacview.Log.Info("Automatically assigning colors")

		AssignColorsNow()

	end
end

----------------------------------------------------------------
-- Add-on initialization
----------------------------------------------------------------

function Initialize()

	-- Declare add-on information

	Tacview.AddOns.Current.SetTitle("IL-2 Color Assigner")
	Tacview.AddOns.Current.SetVersion("1.8.7")
	Tacview.AddOns.Current.SetAuthor("BuzyBee")
	Tacview.AddOns.Current.SetNotes("Assigns colors per coalition")
	
	-- Load user preferences 

	automaticallyAssignColors = Tacview.AddOns.Current.Settings.GetBoolean(automaticallyAssignColorsSettingName, automaticallyAssignColors)

	-- Declare menus

	local mainMenuHandle = Tacview.UI.Menus.AddMenu(nil, "IL-2 Color Assigner")

	Tacview.UI.Menus.AddCommand(mainMenuHandle, "Assign Colors Now", AssignColorsNow)

	Tacview.UI.Menus.AddSeparator(mainMenuHandle)

	automaticallyAssignColorsMenuId = Tacview.UI.Menus.AddOption(mainMenuHandle, "Automatically Assign Colors", automaticallyAssignColors, AutomaticallyAssignColors)

	-- Register callbacks

	Tacview.Events.DocumentLoaded.RegisterListener(OnDocumentLoaded)

end

Initialize()


