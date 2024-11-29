
-- Virtual Flight Report
-- Author: Erin 'BuzyBee' O'Reilly
-- Last update: 2019-10-07 (Tacview 1.8.0)

-- IMPORTANT: This script act both as a tutorial and as a real addon for Tacview.
-- Feel free to modify and improve this script!

--[[

MIT License

Copyright (c) 2019-2024 Raia Software Inc.

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

declareGlobal("unpack", nil)
declareGlobal("module", nil)

local Tacview = require("Tacview180")

-- How close must the aircraft come to an airport for it to be considered arrival/departure ICAO

local minimumDistance = 50000

----------------------------------------------------------------
-- HTTPPOST  service
----------------------------------------------------------------


function PostData()

	local btnpirep 		= "A"
--	local depicao		= "B"
--  local arricao		= "C"
    local dateFilled	= "B"
--  local flightDate	= "C"
    local route 		= "F"
--  local aircraft 		= "G"
    local fuel 			= "21"
    local miles 		= "22"
    local pax 			= "23"	 
    local dh 			= "K"
    local dm 			= "L"
    local ds 			= "M"
    local ah 			= "N"
    local am 			= "O"
    local as 			= "P"
    local th 			= "Q"
    local tm 			= "R"
    local ts 			= "S"
    local comments 		= "T"
--  local pilot 		= "U"
    local flight_number = "V"

	local selectedObjectHandle = Tacview.Context.GetSelectedObject(0) or Tacview.Context.GetSelectedObject(1)

	if not selectedObjectHandle then
		-- message box - please select an object
		-- LOG no object selected
		return
	end

	-- Find departure and arrival ICAO	
	-- Use the closest airport(s) to the first and last known location(s) of the aircraft 

	local firstSampleTime, lastSampleTime = Tacview.Telemetry.GetTransformTimeRange(selectedObjectHandle)

	local initialPosition = Tacview.Telemetry.GetTransform(selectedObjectHandle, firstSampleTime)

	local finalPosition = Tacview.Telemetry.GetTransform(selectedObjectHandle, lastSampleTime)

	local depicao = ClosestAirport(initialPosition.latitude,initialPosition.longitude)
	local arricao = ClosestAirport(finalPosition.latitude,finalPosition.longitude)

	print("Departure ICAO:" .. depicao)
	print("Arrival ICAO:" .. arricao)

	-- Find date of flight in format YYYY-MM-DD.

	local flightDate = os.date("%Y/%m/%d",math.floor(lastSampleTime))

	print("flightDate: "..flightDate)

	-- Find type of aircraft

	local aircraftNamePropertyIndex = Tacview.Telemetry.GetObjectsTextPropertyIndex("Name", false)

	local aircraftName, isSampleValid

	if aircraftNamePropertyIndex ~= Tacview.Telemetry.InvalidPropertyIndex then

		aircraftName, isSampleValid = Tacview.Telemetry.GetTextSample(selectedObjectHandle, lastSampleTime, aircraftNamePropertyIndex)

		if isSampleValid == false then

			aircraftName = nil
			return

		end

		print("aircraftName:"..aircraftName)

	end

	-- Find pilot (call sign)

	local pilotPropertyIndex = Tacview.Telemetry.GetObjectsTextPropertyIndex("Pilot", false)

	local pilot, isSampleValid

	if pilotPropertyIndex ~= Tacview.Telemetry.InvalidPropertyIndex then

		pilot, isSampleValid = Tacview.Telemetry.GetTextSample(selectedObjectHandle, lastSampleTime, pilotPropertyIndex)

		if isSampleValid == false then

			pilot = nil
			return

		end

		print("pilot:"..pilot)

	end

	



    local http = require"socket.http"
    local ltn12 = require"ltn12"

    local reqbody = "btnpirep="		..btnpirep..
					"&date_filled="	..dateFilled..
					"&date="		..flightDate..
					"&depicao="		..depicao..
					"&arricao="		..arricao..
					"&route="		..route..
					"&aircraft="	..aircraftName..
					"&fuel="		..fuel..
					"&miles="		..miles..
					"&pax="			..pax..
					"&dh="			..dh..
					"&dm="			..dm..
					"&ds="			..ds..
					"&ah="			..ah..
					"&am="			..am..
					"&as="			..as..
					"&th="			..th..
					"&tm="			..tm..
					"&ts="			..ts..
					"&comments="	..comments..
					"&pilot="		..pilot..
					"&flight_number="..flight_number

    local respbody = {} 

    local result, respcode, respheaders, respstatus = http.request {
        method = "POST",
        url = "http://127.0.0.1/virtual-flight-report/index.php",
        source = ltn12.source.string(reqbody),
        headers = 
		{
			["content-length"] = #reqbody,        
			["Content-Type"] =  "application/x-www-form-urlencoded" 
        },
        sink = ltn12.sink.table(respbody)
    }
	respbody = table.concat(respbody)
	print(respbody)

end

function SendVirtualFlightReport()

	local sendVirtualFlightReport = Tacview.UI.MessageBox.Question("Click OK to send a Virtual Flight Report now") 

	if(sendVirtualFlightReport==Tacview.UI.MessageBox.OK) then
		PostData()
	else
		return
	end

end

local addOnPath = Tacview.AddOns.Current.GetPath()
local airportListFilePath = addOnPath .. "data/airport-list.csv"
local airportList = {}

function LoadAirportList()

	-- Opens a file in read mode
	local file = io.open(airportListFilePath,"r")

	-- sets the default input file 
	io.input(file)

	-- read from csv file to create a table of tables representing the airport list
	-- 22,"Winnipeg St Andrews","Winnipeg","Canada","YAV","CYAV",50.056389,-97.0325,760,-6,"A"
	
	-- there must be no commas in any fields because data is parsed per line using comma as delimiter 
	-- This could be improved in a future version

	for line in io.lines(airportListFilePath) do

		-- Remove quotation marks if necessary

		line = line:gsub('"','')

		-- Parse line 

		local id, name, city, country, IATA, ICAO, latitude,longitude, someNum1, someNum2, someCode

		= line:match("%s*(.-),%s*(.-),%s*(.-),%s*(.-),%s*(.-),%s*(.-),%s*(.-),%s*(.-),%s*(.-),%s*(.-),%s*(.-)")
		airportList[#airportList + 1] = { id=id, name=name, city=city, country=country, IATA=IATA, ICAO=ICAO, latitude=latitude,
				longitude = longitude, someNum1=someNum1, someNum2=someNum2, someCode=someCode }

		-- convert latitude and longitude into radians

 		airportList[#airportList].latitude = math.rad(tonumber(latitude))
 		airportList[#airportList].longitude = math.rad(tonumber(longitude))

	end

	-- closes the open file
	io.close(file)

end

function ClosestAirport(referenceLatitude,referenceLongitude) 

	local closestAirportICAO = "NONE"
	local closestAirportDistance = minimumDistance

	for i=1,#airportList do

		local x0 = airportList[i].latitude
		local y0 = airportList[i].longitude
		local x1 = referenceLatitude
		local y1 = referenceLongitude

		local distance = GetSphericalDistance(x0,y0,x1,y1)

		if distance<closestAirportDistance then 
			closestAirportDistance = distance
			closestAirportICAO = airportList[i].ICAO
		end

	end

	return closestAirportICAO

end

-- Calculate distance between two points on earth

function GetSphericalDistance(x0, y0, x1, y1)
		
	-- WGS84 semi-major axis size in meters
	-- https://en.wikipedia.org/wiki/Geodetic_datum

	local WGS84_EARTH_RADIUS = 6378137.0;

	return GetSphericalAngle(x0, y0, x1, y1) * WGS84_EARTH_RADIUS;

end

-- Calculate angle between two points on a sphere.
-- http://williams.best.vwh.net/avform.htm

function GetSphericalAngle(x0, y0, x1, y1)

	local arcX = x1 - x0
	local HX = math.sin(arcX * 0.5)
	HX = HX * HX;

	local arcY = y1 - y0
	local HY = math.sin(arcY * 0.5)
	HY = HY * HY

	local tmp = math.cos(y0) * math.cos(y1);

	return 2.0 * math.asin(math.sqrt(HY + tmp * HX));

end

----------------------------------------------------------------
-- Initialize this addon
----------------------------------------------------------------

function Initialize()

	LoadAirportList()

	-- Declare addon properties

	local currentAddOn = Tacview.AddOns.Current

	currentAddOn.SetTitle("Virtual Flight Report")
	currentAddOn.SetVersion("0.2")
	currentAddOn.SetAuthor("BuzyBee")
	currentAddOn.SetNotes("Send flight report to specific website via HTTP POST.")

	-- Declare menus

	Tacview.UI.Menus.AddCommand( nil , "Virtual Flight Report" , SendVirtualFlightReport )

end

Initialize()
