
-- Terrain Downloader
-- Author: Erin 'BuzyBee' O'Reilly
-- Last update: 2020-11-20 (Tacview 1.8.5)

-- IMPORTANT: This script act both as a tutorial and as a real addon for Tacview.
-- Feel free to modify and improve this script!

--[[

MIT License

Copyright (c) 2020 Raia Software Inc.

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

require("lua-strict")
local lfs = require('lfs')

local Tacview = require("Tacview185")
local http = require("socket.http")

----------------------------------------------------------------
-- Constants
----------------------------------------------------------------

local pixelsHeightBase = 728
local MapQuestMaxPixelsAllowed = 1920

----------------------------------------------------------------
-- Preferences / menus
----------------------------------------------------------------

local ThunderforestAPIKeySettingName = "Thunderforest API Key"
local MapQuestAPIKeySettingName = "MapQuest API Key"

local cacheDisabledSettingName = "Cache Disabled"

local mapQuestOptionMapSettingName = "MapQuest Option Map"
local mapQuestOptionLightSettingName = "MapQuest Option Light"
local mapQuestOptionDarkSettingName = "MapQuest Option Dark"
local mapQuestOptionHybridSettingName = "MapQuest Option Hybrid"

local mapQuestOptionTranslucentSettingName = "MapQuest Translucent"

local ThunderforestAPIKey = ""
local MapQuestAPIKey = ""

local mapQuestOptionMap = false
local mapQuestOptionLight = false
local mapQuestOptionDark = false
local mapQuestOptionHybrid = true -- default

local mapQuestOptionTranslucent = true -- default

local cacheDisabled = true

local disableCacheMenuHandle

local mapQuestOptionMapMenuHandle
local mapQuestOptionLightMenuHandle
local mapQuestOptionDarkMenuHandle
local mapQuestOptionHybridMenuHandle

local deleteAllTilesMenuHandle

local mapQuestOptionTranslucentMenuHandle

local data 

local function collect(chunk)
  if chunk ~= nil then
	data = data .. chunk
	end
  return true
end

function GetCoordinates()

	local topLeftLatitude, topLeftLongitude, bottomRightLatitude, bottomRightLongitude

	local objectCount = Tacview.Telemetry.GetObjectCount()

	if objectCount == 0 then
		Tacview.Log.Info("No objects found - calculating coordinates from camera position")
		topLeftLatitude, topLeftLongitude, bottomRightLatitude, bottomRightLongitude = GetCoordinatesFromCamera()
	else
		Tacview.Log.Info(objectCount.." objects found - calculating coordinates from object position")
		topLeftLatitude, topLeftLongitude, bottomRightLatitude, bottomRightLongitude = GetCoordinatesFromObjects(objectCount)
	end

	return topLeftLatitude, topLeftLongitude, bottomRightLatitude, bottomRightLongitude
end

function GetCoordinatesFromObjects(objectCount)

	local topLeftLatitude, topLeftLongitude, bottomRightLatitude, bottomRightLongitude

	local latitude = {}
	local longitude = {}

	for objectCountIndex=0,objectCount-1 do
		local objectHandle = Tacview.Telemetry.GetObjectHandleByIndex(objectCountIndex)
		local transform = Tacview.Telemetry.GetTransform(objectHandle, Tacview.Context.GetAbsoluteTime())
		latitude[#latitude+1] = math.deg(transform.latitude)
		longitude[#longitude+1] = math.deg(transform.longitude)
	end

	table.sort(latitude)
	table.sort(longitude)

	-- for _,v in ipairs(latitude) do print("Latitude: "..v) end
	-- for _,v in ipairs(longitude) do print("Longitude: "..v) end

	topLeftLatitude = math.ceil(latitude[#latitude]+1)
	bottomRightLatitude = math.floor(latitude[1]-1)

	if(longitude[#longitude]-longitude[1]>180) then 
		topLeftLongitude = math.floor(longitude[#longitude]-1)
		bottomRightLongitude = math.ceil(longitude[1]+1)
	else
		topLeftLongitude = math.floor(longitude[1]-1)
		bottomRightLongitude = math.ceil(longitude[#longitude]+1)
	end		

	Tacview.Log.Info("From object position, calculated square area from top left to bottom right: "
						.. string.format("%d",topLeftLatitude).. "," .. string.format("%d",topLeftLongitude) .. " to "
						.. string.format("%d",bottomRightLatitude) .. ","..string.format("%d",bottomRightLongitude))

	return topLeftLatitude, topLeftLongitude, bottomRightLatitude, bottomRightLongitude
end

function GetCoordinatesFromCamera()

	local longitude, latitude = Tacview.Context.Camera.GetSphericalPosition() 
	
	Tacview.Log.Info("From camera position, calculated center: "..string.format("%0.2f",math.deg(latitude)) .."," .. string.format("%0.2f",math.deg(longitude)))

	local topLeftLatitude = math.ceil(math.deg(latitude)+2)
	local topLeftLongitude = math.floor(math.deg(longitude)-2) 
	local bottomRightLatitude = math.floor(math.deg(latitude)-2)
	local bottomRightLongitude = math.ceil(math.deg(longitude)+2)

	if bottomRightLongitude > 180 then
		bottomRightLongitude = 360 - bottomRightLongitude
	end

	if topLeftLongitude <-180 then
		topLeftLongitude = 360 + topLeftLongitude
	end

	Tacview.Log.Info("From camera position, calculated square area from top left to bottom right: "
						.. string.format("%d",topLeftLatitude).. "," .. string.format("%d",topLeftLongitude) .. " to "
						.. string.format("%d",bottomRightLatitude) .. ","..string.format("%d",bottomRightLongitude))

	return topLeftLatitude, topLeftLongitude, bottomRightLatitude, bottomRightLongitude

end

function GetListOfTiles(topLeftLatitude, topLeftLongitude, bottomRightLatitude, bottomRightLongitude)

	local ListOfTiles = {}

	if bottomRightLongitude - topLeftLongitude < -180 then
		
		local wraparoundLongitude = topLeftLongitude
		
		while wraparoundLongitude < 180 do

			for lat1=bottomRightLatitude,topLeftLatitude - 1 do
				ListOfTiles[#ListOfTiles+1] = {lat1,wraparoundLongitude}
				--print("latitude (lat1) = "..lat1..", longitude = wraparoundLongitude " .. wraparoundLongitude)
			end

			wraparoundLongitude = wraparoundLongitude + 1

		end
		
		wraparoundLongitude = -180
		
		while wraparoundLongitude < bottomRightLongitude do

			for lat2=bottomRightLatitude,topLeftLatitude - 1 do
				ListOfTiles[#ListOfTiles+1] = {lat2,wraparoundLongitude}
				--print("latitude (lat2) = "..lat2..", longitude (wraparoundLongitude) = " .. wraparoundLongitude)
			end

			wraparoundLongitude = wraparoundLongitude + 1

		end
	
	else

		for lat3=bottomRightLatitude,topLeftLatitude - 1 do
			for long = topLeftLongitude,bottomRightLongitude - 1 do
				ListOfTiles[#ListOfTiles+1] = {lat3,long}
				--print("latitude (lat3) = "..lat3..", longitude (long) = " .. long)
			end
		end

		--for index=1,#ListOfTiles do
			--print(ListOfTiles[index][1].." "..ListOfTiles[index][2])
		--end

	end

		return ListOfTiles

end

function trim(s)
   return s:match "^%s*(.-)%s*$"
end

----------------------------------------------------------------
-- Menus
----------------------------------------------------------------

function OnDownloadTopographyTiles()

end

function OnEnterThunderforestAPIKey()

	ThunderforestAPIKey = Tacview.UI.MessageBox.InputText( 
							"Thunderforest API Key", 
							"Please enter your Thunderforest API Key\n\n"..
							"(Get a free API key from https://thunderforest.com/ )" , 
							ThunderforestAPIKey )

	if ThunderforestAPIKey then
		ThunderforestAPIKey = trim(ThunderforestAPIKey)
		Tacview.AddOns.Current.Settings.SetString(ThunderforestAPIKeySettingName , ThunderforestAPIKey)
	end

end

function OnEnterMapQuestAPIKey()

	MapQuestAPIKey = Tacview.UI.MessageBox.InputText( 
							"MapQuest API Key", 
							"Please enter your MapQuest API Key\n\n" ..
							"(Get a free API key from https://developer.mapquest.com/ )",
							MapQuestAPIKey )

	if MapQuestAPIKey then
		MapQuestAPIKey = trim(MapQuestAPIKey)
		Tacview.AddOns.Current.Settings.SetString(MapQuestAPIKeySettingName , MapQuestAPIKey)
	end

end

function OnThunderforest()

	if ThunderforestAPIKey == "" or not ThunderforestAPIKey then
		OnEnterThunderforestAPIKey()
	end

	if ThunderforestAPIKey == "" or not ThunderforestAPIKey then
		Tacview.UI.MessageBox.Error("Can't download any tiles from Thunderforest without an API key.\nGet a free API key from https://thunderforest.com/")
		return
	end	
end

function starts_with(str, start)
   return tostring(str):sub(1, #start) == start
end

function OnMapQuest()

	-- Obtain MapQuest API key if necessary

	if MapQuestAPIKey == "" or not MapQuestAPIKey then
		OnEnterMapQuestAPIKey()
	end

	if MapQuestAPIKey == "" or not MapQuestAPIKey then
		Tacview.UI.MessageBox.Error("Can't download any tiles from MapQuest without an API key.\nGet a free API key from https://developer.mapquest.com/")
		return
	end	

	-- Gather information for downloading tiles

	local topLeftLatitude, topLeftLongitude, bottomRightLatitude, bottomRightLongitude = GetCoordinates()

	local response = Tacview.UI.MessageBox.Question("Ready to download tiles from ["
		..topLeftLatitude..","..topLeftLongitude.."] to ["..bottomRightLatitude..","..bottomRightLongitude.."]?")

	if response == 	Tacview.UI.MessageBox.Cancel then 
		return
	end

	local ListOfTiles = GetListOfTiles(topLeftLatitude, topLeftLongitude, bottomRightLatitude, bottomRightLongitude)
		
	local countOfTilesSuccessfullyDownloaded = 0
	local countOfTilesAlreadyInCache = 0
	local countOfTilesFailedToDownload = 0

	local translucency = ""

	if mapQuestOptionTranslucent then
		translucency = "T"
	end

	-- Proceed tile by tile

	for _,tileCoordinates in pairs(ListOfTiles) do

		-- Get string values for the latitude and longitude

		local latitudeString
		local longitudeString

		if tileCoordinates[1] >= 0 then
			latitudeString = "N"..string.format("%02d",tileCoordinates[1])
		else
			latitudeString = "S"..string.format("%02d",math.abs(tileCoordinates[1]))
		end

		if tileCoordinates[2] >= 0 then
			longitudeString = "E"..string.format("%03d",tileCoordinates[2])
		else
			longitudeString = "W"..string.format("%03d",math.abs(tileCoordinates[2]))
		end

		-- Check for existing tiles with the same latitude and longitude

		local filepath_png = "C:/ProgramData/Tacview/Data/Terrain/Textures/"..latitudeString..longitudeString..".png"
		local filepath_jpg = "C:/ProgramData/Tacview/Data/Terrain/Textures/"..latitudeString..longitudeString..".jpg"
		local filepath_png_t = "C:/ProgramData/Tacview/Data/Terrain/Textures/"..latitudeString..longitudeString.."T"..".png"
		local filepath_jpg_t = "C:/ProgramData/Tacview/Data/Terrain/Textures/"..latitudeString..longitudeString.."T"..".jpg"

		local file_png = io.open(filepath_png, "rb")
		local file_jpg = io.open(filepath_jpg, "rb")
		local file_png_t = io.open(filepath_png_t, "rb")
		local file_jpg_t = io.open(filepath_jpg_t, "rb")

		-- If the cache is not disabled, check if a tile with the same extension (.png or .jpg) and same transparency exists.
		-- If so, skip this tile.

		if not cacheDisabled then
			if mapQuestOptionTranslucent then	-- translucent
				if mapQuestOptionDark or mapQuestOptionLight or mapQuestOptionMap then	-- png
					if file_png_t then
						Tacview.Log.Info("File already exists in the cache for "..latitudeString..longitudeString)
						countOfTilesAlreadyInCache = countOfTilesAlreadyInCache + 1
						goto continue
					end
				else	-- jpg
					if file_jpg_t then
						Tacview.Log.Info("File already exists in the cache for "..latitudeString..longitudeString)
						countOfTilesAlreadyInCache = countOfTilesAlreadyInCache + 1
						goto continue
					end
				end
			else	-- not translucent	
				if mapQuestOptionDark or mapQuestOptionLight or mapQuestOptionMap then	-- png
					if file_png then
						Tacview.Log.Info("File already exists in the cache for "..latitudeString..longitudeString)
						countOfTilesAlreadyInCache = countOfTilesAlreadyInCache + 1
						goto continue
					end
				else	-- jpg
					if file_jpg then
						Tacview.Log.Info("File already exists in the cache for "..latitudeString..longitudeString)
						countOfTilesAlreadyInCache = countOfTilesAlreadyInCache + 1
						goto continue
					end
				end
			end	
		end

		-- Gather information to build url 
	
		--local bbTopLeftLatitude = tileCoordinates[1]+1
		--local bbTopLeftLongitude = tileCoordinates[2]
		--local bbBottomRightLatitude = tileCoordinates[1]
		--local bbBottomRightLongitude = tileCoordinates[2] + 1

		local centerLatitude = tileCoordinates[1]+0.5
		local centerLongitude = tileCoordinates[2]+0.5
		--print(latitudeString..longitudeString)

		local mapType
		local fileType
		local fileExt	

		if mapQuestOptionLight then
			mapType="light"
			fileType = "png"
			fileExt = ".png"
		elseif mapQuestOptionDark then
			mapType = "dark"
			fileType = "png"
			fileExt = ".png"
		elseif mapQuestOptionMap then
			mapType = "map"
			fileType = "png"
			fileExt = ".png"
		else
			mapType = "hyb"
			fileType = "jpg80"
			fileExt = ".jpg"
		end

		local mercatorProjectionScaleFactor = 1/math.cos(math.rad(centerLatitude))

		local heightInPixels = math.min(math.floor(pixelsHeightBase * mercatorProjectionScaleFactor), MapQuestMaxPixelsAllowed)

		if heightInPixels < math.floor(pixelsHeightBase * mercatorProjectionScaleFactor) then
			Tacview.Log.Warning(latitudeString..longitudeString .. " tile exceeds maximum pixels allowed. Clamping to "..MapQuestMaxPixelsAllowed..". You may notice some distortion.") 
		end	

		-- print("Degrees of Latitude: " .. centerLatitude ..", Height in Pixels: ".. heightInPixels)

		local url = "http://mapquestapi.com/staticmap/v5/map?key="..MapQuestAPIKey.."&center="..centerLatitude..","..centerLongitude.."&size=728,"..heightInPixels.."@2x&zoom=10&format="..fileType.."&type="..mapType

		data=""

		-- Attempt an http request

		local ok, statusCode, headers, statusText = http.request {
			url = url,
			method = "GET",
			sink = collect	-- collect to data
		}

		-- Check for errors

		if starts_with(statusCode,"3") or starts_with(statusCode,"4") or starts_with(statusCode,"5") then
			Tacview.Log.Debug(url)
			Tacview.Log.Error(latitudeString..longitudeString .. " square failed to download due to: "..statusText) 
			countOfTilesFailedToDownload = countOfTilesFailedToDownload + 1
			goto continue 
		end

		------------------------------------------------------------------------------------------------------------ 
		--	Now we know that 
		-- 	1. The download is successful 
		-- 	2. Either: 	a) The cache is disabled or 
		--				b) There are no tiles in the cache with the same extension and transparency
		-- 	so we can go ahead and delete any tiles in the cache with the same latitude and longitude
		------------------------------------------------------------------------------------------------------------

		if file_png then 
			file_png:close()
			local ok, err = os.remove(filepath_png) 
			if ok then
				Tacview.Log.Debug("Deleting ".. filepath_png)
			else
				Tacview.Log.Debug("Unable to delete ".. filepath_png.. " due to: "..err)
			end				
		end

		if file_jpg then 
			file_jpg:close()
			local ok, err = os.remove(filepath_jpg) 
			if ok then
				Tacview.Log.Debug("Deleting ".. filepath_jpg)
			else
				Tacview.Log.Debug("Unable to delete ".. filepath_jpg.. " due to: "..err)
			end	
		end

		if file_png_t then 
			file_png_t:close()
			local ok, err = os.remove(filepath_png_t) 
			if ok then
				Tacview.Log.Debug("Deleting ".. filepath_png_t)
			else
				Tacview.Log.Debug("Unable to delete ".. filepath_png_t.. " due to: "..err)
			end	
		end

		if file_jpg_t then 
			file_jpg_t:close()
			local ok, err = os.remove(filepath_jpg_t) 
			if ok then
				Tacview.Log.Debug("Deleting ".. filepath_jpg_t)
			else
				Tacview.Log.Debug("Unable to delete ".. filepath_jpg_t.. " due to: "..err)
			end	
		end

		-- Create the new file 

		local f, err = io.open("C:/ProgramData/Tacview/Data/Terrain/Textures/"..latitudeString..longitudeString..translucency..fileExt, "wb") -- open in "binary" mode

		if f then
			f:write(data)
			f:close() 
			Tacview.Log.Debug(url)
			Tacview.Log.Info(latitudeString..longitudeString.." square was successfully downloaded.") 
			countOfTilesSuccessfullyDownloaded = countOfTilesSuccessfullyDownloaded + 1
		else
			Tacview.Log.Debug("Could not create file "..latitudeString..longitudeString.." - "..err)
			countOfTilesFailedToDownload = countOfTilesFailedToDownload + 1
		end

		::continue::
	end

	local msg = ""

	if countOfTilesSuccessfullyDownloaded > 0 then
		msg = msg .. countOfTilesSuccessfullyDownloaded .. " tiles were successfully downloaded.\n\n"
	end
	if countOfTilesAlreadyInCache > 0 then
		msg = msg..countOfTilesAlreadyInCache.." tiles were already in the cache.\n\n"
	end
	if countOfTilesFailedToDownload > 0 then
		msg = msg ..countOfTilesFailedToDownload .. " tiles failed to download.\n\n"
	end
	
	msg = msg .. "See the log for details.\n\n"
	
	if countOfTilesSuccessfullyDownloaded > 0 then
		msg = msg .. "Please restart Tacview to view the tiles"
	end

	if countOfTilesFailedToDownload > 0 then
		Tacview.UI.MessageBox.Error(msg)
	else
		Tacview.UI.MessageBox.Info(msg)
	end
end

function OnDisableCache()

	-- Enable/disable cache

	cacheDisabled = not cacheDisabled

	-- Save option value in registry

	Tacview.AddOns.Current.Settings.SetBoolean(cacheDisabledSettingName, cacheDisabled)

	-- Update menu with the new option value

	Tacview.UI.Menus.SetOption(disableCacheMenuHandle, cacheDisabled)
end

function OnUpdate()

end


function OnMapQuestOptionMap()

	mapQuestOptionMap = not mapQuestOptionMap
	mapQuestOptionLight = false
	mapQuestOptionDark = false
	mapQuestOptionHybrid = false

	-- Save option value in registry

	Tacview.AddOns.Current.Settings.SetBoolean(mapQuestOptionMapSettingName, mapQuestOptionMap)
	Tacview.AddOns.Current.Settings.SetBoolean(mapQuestOptionLightSettingName, mapQuestOptionLight)
	Tacview.AddOns.Current.Settings.SetBoolean(mapQuestOptionDarkSettingName, mapQuestOptionDark)
	Tacview.AddOns.Current.Settings.SetBoolean(mapQuestOptionHybridSettingName, mapQuestOptionHybrid)

	-- Update menu with the new option value

	Tacview.UI.Menus.SetOption(mapQuestOptionMapMenuHandle, mapQuestOptionMap)
	Tacview.UI.Menus.SetOption(mapQuestOptionLightMenuHandle, mapQuestOptionLight)
	Tacview.UI.Menus.SetOption(mapQuestOptionDarkMenuHandle, mapQuestOptionDark)
	Tacview.UI.Menus.SetOption(mapQuestOptionHybridMenuHandle, mapQuestOptionHybrid)

end

function OnMapQuestOptionLight()

	mapQuestOptionMap = false
	mapQuestOptionLight = not mapQuestOptionLight
	mapQuestOptionDark = false
	mapQuestOptionHybrid = false 

	-- Save option value in registry

	Tacview.AddOns.Current.Settings.SetBoolean(mapQuestOptionMapSettingName, mapQuestOptionMap)
	Tacview.AddOns.Current.Settings.SetBoolean(mapQuestOptionLightSettingName, mapQuestOptionLight)
	Tacview.AddOns.Current.Settings.SetBoolean(mapQuestOptionDarkSettingName, mapQuestOptionDark)
	Tacview.AddOns.Current.Settings.SetBoolean(mapQuestOptionHybridSettingName, mapQuestOptionHybrid)

	-- Update menu with the new option value

	Tacview.UI.Menus.SetOption(mapQuestOptionMapMenuHandle, mapQuestOptionMap)
	Tacview.UI.Menus.SetOption(mapQuestOptionLightMenuHandle, mapQuestOptionLight)
	Tacview.UI.Menus.SetOption(mapQuestOptionDarkMenuHandle, mapQuestOptionDark)
	Tacview.UI.Menus.SetOption(mapQuestOptionHybridMenuHandle, mapQuestOptionHybrid)

end


function OnMapQuestOptionHybrid()

	mapQuestOptionMap = false
	mapQuestOptionLight = false
	mapQuestOptionDark = false
	mapQuestOptionHybrid = not mapQuestOptionHybrid

	-- Save option value in registry

	Tacview.AddOns.Current.Settings.SetBoolean(mapQuestOptionMapSettingName, mapQuestOptionMap)
	Tacview.AddOns.Current.Settings.SetBoolean(mapQuestOptionLightSettingName, mapQuestOptionLight)
	Tacview.AddOns.Current.Settings.SetBoolean(mapQuestOptionDarkSettingName, mapQuestOptionDark)
	Tacview.AddOns.Current.Settings.SetBoolean(mapQuestOptionHybridSettingName, mapQuestOptionHybrid)

	-- Update menu with the new option value

	Tacview.UI.Menus.SetOption(mapQuestOptionMapMenuHandle, mapQuestOptionMap)
	Tacview.UI.Menus.SetOption(mapQuestOptionLightMenuHandle, mapQuestOptionLight)
	Tacview.UI.Menus.SetOption(mapQuestOptionDarkMenuHandle, mapQuestOptionDark)
	Tacview.UI.Menus.SetOption(mapQuestOptionHybridMenuHandle, mapQuestOptionHybrid)

end

function OnMapQuestOptionDark()

	mapQuestOptionMap = false
	mapQuestOptionLight = false
	mapQuestOptionDark = not mapQuestOptionDark
	mapQuestOptionHybrid  = false

	-- Save option value in registry

	Tacview.AddOns.Current.Settings.SetBoolean(mapQuestOptionMapSettingName, mapQuestOptionMap)
	Tacview.AddOns.Current.Settings.SetBoolean(mapQuestOptionLightSettingName, mapQuestOptionLight)
	Tacview.AddOns.Current.Settings.SetBoolean(mapQuestOptionDarkSettingName, mapQuestOptionDark)
	Tacview.AddOns.Current.Settings.SetBoolean(mapQuestOptionHybridSettingName, mapQuestOptionHybrid)

	-- Update menu with the new option value

	Tacview.UI.Menus.SetOption(mapQuestOptionMapMenuHandle, mapQuestOptionMap)
	Tacview.UI.Menus.SetOption(mapQuestOptionLightMenuHandle, mapQuestOptionLight)
	Tacview.UI.Menus.SetOption(mapQuestOptionDarkMenuHandle, mapQuestOptionDark)
	Tacview.UI.Menus.SetOption(mapQuestOptionHybridMenuHandle, mapQuestOptionHybrid)

end

function OnMapQuestOptionTranslucent()

	-- Enable/disable MapQuest Translucent tiles

	mapQuestOptionTranslucent = not mapQuestOptionTranslucent

	-- Save option value in registry

	Tacview.AddOns.Current.Settings.SetBoolean(mapQuestOptionTranslucentSettingName, mapQuestOptionTranslucent)

	-- Update menu with the new option value

	Tacview.UI.Menus.SetOption(mapQuestOptionTranslucentMenuHandle, mapQuestOptionTranslucent)

end

function OnDeleteAllTiles()

	if Tacview.UI.MessageBox.Question("Are your sure you want to delete all terrain texture tiles") == Tacview.UI.MessageBox.OK then

		-- Delete the folder and all its contents
		os.execute('rd /s/q "'.."C:/ProgramData/Tacview/Data/Terrain/Textures/"..'"')
		
		-- Recreate the folder, empty, for future use
		os.execute("mkdir " .. "\"C:/ProgramData/Tacview/Data/Terrain/Textures/\"")

	end
end

----------------------------------------------------------------
-- Initialize this addon
----------------------------------------------------------------

function Initialize()

	-- Declare addon properties

	local currentAddOn = Tacview.AddOns.Current

	currentAddOn.SetTitle("Terrain Downloader")
	currentAddOn.SetVersion("0.1")
	currentAddOn.SetAuthor("BuzyBee")
	currentAddOn.SetNotes("Download cartography and/or topography.")

	-- Load API keys

	ThunderforestAPIKey = currentAddOn.Settings.GetString(ThunderforestAPIKeySettingName, ThunderforestAPIKey)
	ThunderforestAPIKey = trim(ThunderforestAPIKey)
	MapQuestAPIKey = currentAddOn.Settings.GetString(MapQuestAPIKeySettingName, MapQuestAPIKey)
	MapQuestAPIKey = trim(MapQuestAPIKey)

	-- Load user preferences
	
	cacheDisabled = Tacview.AddOns.Current.Settings.GetBoolean(cacheDisabledSettingName, cacheDisabled)

	mapQuestOptionMap = Tacview.AddOns.Current.Settings.GetBoolean(mapQuestOptionMapSettingName, mapQuestOptionMap)
	mapQuestOptionLight = Tacview.AddOns.Current.Settings.GetBoolean(mapQuestOptionLightSettingName, mapQuestOptionLight)
	mapQuestOptionDark = Tacview.AddOns.Current.Settings.GetBoolean(mapQuestOptionDarkSettingName, mapQuestOptionDark)
	mapQuestOptionHybrid = Tacview.AddOns.Current.Settings.GetBoolean(mapQuestOptionHybridSettingName, mapQuestOptionHybrid)

	mapQuestOptionTranslucent = Tacview.AddOns.Current.Settings.GetBoolean(mapQuestOptionTranslucentSettingName, mapQuestOptionTranslucent)

	-- Declare menus

	local mainMenuHandle = Tacview.UI.Menus.AddMenu(nil, "Terrain Downloader")
	local cartographyMenuHandle = Tacview.UI.Menus.AddMenu(mainMenuHandle, "Cartography")
	-- local topographyMenuHandle = Tacview.UI.Menus.AddMenu(mainMenuHandle, "Topography")
	Tacview.UI.Menus.AddSeparator(mainMenuHandle)
	disableCacheMenuHandle = Tacview.UI.Menus.AddOption(mainMenuHandle, "Disable Cache", cacheDisabled, OnDisableCache)
	Tacview.UI.Menus.AddSeparator(mainMenuHandle)
	deleteAllTilesMenuHandle = Tacview.UI.Menus.AddCommand(mainMenuHandle, "Delete All Tiles...", OnDeleteAllTiles)


	--local thunderForestMenuHandle =Tacview.UI.Menus.AddMenu(cartographyMenuHandle, "Thunderforest")
	local mapQuestMenuHandle =Tacview.UI.Menus.AddMenu(cartographyMenuHandle, "MapQuest")

	--Tacview.UI.Menus.AddCommand(thunderForestMenuHandle, "Download Thunderforest Tiles", OnThunderforest)
	--Tacview.UI.Menus.AddSeparator(thunderForestMenuHandle)
	--Tacview.UI.Menus.AddCommand(thunderForestMenuHandle, "Enter Thunderforest API key", OnEnterThunderforestAPIKey)

	Tacview.UI.Menus.AddCommand(mapQuestMenuHandle, "Download MapQuest Tiles...", OnMapQuest)
	
	Tacview.UI.Menus.AddSeparator(mapQuestMenuHandle)

	mapQuestOptionMapMenuHandle = Tacview.UI.Menus.AddExclusiveOption( mapQuestMenuHandle , "Map" , mapQuestOptionMap , OnMapQuestOptionMap )
	mapQuestOptionLightMenuHandle = Tacview.UI.Menus.AddExclusiveOption( mapQuestMenuHandle , "Light" , mapQuestOptionLight , OnMapQuestOptionLight )
	mapQuestOptionDarkMenuHandle = Tacview.UI.Menus.AddExclusiveOption( mapQuestMenuHandle , "Dark" , mapQuestOptionDark , OnMapQuestOptionDark )
	mapQuestOptionHybridMenuHandle = Tacview.UI.Menus.AddExclusiveOption( mapQuestMenuHandle , "Hybrid" , mapQuestOptionHybrid , OnMapQuestOptionHybrid )
	
	Tacview.UI.Menus.AddSeparator(mapQuestMenuHandle)

	mapQuestOptionTranslucentMenuHandle = Tacview.UI.Menus.AddOption(mapQuestMenuHandle, "Translucent", mapQuestOptionTranslucent, OnMapQuestOptionTranslucent)

	Tacview.UI.Menus.AddSeparator(mapQuestMenuHandle)

	Tacview.UI.Menus.AddCommand(mapQuestMenuHandle, "Enter MapQuest API key...", OnEnterMapQuestAPIKey)

	--Tacview.UI.Menus.AddCommand(topographyMenuHandle, "Download Topography Tiles", OnDownloadTopographyTiles)

	-- Register callbacks

	--Tacview.Events.Update.RegisterListener(OnUpdate)

end

Initialize()
