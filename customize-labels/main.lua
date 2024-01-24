
--[[
	Customize Label
	Customizes the label of the primary selected object

	Author: BuzyBee
	Last update: 2023-08-17 (Tacview 1.9.3)

	Feel free to modify and improve this script!
--]]

--[[

	MIT License

	Copyright (c) 2023 Raia Software Inc.

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

local Tacview = require("Tacview193")

----------------------------------------------------------------
-- Constants
----------------------------------------------------------------

local LabelWidth = 85 
local LabelHeight = 70

local FontSize = 16
local LeftMargin = 8
local TopMargin = 4

----------------------------------------------------------------
-- "Members"
----------------------------------------------------------------

local labelRenderStateHandle
local labelVertexArrayHandle
local textRenderStateHandle

local labelContents = ""

----------------------------------------------------------------
-- Load and compile any resource required to draw the avatar
----------------------------------------------------------------

function DeclareRenderData()

	local labelWidth = LabelWidth
	local labelHeight = LabelHeight
	
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
			0,-labelHeight,0,
			labelWidth,-labelHeight,0,
			0,0,0,
			labelWidth,0,0,
			labelWidth,-labelHeight,0,
			0,0,0,

		}

		labelVertexArrayHandle = Tacview.UI.Renderer.CreateVertexArray(vertexArray)
	end
	
	if not textRenderStateHandle then
	
		local renderState = 
		{
			color = 0xff000000,
			blendMode = Tacview.UI.Renderer.BlendMode.Normal,
		}
		
		textRenderStateHandle = Tacview.UI.Renderer.CreateRenderState(renderState)
		
	end
end

----------------------------------------------------------------
-- Draw the custom label during transparent UI rendering pass
----------------------------------------------------------------

function OnDrawTransparentUI()

	DeclareRenderData()
	
	local primaryObjectHandle = Tacview.Context.GetSelectedObject(0)
	local secondaryObjectHandle = Tacview.Context.GetSelectedObject(1)
	
	if not primaryObjectHandle or not secondaryObjectHandle then
		return
	end
	
	local lifeTimeBegin1, lifeTimeEnd1 = Tacview.Telemetry.GetLifeTime(primaryObjectHandle)	
	local lifeTimeBegin2, lifeTimeEnd2 = Tacview.Telemetry.GetLifeTime(secondaryObjectHandle)	
	
	local currentTime = Tacview.Context.GetAbsoluteTime()
	
	if currentTime < math.max(lifeTimeBegin1,lifeTimeBegin2) or currentTime > math.min(lifeTimeEnd1,lifeTimeEnd2) then
		return
	end
		
	if not primaryObjectHandle or not secondaryObjectHandle then
		return
	end
	
	local px,py = Tacview.UI.Renderer.GetProjectedPosition(primaryObjectHandle)
	
	if not px or not py then
		return
	end
		
	local labelTransform =
	{
		x = px + 15,
		y = py,-- + 85,
		scale = 1,
	}
	
	local textTransform =
	{
		x = px + 15 + LeftMargin,
		y = py - FontSize - TopMargin, --+ 85 ,
		scale = FontSize,
	}
	
	Tacview.UI.Renderer.DrawUIVertexArray(labelTransform, labelRenderStateHandle, labelVertexArrayHandle)
	
	Tacview.UI.Renderer.Print(textTransform, textRenderStateHandle, labelContents)
	
end

function OnUpdate(dt, absoluteTime)

	-- Obtain secondary object's BE, ASL, TRK, Mach to be displayed in the custom label.

	local secondaryObjectHandle = Tacview.Context.GetSelectedObject(1)
	
	if not secondaryObjectHandle then
		return
	end
	
	local secondaryObjectTransform = Tacview.Telemetry.GetCurrentTransform(secondaryObjectHandle)
	
	labelContents = ""
	
	local br = GetBearingAndRangeToBullseye(secondaryObjectHandle, absoluteTime)
	
	labelContents = labelContents .. "BE " .. br
	
	-- ASL
	
	local asl = secondaryObjectTransform.altitude
	asl = Tacview.Math.Units.MetersToFeet(asl)
	
	labelContents = labelContents .. "\nASL ".. math.floor(asl+0.5)
	
	-- TRK
	
	local trk = Tacview.Telemetry.GetCurrentTrack(secondaryObjectHandle)
		
	if trk then

		local trk = Tacview.Math.Angle.Normalize2Pi(trk)
		local trk = math.deg(trk)
		
		labelContents = labelContents .. "\nTRK " .. math.floor(trk + 0.5)
	else
		labelContents = labelContents .. "\nTRK "	
	end
	
	-- MACH
	
	local mach = Tacview.Telemetry.GetCurrentMachNumber(secondaryObjectHandle)
	
	if mach then
		labelContents = labelContents .. "\nMach " .. string.format("%.2f",mach)
	else
		labelContents = labelContents .. "\nMach "
	end
	
end

function GetBearingAndRangeToBullseye(objectHandle, absoluteTime)

	local Telemetry = Tacview.Telemetry
	local GetCurrentTags = Telemetry.GetCurrentTags
	local AnyGivenTagActive = Telemetry.AnyGivenTagActive
	
	local colorPropertyIndex = Telemetry.GetObjectsTextPropertyIndex("Color", false)
	
	local firstBullseye
	local matchingColorBullseye
	
	local activeObjects = Tacview.Context.GetActiveObjectList()
	
	local objectColor = Telemetry.GetTextSample( objectHandle , absoluteTime , colorPropertyIndex )
	
	for i=1,#activeObjects do
	
		local tags = GetCurrentTags(activeObjects[i])
	
		if AnyGivenTagActive(tags ,Telemetry.Tags.Bullseye)  then
		
			local bullseyeColor = Telemetry.GetTextSample( objectHandle , absoluteTime , colorPropertyIndex )
			
			if not firstBullseye then
				firstBullseye = activeObjects[i] 
			end
			
			if not matchingColorBullseye and bullseyeColor == objectColor then
				matchingColorBullseye = activeObjects[i]
				break
			end
		end
	end
	
	local bullseyeObjectHandle = matchingColorBullseye or firstBullseye
	
	local bearing
	local range
	
	if bullseyeObjectHandle then
	
		local bullseyeTransform = Telemetry.GetCurrentTransform(bullseyeObjectHandle)
		local objectTransform = Telemetry.GetCurrentTransform(objectHandle)
		
		bearing = Tacview.Telemetry.GetAbsoluteBearing(bullseyeObjectHandle, absoluteTime, objectHandle, absoluteTime, true )
		
		if bearing then	
			bearing = math.floor(math.deg(bearing) + 0.5)
		else 
			return ""
		end
	
		range = Tacview.Telemetry.GetRange2D( objectHandle , absoluteTime , bullseyeObjectHandle , absoluteTime )	
		
		if range then	
			range = Tacview.Math.Units.MetersToNauticalMiles(range)
			range = math.floor(range + 0.5)
		else
			return ""
		end	
	else
		return ""
	end
	
	return string.format("%03d",bearing) .. "/" .. range

end

----------------------------------------------------------------
-- Initialize this addon
----------------------------------------------------------------

function Initialize()

	-- Declare add-on information

	Tacview.AddOns.Current.SetTitle("Customize Label")
	Tacview.AddOns.Current.SetVersion("1.9.3.106")
	Tacview.AddOns.Current.SetAuthor("BuzyBee")
	Tacview.AddOns.Current.SetNotes("Customizes the label of the selected object.")

	-- Register callbacks

	Tacview.Events.DrawTransparentUI.RegisterListener(OnDrawTransparentUI)
	Tacview.Events.Update.RegisterListener(OnUpdate)

end

Initialize()
