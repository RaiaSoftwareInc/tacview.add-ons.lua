
--[[
	Batch Processing

	Recursively batch process .acmi files from a folder specified by the user.

	Author: BuzyBee
	Last update: 2019-08-01 (Tacview 1.8.0)

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

-- Request Tacview API, lfs

local Tacview = require("Tacview180")
local lfs = require("lfs")

----------------------------------------------------------------
-- Ask the user for the target file name,
-- then export the statistics collected.
----------------------------------------------------------------

function Export(countPerName)

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

	-- Create the csv file

	local file = io.open(fileName, "wb")

	if not file then
		Tacview.UI.MessageBox.Error("Failed to export data.\n\nEnsure there is enough space and that you have permission to save in this location.")
		return
	end

	-- Write csv file header then the statistics collected.

	file:write("ObjectName, Count\n")

	for shortName, count in pairs(countPerName) do

		file:write
		(
			string.format
			(
				"%s,%d\n",
				shortName,
				count

			)
		)
	end

	-- close the file

	file:close()

end

-- declare a global variable, the table where the statistics will be stored

local countPerName

----------------------------------------------------------------
-- Perform actions on each .acmi file to collect statistics
----------------------------------------------------------------

function ProcessFile(filePath)

	-- TODO: check if the file ends in .acmi, and reject otherwise

	-- Purge any telemetry previously loaded in memory

	Tacview.Telemetry.Clear()

	-- Load the file

	local fileLoaded = Tacview.Telemetry.Load(filePath)

	if not fileLoaded then
		Tacview.Log.Error("Failed to load:", filePath)
		return
	end

	Tacview.Log.Info("Processing:", filePath)

	-- Analyze contents and store in table

	local objectCount = Tacview.Telemetry.GetObjectCount()

	for index=0,objectCount-1 do

		local objectHandle = Tacview.Telemetry.GetObjectHandleByIndex( index )

		local objectTags = Tacview.Telemetry.GetCurrentTags(objectHandle)

		if Tacview.Telemetry.AnyGivenTagActive( objectTags , Tacview.Telemetry.Tags.FixedWing | Tacview.Telemetry.Tags.Rotorcraft ) then

			local shortName = Tacview.Telemetry.GetCurrentShortName( objectHandle )

			if countPerName[shortName] then
				countPerName[shortName] = countPerName[shortName] + 1
			else
				countPerName[shortName] = 1
			end
		end
	end

end

---------------------------------------------------------------------------------
-- Recursively locate and process every file in the user's selected chosen folder
---------------------------------------------------------------------------------

function ProcessFolder(folderPath)

	for itemName in lfs.dir(folderPath) do

		if itemName ~= "." and itemName ~= ".." then

			local itemPath = folderPath..itemName

			local attr = lfs.attributes (itemPath)

			if (type(attr) == "table") then

				if attr.mode == "directory" then
					ProcessFolder(itemPath..'\\')
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

	countPerName = {}

	-- request folder name from user

	local folderPath = Tacview.UI.MessageBox.GetFolderName()

	-- Process all files in the folder

	ProcessFolder(folderPath)

	-- Export the statistics

	Export(countPerName)

end

----------------------------------------------------------------
-- Add-on initialization
----------------------------------------------------------------

function Initialize()


	-- Declare add-on information

	Tacview.AddOns.Current.SetTitle("Batch Process")
	Tacview.AddOns.Current.SetVersion("1.0")
	Tacview.AddOns.Current.SetAuthor("BuzyBee")
	Tacview.AddOns.Current.SetNotes("Recursively batch process .acmi files from a folder specified by the user.")

	-- Create a menu item to batch process files

	Tacview.UI.Menus.AddCommand(nil, "Batch Process Files", OnBatchProcess)

end

Initialize()
