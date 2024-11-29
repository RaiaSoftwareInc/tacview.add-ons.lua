
--[[
	Display Values

	Author: BuzyBee
	Last update: 2023-05-12 (Tacview 1.9.0)

	Feel free to modify and improve this script!
--]]

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
		x = Margin,
		y = FontSize * GetLineCount(msg) + FontSize,
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
		x = 2 * Margin, 
		y = FontSize * GetLineCount(msg),
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
	
	local currentTRT0 = nil
	local currentG0 = nil
	local currentTAS0 = nil
	local currentAOA0 = nil
	local currentTRT1 = nil
	local currentG1 = nil
	local currentTAS1 = nil
	local currentAOA1 = nil
	
	local currentTRT0_Custom = nil
	local currentTRT1_Custom = nil
	local currentTAS0_Custom = nil
	local currentTAS1_Custom = nil	
	
	local relativeBearingPlane1ToPlane2 = nil
	local relativeBearingPlane2ToPlane1 = nil

	local objectHandle0 = Tacview.Context.GetSelectedObject(0)
	local objectHandle1 = Tacview.Context.GetSelectedObject(1)
	
	if objectHandle0 and objectHandle1 then
	
		local dt = 1
	
		local transform0 = Tacview.Telemetry.GetTransform(objectHandle0, absoluteTime)
		local transform1 = Tacview.Telemetry.GetTransform(objectHandle1,absoluteTime)
		
		local P1 = {x=transform0.x, y=transform0.y,z=transform0.z}
		local P2 = {x=transform1.x, y=transform1.y,z=transform1.z}
		
		local P1forward = Tacview.Math.Vector.LocalToGlobal( transform0 , {x=0,y=0,z=-1}) 
		local P2forward = Tacview.Math.Vector.LocalToGlobal( transform1 , {x=0,y=0,z=-1})
		
		local V1 = Tacview.Math.Vector.Subtract(P1forward,P1)
		local V2 = Tacview.Math.Vector.Subtract(P2forward,P2)
		
		relativeBearingPlane1ToPlane2, relativeBearingPlane2ToPlane1 = calculateRelativeBearings(P1, V1, P2, V2)
				
	end

	if objectHandle0 then

		currentTRT0 = Tacview.Telemetry.GetCurrentTurnRate(objectHandle0)
		
		if currentTRT0 then
			currentTRT0 = math.deg(currentTRT0)
		end
		
		currentTRT0_Custom = GetAverageTRT(objectHandle0, absoluteTime, TurnRateCustomDT)

		if currentTRT0_Custom then
			currentTRT0_Custom = math.deg(currentTRT0_Custom)
		end

		currentG0 = Tacview.Telemetry.GetCurrentVerticalGForce(objectHandle0)

		currentTAS0 = GetCurrentTAS(objectHandle0, absoluteTime, 1)

		if currentTAS0 then
			currentTAS0 = mps2knots * currentTAS0
		end
		
		currentTAS0_Custom = GetAverageTAS(objectHandle0, absoluteTime, SpeedCustomDT)

		if currentTAS0_Custom then
			currentTAS0_Custom = mps2knots * currentTAS0_Custom
		end
		
		currentAOA0 = Tacview.Telemetry.GetCurrentAngleOfAttack(objectHandle0)
		
		if currentAOA0 then
			currentAOA0 = math.deg(currentAOA0)
		end
	end

	if objectHandle1 then

		currentTRT1 = Tacview.Telemetry.GetCurrentTurnRate(objectHandle1)

		if currentTRT1 then
			currentTRT1 = math.deg(currentTRT1)
		end
		
		currentTRT1_Custom = GetAverageTRT(objectHandle1, absoluteTime, TurnRateCustomDT)

		if currentTRT1_Custom then
			currentTRT1_Custom = math.deg(currentTRT1_Custom)
		end

		currentG1 = Tacview.Telemetry.GetCurrentVerticalGForce(objectHandle1)

		currentTAS1 = GetCurrentTAS(objectHandle1, absoluteTime, 1)

		if currentTAS1 then
			currentTAS1 = mps2knots * currentTAS1
		end	

		currentTAS1_Custom = GetAverageTAS(objectHandle1, absoluteTime, SpeedCustomDT)

		if currentTAS1_Custom then
			currentTAS1_Custom = mps2knots * currentTAS1_Custom
		end		
		
		currentAOA1 = Tacview.Telemetry.GetCurrentAngleOfAttack(objectHandle1)
		
		if currentAOA1 then
			currentAOA1 = math.deg(currentAOA1)
		end
	end
	
	if objectHandle0 then
		msg = Tacview.Telemetry.GetCurrentShortName(objectHandle0) .. ":\n"
	end

	if currentTAS0 then		
		msg = msg .. "TAS: "..string.format("%.1f",currentTAS0).." kts "
	end
	
	if currentTAS0_Custom then
		msg = msg .. "("..string.format("%.1f",currentTAS0_Custom)  .. " kts) | "
	end

	if currentTRT0 then
		msg = msg .. "TRT: "..string.format("%.1f",currentTRT0).." °/s "
	end
	
	if currentTRT0_Custom then
		msg = msg .. "("..string.format("%.1f",currentTRT0_Custom) .. " °/s) | "
	end

	if currentG0 then
		msg = msg .. "G: "..string.format("%.1f",currentG0).." G | "
	end
	
	if currentAOA0 then
		msg = msg .. "AOA: "..string.format("%.1f",currentAOA0)
	end
	
	if relativeBearingPlane1ToPlane2 then
		msg = msg .. " | Relative Bearing: " .. string.format("%.1f",math.deg(relativeBearingPlane1ToPlane2))
	end
	
	if relativeBearingPlane1ToPlane2 and relativeBearingPlane2ToPlane1 then
		
		local diff = relativeBearingPlane2ToPlane1 - relativeBearingPlane1ToPlane2
		
		if diff >= 0 then
			msg = msg .. " | Lead: " .. string.format("%.1f",math.deg(math.abs(diff))) .. "°"
		else
			msg = msg .. " | Lag: " .. string.format("%.1f",math.deg(math.abs(diff))) .. "°"
		end
	end
	
	if currentTAS1 or currentTRT1 or currentG1 or currentAOA1 or relativeBearingPlane2ToPlane1 then
	
		if objectHandle1 then
			msg = msg .. "\n" .. Tacview.Telemetry.GetCurrentShortName(objectHandle1) .. ":\n"
		end

		if currentTAS1 then			
			msg = msg .. "TAS: "..string.format("%.1f",currentTAS1).." kts "
		end
		
		if currentTAS1_Custom then
			msg = msg .. "("..string.format("%.1f",currentTAS1_Custom)  .. " kts) | "
		end
	
		if currentTRT1 then	
			msg = msg .. "TRT: "..string.format("%.1f",currentTRT1).." °/s "
		end
		
		if currentTRT1_Custom then
			msg = msg .. "("..string.format("%.1f",currentTRT1_Custom)  .. " °/s) | "
		end
	
		if currentG1 then	
			msg = msg .. "G: "..string.format("%.1f",currentG1).." G | "
		end
		
		if currentAOA1 then	
			msg = msg .. "AOA: "..string.format("%.1f",currentAOA1)
		end
		
		if relativeBearingPlane2ToPlane1 then	
			msg = msg .. " | Relative Bearing: "..string.format("%.1f",math.deg(relativeBearingPlane2ToPlane1))
		end		
			
		if relativeBearingPlane1ToPlane2 and relativeBearingPlane2ToPlane1 then
			
			local diff = relativeBearingPlane1ToPlane2 - relativeBearingPlane2ToPlane1
		
			if diff >= 0 then
				msg = msg .. " | Lead: " .. string.format("%.1f",math.deg(math.abs(diff))) .. "°"
			else
				msg = msg .. " | Lag: " .. string.format("%.1f",math.deg(math.abs(diff))) .. "°"
			end
		end
	
	end
	
end

function GetAverageTRT(objectHandle, absoluteTime, dt)

	local sum = 0
	local rate = 0

	if dt <= 1 then
		rate = Tacview.Telemetry.GetCurrentTurnRate(objectHandle)
	else
		
		dt = math.floor(dt+0.5)
		
		for i=1,dt do
			
			local turnRate = Tacview.Telemetry.GetTurnRate(objectHandle, absoluteTime - i,1)
			
			if turnRate then
				sum = sum + Tacview.Telemetry.GetTurnRate(objectHandle, absoluteTime - i,1)
			end
		end
		
		rate = sum / dt
	end
	
	return rate	

end

function GetAverageTAS(objectHandle, absoluteTime, dt)

	local sum = 0
	local speed = 0
	
	if dt <= 1 then
		speed = GetCurrentTAS(objectHandle, absoluteTime, dt)
	else
		
		dt = math.floor(dt+0.5)
		
		for i=1,dt do
			
			local tas = GetCurrentTAS(objectHandle, absoluteTime-i, 1)
			
			if tas then 
				sum = sum + GetCurrentTAS(objectHandle, absoluteTime-i, 1)
			end
		end
		
		speed = sum / dt
	end
	
	return speed	
end	

function GetCurrentTAS(objectHandle, absoluteTime, dt)

	local transform1, isTransform1Valid = Tacview.Telemetry.GetTransform(objectHandle, absoluteTime - dt)
	local transform2, isTransform2Valid = Tacview.Telemetry.GetTransform(objectHandle, absoluteTime)

	if isTransform1Valid == true and isTransform2Valid == true then

		local distance = Tacview.Math.Vector.GetDistanceBetweenObjects(transform1, transform2)
		return distance / dt
	end
end

function calculateRelativeBearings(P1, V1, P2, V2)

	local RelPos1 = Tacview.Math.Vector.Subtract(P2, P1)
		
    local RelPos2 = Tacview.Math.Vector.Subtract(P1, P2)

    local UnitRelPos1 = Tacview.Math.Vector.Normalize(RelPos1)
    local UnitV1 = Tacview.Math.Vector.Normalize(V1)
    local UnitRelPos2 = Tacview.Math.Vector.Normalize(RelPos2)
    local UnitV2 = Tacview.Math.Vector.Normalize(V2)
	
    local relativeBearingPlane1ToPlane2 = Tacview.Math.Vector.AngleBetween(UnitRelPos1, UnitV1) 
    local relativeBearingPlane2ToPlane1 = Tacview.Math.Vector.AngleBetween(UnitRelPos2, UnitV2)

	return relativeBearingPlane1ToPlane2, relativeBearingPlane2ToPlane1

end



----------------------------------------------------------------
-- Initialize this addon
----------------------------------------------------------------

function Initialize()

	-- Declare add-on information

	Tacview.AddOns.Current.SetTitle("Display Values")
	Tacview.AddOns.Current.SetVersion("1.8.7")
	Tacview.AddOns.Current.SetAuthor("BuzyBee")
	Tacview.AddOns.Current.SetNotes("Displays TRT, G, TAS, AOA for each selected object.")

	-- Load user preferences
	-- The variable displayValues already contain the default setting

	displayValues = Tacview.AddOns.Current.Settings.GetBoolean(displayValuesSettingName, displayValues)

	-- Declare menus

	local mainMenuId = Tacview.UI.Menus.AddMenu(nil, "Values Indicator")
	displayValuesMenuId = Tacview.UI.Menus.AddOption(mainMenuId, "Display Values", displayValues, OnMenuEnableAddOn)

	-- Register callbacks

	Tacview.Events.Update.RegisterListener(OnUpdate)
	Tacview.Events.DrawTransparentUI.RegisterListener(OnDrawTransparentUI)
end

Initialize()
