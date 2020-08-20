
-- Fuel Consumption Report
-- Author: Erin 'BuzyBee' O'REILLY
-- Last update: 2019-10-10 (Tacview 1.8.0)

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

require("lua-strict")

local Tacview = require("Tacview180")

local fuelReportEnabled = false

-- Special control characters to change the chartData color on the fly

local OrangeColor = string.char(2)
local DefaultColor = string.char(6)
local GreenColor = string.char(1)

-- text options

local Margin = 16
local FontSize = 16
local FontColor = 0xffffffff		

-- chart options

local AltitudeMax = 6000	
local AltitudeStep=500		-- AltitudeMax should be a multiple of AltitudeStep
local yEntries = 12

local ThrottleMax=1.2
local ThrottleStep=0.1	-- ThrottleMax should be a multiple of ThrottleStep
local xEntries = 12

--constants

local m2ft = 3.28084
local m2km = 1/1000
local s2h = 1/3600
local kgph2gps = 1000/3600 	-- kilograms per hour to grams per second (1 kg / h = 1000 g / 3600 s)

-- What minimum speed in mps

local minGroundSpeed = 28	-- 100kph = 28mps

-- the calculation of the following 2 constants is based on the way the chart is drawn 
-- The chart has yEntries lines and xEntries columns plus axes and legends

local BackgroundHeight = (yEntries + 7)*FontSize
local BackgroundWidth = (xEntries + 3) * 6 * FontSize/2

-- percentiles above and below which values will be flagged red and green respectively

local FlagHighPercentile = 80
local FlagLowPercentile = 20

local updatePeriod = 10		-- how many seconds of data to calculate at one time
local samplePeriod = 1		-- how many seconds over which to calculate fuel consumption
local minDistance = 1		-- minimum distance in meters over which to calculate fuel consumption

-- keep track of existing object

local previousSelectedObjectHandle

-- Cumulative Statistic

local chartEntriesSum = {}
local chartEntriesCount = {}
local chart = {}
local lastStatTime = 0.0

function InitializeCharts()

	for y=0,yEntries-1 do
			
		chart[y]={}
		chartEntriesSum[y]={}
		chartEntriesCount[y]={}
			
		for x=0,xEntries-1 do
			chart[y][x]=0
			chartEntriesSum[y][x]=0
			chartEntriesCount[y][x]=0
		end
	end
end

-- Update is called once a frame by Tacview

function OnUpdate(dt, absoluteTime)

	-- find selected object and determine if it has changed in this update

	local selectedObjectHandle = Tacview.Context.GetSelectedObject(0) or Tacview.Context.GetSelectedObject(1)

	if not selectedObjectHandle then
		return
	end

	local firstSampleTime, lastSampleTime= Tacview.Telemetry.GetTransformTimeRange(selectedObjectHandle)

	-- Object changed?

	if selectedObjectHandle and selectedObjectHandle ~= previousSelectedObjectHandle then
		
		InitializeCharts()
		lastStatTime=firstSampleTime
	
		-- keep track of selected object

		previousSelectedObjectHandle = selectedObjectHandle

	end

	-- Update stats if enough new data is available 
	
	if lastStatTime+updatePeriod <= lastSampleTime then
		calculateChart(selectedObjectHandle, lastStatTime,lastStatTime+updatePeriod)
		lastStatTime = lastStatTime + updatePeriod
	end
end

local flagLowValue = 0
local flagHighValue = 100

function clamp(x,min,max)

	return math.max(math.min(x,max),min)

end



function calculateChart(selectedObjectHandle, startTime, endTime)

	local values = ObtainData(startTime,endTime,selectedObjectHandle)

	-- sort through values 

	for i=1,#values do

		local throttle	=values[i].throttle
		local altitude = values[i].altitude
		local fuelFlowWeight = values[i].fuelFlowWeight
		local groundSpeed = values[i].groundSpeed
		local fuelConsumption	

		if groundSpeed > minGroundSpeed then
			
			fuelConsumption = fuelFlowWeight * kgph2gps/groundSpeed	-- fuel flow weight is in kg/h and ground speed is in m/s
																	-- after conversion, fuel consumption is in g/m.

			local x = math.floor(throttle/ThrottleStep)

			if throttle > 0 and throttle/ThrottleStep - math.floor(throttle/ThrottleStep) == 0 then
				x = x-1
				x = clamp(x,0,xEntries-1)
			end
				
			local y = math.floor(altitude/AltitudeStep)

			if altitude > 0 and altitude/AltitudeStep - math.floor(altitude/AltitudeStep) == 0 then
				y = y-1
				y = clamp(y,0,yEntries-1)
			end

			chartEntriesSum[y][x] = chartEntriesSum[y][x] + fuelConsumption
			chartEntriesCount[y][x] = chartEntriesCount[y][x] + 1

		end
	end

	for y=0,yEntries-1 do

		for x=0,xEntries-1 do

			if chartEntriesCount[y][x]>0 then
				chart[y][x] = chartEntriesSum[y][x]/chartEntriesCount[y][x]
			else
				chart[y][x] = '-'
			end
		end
	end

	-- determine percentiles fuel consumption so that above-average entries may be flagged

	local list = {}

	for y=0,yEntries-1 do

		for x=0,xEntries-1 do
			
			if chart[y][x] ~= '-' then
				list[#list+1] = chart[y][x]
			end
		end
	end

	table.sort(list)

	flagLowValue = list[math.ceil(#list * FlagLowPercentile/100)]
	flagHighValue = list[math.ceil(#list * FlagHighPercentile/100)]

end

function ObtainData(startTime,endTime, selectedObjectHandle)

	local values = {}

	local fuelFlowWeightPropertyIndex = Tacview.Telemetry.GetObjectsNumericPropertyIndex("FuelFlowWeight", false)
	local throttlePropertyIndex = Tacview.Telemetry.GetObjectsNumericPropertyIndex("Throttle", false)

	if fuelFlowWeightPropertyIndex == Tacview.Telemetry.InvalidPropertyIndex then
		return values
	end

	if throttlePropertyIndex == Tacview.Telemetry.InvalidPropertyIndex then
		return values
	end

	-- iterate through the times at the chosen samplePeriod rate

	for i = startTime,endTime,samplePeriod do

		-- find distance and speed between the current and previous position of the object:getSampleRate()

		local currentPosition = Tacview.Telemetry.GetTransform(selectedObjectHandle,i)
		local lastPosition = Tacview.Telemetry.GetTransform(selectedObjectHandle, i-samplePeriod)

		local x0 = lastPosition.latitude
		local y0 = lastPosition.longitude
		local x1 = currentPosition.latitude
		local y1 = currentPosition.longitude
		
		local speedMpS = GetSphericalDistance(x0,y0,x1,y1)/samplePeriod

		-- find other necessary info 

		local fuelFlowWeight, isSampleValid = Tacview.Telemetry.GetNumericSample(selectedObjectHandle, i, fuelFlowWeightPropertyIndex)

		if not isSampleValid then
			break
		end

		local throttle, isSampleValid = Tacview.Telemetry.GetNumericSample(selectedObjectHandle, i, throttlePropertyIndex)

		if not isSampleValid then
			break
		end

		-- keep track of info in a table

		values[#values + 1] = { altitude=currentPosition.altitude, fuelFlowWeight = fuelFlowWeight, throttle = throttle, groundSpeed = speedMpS }

	end

	return values

end

function DisplayBackground()

	local backgroundRenderStateHandle

	if not backgroundRenderStateHandle then

		local renderState =
		{
			color = 0x80000000,
		}

		backgroundRenderStateHandle = Tacview.UI.Renderer.CreateRenderState(renderState)

	end

	local backgroundVertexArrayHandle

	if not backgroundVertexArrayHandle then

		local vertexArray =
		{
			0,0,0,
			0,-BackgroundHeight,0,
			BackgroundWidth,-BackgroundHeight,0,
			0,0,0,
			BackgroundWidth,0,0,
			BackgroundWidth,-BackgroundHeight,0,
			0,0,0,

		}

		backgroundVertexArrayHandle = Tacview.UI.Renderer.CreateVertexArray(vertexArray)

	end


	local backgroundTransform =
	{
		x = Margin,
		y = Tacview.UI.Renderer.GetHeight() / 2 + FontSize * 2,
		scale = 1,
	}

	Tacview.UI.Renderer.DrawUIVertexArray(backgroundTransform, backgroundRenderStateHandle, backgroundVertexArrayHandle)

end


function DisplayChartData()

	-- select chart options

	local ChartDataRenderState =
	{
		color = FontColor,
		blendMode = Tacview.UI.Renderer.BlendMode.Additive,
	}

	local chartDataRenderStateHandle

	if not chartDataRenderStateHandle then

		chartDataRenderStateHandle = Tacview.UI.Renderer.CreateRenderState(ChartDataRenderState)

	end

	local chartDataTransform =
	{
		x = Margin,
		y = Tacview.UI.Renderer.GetHeight() / 2,
		scale = FontSize,
	}

	-- draw chart

	local chartData = " ALTITUDE(M)               FUEL CONSUMPTION G / M\n"

	for y=yEntries-1,0,-1 do

		if((y+1)*AltitudeStep>=1000) then
			chartData = chartData .. "\n  " .. (y+1)*AltitudeStep .."|"
		else
			chartData = chartData .. "\n   " .. (y+1)*AltitudeStep .."|"
		end
	
		for x = 0,xEntries-1 do

			if chart[y][x]=='-' or chart[y][x]==0 then
				chartData = chartData .. "  -   |" 
			elseif chart[y][x]<10 then
				if chart[y][x]>=flagHighValue then
					chartData = chartData .. " "..OrangeColor..string.format("%.2f", tostring(chart[y][x])) ..DefaultColor.." |"
				elseif chart[y][x]<=flagLowValue then
					chartData = chartData .. " "..GreenColor..string.format("%.2f", tostring(chart[y][x])) ..DefaultColor.." |"
				else
					chartData = chartData .. " "..string.format("%.2f", tostring(chart[y][x])) .." |"
				end
			else
				if chart[y][x]>=flagHighValue then
					chartData = chartData .. OrangeColor .. string.format("%.2f", tostring(chart[y][x])) .. DefaultColor.." |"
				elseif chart[y][x]<=flagLowValue then
					chartData = chartData .. GreenColor.. string.format("%.2f", tostring(chart[y][x])) ..DefaultColor.." |"
				else
					chartData = chartData .. string.format("%.2f", tostring(chart[y][x])) .." |"
				end
			end

		end

	end

		chartData = chartData .. "\n       "

	for x = 1, xEntries do 

		chartData = chartData .. "  " .. x*ThrottleStep .. "  "

	end 

		chartData = chartData .. "\n\n               THROTTLE(%)"
	
	-- print chart
	
	Tacview.UI.Renderer.Print(chartDataTransform, chartDataRenderStateHandle, chartData)

end

	

function OnDrawTransparentUI()

	if not fuelReportEnabled then
		return
	end

	DisplayBackground()

	DisplayChartData()

end

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

local fuelReportEnabledSettingName = "Fuel Report"
local fuelReportEnabledMenuId

function OnFuelReportEnabledMenuOption()

	-- Change the option

	fuelReportEnabled = not fuelReportEnabled

	-- Save it in the registry

	Tacview.AddOns.Current.Settings.SetBoolean(fuelReportEnabledSettingName, fuelReportEnabled)

	-- Update menu

	Tacview.UI.Menus.SetOption(fuelReportEnabledMenuId, fuelReportEnabled)

end


----------------------------------------------------------------
-- Initialize this addon
----------------------------------------------------------------

function Initialize()

	-- Declare addon properties

	local currentAddOn = Tacview.AddOns.Current

	InitializeCharts()

	currentAddOn.SetTitle("Fuel Consumption Report")
	currentAddOn.SetVersion("0.4")
	currentAddOn.SetAuthor("BuzyBee")
	currentAddOn.SetNotes("Display fuel consumption as a function of altitude and speed")

	fuelReportEnabledMenuId = Tacview.UI.Menus.AddOption(nil, "Fuel Report", fuelReportEnabled, OnFuelReportEnabledMenuOption)

	-- Register callbacks

	Tacview.Events.Update.RegisterListener(OnUpdate)
	Tacview.Events.DrawTransparentUI.RegisterListener(OnDrawTransparentUI)

end

Initialize()
