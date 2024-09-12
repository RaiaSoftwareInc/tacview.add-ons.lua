
-- Control Zone for Tacview
-- Author: Erin 'BuzyBee' O'REILLY
-- Last update: 2024-02-19 (Tacview 1.9.3)

-- IMPORTANT: This script act both as a tutorial and as a real addon for Tacview.
-- Feel free to modify and improve this script!

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

----------------------------------------------------------------
-- Setup
----------------------------------------------------------------

require("LuaStrict")

local Tacview = require("Tacview193")

----------------------------------------------------------------
-- Preferences
----------------------------------------------------------------

local AddOnEnabledSettingName = "DisplayControlZone"

----------------------------------------------------------------
-- Constants
----------------------------------------------------------------

local Math = Tacview.Math
local MinRange = Math.Units.FeetToMeters(2500)
local MaxRange = Math.Units.FeetToMeters(4500)
local AspectAngle = 45
local CosAspectAngle = math.cos(math.rad(AspectAngle))
local SinAspectAngle = math.sin(math.rad(AspectAngle))

local Telemetry = Tacview.Telemetry
local Context = Tacview.Context

----------------------------------------------------------------
-- "Members"
----------------------------------------------------------------

local outerRenderStateHandle0 = nil
local innerRenderStateHandle0 = nil

local outerRenderStateHandle1 = nil
local innerRenderStateHandle1 = nil


local outerVertexArrayHandle = nil
local innerVertexArrayHandle = nil

local innerRenderState0 = nil
local outerRenderState0 = nil

local innerRenderState1 = nil
local outerRenderState1 = nil

local InnerColor0 = 0x405800B8 -- DEFAULT (red)
local OuterColor0 = 0x805800B8 -- DEFAULT (red)	

local InnerColor1 = 0x405800B8 -- DEFAULT (red)
local OuterColor1 = 0x805800B8 -- DEFAULT (red)	
                                          
----------------------------------------------------------------
-- UI commands and options
----------------------------------------------------------------

local addOnEnabledMenuId
local addOnEnabledOption = false

function OnMenuEnableAddOn()

	-- Change and save option

	addOnEnabledOption = not addOnEnabledOption

	Tacview.AddOns.Current.Settings.SetBoolean(AddOnEnabledSettingName, addOnEnabledOption)

	-- Update menu

	Tacview.UI.Menus.SetOption(addOnEnabledMenuId, addOnEnabledOption)

end

----------------------------------------------------------------
-- 2D Rendering
----------------------------------------------------------------

local Renderer = Tacview.UI.Renderer

local currentColor0
local currentColor1

local color0HasChanged
local color1HasChanged

function SetColor(color)

	local InnerColor= 0x405800B8 	-- DEFAULT (red)
	local OuterColor= 0x805800B8 	-- DEFAULT (red)

	if color == "Red" then
		
		InnerColor = 0x405800B8
		OuterColor = 0x805800B8

	elseif color == "Orange" then
		
		InnerColor = 0x40096CE3
		OuterColor = 0x80096CE3

	elseif color == "Yellow" then
		
		InnerColor = 0x4000d3ff
		OuterColor = 0x8000d3ff
		
	elseif color == "Green" then
	
		InnerColor = 0x4000b454
		OuterColor = 0x8000b454

	elseif color == "Cyan" then
		
		InnerColor = 0x40c1ac00
		OuterColor = 0x80c1ac00
		
	elseif color == "Blue" then
		
		InnerColor = 0x40b45400
		OuterColor = 0x80b45400
		
	elseif color == "Violet" then
		
		InnerColor = 0x40B400B2
		OuterColor = 0x80B400B2
	
	elseif color == "White" then
		
		InnerColor = 0x40ADADAD
		OuterColor = 0x80ADADAD
	
	end

	return InnerColor, OuterColor

end

function DeclareRenderData()

	-- Declare render data once, and re-declare it if the color has changed. 

	local colorPropertyIndex = Telemetry.GetObjectsTextPropertyIndex("Color", false)

	local objectHandle0 = Tacview.Context.GetSelectedObject(0)

	if objectHandle0 then
		
		local objectTags = Tacview.Telemetry.GetCurrentTags(objectHandle0) 

		if Telemetry.AnyGivenTagActive(objectTags, Telemetry.Tags.FixedWing) then			

			local color0, sampleIsValid = Telemetry.GetTextSample(objectHandle0, Context.GetAbsoluteTime(), colorPropertyIndex)

			if color0 ~= currentColor0 then
	
				color0HasChanged = true

				InnerColor0, OuterColor0 = SetColor(color0)
			end

			-- Declare render state if it has not been already declared, and re-declare it if the color has changed.
	
			if not innerRenderState0 or color0HasChanged then
	
				if innerRenderState0 then
					Renderer.ReleaseRenderState(innerRenderStateHandle0)
					innerRenderStateHandle0 = nil
				end
			
				innerRenderState0 =
				{
					color = InnerColor0,
					blendMode = Renderer.BlendMode.Additive,
				}
			
				innerRenderStateHandle0 = Renderer.CreateRenderState(innerRenderState0)
			end
		
			if not outerRenderState0 or color0HasChanged then
	
				if outerRenderState0 then
					Renderer.ReleaseRenderState(outerRenderStateHandle0)
					outerRenderStateHandle0 = nil
				end
			
				local outerRenderState0 =
				{
					color = OuterColor0,
					blendMode = Renderer.BlendMode.Additive,
				}
			
				outerRenderStateHandle0 = Renderer.CreateRenderState(outerRenderState0)
			end
	
			-- Keep track of current color and whether or not it has changed
	
			currentColor0 = color0
			color0HasChanged = false
		end
	end

	local objectHandle1 = Tacview.Context.GetSelectedObject(1)

	if objectHandle1 then

		local objectTags = Tacview.Telemetry.GetCurrentTags(objectHandle1) 

		if Telemetry.AnyGivenTagActive(objectTags, Telemetry.Tags.FixedWing) then			

			local color1, sampleIsValid = Telemetry.GetTextSample(objectHandle1, Context.GetAbsoluteTime(), colorPropertyIndex)
	
			if color1 ~= currentColor1 then
			
				color1HasChanged = true
	
				InnerColor1, OuterColor1 = SetColor(color1)		
			end
	
			-- Declare render state if it has not been already declared, and re-declare it if the color has changed.
		
			if not innerRenderState1 or color1HasChanged then
	
				if innerRenderState1 then
					Renderer.ReleaseRenderState(innerRenderStateHandle1)
					innerRenderStateHandle1 = nil
				end
			
				innerRenderState1 =
				{
					color = InnerColor1,
					blendMode = Renderer.BlendMode.Additive,
				}
			
				innerRenderStateHandle1 = Renderer.CreateRenderState(innerRenderState1)
			end
		
			if not outerRenderState1 or color1HasChanged then
	
				if outerRenderState1 then
					Renderer.ReleaseRenderState(outerRenderStateHandle1)
					outerRenderStateHandle1 = nil
				end
			
				local outerRenderState1 =
				{
					color = OuterColor1,
					blendMode = Renderer.BlendMode.Additive,
				}
			
				outerRenderStateHandle1 = Renderer.CreateRenderState(outerRenderState1)
	
				-- Keep track of current color and whether or not it has changed
	
				currentColor1 = color1
				color1HasChanged = false
			end
		end
	end
end

function DrawVertexArray(objectHandle, innerRenderStateHandle, outerRenderStateHandle)

	local objectTags = Telemetry.GetCurrentTags(objectHandle)

	if Telemetry.AnyGivenTagActive(objectTags, Telemetry.Tags.FixedWing) then

	-- Get *calculated* transform in case of an object without orientation, so that the control zone will be displayed in the right place.

		local currentTransform, transformIsValid = Tacview.Telemetry.GetCurrentCalculatedTransform(objectHandle)
	
		if transformIsValid then
			Renderer.DrawObjectVertexArray(currentTransform, outerRenderStateHandle, outerVertexArrayHandle)
			Renderer.DrawObjectVertexArray(currentTransform, innerRenderStateHandle, innerVertexArrayHandle)
		end
	end
end

function OnDrawTransparentObjects()

	if not addOnEnabledOption then
		return
	end

	DeclareRenderData()

	CreateVertexArrays()

	local objectHandle0 = Tacview.Context.GetSelectedObject(0)

	if objectHandle0 then
		DrawVertexArray(objectHandle0, innerRenderStateHandle0, outerRenderStateHandle0)
	end

	local objectHandle1 = Tacview.Context.GetSelectedObject(1)

	if objectHandle1 then
		DrawVertexArray(objectHandle1, innerRenderStateHandle1, outerRenderStateHandle1)
	end
end

function CreateVertexArrays()

-- Create vertex array handles, if not already created, to be used for both objects if applicable

	if not innerVertexArrayHandle then
		
		local innerVertexArray = {}

		-- 6 points for every degree: x,y,z for point at MinRange and x,y,z for point at MaxRange

		for innerIndex=0,360*6,6 do

			local s = innerIndex/6
			
			local cos_s = math.cos(math.rad(s))
			local sin_s = math.sin(math.rad(s))
		
			innerVertexArray[#innerVertexArray+1] 	= MinRange 	* cos_s * SinAspectAngle
			innerVertexArray[#innerVertexArray+1] 	= MinRange 	* sin_s * SinAspectAngle
			innerVertexArray[#innerVertexArray+1] 	= MinRange 	* CosAspectAngle
			innerVertexArray[#innerVertexArray+1] 	= MaxRange 	* cos_s * SinAspectAngle 
			innerVertexArray[#innerVertexArray+1] 	= MaxRange 	* sin_s * SinAspectAngle 
			innerVertexArray[#innerVertexArray+1] 	= MaxRange 	* CosAspectAngle
		end

		innerVertexArrayHandle = Renderer.CreateVertexArray(innerVertexArray)
	end

	-- repeat in opposite direction to make faces on both sides

	if not outerVertexArrayHandle then

		local outerVertexArray = {}

		for outerIndex=0,-360*6,-6 do

			local s = outerIndex/6

			local cos_s = math.cos(math.rad(s))
			local sin_s = math.sin(math.rad(s))
		
			outerVertexArray[#outerVertexArray + 1]		= MinRange 	* cos_s * SinAspectAngle
			outerVertexArray[#outerVertexArray + 1] 	= MinRange 	* sin_s * SinAspectAngle
			outerVertexArray[#outerVertexArray + 1] 	= MinRange 	* CosAspectAngle
			outerVertexArray[#outerVertexArray + 1] 	= MaxRange 	* cos_s * SinAspectAngle
			outerVertexArray[#outerVertexArray + 1] 	= MaxRange 	* sin_s * SinAspectAngle
			outerVertexArray[#outerVertexArray + 1] 	= MaxRange 	* CosAspectAngle
		end

		outerVertexArrayHandle = Renderer.CreateVertexArray(outerVertexArray)
	end

end

function OnShutdown()
	
	if outerRenderStateHandle0 then
		Tacview.UI.Renderer.ReleaseRenderState(outerRenderStateHandle0)
		outerRenderStateHandle0 = nil
	end
	
		
	if innerRenderStateHandle0 then
		Tacview.UI.Renderer.ReleaseRenderState(innerRenderStateHandle0)
		innerRenderStateHandle0 = nil
	end
	
		
	if outerRenderStateHandle1 then
		Tacview.UI.Renderer.ReleaseRenderState(outerRenderStateHandle1)
		outerRenderStateHandle1 = nil
	end
	
		
	if innerRenderStateHandle1 then
		Tacview.UI.Renderer.ReleaseRenderState(innerRenderStateHandle1)
		innerRenderStateHandle1 = nil
	end
	
		
	if outerVertexArrayHandle then
		Tacview.UI.Renderer.ReleaseVertexArray(outerVertexArrayHandle)
		outerVertexArrayHandle = nil
	end
	
		
	if innerVertexArrayHandle then
		Tacview.UI.Renderer.ReleaseVertexArray(innerVertexArrayHandle)
		innerVertexArrayHandle = nil
	end
			
end

----------------------------------------------------------------
-- Initialize this addon
----------------------------------------------------------------

function Initialize()

	-- Declare addon properties

	local currentAddOn = Tacview.AddOns.Current

	currentAddOn.SetTitle("Control Zone")
	currentAddOn.SetVersion("1.9.4.1")
	currentAddOn.SetAuthor("BuzyBee")
	currentAddOn.SetNotes("Displays the control zone one or both selected aircraft.")

	-- Load preferences - use current addOnEnabledOption value as the default setting

	addOnEnabledOption = Tacview.AddOns.Current.Settings.GetBoolean(AddOnEnabledSettingName, addOnEnabledOption)

	-- Declare menus

	local addOnMenuId = Tacview.UI.Menus.AddMenu(nil, "Control Zone")
	
	addOnEnabledMenuId = Tacview.UI.Menus.AddOption(addOnMenuId, "Display Control Zone", addOnEnabledOption, OnMenuEnableAddOn)

	-- Register callbacks

	Tacview.Events.DrawTransparentObjects.RegisterListener(OnDrawTransparentObjects)
	Tacview.Events.Shutdown.RegisterListener(OnShutdown) 

end

Initialize()
