--[[
	Custom CSV

	Author: BuzyBee
	Last update: 2025-05-17 (Tacview 1.9.4)

	Feel free to modify and improve this script!
--]]

--[[

	MIT License

	Copyright (c) 2025 Raia Software Inc.

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

local Tacview = require("Tacview194")

-- Set default path when opening file 

local DefaultPath = "";

local filesSuccessfullyLoaded = {}

--local STRING_TYPE = "string"

local fileName

function GetOpenFileNames()

	local openFileNameOptions =
		{
			defaultFileExtension = "csv",
			fileName = Tacview.AddOns.Current.Settings.GetString("CustomCSVDefaultPath", DefaultPath),
			multiSelection = true,

			fileTypeList =									
			{
				{"*.csv", "Comma-separated values file"}
			}
		}

		local fileNames = Tacview.UI.MessageBox.GetOpenFileName(openFileNameOptions)

	if not fileNames then
		return
	end

	Tacview.AddOns.Current.Settings.SetString("CustomCSVDefaultPath", fileNames[1]);

	return fileNames
end

function GetNewObjectID(fileName)

	return 0xACCBD70600000000 + Tacview.String.Crc32(fileName)	

end

-- http://lua-users.org/wiki/LuaCsv

function ParseCSVLine (line,sep) 
	local res = {}
	local pos = 1
	sep = sep or ','
	while true do 
		local c = string.sub(line,pos,pos)
		if (c == "") then break end
		if (c == '"') then
			-- quoted value (ignore separator within)
			local txt = ""
			repeat
				local startp,endp = string.find(line,'^%b""',pos)
				txt = txt..string.sub(line,startp+1,endp-1)
				pos = endp + 1
				c = string.sub(line,pos,pos) 
				if (c == '"') then txt = txt..'"' end 
				-- check first char AFTER quoted string, if it is another
				-- quoted string without separator, then append it
				-- this is the way to "escape" the quote char in a quote. example:
				--   value1,"blub""blip""boing",value3  will result in blub"blip"boing  for the middle
			until (c ~= '"')
			table.insert(res,txt)
			assert(c == sep or c == "")
			pos = pos + 1
		else	
			-- no quotes used, just look for the first separator
			local startp,endp = string.find(line,sep,pos)
			if (startp) then 
				table.insert(res,string.sub(line,pos,startp-1))
				pos = endp + 1
			else
				-- no separator found -> use rest of string and terminate
				table.insert(res,string.sub(line,pos))
				break
			end 
		end
	end
	return res
end

function OnMenuImportCustomCSV(fileNames)

	for _,fileName in pairs(fileNames) do

		Tacview.Log.Info("Loading file ["..fileName.."]")

		local objectId = GetNewObjectID(fileName)

		local objectHandle = Tacview.Telemetry.GetCurrentOrCreateObjectHandle(objectId)

		local typePropertyIndex = Tacview.Telemetry.GetObjectsTextPropertyIndex("Type", true)

		Tacview.Telemetry.SetTextSample(objectHandle, Tacview.Telemetry.BeginningOfTime, typePropertyIndex, "Air+FixedWing")	

		local telemetryLines = {}
		local additionalHeadersInfo = {}
		local columnMap = {}

		local firstLine = true

		for line in io.lines(fileName) do

			if firstLine then

				local headers = ParseCSVLine(line, ",")

				for i, header in ipairs(headers) do
					
					if header == "ISO time" then
						columnMap["ISO time"] = i
					elseif header == "Unix time" then
						columnMap["Unix time"] = i
					elseif header == "Time" then
						columnMap["Time"] = i
					elseif header == "Longitude" then
						columnMap["Longitude"] = i
					elseif header == "Latitude" then
						columnMap["Latitude"] = i
					elseif header == "Altitude" then
						columnMap["Altitude"] = i
					elseif header == "Roll" then
						columnMap["Roll"] = i
					elseif header == "Pitch" then
						columnMap["Pitch"] = i
					elseif header == "Yaw" then
						columnMap["Yaw"] = i
					elseif string.sub(header, 1, 1) == "#" then
						local numericProperty = header:sub(2)

						local propertyIndex = Tacview.Telemetry.GetObjectsNumericPropertyIndex(numericProperty, true)
						
						table.insert(additionalHeadersInfo, {
							columnIndex = i,
							propertyName = numericProperty,
							propertyIndex = propertyIndex,
							propertyType = "NUMERIC"
						})					
					else

						local textProperty = header

						local propertyIndex = Tacview.Telemetry.GetObjectsTextPropertyIndex(textProperty, true)

						table.insert(additionalHeadersInfo, {
							columnIndex = i,
							propertyName = textProperty,
							propertyIndex = propertyIndex,
							propertyType = "TEXT"
						})					
					end
				end
					
				firstLine = false
			else

				telemetryLines[#telemetryLines + 1] = ParseCSVLine(line, ",")
			end
		end

		for _,telemetryLine in ipairs(telemetryLines) do

			local isoTime 	= telemetryLine[columnMap["ISO time"]]
			local unixTime 	= telemetryLine[columnMap["Unix time"]]
			local time 	= telemetryLine[columnMap["Time"]]
			local longitude	= telemetryLine[columnMap["Longitude"]]
			local latitude 	= telemetryLine[columnMap["Latitude"]]
			local altitude 	= telemetryLine[columnMap["Altitude"]]
			local roll 		= telemetryLine[columnMap["Roll"]]
			local pitch 	= telemetryLine[columnMap["Pitch"]]
			local yaw 		= telemetryLine[columnMap["Yaw"]]

			local transform = {}
			
			if longitude and longitude ~= "" then
				transform.longitude = math.rad(longitude)
			end
			if latitude and latitude ~= "" then
				transform.latitude = math.rad(latitude)
			end
			if altitude and altitude ~= "" then
				transform.altitude = altitude
			end
			if roll and roll ~= "" then
				transform.roll = math.rad(roll)
			end
			if pitch and pitch ~= "" then
				transform.pitch = math.rad(pitch)
			end
			if yaw and yaw ~= "" then
				transform.yaw = math.rad(yaw)
			end

			local absoluteTime
			
			if isoTime then
				absoluteTime = Tacview.UI.Format.TextToAbsoluteTime(isoTime)
			elseif unixTime then
				absoluteTime = unixTime
			elseif time then
				if Tacview.UI.Format.TextToAbsoluteTime(time) then
					absoluteTime = Tacview.UI.Format.TextToAbsoluteTime(time)
				else
					absoluteTime = time
				end
			end

			Tacview.Telemetry.SetTransform( objectHandle , absoluteTime, transform )

			for _, additionalHeader in ipairs(additionalHeadersInfo) do
				local propertyIndex = additionalHeader.propertyIndex
				local value = telemetryLine[additionalHeader.columnIndex]
			
				if value and value ~= "" then
					if additionalHeader.propertyType == "TEXT" then
						Tacview.Telemetry.SetTextSample(objectHandle, absoluteTime, propertyIndex, value)
					else
						Tacview.Telemetry.SetNumericSample(objectHandle, absoluteTime, propertyIndex, value)
					end
				end
			end
		end

		filesSuccessfullyLoaded[#filesSuccessfullyLoaded+1] = fileName
	
		::nextFile::	
	end

	if #filesSuccessfullyLoaded > 0 then
		return true		
	else
		return false
	end
end

function OnLoad()

	Load(false)
end

function OnMerge()

	Load(true)
end

function Load(mergeWithExistingData)

	local fileNames = GetOpenFileNames()

	if not fileNames then
		return
	end

	if Tacview.Telemetry.OnLoadStart(mergeWithExistingData) then

		local success = OnMenuImportCustomCSV(fileNames)

		if success then
			Tacview.Telemetry.OnLoadEnd(filesSuccessfullyLoaded[1])
		else
			Tacview.Telemetry.OnLoadEnd()
		end
	end
end

----------------------------------------------------------------
-- Add-on initialization
----------------------------------------------------------------

function Initialize()

	-- Declare add-on information

	Tacview.AddOns.Current.SetTitle("Strict CSV Importer")
	Tacview.AddOns.Current.SetVersion("1.9.5.108")
	Tacview.AddOns.Current.SetAuthor("BuzyBee")
	Tacview.AddOns.Current.SetNotes("Import a strictly formatted custom CSV file")

	-- Create a menu item

	local mainMenuHandle = Tacview.UI.Menus.AddMenu(nil, "Strict CSV Importer")
	Tacview.UI.Menus.AddCommand(mainMenuHandle, "Open...", OnLoad)
	Tacview.UI.Menus.AddCommand(mainMenuHandle, "Merge...", OnMerge)

end

Initialize()