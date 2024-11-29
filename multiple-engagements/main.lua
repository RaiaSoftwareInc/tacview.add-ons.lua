
--[[
	Multiple Engagements

	Author: BuzyBee
	Last update: 2023-09-07 (Tacview 1.9.0)

	Feel free to modify and improve this script!
--]]

--[[

	MIT License

	Copyright (c) 2023-2024 Raia Software Inc.

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

local Tacview = require("Tacview193")

----------------------------------------------------------------
-- Constants
----------------------------------------------------------------

local displayMultipleEngagementsSettingName = "Display Values"

----------------------------------------------------------------
-- UI commands and options
----------------------------------------------------------------

local displayMultipleEngagementsMenuId
local displayMultipleEngagements = true

local lineRenderStateHandle
local textRenderStateHandle

local LineColor = 0xffffffff		-- Black/White line for now
local TextColor = 0xff000000		-- Black/White text for now
local FontSize = 20


function OnMenuDisplayMultipleEngagements()

	-- Enable/disable add-on

	displayMultipleEngagements = not displayMultipleEngagements

	-- Save option value in registry

	Tacview.AddOns.Current.Settings.SetBoolean(displayMultipleEngagementsSettingName, displayMultipleEngagements)

	-- Update menu with the new option value

	Tacview.UI.Menus.SetOption(displayMultipleEngagementsMenuId, displayMultipleEngagements)

end

-- Draw Lines

function OnDrawTransparentObjects()

	if not displayMultipleEngagements then
		return
	end
	
	local primarySelectedObject = Tacview.Context.GetSelectedObject(0)
	local secondarySelectedObject = Tacview.Context.GetSelectedObject(1)
	
	if not lineRenderStateHandle then

		local lineRenderState =
		{
			color = LineColor,
		}

		lineRenderStateHandle = Tacview.UI.Renderer.CreateRenderState(lineRenderState)

	end	
	
	local activeObjects = Tacview.Context.GetActiveObjectList()
	
	for i=1,#activeObjects do
	
		local transform1 = Tacview.Telemetry.GetCurrentTransform(activeObjects[i])
		
		local x1,y1 = Tacview.UI.Renderer.GetProjectedPosition(activeObjects[i])
		
		local vertex1 = Tacview.Math.Vector.LongitudeLatitudeToCartesian(transform1)
			
		local j = i+1
		
		while j <= #activeObjects do
		
			local transform2 = Tacview.Telemetry.GetCurrentTransform(activeObjects[j])
			
			local x2,y2 = Tacview.UI.Renderer.GetProjectedPosition(activeObjects[j])

			local vertex2 = Tacview.Math.Vector.LongitudeLatitudeToCartesian(transform2)
			
			local vertices =
			{
				{vertex1.x,vertex1.y,vertex1.z},
				{vertex2.x,vertex2.y,vertex2.z},
			}
			
			-- Do not display a line between the objects if they are the primary and secondary selected objects																				
		
			if primarySelectedObject and secondarySelectedObject then
				if 		(primarySelectedObject == activeObjects[i] and secondarySelectedObject == activeObjects[j])
					or 	(primarySelectedObject == activeObjects[j] and secondarySelectedObject == activeObjects[i]) then
					
					goto continue
				end
			end
			
			Tacview.UI.Renderer.DrawLines(lineRenderStateHandle, 1, vertices)
			
			::continue::	

			j = j+1
		end
	end	
end

-- Draw Text

function OnDrawTransparentUI()

	if not displayMultipleEngagements then
		return
	end
	
	local primarySelectedObject = Tacview.Context.GetSelectedObject(0)
	local secondarySelectedObject = Tacview.Context.GetSelectedObject(1)
	
	if not textRenderStateHandle then
	
		local textRenderState = 
		{	
			color = TextColor,
		}
		
		textRenderStateHandle = Tacview.UI.Renderer.CreateRenderState(textRenderState)
	end	
	
	local activeObjects = Tacview.Context.GetActiveObjectList()
	
	for i=1,#activeObjects do
	
		local transform1 = Tacview.Telemetry.GetCurrentTransform(activeObjects[i])
		
		local x1,y1,z1 = Tacview.UI.Renderer.GetProjectedPosition(activeObjects[i])
		
		local vertex1 = Tacview.Math.Vector.LongitudeLatitudeToCartesian(transform1)
		
		local j = i+1
		
		while j <= #activeObjects do
		
			local transform2 = Tacview.Telemetry.GetCurrentTransform(activeObjects[j])
			
			local x2,y2,z2 = Tacview.UI.Renderer.GetProjectedPosition(activeObjects[j])
			
			local vertex2 = Tacview.Math.Vector.LongitudeLatitudeToCartesian(transform2)
			
			local textTransform = 
			{	x = (x1+x2)/2, 
				y = (y1+y2)/2, 
				scale = FontSize,
			}
			
			local bra = Tacview.Math.Vector.LongitudeLatitudeToBearingRangeAltitude(transform1.longitude, transform1.latitude, transform1.altitude, 
																					transform2.longitude, transform2.latitude, transform2.altitude)
																					
			-- Do not display text line between the objects if they are the primary and secondary selected objects																						
			
			local object1 = Tacview.Telemetry.GetCurrentShortName( activeObjects[i] )
			local object2 = Tacview.Telemetry.GetCurrentShortName( activeObjects[j] )
			
			if primarySelectedObject and secondarySelectedObject then
				if 		(primarySelectedObject == activeObjects[j] and secondarySelectedObject == activeObjects[i])
					or 	(primarySelectedObject == activeObjects[i] and secondarySelectedObject == activeObjects[j]) then
					
					goto continue
				end
			end
			
			-- Check z1 and z2 to verify if text should be visible to user and, if so, display it.
			
			if z1 and z2 and not (z1 < 0.0 or z1 >= 1.0 or z2 < 0.0 or z2 >= 1.0) then
				local msg = string.format("%.1f", math.deg(bra.bearing)) .. "°\n" .. Tacview.UI.Format.DistanceToText(bra.range)
				Tacview.UI.Renderer.Print(textTransform, textRenderStateHandle, msg)
			end
			
			::continue::
			
			j = j+1
		end
	end
end

----------------------------------------------------------------
-- Initialize this addon
----------------------------------------------------------------

function Initialize()

	-- Declare add-on information

	Tacview.AddOns.Current.SetTitle("Multiple Engagements")
	Tacview.AddOns.Current.SetVersion("1.9.3")
	Tacview.AddOns.Current.SetAuthor("BuzyBee")
	Tacview.AddOns.Current.SetNotes("Displays Bearing and Range between each pair of fixed wing aircraft.")

	-- Load user preferences
	-- The variable displayMultipleEngagements already contain the default setting

	displayMultipleEngagements = Tacview.AddOns.Current.Settings.GetBoolean(displayMultipleEngagementsSettingName, displayMultipleEngagements)

	-- Declare menus

	local mainMenuId = Tacview.UI.Menus.AddMenu(nil, "Multiple Engagements")
	displayMultipleEngagementsMenuId = Tacview.UI.Menus.AddOption(mainMenuId, "Display Multiple Engagements", displayMultipleEngagements, OnMenuDisplayMultipleEngagements)

	-- Register callbacks

	Tacview.Events.DrawTransparentObjects.RegisterListener(OnDrawTransparentObjects)
	Tacview.Events.DrawTransparentUI.RegisterListener(OnDrawTransparentUI) 

end

Initialize()
