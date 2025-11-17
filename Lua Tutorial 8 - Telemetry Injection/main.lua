
-- Telemetry Injection tutorial for Tacview
-- Author: Frantz 'Vyrtuoz' RAIA
-- Last update: 2020-11-09 (Tacview 1.8.5)

-- Feel free to modify and improve this script!

--[[

MIT License

Copyright (c) 2018-2025 Raia Software Inc.

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

require("LuaStrict")

local Tacview = require("Tacview180")

----------------------------------------------------------------
-- Tools & Constants
----------------------------------------------------------------

local WaypointType = "Navaid+Static+Waypoint"

-- We use Telemetry.BeginningOfTime because waypoints are timeless objects.

local WaypointTime = Tacview.Telemetry.BeginningOfTime

-- Conversion

function FeetToMeters(feetValue)

	return feetValue / 3.2808

end

-- Create waypoints from given list

function CreateWaypoints(waypointList, color)

	-- Retrieve properties indexes (create corresponding property if required)

	local namePropertyIndex = Tacview.Telemetry.GetObjectsTextPropertyIndex("Name", true)
	local typePropertyIndex = Tacview.Telemetry.GetObjectsTextPropertyIndex("Type", true)
	local nextPropertyIndex = Tacview.Telemetry.GetObjectsTextPropertyIndex("Next", true)
	local colorPropertyIndex = Tacview.Telemetry.GetObjectsTextPropertyIndex("Color", true)

	-- First object id (free 64-bit non zero integer)

	for _,waypoint in pairs(waypointList) do

		-- Waypoint id

		local waypointId = waypoint[1]

		-- Create a new object (or retrieve existing one if already created)

		local objectHandle = Tacview.Telemetry.GetOrCreateObjectHandle(waypointId, WaypointTime)

		if objectHandle then

			-- Define waypoint position

			local transform =
			{
				longitude = math.rad(waypoint[4]),
				latitude = math.rad(waypoint[3]),
				altitude = FeetToMeters(waypoint[5]),
			}

			Tacview.Telemetry.SetTransform(objectHandle, WaypointTime, transform)

			-- Set waypoint properties

			Tacview.Telemetry.SetTextSample(objectHandle, WaypointTime, namePropertyIndex, waypoint[2])
			Tacview.Telemetry.SetTextSample(objectHandle, WaypointTime, typePropertyIndex, WaypointType)

			-- Link with the next waypoint
			-- NOTE: next waypoint id must be injected as a hexadecimal number in a text property

			local nextWaypointId = waypoint[6]

			if nextWaypointId then
				Tacview.Telemetry.SetTextSample(objectHandle, WaypointTime, nextPropertyIndex, string.format("%x", nextWaypointId))
			end

			-- Set waypoint color (if any provided)

			if color then
				Tacview.Telemetry.SetTextSample(objectHandle, WaypointTime, colorPropertyIndex, color)
			end
		end
	end
end

-- Delete waypoints based on their IDs

function DeleteWaypoints(waypointList)

	-- First object id (free 64-bit non zero integer)

	for _,waypoint in pairs(waypointList) do

		-- Waypoint id

		local waypointId = waypoint[1]

		-- Find waypoint by id

		local objectHandle = Tacview.Telemetry.GetCurrentObjectHandle(waypointId)

		if objectHandle then

			-- Delete waypoint

			Tacview.Telemetry.DeleteObject(objectHandle)
		end
	end
end

----------------------------------------------------------------
-- Menu option to purge all loaded telemetry
----------------------------------------------------------------

function OnPurgeTelemetry()

	if Tacview.UI.MessageBox.Question("Are you sure you want to purge all currently loaded telemetry?") == Tacview.UI.MessageBox.OK then

		Tacview.Telemetry.Clear()

	end
end

----------------------------------------------------------------
-- Menu option to create waypoints over France
----------------------------------------------------------------

local frenchWaypointList =
{
	-- id, name, latitude, longitude, altitude (feet), nextId

	{0x10001, "LFBD", 44.83667, -0.7255556, 166.0, 0x10002},
	{0x10002, "BD", 44.93972, -0.5708333, 3000.0, 0x10003},
	{0x10003, "BE", 44.87222, -0.4066667, 3000.0, 0x10004},
	{0x10004, "DIRAX", 44.55306, -0.4627778, 3000.0, 0x10005},
	{0x10005, "LFCH", 44.60611, -1.123056, 52.0, nil},
}

function OnCreateFrenchWaypoints()

	CreateWaypoints(frenchWaypointList)

end

----------------------------------------------------------------
-- Menu option to delete waypoints over France
----------------------------------------------------------------

function OnDeleteFrenchWaypoints()

	DeleteWaypoints(frenchWaypointList)

end

----------------------------------------------------------------
-- Menu option to create waypoints over the US
----------------------------------------------------------------

function OnCreateGreatCircleWaypoints()

	-- from https://flightaware.com/live/flight/THY35/history/20181030/1255Z/LTBA/CYUL/tracklog

	local waypointList =
	{
		-- id, name, latitude, longitude, altitude (feet), nextId

		{0x20001, "LTBA", 40.9844, 28.8090, 163, 0x20002},
		{0x20002, "1400Z", 45.6059, 25.1836, 34000, 0x20003},
		{0x20003, "1500Z", 52.6777, 17.8474, 35975, 0x20004},
		{0x20004, "1600Z", 58.8200, 6.4469, 36000, 0x20005},
		{0x20005, "1700Z", 63.2711, -7.7375, 36000, 0x20006},
		{0x20006, "1800Z", 65.5921, -24.6585, 36000, 0x20007},
		{0x20007, "1900Z", 64.5063, -42.0502, 36000, 0x20008},
		{0x20008, "2000Z", 61.9500, -56.7667, 38000, 0x20009},
		{0x20009, "2100Z", 55.4333, -63.5833, 39000, 0x2000A},
		{0x2000A, "2200Z", 48.8096, -68.6912, 38975, 0x2000B},
		{0x2000B, "2230Z", 46.1349, -72.2708, 19875, 0x2000C},
		{0x2000C, "CUYL", 45.5069, -73.7051, 650, nil},
	}

	CreateWaypoints(waypointList, "Orange" )

end

----------------------------------------------------------------
-- Initialize this addon
----------------------------------------------------------------

function Initialize()

	-- Declare addon properties

	local currentAddOn = Tacview.AddOns.Current

	currentAddOn.SetTitle("Lua Tutorial 8 - Telemetry Injection")
	currentAddOn.SetVersion("1.8.5")
	currentAddOn.SetAuthor("Vyrtuoz")
	currentAddOn.SetNotes("Shows how to create/delete objects and how to set their properties via the telemetry API.")

	-- Declare menus

	local addOnMenuId = Tacview.UI.Menus.AddMenu(nil, "Telemetry Injection")

	Tacview.UI.Menus.AddCommand(addOnMenuId, "Create Waypoints in France", OnCreateFrenchWaypoints)
	Tacview.UI.Menus.AddCommand(addOnMenuId, "Delete Waypoints in France", OnDeleteFrenchWaypoints)
	Tacview.UI.Menus.AddSeparator(addOnMenuId)
	Tacview.UI.Menus.AddCommand(addOnMenuId, "Create LTBA->CYUL Great Circle Waypoints", OnCreateGreatCircleWaypoints)
	Tacview.UI.Menus.AddSeparator(addOnMenuId)
	Tacview.UI.Menus.AddCommand(addOnMenuId, "Purge Telemetry...", OnPurgeTelemetry)
end

Initialize()
