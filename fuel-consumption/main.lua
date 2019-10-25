
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
local yEntries = math.floor(AltitudeMax/AltitudeStep)

local ThrottleMax=1.2
local ThrottleStep=0.1	-- ThrottleMax should be a multiple of ThrottleStep
local xEntries = math.floor(ThrottleMax/ThrottleStep)

--constants

local m2ft = 3.28084
local m2km = 1/1000
local s2h = 1/3600
local rejectMax= 100

-- the calculation of the following 2 constants is based on the way the chart is drawn 
-- The chart has yEntries lines and xEntries columns plus axes and legends

local BackgroundHeight = (yEntries + 7)*FontSize
local BackgroundWidth = (xEntries + 1) * 6 * FontSize/2

-- choose calculation period

local dt = 5

local chart = {}

-- keep track of existing object

local previousSelectedObjectHandle

-- Update is called once a frame by Tacview

function OnUpdate(dt, absoluteTime)

	-- find selected object and determine if it has changed in this update

	local selectedObjectHandle = Tacview.Context.GetSelectedObject(0) or Tacview.Context.GetSelectedObject(1)

	if not selectedObjectHandle then
		return
	end

	if selectedObjectHandle ~= previousSelectedObjectHandle then
		print"New object found, calculating fuel consumption chart"
		calculateChart(selectedObjectHandle)
	end

	-- keep track of selected object
	
	previousSelectedObjectHandle = selectedObjectHandle

end

local averageFuelConsumption

function calculateChart(selectedObjectHandle)

	-- iterate through the lifetime of the object at the chosen dt rate

	local firstSampleTime, lastSampleTime = Tacview.Telemetry.GetTransformTimeRange(selectedObjectHandle)

	local values = {}

	for i=math.ceil(firstSampleTime),math.floor(lastSampleTime),dt do

		-- find distance and speed between the current and previous position of the object:getSampleRate()

		local previousTime
		local speedKpH
		local currentPosition
		local lastPosition

		currentPosition = Tacview.Telemetry.GetTransform(selectedObjectHandle,i)

		if previousTime then
			lastPosition = Tacview.Telemetry.GetTransform(selectedObjectHandle, previousTime)
			previousTime = i
		else
			lastPosition = Tacview.Telemetry.GetTransform(selectedObjectHandle, firstSampleTime)
		end

		local x0 = math.rad(tonumber(lastPosition.latitude))
		local y0 = math.rad(tonumber(lastPosition.longitude))
		local x1 = math.rad(tonumber(currentPosition.latitude))
		local y1 = math.rad(tonumber(currentPosition.longitude))

		local distanceInMeters = GetSphericalDistance(x0,y0,x1,y1)

		local speedKpH = (distanceInMeters*m2km)/(dt*s2h)

		-- find other necessary info 

		local fuelFlowWeightPropertyIndex = Tacview.Telemetry.GetObjectsNumericPropertyIndex("FuelFlowWeight", false)
		local throttlePropertyIndex = Tacview.Telemetry.GetObjectsNumericPropertyIndex("Throttle", false)

		if fuelFlowWeightPropertyIndex == Tacview.Telemetry.InvalidPropertyIndex then
			return
		end

		if throttlePropertyIndex == Tacview.Telemetry.InvalidPropertyIndex then
			return
		end

		local fuelFlowWeight, isSampleValid = Tacview.Telemetry.GetNumericSample(selectedObjectHandle, i, fuelFlowWeightPropertyIndex)

		if not isSampleValid then
			fuelFlowWeight = nil
			return
		end

		local throttle, isSampleValid = Tacview.Telemetry.GetNumericSample(selectedObjectHandle, i, throttlePropertyIndex)

		if not isSampleValid then
			throttle = nil
			return
		end

		-- keep track of info in a table

		values[#values + 1] = { altitude=currentPosition.altitude*m2ft, fuelFlowWeight = fuelFlowWeight, throttle = throttle, groundSpeed = speedKpH }
		
	end

	-- Create chart outline and sort through the values collected to place average values in correct location on chart.
	-- Keep track of sum and count so that average can be calculated later.
		
	local sum = {}
	local count = {}


	for x=0,xEntries-1 do
			
		chart[x]={}
		sum[x]={}
		count[x]={}
			
		for y=0,yEntries-1 do
			chart[x][y]=-1
			sum[x][y]=-1
			count[x][y]=-1
		end
	end

	-- sort through values 

	for i=1,#values do

		local throttle	=values[i].throttle
		local altitude = values[i].altitude
		local fuelFlowWeight = values[i].fuelFlowWeight
		local groundSpeed = values[i].groundSpeed
		local fuelConsumption	

		if groundSpeed ~= 0 then
			fuelConsumption = fuelFlowWeight/groundSpeed
		else
			fuelConsumption = 999
		end

		local x = math.floor(throttle/ThrottleStep)
		local y = math.floor(altitude/AltitudeStep)

		if fuelConsumption < 100 then
	
			if sum[x][y] >0 then
				sum[x][y] = sum[x][y] + fuelConsumption
			else 
				sum[x][y] = fuelConsumption
			end
	
			if count[x][y] >0 then
				count[x][y] = count[x][y] + 1
			else
				count[x][y] = 1
			end
			
		end
	end

	for x=0,xEntries-1 do

		chart[x]={}
				
		for y=0,yEntries-1 do

			if count[x][y]>0 then
				local average = sum[x][y]/count[x][y]
				chart[x][y]=math.floor(average*10)/10
			else
				chart[x][y] = '-'
			end
		end
	end

	for x=0,xEntries-1 do

		for y=0,yEntries-1 do

			if count[x][y]>0 then
				local average = sum[x][y]/count[x][y]
				chart[x][y]=math.floor(average*10)/10
			else
				chart[x][y] = '-'
			end
		end
	end

	-- determine average fuel consumption so that above-average entries may be flagged

	local sum = 0
	local count = 0

	for x=0,xEntries-1 do

		for y=0,yEntries-1 do
			
			if chart[x][y] ~= '-' then
				sum = sum + chart[x][y]
				count = count+1
			end
		end

		averageFuelConsumption = sum/count

	end

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

	local chartData = " ALTITUDE(M)               FUEL CONSUMPTION KG / KM\n"

	for y=yEntries-1,0,-1 do

		if((y+1)*AltitudeStep>=1000) then
			chartData = chartData .. "\n  " .. (y+1)*AltitudeStep .."|"
		else
			chartData = chartData .. "\n   " .. (y+1)*AltitudeStep .."|"
		end
	
		for x = 0,xEntries-1 do

			if(chart[x][y]=='-') then
				chartData = chartData .. "  -  |" 
			elseif chart[x][y]<10 then
				if chart[x][y]>averageFuelConsumption then
					chartData = chartData .. " "..OrangeColor..chart[x][y] ..DefaultColor.." |"
				else
					chartData = chartData .. " "..GreenColor..chart[x][y] ..DefaultColor.." |"
				end
			else
				if chart[x][y]>averageFuelConsumption then
					chartData = chartData .. OrangeColor .. chart[x][y] .. DefaultColor.." |"
				else
					chartData = chartData .. GreenColor..chart[x][y] ..DefaultColor.." |"
				end
			end

		end

	end

		chartData = chartData .. "\n         "

	for x = 1, xEntries do 

		chartData = chartData .. " " .. x*ThrottleStep .. "  "

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

	currentAddOn.SetTitle("Fuel Consumption Report")
	currentAddOn.SetVersion("0.3")
	currentAddOn.SetAuthor("BuzyBee")
	currentAddOn.SetNotes("Display fuel consumption as a function of altitude and speed")

	fuelReportEnabledMenuId = Tacview.UI.Menus.AddOption(nil, "Fuel Report", fuelReportEnabled, OnFuelReportEnabledMenuOption)

	-- Register callbacks

	Tacview.Events.Update.RegisterListener(OnUpdate)
	Tacview.Events.DrawTransparentUI.RegisterListener(OnDrawTransparentUI)

end

Initialize()
