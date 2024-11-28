
--[[
	Customize Labels Bullseye
	Customizes the label of the primary selected object to list bearing and range to multiple bullseye

	Author: BuzyBee
	Last update: 2023-11-23 (Tacview 1.9.3)

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

local LabelWidth = 125 
local LabelHeight = 60

local PositionLabelHorizontal = 15
local PositionLabelVertical = 0

local PositionTextHorizontal = 15
local PositionTextVertical = 0


local FontSize = 16
local LeftMargin = 4
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
	
	if not primaryObjectHandle then
		return
	end
	
	local lifeTimeBegin1, lifeTimeEnd1 = Tacview.Telemetry.GetLifeTime(primaryObjectHandle)	
	--local lifeTimeBegin2, lifeTimeEnd2 = Tacview.Telemetry.GetLifeTime(secondaryObjectHandle)	
	
	local currentTime = Tacview.Context.GetAbsoluteTime()
	
	--if currentTime < math.max(lifeTimeBegin1,lifeTimeBegin2) or currentTime > math.min(lifeTimeEnd1,lifeTimeEnd2) then
		--return
	--end
	
	if currentTime < lifeTimeBegin1 or currentTime > lifeTimeEnd1 then
		return
	end
	
	local px,py = Tacview.UI.Renderer.GetProjectedPosition(primaryObjectHandle)
	
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
	
	Tacview.UI.Renderer.DrawUIVertexArray(labelTransform, labelRenderStateHandle, labelVertexArrayHandle)
	
	Tacview.UI.Renderer.Print(textTransform, textRenderStateHandle, labelContents)
	
end

function OnUpdate(dt, absoluteTime)

	labelContents = ""

	local selectedObjectHandle = Tacview.Context.GetSelectedObject(0)

	local telemetry = Tacview.Telemetry

	-- Find all the bullseye
	
	local activeObjectList = Tacview.Context.GetActiveObjectList()
	
	local colorPropertyIndex = telemetry.GetObjectsTextPropertyIndex("Color" , false)
	
	for i=1, #activeObjectList do
	
		local bullseyeObjectHandle = activeObjectList[i]
		
		local objectTags = telemetry.GetCurrentTags(bullseyeObjectHandle)
		
		if telemetry.AnyGivenTagActive(objectTags, telemetry.Tags.Bullseye) then
		
			local color = telemetry.GetTextSample(bullseyeObjectHandle, absoluteTime, colorPropertyIndex)
			local bearing = telemetry.GetAbsoluteBearing(bullseyeObjectHandle, absoluteTime, selectedObjectHandle, absoluteTime, true )
			local range = telemetry.GetRange2D( selectedObjectHandle , absoluteTime , bullseyeObjectHandle , absoluteTime )	
			
			bearing = Tacview.Math.Angle.Normalize2Pi(bearing) 
			bearing = math.deg(bearing)
			bearing = math.floor(bearing+0.5)
			
			range = range/1000
			range = math.floor(range+0.5)
			
			if color and range and bearing then
				labelContents = labelContents .. "BE " .. color .. " " .. string.format("%03d",bearing) .. "/" .. range .. "\n"
			end
		end
	end
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
