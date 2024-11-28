
--[[
	Display Avatar
	Displays an avatar for the selected object

	Author: BuzyBee
	Last update: 2022-09-22 (Tacview 1.9.0)

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

local DisplayAvatarSettingName = "displayAvatar"

local GlobalScale = 1

local AvatarWidth = 64 * GlobalScale

----------------------------------------------------------------
-- "Members"
----------------------------------------------------------------

local currentAoAUnits

local avatarTextureHandle
local avatarVertexArrayHandle
local avatarRenderStateHandle
local avatarTextureCoordinateArrayHandle

----------------------------------------------------------------
-- UI commands and options
----------------------------------------------------------------

local displayAvatarMenuId
local displayAvatar = true

function OnMenuEnableAddOn()

	-- Enable/disable add-on

	displayAvatar = not displayAvatar

	-- Save option value in registry
	
	Tacview.AddOns.Current.Settings.SetBoolean(DisplayAvatarSettingName, displayAvatar)

	-- Update menu with the new option value

	Tacview.UI.Menus.SetOption(displayAvatarMenuId, displayAvatar)

end

----------------------------------------------------------------
-- Load and compile any resource required to draw the avatar
----------------------------------------------------------------

function DeclareRenderData()

	-- Load the background texture as required

	if not avatarTextureHandle then

		local addOnPath = Tacview.AddOns.Current.GetPath()
		
		avatarTextureHandle = Tacview.UI.Renderer.LoadTexture(addOnPath.."textures/avatar.jpg", false)
		
	end

	-- Declare the render state for the avatar.
	-- The render state is used to define how to draw our 2D models.

	if not avatarRenderStateHandle then

		local renderState =
		{
			texture = avatarTextureHandle,
		}
		
		avatarRenderStateHandle = Tacview.UI.Renderer.CreateRenderState(renderState)
		
	end

	-- The following list of vertices is used to define the square shape of the avatar using two triangles.

	if not avatarVertexArrayHandle then

		local HalfWidth = AvatarWidth / 2
		local HalfHeight = AvatarWidth / 2

		local vertexArray =
		{
			-HalfWidth, HalfHeight, 0.0,
			-HalfWidth, -HalfHeight, 0.0,
			HalfWidth, -HalfHeight, 0.0,
			-HalfWidth, HalfHeight, 0.0,
			HalfWidth, HalfHeight, 0.0,
			HalfWidth, -HalfHeight, 0.0,
		}
		
		avatarVertexArrayHandle = Tacview.UI.Renderer.CreateVertexArray(vertexArray)
	end
	
	-- Declare the textures coordinates to project the image on a rectangle made of two triangles.

	if not avatarTextureCoordinateArrayHandle then

		local baseTextureArray =
		{
			0.0, 0.0,
			0.0, 1.0,
			1.0, 1.0,
			0.0, 0.0,
			1.0, 0.0,
			1.0, 1.0,
		}
		
		avatarTextureCoordinateArrayHandle = Tacview.UI.Renderer.CreateTextureCoordinateArray(baseTextureArray)
		
	end
end

----------------------------------------------------------------
-- Draw the avatar during transparent UI rendering pass
----------------------------------------------------------------

function OnDrawTransparentUI()

	if not displayAvatar then
		return
	end
	
	local selectedObjectHandle = Tacview.Context.GetSelectedObject(0)
	
	if not selectedObjectHandle then
		return
	end
	
	DeclareRenderData()
	
	-- Draw Avatar
	
	local px,py = Tacview.UI.Renderer.GetProjectedPosition(selectedObjectHandle)
			
	if not px or not py then
		return
	end
		
	local avatarTransform =
	{
		x = px + 50,
		y = py + 75,
		scale = 1,
	}
			
	Tacview.UI.Renderer.DrawUIVertexArray(avatarTransform, avatarRenderStateHandle, avatarVertexArrayHandle, avatarTextureCoordinateArrayHandle)

end

----------------------------------------------------------------
-- Initialize this addon
----------------------------------------------------------------

function Initialize()

	-- Declare add-on information

	Tacview.AddOns.Current.SetTitle("Display Avatar (2D)")
	Tacview.AddOns.Current.SetVersion("1.8.8")
	Tacview.AddOns.Current.SetAuthor("BuzyBee")
	Tacview.AddOns.Current.SetNotes("Displays 2D avatar of selected object.")

	-- Load user preferences
	-- The variable displayAvatar already contains the default setting

	displayAvatar = Tacview.AddOns.Current.Settings.GetBoolean(DisplayAvatarSettingName, displayAvatar)

	-- Declare menus
	-- Create a main menu "Display Avatar"
	-- Then insert in it an option to display or not the avatar

	local mainMenuId = Tacview.UI.Menus.AddMenu(nil, "Avatar (2D)")
	displayAvatarMenuId = Tacview.UI.Menus.AddOption(mainMenuId, "Display Avatar (2D)", displayAvatar, OnMenuEnableAddOn)

	-- Register callbacks

	Tacview.Events.DrawTransparentUI.RegisterListener(OnDrawTransparentUI)

end

Initialize()
