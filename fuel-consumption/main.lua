
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
local DefaultColor = string.char(1)

local Margin = 16
local FontSize = 16
local FontColor = 0xFFA0FF46		-- HUD style green

local BackgroundWidth = 600
local BackgroundHeight = 200

local AltitudeMax = 20000
local AltitudeStep=2000
local yEntries = 10

local ThrottleMax=1.2
local ThrottleStep=0.1
local xEntries = 12 

local m2ft = 3.28084

local dt = 5

local chart = {}

local previousSelectedObjectHandle

-- Update is called once a frame by Tacview

function OnUpdate(dt, absoluteTime)

	local selectedObjectHandle = Tacview.Context.GetSelectedObject(0) or Tacview.Context.GetSelectedObject(1)

	if not selectedObjectHandle then
		return
	end

	if selectedObjectHandle ~= previousSelectedObjectHandle then
		print"New object found, calculating fuel consumption chart"
		calculateChart(selectedObjectHandle)
	end
	
	previousSelectedObjectHandle = selectedObjectHandle

end

function calculateChart(selectedObjectHandle)

	local firstSampleTime, lastSampleTime = Tacview.Telemetry.GetTransformTimeRange(selectedObjectHandle)

	local previousTime

	local values = {}

	for i=math.ceil(firstSampleTime),math.floor(lastSampleTime),dt do
		previousTime = i
		local position = Tacview.Telemetry.GetTransform(selectedObjectHandle, i)

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

		values[#values + 1] = { altitude=position.altitude*m2ft, fuelFlowWeight = fuelFlowWeight, throttle = throttle }
		
	end
		
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

	for i=1,#values do

		local throttle	=values[i].throttle
		local altitude = values[i].altitude
		local fuelFlowWeight = values[i].fuelFlowWeight

		local x = math.floor(throttle/ThrottleStep)
		local y = math.floor(altitude/AltitudeStep)

		if sum[x][y] >0 then
			sum[x][y] = sum[x][y] + fuelFlowWeight
		else
			sum[x][y] = fuelFlowWeight
		end

		if count[x][y] >0 then
			count[x][y] = count[x][y] + 1
		else
			count[x][y] = 1
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

		local HalfWidth = BackgroundWidth / 2
		local HalfHeight = BackgroundHeight / 2

		local vertexArray =
		{
			-HalfWidth,0,0,
			-HalfWidth,-BackgroundHeight,0,
			HalfWidth,-BackgroundHeight,0,
			-HalfWidth,0,0,
			HalfWidth,0,0,
			HalfWidth,-BackgroundHeight,0,

			
			
		--[[	-HalfWidth, HalfHeight, 0.0,
			-HalfWidth, -HalfHeight, 0.0,
			HalfWidth, -HalfHeight, 0.0,
			-HalfWidth, HalfHeight, 0.0,
			HalfWidth, HalfHeight, 0.0,
			HalfWidth, -HalfHeight, 0.0,--]]

		}

		backgroundVertexArrayHandle = Tacview.UI.Renderer.CreateVertexArray(vertexArray)

	end


	local backgroundTransform =
	{
		x = Margin + BackgroundWidth / 2,
		y = Tacview.UI.Renderer.GetHeight() / 2,
		scale = 1,
	}

	Tacview.UI.Renderer.DrawUIVertexArray(backgroundTransform, backgroundRenderStateHandle, backgroundVertexArrayHandle)

end


function DisplayChartData()

	local ChartDataRenderState =
	{
		color = FontColor,
		blendMode = Tacview.UI.Renderer.BlendMode.Additive,
	}

	local chartDataRenderStateHandle

	if not chartDataRenderStateHandle then

		chartDataRenderStateHandle = Tacview.UI.Renderer.CreateRenderState(ChartDataRenderState)

	end

	local chartData = "ALTITUDE(FT)"

	for y=yEntries-1,0,-1 do

		if((y+1)*AltitudeStep>=10000) then
			chartData = chartData .. "\n" .. (y+1)*AltitudeStep .."|"
		else
			chartData = chartData .. "\n " .. (y+1)*AltitudeStep .."|"
		end
	
		for x = 0,xEntries-1 do

			if(chart[x][y]=='-') then
				chartData = chartData .. "  -  |" 
			elseif chart[x][y]<10 then
				chartData = chartData .. " "..chart[x][y] .." |"
			else
				chartData = chartData .. chart[x][y] .." |"
			end

		end

	end

		chartData = chartData .. "\n      "

	for x = 1, xEntries do 

		chartData = chartData .. " " .. x*ThrottleStep .. "  "

	end 

		chartData = chartData .. "\n     THROTTLE(%)"
	
								
	local chartDataTransform =
	{
		x = Margin,
		y = Tacview.UI.Renderer.GetHeight() / 2,
		scale = FontSize,
	}
	
	Tacview.UI.Renderer.Print(chartDataTransform, chartDataRenderStateHandle, chartData)

end

	

function OnDrawTransparentUI()

	if not fuelReportEnabled then
		return
	end

	DisplayBackground()

	DisplayChartData()



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
	currentAddOn.SetVersion("0.2")
	currentAddOn.SetAuthor("BuzyBee")
	currentAddOn.SetNotes("Display fuel consumption as a function of altitude and speed")

	fuelReportEnabledMenuId = Tacview.UI.Menus.AddOption(nil, "Fuel Report", fuelReportEnabled, OnFuelReportEnabledMenuOption)

	-- Register callbacks

	Tacview.Events.Update.RegisterListener(OnUpdate)
	Tacview.Events.DrawTransparentUI.RegisterListener(OnDrawTransparentUI)

end

Initialize()
