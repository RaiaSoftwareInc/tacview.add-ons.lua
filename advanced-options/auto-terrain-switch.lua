
--[[
	Terrain Selector
	Select the correct custom terrain texture and heightmap depending on current MapId.

	Author: BuzyBee
	Last update: 2025-06-23

	Feel free to modify and improve this script!
--]]

--[[

	MIT License

	Copyright (c) 2025 Raia Software Inc.

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

local Tacview = require("Tacview195")

----------------------------------------------------------------
-- UI commands and options
----------------------------------------------------------------

local AutoTerrainSwitchSettingName = "AutoTerrainSwitch"

function IsAutoSwitchEnabled()

	return Tacview.AddOns.Current.Settings.GetBoolean(AutoTerrainSwitchSettingName, true)

end

function SetAutoSwitch(enabled)

	Tacview.AddOns.Current.Settings.SetBoolean(AutoTerrainSwitchSettingName, enabled)

end

function OnAutoTerrainSwitch()

	local autoTerrainSwitch = not IsAutoSwitchEnabled()

	SetAutoSwitch(autoTerrainSwitch)

end

----------------------------------------------------------------
-- Initialize this addon
----------------------------------------------------------------

function InitializeAutoTerrainSwitch(advancedOptionsMenuHandle)

	-- Declare menus

	Tacview.UI.Menus.AddOption(advancedOptionsMenuHandle, "Auto Terrain Switch", IsAutoSwitchEnabled(), OnAutoTerrainSwitch)

	-- Register listeners

	Tacview.Events.Update.RegisterListener(OnUpdate)

end

----------------------------------------------------------------
-- Check once a frame if target terrain has changed.
----------------------------------------------------------------

local previousMapId

function OnUpdate(dt, absoluteTime)

	-- Check if auto-switch is enabled.

	if not IsAutoSwitchEnabled() then
		return
	end

	-- Check if MapId has changed since the last update.

	local mapIdPropertyIndex = Tacview.Telemetry.GetGlobalTextPropertyIndex("MapId", false)
	local mapId

	if mapIdPropertyIndex ~= Tacview.Telemetry.InvalidPropertyIndex then

		mapId = Tacview.Telemetry.GetTextSample(0, absoluteTime, mapIdPropertyIndex)

	end

	if mapId == previousMapId then

		return

	end

	-- Switch terrain to the new map.

	previousMapId = mapId

	SwitchTextureMap(mapId)
	SwitchElevationMap(mapId)

end

----------------------------------------------------------------
-- Switch current texture and elevation maps.
-- NOTE: As a failsafe, if not valid mapId is provided then we enable all maps.
----------------------------------------------------------------

local NuclearOptionLayerFilter = "Nuclear Option"

function SwitchTextureMap(mapId)

	SwitchMap(mapId, Tacview.Terrain.GetTextureList(), Tacview.Terrain.ShowTexture, Tacview.Terrain.HideTexture, true)

end

function SwitchElevationMap(mapId)

	SwitchMap(mapId, Tacview.Terrain.GetElevationMapList(), Tacview.Terrain.ShowElevationMap, Tacview.Terrain.HideElevationMap, false)

end

function SwitchMap(mapId, mapList, ShowMapFunction, HideMapFunction, logEnabled)

	-- Retrieve the list of all custom maps.

	if not mapList then

		return

	end

	-- Activate currently selected map.

	if contains(mapList, mapId) then

		-- Enable only the current MapId.

		for _, map in ipairs(mapList) do

			if map == mapId then

				ShowMapFunction(map)

				if logEnabled then

					Tacview.Log.Info("Showing map '" .. mapId .. "' and hiding others.")

				end
			else

				HideMapFunction(map)

			end

		end

	else

		-- Enable all maps if no valid MapId provided.

		for _, map in ipairs(mapList) do

			ShowMapFunction(map)

		end

		if logEnabled then

			Tacview.Log.Info("No valid MapId found, showing all maps.")

		end
	end
end

----------------------------------------------------------------
-- Tools
----------------------------------------------------------------

function contains(t, value)

	for _, v in ipairs(t) do

		if v == value then

			return true

		end

	end

	return false

end
