
-- Automatic Remote Control Demo
-- Author: Frantz 'Vyrtuoz' RAIA
-- Last update: 2021-05-04 (Tacview 1.8.7)

--[[

MIT License

Copyright (c) 2021 Raia Software Inc.

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

local Tacview = require("Tacview187")

local RemoteControl = Tacview.RemoteControl
local Renderer = Tacview.UI.Renderer
local Telemetry = Tacview.Telemetry
local Log = Tacview.Log
local Units = Tacview.Math.Units

----------------------------------------------------------------
-- Constants
----------------------------------------------------------------

local AutoRollSettingName = "AutoRoll"
local AutoFlapsSettingName = "AutoFlaps"
local AutoLandingGearSettingName = "AutoLandingGear"

local StatusMargin = 16

local FlapsDownSpeed = Units.KnotsToMetersPerSecond(93)
local FlapsUpSpeed = Units.KnotsToMetersPerSecond(103)

local LandingGearDownSpeed = Units.KnotsToMetersPerSecond(87)
local LandingGearUpSpeed = Units.KnotsToMetersPerSecond(97)

----------------------------------------------------------------
-- "Members"
----------------------------------------------------------------

local autoRollEnabled = false
local autoFlapsEnabled = true
local autoLandingGearEnabled = true

local autoRollMenuId = 0
local autoFlapsMenuId = 0
local autoLandingGearMenuId = 0

local remoteControlHandle = 0
local renderStateHandle = nil

----------------------------------------------------------------
-- Main loop
----------------------------------------------------------------

-- Update is called once a frame by Tacview

function OnUpdate(dt, absoluteTime)

	local remoteControlStatus = RemoteControl.GetStatus(remoteControlHandle)

	if remoteControlStatus ~= RemoteControl.Status.Connected then
		return
	end

	if autoRollEnabled then
		RemoteControlRoll()
	end

	if autoFlapsEnabled then
		RemoteControlFlaps(absoluteTime)
	end

	if autoLandingGearEnabled then
		RemoteControlLandingGear(absoluteTime)
	end

end

----------------------------------------------------------------
-- Automatic roll
----------------------------------------------------------------

function RemoteControlRoll()

	-- Check parameters

	local objectHandle = Tacview.Context.GetSelectedObject(0)

	if not objectHandle then
		return
	end

	-- Retrieve aircraft roll

	local objectTransform, objectTransformIsValid = Telemetry.GetCurrentTransform( objectHandle )
	
	if not objectTransformIsValid then
		return
	end

	if not objectTransform.rotationIsValid then
		return
	end

	local roll = objectTransform.roll

	-- Apply correction

	local stickPosition = roll / -math.pi / 2

	if math.abs(stickPosition) > 0.001 then

		RemoteControl.SendCommand(remoteControlHandle, "Axis.Roll.Value", stickPosition)
		Log.Info("Roll Stick Position", stickPosition);

	end
end

----------------------------------------------------------------
-- Automatic flaps
----------------------------------------------------------------

function RemoteControlFlaps(absoluteTime)

	-- Check parameters

	local objectHandle = Tacview.Context.GetSelectedObject(0)

	if not objectHandle then
		return
	end

	-- Landing gear current status

	local flapsPropertyIndex = Telemetry.GetObjectsNumericPropertyIndex("Flaps", false) 

	if flapsPropertyIndex == Telemetry.InvalidPropertyIndex then
		return
	end

	local flapsPosition, flapsPositionIsValid = Telemetry.GetNumericSample(objectHandle, absoluteTime, flapsPropertyIndex)

	if not flapsPositionIsValid then
		return
	end

	-- Retrieve IAS (if available)

	local iasPropertyIndex = Telemetry.GetObjectsNumericPropertyIndex("IAS", false) 

	if iasPropertyIndex == Telemetry.InvalidPropertyIndex then
		return
	end

	local ias, iasIsValid = Telemetry.GetNumericSample(objectHandle, absoluteTime, iasPropertyIndex)

	if not iasIsValid then
		return
	end

	-- Auto gear out

	if flapsPosition <= 0 and ias < FlapsDownSpeed then

		RemoteControl.SendCommand(remoteControlHandle, "FlightControl.Flaps.Down")
		Log.Info("Flaps Down");

	end

	-- Auto gear in

	if flapsPosition >= 1 and ias > FlapsUpSpeed then

		RemoteControl.SendCommand(remoteControlHandle, "FlightControl.Flaps.Up")
		Log.Info("Flaps Up");

	end
end

----------------------------------------------------------------
-- Automatic landing gear
----------------------------------------------------------------

function RemoteControlLandingGear(absoluteTime)

	-- Check parameters

	local objectHandle = Tacview.Context.GetSelectedObject(0)

	if not objectHandle then
		return
	end

	-- Landing gear current status

	local landingGearPropertyIndex = Telemetry.GetObjectsNumericPropertyIndex("LandingGear", false) 

	if landingGearPropertyIndex == Telemetry.InvalidPropertyIndex then
		return
	end

	local landingGearPosition, landingGearPositionIsValid = Telemetry.GetNumericSample(objectHandle, absoluteTime, landingGearPropertyIndex)

	if not landingGearPositionIsValid then
		return
	end

	-- Retrieve IAS (if available)

	local iasPropertyIndex = Telemetry.GetObjectsNumericPropertyIndex("IAS", false) 

	if iasPropertyIndex == Telemetry.InvalidPropertyIndex then
		return
	end

	local ias, iasIsValid = Telemetry.GetNumericSample(objectHandle, absoluteTime, iasPropertyIndex)

	if not iasIsValid then
		return
	end

	-- Auto gear out

	if landingGearPosition <= 0 and ias < LandingGearDownSpeed then

		RemoteControl.SendCommand(remoteControlHandle, "System.LandingGear.Down")
		Log.Info("Gear Down");

	end

	-- Auto gear in

	if landingGearPosition >= 1 and ias > LandingGearUpSpeed then

		RemoteControl.SendCommand(remoteControlHandle, "System.LandingGear.Up")
		Log.Info("Gear Up");

	end
end

----------------------------------------------------------------
-- Display status
----------------------------------------------------------------

function OnDrawTransparentUI()

	-- Check status

	local statusText = "Remote Control: "

	local remoteControlStatus = RemoteControl.GetStatus(remoteControlHandle)

	if remoteControlStatus == RemoteControl.Status.NotStarted or remoteControlStatus == RemoteControl.Status.DisconnectedByRemotePeer or remoteControlStatus == RemoteControl.Status.CanceledByLocalPeer then

		statusText = statusText.."not connected"

	elseif remoteControlStatus == RemoteControl.Status.Connecting then

		statusText = statusText.."connecting..."

	elseif remoteControlStatus == RemoteControl.Status.Connected then

		statusText = statusText.."connected to "..RemoteControl.GetPeerName(remoteControlHandle)

	elseif remoteControlStatus == RemoteControl.Status.UnsupportedProtocol then

		statusText = statusText.."unsupported protocol"

	elseif remoteControlStatus == RemoteControl.Status.WrongPassword then

		statusText = statusText.."wrong password"
		
	elseif remoteControlStatus == RemoteControl.Status.ConnectionFailed then

		statusText = statusText.."connection failed"
		
	end

	-- Display status

	local transform =
	{
		x = StatusMargin,
		y = Renderer.GetHeight() - StatusMargin - 200,
	}

	if renderStateHandle == nil then

		local renderState =
		{
			color = 0xff2020ff,
			blendMode =	Renderer.BlendMode.Normal,
		}

		renderStateHandle = Renderer.CreateRenderState( renderState )

	end

	Renderer.Print(transform, renderStateHandle, statusText)

end

----------------------------------------------------------------
-- Connnect/Disconnect
----------------------------------------------------------------

function OnConnect()

	RemoteControl.Connect(remoteControlHandle, "127.0.0.1", 42675, "", "Remote control tutorial");

end

function OnDisconnect()

	RemoteControl.Disconnect(remoteControlHandle);

end

----------------------------------------------------------------
-- Settings change
----------------------------------------------------------------

function OnAutoRoll()

	-- Enable/disable add-on

	autoRollEnabled = not autoRollEnabled

	-- Save option value in registry

	Tacview.AddOns.Current.Settings.SetBoolean(AutoRollSettingName, autoRollEnabled)

	-- Update menu with the new option value

	Tacview.UI.Menus.SetOption(autoRollMenuId, autoRollEnabled)

end

function OnAutoFlaps()

	-- Enable/disable add-on

	autoFlapsEnabled = not autoFlapsEnabled

	-- Save option value in registry

	Tacview.AddOns.Current.Settings.SetBoolean(AutoFlapsSettingName, autoFlapsEnabled)

	-- Update menu with the new option value

	Tacview.UI.Menus.SetOption(autoFlapsMenuId, autoFlapsEnabled)

end

function OnAutoLandingGear()

	-- Enable/disable add-on

	autoLandingGearEnabled = not autoLandingGearEnabled

	-- Save option value in registry

	Tacview.AddOns.Current.Settings.SetBoolean(AutoLandingGearSettingName, autoLandingGearEnabled)

	-- Update menu with the new option value

	Tacview.UI.Menus.SetOption(autoLandingGearMenuId, autoLandingGearEnabled)

end

----------------------------------------------------------------
-- Initialize this addon
----------------------------------------------------------------

function Initialize()

	-- Declare addon properties

	local currentAddOn = Tacview.AddOns.Current

	currentAddOn.SetTitle("Auto Remote Control Demo")
	currentAddOn.SetVersion("1.8.7")
	currentAddOn.SetAuthor("Vyrtuoz")
	currentAddOn.SetNotes("Shows how to remotely control a simulator via the dedicated API.")

	-- Register callbacks

	Tacview.Events.Update.RegisterListener(OnUpdate)
	Tacview.Events.DrawTransparentUI.RegisterListener(OnDrawTransparentUI)

	-- Load user preferences 

	autoRollEnabled = Tacview.AddOns.Current.Settings.GetBoolean(AutoRollSettingName, autoRollEnabled)
	autoFlapsEnabled = Tacview.AddOns.Current.Settings.GetBoolean(AutoFlapsSettingName, autoFlapsEnabled)
	autoLandingGearEnabled = Tacview.AddOns.Current.Settings.GetBoolean(AutoLandingGearSettingName, autoLandingGearEnabled)

	-- Declare menus

	local addOnMenuId = Tacview.UI.Menus.AddMenu(nil, "Auto Remote Control")

	Tacview.UI.Menus.AddCommand(addOnMenuId, "Connect", OnConnect)
	Tacview.UI.Menus.AddCommand(addOnMenuId, "Disconnect", OnDisconnect)
	Tacview.UI.Menus.AddSeparator(addOnMenuId)
	autoRollMenuId = Tacview.UI.Menus.AddOption(addOnMenuId, "Auto Roll", autoRollEnabled, OnAutoRoll)
	Tacview.UI.Menus.AddSeparator(addOnMenuId)
	autoFlapsMenuId = Tacview.UI.Menus.AddOption(addOnMenuId, "Auto Flaps", autoFlapsEnabled, OnAutoFlaps)
	autoLandingGearMenuId = Tacview.UI.Menus.AddOption(addOnMenuId, "Auto Langing Gear", autoLandingGearEnabled, OnAutoLandingGear)

	-- Create remote control

	remoteControlHandle = RemoteControl.Create()

end

Initialize()
