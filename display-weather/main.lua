
--[[
	Display Weather

	Author: BuzyBee
	Last update: 2024-08-17 (Tacview 1.9.4)

	Feel free to modify and improve this script!
--]]

--[[

	MIT License

	Copyright (c) 2024-2025 Raia Software Inc.

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

local settingName = "Display Weather"

----------------------------------------------------------------
-- UI commands and options
----------------------------------------------------------------

local addOnEnabledMenuId
local addOnEnabled = false

local msg = ""

local backgroundRenderStateHandle
local backgroundVertexArrayHandle

local textRenderStateHandle

local hPa2inHg = 0.02953

function OnMenuEnableAddOn()

	-- Enable/disable add-on

	addOnEnabled = not addOnEnabled

	-- Save option value in registry

	Tacview.AddOns.Current.Settings.SetBoolean(settingName, addOnEnabled)

	-- Update menu with the new option value

	Tacview.UI.Menus.SetOption(addOnEnabledMenuId, addOnEnabled)

end

local Margin = 16
local FontSize = 24
local FontColor = 0xff000000		-- Black text

local TextRenderState =
{
	color = FontColor,
	blendMode = Tacview.UI.Renderer.BlendMode.Normal,
}

local currentBackgroundWidth =0
local currentBackgroundHeight=0

function DisplayBackground()

	if not backgroundRenderStateHandle then

		local renderState =
		{
			color = 0x80ffffff,
		}

		backgroundRenderStateHandle = Tacview.UI.Renderer.CreateRenderState(renderState)

	end

	local backgroundHeight = FontSize*getLineCount(msg)
	local backgroundWidth = FontSize*getMaxWidth(msg)*0.55

	if not backgroundVertexArrayHandle or (currentBackgroundHeight ~= backgroundHeight or currentBackgroundWidth ~= backgroundWidth) then

		-- Rebuild background from scratch if parameters have changed.

		if backgroundVertexArrayHandle then
			Tacview.UI.Renderer.ReleaseVertexArray( backgroundVertexArrayHandle )
			backgroundVertexArrayHandle = nil
		end

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

		currentBackgroundHeight = backgroundHeight
		currentBackgroundWidth = backgroundWidth

	end

	local backgroundTransform =
	{
		x = Margin,
		y = Tacview.UI.Renderer.GetHeight() * 0.75,
		scale = 1,
	}

	if backgroundRenderStateHandle and backgroundVertexArrayHandle then

		Tacview.UI.Renderer.DrawUIVertexArray(backgroundTransform, backgroundRenderStateHandle, backgroundVertexArrayHandle)

	end
end

function getLineCount(str)
	local lines = 1
	for i = 1, #str do
		local c = str:sub(i, i)
		if c == '\n' then lines = lines + 1 end
	end

	return lines
end

function getMaxWidth(str)

	local maxWidth = 0
	local count = 0

	for i = 1, #str do
		count = count+1
		local c = str:sub(i, i)
		if c == '\n' or i==#str then
			maxWidth = math.max(count,maxWidth)
			count=0
		end
	end

	return maxWidth
end

function OnDrawTransparentUI()

	if not addOnEnabled then
		return
	end

	-- Compile render state

	if not textRenderStateHandle then
		textRenderStateHandle = Tacview.UI.Renderer.CreateRenderState(TextRenderState)
	end

	local renderer = Tacview.UI.Renderer

	local transform =
	{
		x = 2*Margin,
		y = Tacview.UI.Renderer.GetHeight() * .75,
		scale = FontSize,
	}

	if string.len(msg)>0 then
		DisplayBackground()
		renderer.Print(transform, textRenderStateHandle, msg)
	end

end

----------------------------------------------------------------
-- Main loop
----------------------------------------------------------------

-- Update is called once a frame by Tacview
-- Here we retrieve current values which will be displayed by OnDrawTransparentUI()

function OnUpdate(dt, absoluteTime)

	-- Verify that the user wants to display values

	msg = ""

	if not addOnEnabled then
		return
	end

	local activeObjects = Tacview.Context.GetActiveObjectList()

	local windSpeedPropertyIndex = Tacview.Telemetry.GetObjectsNumericPropertyIndex("WindSpeed", false)
	local WindDirectionPropertyIndex = Tacview.Telemetry.GetObjectsNumericPropertyIndex("WindDirection", false)
	local QNHPropertyIndex = Tacview.Telemetry.GetGlobalNumericPropertyIndex("QNH", false)
	local pilotPropertyIndex = Tacview.Telemetry.GetObjectsTextPropertyIndex("Pilot", false)
	local groupPropertyIndex = Tacview.Telemetry.GetObjectsTextPropertyIndex("Group", false)

	-- Get the QNH and display it

	local qnh, qnhIsValid

	if QNHPropertyIndex ~= Tacview.Telemetry.InvalidPropertyIndex then

		qnh, qnhIsValid = Tacview.Telemetry.GetNumericSample(0, absoluteTime, QNHPropertyIndex)

		if qnhIsValid then
			msg = msg .. "\n\nQNH ".. math.floor(qnh+0.5) .. "/" .. math.floor(qnh*hPa2inHg*100)/100
		end
	end

	-- Check each active object to find objects with wind - WindProbe or local aircraft

	for k,objectHandle in ipairs(activeObjects) do

		if windSpeedPropertyIndex == Tacview.Telemetry.InvalidPropertyIndex or Tacview.Telemetry.GetNumericSampleCount(objectHandle, windSpeedPropertyIndex ) == 0 then
			goto continue
		end

		-- current objectHandle contains wind - it is either WindProbe or local aircraft. List an appropriate object name name.

		local pilot=""
		local group=""

		if pilotPropertyIndex ~= Tacview.Telemetry.InvalidPropertyIndex then

			local potentialPilot, pilotIsValid 	= Tacview.Telemetry.GetTextSample(objectHandle , absoluteTime , pilotPropertyIndex)

			if pilotIsValid then
				pilot= potentialPilot
			end
		end

		if groupPropertyIndex ~= Tacview.Telemetry.InvalidPropertyIndex then

			local potentialGroup, groupIsValid 	= Tacview.Telemetry.GetTextSample(objectHandle , absoluteTime , groupPropertyIndex)

			if groupIsValid then
				group = potentialGroup
			end
		end

		-- If it's a WindProbe remove the string WindProbe from the name. Otherwise, display the pilot name.

		if 	string.match(pilot,"WindProbe") or string.match(group,"WindProbe") then

			local pilotTrimmed = string.gsub(pilot, "WindProbe","")

			if string.len(pilotTrimmed) ~=0 then
				msg = msg .. "\n\n" .. pilotTrimmed
			else
				msg = msg .. "\n\n" .. Tacview.Telemetry.GetCurrentShortName(objectHandle)
			end
		else

			msg = msg .. "\n\n" .. pilot

		end

		local transform = Tacview. Telemetry.GetCurrentTransform(objectHandle)

		local altitude = transform.altitude

		-- https://www.sensorsone.com/elevation-station-qfe-sea-level-qnh-pressure-calculator/

		if qnh then
			local qfe = qnh * (1+(-0.0065*altitude)/288.15)^(-9.80665/(-0.0065*287.05287))
			msg = msg .. "\n    QFE ".. math.floor(qfe+0.5) .. "/" .. string.format("%.2f",math.floor(qfe*hPa2inHg*100)/100)
		end

		local windDirection, windDirectionIsValid 	= Tacview.Telemetry.GetNumericSample(objectHandle , absoluteTime , WindDirectionPropertyIndex)

		if windDirectionIsValid then
			windDirection = math.fmod(windDirection+180,360)
			windDirection = math.floor(windDirection+0.5)
			msg = msg .. "\n    W/V " .. string.format("%03d",windDirection)
		end

		local windSpeed, windSpeedIsValid 	= Tacview.Telemetry.GetNumericSample(objectHandle , absoluteTime , windSpeedPropertyIndex)

		if windSpeedIsValid then
			if windDirectionIsValid then
				windSpeed = Tacview.Math.Units.MetersPerSecondToKnots(windSpeed)
				windSpeed = math.floor(windSpeed+0.5)

				msg = msg .. "/" .. string.format("%02d",windSpeed)
			else
				msg = msg .. "\n    W/V    /"..windSpeed
			end

		end

		::continue::
	end
end

function OnCleanUp()

	if backgroundRenderStateHandle then
		Tacview.UI.Renderer.ReleaseRenderState(backgroundRenderStateHandle)
		backgroundRenderStateHandle = nil
	end

	if backgroundVertexArrayHandle then
		Tacview.UI.Renderer.ReleaseVertexArray( backgroundVertexArrayHandle )
		backgroundVertexArrayHandle = nil
	end

	if textRenderStateHandle then
		Tacview.UI.Renderer.ReleaseRenderState(textRenderStateHandle)
		textRenderStateHandle = nil
	end

	currentBackgroundWidth = 0
	currentBackgroundHeight = 0

end

----------------------------------------------------------------
-- Initialize this addon
----------------------------------------------------------------

function Initialize()

	-- Declare add-on information

	Tacview.AddOns.Current.SetTitle("Display Weather Conditions")
	Tacview.AddOns.Current.SetVersion("1.9.4")
	Tacview.AddOns.Current.SetAuthor("BuzyBee")
	Tacview.AddOns.Current.SetNotes("Displays QNH and Wind Information where available.")

	-- Load user preferences
	-- The variable addOnEnabled already contain the default setting

	addOnEnabled = Tacview.AddOns.Current.Settings.GetBoolean(settingName, addOnEnabled)

	-- Declare menus

	local mainMenuId = Tacview.UI.Menus.AddMenu(nil, "Display Weather")
	addOnEnabledMenuId = Tacview.UI.Menus.AddOption(mainMenuId, "Display Weather", addOnEnabled, OnMenuEnableAddOn)

	-- Register callbacks

	Tacview.Events.Update.RegisterListener(OnUpdate)
	Tacview.Events.DrawTransparentUI.RegisterListener(OnDrawTransparentUI)
	Tacview.Events.Shutdown.RegisterListener(OnCleanUp)
	Tacview.Events.DocumentLoaded.RegisterListener(OnCleanUp)

end

Initialize()
