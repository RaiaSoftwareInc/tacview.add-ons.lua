
--[[
	Airboss

	Author: BuzyBee
	Last update: 2022-05-04 (Tacview 1.8.8)

	Feel free to modify and improve this script!
--]]

--[[

	MIT License

	Copyright (c) 2022 Raia Software Inc.

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

local Tacview = require("Tacview188")

-- Constants 

local AirbossEnabledSettingName = "airbossEnabled"
local HitRange = 150 -- meters
local DestroyedRange = 40 -- meters
local DisplayTime = 10 -- seconds

-- Members

local airbossEnabledMenuId
local airbossEnabled = false
local listOfEvents = {}          -- create the matrix

function OnUpdate( dt , absoluteTime )

	local Telemetry = Tacview.Telemetry
	local GetObjectHandleByIndex = Telemetry.GetObjectHandleByIndex
	local GetCurrentTags = Telemetry.GetCurrentTags
	local AnyGivenTagActive = Telemetry.AnyGivenTagActive
	local Tags = Telemetry.Tags
	local GetLifeTime = Telemetry.GetLifeTime
	local GetCurrentTransform = Telemetry.GetCurrentTransform
	local GetDistanceBetweenObjects = Tacview.Math.Vector.GetDistanceBetweenObjects
	local InvalidPropertyIndex = Telemetry.InvalidPropertyIndex
	local GetTextSample = Telemetry.GetTextSample
	local GetCurrentShortName = Telemetry.GetCurrentShortName
	local AbsoluteTimeToISOText = Tacview.UI.Format.AbsoluteTimeToISOText
		
	if not airbossEnabled then 
		return 
	end
	
	local pilotPropertyIndex = Telemetry.GetObjectsTextPropertyIndex("Pilot",false)

	local listOfActiveObjects = Tacview.Context.GetActiveObjectList()
	
	-- ***************************************************************************
	-- ***  PRIMARY OBJECT = the target / the object that got hit or destroyed
	-- ***	Secondary Object = the weapon that hit the target (missile or bomb)  
	-- ***	Parent Object = the object that fired the secondary object (aircraft, watercraft, antiaircraft or ground vehicle)
	-- ***************************************************************************
	
	for _,secondaryObjectHandle in pairs(listOfActiveObjects) do
	
		local secondaryObjectTags = GetCurrentTags(secondaryObjectHandle)

		if not secondaryObjectTags then 
			goto nextSecondaryObject 
		end

		local isEligibleSecondaryObject = AnyGivenTagActive(secondaryObjectTags,Tags.Missile|Tags.Bomb)

		if not isEligibleSecondaryObject then
			goto nextSecondaryObject  
		end
		
		local _,lifeTimeEnd = GetLifeTime(secondaryObjectHandle)
		
		if lifeTimeEnd > absoluteTime - dt and lifeTimeEnd <= absoluteTime then
		
			-- a missile has just exploded. Was it close enough to anyone to cause damage?
			
			local secondaryObjectTransform = GetCurrentTransform(secondaryObjectHandle)
			
			local secondaryObjectIdentifier = GetCurrentShortName(secondaryObjectHandle)
			
			for _,primaryObjectHandle in pairs(listOfActiveObjects) do
			
				local primaryObjectTags = GetCurrentTags(primaryObjectHandle)
	
				if not primaryObjectTags then 
					goto nextPrimaryObject 
				end
	
				local isEligiblePrimaryObject = AnyGivenTagActive(primaryObjectTags, Tags.FixedWing|Tags.Rotorcraft|Tags.Watercraft|Tags.AntiAircraft|Tags.Vehicle|Tags.Warship)
	
				if not isEligiblePrimaryObject then
					goto nextPrimaryObject  
				end

				local primaryObjectTransform = GetCurrentTransform(primaryObjectHandle) 
				
				local distance = GetDistanceBetweenObjects(secondaryObjectTransform ,primaryObjectTransform )
							
				if distance <= HitRange then
			
					-- this object has been HIT BY this missile.
					
					local primaryObjectIdentifier				
					
					if pilotPropertyIndex ~= InvalidPropertyIndex then
						
						local pilot, sampleIsValid = GetTextSample(primaryObjectHandle, absoluteTime, pilotPropertyIndex)
						
						if sampleIsValid then 
						
							primaryObjectIdentifier = pilot
							
						else
						
							primaryObjectIdentifier = GetCurrentShortName(primaryObjectHandle)
						
						end

					else

						primaryObjectIdentifier = GetCurrentShortName(primaryObjectHandle)

					end
					
					local parentObjectHandle = Tacview.Telemetry.GetCurrentParentHandle(secondaryObjectHandle)
					
					local parentObjectIdentifier
					
					if parentObjectHandle then
					
						if pilotPropertyIndex ~= InvalidPropertyIndex then
						
							local pilot, sampleIsValid = GetTextSample(parentObjectHandle, absoluteTime, pilotPropertyIndex)
						
							if sampleIsValid then 
							
								parentObjectIdentifier = pilot
							
							else
							
								parentObjectIdentifier = GetCurrentShortName(parentObjectHandle)
							
							end	

						else

							parentObjectIdentifier = GetCurrentShortName(secondaryObjectHandle)
						end
	
					else
					
						parentObjectIdentifier = GetCurrentShortName(secondaryObjectHandle)

					end			
	
					local index = #listOfEvents+1
					
					if not listOfEvents[index] then
						listOfEvents[index] = {}
					end		
					
					if not listOfEvents[index]["primaryObject"] then
						listOfEvents[index]["primaryObject"] = {}
					end
					
					if not listOfEvents[index]["secondaryObject"] then
						listOfEvents[index]["secondaryObject"] = {}
					end
					
					if not listOfEvents[index]["parentObject"] then
						listOfEvents[index]["parentObject"] = {}
					end	

					if not listOfEvents[index]["absoluteTime"] then
						listOfEvents[index]["absoluteTime"] = {}
					end							
					
					listOfEvents[index]["primaryObject"] = primaryObjectIdentifier
					listOfEvents[index]["secondaryObject"] = secondaryObjectIdentifier	
					listOfEvents[index]["parentObject"] = parentObjectIdentifier
					listOfEvents[index]["absoluteTime"] = absoluteTime	
					listOfEvents[index]["dateTime"] = AbsoluteTimeToISOText(absoluteTime)
					
				
					Tacview.Log.Info(listOfEvents[index]["dateTime"] .." - " .. listOfEvents[index]["primaryObject"] .. " is hit by " .. listOfEvents[index]["secondaryObject"] .. " fired by " .. listOfEvents[index]["parentObject"])
				end				
				
				::nextPrimaryObject::
			end	
			
		end	
		
		::nextSecondaryObject::	
	end
end

----------------------------------------------------------------
-- Menu callbacks
----------------------------------------------------------------

function OnMenuAirboss()

	-- Enable/disable add-on

	airbossEnabled = not airbossEnabled

	-- Save option value in registry

	Tacview.AddOns.Current.Settings.SetBoolean(AirbossEnabledSettingName, airbossEnabled)

	-- Update menu with the new option value

	Tacview.UI.Menus.SetOption(airbossEnabledMenuId, airbossEnabled)

end

local Margin = 16
local FontSize = 24
local FontColor = 0xFFA0FF46		-- HUD style green

local StatisticsRenderState =
{
	color = FontColor,
	blendMode = Tacview.UI.Renderer.BlendMode.Additive,
}

local statisticsRenderStateHandle

function OnDrawTransparentUI()

	if not airbossEnabled then
		return
	end

	-- Compile render state

	if not statisticsRenderStateHandle then

		statisticsRenderStateHandle = Tacview.UI.Renderer.CreateRenderState(StatisticsRenderState)

	end

	local renderer = Tacview.UI.Renderer

	local transform =
	{
		x = Margin,
		y = (renderer.GetHeight() + 4 * FontSize) / 2,
		scale = FontSize,
	}
	
	local msg = ""
	
	for i=1,#listOfEvents do
	
		if math.abs(Tacview.Context.GetAbsoluteTime() - listOfEvents[i]["absoluteTime"]) < DisplayTime then
			msg = msg .. listOfEvents[i]["primaryObject"] .. " has been hit\n"
		end
	end
	
	renderer.Print(transform, statisticsRenderStateHandle, msg)
end

function OnDocumentLoadedOrUnloaded()

	listOfEvents = {}

end


----------------------------------------------------------------
-- Add-on initialization
----------------------------------------------------------------

function Initialize()

	-- Declare add-on information

	Tacview.AddOns.Current.SetTitle("Airboss")
	Tacview.AddOns.Current.SetVersion("1.8.8.200")
	Tacview.AddOns.Current.SetAuthor("BuzyBee")
	Tacview.AddOns.Current.SetNotes("Display when an object has been hit, in real-time or during debriefing.")

	-- Create a menu item

-- Load user preferences 

	airbossEnabled = Tacview.AddOns.Current.Settings.GetBoolean(AirbossEnabledSettingName, airbossEnabled)

	-- Declare menus

	local mainMenuHandle = Tacview.UI.Menus.AddMenu(nil, "Airboss")

	airbossEnabledMenuId = Tacview.UI.Menus.AddOption(mainMenuHandle, "Enable Airboss", airbossEnabled, OnMenuAirboss)

	-- Register callbacks

	Tacview.Events.Update.RegisterListener(OnUpdate)
	Tacview.Events.DrawTransparentUI.RegisterListener(OnDrawTransparentUI)
	
	Tacview.Events.DocumentLoaded.RegisterListener(OnDocumentLoadedOrUnloaded)
	Tacview.Events.DocumentUnload.RegisterListener(OnDocumentLoadedOrUnloaded)
end

Initialize()
