
--[[
	Lock Camera

	Author: BuzyBee
	Last update: 2024-04-22 (Tacview 1.9.4)

	Feel free to modify and improve this script!
--]]

--[[

	MIT License

	Copyright (c) 2024-2025 Raia Software Inc.

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

local Tacview = require("Tacview194")

local cameraLocked = false

local mode
local longitude
local latitude
local altitude
local roll
local pitch
local yaw
local range

function OnContextMenu(contextMenuId, objectHandle, mouseLongitude, mouseLatitude, mouseAltitude)

	if cameraLocked then

		Tacview.UI.Menus.AddCommand(contextMenuId, "Release Camera", OnCameraLock)

	else

		Tacview.UI.Menus.AddCommand(contextMenuId, "Lock Camera", OnCameraLock)

	end	
end

function OnCameraLock()

	cameraLocked = not cameraLocked
	
	if cameraLocked then 
	
		mode = Tacview.Settings.GetString("UI.View.Camera.Mode")
		longitude, latitude, altitude =  Tacview.Context.Camera.GetSphericalPosition()
		roll, pitch, yaw = Tacview.Context.Camera.GetRotation()
		range = Tacview.Context.Camera.GetRangeToTarget()

		print("Camera locked")
		
	else
	
		print("Camera released")
		
	end	
end

function OnUpdate(dt, absoluteTime)

	if cameraLocked then
		if mode and longitude and latitude and altitude and roll and pitch and yaw then
			Tacview.Settings.SetString("UI.View.Camera.Mode", mode)
			Tacview.Context.Camera.SetSphericalPosition(longitude , latitude , altitude)
			Tacview.Context.Camera.SetRotation(roll, pitch, yaw)
			Tacview.Context.Camera.SetRangeToTarget(range)
		else
			print("Missing information, unable to lock camera")
		end
	end
end

----------------------------------------------------------------
-- Add-on initialization
----------------------------------------------------------------

function Initialize()

	-- Declare add-on information

	Tacview.AddOns.Current.SetTitle("Lock Camera")
	Tacview.AddOns.Current.SetVersion("1.9.4")
	Tacview.AddOns.Current.SetAuthor("BuzyBee")
	Tacview.AddOns.Current.SetNotes("Lock Camera Position")

	Tacview.UI.Renderer.ContextMenu.RegisterListener(OnContextMenu)
	Tacview.Events.Update.RegisterListener(OnUpdate)

end

Initialize()


