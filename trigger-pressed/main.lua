
--[[
	Trigger Pressed Indicator

	Author: BuzyBee
	Last update: 2022-11-22 (Tacview 1.9.0)

	Feel free to modify and improve this script!
--]]

--[[

	MIT License

	Copyright (c) 2022-2024 Raia Software Inc.

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

local Tacview = require("Tacview190")

----------------------------------------------------------------
-- Constants
----------------------------------------------------------------

local settingName = "triggerPressedIndicator"

----------------------------------------------------------------
-- UI commands and options
----------------------------------------------------------------

local addOnEnabled = false
local subMenuId

----------------------------------------------------------------

function OnMenuEnableAddOn()

	-- Enable/disable add-on

	addOnEnabled = not addOnEnabled

	-- Save option value in registry

	Tacview.AddOns.Current.Settings.SetBoolean(settingName, addOnEnabled)

	-- Update menu with the new option value

	Tacview.UI.Menus.SetOption(subMenuId, addOnEnabled)

end

function OnDocumentLoaded()

	-- look for instances where TriggerPressed = 1 and inject events accordingly

	local Telemetry = Tacview.Telemetry
	local GetObjectHandleByIndex = Telemetry.GetObjectHandleByIndex 
	local GetCurrentTags = Telemetry.GetCurrentTags
	local AnyGivenTagActive = Telemetry.AnyGivenTagActive
	local GetNumericSampleFromIndex = Telemetry.GetNumericSampleFromIndex
	local GetNumericSamplenumberOfMessagesToDisplay = Telemetry.GetNumericSamplenumberOfMessagesToDisplay
	local SetTextSample = Telemetry.SetTextSample
	
	local triggerPressedPropertyIndex = Telemetry.GetObjectsNumericPropertyIndex("TriggerPressed", false)
	
	if triggerPressedPropertyIndex == Telemetry.InvalidPropertyIndex then
		Tacview.Log.Info("No trigger press detected")
		return
	end
	
	local eventPropertyIndex = Telemetry.GetGlobalTextPropertyIndex("Event", true) 

	local objectCount = Telemetry.GetObjectCount()
	
	for objectIndex=objectCount-1,0,-1 do

		local objectHandle = GetObjectHandleByIndex(objectIndex)

		if not objectHandle then
			goto continue
		end

		local objectTags = GetCurrentTags(objectHandle)

		if not objectTags then
			goto continue
		end

		if not AnyGivenTagActive(objectTags , Telemetry.Tags.FixedWing) then
			goto continue
		end
		
		local sampleIndex = Telemetry.GetNumericSampleCount( objectHandle , triggerPressedPropertyIndex )
		
		for i=0,sampleIndex,1 do
		
			local triggerPressed, absoluteTime = GetNumericSampleFromIndex(objectHandle,i,triggerPressedPropertyIndex)
			
			if triggerPressed == 1 then
				
				Tacview.Log.Info("Trigger pressed at " .. Tacview.UI.Format.AbsoluteTimeToISOText( absoluteTime))
				
				local objectId = Telemetry.GetObjectId(objectHandle)
				
				SetTextSample(0, absoluteTime, eventPropertyIndex, "Message|" .. string.format("%x",objectId) .. "|Trigger Pressed")
				
			end
		end
		::continue::
	end
end
	
----------------------------------------------------------------
-- Initialize this addon
----------------------------------------------------------------

function Initialize()

	-- Declare add-on information

	Tacview.AddOns.Current.SetTitle("Trigger Pressed Indicator")
	Tacview.AddOns.Current.SetVersion("1.8.8")
	Tacview.AddOns.Current.SetAuthor("BuzyBee")
	Tacview.AddOns.Current.SetNotes("Creates events when trigger is pressed.")

	-- Load user preferences

	addOnEnabled = Tacview.AddOns.Current.Settings.GetBoolean(settingName, addOnEnabled)

	-- Declare menus

	local mainMenuId = Tacview.UI.Menus.AddMenu(nil, "Trigger Pressed Indicator")
	subMenuId = Tacview.UI.Menus.AddOption(mainMenuId, "Activate", addOnEnabled, OnMenuEnableAddOn)
	
	-- Register callbacks

	Tacview.Events.DocumentLoaded.RegisterListener(OnDocumentLoaded)
end

Initialize()
