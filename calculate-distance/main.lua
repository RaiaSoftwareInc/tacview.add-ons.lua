
--[[
	Calculate Distance

	Author: BuzyBee
	Last update: 2026-03-19 (Tacview 1.9.5)

	Feel free to modify and improve this script!
--]]

--[[

	MIT License

	Copyright (c) 2020-2025 Raia Software Inc.

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

-- Constants 

local settingName = "Calculate Distance"
local menuId
local enabled = false

local timeElapsed = 0
local timeout = 1
local displayingLineAndText = false

local NumberOfSegments = 1000


local points = {}

----------------------------------------------------------------
-- Menu callbacks
----------------------------------------------------------------

function MenuOption()

	-- Enable/disable add-on

	enabled = not enabled

	-- Save option value in registry

	Tacview.AddOns.Current.Settings.SetBoolean(settingName, enabled)

	-- Update menu with the new option value

	Tacview.UI.Menus.SetOption(menuId, enabled)

end

local FontSize = 24
local FontColor = 0xFFA0FF46		-- HUD style green
local Red = 0x00FF0000

local TextRenderState =
{
	color = FontColor,
	blendMode = Tacview.UI.Renderer.BlendMode.Additive,
}

local LineRenderState=
{
	color = FontColor,
	blendMode = Tacview.UI.Renderer.BlendMode.Additive,
}

local textRenderStateHandle
local lineRenderStateHandle

function OnUpdate( dt , absoluteTime )

	if not enabled then
		return
	end

	if displayingLineAndText then
		timeElapsed = timeElapsed + dt

		if timeElapsed > timeout then
			displayingLineAndText = false
		end
	end
end


function OnDrawTransparentUI()

	if not enabled then
		return
	end

	if not displayingLineAndText then
		return
	end

	-- Compile render state

	if not textRenderStateHandle then

		textRenderStateHandle = Tacview.UI.Renderer.CreateRenderState(TextRenderState)
	end

	local TextTransform =
	{
		x = Tacview.UI.Renderer.GetWidth() * 0.85,
		y = Tacview.UI.Renderer.GetHeight() * 0.05,
		scale = FontSize,
	}

	local renderer = Tacview.UI.Renderer

	local p1 = points[#points-1]
	local p2 = points[#points]

	if not (p1 and p2) then
		return
	end

	local distance = Tacview.Math.Vector.GetDistanceOnEarth(p1[1],p1[2],p2[1],p2[2],0) 

	renderer.Print(TextTransform, textRenderStateHandle, "Distance: " .. Tacview.UI.Format.DistanceToText(distance))

end

local function GetMaxTerrainAlongLine(p1, p2)

    -- Convert to Cartesian
    local c1 = Tacview.Math.Vector.LongitudeLatitudeToCartesian({
        longitude = p1[1],
        latitude = p1[2],
        altitude = 0.0
    })

    local c2 = Tacview.Math.Vector.LongitudeLatitudeToCartesian({
        longitude = p2[1],
        latitude = p2[2],
        altitude = 0.0
    })

    -- Direction vector
    local dx = c2.x - c1.x
    local dy = c2.y - c1.y
    local dz = c2.z - c1.z

    local length = math.sqrt(dx*dx + dy*dy + dz*dz)
    
	if length == 0 then
        return
    end

	local increment = length/NumberOfSegments

    -- Normalize direction
    dx = dx / length
    dy = dy / length
    dz = dz / length

    local maxTerrain = 0

    local d = 0.0
    while d <= length do

        -- Step along the vector
        local x = c1.x + dx * d
        local y = c1.y + dy * d
        local z = c1.z + dz * d

        -- Convert back to lon/lat
        local pos = Tacview.Math.Vector.CartesianToLongitudeLatitude({
            x = x,
            y = y,
            z = z
        })

        local terrainAlt = Tacview.Terrain.GetElevation(pos.longitude, pos.latitude)

        if terrainAlt and terrainAlt > maxTerrain then
            maxTerrain = terrainAlt
        end

        d = d + increment
    end

    return maxTerrain
end

function OnDrawTransparentObjects()

	if not enabled then
		return
	end

	if not displayingLineAndText then
		return
	end

	if not lineRenderStateHandle then

		lineRenderStateHandle = Tacview.UI.Renderer.CreateRenderState(LineRenderState)
	end

	local renderer = Tacview.UI.Renderer

	local p1 = points[#points-1]
	local p2 = points[#points]
	
	if not (p1 and p2) then
		return
	end

	local maxAltitude = GetMaxTerrainAlongLine(p1, p2, 1)

	local c1 = Tacview.Math.Vector.LongitudeLatitudeToCartesian({
		longitude = p1[1],
		latitude = p1[2],
		altitude = maxAltitude,
	})
	
	local c2 = Tacview.Math.Vector.LongitudeLatitudeToCartesian({
		longitude = p2[1],
		latitude = p2[2],
		altitude = maxAltitude,
	})
	
	renderer.DrawLines(lineRenderStateHandle, 4, {{ c1.x,c1.y,c1.z },{ c2.x,c2.y,c2.z }})

end


function OnShutdown()

	if lineRenderStateHandle then
		Tacview.UI.Renderer.ReleaseRenderState(lineRenderStateHandle)
	end

	if textRenderStateHandle then
		Tacview.UI.Renderer.ReleaseRenderState(textRenderStateHandle)
	end

	points={}

end

function OnPick3DPoint(longitude, latitude, altitude)

	if #points == 2 then
		points = {}
	end

	points[#points+1] = {longitude, latitude, altitude}

	timeElapsed = 0
	displayingLineAndText = true
end

function PowerSave()

	return not displayingLineAndText

end

----------------------------------------------------------------
-- Add-on initialization
----------------------------------------------------------------

function Initialize()

	-- Declare add-on information

	Tacview.AddOns.Current.SetTitle("Calculate Distance")
	Tacview.AddOns.Current.SetVersion("0.1")
	Tacview.AddOns.Current.SetAuthor("BuzyBee")
	Tacview.AddOns.Current.SetNotes("Display distance between two points")


	-- Load user preferences 

	enabled = Tacview.AddOns.Current.Settings.GetBoolean(settingName, enabled)

	-- Declare menus

	local mainMenuHandle = Tacview.UI.Menus.AddMenu(nil, "Calculate Distance")

	menuId = Tacview.UI.Menus.AddOption(mainMenuHandle, "Calculate Distance", enabled, MenuOption)

	-- Register callbacks

	Tacview.Events.DrawTransparentUI.RegisterListener(OnDrawTransparentUI)
	Tacview.UI.Renderer.Pick3DPoint.RegisterListener(OnPick3DPoint )
	Tacview.Events.Shutdown.RegisterListener(OnShutdown)
	Tacview.Events.DrawTransparentObjects.RegisterListener(OnDrawTransparentObjects)
	Tacview.Events.Update.RegisterListener(OnUpdate)

	Tacview.Events.PowerSave.RegisterListener(PowerSave)

end

Initialize()
