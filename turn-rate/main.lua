
-- Turn Rate Report
-- Author: Erin 'BuzyBee' O'REILLY
-- Last update: 2020-07-08 (Tacview 1.8.3)

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

local Tacview = require("Tacview184")

local instantaneousTurnRateReportRequested = false
local sustainedTurnRateReportRequested = false

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

local MachMax=1.2
local MachStep=0.1	-- MachMax should be a multiple of MachStep
local xEntries = 12

--constants

local rad2deg = 180/math.pi
local InstantaneousTurnRatePeriod = 1
local SustainedTurnRatePeriod = 10
local MaxChangeInAltitudeInstantaneous = 20
local MaxChangeInAltitudeSustained = 200

-- the calculation of the following 2 constants is based on the way the chart is drawn 
-- The chart has yEntries lines and xEntries columns plus axes and legends

local BackgroundHeight = (yEntries + 7)*FontSize
local BackgroundWidth = (xEntries + 3) * 6 * FontSize/2

-- percentiles above and below which values will be flagged red and green respectively

local FlagHighPercentile = 80
local FlagLowPercentile = 20

local updatePeriod = 10		-- how many seconds of data to calculate at one time
local samplePeriod = 1		-- how often to record turn rate data 

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
			
		for x=0,xEntries-1 do
			chart[y][x]=0

		end
	end
end

local previouslyInstantaneousTurnRateReportRequested = instantaneousTurnRateReportRequested
local previouslySustainedTurnRateReportRequested = sustainedTurnRateReportRequested

-- Update is called once a frame by Tacview

function OnUpdate(dt, absoluteTime)

	-- find selected object and determine if it has changed in this update

	local selectedObjectHandle = Tacview.Context.GetSelectedObject(0) or Tacview.Context.GetSelectedObject(1)

	if not selectedObjectHandle then
		return
	end

	local firstSampleTime, lastSampleTime= Tacview.Telemetry.GetTransformTimeRange(selectedObjectHandle)

	if selectedObjectHandle and selectedObjectHandle ~= previousSelectedObjectHandle then
		
		print"TURN RATE REPORT: New object found, calculating turn rate report"

		InitializeCharts()
		lastStatTime=firstSampleTime

	end

	-- keep track of selected object

	previousSelectedObjectHandle = selectedObjectHandle

	-- Report type changed?

	if	(previouslyInstantaneousTurnRateReportRequested ~= instantaneousTurnRateReportRequested) or
		(previouslySustainedTurnRateReportRequested ~= sustainedTurnRateReportRequested) then

		print"TURN RATE REPORT: New report type selected, calculating turn rate report"

		InitializeCharts()
		lastStatTime=firstSampleTime

	end	

	-- keep track of report type
		
	previouslyInstantaneousTurnRateReportRequested = instantaneousTurnRateReportRequested
	previouslySustainedTurnRateReportRequested = sustainedTurnRateReportRequested

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

	local values = ObtainData(selectedObjectHandle,startTime,endTime)

	-- sort through values 

	for i=1,#values do

		local instantaneousTurnRate = values[i].instantaneousTurnRate
		local sustainedTurnRate = values[i].sustainedTurnRate
		local machNumber = values[i].machNumber
		local previousAltitude = values[i].previousAltitude
		local currentAltitude = values[i].currentAltitude
		local machNumber = values[i].machNumber

		if instantaneousTurnRateReportRequested and (currentAltitude - previousAltitude > MaxChangeInAltitudeInstantaneous) then
			goto continue
		elseif sustainedTurnRateReportRequested and (currentAltitude - previousAltitude > MaxChangeInAltitudeSustained) then
			goto continue
		end

		local x = clamp(math.floor(machNumber/MachStep),0,xEntries-1)

		if machNumber > 0 and machNumber/MachStep - math.floor(machNumber/MachStep) == 0 then
			x = x-1
			x = clamp(x,0,xEntries-1)
		end
				
		local y = clamp(math.floor(currentAltitude/AltitudeStep),0,yEntries-1)

		if currentAltitude > 0 and currentAltitude/AltitudeStep - math.floor(currentAltitude/AltitudeStep) == 0 then
			y = y-1
			y = clamp(y,0,yEntries-1)
		end

		if instantaneousTurnRateReportRequested and instantaneousTurnRate then
			chart[y][x] = math.max(chart[y][x],instantaneousTurnRate * rad2deg)
		elseif sustainedTurnRateReportRequested and sustainedTurnRate then
			chart[y][x] = math.max(chart[y][x],sustainedTurnRate * rad2deg)
		end

		::continue::

	end

	-- determine percentiles fuel consumption so that above-average entries may be flagged

	local list = {}

	for y=0,yEntries-1 do

		for x=0,xEntries-1 do
			
			if chart[y][x] ~= 0 then
				list[#list+1] = chart[y][x]
			end
		end
	end

	table.sort(list)

	flagLowValue = list[math.ceil(#list * FlagLowPercentile/100)]
	flagHighValue = list[math.ceil(#list * FlagHighPercentile/100)] 

end

function ObtainData(selectedObjectHandle,startTime,endTime)

	local values = {}

	-- iterate through the times at the chosen samplePeriod rate

	for i = startTime+samplePeriod,endTime,samplePeriod do

		-- find distance and speed between the current and previous position of the object:getSampleRate()

		local lastPosition = Tacview.Telemetry.GetTransform(selectedObjectHandle, i-samplePeriod)
		local currentPosition = Tacview.Telemetry.GetTransform(selectedObjectHandle,i)

		local altitude0 =  lastPosition.altitude
		local altitude1 =  currentPosition.altitude
		local instantaneousTurnRate = Tacview.Telemetry.GetTurnRate(selectedObjectHandle,i,InstantaneousTurnRatePeriod) 
		local sustainedTurnRate = Tacview.Telemetry.GetTurnRate(selectedObjectHandle,i, SustainedTurnRatePeriod)

		-- keep track of info in a table

		values[#values + 1] = { previousAltitude = altitude0,
								currentAltitude = altitude1, 
								machNumber = Tacview.Telemetry.GetMachNumber(selectedObjectHandle,i),
								instantaneousTurnRate = instantaneousTurnRate,
								sustainedTurnRate = sustainedTurnRate }
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
	local chartData

	if(instantaneousTurnRateReportRequested) then
		chartData = " ALTITUDE(M)               INSTANTANEOUS TURN RATE\n"
	elseif(sustainedTurnRateReportRequested) then
		chartData = " ALTITUDE(M)               SUSTAINED TURN RATE\n"
	end

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

		chartData = chartData .. "  " .. x*MachStep .. "  "

	end 

		chartData = chartData .. "\n\n               SPEED (MACH NUMBER)"
	
	-- print chart
	
	Tacview.UI.Renderer.Print(chartDataTransform, chartDataRenderStateHandle, chartData)

end

function OnDrawTransparentUI()

	if not instantaneousTurnRateReportRequested and not sustainedTurnRateReportRequested then
		return
	end

	DisplayBackground()

	DisplayChartData()

end

--[[function GetSphericalDistance(x0, y0, x1, y1)
		
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

end--]]

local instantaneousTurnRateReportRequestedSettingName = "Instantaneous Turn Rate Report Requested"
local instantaneousTurnRateReportRequestedMenuId

local sustainedTurnRateReportRequestedSettingName = "Sustained Turn Rate Report Requested"
local sustainedTurnRateReportRequestedMenuId

function OnInstantaneousTurnRateReportRequested()

	-- Change the option

	instantaneousTurnRateReportRequested = not instantaneousTurnRateReportRequested

	if instantaneousTurnRateReportRequested and sustainedTurnRateReportRequested then
		
		sustainedTurnRateReportRequested = false;
		Tacview.AddOns.Current.Settings.SetBoolean(sustainedTurnRateReportRequestedSettingName, false)
		Tacview.UI.Menus.SetOption(sustainedTurnRateReportRequestedMenuId, false)

	end

	-- Save it in the registry

	Tacview.AddOns.Current.Settings.SetBoolean(instantaneousTurnRateReportRequestedSettingName, instantaneousTurnRateReportRequested)

	-- Update menu

	Tacview.UI.Menus.SetOption(instantaneousTurnRateReportRequestedMenuId, instantaneousTurnRateReportRequested)

end

function OnSustainedTurnRateReportRequested()

	-- Change the option

	sustainedTurnRateReportRequested = not sustainedTurnRateReportRequested

	if instantaneousTurnRateReportRequested and sustainedTurnRateReportRequested then

		instantaneousTurnRateReportRequested = false;
		Tacview.AddOns.Current.Settings.SetBoolean(instantaneousTurnRateReportRequestedSettingName, false)
		Tacview.UI.Menus.SetOption(instantaneousTurnRateReportRequestedMenuId, false)

	end

	-- Save it in the registry

	Tacview.AddOns.Current.Settings.SetBoolean(sustainedTurnRateReportRequestedSettingName, sustainedTurnRateReportRequested)

	-- Update menu

	Tacview.UI.Menus.SetOption(sustainedTurnRateReportRequestedMenuId, sustainedTurnRateReportRequested)

end

----------------------------------------------------------------
-- Initialize this addon
----------------------------------------------------------------

function Initialize()

	-- Declare addon properties

	local currentAddOn = Tacview.AddOns.Current

	currentAddOn.SetTitle("Turn Rate Report")
	currentAddOn.SetVersion("0.1")
	currentAddOn.SetAuthor("BuzyBee")
	currentAddOn.SetNotes("Display instantaneous or sustained turn rate as a function of altitude and speed")

	InitializeCharts()

	local mainMenuHandle = Tacview.UI.Menus.AddMenu(nil, "Turn Rate")

	instantaneousTurnRateReportRequested = Tacview.AddOns.Current.Settings.GetBoolean(instantaneousTurnRateReportRequestedSettingName, instantaneousTurnRateReportRequested)
	sustainedTurnRateReportRequested = Tacview.AddOns.Current.Settings.GetBoolean(sustainedTurnRateReportRequestedSettingName, sustainedTurnRateReportRequested)

	instantaneousTurnRateReportRequestedMenuId = Tacview.UI.Menus.AddExclusiveOption(mainMenuHandle, "Instantaneous Turn Rate Report", instantaneousTurnRateReportRequested, OnInstantaneousTurnRateReportRequested)
	sustainedTurnRateReportRequestedMenuId = Tacview.UI.Menus.AddExclusiveOption(mainMenuHandle, "Sustained Turn Rate Report", sustainedTurnRateReportRequested, OnSustainedTurnRateReportRequested)

	-- Register callbacks

	Tacview.Events.Update.RegisterListener(OnUpdate)
	Tacview.Events.DrawTransparentUI.RegisterListener(OnDrawTransparentUI)


end

Initialize()
