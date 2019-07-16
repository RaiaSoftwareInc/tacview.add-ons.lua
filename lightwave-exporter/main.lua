
--[[
	CSV Exporter for LightWave
	Exports the telemetry of the selected object in a csv file to be imported as an animation in LightWave

	Author: BuzyBee
	Last update: 2019-06-04 (Tacview 1.8.0)

	Feel free to modify and improve this script!
--]]

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

require("lua-strict")

-- Request Tacview API

local Tacview = require("Tacview180")

----------------------------------------------------------------
-- Export the given object in a csv file.
-- The time and position are relative to the object first sample time and position.
-- The roll, pitch and yaw angles will increase or decrease cumulatively with no wrap to 0.
----------------------------------------------------------------

local relativeObjectExportEnabledMenuID
local exportRelativeObject = false

function OnMenuEnableRelativeObjectExport()

	-- Change and save option

	exportRelativeObject = not exportRelativeObject

	Tacview.AddOns.Current.Settings.SetBoolean("enableRelativeObjectExport", exportRelativeObject)

	-- Update menu

	Tacview.UI.Menus.SetOption(relativeObjectExportEnabledMenuID, exportRelativeObject)

end

function DoNothing()

end

-- Export first object relative to its own starting position, or export first object relative to second object's starting position.

function ExportObject(objectHandle1, objectHandle2, fileName, frameRate)

	-- Check parameters

	if frameRate <= 0 then
		return
	end

	local dt = 1 / frameRate

	-- Retrieve object first and last sample time

	local initialPosition

	local firstSampleTime, lastSampleTime = Tacview.Telemetry.GetTransformTimeRange(objectHandle1)

	if exportRelativeObject then

		-- Retrieve second object's first sample position
		-- At this point objectHandle2 is NOT nil (this has been validated earlier)

		initialPosition = Tacview.Telemetry.GetTransform(objectHandle2, firstSampleTime)

	else

		--if not exporting a relative object
		-- Retrieve first object's first sample position

		initialPosition = Tacview.Telemetry.GetTransform(objectHandle1, firstSampleTime)

	end

	local u0, v0, altitude0 = initialPosition.u, initialPosition.v, initialPosition.altitude

	-- Create the csv file

	local file = io.open(fileName, "wb")

	if not file then
		Tacview.UI.MessageBox.Error("Failed to export data.\n\nEnsure there is enough space and that you have permission to save in this location.")
		return
	end

	-- Write csv file header

	file:write("Frame Number,Relative Time,X,Y,Z,Heading,Pitch,Roll\n")

	-- Export samples at the given frameRate

	local frameNumber = 0
	local rollWrap = 0
	local pitchWrap = 0
	local headingWrap = 0

	local previousObjectTransform = initialPosition

	for currentSampleTime = firstSampleTime, lastSampleTime, dt do

		-- Current relative time

		local relativeTime = currentSampleTime - firstSampleTime

		-- Retrieve current transform to export

		local objectTransform = Tacview.Telemetry.GetTransform(objectHandle1, currentSampleTime)

		-- Make sure angles are increased cumulatively

		local rollDiff		= objectTransform.roll - previousObjectTransform.roll
		local pitchDiff		= objectTransform.pitch - previousObjectTransform.pitch
		local headingDiff	= objectTransform.heading - previousObjectTransform.heading

		if rollDiff > math.pi then
			rollWrap = rollWrap - 2 * math.pi
		elseif rollDiff < -math.pi then
			rollWrap = rollWrap + 2 * math.pi
		end

		if pitchDiff > math.pi then
			pitchWrap = pitchWrap - 2 * math.pi
		elseif pitchDiff < -math.pi then
			pitchWrap = pitchWrap + 2 * math.pi
		end

		if headingDiff > math.pi then
			headingWrap = headingWrap - 2 * math.pi
		elseif headingDiff < -math.pi then
			headingWrap = headingWrap + 2 * math.pi
		end

		local totalRoll 	= objectTransform.roll + rollWrap
		local totalPitch 	= objectTransform.pitch + pitchWrap
		local totalHeading 	= objectTransform.heading + headingWrap

		-- Lightwave understands picht in the opposite direction of Tacview

		local lightwavePitch

		if totalPitch == 0 then
			lightwavePitch = 0
		else
			lightwavePitch = -totalPitch
		end

		-- Lightwave understands roll in the opposite direction of Tacview so the sign of the roll variable must be reversed

		local lightwaveRoll

		if totalRoll == 0 then
			lightwaveRoll = 0
		else
			lightwaveRoll = -totalRoll
		end

		-- Output data in the csv file

		file:write
		(
			string.format
			(
				"%u,%.02f,%g,%g,%g,%g,%g,%g\n",
				frameNumber,
				relativeTime,
				objectTransform.u - u0,
				objectTransform.altitude - altitude0,
				objectTransform.v - v0,
				math.deg(totalHeading),
				math.deg(lightwavePitch),
				math.deg(lightwaveRoll)
			)
		)

	--[[

		file:write
		(
			string.format("%u,%.02f,%g,%g,%g | roll=%g,%g,%g | totalroll=%g,%g,%g | rollwrap=%g,%g,%g\n",
			frameNumber,relativeTime,objectTransform.u-u0,objectTransform.v-v0,objectTransform.altitude-altitude0,
			math.deg(objectTransform.roll),math.deg(objectTransform.pitch),math.deg(objectTransform.heading),
			math.deg(totalRoll),math.deg(totalPitch),math.deg(totalHeading),
			math.deg(rollWrap), math.deg(pitchWrap),math.deg(headingWrap))
		)

	--]]

		-- Next sample

		frameNumber = frameNumber + 1
		previousObjectTransform = objectTransform
	end

	file:close()

end

----------------------------------------------------------------
-- Ask the user for the target file name,
-- then export selected object position samples.
----------------------------------------------------------------

function Export(frameRate)

	-- Debug log

	Tacview.Log.Debug("Frame Rate of", frameRate, "Hz selected")

	-- Retrieve selected object(s)

	local selectedObjectHandle1
	local selectedObjectHandle2

	if exportRelativeObject then

		selectedObjectHandle1 = Tacview.Context.GetSelectedObject(0)
		selectedObjectHandle2 = Tacview.Context.GetSelectedObject(1)

		if not selectedObjectHandle1 or not selectedObjectHandle2 then

			Tacview.UI.MessageBox.Info("Please select two objects for relative export.")
			return

		end

	else -- if not exportRelativeObject

		selectedObjectHandle1 = Tacview.Context.GetSelectedObject(0) or Tacview.Context.GetSelectedObject(1)

		if not selectedObjectHandle1 then

			Tacview.UI.MessageBox.Info("Please select an object to export.")
			return

		end
	end

	-- Ask the user for the target file name

	local saveFileNameOptions =
	{
		defaultFileExtension = "csv",
		fileTypeList =
		{
			{"*.csv", "Comma-separated values"}
		}
	}

	local fileName = Tacview.UI.MessageBox.GetSaveFileName(saveFileNameOptions)

	if not fileName then
		return
	end

	-- Export the data

	ExportObject(selectedObjectHandle1, selectedObjectHandle2, fileName, frameRate)

end

----------------------------------------------------------------
-- Menu callbacks
----------------------------------------------------------------

function OnExport24()
	Export(24)
end

function OnExport25()
	Export(25)
end

function OnExport2997()
	Export(29.97)
end

function OnExport30()
	Export(30)
end

----------------------------------------------------------------
-- Add-on initialization
----------------------------------------------------------------

function Initialize()

	-- Declare add-on information

	Tacview.AddOns.Current.SetTitle("LightWave Exporter")
	Tacview.AddOns.Current.SetVersion("1.1")
	Tacview.AddOns.Current.SetAuthor("BuzyBee")
	Tacview.AddOns.Current.SetNotes("Exports the telemetry of the selected object in a csv file to be imported as an animation in LightWave.")

	-- Create a menu to export data at different frame rate

	local mainMenuHandle = Tacview.UI.Menus.AddMenu(nil, "LightWave Exporter")

	-- Load preferences
	-- Use current exportRelativeObject value as the default setting

	exportRelativeObject = Tacview.AddOns.Current.Settings.GetBoolean("enableRelativeObjectExport", exportRelativeObject)

	-- Declare menus

	Tacview.UI.Menus.AddCommand(mainMenuHandle, "Export Selected Object @ 24 Hz", OnExport24)
	Tacview.UI.Menus.AddCommand(mainMenuHandle, "Export Selected Object @ 25 Hz", OnExport25)
	Tacview.UI.Menus.AddCommand(mainMenuHandle, "Export Selected Object @ 29.97 Hz", OnExport2997)
	Tacview.UI.Menus.AddCommand(mainMenuHandle, "Export Selected Object @ 30 Hz", OnExport30)

	-- Tacview.UI.Menus.AddSeparator(mainMenuHandle)

	Tacview.UI.Menus.AddCommand(mainMenuHandle, "------------------------------", DoNothing)

	relativeObjectExportEnabledMenuID = Tacview.UI.Menus.AddOption(mainMenuHandle, "Export Relative Object", exportRelativeObject, OnMenuEnableRelativeObjectExport)
end

Initialize()
