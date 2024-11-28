
--[[
	Corner Speed

	Author: BuzyBee
	Last update: 2022-11-24 (Tacview 1.8.8)

	Feel free to modify and improve this script!
--]]

--[[

	MIT License

	Copyright (c) 2022 Raia Software Inc.

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

local Tacview = require("Tacview188")

-- Constants 

local settingName = "addOnActivated"

local PercentageAllowance = 10 -- % 

local BackgroundHeight = 90
local BackgroundWidth = 250

local TextTransform_X = 300 	-- from left
local TextTransform_Y	= 90	-- from top

local BackgroundTransform_X = 275		-- from left
local BackgroundTransform_Y = 18		-- from top

local FontSize = 60

local FontColor = 0xFFA0FF46	-- HUD style green

-- Special control characters to change the chartData color on the fly

local OrangeColor = string.char(2)
local DefaultColor = string.char(6)

--- Menu options

local activateMenuId
local addOnActivated = false

-- Members

local msg = ""

local statisticsRenderStateHandle

----

dofile(Tacview.AddOns.Current.GetPath() .."speed-list.lua")

local speedList = speed_list()

function OnUpdate( dt , absoluteTime )

	if not addOnActivated then 
		return 
	end
	
	local objectHandle = Tacview.Context.GetSelectedObject(0)
	
	if not objectHandle then
		return
	end
	
	local speed

	local iasPropertyIndex = Tacview.Telemetry.GetObjectsTextPropertyIndex("IAS",false)
	
	if iasPropertyIndex == Tacview.Telemetry.InvalidPropertyIndex then
	
		speed = GetCurrentTAS(objectHandle, absoluteTime)
	
	else
			
		local IAS, sampleIsValid = Tacview.Telemetry.GetObjectsNumericPropertyIndex(objectHandle,absoluteTime, iasPropertyIndex)
		
		if sampleIsValid then
			speed = IAS
		end
	end
	
	local speedKTS
	
	if speed and speed > 0 then
		speedKTS = Tacview.Math.Units.MetersPerSecondToKnots(speed)
		msg = math.floor(speedKTS + 0.5) .. " kts"
	else
		msg=""	
	end
	
	local shortName = Tacview.Telemetry.GetCurrentShortName(objectHandle)
	
	local cornerSpeed
	
	for aircraftName,speedListTableEntry in pairs(speedList) do
			if shortName and string.find(shortName, aircraftName,1,true) then
				cornerSpeed = speedListTableEntry
			break
		end
	end
	
	if cornerSpeed and speedKTS and math.abs(cornerSpeed - speedKTS) < cornerSpeed*PercentageAllowance/100 then
		msg = OrangeColor .. msg .. DefaultColor
	end	
end

function GetCurrentTAS(objectHandle, absoluteTime)

	local dt = 1.0	-- Calculate TAS over one second

	if not objectHandle then
		return
	end
	
	local transform1, isTransform1Valid = Tacview.Telemetry.GetTransform(objectHandle, absoluteTime - dt)
	local transform2, isTransform2Valid = Tacview.Telemetry.GetTransform(objectHandle, absoluteTime)

	if isTransform1Valid == true and isTransform2Valid == true then

		local distance = Tacview.Math.Vector.GetDistanceBetweenObjects(transform1, transform2)
		return distance / dt
	end
end

----------------------------------------------------------------
-- Menu callbacks
----------------------------------------------------------------

function OnMenuActivated()

	-- Enable/disable add-on

	addOnActivated = not addOnActivated

	-- Save option value in registry

	Tacview.AddOns.Current.Settings.SetBoolean(settingName, addOnActivated)

	-- Update menu with the new option value

	Tacview.UI.Menus.SetOption(activateMenuId, addOnActivated)

end

local StatisticsRenderState =
{
	color = FontColor,
	blendMode = Tacview.UI.Renderer.BlendMode.Normal,
}

function OnDrawTransparentUI()

	if not addOnActivated then
		return
	end
	
	local renderer = Tacview.UI.Renderer

	-- Compile render state

	if not statisticsRenderStateHandle then

		statisticsRenderStateHandle =renderer.CreateRenderState(StatisticsRenderState)

	end

	local transform =
	{
		x = TextTransform_X, --300,
		y = Tacview.UI.Renderer.GetHeight() - TextTransform_Y,
		scale = FontSize,
	}
	
	if msg ~= "" then
		DisplayBackground()
	end
	
	renderer.Print(transform, statisticsRenderStateHandle, msg)

end

function OnDocumentLoaded()

	statisticsRenderStateHandle = nil
	
	msg = ""

end

function DisplayBackground()



	local backgroundRenderStateHandle

	if not backgroundRenderStateHandle then

		local renderState =
		{
			color = 0xffffffff,	-- black background
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
		x = BackgroundTransform_X, --275,
		y = Tacview.UI.Renderer.GetHeight() - BackgroundTransform_Y, --18,
		scale = 1,
	}

	Tacview.UI.Renderer.DrawUIVertexArray(backgroundTransform, backgroundRenderStateHandle, backgroundVertexArrayHandle)
end


----------------------------------------------------------------
-- Add-on initialization
----------------------------------------------------------------

function Initialize()

	-- Declare add-on information

	Tacview.AddOns.Current.SetTitle("Corner Speed")
	Tacview.AddOns.Current.SetVersion("1.0")
	Tacview.AddOns.Current.SetAuthor("BuzyBee")
	Tacview.AddOns.Current.SetNotes("Display speed, targeting corner speed")

	-- Create a menu item

-- Load user preferences 

	addOnActivated = Tacview.AddOns.Current.Settings.GetBoolean(settingName, addOnActivated)

	-- Declare menus

	local mainMenuHandle = Tacview.UI.Menus.AddMenu(nil, "Corner Speed")

	activateMenuId = Tacview.UI.Menus.AddOption(mainMenuHandle, "Enable", addOnActivated, OnMenuActivated)

	-- Register callbacks

	Tacview.Events.Update.RegisterListener(OnUpdate)
	Tacview.Events.DrawTransparentUI.RegisterListener(OnDrawTransparentUI)

	Tacview.Events.DocumentLoaded.RegisterListener(OnDocumentLoaded)
	--Tacview.Events.DocumentUnload.RegisterListener(OnDocumentLoadedOrUnloaded )


end

Initialize()
