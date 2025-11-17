
-- Fuel Consumption Report
-- Author: Erin 'BuzyBee' O'REILLY
-- Last update: 2025-03-19 (Tacview 1.9.5)

--[[

MIT License

Copyright (c) 2019-2025 Raia Software Inc.

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

local Tacview = require("Tacview195")

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

local AltitudeMaxMeters = 15000	
local AltitudeStepMeters=1000
local yEntriesMeters = 15		-- Entries * Step = Max

local AltitudeMaxFeet = 45000	
local AltitudeStepFeet=3000
local yEntriesFeet = 15			-- Entries * Step = Max

local AltitudeMax	
local AltitudeStep				
local yEntries

local ThrottleMax=1.2
local ThrottleStep=0.1			-- Entries * Step = Max
local xEntries = 12

-- data options

local perMinute = true
local perDistance = false
local perMinuteMenuHandle
local perDistanceMenuHandle

-- To reduce outliers obviously caused by data errors

local MinimumNumberOfSamplesRequired = 5  -- Arbitrary number - test to see 

--constants

local KilogramsToPounds = 2.20462
local LitersToGallons = 0.264172
local MetersToKilometers = 1/1000
local SecondsToMinutes = 1/60
local HoursToMinutes = 60
local FeetToMiles = 1/5280
local SecondsToHours = 1/3600
local MetersPerSecondToMilesPerHour = 2.23694
local MetersPerSecondToKilometersPerHour = 3.6
local MetersToMiles = 0.000621371

-- What minimum groundSpeed in mps

local minGroundSpeed = 28	-- 100kph = 28mps

-- the calculation of the following 2 constants is based on the way the chart is drawn 
-- The chart has yEntries lines and xEntries columns plus axes and legends

local BackgroundHeight = 350
local BackgroundWidth = 750

-- percentiles above and below which values will be flagged red and green respectively

local FlagHighPercentile = 80
local FlagLowPercentile = 20

local updatePeriod = 10		-- how many seconds of data to calculate at one time
local samplePeriod = 1		-- how many seconds over which to calculate fuel consumption
local samplePeriodInHours = 1/(3600/samplePeriod)
local samplePeriodInMinutes = 1/(60/samplePeriod)
local minDistance = 1		-- minimum distance in meters over which to calculate fuel consumption

-- keep track of existing object

local lastSelectedObjectHandle
local previousFuelVolume

-- keep track of whether data collection is calculationsPending 

local calculationsPending = true

-- Cumulative Statistic

local chartEntriesSum = {}
local chartEntriesCount = {}
local chart = {}
local lastStatTime = 0.0

local fuelVolumeAvailable = false
local fuelFlowWeightAvailable = false
local fuelWeightAvailable = false
local fuelFlowVolumeAvailable = false

local backgroundRenderStateHandle
local backgroundVertexArrayHandle
local chartDataRenderStateHandle

local onPerMinuteSettingName = "Per Minute"
local onPerDistanceSettingName = "Per Distance"

local noFuelInfoMessageDisplayed = false

local fuelWeightPropertyIndices = {}
local fuelVolumePropertyIndices = {}
local fuelFlowWeightPropertyIndices = {}
local fuelFlowVolumePropertyIndices = {}
local throttlePropertyIndex

function OnPerMinute()

	perMinute = true
	perDistance = false
	
	Tacview.UI.Menus.SetOption(perMinuteMenuHandle, true)
	Tacview.UI.Menus.SetOption(perDistanceMenuHandle, false)
	
	Tacview.AddOns.Current.Settings.SetBoolean(onPerMinuteSettingName, perMinute)
	Tacview.AddOns.Current.Settings.SetBoolean(onPerDistanceSettingName, perDistance)
	
	ResetCharts()
	
end

function OnPerDistance()

	perMinute = false
	perDistance = true
	
	Tacview.UI.Menus.SetOption(perMinuteMenuHandle, false)
	Tacview.UI.Menus.SetOption(perDistanceMenuHandle, true)
	
	Tacview.AddOns.Current.Settings.SetBoolean(onPerMinuteSettingName, perMinute)
	Tacview.AddOns.Current.Settings.SetBoolean(onPerDistanceSettingName, perDistance)
	
	ResetCharts()

end

function ResetCharts()

	Tacview.Log.Info("Resetting Charts")
	
	if Tacview.Settings.GetAltitudeUnit() == Tacview.Settings.Units.Feet then

		AltitudeMax = AltitudeMaxFeet
		AltitudeStep = AltitudeStepFeet
		yEntries = yEntriesFeet
	
	else 

		AltitudeMax = AltitudeMaxMeters
		AltitudeStep = AltitudeStepMeters
		yEntries = yEntriesMeters 

	end

	lastStatTime=0.0
	
	calculationsPending = true

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

local lastAltitudeUnits
local lastDistanceUnits

function OnUpdate(dt, absoluteTime)

	local selectedObjectHandle = Tacview.Context.GetSelectedObject(0) or Tacview.Context.GetSelectedObject(1)

	if not selectedObjectHandle then
		return
	end

	-- Do nothing if add-on is not in use.

	if not fuelReportEnabled then
		return
	end

	for i = 1, 9 do
		local propertyName = i == 1 and "FuelWeight" or ("FuelWeight" .. i)
		local propertyIndex = Tacview.Telemetry.GetObjectsNumericPropertyIndex(propertyName, false)
		fuelWeightPropertyIndices[i] = propertyIndex ~= Tacview.Telemetry.InvalidPropertyIndex and propertyIndex or nil
	end


	for i = 1, 9 do
		local propertyName = i == 1 and "FuelVolume" or ("FuelVolume" .. i)
		local propertyIndex = Tacview.Telemetry.GetObjectsNumericPropertyIndex(propertyName, false)
		fuelVolumePropertyIndices[i] = propertyIndex ~= Tacview.Telemetry.InvalidPropertyIndex and propertyIndex or nil
	end


	for i = 1, 9 do
		local propertyName = i == 1 and "FuelFlowWeight" or ("FuelFlowWeight" .. i)
		local propertyIndex = Tacview.Telemetry.GetObjectsNumericPropertyIndex(propertyName, false)
		fuelFlowWeightPropertyIndices[i] = propertyIndex ~= Tacview.Telemetry.InvalidPropertyIndex and propertyIndex or nil
	end


	for i = 1, 9 do
		local propertyName = i == 1 and "FuelFlowVolume" or ("FuelFlowVolume" .. i)
		local propertyIndex = Tacview.Telemetry.GetObjectsNumericPropertyIndex(propertyName, false)
		fuelFlowVolumePropertyIndices[i] = propertyIndex ~= Tacview.Telemetry.InvalidPropertyIndex and propertyIndex or nil
	end

	throttlePropertyIndex = Tacview.Telemetry.GetObjectsNumericPropertyIndex("Throttle", false)

	if throttlePropertyIndex == Tacview.Telemetry.InvalidPropertyIndex then
		return
	end

	local firstSampleTime, lastSampleTime = Tacview.Telemetry.GetTransformTimeRange(selectedObjectHandle)

	-- Do not perform calculations on intemporal objects.

	if firstSampleTime <= Tacview.Telemetry.BeginningOfTime then 
		return 
	end

	-- If object has changed, reset no fuel data available warning.

	local objectChanged = selectedObjectHandle and selectedObjectHandle ~= lastSelectedObjectHandle

	-- If units or object have changed, reinitialize charts.

	local currentAltitudeUnits = Tacview.Settings.GetAltitudeUnit()
	local currentDistanceUnits = Tacview.Settings.GetDistanceUnit()

	local unitsChanged = lastAltitudeUnits ~= currentAltitudeUnits or lastDistanceUnits ~= currentDistanceUnits

	if objectChanged or unitsChanged then
		ResetCharts()
	end

	-- keep track of selected object and units

	lastSelectedObjectHandle = selectedObjectHandle
	lastAltitudeUnits = currentAltitudeUnits
	lastDistanceUnits = currentDistanceUnits

	-- populate chart if the add-on was reloaded

	if lastStatTime <= 0.0 then
		lastStatTime = firstSampleTime
	end

	-- Update stats if enough new data is available 
	
	if lastStatTime + updatePeriod <= lastSampleTime then
		CalculateChart(selectedObjectHandle, lastStatTime,lastStatTime+updatePeriod)
		lastStatTime = lastStatTime + updatePeriod
	else
		
		if calculationsPending then
			Tacview.UI.Update()
			Tacview.Log.Info("Updating UI")
		end

		calculationsPending = false
	end
end

local flagLowValue = 0
local flagHighValue = 100

function clamp(x,min,max)

	return math.max(math.min(x,max),min)

end

function CalculateChart(selectedObjectHandle, startTime, endTime)

	local values = ObtainData(startTime,endTime,selectedObjectHandle)

	for i=1,#values do

		local throttle	=values[i].throttle
		local altitude = values[i].altitude
		local groundSpeed = values[i].groundSpeed
		local distance = values[i].distance
		local fuelConsumption

		local fuelFlowWeight = values[i].fuelFlowWeightTotal
		
		local fuelWeightDelta = values[i].fuelWeightDelta
		
		local fuelFlowVolume = values[i].fuelFlowVolumeTotal
		
		local fuelVolumeDelta = values[i].fuelVolumeDelta

		if Tacview.Settings.GetAltitudeUnit() == Tacview.Settings.Units.Feet then
			altitude = Tacview.Math.Units.MetersToFeet(altitude)
		end

		if groundSpeed > minGroundSpeed then
		
			if fuelFlowWeight then
			
				fuelFlowWeightAvailable = true
				fuelWeightAvailable = false
				fuelFlowVolumeAvailable = false
				fuelVolumeAvailable = false

				-- Fuel flow weight is in kilograms per hour
			
				if Tacview.Settings.GetDistanceUnit() == Tacview.Settings.Units.StatuteMilesFeet then
				
					if perMinute then			-- Pounds per Minute
							
						fuelConsumption = 	fuelFlowWeight* KilogramsToPounds / HoursToMinutes	 	
											
					else 						-- Pounds per Mile
					
						fuelConsumption = fuelFlowWeight* KilogramsToPounds * samplePeriodInHours / (distance * MetersToMiles)

					end

				elseif 	Tacview.Settings.GetDistanceUnit() == Tacview.Settings.Units.NauticalMilesFeet or 
						Tacview.Settings.GetDistanceUnit() == Tacview.Settings.Units.Feet then
				
					if perMinute then			--Pounds Per Minute
							
						fuelConsumption = 	fuelFlowWeight * KilogramsToPounds / HoursToMinutes	
											
					else 	  					-- Pounds Per Nautical Mile
					
						fuelConsumption = fuelFlowWeight * KilogramsToPounds * samplePeriodInHours /(Tacview.Math.Units.MetersToNauticalMiles(distance))
					end					
				
				else	-- metric / default

					if perMinute then			--Kilograms Per Minute
				
						fuelConsumption = 	fuelFlowWeight / HoursToMinutes		

					else 						-- perDistance / default
												--Kilograms Per Kilometer

						fuelConsumption = 	fuelFlowWeight * samplePeriodInHours /(distance * MetersToKilometers)
			
					end
				end
				
			elseif fuelWeightDelta then

				fuelFlowWeightAvailable = false
				fuelWeightAvailable = true
				fuelFlowVolumeAvailable = false
				fuelVolumeAvailable = false
				
				-- Fuel Weight is in Kilograms

				if Tacview.Settings.GetDistanceUnit() == Tacview.Settings.Units.StatuteMilesFeet then
				
					if perMinute then 			--Pounds Per Minute
							
						fuelConsumption = 	fuelWeightDelta*KilogramsToPounds/(samplePeriodInMinutes)								
											
					else 						-- perDistance/ default
												-- Pounds Per Mile
					
						fuelConsumption = 	fuelWeightDelta * KilogramsToPounds / (distance * MetersToMiles )		
						
					end

				elseif 	Tacview.Settings.GetDistanceUnit() == Tacview.Settings.Units.NauticalMilesFeet or 
						Tacview.Settings.GetDistanceUnit() == Tacview.Settings.Units.Feet then
				
					if perMinute then 			--Pounds Per Minute
							
						fuelConsumption = 	fuelWeightDelta*KilogramsToPounds/(samplePeriod * SecondsToMinutes)								
											
					else 						-- perDistance Pounds Per Nautical Mile
					
						fuelConsumption = 	fuelWeightDelta * KilogramsToPounds / (Tacview.Math.Units.MetersToNauticalMiles(distance) )	 
					end	
							
				else	-- metric/default
				
					if perMinute then			--Kilograms Per Minute
				
						fuelConsumption = 	fuelWeightDelta/(samplePeriodInMinutes)			

					else 						-- perDistance  
												--Kilograms Per Kilometer

						fuelConsumption = 	fuelWeightDelta/(distance * MetersToKilometers)
					end
				end
				
			elseif fuelFlowVolume then
			
				fuelFlowWeightAvailable = false
				fuelWeightAvailable = false
				fuelFlowVolumeAvailable = true
				fuelVolumeAvailable = false

				-- Fuel Flow Volume is in Litres Per Hour

				if Tacview.Settings.GetDistanceUnit() == Tacview.Settings.Units.StatuteMilesFeet then
				
					if perMinute then  		--Gallons Per Minute
							
						fuelConsumption = 	fuelFlowVolume * LitersToGallons/HoursToMinutes
											
					else 					-- perDistance / default	
											-- Gallons Per Mile
					
						fuelConsumption = fuelFlowVolume* LitersToGallons * samplePeriodInHours/(distance * MetersToMiles)

					end

				elseif 	Tacview.Settings.GetDistanceUnit() == Tacview.Settings.Units.NauticalMilesFeet or
						Tacview.Settings.GetDistanceUnit() == Tacview.Settings.Units.Feet then
				
					if perMinute then 		--Gallons Per Minute
							
						fuelConsumption = 	fuelFlowVolume* LitersToGallons/HoursToMinutes
											
					else					-- perDistance / default
											--Gallons Per Nautical Mile
					
						fuelConsumption = fuelFlowVolume* LitersToGallons * samplePeriodInHours/(Tacview.Math.Units.MetersToNauticalMiles(distance))

					end	
					
				else -- metric / default 

					if perMinute then		--Litres Per Minute
				
						fuelConsumption = 	fuelFlowVolume/HoursToMinutes

					else 					-- perDistance / default
											--Litres Per Kilometer

						fuelConsumption = 	fuelFlowVolume * samplePeriodInHours/(distance * MetersToKilometers)	
			
					end
				end
				
			elseif fuelVolumeDelta then
			
				fuelFlowWeightAvailable = false
				fuelWeightAvailable = false
				fuelFlowVolumeAvailable = false
				fuelVolumeAvailable = true

				-- Fuel Volume is in Litres
				
				if Tacview.Settings.GetDistanceUnit() == Tacview.Settings.Units.StatuteMilesFeet then
				
					if perMinute then			-- Gallons Per Minute
							
						fuelConsumption = 	fuelVolumeDelta * LitersToGallons/(samplePeriodInMinutes)
											
					else 						-- perDistance / default	
												-- Gallons Per Mile
					
						fuelConsumption = 	fuelVolumeDelta * LitersToGallons / (distance * MetersToMiles)
					end
				

				elseif 	Tacview.Settings.GetDistanceUnit() == Tacview.Settings.Units.NauticalMilesFeet or
						Tacview.Settings.GetDistanceUnit() == Tacview.Settings.Units.Feet then
				
					if perMinute then			-- Gallons Per Minute
							
						fuelConsumption = 	fuelVolumeDelta*LitersToGallons/(samplePeriodInMinutes)									
											
					else 						-- perDistance / default
												--Gallons Per Nautical Mile
					
						fuelConsumption = 	fuelVolumeDelta * LitersToGallons /Tacview.Math.Units.MetersToNauticalMiles(distance)	
					end	
				
				else -- metric / default
				
					if perMinute then			-- Litres Per Minute
				
						fuelConsumption = 	fuelVolumeDelta/(samplePeriodInMinutes)

					else 						-- perDistance / default
												--Litres Per Kilometer

						fuelConsumption = 	fuelVolumeDelta/(distance * MetersToKilometers)	
					end
				end			
				
			end

			local x =math.floor(throttle/ThrottleStep)

			if throttle > 0 and throttle/ThrottleStep -math.floor(throttle/ThrottleStep) == 0 then
				x = x-1
			end

			x = clamp(x,0,xEntries-1)

			local y =math.floor(altitude/AltitudeStep)

			if altitude > 0 and altitude/AltitudeStep -math.floor(altitude/AltitudeStep) == 0 then
				y = y-1
			end

			y = clamp(y,0,yEntries-1)
			
			if fuelConsumption then
				chartEntriesSum[y][x] = chartEntriesSum[y][x] + fuelConsumption
				chartEntriesCount[y][x] = chartEntriesCount[y][x] + 1
			end
		end
	end

	for y=0,yEntries-1 do

		for x=0,xEntries-1 do

			if chartEntriesCount[y][x] > MinimumNumberOfSamplesRequired then
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

	for i = startTime,endTime-samplePeriod,samplePeriod do

		-- Find distance and ground speed between the current and previous position of the object

		local previousPosition, previousPositionIsValid = Tacview.Telemetry.GetTransform(selectedObjectHandle, i-samplePeriod)
		local currentPosition, currentPositionIsValid = Tacview.Telemetry.GetTransform(selectedObjectHandle,i)

		if not previousPositionIsValid or not currentPositionIsValid then
			goto continue
		end

		local x0 = previousPosition.latitude
		local y0 = previousPosition.longitude
		local x1 = currentPosition.latitude
		local y1 = currentPosition.longitude

		local distance = GetSphericalDistance(x0,y0,x1,y1)

		if not distance then 
			goto continue
		end

		local groundSpeed = distance/samplePeriod

		-- Find fuel flow or change in fuel amount

		local fuelFlowWeightTotal = GetTotalFuelFlowWeight(selectedObjectHandle, i)

		local fuelWeightStartTime = GetTotalFuelWeight(selectedObjectHandle,i)
		local fuelWeightEndTime = GetTotalFuelWeight(selectedObjectHandle,i+samplePeriod)

		local fuelWeightDelta

		if fuelWeightStartTime and fuelWeightEndTime and fuelWeightEndTime <= fuelWeightStartTime then
			fuelWeightDelta = fuelWeightStartTime - fuelWeightEndTime
		end

		local fuelFlowVolumeTotal = GetTotalFuelFlowVolume(selectedObjectHandle, endTime)

		local fuelVolumeStartTime = GetTotalFuelVolume(selectedObjectHandle,i)
		local fuelVolumeEndTime = GetTotalFuelVolume(selectedObjectHandle,i+samplePeriod)

		local fuelVolumeDelta

		if fuelVolumeStartTime and fuelVolumeEndTime and fuelVolumeEndTime <= fuelVolumeStartTime then
			fuelVolumeDelta = fuelVolumeStartTime - fuelVolumeEndTime
		end

		if not fuelFlowWeightTotal and not fuelWeightDelta and not fuelFlowVolumeTotal and not fuelVolumeDelta then		
			goto continue
		end

		-- Find throttle

		local throttle, sampleIsValid = Tacview.Telemetry.GetNumericSample(selectedObjectHandle, i, throttlePropertyIndex)

		if not sampleIsValid or not throttle then
			goto continue 
		end

		-- keep track of info in a table

		if fuelFlowWeightTotal then

			values[#values + 1] = { altitude=currentPosition.altitude, distance = distance, fuelFlowWeightTotal = fuelFlowWeightTotal, throttle = throttle, groundSpeed = groundSpeed }
		
		elseif fuelWeightDelta then
			
			values[#values + 1] = { altitude=currentPosition.altitude, distance = distance, fuelWeightDelta = fuelWeightDelta, throttle = throttle, groundSpeed = groundSpeed }
		
		elseif fuelFlowVolumeTotal then

			values[#values + 1] = { altitude=currentPosition.altitude, distance = distance, fuelFlowVolumeTotal = fuelFlowVolumeTotal, throttle = throttle, groundSpeed = groundSpeed }
		
		elseif fuelVolumeDelta then

			values[#values + 1] = { altitude=currentPosition.altitude, distance = distance, fuelVolumeDelta = fuelVolumeDelta, throttle = throttle, groundSpeed = groundSpeed }
		
		end

		::continue::
	end

	return values
end



function GetTotalFuelWeight(selectedObjectHandle, time)
    
	local totalFuelWeight = 0
    local validSample = false

    for _, propertyIndex in ipairs(fuelWeightPropertyIndices) do
        if propertyIndex then
            local fuelWeight, sampleIsValid = Tacview.Telemetry.GetNumericSample(selectedObjectHandle, time, propertyIndex)
            if sampleIsValid and fuelWeight then
                totalFuelWeight = totalFuelWeight + fuelWeight
                validSample = true
            end
        end
    end

    return validSample and totalFuelWeight or nil
end

function GetTotalFuelVolume(selectedObjectHandle, time)

 
	local totalFuelVolume = 0
    local validSample = false

    for _, propertyIndex in ipairs(fuelVolumePropertyIndices) do
        if propertyIndex then
            local fuelVolume, sampleIsValid = Tacview.Telemetry.GetNumericSample(selectedObjectHandle, time, propertyIndex)
            if sampleIsValid and fuelVolume then
                totalFuelVolume = totalFuelVolume + fuelVolume
                validSample = true
            end
        end
    end

    return validSample and totalFuelVolume or nil
end

function GetTotalFuelFlowWeight(selectedObjectHandle, time)


    
	local totalFuelFlowWeight = 0
    local validSample = false

    for _, propertyIndex in ipairs(fuelFlowWeightPropertyIndices) do
        if propertyIndex then
            local fuelFlowWeight, sampleIsValid = Tacview.Telemetry.GetNumericSample(selectedObjectHandle, time, propertyIndex)
            if sampleIsValid and fuelFlowWeight then
                totalFuelFlowWeight = totalFuelFlowWeight + fuelFlowWeight
                validSample = true
            end
        end
    end

    return validSample and totalFuelFlowWeight or nil
end

function GetTotalFuelFlowVolume(selectedObjectHandle, time)


    
	local totalFuelFlowVolume = 0
    local validSample = false

    for _, propertyIndex in ipairs(fuelFlowVolumePropertyIndices) do
        if propertyIndex then
            local fuelFlowVolume, sampleIsValid = Tacview.Telemetry.GetNumericSample(selectedObjectHandle, time, propertyIndex)
            if sampleIsValid and fuelFlowVolume then
                totalFuelFlowVolume = totalFuelFlowVolume + fuelFlowVolume
                validSample = true
            end
        end
    end
    return validSample and totalFuelFlowVolume or nil
end

function DisplayBackground()

	if not backgroundRenderStateHandle then

		local renderState =
		{
			color = 0x80000000,
		}

		backgroundRenderStateHandle = Tacview.UI.Renderer.CreateRenderState(renderState)

	end


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
		y = 395,
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

	if not chartDataRenderStateHandle then

		chartDataRenderStateHandle = Tacview.UI.Renderer.CreateRenderState(ChartDataRenderState)

	end

	local chartDataTransform =
	{
		x = Margin,
		y = 364,
		scale = FontSize,
	}

	-- draw chart
	
	local chartData = ""

	if Tacview.Settings.GetAltitudeUnit() == Tacview.Settings.Units.Feet then

		chartData = " ASL(ft)" .. string.rep(" ",30) .. "FUEL CONSUMPTION "
	
	else 

		chartData = " ASL(m)" .. string.rep(" ",30) .. "FUEL CONSUMPTION "
	end

	if fuelWeightAvailable or fuelFlowWeightAvailable then
	
		if Tacview.Settings.GetDistanceUnit() == Tacview.Settings.Units.StatuteMilesFeet then

			if perMinute then	
				chartData = chartData .. "(POUNDS PER MINUTE)\n"
			elseif perDistance then
				chartData = chartData .. "(POUNDS PER MILE)\n"
			end
	
		elseif 	Tacview.Settings.GetDistanceUnit() == Tacview.Settings.Units.NauticalMilesFeet or 
				Tacview.Settings.GetDistanceUnit() == Tacview.Settings.Units.Feet then

			if perMinute then
				chartData = chartData .. "(POUNDS PER MINUTE)\n"
			elseif perDistance then
				chartData = chartData .. "(POUNDS PER NAUTICAL MILE)\n"
			end

		else -- metric / default

			if perMinute then
					chartData = chartData .. "(KILOGRAMS PER MINUTE)\n"
			elseif perDistance then
					chartData = chartData .. "(KILOGRAMS PER KILOMETER)\n"
			end
		end
	
	elseif fuelFlowVolumeAvailable or fuelVolumeAvailable then 
	
		if Tacview.Settings.GetDistanceUnit() == Tacview.Settings.Units.StatuteMilesFeet then
	
			if perMinute then
				chartData = chartData .. "(GALLONS PER MINUTE)\n"
			elseif perDistance then
				chartData = chartData .. "(GALLONS PER STATUTE MILE)\n"
			end

		elseif 	Tacview.Settings.GetDistanceUnit() == Tacview.Settings.Units.NauticalMilesFeet or 
				Tacview.Settings.GetDistanceUnit() == Tacview.Settings.Units.Feet then

			if perMinute then
				chartData = chartData .. "(GALLONS PER MINUTE)\n"
			elseif perDistance then
				chartData = chartData .. "(GALLONS PER NAUTICAL MILE)\n"
			end

		else -- metric / default
	
			if perMinute then
					chartData = chartData .. "(LITERS PER MINUTE)\n"
			elseif perDistance then
					chartData = chartData .. "(LITERS PER KILOMETER)\n"
			end
		end
	end	
	
	for y=yEntries-1,0,-1 do

		chartData = chartData .. "\n" .. string.format("%6s",(y+1)*AltitudeStep) .. " |"

		for x = 0,xEntries-1 do

			if chart[y][x]=='-' or chart[y][x]==0 then
				chartData = chartData .. "  -   |" 
			elseif chart[y][x]<10 then
				if chart[y][x]>=flagHighValue then
					chartData = chartData .. "  "..OrangeColor..string.format("%.2f", tostring(chart[y][x])) ..DefaultColor.."|"
				elseif chart[y][x]<=flagLowValue then
					chartData = chartData .. "  "..GreenColor..string.format("%.2f", tostring(chart[y][x])) ..DefaultColor.."|"
				else
					chartData = chartData .. "  "..string.format("%.2f", tostring(chart[y][x])) .."|"
				end
			elseif chart[y][x]<100 then
				if chart[y][x]>=flagHighValue then
					chartData = chartData .. " " .. OrangeColor .. string.format("%.2f", tostring(chart[y][x])) .. DefaultColor.."|"
				elseif chart[y][x]<=flagLowValue then
					chartData = chartData .. " " .. GreenColor.. string.format("%.2f", tostring(chart[y][x])) ..DefaultColor.."|"
				else
					chartData = chartData .. " " .. string.format("%.2f", tostring(chart[y][x])) .."|"
				end
			else 
				if chart[y][x]>=flagHighValue then
					chartData = chartData .. OrangeColor .. string.format("%.2f", tostring(chart[y][x])) .. DefaultColor.."|"
				elseif chart[y][x]<=flagLowValue then
					chartData = chartData .. GreenColor.. string.format("%.2f", tostring(chart[y][x])) ..DefaultColor.."|"
				else
					chartData = chartData .. string.format("%.2f", tostring(chart[y][x])) .."|"
				end
			end

		end

	end

		chartData = chartData .. "\n       "

	for x = 1, xEntries do 

		chartData = chartData .. "  " .. x*ThrottleStep .. "  "

	end 

		chartData = chartData .. "\n\n" .. string.rep(" ",40) .. "THROTTLE(%)"
	
	-- print chart
	
	Tacview.UI.Renderer.Print(chartDataTransform, chartDataRenderStateHandle, chartData)

end

function OnDrawTransparentUI()

	if not fuelReportEnabled then
		return
	end

	local objectHandle = Tacview.Context.GetSelectedObject(0) or Tacview.Context.GetSelectedObject(1)

	if not objectHandle then
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

	local tmp =math.cos(y0) *math.cos(y1);

	return 2.0 *math.asin(math.sqrt(HY + tmp * HX));

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


function OnDocumentLoaded()

	ResetCharts()

end


function OnPowerSaveOK()
	return not calculationsPending 
end

function OnShutdown()

	if backgroundRenderStateHandle then
		Tacview.UI.Renderer.ReleaseRenderState(backgroundRenderStateHandle)
		backgroundRenderStateHandle = nil
	end
	
		
	if chartDataRenderStateHandle then
		Tacview.UI.Renderer.ReleaseRenderState(chartDataRenderStateHandle)
		chartDataRenderStateHandle = nil
	end
	
	if backgroundVertexArrayHandle then
		Tacview.UI.Renderer.ReleaseVertexArray(backgroundVertexArrayHandle)
		backgroundVertexArrayHandle = nil
	end

end

----------------------------------------------------------------
-- Initialize this addon
----------------------------------------------------------------

function Initialize()

	-- Declare addon properties

	local currentAddOn = Tacview.AddOns.Current

	ResetCharts()

	currentAddOn.SetTitle("Fuel Consumption Report")
	currentAddOn.SetVersion("1.9.5.104")
	currentAddOn.SetAuthor("BuzyBee")
	currentAddOn.SetNotes("Display fuel consumption as a function of altitude and groundSpeed")
	
	fuelReportEnabled = Tacview.AddOns.Current.Settings.GetBoolean(fuelReportEnabledSettingName, fuelReportEnabled)
	perMinute = Tacview.AddOns.Current.Settings.GetBoolean(onPerMinuteSettingName, perMinute)
	perDistance = Tacview.AddOns.Current.Settings.GetBoolean(onPerDistanceSettingName, perDistance)

	local mainMenuHandle = Tacview.UI.Menus.AddMenu(nil, "Fuel Report")
	
	fuelReportEnabledMenuId = Tacview.UI.Menus.AddOption( mainMenuHandle , "Display Fuel Consumption Report" , fuelReportEnabled , OnFuelReportEnabledMenuOption )
	
	Tacview.UI.Menus.AddSeparator(mainMenuHandle)
	
	perMinuteMenuHandle = Tacview.UI.Menus.AddExclusiveOption( mainMenuHandle , "Show Consumption Over Time" , perMinute , OnPerMinute )
	perDistanceMenuHandle = Tacview.UI.Menus.AddExclusiveOption( mainMenuHandle , "Show Consumption Over Distance" , perDistance , OnPerDistance )

	Tacview.UI.Menus.AddSeparator( mainMenuHandle )

	local resetChartsMenuHandle = Tacview.UI.Menus.AddCommand(mainMenuHandle, "Reset Fuel Charts", ResetCharts)

	
	-- Register callbacks

	Tacview.Events.Update.RegisterListener(OnUpdate)
	Tacview.Events.DrawTransparentUI.RegisterListener(OnDrawTransparentUI)
	Tacview.Events.DocumentLoaded.RegisterListener(OnDocumentLoaded)
	Tacview.Events.DocumentUnload.RegisterListener(OnDocumentLoaded)
	Tacview.Events.PowerSave.RegisterListener(OnPowerSaveOK)
	Tacview.Events.Shutdown.RegisterListener(OnShutdown) 

end

Initialize()
