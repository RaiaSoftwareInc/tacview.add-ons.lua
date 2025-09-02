
--[[
	Head-On Camera

	Author: BuzyBee
	Last update: 2025-08-19 (Tacview 1.9.4)

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

CAMERA_LATERAL_OFFSET = 10		--meters_positive_to_the_right,
CAMERA_LONGITUDINAL_OFFSET = 0 	--meters_positive_forward,
CAMERA_VERTICAL_OFFSET = 10 	--meters_positive_up,

-- Request Tacview API

local Tacview = require("Tacview194")

local headOnCameraEnabled = false

local headOnCameraEnabledSettingPath = "Head On Camera Enabled"

function OnContextMenu(contextMenuId, objectHandle, mouseLongitude, mouseLatitude, mouseAltitude)

	if headOnCameraEnabled then

		Tacview.UI.Menus.AddCommand(contextMenuId, "Release Head-On Camera", OnHeadOnCamera)

	else

		Tacview.UI.Menus.AddCommand(contextMenuId, "Enable Head-On Camera", OnHeadOnCamera)

	end	
end

function OnHeadOnCamera()

	if not headOnCameraEnabled then 
		
		headOnCameraEnabled = true

		Tacview.Log.Info("Head-on camera enabled.")
		
	else

		headOnCameraEnabled = false
	
		Tacview.Log.Info("Head-on camera released.")
		
	end	

	Tacview.AddOns.Current.Settings.SetBoolean(headOnCameraEnabledSettingPath, headOnCameraEnabled)
	
end

function OnUpdate(dt, absoluteTime)

	if headOnCameraEnabled then

		local selectedObjectHandle = Tacview.Context.GetSelectedObject(0)

		if not selectedObjectHandle then
			return
		end

		local selectedObjectTransform = Tacview.Telemetry.GetCalculatedTransform(selectedObjectHandle, absoluteTime)

		if not selectedObjectTransform then
			return
		end

		local cameraCoordinatesCartesian = Tacview.Math.Vector.LocalToGlobal( selectedObjectTransform , {x = 0,y = 0,z = -100} )
		local cameraTransform = Tacview.Math.Vector.CartesianToLongitudeLatitude(cameraCoordinatesCartesian)

		Tacview.Settings.SetString("UI.View.Camera.Mode", "External") 
		
		Tacview.Context.Camera.SetSphericalPosition(cameraTransform.longitude, cameraTransform.latitude, cameraTransform.altitude)

		local roll = selectedObjectTransform.roll
		local pitch = selectedObjectTransform.pitch
		local yaw = selectedObjectTransform.yaw

		if selectedObjectTransform.roll and selectedObjectTransform.pitch and selectedObjectTransform.yaw then

			Tacview.Context.Camera.SetRotation(-selectedObjectTransform.roll, -selectedObjectTransform.pitch, selectedObjectTransform.yaw + math.rad(180))

		else

			local track = Tacview.Telemetry.GetCurrentTrack(selectedObjectHandle )

			if not track then 
				return 
			end

			Tacview.Context.Camera.SetRotation(0,0, track + math.rad(180))
		end

		Tacview.Context.Camera.SetOffset(	
		{
			lateral = CAMERA_LATERAL_OFFSET,
			longitudinal = CAMERA_LONGITUDINAL_OFFSET,
			vertical = CAMERA_VERTICAL_OFFSET ,
			roll = 0,
			pitch = 0 ,
			yaw = 0,
		})

	end
end

function OnShutdown()

	Tacview.Context.Camera.SetRotation(0,0,0)
	Tacview.Context.Camera.SetOffset(0,0,0,0,0,0)

end

----------------------------------------------------------------
-- Add-on initialization
----------------------------------------------------------------

function Initialize()

	-- Declare add-on information

	Tacview.AddOns.Current.SetTitle("Head-On Camera")
	Tacview.AddOns.Current.SetVersion("1.9.4")
	Tacview.AddOns.Current.SetAuthor("BuzyBee")
	Tacview.AddOns.Current.SetNotes("Place the camera head-on to the selected aircraft.")

	headOnCameraEnabled = Tacview.AddOns.Current.Settings.GetBoolean(headOnCameraEnabledSettingPath, false)

	Tacview.UI.Renderer.ContextMenu.RegisterListener(OnContextMenu)
	Tacview.Events.Update.RegisterListener(OnUpdate)
	Tacview.Events.Shutdown.RegisterListener(OnShutdown) 

end

Initialize()
