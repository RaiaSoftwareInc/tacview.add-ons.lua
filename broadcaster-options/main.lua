
--[[
	Broadcaster Options

	Author: BuzyBee
	Last update: 2026-05-15 (Tacview 1.9.5)

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

-- Request Tacview API

local Tacview = require("Tacview195")

local splinePoints = {}

local renderStateHandle

function OnDeleteVehicles()

	local objectHandles = {}

	local count = Tacview.Telemetry.GetObjectCount()
	
	for index=0,count-1 do

		objectHandles[#objectHandles+1] = Tacview.Telemetry.GetObjectHandleByIndex(index) 
	end

	for index = #objectHandles, 1, -1 do

		local objectHandle = objectHandles[index]

		if objectHandle then

			local objectTags = Tacview.Telemetry.GetCurrentTags(objectHandle) 
	
			if objectTags then
		
				if Tacview.Telemetry.AnyGivenTagActive(objectTags, Tacview.Telemetry.Tags.Vehicle) then
	
					Tacview.Telemetry.DeleteObject( objectHandle )
				end
			end
		end
	end

	Tacview.UI.Update()

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

function OnAddSplines()

	splinePoints = {}

	local gates = GetGatesInfo()

	BuildSpline(gates)
	
end

function GetGatesInfo()

	local gates = {}

	local pilotNamePropertyIndex = Tacview.Telemetry.GetObjectsTextPropertyIndex("Pilot", false)

	if pilotNamePropertyIndex == Tacview.Telemetry.InvalidPropertyIndex then
		Tacview.UI.Warning("Unable to add splines because of missing Pilot property")
		return
	end

	local namePropertyIndex = Tacview.Telemetry.GetObjectsTextPropertyIndex("Name", false)

	if namePropertyIndex == Tacview.Telemetry.InvalidPropertyIndex then
		Tacview.UI.Warning("Unable to add splines because of missing Name property")
		return
	end

	local count = Tacview.Telemetry.GetObjectCount()
	local absoluteTime = Tacview.Context.GetAbsoluteTime()

	for index = 0, count - 1 do

		local objectHandle = Tacview.Telemetry.GetObjectHandleByIndex(index)

		if objectHandle then

			local objectTags = Tacview.Telemetry.GetCurrentTags(objectHandle)

			if objectTags and Tacview.Telemetry.AnyGivenTagActive(objectTags, Tacview.Telemetry.Tags.Building) then

				local pilot = Tacview.Telemetry.GetTextSample(objectHandle, absoluteTime, pilotNamePropertyIndex)
				local name = Tacview.Telemetry.GetTextSample(objectHandle, absoluteTime, namePropertyIndex)
				local transform = Tacview.Telemetry.GetCurrentTransform(objectHandle)

				if pilot and name and transform then

					if string.match(pilot, "Finish Gate") then
						
						local gateHeight = 62.98 -- the actual height of the gate object

						local adjustedAltitudeForSpline = Tacview.Terrain.GetElevation(transform.longitude, transform.latitude) + 0.5 * gateHeight

						local gateCenterCartesianForSpline =
							Tacview.Math.Vector.LongitudeLatitudeToCartesian({
								longitude = transform.longitude,
								latitude = transform.latitude,
								altitude = adjustedAltitudeForSpline
							})

						gates["Finish Gate"] = {
							x = gateCenterCartesianForSpline.x,
							y = gateCenterCartesianForSpline.y,
							z = gateCenterCartesianForSpline.z
						}

					else

						local altitude = string.match(name, "(%d+)ft")

						if altitude then

							altitude = Tacview.Math.Units.FeetToMeters(altitude)

							local adjustedAltitudeForSpline =
								Tacview.Terrain.GetElevation(transform.longitude, transform.latitude) + altitude

							local gateCenterCartesianForSpline =
								Tacview.Math.Vector.LongitudeLatitudeToCartesian({
									longitude = transform.longitude,
									latitude = transform.latitude,
									altitude = adjustedAltitudeForSpline
								})

							for gateNumberText in string.gmatch(pilot, "%d+") do

								local gateNumber = tonumber(gateNumberText)

								if gateNumber then
									gates[gateNumber] = {
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
		end
	end

	return gates
end

function OnDrawOpaqueObjects()

	local renderState = {}

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
end

function BuildSpline(gates)

	local orderedGates = {}

	for gateNumber = 1, 100 do

		if gates[gateNumber] then

			orderedGates[#orderedGates + 1] = gates[gateNumber]
		end
	end

	if gates["Finish Gate"] then 

		orderedGates[#orderedGates + 1] = gates["Finish Gate"]
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

----------------------------------------------------------------
-- Add-on initialization
----------------------------------------------------------------

function Initialize()

	-- Declare add-on information

	Tacview.AddOns.Current.SetTitle("Broadcaster Options")
	Tacview.AddOns.Current.SetVersion("1.9.5")
	Tacview.AddOns.Current.SetAuthor("BuzyBee")
	Tacview.AddOns.Current.SetNotes("Options for broadcasters.")

	local mainMenuHandle = Tacview.UI.Menus.AddMenu(nil, "Broadcaster Options")
	local deleteVehiclesMenuHandle = Tacview.UI.Menus.AddCommand(mainMenuHandle, "Delete Vehicles", OnDeleteVehicles)
	local addSplinesMenuHandle = Tacview.UI.Menus.AddCommand(mainMenuHandle, "Add Splines", OnAddSplines)

	Tacview.Events.DrawOpaqueObjects.RegisterListener(OnDrawOpaqueObjects)
	Tacview.Events.Shutdown.RegisterListener(OnShutdown) 
end

Initialize()