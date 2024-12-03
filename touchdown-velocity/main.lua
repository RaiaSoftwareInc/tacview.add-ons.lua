
--[[
	Touchdown Velocity
	Displays the touchdown velocity in the 3D view
	
	Author: BuzyBee
	Last update: 2024-10-28 (Tacview 1.9.4)

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

local Tacview = require("Tacview195")

----------------------------------------------------------------
-- Constants
----------------------------------------------------------------

local AddOnEnabledSettingName = "Display Touchdown Velocity"
local MessageDisplayTime = 10 --Seconds for which the message is to be displayed


----------------------------------------------------------------
-- UI commands and options
----------------------------------------------------------------


local addOnEnabledMenuId
local addOnEnabled = false


function OnMenuEnableAddOn()

	-- Enable/disable add-on

	addOnEnabled = not addOnEnabled

	-- Save option value in registry

	Tacview.AddOns.Current.Settings.SetBoolean(AddOnEnabledSettingName, addOnEnabled)

	-- Update menu with the new option value

	Tacview.UI.Menus.SetOption(addOnEnabledMenuId, addOnEnabled)

end

local Margin = 16
local FontSize = 36
local FontColor = 0xFFA0FF46	-- HUD style green

local StatisticsRenderState =
{
	color = FontColor,
	blendMode = Tacview.UI.Renderer.BlendMode.Additive,
}

local statisticsRenderStateHandle
local msg=""

function OnDrawTransparentUI()

	if not addOnEnabled then
		return
	end

	-- Compile render state

	if not statisticsRenderStateHandle then

		statisticsRenderStateHandle = Tacview.UI.Renderer.CreateRenderState(StatisticsRenderState)

	end

	local renderer = Tacview.UI.Renderer

	local transform =
	{
		x = renderer.GetWidth()/3,
		y = renderer.GetHeight() - 50,
		scale = FontSize,
	}

				
	renderer.Print(transform, statisticsRenderStateHandle, msg)

end

----------------------------------------------------------------
-- Main loop
----------------------------------------------------------------

-- Update is called once a frame by Tacview

function OnUpdate(dt, absoluteTime)

	msg = ""

	if not addOnEnabled then
		return
	end
	
	-- Proceed only if one of the objects is a Fixed Wing Aircraft or Rotocraft
	
	local objectHandle = Tacview.Context.GetSelectedObject(0) or Tacview.Context.GetSelectedObject(1)
	
	if not objectHandle then
		return
	end
	
	local objectTags = Tacview.Telemetry.GetCurrentTags(objectHandle)
	
	if not objectTags then
		return
	end
	
	 if not Tacview.Telemetry.AnyGivenTagActive(objectTags, Tacview.Telemetry.Tags.FixedWing|Tacview.Telemetry.Tags.Rotorcraft) then
		return
	end
	
	-- Retrieve OnGround property index & status
	
	local onGroundPropertyIndex = Tacview.Telemetry.GetObjectsNumericPropertyIndex("OnGround", false)
	
	if onGroundPropertyIndex == Tacview.Telemetry.InvalidPropertyIndex then
		return
	end
	
	local latestOnGroundSampleTime=0
	local latestOnGroundVerticalSpeed=0
	
	local startIndex = Tacview.Telemetry.GetNumericSampleIndex(objectHandle, absoluteTime - MessageDisplayTime, onGroundPropertyIndex)
	
	if not startIndex then
		startIndex = Tacview.Telemetry.GetNumericSampleCount(objectHandle, onGroundPropertyIndex)
	end	

	local endIndex = Tacview.Telemetry.GetNumericSampleIndex(objectHandle, absoluteTime, onGroundPropertyIndex)
	
	if not endIndex then
		endIndex = Tacview.Telemetry.GetNumericSampleCount(objectHandle, onGroundPropertyIndex)
	end	
			
	for i=math.max(startIndex-1,0),endIndex do
		
		local onGround, sampleTime = Tacview.Telemetry.GetNumericSampleFromIndex(objectHandle, i, onGroundPropertyIndex)
				
		if not onGround or not sampleTime or sampleTime > absoluteTime then
			goto continue
		end
				
		if onGround == 1 then
		
		
			local previousOnGround, previousSampleTime = Tacview.Telemetry.GetNumericSampleFromIndex(objectHandle, i-1, onGroundPropertyIndex)
			
			if not previousOnGround or not previousSampleTime then
				goto continue
			end
			
			if previousOnGround == 0 then
				latestOnGroundSampleTime = sampleTime
				latestOnGroundVerticalSpeed = GetVerticalSpeed(objectHandle, latestOnGroundSampleTime)
			end
		end
		::continue::
	end
	
	if absoluteTime - latestOnGroundSampleTime <= MessageDisplayTime then
		msg = "Touchdown Velocity: " .. Tacview.UI.Format.VerticalSpeedToText(latestOnGroundVerticalSpeed)
	else
		msg = ""
	end	

end

function GetVerticalSpeed(objectHandle, absoluteTime)

	local dt = 1.0

	local transform = Tacview.Telemetry.GetTransform(objectHandle, absoluteTime)
	
	local previousTransform = Tacview.Telemetry.GetTransform( objectHandle, absoluteTime - dt)
	
	return math.abs(transform.altitude - previousTransform.altitude) / dt
end

----------------------------------------------------------------
-- Initialize this addon
----------------------------------------------------------------

function Initialize()

	-- Declare add-on information

	Tacview.AddOns.Current.SetTitle("Touchdown Velocity")
	Tacview.AddOns.Current.SetVersion("1.9.5.101")
	Tacview.AddOns.Current.SetAuthor("BuzyBee")
	Tacview.AddOns.Current.SetNotes("Displays Touchdown Velocity.")

	-- Load user preferences
	-- The variable addOnEnabled already contain the default setting

	addOnEnabled = Tacview.AddOns.Current.Settings.GetBoolean(AddOnEnabledSettingName, addOnEnabled)

	-- Declare menus

	local mainMenuId = Tacview.UI.Menus.AddMenu(nil, "Touchdown Velocity")
	addOnEnabledMenuId = Tacview.UI.Menus.AddOption(mainMenuId, "Display Touchdown Velocity", addOnEnabled, OnMenuEnableAddOn)

	-- Register callbacks

	Tacview.Events.Update.RegisterListener(OnUpdate)
	Tacview.Events.DrawTransparentUI.RegisterListener(OnDrawTransparentUI)

end

Initialize()
