
--[[
	Airboss

	Author: BuzyBee
	Last update: 2022-06-23 (Tacview 1.9.0)

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

-- Constants 

local AirbossEnabledSettingName = "airbossEnabled"
local HitRange = 150 -- meters
local DestroyedRange = 40 -- meters
local DisplayTime = 10 -- seconds

local Margin = 16
local FontSize = 24

-- Members

local airbossEnabledMenuId
local airbossEnabled = false
local listOfEvents = {}          -- create the matrix
local file

function StartLog()
	
	local dateArray = os.date("!*t");
	local formattedDate = dateArray.year .. dateArray.month .. dateArray.day .. "T" .. dateArray.hour .. dateArray.min .. dateArray.sec .. "Z"
	local fileName = formattedDate .. "-airboss-log.txt"
	
	-- close any existing log
	
	if file then
		file:close()
	end
	
	local logFullPath = Tacview.Path.GetSpecialDirectoryName("UserDocuments") .. "Tacview\\AirbossAddOn\\"
	
	lfs.mkdir(logFullPath)
	
	file = io.open(logFullPath..fileName,"w")
	
	if not file then 
		Tacview.Log.Warning("Failed to create log file at ["..logFullPath..fileName"]")
	else
		Tacview.Log.Info("Succesfully created new log file ["..logFullPath..fileName.."]")
	end
end

function OnUpdate( dt , absoluteTime )

	if not Tacview.Context.Playback.IsPlaying() then
		return
	end

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
	
	-- ***************************************************************************************************************************
	-- ***	Primary Object = the target / the object that got hit or destroyed                                                  **
	-- ***	Secondary Object = the weapon that hit the target (missile or bomb)                                                 **
	-- ***	Parent Object = the object that fired the secondary object (aircraft, watercraft, antiaircraft or ground vehicle)   **
	-- ***************************************************************************************************************************
	
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
		
			-- a weapon has just exploded. Was it close enough to anyone to cause damage?
			
			local secondaryObjectTransform = GetCurrentTransform(secondaryObjectHandle)
			
			local secondaryObjectIdentifier = GetCurrentShortName(secondaryObjectHandle)
			
			local eligiblePrimaryObjectHandles = {}
			
			for _,primaryObjectHandle in pairs(listOfActiveObjects) do
						
				local primaryObjectTags = GetCurrentTags(primaryObjectHandle)
	
				if primaryObjectTags then
								
					local isEligiblePrimaryObject = AnyGivenTagActive(primaryObjectTags, Tags.FixedWing|Tags.Rotorcraft|Tags.Watercraft|Tags.AntiAircraft|Tags.Vehicle|Tags.Warship)
		
					if isEligiblePrimaryObject then 
						eligiblePrimaryObjectHandles[#eligiblePrimaryObjectHandles+1] = primaryObjectHandle
					end
				end
			end
			
			local minDistance = HitRange
			local closestObjectHandle = nil			
			
			for _,eligiblePrimaryObjectHandle in pairs(eligiblePrimaryObjectHandles) do

				local primaryObjectTransform = GetCurrentTransform(eligiblePrimaryObjectHandle) 
				
				local distance = GetDistanceBetweenObjects(secondaryObjectTransform ,primaryObjectTransform )
				
				if distance < minDistance then
					closestObjectHandle = eligiblePrimaryObjectHandle
					minDistance = distance
				end
			end
			
			if not closestObjectHandle then 
				
				-- the weapon exploded but no one was close enough. 
				
				goto nextSecondaryObject
				
			end
			
			-- If we got this far, an object is hit or destroyed.
				
			local event
			
			if minDistance <= DestroyedRange then
			
				event = "has been destroyed"
			
			else
			
				event = "has been hit"

			end
			
			local primaryObjectIdentifier				
	
			if pilotPropertyIndex ~= InvalidPropertyIndex then
					
				local pilot, sampleIsValid = GetTextSample(closestObjectHandle, absoluteTime, pilotPropertyIndex)
					
				if sampleIsValid then 
					
					primaryObjectIdentifier = pilot
				
				else
				
					primaryObjectIdentifier = GetCurrentShortName(closestObjectHandle)
				end
	
			else
	
				primaryObjectIdentifier = GetCurrentShortName(closestObjectHandle)
	
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
			
			if not listOfEvents[index]["event"] then
				listOfEvents[index]["event"] = {}
			end
			
			listOfEvents[index]["primaryObject"] = primaryObjectIdentifier
			listOfEvents[index]["secondaryObject"] = secondaryObjectIdentifier	
			listOfEvents[index]["parentObject"] = parentObjectIdentifier
			listOfEvents[index]["absoluteTime"] = absoluteTime	
			listOfEvents[index]["dateTime"] = AbsoluteTimeToISOText(absoluteTime)
			listOfEvents[index]["event"] = event
			
			local msg = listOfEvents[index]["dateTime"] .." - " .. listOfEvents[index]["primaryObject"] .. " " .. listOfEvents[index]["event"] .. " by " .. listOfEvents[index]["secondaryObject"] .. " fired by " .. listOfEvents[index]["parentObject"]
			
			Tacview.Log.Info(msg)

			if file then
				file:write(msg .. "\n")
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

local StatisticsRenderState =
{
	blendMode = Tacview.UI.Renderer.BlendMode.Additive,
}

local statisticsRenderStateHandle

local BackgroundRenderState =
{
	color = 0x80000000,	-- black transparent background
}

local backgroundRenderStateHandle

function OnDrawTransparentUI()

	if not airbossEnabled then
		return
	end
	
	local Renderer = Tacview.UI.Renderer
	local GetAbsoluteTime = Tacview.Context.GetAbsoluteTime
	local CreateRenderState = Renderer.CreateRenderState
	local CreateVertexArray = Renderer.CreateVertexArray
	local DrawUIVertexArray = Renderer.DrawUIVertexArray
	local ReleaseVertexArray = Renderer.ReleaseVertexArray
	local DrawUITriangleStrip = Tacview.UI.Renderer.DrawUITriangleStrip
	
	local textTransform =
	{
		x = Margin,
		y = Renderer.GetHeight() / 2,
		scale = FontSize,
	}
	
	local count = 0
	local maxNumCharacters = 0
	
	if not statisticsRenderStateHandle then

		statisticsRenderStateHandle = CreateRenderState(StatisticsRenderState)

	end
	
	local msg = ""
	
	for i=1,#listOfEvents do
		
		if math.abs(GetAbsoluteTime() - listOfEvents[i]["absoluteTime"]) < DisplayTime then
		
			local submsg = listOfEvents[i]["primaryObject"] .. " " .. listOfEvents[i]["event"]
			
			maxNumCharacters = math.max(maxNumCharacters, string.len(submsg))
			
			msg = msg .. " " .. submsg .. "\n"
			
			count = count + 1			
		end
	end
	
	local backgroundTransform =
	{
		x = Margin,
		y = Renderer.GetHeight() / 2 + FontSize,
		scale = FontSize,
	}
	
	local BackgroundHeight = count
	local BackgroundWidth = maxNumCharacters / 2
	
	if not backgroundRenderStateHandle then
		backgroundRenderStateHandle = CreateRenderState(BackgroundRenderState)
	end
	
	--local backgroundVertexArrayHandle

	--if not backgroundVertexArrayHandle then

	--[[local vertexArray =
	{
		0,0,0,
		0,-BackgroundHeight,0,
		BackgroundWidth,-BackgroundHeight,0,
		0,0,0,
		BackgroundWidth,0,0,
		BackgroundWidth,-BackgroundHeight,0,
		0,0,0,
	
	}--]]
	
	local vertexArray =
	{
		0,0,0,
		0,-BackgroundHeight,0,
		BackgroundWidth,0,0,
		BackgroundWidth,-BackgroundHeight,0,
	}
	
	--backgroundVertexArrayHandle = CreateVertexArray(vertexArray)

	--end
	
	DrawUITriangleStrip(backgroundTransform, backgroundRenderStateHandle, vertexArray)

	--DrawUIVertexArray(backgroundTransform, backgroundRenderStateHandle, backgroundVertexArrayHandle)
	Renderer.Print(textTransform, statisticsRenderStateHandle, msg)	
	
	--ReleaseVertexArray(backgroundVertexArrayHandle)

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
	Tacview.AddOns.Current.SetVersion("1.9.0.102")
	Tacview.AddOns.Current.SetAuthor("BuzyBee")
	Tacview.AddOns.Current.SetNotes("Display when an object has been hit, in real-time or during debriefing.")

	-- Create a log file
	
	StartLog()
	
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
