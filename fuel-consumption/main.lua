
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


-- Special control characters to change the text color on the fly

- local OrangeColor = string.char(2)
local DefaultColor = string.char(1)

local Margin = 16
local FontSize = 16
local FontColor = 0xFFA0FF46		-- HUD style green

local StatisticsRenderState =
{
	color = FontColor,
	blendMode = Tacview.UI.Renderer.BlendMode.Additive,
}

-- Drawing data

local statisticsRenderStateHandle

local fuelReportEnabledSettingName = "Fuel Report"
local fuelReportEnabledMenuId

local fuelReportEnabled = true

local indicatorRenderStateHandle
local indicatorVertexArrayHandle

local IndicatorWidth = 512
local IndicatorHeight = 256

local altitudeMax = 20000
local altitudeStep=2000

local throttleMax=1.2
local throttleStep=0.1

local dt = 10

local chart = {}

local previousSelectedObjectHandle

----------------------------------------------------------------
-- 2D Rendering
----------------------------------------------------------------

----------------------------------------------------------------
-- Main loop
----------------------------------------------------------------

-- Update is called once a frame by Tacview

function OnUpdate(dt, absoluteTime)

	local selectedObjectHandle = Tacview.Context.GetSelectedObject(0) or Tacview.Context.GetSelectedObject(1)

	if not selectedObjectHandle then
		return
	end

	if selectedObjectHandle ~= previousSelectedObjectHandle then
		print"new object found, calculating chart"
		calculateChart(selectedObjectHandle)
	end
	
	previousSelectedObjectHandle = selectedObjectHandle

end


function DeclareRenderData()

	-- Declare the render states for the instrument indicator and tape.
	-- The render state is used to define how to draw our 2D models.

	if not indicatorRenderStateHandle then

		local renderState =
		{
			color = 0x80000000,
		}

		indicatorRenderStateHandle = Tacview.UI.Renderer.CreateRenderState(renderState)

	end

	-- The following list of vertices is used to define the square shape of the instrument using two triangles.

	if not indicatorVertexArrayHandle then

		local HalfWidth = IndicatorWidth / 2
		local HalfHeight = IndicatorHeight / 2

		local vertexArray =
		{
			-HalfWidth, HalfHeight, 0.0,
			-HalfWidth, -HalfHeight, 0.0,
			HalfWidth, -HalfHeight, 0.0,
			-HalfWidth, HalfHeight, 0.0,
			HalfWidth, HalfHeight, 0.0,
			HalfWidth, -HalfHeight, 0.0,
		}

		indicatorVertexArrayHandle = Tacview.UI.Renderer.CreateVertexArray(vertexArray)

	end

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

		local throttle, isSampleValid = Tacview.Telemetry.GetNumericSample(selectedObjectHandle, i, fuelFlowWeightPropertyIndex)

		if not isSampleValid then
			throttle = nil
			return
		end

		values[#values + 1] = { altitude=position.altitude, fuelFlowWeight = fuelFlowWeight, throttle = throttle }
		
	end

	local sum = {}
	local count = {}

	for i=1,#values do

		for x=throttleStep,throttleMax,throttleStep do
		
			chart[x] = {}
			sum[x] = {}
			count[x] = {}

			for y=altitudeStep,altitudeMax,altitudeStep do

				if (values[i].throttle >= x - throttleStep) and (values[i].throttle < x) then

					if (values[i].altitude >= y - altitudeStep) and (values[i].altitude < y) then
					
						if sum[x][y] then
							sum[x][y] = sum[x][y] + values[i].fuelFlowWeight
						else
							sum[x][y] = values[i].fuelFlowWeight
						end

						if count[x][y] then
							count[x][y] = count[x][y] + 1
						else
							count[x][y] = 1
						end
					end
				end

				if count[x][y] then
					chart[x][y] = sum[x][y] / count[x][y]
				else
					chart[x][y] = '-'
				end
			end
		end
	end
end
	

function OnDrawTransparentUI()

	print"OnDrawTransparentUI"

	if not fuelReportEnabled then
		return
	end

	-- Compile render state

	local renderer = Tacview.UI.Renderer

	if not statisticsRenderStateHandle then

		statisticsRenderStateHandle = renderer.CreateRenderState(StatisticsRenderState)

	end

	DeclareRenderData()

	-- Draw Indicator

	local indicatorTransform =
	{
		x = Margin + IndicatorWidth / 2,
		y = renderer.GetHeight() * 3/8,
		scale = 1,
	}

	print"DrawUIVertexArray"

print ("indicatorRenderStateHandle",indicatorRenderStateHandle);

print("indicatorVertexArrayHandle",indicatorVertexArrayHandle);

	renderer.DrawUIVertexArray(indicatorTransform, indicatorRenderStateHandle, indicatorVertexArrayHandle)

	-- Display active objects statistics

	print"Display active objects statistics"

	local text = "Altitude"

	for y=altitudeMax,altitudeStep,-altitudeStep do

		text = text .. "\n" .. y
			
			for x = throttleStep,throttleMax,throttleStep do

				text = text .. chart[x][y]

			end
	end

		text = text .. "\n          "

	for x = throttleStep, throttleMax, throttleStep do 

		text = text .. x .. " "

	end 
	
								
	local transform =
	{
		x = Margin,
		y = renderer.GetHeight() / 2,
		scale = FontSize,
	}
	
	renderer.Print(transform, statisticsRenderStateHandle, text)

end

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
	currentAddOn.SetVersion("0.1")
	currentAddOn.SetAuthor("BuzyBee")
	currentAddOn.SetNotes("Display fuel consumption as a function of altitude and speed")

	fuelReportEnabledMenuId = Tacview.UI.Menus.AddOption(nil, "Fuel Report", fuelReportEnabled, OnFuelReportEnabledMenuOption)

	-- Register callbacks

	Tacview.Events.Update.RegisterListener(OnUpdate)
	Tacview.Events.DrawTransparentUI.RegisterListener(OnDrawTransparentUI)

end

Initialize()
