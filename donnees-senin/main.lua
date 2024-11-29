
--[[
	Données SENIN

	Author: BuzyBee
	Last update: 2020-10-08 (Tacview 1.8.5)

	Feel free to modify and improve this script!
--]]

--[[

	MIT License

	Copyright (c) 2020-2024 Raia Software Inc.

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

--[[
	File naming convention: Classe(Trigramme)[Camp]_AAAAMMJJ_Exercice.txt
	Where:
		Name 	= Trigamme
		Color 	= Camp
--]]



require("lua-strict")

-- Request Tacview API

local Tacview = require("Tacview185")

-- Set default path when opening file 

local DefaultPath = "";

local filesSuccessfullyLoaded = {}

local STRING_TYPE = "string"

function GetOpenFileNames()

	local openFileNameOptions =
		{
			defaultFileExtension = "txt",
			fileName = Tacview.AddOns.Current.Settings.GetString("ImporterDonneesSENINDefaultPath", DefaultPath),
			multiSelection = true,

			fileTypeList =									
			{
				{"*.txt", "Text file"}
			}
		}

		local fileNames = Tacview.UI.MessageBox.GetOpenFileName(openFileNameOptions)

	if not fileNames then
		return
	end

	Tacview.AddOns.Current.Settings.SetString("ImporterDonneesSENINDefaultPath", fileNames[1]);

	return fileNames
end

function GetNewObjectID(shortFileName)

	return 0xACCBD70600000000 + Tacview.String.Crc32(shortFileName)	

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

function compare(a,b)

	local aNumber = a[1]
	local bNumber = b[1]

	if aNumber and bNumber then
		return aNumber < bNumber
	end

	if not aNumber and bNumber then
		return false
	end

	if aNumber and not bNumber then
		return true
	end

	return false
end

----------------------------------------------------------------
-- Menu callbacks
----------------------------------------------------------------

function OnMenuImporterDonneesSENIN(fileNames)

	local TextToAbsoluteTime = Tacview.UI.Format.TextToAbsoluteTime
	local NormalizePi = Tacview.Math.Angle.NormalizePi
	local SetTransform = Tacview.Telemetry.SetTransform

	for _,fileName in pairs(fileNames) do

		Tacview.Log.Info("DONNÉES SENIN: Loading file ["..fileName.."]")
		
		local shortFileName = fileName:match(".+[\\/]+(.+)$")

		if not shortFileName then
			Tacview.Log.Error("DONNÉES SENIN: Unable to parse short file name from ["..fileName.."]")
			goto nextFile
		end		

		local objectId = GetNewObjectID(shortFileName)

		if not objectId then
			Tacview.Log.Error("DONNÉES SENIN: Unable to get new object ID for [".. fileName.."]")
			goto nextFile
		end

		local objectHandle

		local objectPropertiesInstantiated

		local parsedLines = {}

		for line in io.lines(fileName) do

			local parsedLine = ParseCSVLine (line,"\t")

			parsedLine[1] = tonumber(parsedLine[1])

			parsedLines[#parsedLines+1] = parsedLine

		end

		table.sort(parsedLines, compare)

		local countValidLines = 0
		local countInvalidLines = 0

		local parsedLineCount = #parsedLines

		for parsedLineIndex=1,parsedLineCount do

			-- Display error message if the line does not start with a number

			if not parsedLines[parsedLineIndex][1] then

				countInvalidLines = countInvalidLines + 1

				local msg = ""

				if countInvalidLines == 5 then

					msg = "Additional errors exist"

				elseif countInvalidLines > 5 then
			
					goto nextLine

				else
								
					msg = "Skipping a line because it does not seem to contain any data: "
					
					for i=2, #parsedLines[parsedLineIndex] do
						local v = parsedLines[parsedLineIndex][i]
						if type(v) == STRING_TYPE then
							msg = msg .. " " .. v:gsub("\xb0","\xC2\xB0")
						else
							msg = msg .. " " .. v
						end
					end
				end

				Tacview.Log.Info("DONNÉES SENIN: "..msg)
				
				goto nextLine
			end
				
			-- Gather position data

			local tableOfPositionData = {}

			for positionData in parsedLines[parsedLineIndex][2]:gmatch("(%d+)") do  
					tableOfPositionData[#tableOfPositionData + 1] = positionData
			end

			local longHours				= tableOfPositionData[1]
			local longMinutes			= tableOfPositionData[2]
			local longDecimalMinutes	= tableOfPositionData[3]
			local latHours				= tableOfPositionData[4]
			local latMinutes			= tableOfPositionData[5]
			local latDecimalMinutes		= tableOfPositionData[6]


			-- Display error message if the position is not well formatted

			if not (tableOfPositionData[1] and tableOfPositionData[2] and tableOfPositionData[3] and tableOfPositionData[4] and tableOfPositionData[5] and tableOfPositionData[6]) then
				
				countInvalidLines = countInvalidLines + 1

				local msg = ""

				if countInvalidLines == 5 then

					msg = "Additional errors exist"

				elseif countInvalidLines > 5 then
			
					goto nextLine

				else

					msg = "Skipping a line because latitude or longitude do not seem to be formatted correctly (should be like 42\xC2\xB007'646 N - 006\xC2\xB032'889 E): "
				
					for k,v in ipairs(parsedLines[parsedLineIndex]) do
						if type(v) == STRING_TYPE then
							msg = msg .. " " .. v:gsub("\xb0","\xC2\xB0")
						else
							msg = msg .. " " .. v
						end
					end
				end
				
				Tacview.Log.Warning("DONNEES SENIN: "..msg)
				
				goto nextLine
			end

			local decimalLatitude 	= tableOfPositionData[1] + (tableOfPositionData[2] + tableOfPositionData[3]/1000)/60
			local decimalLongitude 	= tableOfPositionData[4] + (tableOfPositionData[5] + tableOfPositionData[6]/1000)/60

			local longitude 	= math.rad(decimalLongitude)
			
			local latitude		= math.rad(decimalLatitude)

			-- Gather date and time data

			local tableOfTimeData = {}

			for timeData in parsedLines[parsedLineIndex][3]:gmatch("(%d+)") do  
				tableOfTimeData[#tableOfTimeData + 1] = timeData
			end 
			
			-- Display error message if the date and time is not well formatted
			if not (tableOfTimeData[1] and tableOfTimeData[2] and tableOfTimeData[3] and tableOfTimeData[4] and tableOfTimeData[5] and tableOfTimeData[6]) then

				countInvalidLines = countInvalidLines + 1

				local msg = ""

				if countInvalidLines == 5 then

					msg = "Additional errors exist"

				elseif countInvalidLines > 5 then
			
					goto nextLine

				else

					msg = "Skipping a line because date and time do not seem to be formatted correctly (should be DD/MM/YYYY HH:MM:SS): "
					
					for k,v in ipairs(parsedLines[parsedLineIndex]) do
						if type(v) == STRING_TYPE then
							msg = msg .. " " .. v:gsub("\xb0","\xC2\xB0")
						else
							msg = msg .. " " .. v
						end
					end
				end

				Tacview.Log.Warning("DONNÉES SENIN: "..msg)
				
				goto nextLine
			end

			local day 		= tableOfTimeData[1]
			local month 	= tableOfTimeData[2]
			local year 		= tableOfTimeData[3]
			local hour 		= tableOfTimeData[4]
			local minute 	= tableOfTimeData[5]
			local second 	= tableOfTimeData[6]

			local isoTime = year .. "-" .. month 	.. "-" .. day 		.. "T" .. 
							hour .. ":" .. minute 	.. ":" .. second	.."Z"

			local absoluteTime = TextToAbsoluteTime(isoTime)
			
			countValidLines = countValidLines + 1

			local yaw = parsedLines[parsedLineIndex][4]:match("[%d%.]+\xb0")
			
			if yaw then 
				yaw = yaw:gsub("\xb0","")
				yaw = tonumber(yaw)
				yaw = math.rad(yaw)
				yaw = NormalizePi(yaw)
			end

			if not objectPropertiesInstantiated then
				
				objectHandle = Tacview.Telemetry.GetOrCreateObjectHandle(objectId, absoluteTime)

				if not objectHandle then
					Tacview.Log.Error("DONNÉES SENIN: Unable  to create an object handle")
					goto nextFile
				end

				local namePropertyIndex = Tacview.Telemetry.GetObjectsTextPropertyIndex("Name", true)

				local objectName = shortFileName:match("%(([%a%s]+)%)")

				if objectName then 
					Tacview.Telemetry.SetTextSample(objectHandle, absoluteTime, namePropertyIndex, objectName)
				else
					Tacview.Log.Warning("DONNÉES SENIN: No object name found in file name. Object name should be in parentheses: Classe(Trigramme)[Camp]_AAAAMMJJ_Exercice.txt")
				end

				local typePropertyIndex = Tacview.Telemetry.GetObjectsTextPropertyIndex("Type", true)

				Tacview.Telemetry.SetTextSample(objectHandle, absoluteTime, typePropertyIndex, "Watercraft+Sea")

				local colorPropertyIndex = Tacview.Telemetry.GetObjectsTextPropertyIndex("Color", true)
		
				local objectColor = shortFileName:match("%[(%a+)%]")

				if objectColor then 
					Tacview.Telemetry.SetTextSample(objectHandle, absoluteTime, colorPropertyIndex, objectColor)
				else
					Tacview.Log.Info("DONNÉES SENIN: No color found in file name. Color should be in brackets: Classe(Trigramme)[Camp]_AAAAMMJJ_Exercice.txt")
				end

				local objectTransform 

				if yaw then
					objectTransform = { latitude = latitude, longitude = longitude, altitude = 0, yaw = yaw }
				else
					objectTransform = { latitude = latitude, longitude = longitude, altitude = 0}
				end

				Tacview.Telemetry.SetTransform(objectHandle, absoluteTime, objectTransform)

				objectPropertiesInstantiated = true

				goto nextLine

			end

			local objectTransform = { latitude = latitude, longitude = longitude, altitude = 0, yaw = yaw }

			SetTransform(objectHandle, absoluteTime, objectTransform)

			::nextLine::
		end

		if countValidLines == 0 then
			Tacview.Log.Error("DONNÉES SENIN: Failed to load ["..(fileName).."] - could not find any valid data")
			goto nextFile
		end

		Tacview.Log.Info("DONNÉES SENIN: Successfully loaded file ["..fileName.."]")
		filesSuccessfullyLoaded[#filesSuccessfullyLoaded+1] = fileName
		
		::nextFile::	
	end

	Tacview.UI.Update()

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

	if not fileNames then return end

	if (Tacview.Telemetry.OnLoadStart(mergeWithExistingData)) then

		local success = OnMenuImporterDonneesSENIN(fileNames)

		if (success) then
			Tacview.Telemetry.OnLoadEnd(filesSuccessfullyLoaded[1])
		else
			Tacview.Telemetry.OnLoadEnd();
		end
	end
end

----------------------------------------------------------------
-- Add-on initialization
----------------------------------------------------------------

function Initialize()

	-- Declare add-on information

	Tacview.AddOns.Current.SetTitle("Importer données SENIN")
	Tacview.AddOns.Current.SetVersion("0.9")
	Tacview.AddOns.Current.SetAuthor("BuzyBee")
	Tacview.AddOns.Current.SetNotes("Importer données SENIN")

	-- Create a menu item

	local mainMenuHandle = Tacview.UI.Menus.AddMenu(nil, "Données SENIN")
	Tacview.UI.Menus.AddCommand(mainMenuHandle, "Ouvrir...", OnLoad)
	Tacview.UI.Menus.AddCommand(mainMenuHandle, "Fusionner...", OnMerge)	

end

Initialize()
