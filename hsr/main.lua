
-- Exporter for HSIMRACING.COM Fan System
-- Author: Frantz 'Vyrtuoz' RAIA
-- Last update: 2019-07-24 (Tacview 1.8.0)

-- IMPORTANT: This script act both as a tutorial and as a real addon for Tacview.
-- Feel free to modify and improve this script!

--[[

MIT License

Copyright (c) 2019 Raia Software Inc.

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

local Tacview = require("Tacview180")

----------------------------------------------------------------
-- Constants
----------------------------------------------------------------

local kph2mps = 1000.0 / 3600				-- To convert km/h in m/s
local mps2kph = 3600 / 1000.0

local MinFanSpeed = 0.0						-- Min speed value sent the fan
local MaxFanSpeed = 999.0					-- Max speed value send to the fan

local MinVehicleSpeed = 0.0					-- Min vehicle speed (m/s)
local MaxVehicleSpeed = 1000.0 * kph2mps	-- Max vehicle speed (1000 km/h in m/s)

local FanSpeedFactor = (MaxFanSpeed - MinFanSpeed) / (MaxVehicleSpeed - MinVehicleSpeed)

local udpAddress = "127.0.0.1"
local udpPort = 8053

local PacketsPerSecond = 4 					-- Maximum number of packets sent per second

----------------------------------------------------------------
-- Preferences / menus
----------------------------------------------------------------

local FanEnabledSettingName = "FanEnabled"
local fanEnabledMenuId = nil

local fanEnabled = false

----------------------------------------------------------------
-- UDP service
----------------------------------------------------------------

local udpSocket

function InitializeUDP()

	local socket = require("socket")
	udpSocket = assert(socket.udp())

	if fanEnabled and udpSocket then
		Tacview.Log.Info("HSR: Ready to send packets to", udpAddress, udpPort)
	end

end

function SendUDPMessage(message)

	assert(udpSocket:sendto(message, udpAddress, udpPort))

end

----------------------------------------------------------------
-- Retrieve player vehicle
----------------------------------------------------------------

function GetLocalVehicleHandle(absoluteTime)

	local telemetry = Tacview.Telemetry

	-- Use the primary selected object, or the secondary if there is no primary

	local selectedObjectHandle = Tacview.Context.GetSelectedObject(0) or Tacview.Context.GetSelectedObject(1)

	if selectedObjectHandle then
	
		return selectedObjectHandle

	end

	-- If no object is selected, find the most important object which is currently alive

	local importancePropertyIndex = telemetry.GetObjectsNumericPropertyIndex("Importance", false)

	if importancePropertyIndex ~= telemetry.InvalidPropertyIndex then

		local objectCount = telemetry.GetObjectCount()
		local bestImportance = 0.0
		local bestObjectHandle = nil

		for objectIndex = 0, objectCount-1 do

			local objectHandle = telemetry.GetObjectHandleByIndex(objectIndex)

			-- If the object is dead, its importance will not be valid

			local objectImportance, importanceIsValid = telemetry.GetNumericSample(objectHandle, absoluteTime, importancePropertyIndex)

			if importanceIsValid and objectImportance > bestImportance then

				bestImportance = objectImportance
				bestObjectHandle = objectHandle
			end
		end

		if bestObjectHandle then

			return bestObjectHandle

		end
	end

	return nil
end

function GetVehicleSpeed(vehicleHandle , absoluteTime)

	local telemetry = Tacview.Telemetry

	-- Retrieve IAS if available

	local iasPropertyIndex = telemetry.GetObjectsNumericPropertyIndex("IAS", false)

	if iasPropertyIndex ~= Tacview.Telemetry.InvalidPropertyIndex then

		local vehicleIAS, isSampleValid = telemetry.GetNumericSample(vehicleHandle, absoluteTime, iasPropertyIndex)

		if isSampleValid == true then

			return vehicleIAS

		end
	end

	-- If IAS is not available calculate TAS as a failsafe

	local dt = 1.0	-- Calculate TAS over one second

	local position0, isPosition0Valid = telemetry.GetTransform(vehicleHandle, absoluteTime - dt)
	local position1, isPosition1Valid = telemetry.GetTransform(vehicleHandle, absoluteTime)

	if isPosition0Valid == true and isPosition1Valid == true then

		local distance = Tacview.Math.Vector.GetDistance(position0, position1)
		return distance / dt

	end

	-- Not enough data available

	return 0
end

----------------------------------------------------------------
-- Main loop
----------------------------------------------------------------

-- keep track of whether player has changed vehicle

local previousVehicleHandle

local vehicleId = 0 		-- incremented by 1 each time vehicle is changed

-- keep track of how much time has elapsed since last packet sent

local timeElapsed = 0

-- keep track of whether playback is currently paused

local isPaused

-- Update is called once a frame by Tacview

function OnUpdate(dt, absoluteTime)

	-- Keep track of whether playback was paused at LAST update

	local previousIsPaused = isPaused

	-- Determine if playback is currently paused. 

	if Tacview.Context.Playback.IsPlaying()	then	
		isPaused = 0
	else
		isPaused = 1
	end

	-- Keep track of whether playback was just paused at this frame

	local justPaused

	if previousIsPaused == 0 and isPaused == 1 then
		justPaused = true
	end

	-- Keep track of how much time has elapsed since last packet sent

	timeElapsed = timeElapsed + dt

	-- Add-on enabled?

	if not fanEnabled then
		return
	end

	-- Retrieve the handle of the most important object

	local vehicleHandle = GetLocalVehicleHandle(absoluteTime)

	if vehicleHandle ~= previousVehicleHandle then

		if vehicleHandle then
			
			Tacview.Log.Info("HSR: New vehicle detected:", Tacview.Telemetry.GetCurrentShortName(vehicleHandle))
			vehicleId = vehicleId + 1
			previousVehicleHandle = vehicleHandle

		else

			-- If there was previously a vehicle handle and now there isn't, send a message to STOP the fan.

			if previousVehicleHandle then

				StopFan()
				previousVehicleHandle = nil
				return

			end

		end

	end

	-- Retrieve vehicle speed

	local vehicleSpeed

	if vehicleHandle then

		vehicleSpeed = GetVehicleSpeed(vehicleHandle , absoluteTime)

	end

	-- Send wind factor over UDP to Rfun fan system driver

	if vehicleSpeed then

		-- Speed is in m/s so we convert it to an arbitrary 000-999 range for the fan

		local fanSpeed = (vehicleSpeed - MinVehicleSpeed) * FanSpeedFactor + MinFanSpeed

		-- Clamp fan speed

		fanSpeed = math.max(math.min(fanSpeed, MaxFanSpeed), MinFanSpeed)

		-- Alternatively, convert vehicle speed to km/h

		local vehicleSpeedKph = vehicleSpeed * mps2kph

		-- Prepare packet

		local packet = string.format("speed=%i\nisPaused=%i\nvehicleId=%i", 
						math.floor(vehicleSpeedKph + 0.5),
						isPaused,
						vehicleId)

		-- Send a packet if enough time has elapsed since the last packet

		if (timeElapsed > 1 / PacketsPerSecond) or justPaused then

			SendUDPMessage(packet)
			timeElapsed = 0

		end
	end
end

function OnShutdown()

	StopFan()

end

function StopFan()

	SendUDPMessage("STOP")

end

----------------------------------------------------------------
-- Menus
----------------------------------------------------------------

function OnFanEnabledMenuOption()

	-- Change the option

	fanEnabled = not fanEnabled

	if fanEnabled and udpSocket then
		Tacview.Log.Info("HSR: Ready to send packets to", udpAddress, udpPort)
	end

	-- Save it in the registry

	Tacview.AddOns.Current.Settings.SetBoolean(FanEnabledSettingName, fanEnabled)

	-- Update menu

	Tacview.UI.Menus.SetOption(fanEnabledMenuId, fanEnabled)

end

----------------------------------------------------------------
-- Initialize this addon
----------------------------------------------------------------

function Initialize()

	-- Declare addon properties

	local currentAddOn = Tacview.AddOns.Current

	currentAddOn.SetTitle("Rfun Fan System")
	currentAddOn.SetVersion("0.9")
	currentAddOn.SetAuthor("BuzyBee")
	currentAddOn.SetNotes("Exports local aircraft speed to Rfun fan system driver.")

	-- Load preferences
	-- Use current fanEnabled value as the default setting

	fanEnabled = Tacview.AddOns.Current.Settings.GetBoolean(FanEnabledSettingName, fanEnabled)

	-- Declare menus

	local addOnMenuId = Tacview.UI.Menus.AddMenu(nil, "Rfun")
	fanEnabledMenuId = Tacview.UI.Menus.AddOption(addOnMenuId, "Enable Fan Output", fanEnabled, OnFanEnabledMenuOption)

	-- Initialize services

	InitializeUDP()

	-- Register callbacks

	Tacview.Events.Update.RegisterListener(OnUpdate)
	Tacview.Events.Shutdown.RegisterListener(OnShutdown)

end

Initialize()
