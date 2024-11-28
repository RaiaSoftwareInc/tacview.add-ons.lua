
--[[
	Display 3D Avatar
	Displays an avatar in the form of a 3d object

	Author: BuzyBee
	Last update: 2022-09-22 (Tacview 1.8.8)

	Feel free to modify and improve this script!
--]]

--[[

	MIT License

	Copyright (c) 2022 Raia Software Inc.

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

local Display3dAvatarSettingName = "display3dAvatar"

----------------------------------------------------------------
-- UI commands and options
----------------------------------------------------------------

local display3dAvatarMenuId
local display3dAvatar = true

function OnMenuEnableAddOn()

	-- Enable/disable add-on

	display3dAvatar = not display3dAvatar

	-- Save option value in registry
	
	Tacview.AddOns.Current.Settings.SetBoolean(Display3dAvatarSettingName, display3dAvatar)

	-- Update menu with the new option value

	Tacview.UI.Menus.SetOption(display3dAvatarMenuId, display3dAvatar)

end

----------------------------------------------------------------
-- Main loop
----------------------------------------------------------------

-- Update is called once a frame by Tacview

function OnDrawOpaqueObjects()

	-- Verify that the user wants to display a 3d avatar

	if not display3dAvatar then
		return
	end

	-- Load the .OBJ file
	
	local avatarObjectHandle = Tacview.UI.Renderer.Load3DModel(Tacview.AddOns.Current.GetPath().."die.obj")
	
	if not avatarObjectHandle then
		return
	end
	
	-- Draw the avatar 50 m above the primary selected object.
	
	local selectedObjectHandle = Tacview.Context.GetSelectedObject(0)
	
	if not selectedObjectHandle then
		return
	end
			
	local objectTransform = Tacview.Telemetry.GetCurrentTransform(selectedObjectHandle);
	
	if not objectTransform then
		return
	end
		
	local avatarTransform =
	{
		longitude=objectTransform.longitude, latitude=objectTransform.latitude,  altitude=objectTransform.altitude+50,
	};
		
	Tacview.UI.Renderer.Draw3DModel(avatarObjectHandle, avatarTransform, 0xffff0000)	
end

----------------------------------------------------------------
-- Initialize this addon
----------------------------------------------------------------

function Initialize()

	-- Declare add-on information

	Tacview.AddOns.Current.SetTitle("Display Avatar (3D)")
	Tacview.AddOns.Current.SetVersion("1.8.8")
	Tacview.AddOns.Current.SetAuthor("BuzyBee")
	Tacview.AddOns.Current.SetNotes("Displays a 3D object as an avatar of the selected object.")

	-- Load user preferences
	-- The variable display3dAvatar already contain the default setting

	display3dAvatar = Tacview.AddOns.Current.Settings.GetBoolean(Display3dAvatarSettingName, display3dAvatar)

	-- Declare menus
	-- Create a main menu "Avatar (3D)"
	-- Then insert in it an option to display or not the avatar

	local mainMenuId = Tacview.UI.Menus.AddMenu(nil, "Avatar (3D)")
	display3dAvatarMenuId = Tacview.UI.Menus.AddOption(mainMenuId, "Display Avatar (3D)", display3dAvatar, OnMenuEnableAddOn)

	-- Register callbacks

	Tacview.Events.DrawTransparentObjects.RegisterListener(OnDrawOpaqueObjects);

end

Initialize()
