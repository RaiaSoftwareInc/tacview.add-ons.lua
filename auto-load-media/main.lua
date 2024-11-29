
--[[
	Auto-Load Media

	Automatically load media files associated with currently selected primary and/or secondary object.

	Author: BuzyBee
	Last update: 2021-06-22 (Tacview 1.8.7)

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

-- Request Tacview API, lfs

local Tacview = require("Tacview187")
local lfs = require("lfs")

local DisabledSettingName = "AutoLoadMediaDisabled"
local PrimaryObjectOnlySettingName = "PrimaryObjectOnly"
local BothSelectedObjectsSettingName = "BothSelectedObjects"

local disabledMenuHandle
local primaryObjectOnlyMenuHandle
local bothSelectedObjectsMenuHandle

local disabled = false
local primaryObjectOnly = false
local bothSelectedObjects = true

local mediaFileTypes = {".avi",".mkv",".mov",".mp3",".mp4",".m4a",".mpg",".ogg",".wav",".wma",".wmv"}

local mediaFileNames = {}

local GetObjectsTextPropertyIndex = Tacview.Telemetry.GetObjectsTextPropertyIndex
local InvalidPropertyIndex = Tacview.Telemetry.InvalidPropertyIndex
local GetSelectedObject = Tacview.Context.GetSelectedObject
local GetTextSample = Tacview.Telemetry.GetTextSample
local GetAbsoluteTime = Tacview.Context.GetAbsoluteTime

local primaryObjectHandle
local secondaryObjectHandle

local function ends_with(str, endings)

	str = string.lower(str)

	for k,ending in pairs(endings) do

		ending = string.lower(ending)

		if str:sub(-#ending) == ending then
			
			return true	

		end
	end

	return false
end

function OnLoad()

	-- Reset tables for new ACMI file

	mediaFileNames = {}

	if disabled then
		return
	end

	-- Obtain a list of media files found in the same directory as the new ACMI file. 

	local path = Tacview.Context.GetDocumentPath()

	if not path then 
		return
	end	

	local directory = Tacview.Path.GetDirectoryName(path)

	local fileNames = Tacview.Directory.GetFiles(directory, true)

	for k,fileName in pairs(fileNames) do

		if ends_with(fileName, mediaFileTypes) then

			table.insert(mediaFileNames, fileName)

			Tacview.Log.Debug("Found a media file in the same folder as this ACMI file: " .. fileName)
		end
	end

	table.sort(mediaFileNames, function(a, b) return a:lower() < b:lower() end)

--	for k,v in pairs(mediaFileNames) do
--		print(v)
--	end
end

function GetInfo(selectedObjectHandle)

	local callSignPropertyIndex = GetObjectsTextPropertyIndex("CallSign", false)
	local pilotPropertyIndex = GetObjectsTextPropertyIndex("Pilot", false)
	local namePropertyIndex = GetObjectsTextPropertyIndex("Name", false)

	local callSign=""
	local pilot=""
	local name=""

	local callSignSampleIsValid
	local pilotSampleIsValid
	local nameSampleIsValid


	if callSignPropertyIndex ~= InvalidPropertyIndex then

		callSign, callSignSampleIsValid = GetTextSample(selectedObjectHandle, GetAbsoluteTime(), callSignPropertyIndex)

		if not callSignSampleIsValid then
		
			callSign = ""

		end
	end

	if pilotPropertyIndex ~= InvalidPropertyIndex then

		pilot, pilotSampleIsValid = GetTextSample(selectedObjectHandle, GetAbsoluteTime(), pilotPropertyIndex)

		if not pilotSampleIsValid then
		
			pilot = ""

		end
	end

	if namePropertyIndex ~= InvalidPropertyIndex then

		name, nameSampleIsValid = GetTextSample(selectedObjectHandle, GetAbsoluteTime(), namePropertyIndex)

		if not nameSampleIsValid then
		
			name = ""

		end
	end

	return string.lower(callSign), string.lower(pilot), string.lower(name)
end

function LoadMedia(handle1 , handle2)

	local mediaPlayerID = 0

	if handle1 then

		local callSign1, pilot1, name1 = GetInfo(handle1)

		if callSign1 ~= "" or pilot1 ~= "" or name1 ~= "" then

			for k,mediaFileName in pairs(mediaFileNames) do

				local mediaFileShortName = Tacview.Path.GetFileName(mediaFileName)

				if 	callSign1 ~= "" and string.find(string.lower(mediaFileShortName),callSign1) or
					pilot1 ~= "" and string.find(string.lower(mediaFileShortName), pilot1) or
					name1 ~= "" and string.find(string.lower(mediaFileShortName), name1) then

					Tacview.Media.Load(mediaPlayerID, mediaFileName)

					Tacview.Log.Info("Loading file name = " .. mediaFileShortName .. " into Media Player " .. mediaPlayerID+1)

					mediaPlayerID = mediaPlayerID + 1

					if mediaPlayerID > 3 then
						break
					end

				end				
			end
		end
	end

	if handle2 then

		mediaPlayerID = 4

		local callSign2, pilot2, name2 = GetInfo(handle2)

		if callSign2 ~= "" or pilot2 ~= "" or name2 ~= "" then

			for k,mediaFileName in pairs(mediaFileNames) do

				local mediaFileShortName = Tacview.Path.GetFileName(mediaFileName)

				if 	callSign2 ~= "" and string.find(string.lower(mediaFileShortName),callSign2) or
					pilot2 ~= "" and string.find(string.lower(mediaFileShortName), pilot2) or
					name2 ~= "" and string.find(string.lower(mediaFileShortName), name2) then

					Tacview.Media.Load(mediaPlayerID, mediaFileName)

					Tacview.Log.Info("Loading file name = " .. mediaFileShortName .. " into Media Player " .. mediaPlayerID+1)

					mediaPlayerID = mediaPlayerID + 1

					if mediaPlayerID > 7 then
						break
					end

				end				
			end
		end
	end
end

function OnDisabled()

	-- Change and save option

	disabled = not disabled

	Tacview.AddOns.Current.Settings.SetBoolean(DisabledSettingName, disabled)

	-- Update menu

	Tacview.UI.Menus.SetOption(disabledMenuHandle, disabled)

	-- Set other options to false if applicable

	if not disabled then
		return
	end

	if primaryObjectOnly then

		primaryObjectOnly = false

		Tacview.AddOns.Current.Settings.SetBoolean(PrimaryObjectOnlySettingName, false)

		Tacview.UI.Menus.SetOption(primaryObjectOnlyMenuHandle, false)

	end

	if bothSelectedObjects then

		bothSelectedObjects = false

		Tacview.AddOns.Current.Settings.SetBoolean(BothSelectedObjectsSettingName, false)

		Tacview.UI.Menus.SetOption(bothSelectedObjectsMenuHandle, false)

	end

end

function OnPrimaryObjectOnly()

	-- Change and save option

	primaryObjectOnly = not primaryObjectOnly

	Tacview.AddOns.Current.Settings.SetBoolean(PrimaryObjectOnlySettingName, primaryObjectOnly)

	-- Update menu

	Tacview.UI.Menus.SetOption(primaryObjectOnlyMenuHandle, primaryObjectOnly)

	-- Set other options to false if applicable

	if not primaryObjectOnly then
		return
	end

	if bothSelectedObjects then

		bothSelectedObjects = false

		Tacview.AddOns.Current.Settings.SetBoolean(BothSelectedObjectsSettingName, false)

		Tacview.UI.Menus.SetOption(bothSelectedObjectsMenuHandle, false)

	end

	if disabled then

		disabled = false

		Tacview.AddOns.Current.Settings.SetBoolean(DisabledSettingName, false)

		Tacview.UI.Menus.SetOption(disabledMenuHandle, false)

	end	

end

function OnBothSelectedObjects()

	-- Change and save option

	bothSelectedObjects = not bothSelectedObjects

	Tacview.AddOns.Current.Settings.SetBoolean(BothSelectedObjectsSettingName, bothSelectedObjects)

	-- Update menu

	Tacview.UI.Menus.SetOption(bothSelectedObjectsMenuHandle, bothSelectedObjects)

	-- Set other options to false if applicable

	if not bothSelectedObjects then
		return
	end

	if disabled then

		disabled = false

		Tacview.AddOns.Current.Settings.SetBoolean(DisabledSettingName, false)

		Tacview.UI.Menus.SetOption(disabledMenuHandle, false)

	end

	if primaryObjectOnly then

		primaryObjectOnly = false

		Tacview.AddOns.Current.Settings.SetBoolean(PrimaryObjectOnlySettingName, false)

		Tacview.UI.Menus.SetOption(primaryObjectOnlyMenuHandle, false)

	end
end

function OnUpdate(dt , absoluteTime )

	if disabled then
		return
	end

	local currentPrimaryObjectHandle = GetSelectedObject(0)
	local currentSecondaryObjectHandle = GetSelectedObject(1)

	if 	primaryObjectOnly and 
		currentPrimaryObjectHandle == primaryObjectHandle then

		return
	end

	if 	bothSelectedObjects and 
		currentPrimaryObjectHandle == primaryObjectHandle and 
		currentSecondaryObjectHandle == secondaryObjectHandle then

		return
	end

	if currentPrimaryObjectHandle ~= primaryObjectHandle then
		Tacview.Media.Unload(0)
		Tacview.Media.Unload(1)
		Tacview.Media.Unload(2)
		Tacview.Media.Unload(3)
	end

	if currentSecondaryObjectHandle ~= secondaryObjectHandle then
		Tacview.Media.Unload(4)
		Tacview.Media.Unload(5)
		Tacview.Media.Unload(6)
		Tacview.Media.Unload(7)
	end

	if 	primaryObjectOnly and 
		currentPrimaryObjectHandle ~= primaryObjectHandle then

		--Tacview.Log.Info("Change of primary object detected")

		if currentPrimaryObjectHandle ~= nil then

			LoadMedia(currentPrimaryObjectHandle)

		end

	elseif 	bothSelectedObjects and 
			(currentPrimaryObjectHandle ~= primaryObjectHandle or currentSecondaryObjectHandle ~= secondaryObjectHandle) then

		--Tacview.Log.Info("Change of primary or secondary object detected")

		if currentPrimaryObjectHandle ~= nil or currentSecondaryObjectHandle ~= nil then

			LoadMedia(currentPrimaryObjectHandle,currentSecondaryObjectHandle)

		end

	end

	primaryObjectHandle = currentPrimaryObjectHandle
	secondaryObjectHandle = currentSecondaryObjectHandle

end

----------------------------------------------------------------
-- Add-on initialization
----------------------------------------------------------------

function Initialize()

	-- Declare add-on information

	Tacview.AddOns.Current.SetTitle("Auto-Load Media")
	Tacview.AddOns.Current.SetVersion("1.8.7")
	Tacview.AddOns.Current.SetAuthor("BuzyBee")
	Tacview.AddOns.Current.SetNotes("Automatically load media files associated with currently selected primary and/or secondary object.")

	-- Load Preferences

	disabled = Tacview.AddOns.Current.Settings.GetBoolean(DisabledSettingName, disabled)
	primaryObjectOnly = Tacview.AddOns.Current.Settings.GetBoolean(PrimaryObjectOnlySettingName, primaryObjectOnly)
	bothSelectedObjects = Tacview.AddOns.Current.Settings.GetBoolean(BothSelectedObjectsSettingName, bothSelectedObjects)

	-- Create menu items

	local mainMenuHandle = Tacview.UI.Menus.AddMenu(nil, "Auto-Load Media")

	disabledMenuHandle = Tacview.UI.Menus.AddExclusiveOption(mainMenuHandle, "Disabled", disabled, OnDisabled)
	primaryObjectOnlyMenuHandle = Tacview.UI.Menus.AddExclusiveOption(mainMenuHandle, "Primary Object Only", primaryObjectOnly, OnPrimaryObjectOnly)
	bothSelectedObjectsMenuHandle = Tacview.UI.Menus.AddExclusiveOption(mainMenuHandle, "Both Selected Objects", bothSelectedObjects, OnBothSelectedObjects)	

	Tacview.Events.DocumentLoaded.RegisterListener(OnLoad)
	Tacview.Events.Update.RegisterListener(OnUpdate)

	OnLoad()

end

Initialize()

