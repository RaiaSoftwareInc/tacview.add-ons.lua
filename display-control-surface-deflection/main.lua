
--[[
	Display Control Surface Deflection

	Author: BuzyBee
	Last update: 2024-11-28 (Tacview 1.9.4)

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

local Tacview = require("Tacview190")

----------------------------------------------------------------
-- Constants
----------------------------------------------------------------

local displayValuesSettingName = "Display Values"

----------------------------------------------------------------
-- UI commands and options
----------------------------------------------------------------

local TurnRateCustomDT = 20		-- Positive Integers Only (1,2,3,...)
local SpeedCustomDT = 20		-- Positive Integers Only  (1,2,3,...)

local displayValuesMenuId
local displayValues = true

local msg = ""

local mps2knots = 1.94384

local backgroundRenderStateHandle
local backgroundVertexArrayHandle

local statisticsRenderStateHandle

local OrangeColor = string.char(2)
local DefaultColor = string.char(6)
local GreenColor = string.char(1)


function OnMenuEnableAddOn()

	-- Enable/disable add-on

	displayValues = not displayValues

	-- Save option value in registry

	Tacview.AddOns.Current.Settings.SetBoolean(displayValuesSettingName, displayValues)

	-- Update menu with the new option value

	Tacview.UI.Menus.SetOption(displayValuesMenuId, displayValues)

end

local Margin = 16
local FontSize = 24
local FontColor = 0xff000000		-- Black text

local StatisticsRenderState =
{
	color = FontColor,
	blendMode = Tacview.UI.Renderer.BlendMode.Normal,
}

local function GetLineCount(str)

	local lines = 1
	local maxWidth = 0
	local width = 0
	
    for i = 1, #str do
    	local c = str:sub(i, i)		
		width = width + 1
		maxWidth = math.max(maxWidth,width)
	    if c == '\n' then 
			lines = lines + 1 
			width = 0				
		end
    end

    return lines, maxWidth
end

local previousBackgroundWidth

function DisplayBackground()

	local lineCount, maxWidth = GetLineCount(msg)

	local BackgroundHeight = FontSize * lineCount
	local BackgroundWidth = FontSize * maxWidth / 2 
	
	if BackgroundWidth ~= previousBackgroundWidth and backgroundVertexArrayHandle then
		Tacview.UI.Renderer.ReleaseVertexArray(backgroundVertexArrayHandle)
		backgroundVertexArrayHandle = nil
	end

	previousBackgroundWidth = BackgroundWidth	

	if not backgroundRenderStateHandle then

		local renderState =
		{
			color = 0x80ffffff,	
		}

		backgroundRenderStateHandle = Tacview.UI.Renderer.CreateRenderState(renderState)

	end

	if not backgroundVertexArrayHandle then

		local vertexArray =
		{
			0,0,0,
			0,-BackgroundHeight,0,
			BackgroundWidth,-BackgroundHeight,0,
			0,0,0,
			BackgroundWidth,0,0,
			BackgroundWidth,-BackgroundHeight,0,
			0,0,0,

		}

		backgroundVertexArrayHandle = Tacview.UI.Renderer.CreateVertexArray(vertexArray)
	end

	local backgroundTransform =
	{
		x = 300,
		y = Tacview.UI.Renderer.GetHeight() - 18,
		scale = 1,
	}

	Tacview.UI.Renderer.DrawUIVertexArray(backgroundTransform, backgroundRenderStateHandle, backgroundVertexArrayHandle)
end

function OnDrawTransparentUI()

	if not displayValues then
		return
	end

	-- Compile render state

	if not statisticsRenderStateHandle then
		statisticsRenderStateHandle = Tacview.UI.Renderer.CreateRenderState(StatisticsRenderState)
	end

	local renderer = Tacview.UI.Renderer

	local transform =
	{
		x = 300 + Margin,
		y = Tacview.UI.Renderer.GetHeight() - Margin - FontSize,
		scale = FontSize,
	}

	if string.len(msg)>0 then
		DisplayBackground()
	end
	
	renderer.Print(transform, statisticsRenderStateHandle, msg)
	
end

----------------------------------------------------------------
-- Main loop
----------------------------------------------------------------

-- Update is called once a frame by Tacview
-- Here we retrieve current values which will be displayed by OnDrawTransparentUI()

function OnUpdate(dt, absoluteTime)

	-- Verify that the user wants to display values
	
	if not displayValues then
		return
	end
	
	msg = ""
	
	local objectHandle0 = Tacview.Context.GetSelectedObject(0)
	
	if objectHandle0 then
	
		--msg = msg .. Tacview.Telemetry.GetCurrentShortName(objectHandle0) .. ": "
		
		printSurfaceDeflection(objectHandle0, absoluteTime)
	
	end
	
	--local objectHandle1 = Tacview.Context.GetSelectedObject(1)
	
	--if objectHandle1 then
	
	--	msg = msg .. "\n" .. Tacview.Telemetry.GetCurrentShortName(objectHandle1) .. ": "
		
	--	printSurfaceDeflection(objectHandle1, absoluteTime)
	
	--end
	
end

function printSurfaceDeflection(objectHandle, absoluteTime)

	local aileronLeftPropertyIndex = Tacview.Telemetry.GetObjectsNumericPropertyIndex("AileronLeft", false )
	
	if aileronLeftPropertyIndex ~= Tacview.Telemetry.InvalidPropertyIndex then
	
		local aileronLeft, sampleIsValid = Tacview.Telemetry.GetNumericSample(objectHandle , absoluteTime , aileronLeftPropertyIndex)
		
		if sampleIsValid then
			
			if aileronLeft >= 0 then
				msg = msg .. "Ailerons:  " .. string.format("%.0f",aileronLeft * 100) .. "%"
			else
				msg = msg .. "Ailerons: " .. string.format("%.0f",aileronLeft * 100) .. "%"
			end
		end
			
	end	
	
	local aileronRightPropertyIndex = Tacview.Telemetry.GetObjectsNumericPropertyIndex("AileronRight", false )
	
	if aileronRightPropertyIndex ~= Tacview.Telemetry.InvalidPropertyIndex then
	
		local aileronRight, sampleIsValid = Tacview.Telemetry.GetNumericSample(objectHandle , absoluteTime , aileronRightPropertyIndex)
		
		if sampleIsValid then
		
			if aileronRight >= 0 then
		
				msg = msg .. " / "..string.format("%.0f",aileronRight * 100) .. "%\n"
			else
				msg = msg .. " /"..string.format("%.0f",aileronRight * 100) .. "%\n"
			end
			
		end
	end
	
	
	local elevatorPropertyIndex = Tacview.Telemetry.GetObjectsNumericPropertyIndex("Elevator", false )
	
	if elevatorPropertyIndex ~= Tacview.Telemetry.InvalidPropertyIndex then
	
		local elevator, sampleIsValid = Tacview.Telemetry.GetNumericSample(objectHandle , absoluteTime , elevatorPropertyIndex)
		
		if sampleIsValid then
			
			if elevator >= 0 then
				msg = msg .. "Elevator:  " .. string.format("%.0f",elevator * 100) .. "%\n"
			else			
				msg = msg .. "Elevator: " .. string.format("%.0f",elevator * 100) .. "%\n"
			end			
		end
	end
	
	
	local rudderPropertyIndex = Tacview.Telemetry.GetObjectsNumericPropertyIndex("Rudder", false )
	
	if rudderPropertyIndex ~= Tacview.Telemetry.InvalidPropertyIndex then
	
		local rudder, sampleIsValid = Tacview.Telemetry.GetNumericSample(objectHandle , absoluteTime , rudderPropertyIndex)
		
		if sampleIsValid then
			
			if rudder >= 0 then
			
				msg = msg .. "Rudder  :  " .. string.format("%.0f",rudder * 100) .. "%"
			else
				msg = msg .. "Rudder  : " .. string.format("%.0f",rudder * 100) .. "%"
			end			
		end	
	end
end
	
----------------------------------------------------------------
-- Initialize this addon
----------------------------------------------------------------

function Initialize()

	-- Declare add-on information

	Tacview.AddOns.Current.SetTitle("Display Surface Deflection")
	Tacview.AddOns.Current.SetVersion("1.9.4")
	Tacview.AddOns.Current.SetAuthor("BuzyBee")
	Tacview.AddOns.Current.SetNotes("Display Surface Deflection.")

	-- Load user preferences

	displayValues = Tacview.AddOns.Current.Settings.GetBoolean(displayValuesSettingName, displayValues)

	-- Declare menus

	local mainMenuId = Tacview.UI.Menus.AddMenu(nil, "Surface Deflection")
	displayValuesMenuId = Tacview.UI.Menus.AddOption(mainMenuId, "Show Surface Deflection", displayValues, OnMenuEnableAddOn)

	-- Register callbacks

	Tacview.Events.Update.RegisterListener(OnUpdate)
	Tacview.Events.DrawTransparentUI.RegisterListener(OnDrawTransparentUI)
end

Initialize()
