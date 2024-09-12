
-- Turn Rate Report
-- Author: Erin 'BuzyBee' O'REILLY
-- Last update: 2024-08-19 (Tacview 1.9.3)

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

----------------------------------------------------------------
-- Setup
----------------------------------------------------------------

require("lua-strict")

local Tacview = require("Tacview193")

local instantaneous = false
local sustained = false

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
local yEntriesMeters = 15				-- Entries * Step = Max

local AltitudeMaxFeet = 45000	
local AltitudeStepFeet=3000
local yEntriesFeet = 15					-- Entries * Step = Max

local AltitudeMax = AltitudeMaxMeters	-- default
local AltitudeStep = AltitudeStepMeters	-- default
local yEntries = yEntriesMeters			-- default

local MachMin=0.3
local MachMax=1.0
local MachStep=0.05	
local xEntries = 15						-- Min + (Entries - 1)*Step = Max

--constants

local m2ft = 3.28084

local InstantaneousTurnRatePeriod = 1
local SustainedTurnRatePeriod = 5

local MaxChangeInAltitudeInstantaneous = 20		-- m
local MaxChangeInAltitudeSustained = 200		-- m

local MaxChangeInSpeedInstantaneous = 0.3 * InstantaneousTurnRatePeriod
local MaxChangeInSpeedSustained = 0.015 * SustainedTurnRatePeriod

local MinimumTurnRate = 5

-- the calculation of the following 2 constants is based on the way the chart is drawn 
-- The chart has yEntries lines and xEntries columns plus axes and legends

local BackgroundHeight = 350
local BackgroundWidth = 750

-- percentiles above and below which values will be flagged red and green respectively

local FlagHighPercentile = 80
local FlagLowPercentile = 20

local updatePeriod = 10		-- how many seconds of data to calculate at one time
local samplePeriod = 1		-- how often to record turn rate data 

-- keep track of existing object

local previousSelectedObjectHandle

-- keep track of whether data collection is done

local done = true

-- Display handles

local backgroundRenderStateHandle
local backgroundVertexArrayHandle
local chartDataRenderStateHandle

-- Cumulative Statistic

local chartEntriesSum = {}
local chartEntriesCount = {}
local sustainedChart = {}
local instantaneousChart={}
local displayChart={}
local lastStatTime = 0.0

function InitializeCharts()

	for y=0,yEntries-1 do
			
		sustainedChart[y]={}
		instantaneousChart[y]={}
		displayChart[y]={}
			
		for x=0,xEntries-1 do
			sustainedChart[y][x]=0
			instantaneousChart[y][x]=0
			displayChart[y][x]=0
		end
	end
	
	done = true

end

local previousInstantaneous = instantaneous
local previousSustained = sustained
local previousUnits 

-- Update is called once a frame by Tacview

function OnUpdate(dt, absoluteTime)

	-- Do nothing if add-on is not in use.

	if not instantaneous and not sustained then
		return
	end
	
	-- Use correct units

	SetUnits()	

	-- Find selected object and its time range

	local selectedObjectHandle = Tacview.Context.GetSelectedObject(0) or Tacview.Context.GetSelectedObject(1)
	
	if not selectedObjectHandle then
		return
	end
	
	local tags = Tacview.Telemetry.GetCurrentTags(selectedObjectHandle)
	
	if not Tacview.Telemetry.AnyGivenTagActive(tags, Tacview.Telemetry.Tags.FixedWing|Tacview.Telemetry.Tags.Rotorcraft) then
		InitializeCharts()
		return
	end

	local firstSampleTime, lastSampleTime= Tacview.Telemetry.GetTransformTimeRange(selectedObjectHandle)

	-- Do not perform calculations on intemporal objects.
	
	if firstSampleTime <= Tacview.Telemetry.BeginningOfTime then 
		
		local count = Tacview.Telemetry.GetTransformCount(selectedObjectHandle)
		
		-- Falcon BMS 4.37.3 is adding aircraft as intemporal objects
		-- Compensate by using the second sample available
		
		if count > 1 then
			local transform = Tacview.Telemetry.GetTransformFromIndex(selectedObjectHandle, 1)
			firstSampleTime = transform.time
		else
			return
		end
	end

	-- If object has changed, reinitialize charts.

	if selectedObjectHandle ~= previousSelectedObjectHandle and (instantaneous or sustained) then

        InitializeCharts()
		lastStatTime=firstSampleTime

	end

	-- Keep track of selected object.

	previousSelectedObjectHandle = selectedObjectHandle

	-- If report type has changed, reinitialize charts.

	if	(previousInstantaneous ~= instantaneous) or
		(previousSustained ~= sustained) then

		InitializeCharts()
		lastStatTime=firstSampleTime

	end	

	-- Keep track of report type.
		
	previousInstantaneous = instantaneous
	previousSustained = sustained

	-- If units have changed, reinitialize charts.

	local currentUnits = Tacview.Settings.GetAltitudeUnit()

	if previousUnits ~= currentUnits then

		InitializeCharts()
		lastStatTime=firstSampleTime
		SetUnits()

	end

	-- Keep track of units.

	previousUnits = currentUnits

	-- Update stats if enough new data is available.

	if lastStatTime+updatePeriod <= lastSampleTime then
		done = false
		calculateChart(selectedObjectHandle, lastStatTime,lastStatTime+updatePeriod)
		lastStatTime = lastStatTime + updatePeriod
	else
		done = true
	end

end

local flagLowValueInstantaneous = 0
local flagHighValueInstantaneous = 100
local flagLowValueSustained = 0
local flagHighValueSustained = 100

function clamp(x,min,max)

	return math.max(math.min(x,max),min)

end

function calculateChart(selectedObjectHandle, startTime, endTime)

	local values = ObtainData(selectedObjectHandle,startTime,endTime)

	-- sort through values 

	for i=1,#values do

		local instantaneousTurnRate = values[i].instantaneousTurnRate
		local sustainedTurnRate = values[i].sustainedTurnRate
		local currentMach = values[i].currentMach
		local previousMach = values[i].previousMach
		local previousAltitude = values[i].previousAltitude
		local currentAltitude = values[i].currentAltitude
		local machNumber = values[i].machNumber
		local sampleStartTime = values[i].sampleStartTime
		local sampleEndTime = values[i].sampleEndTime

		--if Tacview.Settings.GetAltitudeUnit() == Tacview.Settings.Units.Feet then 
			--currentAltitude = currentAltitude * m2ft
			--previousAltitude = previousAltitude * m2ft
		--end

		if not (instantaneousTurnRate and 
				sustainedTurnRate and 
				currentMach and 
				previousMach and 
				previousAltitude and 
				currentAltitude and 
				machNumber and 
				sampleStartTime and 
				sampleEndTime ) then
			goto continue
		end

		if machNumber < MachMin then
			goto continue
		end

		if instantaneous and (currentAltitude - previousAltitude > MaxChangeInAltitudeInstantaneous) and instantaneousTurnRate > MinimumTurnRate then
			
			local msg = "Not including instantaneous turn rate calculated between "..
						Tacview.UI.Format.AbsoluteTimeToISOText(sampleStartTime).." to "..Tacview.UI.Format.AbsoluteTimeToISOText(sampleEndTime)..
						" because of difference in altitude of "
			
			if(Tacview.Settings.GetAltitudeUnit() == Tacview.Settings.Units.Feet) then
				msg = msg .. string.format("%0.0f",(currentAltitude-previousAltitude)*m2ft).." ft" 
			else
				msg = msg .. string.format("%0.0f",(currentAltitude-previousAltitude)).." m"
			end
			
			Tacview.Log.Debug(msg)
			
			goto continue
			
		elseif 	sustained and 
				sustainedTurnRate > MinimumTurnRate and 
				(currentAltitude - previousAltitude > MaxChangeInAltitudeSustained)  then
			
			local msg = "Not including sustained turn rate calculated between "..
						Tacview.UI.Format.AbsoluteTimeToISOText(sampleStartTime).." to "..Tacview.UI.Format.AbsoluteTimeToISOText(sampleEndTime)..
						" because of difference in altitude of "
			
			if(Tacview.Settings.GetAltitudeUnit() == Tacview.Settings.Units.Feet) then
				msg = msg .. string.format("%0.0f",(currentAltitude-previousAltitude)*m2ft.." ft")
			else
				msg = msg .. string.format("%0.0f",(currentAltitude-previousAltitude).." m")
			end
			
			Tacview.Log.Debug(msg)
			
			goto continue
			
		elseif 	instantaneous and 
				instantaneousTurnRate > MinimumTurnRate and
				(currentMach - previousMach > MaxChangeInSpeedInstantaneous)  then
			
			Tacview.Log.Debug(	"Not including instantaneous turn rate calculated between "..
								Tacview.UI.Format.AbsoluteTimeToISOText(sampleStartTime).." to "..Tacview.UI.Format.AbsoluteTimeToISOText(sampleEndTime)..
								" because of difference in mach number of "..string.format("%0.01f",currentMach-previousMach)	)
			
			goto continue

		elseif 	sustained and 
				sustainedTurnRate > MinimumTurnRate and 
				(currentMach - previousMach > MaxChangeInSpeedSustained) then
		
			Tacview.Log.Debug(	"Not including sustained turn rate calculated between "..
								Tacview.UI.Format.AbsoluteTimeToISOText(sampleStartTime).." to "..Tacview.UI.Format.AbsoluteTimeToISOText(sampleEndTime)..
								" because of difference in mach number of "..string.format("%0.01f",currentMach-previousMach)	)
			
			goto continue

		end

		local x = clamp(math.floor((machNumber-MachMin)/MachStep),0,xEntries-1)

		if machNumber > 0 and (machNumber-MachMin)/MachStep - math.floor((machNumber-MachMin)/MachStep) == 0 then
			x = x-1
		end

		x = clamp(x,0,xEntries-1)

		if Tacview.Settings.GetAltitudeUnit() == Tacview.Settings.Units.Feet then
			currentAltitude = currentAltitude * m2ft
		end				

		local y = clamp(math.floor(currentAltitude/AltitudeStep),0,yEntries-1)

		if currentAltitude > 0 and currentAltitude/AltitudeStep - math.floor(currentAltitude/AltitudeStep) == 0 then
			y = y-1
		end

		y = clamp(y,0,yEntries-1)

		if instantaneous and instantaneousTurnRate and math.deg(instantaneousTurnRate) >= MinimumTurnRate then
			instantaneousChart[y][x] = math.max(instantaneousChart[y][x], math.deg(instantaneousTurnRate))
		end

		if sustained and sustainedTurnRate and math.deg(sustainedTurnRate) >=MinimumTurnRate then
			sustainedChart[y][x] = math.max(sustainedChart[y][x], math.deg(sustainedTurnRate))
		end

		::continue::

	end

	-- determine percentiles fuel consumption so that above-average entries may be flagged

	if instantaneous then

		local listInstantaneous = {}

		for y=0,yEntries-1 do

			for x=0,xEntries-1 do
				
				if instantaneousChart[y][x] ~= 0 then
					listInstantaneous[#listInstantaneous+1] = instantaneousChart[y][x]
				end
			end
		end

		table.sort(listInstantaneous)

		local instantaneousLowIndex = math.ceil(#listInstantaneous * FlagLowPercentile/100)

		if(instantaneousLowIndex ~= 0) then
			flagLowValueInstantaneous = listInstantaneous[instantaneousLowIndex]
		end

		local instantaneousHighIndex = math.ceil(#listInstantaneous * FlagHighPercentile/100)

		if(instantaneousHighIndex ~= 0) then
			flagHighValueInstantaneous = listInstantaneous[instantaneousHighIndex]
		end
	end

	if sustained then

		local listSustained = {}

		for y=0,yEntries-1 do

			for x=0,xEntries-1 do
				
				if sustainedChart[y][x] ~= 0 then
					listSustained[#listSustained+1] = sustainedChart[y][x]
				end
			end
		end

		table.sort(listSustained)

		local sustainedLowIndex = math.ceil(#listSustained * FlagLowPercentile/100)

		if(sustainedLowIndex ~= 0) then
			flagLowValueSustained = listSustained[sustainedLowIndex]
		end

		local sustainedHighIndex = math.ceil(#listSustained * FlagHighPercentile/100)

		if(sustainedHighIndex ~= 0) then
			flagHighValueSustained = listSustained[sustainedHighIndex]
		end

	end
end

function ObtainData(selectedObjectHandle,startTime,endTime)

	local values = {}
	
	-- iterate through the times at the chosen samplePeriod rate

	for i = startTime+samplePeriod,endTime,samplePeriod do

		-- find distance and speed between the current and previous position of the object:getSampleRate()

		local lastPosition = Tacview.Telemetry.GetTransform(selectedObjectHandle, i-samplePeriod)
		local currentPosition = Tacview.Telemetry.GetTransform(selectedObjectHandle,i)
		local previousMach = Tacview.Telemetry.GetMachNumber(selectedObjectHandle, i-samplePeriod)
		local currentMach = Tacview.Telemetry.GetMachNumber(selectedObjectHandle,i)

		local altitude0 =  lastPosition.altitude
		local altitude1 =  currentPosition.altitude
		local instantaneousTurnRate = Tacview.Telemetry.GetTurnRate(selectedObjectHandle,i,InstantaneousTurnRatePeriod) 
		local sustainedTurnRate = Tacview.Telemetry.GetTurnRate(selectedObjectHandle,i, SustainedTurnRatePeriod)

		-- keep track of info in a table

		values[#values + 1] = { sampleStartTime = i-samplePeriod,
								sampleEndTime = i,
								previousAltitude = altitude0,
								currentAltitude = altitude1, 
								machNumber = Tacview.Telemetry.GetMachNumber(selectedObjectHandle,i),
								instantaneousTurnRate = instantaneousTurnRate,
								sustainedTurnRate = sustainedTurnRate ,
								previousMach = previousMach,
								currentMach = currentMach,
							}
	end

	return values

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
	local chartData

	if Tacview.Settings.GetAltitudeUnit() == Tacview.Settings.Units.Feet then
		chartData = " ASL (ft)"
	else
		chartData = " ASL (m)"
	end

	if(instantaneous and sustained) then
		chartData = chartData .. "                       SUSTAINED/INSTANTANEOUS TURN RATE (\xC2\xB0/s)\n"
	elseif(instantaneous) then
		chartData = chartData .. "                            INSTANTANEOUS TURN RATE (\xC2\xB0/s)\n"
	elseif(sustained) then
		chartData = chartData .. "                              SUSTAINED TURN RATE (\xC2\xB0/s)\n"
	end

	for y=yEntries-1,0,-1 do

		if((y+1)*AltitudeStep>=10000) then
			chartData = chartData .. "\n  " .. (y+1)*AltitudeStep .."|"
		else
			chartData = chartData .. "\n   " .. (y+1)*AltitudeStep .."|"
		end
	
		for x = 0,xEntries-1 do

			if instantaneousChart[y][x] > 100 then
				instantaneousChart[y][x] = 99
			end

			if sustainedChart[y][x] > 100 then
				sustainedChart[y][x] = 99
			end

			if instantaneous and sustained then

				if ((not instantaneousChart[y][x]) or instantaneousChart[y][x]==0) and 
					((not sustainedChart[y][x]) or sustainedChart[y][x] ==0) then
					chartData = chartData .. "  -  |"
					goto continue
				end

				local sustainedRounded
				
				if sustainedChart[y][x] then
					sustainedRounded = math.floor(sustainedChart[y][x]+0.5)
				else
					sustainedRounded = 0
				end

				local instantaneousRounded

				if instantaneousChart[y][x] then
					instantaneousRounded = math.floor(instantaneousChart[y][x]+0.5)
				else
					instantaneousRounded = 0
				end
						
				if not flagHighValueSustained or not flagLowValueSustained or not flagHighValueInstantaneous or not flagLowValueInstantaneous then
					chartData = chartData .. "  -  |"
					Tacview.Log.Debug("TURN-RATE: Missing flag high/low value")
					goto continue
				end

				if sustainedRounded ~= 0 then
					
					if sustainedRounded>=flagHighValueSustained then
							chartData = chartData .. GreenColor .. string.format("%2d",sustainedRounded) .. DefaultColor
					elseif sustainedRounded<=flagLowValueSustained then
							chartData = chartData ..OrangeColor .. string.format("%2d",sustainedRounded) .. DefaultColor
					else
						chartData = chartData .. string.format("%2d",sustainedRounded)
					end
					
					if instantaneousRounded == 0 then
						chartData = chartData .. "/"
					end
				else -- sustainedRounded == 0; therefore instantaneousRounded is NOT zero
					chartData = chartData .. "  "
				end

				if instantaneousRounded ~= 0 then
					if instantaneousRounded>=flagHighValueInstantaneous then
							chartData = chartData .. "/" ..GreenColor .. string.format("%2d",instantaneousRounded) .. DefaultColor .. "|"
					elseif instantaneousRounded<=flagLowValueInstantaneous then
							chartData = chartData .. "/" .. OrangeColor .. string.format("%2d",instantaneousRounded) .. DefaultColor .. "|"
					else
						chartData = chartData .. "/" .. string.format("%2d",instantaneousRounded) .."|"
					end
				else -- instantaneousRounded == 0; therefore sustainedRounded is NOT zero
					chartData = chartData .. "  |"
				end

			elseif instantaneous or sustained then

				local flagHighValue
				local flagLowValue
				
				if instantaneous then 

					if not flagHighValueInstantaneous or not flagLowValueInstantaneous then
						chartData = chartData .. "  -  |"
						Tacview.Log.Debug("TURN-RATE: Missing flag high/low value")
						goto continue
					end

					displayChart = instantaneousChart 
					flagHighValue = flagHighValueInstantaneous
					flagLowValue = flagLowValueInstantaneous

				elseif sustained then 

					if not flagHighValueSustained or not flagLowValueSustained then
						chartData = chartData .. "  -  |"
						Tacview.Log.Debug("TURN-RATE: Missing flag high/low value")
						goto continue
					end

					displayChart = sustainedChart 
					flagHighValue = flagHighValueSustained
					flagLowValue = flagLowValueSustained
				end

				if not displayChart[y][x] or displayChart[y][x]==0 then 
					chartData = chartData .. "  -  |" 
					goto continue 
				end

				local rate = math.floor(displayChart[y][x]*10)/10
				local stringRate = tostring(rate)
				if rate<10 then
					stringRate = " "..stringRate
				end
				
				if displayChart[y][x]>=flagHighValue then
					chartData = chartData .. " " .. GreenColor .. stringRate .. DefaultColor .. "|"
				elseif displayChart[y][x]<=flagLowValue then
					chartData = chartData .. " "..OrangeColor..stringRate ..DefaultColor.."|"
				else
					chartData = chartData .. " "..stringRate .."|"
				end
			end
			::continue::
		end -- for x = 0,xEntries-1 do
	end -- for y=yEntries-1,0,-1 do

	chartData = chartData .. "\n       " 

	for x = MachMin,MachMax+MachStep,MachStep do 

		chartData = chartData .. " " .. string.format("%.2f",x) .. " "

	end 

	chartData = chartData .. "\n\n                                              SPEED (Ma)"
	
	-- print chart
	
	Tacview.UI.Renderer.Print(chartDataTransform, chartDataRenderStateHandle, chartData)

end

function OnDrawTransparentUI()

	if not instantaneous and not sustained then
		return
	end

	DisplayBackground()

	DisplayChartData()

end

local instantaneousSettingName = "Instantaneous"
local instantaneousMenuId

local sustainedSettingName = "Sustained"
local sustainedMenuId

function OnInstantaneousRequested()

	-- Change the option

	instantaneous = not instantaneous

	-- Save it in the registry

	Tacview.AddOns.Current.Settings.SetBoolean(instantaneousSettingName, instantaneous)

	-- Update menu

	Tacview.UI.Menus.SetOption(instantaneousMenuId, instantaneous)

end

function OnSustainedRequested()

	-- Change the option

	sustained = not sustained

	-- Save it in the registry

	Tacview.AddOns.Current.Settings.SetBoolean(sustainedSettingName, sustained)

	-- Update menu

	Tacview.UI.Menus.SetOption(sustainedMenuId, sustained)

end

function OnDocumentLoaded()

	InitializeCharts()

end

function SetUnits()

	if Tacview.Settings.GetAltitudeUnit() == Tacview.Settings.Units.Feet then

		AltitudeMax = AltitudeMaxFeet
		AltitudeStep = AltitudeStepFeet
		yEntries = yEntriesFeet

	elseif Tacview.Settings.GetAltitudeUnit() == Tacview.Settings.Units.Meters then

		AltitudeMax = AltitudeMaxMeters
		AltitudeStep = AltitudeStepMeters
		yEntries = yEntriesMeters

	end
	
end

function OnPowerSaveOK()

	return done
	
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

	SetUnits()	

	currentAddOn.SetTitle("Turn Rate Report")
	currentAddOn.SetVersion("1.9.4.10")
	currentAddOn.SetAuthor("BuzyBee")
	currentAddOn.SetNotes("Display instantaneous or sustained turn rate as a function of altitude and speed")

	InitializeCharts()

	local mainMenuHandle = Tacview.UI.Menus.AddMenu(nil, "Turn Rate")

	instantaneous = Tacview.AddOns.Current.Settings.GetBoolean(instantaneousSettingName, instantaneous)
	sustained = Tacview.AddOns.Current.Settings.GetBoolean(sustainedSettingName, sustained)

	instantaneousMenuId = Tacview.UI.Menus.AddOption(mainMenuHandle, "Instantaneous", instantaneous, OnInstantaneousRequested)
	sustainedMenuId = Tacview.UI.Menus.AddOption(mainMenuHandle, "Sustained", sustained, OnSustainedRequested)

	-- Register callbacks

	Tacview.Events.Update.RegisterListener(OnUpdate)
	Tacview.Events.DrawTransparentUI.RegisterListener(OnDrawTransparentUI)
	Tacview.Events.DocumentLoaded.RegisterListener(OnDocumentLoaded)
	Tacview.Events.DocumentUnload.RegisterListener(OnDocumentLoaded)
	Tacview.Events.PowerSave.RegisterListener(OnPowerSaveOK)
	Tacview.Events.Shutdown.RegisterListener(OnShutdown) 
	
end

Initialize()
