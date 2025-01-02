
--[[
	Speed Thresholds

	Author: BuzyBee
	Last update: 2023-02-28 (Tacview 1.9.0)

	Feel free to modify and improve this script!
--]]

--[[

	MIT License

	Copyright (c) 2023-2025 Raia Software Inc.

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

local displaySpeedsSettingName = "Display Speeds"

----------------------------------------------------------------
-- UI commands and options
----------------------------------------------------------------

local MaxIAS 	= 200	-- m/s
local MinIAS 	= 50	-- m/s
local MaxVS 	= 150	-- m/s
local MinVS 	= -150	-- m/s
local MaxGS		= 200	-- m/s
local MinGS 	= 50	-- m/s

local GreenColor = string.char(1)
local OrangeColor = string.char(2)
local BlueColor = string.char(3)
local RedColor = string.char(4)
local BlackColor = string.char(5)
local DefaultColor = string.char(6)

local displaySpeedsMenuId
local displaySpeeds = true

local msg = ""

-- local mps2knots = 1.94384

local backgroundRenderStateHandle
local backgroundVertexArrayHandle

local statisticsRenderStateHandle


function OnMenuEnableAddOn()

	-- Enable/disable add-on

	displaySpeeds = not displaySpeeds

	-- Save option value in registry

	Tacview.AddOns.Current.Settings.SetBoolean(displaySpeedsSettingName, displaySpeeds)

	-- Update menu with the new option value

	Tacview.UI.Menus.SetOption(displaySpeedsMenuId, displaySpeeds)

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
local backgroundWidth
local backgroundHeight

function DisplayBackground()

	local lineCount, maxWidth = GetLineCount(msg)

	backgroundHeight = FontSize * lineCount + 2 * Margin
	backgroundWidth = FontSize * maxWidth / 2 
	
	if (backgroundWidth ~= previousBackgroundWidth or not backgroundWidth or not previousBackgroundWidth) and backgroundVertexArrayHandle then
		Tacview.UI.Renderer.ReleaseVertexArray(backgroundVertexArrayHandle)
		backgroundVertexArrayHandle = nil
	end

	previousBackgroundWidth = backgroundWidth
	

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
			0,-backgroundHeight,0,
			backgroundWidth,-backgroundHeight,0,
			0,0,0,
			backgroundWidth,0,0,
			backgroundWidth,-backgroundHeight,0,
			0,0,0,

		}

		backgroundVertexArrayHandle = Tacview.UI.Renderer.CreateVertexArray(vertexArray)
	end

	local backgroundTransform =
	{
		x = Tacview.UI.Renderer.GetWidth() - backgroundWidth - Margin,
		y = Tacview.UI.Renderer.GetHeight() / 2 + backgroundHeight / 2,
		scale = 1,
	}

	Tacview.UI.Renderer.DrawUIVertexArray(backgroundTransform, backgroundRenderStateHandle, backgroundVertexArrayHandle)
end

function OnDrawTransparentUI()

	if not displaySpeeds then
		return
	end

	-- Compile render state

	if not statisticsRenderStateHandle then
		statisticsRenderStateHandle = Tacview.UI.Renderer.CreateRenderState(StatisticsRenderState)
	end

	local renderer = Tacview.UI.Renderer
	
	if string.len(msg)>0 then
		DisplayBackground()
	else
			return
	end
	
	local transform =
	{
		x = Tacview.UI.Renderer.GetWidth() - backgroundWidth, --x = 2 * Margin, 
		y = Tacview.UI.Renderer.GetHeight() / 2 + backgroundHeight / 2 + - FontSize * 1.5,
		scale = FontSize,
	}
	
	renderer.Print(transform, statisticsRenderStateHandle, msg)

end

----------------------------------------------------------------
-- Main loop
----------------------------------------------------------------

-- Update is called once a frame by Tacview
-- Here we retrieve current values which will be displayed by OnDrawTransparentUI()

function OnUpdate(dt, absoluteTime)

	-- Verify that the user wants to display speeds
	
	msg = ""
	
	if not displaySpeeds then
		return
	end
	
	local currentIAS = nil
	local currentVerticalSpeed = nil
	local currentGroundSpeed = nil
	
	local objectHandle = Tacview.Context.GetSelectedObject(0)
	
	
	
	if objectHandle then
	
		msg = msg .. "--- " .. Tacview.Telemetry.GetCurrentShortName(objectHandle) .. " ---"
	
		local IASPropertyIndex = Tacview.Telemetry.GetObjectsNumericPropertyIndex("IAS",false)
		
		if IASPropertyIndex ~= Tacview.Telemetry.InvalidPropertyIndex then
		
			local IAS, sampleIsValid = Tacview.Telemetry.GetNumericSample(objectHandle, absoluteTime, IASPropertyIndex ) 
			
			if sampleIsValid then
			
				currentIAS = IAS
				
					if currentIAS < MinIAS or currentIAS > MaxIAS then
					
							msg = msg .. RedColor .. "\nIAS: " .. Tacview.UI.Format.SpeedToText(currentIAS) .. BlackColor
							
					else
						
							msg = msg .. BlackColor .. "\nIAS: " .. Tacview.UI.Format.SpeedToText(currentIAS) .. BlackColor
												
					end				

			end
		end			
		
		currentVerticalSpeed = GetVerticalSpeed(objectHandle, absoluteTime)
		
		if currentVerticalSpeed < MinVS or currentVerticalSpeed > MaxVS then
		
				msg = msg .. RedColor .. "\nVS : " .. Tacview.UI.Format.SpeedToText(currentVerticalSpeed) .. BlackColor
				
		else
			
				msg = msg .. BlackColor .. "\nVS : " .. Tacview.UI.Format.SpeedToText(currentVerticalSpeed)  .. BlackColor
	
	end	
		
		currentGroundSpeed = GetGroundSpeed(objectHandle, absoluteTime)
		
		if currentGroundSpeed < MinGS or currentGroundSpeed > MaxGS then
			
				msg = msg .. RedColor .. "\nGS : " .. Tacview.UI.Format.SpeedToText(currentGroundSpeed) .. BlackColor
						
		else
			
				msg = msg .. BlackColor .."\nGS : " .. Tacview.UI.Format.SpeedToText(currentGroundSpeed)  .. BlackColor
									
		end		
		
	end
	
end

function GetVerticalSpeed(objectHandle, absoluteTime)

	local dt = 1.0
	
	local transform0 = Tacview.Telemetry.GetTransform(objectHandle , absoluteTime-dt)
	local transform1 = Tacview.Telemetry.GetTransform(objectHandle , absoluteTime)
	
	local speed 
	
	if transform0 and transform1 and transform0.altitude and transform1.altitude then
	
		speed = (transform1.altitude - transform0.altitude) / dt
		
	end
	
	return speed
end

function GetGroundSpeed(objectHandle, absoluteTime)

	local dt = 1.0
	
	local transform0 = Tacview.Telemetry.GetTransform(objectHandle , absoluteTime-dt)
	local transform1 = Tacview.Telemetry.GetTransform(objectHandle , absoluteTime)
	
	local distance = nil
	
	if transform0 and transform1 then	
		distance = Tacview.Math.Vector.GetDistanceOnEarth(transform0.longitude, transform0.latitude, transform1.longitude, transform1.latitude, 0)
	end

	return distance / dt

end

----------------------------------------------------------------
-- Initialize this addon
----------------------------------------------------------------

function Initialize()

	-- Declare add-on information

	Tacview.AddOns.Current.SetTitle("Speed Thresholds")
	Tacview.AddOns.Current.SetVersion("0.1")
	Tacview.AddOns.Current.SetAuthor("BuzyBee")
	Tacview.AddOns.Current.SetNotes("Displays IAS, VS and GS in 3D view.")

	-- Load user preferences
	-- The variable displaySpeeds already contain the default setting

	displaySpeeds = Tacview.AddOns.Current.Settings.GetBoolean(displaySpeedsSettingName, displaySpeeds)

	-- Declare menus

	local mainMenuId = Tacview.UI.Menus.AddMenu(nil, "Speed Thresholds")
	displaySpeedsMenuId = Tacview.UI.Menus.AddOption(mainMenuId, "Display Speeds", displaySpeeds, OnMenuEnableAddOn)

	-- Register callbacks

	Tacview.Events.Update.RegisterListener(OnUpdate)
	Tacview.Events.DrawTransparentUI.RegisterListener(OnDrawTransparentUI)
end

Initialize()
