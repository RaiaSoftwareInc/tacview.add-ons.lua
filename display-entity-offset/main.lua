
--[[
	Display Offset Entity
	Adds an object offset from the primary selected object.

	Author: BuzyBee
	Last update: 2022-11-29 (Tacview 1.8.8)

	Feel free to modify and improve this script!
--]]

--[[

	MIT License

	Copyright (c) 2022-2025 Raia Software Inc.

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

local Tacview = require("Tacview190")

----------------------------------------------------------------
-- Constants
----------------------------------------------------------------

local SettingName = "activated"

local DistanceBehind = 10 	-- in meters
local DistanceBelow = 1 	-- in meters

----------------------------------------------------------------
-- UI commands and options
----------------------------------------------------------------

local subMenuId
local activated = true

local offsetEntityHandle

function OnMenuActivateAddOn()

	if activated and offsetEntityHandle then
		Tacview.Telemetry.DeleteObject(offsetEntityHandle) 
		offsetEntityHandle = nil
	end

	-- Enable/disable add-on

	activated = not activated

	-- Save option value in registry
	
	Tacview.AddOns.Current.Settings.SetBoolean(SettingName, activated)

	-- Update menu with the new option value

	Tacview.UI.Menus.SetOption(subMenuId, activated)

end

function GetObjectId()

	local baseId = 0x72A030A380000000;
	local objectId = baseId;
	
	math.randomseed(os.time())
	math.random(1000000000)
	math.random(1000000000)
	math.random(1000000000)
	
	local rand = math.random(1000000000)
	
	objectId = objectId + rand
	
	return objectId

end

function GetCurrentTAS(objectHandle, absoluteTime)

	local calculationPeriod = 1.0	-- Calculate TAS over one second
	
	local lifetimeBegin, lifetimeEnd = Tacview.Telemetry.GetLifeTime( objectHandle )
	
	if absoluteTime - calculationPeriod < lifetimeBegin then
		return
	end

	local transform1, isTransform1Valid = Tacview.Telemetry.GetTransform(objectHandle, absoluteTime - calculationPeriod)
	local transform2, isTransform2Valid = Tacview.Telemetry.GetTransform(objectHandle, absoluteTime)

	if isTransform1Valid == true and isTransform2Valid == true then

		local distance = Tacview.Math.Vector.GetDistanceBetweenObjects(transform1, transform2)
		return distance / calculationPeriod

	end
end

function OnUpdate(dt, absoluteTime)

	-- Verify that the user wants to display the offset entity

	if not activated then
		
		if offsetEntityHandle then
			Tacview.Telemetry.DeleteObject(offsetEntityHandle) 
			offsetEntityHandle = nil
		end
		
		return
	end

	local selectedObjectHandle = Tacview.Context.GetSelectedObject(0)
	
	if not selectedObjectHandle then
		return
	end
	
	local speed = GetCurrentTAS(selectedObjectHandle,absoluteTime)
	
	if not speed or speed == 0 then
		return
	end
	
	local seconds = DistanceBehind / speed
	
	local timeShiftedTransform = Tacview.Telemetry.GetTransform(selectedObjectHandle, absoluteTime - seconds);
	
	--local fullyAdjustedTransform = {altitude = {altitude = timeShiftedTransform.altitude - DistanceBelow}}
	
	if not offsetEntityHandle then
	
		--local flag3DObjectHandle = Tacview.UI.Renderer.Load3DModel(Tacview.AddOns.Current.GetPath().. "flag.obj")

		--if not flag3DObjectHandle then
			--return
		--end	

		local objectId = GetObjectId()

		offsetEntityHandle = Tacview.Telemetry.GetCurrentOrCreateObjectHandle(objectId, absoluteTime)
		
		local shapePropertyIndex = Tacview.Telemetry.GetObjectsTextPropertyIndex("Shape", true)
		local typePropertyIndex = Tacview.Telemetry.GetObjectsTextPropertyIndex("Type", true)

		
		local shape, shapeSampleIsValid = Tacview.Telemetry.GetTextSample( selectedObjectHandle , absoluteTime , shapePropertyIndex )
		local objectType, typeSampleIsValid = Tacview.Telemetry.GetTextSample( selectedObjectHandle , absoluteTime , typePropertyIndex )
		
		Tacview.Telemetry.SetTextSample(offsetEntityHandle, absoluteTime, shapePropertyIndex, shape)
		Tacview.Telemetry.SetTextSample(offsetEntityHandle, absoluteTime, typePropertyIndex, objectType)
		
	end
	
	Tacview.UI.Renderer.Draw3DModel(offsetEntityHandle, timeShiftedTransform, 0x88ffffff)

	Tacview.Telemetry.SetTransform(offsetEntityHandle, Tacview.Context.GetAbsoluteTime(), timeShiftedTransform)
	Tacview.Telemetry.SetTransform(offsetEntityHandle, Tacview.Context.GetAbsoluteTime(), {altitude = timeShiftedTransform.altitude - DistanceBelow})	

end

function OnDocumentLoadedOrUnloaded()

	if offsetEntityHandle then
		Tacview.Telemetry.DeleteObject(offsetEntityHandle) 
		offsetEntityHandle = nil
	end
	
end

----------------------------------------------------------------
-- Initialize this addon
----------------------------------------------------------------

function Initialize()

	-- Declare add-on information

	Tacview.AddOns.Current.SetTitle("Display Offset Entity")
	Tacview.AddOns.Current.SetVersion("1.9.0")
	Tacview.AddOns.Current.SetAuthor("BuzyBee")
	Tacview.AddOns.Current.SetNotes("Displays an object at some offset from the selected object.")

	-- Load user preferences 
	-- The variable activated already contain the default setting

	activated = Tacview.AddOns.Current.Settings.GetBoolean(SettingName, activated)

	-- Declare menus
	-- Create a main menu "Offset Entity"
	-- Then insert in it an option to enable or disable the display of the offset object

	local mainMenuId = Tacview.UI.Menus.AddMenu(nil, "Offset Entity")
	subMenuId = Tacview.UI.Menus.AddOption(mainMenuId, "Activate", activated, OnMenuActivateAddOn)

	-- Register callbacks

	Tacview.Events.Update.RegisterListener(OnUpdate);

	Tacview.Events.DocumentLoaded.RegisterListener(OnDocumentLoadedOrUnloaded)
	Tacview.Events.DocumentUnload.RegisterListener(OnDocumentLoadedOrUnloaded)

end 
	
Initialize()
