
--[[
	Display Values

	Author: BuzyBee
	Last update: 2023-08-14 (Tacview 1.9.0)

	Feel free to modify and improve this script!
--]]

--[[

	MIT License

	Copyright (c) 2021-2023 Raia Software Inc.

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

local displayFlighTimeMenuId
local displayFlightTime = true

local msg0 = ""
local msg1 = ""

local backgroundRenderStateHandle
local backgroundVertexArrayHandle

local statisticsRenderStateHandle

function OnMenuEnableAddOn()

	-- Enable/disable add-on

	displayFlightTime = not displayFlightTime

	-- Save option value in registry

	Tacview.AddOns.Current.Settings.SetBoolean(displayValuesSettingName, displayFlightTime)

	-- Update menu with the new option value

	Tacview.UI.Menus.SetOption(displayFlighTimeMenuId, displayFlightTime)

end

local Margin = 16
local FontSize = 24
local FontColor = 0xff000000		-- Black text

local StatisticsRenderState =
{
	color = FontColor,
	blendMode = Tacview.UI.Renderer.BlendMode.Normal,
}

function DisplayBackground0()

	local BackgroundHeight = FontSize
	local BackgroundWidth = Tacview.UI.Renderer.GetWidth() * 0.2
	
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

	local background0Transform =
	{
		x = Tacview.UI.Renderer.GetWidth() * 0.2,
		y = Tacview.UI.Renderer.GetHeight(),
		scale = 1,
	}

	Tacview.UI.Renderer.DrawUIVertexArray(background0Transform, backgroundRenderStateHandle, backgroundVertexArrayHandle)

end

function DisplayBackground1()

	local BackgroundHeight = FontSize
	local BackgroundWidth = Tacview.UI.Renderer.GetWidth() * 0.2
	
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
	
	local background1Transform =
	{
		x = Tacview.UI.Renderer.GetWidth() * 0.6,
		y = Tacview.UI.Renderer.GetHeight(),
		scale = 1,
	}

	Tacview.UI.Renderer.DrawUIVertexArray(background1Transform, backgroundRenderStateHandle, backgroundVertexArrayHandle)

end

function OnDrawTransparentUI()

	if not displayFlightTime then
		return
	end

	-- Compile render state

	if not statisticsRenderStateHandle then
		statisticsRenderStateHandle = Tacview.UI.Renderer.CreateRenderState(StatisticsRenderState)
	end
	
	local renderer = Tacview.UI.Renderer

	local transform0 =
	{
		x = Tacview.UI.Renderer.GetWidth() * 0.2 + Margin,
		y = Tacview.UI.Renderer.GetHeight() - FontSize,
		scale = FontSize,
	}
	
	local transform1 =
	{
		x = Tacview.UI.Renderer.GetWidth() * 0.6 + Margin,
		y = Tacview.UI.Renderer.GetHeight() - FontSize,
		scale = FontSize,
	}
	
	if Tacview.Context.GetSelectedObject(0) and msg0 ~= "" then
		DisplayBackground0()
		renderer.Print(transform0, statisticsRenderStateHandle, msg0)
	end
	
	if Tacview.Context.GetSelectedObject(1) and msg1 ~= "" then
		DisplayBackground1()
		renderer.Print(transform1, statisticsRenderStateHandle, msg1)
	end
	
end

----------------------------------------------------------------
-- Main loop
----------------------------------------------------------------

-- Update is called once a frame by Tacview
-- Here we retrieve current values which will be displayed by OnDrawTransparentUI()

function OnUpdate(dt, absoluteTime)

	msg0 = ""
	msg1 = ""

	-- Verify that the user wants to display values

	if not displayFlightTime then
		return
	end
	
	local objectHandle0 = Tacview.Context.GetSelectedObject(0)
	
	if objectHandle0 then

		local lifeTimeBegin0, lifeTimeEnd0 = Tacview.Telemetry.GetLifeTime(objectHandle0)
		
		if lifeTimeBegin0 and lifeTimeEnd0 and Tacview.Context.GetAbsoluteTime() < lifeTimeEnd0 then
		
			local timeElapsed = Tacview.Context.GetAbsoluteTime() - lifeTimeBegin0
			
			if timeElapsed > 0 then
				msg0 = "Flight Time: " .. disp_time(timeElapsed)
			end
			
		end

	end
	
	local objectHandle1 = Tacview.Context.GetSelectedObject(1)

	if objectHandle1 then

		local lifeTimeBegin1, lifeTimeEnd1 = Tacview.Telemetry.GetLifeTime(objectHandle1)
		
		if lifeTimeBegin1 and lifeTimeEnd1 and Tacview.Context.GetAbsoluteTime() < lifeTimeEnd1 then
			
			local timeElapsed = Tacview.Context.GetAbsoluteTime() - lifeTimeBegin1
			
			if timeElapsed > 0 then
				msg1 = "Flight Time: " .. disp_time(timeElapsed)
			end
		end

	end	

end

function disp_time(absoluteTime)
  local hours = math.floor((absoluteTime % 86400)/3600)
  local minutes = math.floor((absoluteTime % 3600)/60)
  local seconds = math.floor(absoluteTime % 60)
  return string.format("%02d:%02d:%02d",hours,minutes,seconds)
end

----------------------------------------------------------------
-- Initialize this addon
----------------------------------------------------------------

function Initialize()

	-- Declare add-on information

	Tacview.AddOns.Current.SetTitle("Display Flight Time")
	Tacview.AddOns.Current.SetVersion("1.9.0")
	Tacview.AddOns.Current.SetAuthor("BuzyBee")
	Tacview.AddOns.Current.SetNotes("Displays flight time for each selected object.")

	-- Load user preferences
	-- The variable displayFlightTime already contain the default setting

	displayFlightTime = Tacview.AddOns.Current.Settings.GetBoolean(displayValuesSettingName, displayFlightTime)

	-- Declare menus

	local mainMenuId = Tacview.UI.Menus.AddMenu(nil, "Flight Time")
	displayFlighTimeMenuId = Tacview.UI.Menus.AddOption(mainMenuId, "Display Flight Time", displayFlightTime, OnMenuEnableAddOn)

	-- Register callbacks

	Tacview.Events.Update.RegisterListener(OnUpdate)
	Tacview.Events.DrawTransparentUI.RegisterListener(OnDrawTransparentUI)
end

Initialize()
