
--[[
	Altitude Corrector
	Correct altitudes where ground objects are floating in the air or objects appear underground.

	Author: BuzyBee
	Last update: 2021-02-16 (Tacview 1.8.6)

	Feel free to modify and improve this script!
--]]

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

require("lua-strict")

----------------------------------------------------------------
-- Request Tacview API
----------------------------------------------------------------

local Tacview = require("Tacview186")

----------------------------------------------------------------
-- Preferences
----------------------------------------------------------------

local autoCorrectAltitudesSettingName = "automaticallyCorrectAltitudes"
local autoCorrectAltitudes = false

----------------------------------------------------------------
-- Constants
----------------------------------------------------------------

local tolerance = 100					-- if the object is within this distance from the ground, its altitude will be corrected.
										-- otherwise it will be assumed that the object is supposed to be in the air
										-- i.e., infantry members traveling by helicopter. 

local helicopterHeightAllowance = 2.6 	-- half the height of a Puma
local infantryHeightAllowance = 1		-- half the height of a human
local parachutistHeightAllowance = 1	
local tankHeightAllowance = 1
local antiAircraftHeightAllowance = 1
local vehicleHeightAllowance = 1
local fixedWingHeightAllowance = 2.6	-- half the height of a Rafale

----------------------------------------------------------------
-- UI commands and options
----------------------------------------------------------------

local autoCorrectAltitudesMenuId

function CorrectAltitudes()

	local newTransform = {}
	local msg =""

	local telemetry = Tacview.Telemetry
	local tags = telemetry.Tags
	local getObjectHandleByIndex = telemetry.GetObjectHandleByIndex
	local getCurrentTags = telemetry.GetCurrentTags
	local anyGivenTagActive = telemetry.AnyGivenTagActive
	local getTransformCount = telemetry.GetTransformCount
	local getTransformFromIndex = telemetry.GetTransformFromIndex
	local getElevation = Tacview.Terrain.GetElevation
	local setTransform = telemetry.SetTransform
	local getCurrentShortName = telemetry.GetCurrentShortName
	local logDebug = Tacview.Log.Debug
	local logInfo = Tacview.Log.Info
	local objectCount = telemetry.GetObjectCount()

	for objectIndex=0,objectCount-1 do

		local logged = false

		local objectHandle = getObjectHandleByIndex(objectIndex)

		local shortName = getCurrentShortName(objectHandle)

		local objectTags = getCurrentTags(objectHandle)

		if anyGivenTagActive(objectTags, tags.Tank|tags.Ground|tags.Infantry|tags.AntiAircraft|tags.Vehicle|tags.Rotorcraft|tags.Parachutist|tags.FixedWing) then

			local transformCount = getTransformCount(objectHandle)
		
			for transformIndex=0, transformCount-1 do

				local objectTransform = getTransformFromIndex(objectHandle, transformIndex)

				local elevation = getElevation(objectTransform.longitude, objectTransform.latitude)

				-- For Tanks, Infantry, AntiAircraft and Vehicle, if they are in the air within tolerance, modify the transform to place the object on the ground.

				if anyGivenTagActive(objectTags, tags.Tank)  then

					if objectTransform.altitude < elevation + tolerance then

						if not logged then
							logInfo("ALTITUDE CORRECTOR: Correcting "..shortName.." altitude")
							logged = true
						end

						newTransform = {altitude = elevation + tankHeightAllowance}

						setTransform(objectHandle, objectTransform.time, newTransform) 
					end

				elseif anyGivenTagActive(objectTags, tags.Infantry) then

					if objectTransform.altitude < elevation + tolerance  then 

						if not logged then
							logInfo("ALTITUDE CORRECTOR: Correcting "..shortName.." altitude")
							logged = true
						end

						newTransform = {altitude = elevation + infantryHeightAllowance}

						setTransform(objectHandle, objectTransform.time, newTransform) 

					end

				elseif anyGivenTagActive(objectTags, tags.Vehicle) then

					if objectTransform.altitude < elevation + tolerance  then 

						if not logged then
							logInfo("ALTITUDE CORRECTOR: Correcting "..shortName.." altitude")
							logged = true
						end

						newTransform = {altitude = elevation + vehicleHeightAllowance}

						setTransform(objectHandle, objectTransform.time, newTransform) 

					end

				elseif anyGivenTagActive(objectTags, tags.AntiAircraft) then

					if objectTransform.altitude < elevation + tolerance  then 

						if not logged then
							logInfo("ALTITUDE CORRECTOR: Correcting "..shortName.." altitude")
							logged = true
						end

						newTransform = {altitude = elevation + antiAircraftHeightAllowance}

						setTransform(objectHandle, objectTransform.time, newTransform) 

					end

				-- For Rotorcraft, FixedWing and Parachutists, ensure that the objects do not appear underground at any time.

				elseif anyGivenTagActive(objectTags, tags.Rotorcraft) then

					if objectTransform.altitude < elevation + helicopterHeightAllowance  then 

						if not logged then
							logInfo("ALTITUDE CORRECTOR: Correcting "..shortName.." altitude")
							logged = true
						end

						newTransform = {altitude = elevation + helicopterHeightAllowance}

						setTransform(objectHandle, objectTransform.time, newTransform) 

					end

				elseif anyGivenTagActive(objectTags, tags.Parachutist) then

					if objectTransform.altitude < elevation + parachutistHeightAllowance then 

						if not logged then
							logInfo("ALTITUDE CORRECTOR: Correcting "..shortName.." altitude")
							logged = true
						end

						newTransform = {altitude = elevation + parachutistHeightAllowance}

						setTransform(objectHandle, objectTransform.time, newTransform) 

					end

				elseif anyGivenTagActive(objectTags, tags.FixedWing) then

					if objectTransform.altitude < elevation + fixedWingHeightAllowance then

						if not logged then
							logInfo("ALTITUDE CORRECTOR: Correcting "..shortName.." altitude")
							logged = true
						end

						newTransform = {altitude = elevation + fixedWingHeightAllowance}

						setTransform(objectHandle, objectTransform.time, newTransform) 

					end
				end
			end		
		end
	end
end

function OnMenuAutoCorrectAltitudes()

	-- Enable/disable add-on

	autoCorrectAltitudes = not autoCorrectAltitudes

	-- Save option value in registry

	Tacview.AddOns.Current.Settings.SetBoolean(autoCorrectAltitudesSettingName, autoCorrectAltitudes)

	-- Update menu with the new option value

	Tacview.UI.Menus.SetOption(autoCorrectAltitudesMenuId, autoCorrectAltitudes)

	-- Correct altitudes if user has requested to do so automatically

	if autoCorrectAltitudes then

		CorrectAltitudes()

	end

end

-- OnDocumetLoaded is called by Tacview when a document is loaded

function OnDocumentLoaded()

	-- Check if the user wants to correct altitudes automatically

	if autoCorrectAltitudes then

		CorrectAltitudes()

	end
end

----------------------------------------------------------------
-- Initialize this addon
----------------------------------------------------------------

function Initialize()

	-- Declare add-on information

	Tacview.AddOns.Current.SetTitle("Altitude Corrector")
	Tacview.AddOns.Current.SetVersion("0.1")
	Tacview.AddOns.Current.SetAuthor("BuzyBee")
	Tacview.AddOns.Current.SetNotes("Correct altitudes where ground objects are floating in the air or objects appear underground.")

	-- Load user preferences 

	autoCorrectAltitudes = Tacview.AddOns.Current.Settings.GetBoolean(autoCorrectAltitudesSettingName, autoCorrectAltitudes)

	-- Declare menus

	local mainMenuHandle = Tacview.UI.Menus.AddMenu(nil, "Correct Altitudes")

	Tacview.UI.Menus.AddCommand(mainMenuHandle, "Correct Altitudes Now", CorrectAltitudes)

	autoCorrectAltitudesMenuId = Tacview.UI.Menus.AddOption(mainMenuHandle, "Automatically Correct Altitudes", autoCorrectAltitudes, OnMenuAutoCorrectAltitudes)

	-- Register callbacks

	Tacview.Events.DocumentLoaded.RegisterListener(OnDocumentLoaded)

end

Initialize()
