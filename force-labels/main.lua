
--[[
	Force Labels
	Force labels to appear on certain types of objects

	Author: BuzyBee
	Last update: 2024-10-03 (Tacview 1.9.4)

	Feel free to modify and improve this script!
--]]

--[[

	MIT License

	Copyright (c) 2024 Raia Software Inc.

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

local Tacview = require("Tacview194")

----------------------------------------------------------------
-- Constants
----------------------------------------------------------------

local LabelWidth = 125 
local LabelHeight = 18

local PositionLabelHorizontal = 17
local PositionLabelVertical = 38

local PositionTextHorizontal = 18
local PositionTextVertical = 41


local FontSize = 16
local LeftMargin = 4
local TopMargin = 4

local LowThreatLabelDistance = 4000 -- Native Tacview value

----------------------------------------------------------------
-- "Members"
----------------------------------------------------------------

local labelRenderStateHandle
local labelVertexArrayHandle
local textRenderStateHandle
local textRenderStateHandleBlue
local textRenderStateHandleRed
local textRenderStateHandleGreen
local textRenderStateHandleViolet

local labelContents = ""

local forceWatercraftLabels = false
local forceWatercraftLabelsSettingName = "Force Watercraft Labels"
local forceWatercraftLabelsMenuHandle

----------------------------------------------------------------
-- Load and compile any resource required to draw the avatar
----------------------------------------------------------------

function OnMenuForceWatercraftLabels()

	-- Enable/disable add-on

	forceWatercraftLabels = not forceWatercraftLabels

	-- Save option value in registry

	Tacview.AddOns.Current.Settings.SetBoolean(forceWatercraftLabelsSettingName, forceWatercraftLabels)

	-- Update menu with the new option value

	Tacview.UI.Menus.SetOption(forceWatercraftLabelsMenuHandle, forceWatercraftLabels)

end

function DeclareRenderData()

	if not labelRenderStateHandle then

		local renderState =
		{
			color = 0xc0ffffff,	
		}

		labelRenderStateHandle = Tacview.UI.Renderer.CreateRenderState(renderState)

	end

	if not labelVertexArrayHandle then

		local vertexArray =
		{
			0,0,0,
			0,-LabelHeight,0,
			LabelWidth,-LabelHeight,0,
			0,0,0,
			LabelWidth,0,0,
			LabelWidth,-LabelHeight,0,
			0,0,0,

		}

		labelVertexArrayHandle = Tacview.UI.Renderer.CreateVertexArray(vertexArray)
	end
	
	if not textRenderStateHandleBlue then
	
		local textRenderStateBlue = 
		{
			color = 0xFF9f2000,	-- Default Blue
			blendMode = Tacview.UI.Renderer.BlendMode.Normal,
		}
			
		textRenderStateHandleBlue = Tacview.UI.Renderer.CreateRenderState(textRenderStateBlue)
	end
	
	if not textRenderStateHandleRed then
	
		local textRenderStateRed = 
		{
			color = 0xFF0000FF,	-- Red
			blendMode = Tacview.UI.Renderer.BlendMode.Normal,
		}
			
		textRenderStateHandleRed = Tacview.UI.Renderer.CreateRenderState(textRenderStateRed)
	end
	
		if not textRenderStateHandleGreen then
	
		local textRenderStateGreen = 
		{
			color = 0xFF006000,	
			blendMode = Tacview.UI.Renderer.BlendMode.Normal,
		}
			
		textRenderStateHandleGreen = Tacview.UI.Renderer.CreateRenderState(textRenderStateGreen)
	end
	
		if not textRenderStateHandleViolet then
	
		local textRenderStateViolet = 
		{
			color = 0xFFfd00fe,	
			blendMode = Tacview.UI.Renderer.BlendMode.Normal,
		}
			
		textRenderStateHandleViolet = Tacview.UI.Renderer.CreateRenderState(textRenderStateViolet)
	end
	
end

----------------------------------------------------------------
-- Draw the custom label during transparent UI rendering pass
----------------------------------------------------------------

function OnDrawTransparentUI()

	if not forceWatercraftLabels then
		return
	end
	
	DeclareRenderData()
	
	local activeObjects = Tacview.Context.GetActiveObjectList()
	
	for _,objectHandle in ipairs(activeObjects) do
	
		local objectTags = Tacview.Telemetry.GetCurrentTags(objectHandle)
		
		if not objectTags then
			goto continue
		end
		
		if Tacview.Telemetry.AnyGivenTagActive(objectTags, Tacview.Telemetry.Tags.Watercraft) then
		
			local engagementRangePropertyIndex = Tacview.Telemetry.GetObjectsNumericPropertyIndex("EngagementRange",false)
			
			local colorPropertyIndex = Tacview.Telemetry.GetObjectsTextPropertyIndex("Color",false)
			
			local color, sampleIsValid
			
			if colorPropertyIndex ~= Tacview.Telemetry.InvalidPropertyIndex then
				
				color, sampleIsValid = Tacview.Telemetry.GetTextSample(objectHandle, Tacview.Context.GetAbsoluteTime(), colorPropertyIndex)
							
			end		
			
			if color == "Red" then
				textRenderStateHandle = textRenderStateHandleRed
			elseif color == "Green" then
				textRenderStateHandle = textRenderStateHandleGreen
			elseif color == "Violet" then
				textRenderStateHandle = textRenderStateHandleViolet
			else -- color blue is default
				textRenderStateHandle = textRenderStateHandleBlue
			end
			
			local lifeTimeBegin, lifeTimeEnd = Tacview.Telemetry.GetLifeTime(objectHandle)	
				
			local currentTime = Tacview.Context.GetAbsoluteTime()
			
			if currentTime < lifeTimeBegin or currentTime > lifeTimeEnd then
				return
			end
				
			local px,py = Tacview.UI.Renderer.GetProjectedPosition(objectHandle)
			
			if not px or not py then
				return
			end
			
			local labelTransform =
			{
				y = py + PositionLabelVertical,
				x = px + PositionLabelHorizontal,
				scale = 1,
			}
		
			local textTransform =
			{
				x = px + LeftMargin + PositionTextHorizontal,
				y = py - FontSize - TopMargin + PositionTextVertical,
				scale = FontSize,
			}
			
			local msg = Tacview.Telemetry.GetCurrentShortName(objectHandle)
	
			local distanceToCamera = Tacview.Context.Camera.GetRangeToTarget(objectHandle)
			
			local forceLabelRequired = false
			
			if engagementRangePropertyIndex == Tacview.Telemetry.InvalidPropertyIndex then
				
				if distanceToCamera >= LowThreatLabelDistance then
					forceLabelRequired = true
				end
			
			else
				
				local engagementRange, sampleIsValid = Tacview.Telemetry.GetNumericSample(objectHandle, Tacview.Context.GetAbsoluteTime(), engagementRangePropertyIndex)
				
				if not sampleIsValid and distanceToCamera >= LowThreatLabelDistance then
					forceLabelRequired = true
				end	
			end
			
			if Tacview.Context.GetSelectedObject(0) == objectHandle or Tacview.Context.GetSelectedObject(1) == objectHandle then
				forceLabelRequired = false
			end
			
			if forceLabelRequired then 			
				Tacview.UI.Renderer.DrawUIVertexArray(labelTransform, labelRenderStateHandle, labelVertexArrayHandle)
				Tacview.UI.Renderer.Print(textTransform, textRenderStateHandle, msg)	
			end
		end
		::continue::
	end
end

function OnCleanUp()

	if textRenderStateHandle then
		Tacview.UI.Renderer.ReleaseRenderState(textRenderStateHandle)
		textRenderStateHandle = nil
	end
	
	if textRenderStateHandleRed then
		Tacview.UI.Renderer.ReleaseRenderState(textRenderStateHandleRed)
		textRenderStateHandleRed = nil
	end
	
	if textRenderStateHandleGreen then
		Tacview.UI.Renderer.ReleaseRenderState(textRenderStateHandleGreen)
		textRenderStateHandleGreen = nil
	end
	
	if textRenderStateHandleViolet then
		Tacview.UI.Renderer.ReleaseRenderState(textRenderStateHandleViolet)
		textRenderStateHandleViolet = nil
	end
	
	if textRenderStateHandleBlue then
		Tacview.UI.Renderer.ReleaseRenderState(textRenderStateHandleBlue)
		textRenderStateHandleBlue = nil
	end

	if labelVertexArrayHandle then
		Tacview.UI.Renderer.ReleaseVertexArray(labelVertexArrayHandle)
		labelVertexArrayHandle = nil
	end

	if labelRenderStateHandle then
		Tacview.UI.Renderer.ReleaseRenderState(labelRenderStateHandle)
		labelRenderStateHandle = nil
	end
end

----------------------------------------------------------------
-- Initialize this addon
----------------------------------------------------------------

function Initialize()

	-- Declare add-on information

	Tacview.AddOns.Current.SetTitle("Force Labels")
	Tacview.AddOns.Current.SetVersion("1.9.4")
	Tacview.AddOns.Current.SetAuthor("BuzyBee")
	Tacview.AddOns.Current.SetNotes("Forces labels to appear on all watercraft.")
	
	forceWatercraftLabels = Tacview.AddOns.Current.Settings.GetBoolean(forceWatercraftLabelsSettingName, forceWatercraftLabels)
	
	-- Declare menus

	local mainMenuHandle = Tacview.UI.Menus.AddMenu(nil, "Force Labels")
	forceWatercraftLabelsMenuHandle = Tacview.UI.Menus.AddOption(mainMenuHandle, "Force Watercraft Labels", forceWatercraftLabels, OnMenuForceWatercraftLabels)
	
	-- Register callbacks

	Tacview.Events.DrawTransparentUI.RegisterListener(OnDrawTransparentUI)
	Tacview.Events.Shutdown.RegisterListener(OnCleanUp)


end

Initialize()
