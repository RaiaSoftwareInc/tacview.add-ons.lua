
--[[
	Broadcast Tools

	Author: BuzyBee
	Last update: 2026-05-20 (Tacview 1.9.5)

	Feel free to modify and improve this script!
--]]

--[[

	MIT License

	Copyright (c) 2026 Raia Software Inc.

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

require("lua-strict")

local autoDeleteDownSettingName = "Auto Delete Gate Vehicles"
local showLineSettingName = "Show Racing Line"

local autoDeleteMenuHandle
local showLineMenuHandle

local autoDelete = false
local showLine = false

local showLineDone = false
local autoDeleteDone = false

-- Request Tacview API

local Tacview = require("Tacview195")

local splinePoints = {}

local renderStateHandle

function OnAutoDeleteGateVehicles()

	autoDelete = not autoDelete

	Tacview.AddOns.Current.Settings.SetBoolean(autoDeleteDownSettingName, autoDelete ) 

	Tacview.UI.Menus.SetOption(autoDeleteMenuHandle, autoDelete ) 
end

function OnShowRacingLine()

	showLine = not showLine

	Tacview.AddOns.Current.Settings.SetBoolean(showLineSettingName, showLine ) 

	Tacview.UI.Menus.SetOption(showLineMenuHandle, showLine ) 
end

function OnUpdate(dt, absoluteTime )

	if autoDelete and not autoDeleteDone then
		
		local objectHandles = {}
	
		local count = Tacview.Telemetry.GetObjectCount()
		
		for index=0,count-1 do
	
			objectHandles[#objectHandles+1] = Tacview.Telemetry.GetObjectHandleByIndex(index) 
		end
	
		for index = #objectHandles, 1, -1 do
	
			local objectHandle = objectHandles[index]
	
			if objectHandle then

				local pilotNamePropertyIndex = Tacview.Telemetry.GetObjectsTextPropertyIndex("Pilot", false)
	
				if pilotNamePropertyIndex == Tacview.Telemetry.InvalidPropertyIndex then
					
					Tacview.UI.Warning("Unable to delete gate dummies because of missing information")
					
					return
				end	

				local pilot = Tacview.Telemetry.GetTextSample(objectHandle, absoluteTime, pilotNamePropertyIndex)

				pilot = string.lower(pilot)

				if pilot and string.match(pilot, "dummy") then

					Tacview.Telemetry.DeleteObject(objectHandle)
				end		
			end
		end

		autoDeleteDone = true
	
		Tacview.UI.Update()
	end
	
	if showLine and not showLineDone then

		splinePoints = {}
	
		local gates = GetGatesInfo()
	
		BuildSpline(gates)

		showLineDone = true
	end
end

local function CatmullRom(p0, p1, p2, p3, t)

    local t2 = t * t
    local t3 = t2 * t

    return
    {
        x = 0.5 * (
            2 * p1.x +
            (-p0.x + p2.x) * t +
            (2*p0.x - 5*p1.x + 4*p2.x - p3.x) * t2 +
            (-p0.x + 3*p1.x - 3*p2.x + p3.x) * t3
        ),

        y = 0.5 * (
            2 * p1.y +
            (-p0.y + p2.y) * t +
            (2*p0.y - 5*p1.y + 4*p2.y - p3.y) * t2 +
            (-p0.y + 3*p1.y - 3*p2.y + p3.y) * t3
        ),

        z = 0.5 * (
            2 * p1.z +
            (-p0.z + p2.z) * t +
            (2*p0.z - 5*p1.z + 4*p2.z - p3.z) * t2 +
            (-p0.z + 3*p1.z - 3*p2.z + p3.z) * t3
        )
    }
end

local function GetGateSortKeys(pilot)

	local gateSortKeys = {}

	if not pilot then
		return gateSortKeys
	end

	local lowerPilot = string.lower(pilot)

	if string.match(lowerPilot, "finish%s*gate") then
		gateSortKeys[#gateSortKeys + 1] = 999
	end

	for numberText, suffix in string.gmatch(lowerPilot, "(%d+)%s*([a-z]*)") do

		print("numberText: " .. numberText)
		print("suffix: " .. suffix)

		local gateNumber = tonumber(numberText)

		if gateNumber then

			local suffixValue = 0

			if suffix == "pup" then

				suffixValue = 99

			elseif suffix and suffix ~= "" then

				local firstLetter = string.byte(suffix, 1)

				if firstLetter >= string.byte("a") and firstLetter <= string.byte("z") then
					suffixValue = firstLetter - string.byte("a") + 1
				end
			end

			gateSortKeys[#gateSortKeys + 1] = gateNumber * 100 + suffixValue
		end
	end

	for k,v in ipairs(gateSortKeys) do
		print("gateSortKey: " .. v)
	end

	return gateSortKeys
end

function GetGatesInfo()

	local gates = {}

	local pilotNamePropertyIndex = Tacview.Telemetry.GetObjectsTextPropertyIndex("Pilot", false)

	if pilotNamePropertyIndex == Tacview.Telemetry.InvalidPropertyIndex then
		Tacview.UI.Warning("Unable to add racing line because of missing information")
		return
	end

	local namePropertyIndex = Tacview.Telemetry.GetObjectsTextPropertyIndex("Name", false)

	if namePropertyIndex == Tacview.Telemetry.InvalidPropertyIndex then
		Tacview.UI.Warning("Unable to add racing line because of missing information")
		return
	end

	local count = Tacview.Telemetry.GetObjectCount()
	local absoluteTime = Tacview.Context.GetAbsoluteTime()

	for index = 0, count - 1 do

		local objectHandle = Tacview.Telemetry.GetObjectHandleByIndex(index)

		if objectHandle then

			local objectTags = Tacview.Telemetry.GetCurrentTags( objectHandle )

			if objectTags then 

				if Tacview.Telemetry.AnyGivenTagActive(objectTags ,Tacview.Telemetry.Tags.Building) then

					local pilot = Tacview.Telemetry.GetTextSample(objectHandle, absoluteTime, pilotNamePropertyIndex)
					pilot = string.lower(pilot)

					local name = Tacview.Telemetry.GetTextSample(objectHandle, absoluteTime, namePropertyIndex)
					name = string.lower(name)
					
					local transform = Tacview.Telemetry.GetCurrentTransform(objectHandle)

					if pilot and string.match(name, "gate") and transform then
			
						local altitude = string.match(name, "(%d+)ft")

						if not altitude then
							altitude = 0
						end
			
						altitude = Tacview.Math.Units.FeetToMeters(altitude)
			
						local adjustedAltitudeForSpline = Tacview.Terrain.GetElevation(transform.longitude, transform.latitude) + altitude
				
						local gateCenterCartesianForSpline =
							Tacview.Math.Vector.LongitudeLatitudeToCartesian({
								longitude = transform.longitude,
								latitude = transform.latitude,
								altitude = adjustedAltitudeForSpline
							})
				
						local gateSortKeys = GetGateSortKeys(pilot)
		
						for _, gateSortKey in ipairs(gateSortKeys) do
		
							gates[gateSortKey] = {
								x = gateCenterCartesianForSpline.x,
								y = gateCenterCartesianForSpline.y,
								z = gateCenterCartesianForSpline.z
							}
						end
					end
				end
			end
		end
	end

	return gates
end

function OnDrawOpaqueObjects()

	local renderState = { color = 0xFFA0FF46, blendMode = Tacview.UI.Renderer.BlendMode.Additive}

	if not renderStateHandle then
		renderStateHandle = Tacview.UI.Renderer.CreateRenderState(renderState)
	end

	Tacview.UI.Renderer.DrawLineStrip(renderStateHandle, 2, splinePoints ) -- Tacview 1.8.4
end

function OnShutdown()

	if renderStateHandle then
		Tacview.UI.Renderer.ReleaseRenderState( renderStateHandle ) 
	end

	splinePoints = {}

	autoDeleteDone = false
	showLineDone = false
end

function BuildSpline(gates)

	local orderedKeys = {}

	for key, gate in pairs(gates) do
		print(key)
		orderedKeys[#orderedKeys + 1] = key
	end

	table.sort(orderedKeys)

	local orderedGates = {}

	for _, key in ipairs(orderedKeys) do
		orderedGates[#orderedGates + 1] = gates[key]
	end

	local numberOfSteps = 10

	for i = 1, #orderedGates - 1 do

		local p0 = orderedGates[math.max(i - 1, 1)]
		local p1 = orderedGates[i]
		local p2 = orderedGates[i + 1]
		local p3 = orderedGates[math.min(i + 2, #orderedGates)]

		for step = 0, numberOfSteps do

			local t = step / numberOfSteps

			local point = CatmullRom(p0, p1, p2, p3, t)

			splinePoints[#splinePoints + 1] = {point.x, point.y, point.z}
		end
	end

	return splinePoints
end

function OnDocumentLoaded()

	splinePoints = {}

	autoDeleteDone = false
	showLineDone = false
end

----------------------------------------------------------------
-- Add-on initialization
----------------------------------------------------------------

function Initialize()

	-- Declare add-on information

	Tacview.AddOns.Current.SetTitle("Broadcast Tools")
	Tacview.AddOns.Current.SetVersion("1.9.5")
	Tacview.AddOns.Current.SetAuthor("BuzyBee")
	Tacview.AddOns.Current.SetNotes("Tools for broadcasts.")

	autoDelete = Tacview.AddOns.Current.Settings.GetBoolean(autoDeleteDownSettingName, false) 
	showLine = Tacview.AddOns.Current.Settings.GetBoolean(showLineSettingName, false) 

	local mainMenuHandle = Tacview.UI.Menus.AddMenu(nil, "Broadcast Tools")
	autoDeleteMenuHandle = Tacview.UI.Menus.AddOption(mainMenuHandle, "Auto Delete Gates Vehicles", autoDelete, OnAutoDeleteGateVehicles)
	showLineMenuHandle = Tacview.UI.Menus.AddOption(mainMenuHandle, "Show Racing Line", showLine, OnShowRacingLine)

	Tacview.Events.DrawOpaqueObjects.RegisterListener(OnDrawOpaqueObjects)
	Tacview.Events.Shutdown.RegisterListener(OnShutdown) 
	Tacview.Events.Update.RegisterListener(OnUpdate)
	Tacview.Events.DocumentLoaded.RegisterListener(OnDocumentLoaded)

end

Initialize()