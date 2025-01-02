
--[[
	Display Time

	Author: BuzyBee
	Last update: 2022-04-15 (Tacview 1.8.7)

	Feel free to modify and improve this script!
--]]

--[[

	MIT License

	Copyright (c) 2021-2025 Raia Software Inc.

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

local Tacview = require("Tacview187")

----------------------------------------------------------------
-- Constants
----------------------------------------------------------------

local DisplayValuesSettingName = "DisplayTime"

----------------------------------------------------------------
-- UI commands and options
----------------------------------------------------------------

local displayValuesMenuId
local DisplayValues = true

function OnMenuEnableAddOn()

	-- Enable/disable add-on

	DisplayValues = not DisplayValues

	-- Save option value in registry

	Tacview.AddOns.Current.Settings.SetBoolean(DisplayValuesSettingName, DisplayValues)

	-- Update menu with the new option value

	Tacview.UI.Menus.SetOption(displayValuesMenuId, DisplayValues)

end

local Margin = 16
local FontSize = 24
local FontColor = 0xff000000		-- Black text

local statisticsRenderState =
{
	color = FontColor,
	blendMode = Tacview.UI.Renderer.BlendMode.Normal,
}

function DisplayBackground()

	local BackgroundHeight = 80	
	local BackgroundWidth = 247

	local backgroundRenderStateHandle

	if not backgroundRenderStateHandle then

		local renderState =
		{
			color = 0xffffffff,	-- white background
		}

		backgroundRenderStateHandle = Tacview.UI.Renderer.CreateRenderState(renderState)

	end

	local backgroundVertexArrayHandle

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
		x = Margin,
		y = Tacview.UI.Renderer.GetHeight(),
		scale = 1,
	}

	Tacview.UI.Renderer.DrawUIVertexArray(backgroundTransform, backgroundRenderStateHandle, backgroundVertexArrayHandle)
end

local statisticsRenderStateHandle

function OnDrawTransparentUI()

	if not DisplayValues then
		return
	end

	-- Compile render state

	if not statisticsRenderStateHandle then
		statisticsRenderStateHandle = Tacview.UI.Renderer.CreateRenderState(statisticsRenderState)
	end

	local renderer = Tacview.UI.Renderer

	local transform =
	{
		x = Margin,
		y = renderer.GetHeight() - FontSize,
		scale = FontSize,
	}

	DisplayBackground()
	
	local absoluteTime = Tacview.Context.GetAbsoluteTime()
	local fractionsOfSeconds = (absoluteTime - math.floor(absoluteTime))
	local hundredthsOfSeconds = math.floor(fractionsOfSeconds * 100 + 0.5) 
	
	local dateArray = os.date("*t",math.floor(absoluteTime))
	
	local dateString = 	"\n    " .. dateArray.year .. "-" .. string.format("%02d",dateArray.month) .. "-" .. string.format("%02d",dateArray.day) .. "\n    " .. 
						string.format("%02d",dateArray.hour) .. ":" .. string.format("%02d",dateArray.min) .. ":" .. string.format("%02d",dateArray.sec) .. "." .. hundredthsOfSeconds
	
	renderer.Print(transform, statisticsRenderStateHandle, dateString)

end

----------------------------------------------------------------
-- Initialize this addon
----------------------------------------------------------------

function Initialize()

	-- Declare add-on information

	Tacview.AddOns.Current.SetTitle("Customize Time Block")
	Tacview.AddOns.Current.SetVersion("1.8.7")
	Tacview.AddOns.Current.SetAuthor("BuzyBee")
	Tacview.AddOns.Current.SetNotes("Displays time in hundredths of seconds")

	-- Load user preferences
	-- The variable DisplayValues already contain the default setting

	DisplayValues = Tacview.AddOns.Current.Settings.GetBoolean(DisplayValuesSettingName, DisplayValues)

	-- Declare menus

	local mainMenuId = Tacview.UI.Menus.AddMenu(nil, "Customize Time Block")
	displayValuesMenuId = Tacview.UI.Menus.AddOption(mainMenuId, "Show Fractions of Seconds", DisplayValues, OnMenuEnableAddOn)

	-- Register callbacks

	Tacview.Events.DrawTransparentUI.RegisterListener(OnDrawTransparentUI)
end

Initialize()
