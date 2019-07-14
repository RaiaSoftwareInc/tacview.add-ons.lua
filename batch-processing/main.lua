
--[[
	Batch Processing

	Recursiveley batch process .acmi files from a folder specified by the user.

	Author: BuzyBee
	Last update: 2019-07-03 (Tacview 1.8.0)

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
local lfs = require("lfs")

----------------------------------------------------------------
-- Export the given object in a csv file.
-- The time and position are relative to the object first sample time and position.
-- The roll, pitch and yaw angles will increase or decrease cumulatively with no wrap to 0.
----------------------------------------------------------------

function ExportObject(objectHandle, fileName, frameRate)

	-- Check parameters

	if frameRate <= 0 then
		return
	end

	local dt = 1 / frameRate

	-- Retrieve object first and last sample time

	local firstSampleTime, lastSampleTime = Tacview.Telemetry.GetTransformTimeRange(objectHandle)

--	Tacview.Log.Debug("firstSampleTime:", firstSampleTime, "lastSampleTime:", lastSampleTime, "dt:", dt)

	-- Retrieve object first sample position

	local initialPosition = Tacview.Telemetry.GetTransform(objectHandle, firstSampleTime)
	local u0, v0, altitude0 = initialPosition.u, initialPosition.v, initialPosition.altitude

--	Tacview.Log.Debug("u0: ", u0, "v0:", v0, "altitude0:", altitude0)

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

		local objectTransform = Tacview.Telemetry.GetTransform(objectHandle, currentSampleTime)

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

	-- Retrieve selected object

	local selectedObjectHandle = Tacview.Context.GetSelectedObject(0) or Tacview.Context.GetSelectedObject(1)

	if not selectedObjectHandle then
		Tacview.UI.MessageBox.Info("Please select an object to export.")
		return
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

	ExportObject(selectedObjectHandle, fileName, frameRate)
end





function ProcessFile(filePath)

	Tacview.Log.Info("Processing:", filePath)

end


function ProcessFolder(folderPath)
    
	for itemName in lfs.dir(folderPath) do
        
		if itemName ~= "." and itemName ~= ".." then

            local itemPath = folderPath..itemName

            local attr = lfs.attributes (itemPath)

            if (type(attr) == "table") then

				if attr.mode == "directory" then
					ProcessFolder (itemPath..'\\')
				else
					ProcessFile(itemPath)
				end
			end



        end
    end
end

----------------------------------------------------------------
-- Menu callbacks
----------------------------------------------------------------

function OnBatchProcess()
	
	-- request folder name from user
	-- hard code for now while waiting for new function

	local folderPath = Tacview.UI.MessageBox.GetFolderName() --"C:/Users/oreil/Documents/Batch Processing Test/"

	ProcessFolder(folderPath)






end


----------------------------------------------------------------
-- Add-on initialization
----------------------------------------------------------------

function Initialize()

	-- Declare add-on information

	Tacview.AddOns.Current.SetTitle("Batch Process")
	Tacview.AddOns.Current.SetVersion("1.0")
	Tacview.AddOns.Current.SetAuthor("BuzyBee")
	Tacview.AddOns.Current.SetNotes("Recursiveley batch process .acmi files from a folder specified by the user.")

	-- Create a menu item to batch process files

	Tacview.UI.Menus.AddCommand(nil, "Batch Process Files...", OnBatchProcess)


end

Initialize()
