
--[[
	IL2 Explosions Corrector

	Author: BuzyBee
	Last update: 2021-09-27 (Tacview 1.8.7)

	Feel free to modify and improve this script!
--]]

--[[

	MIT License

	Copyright (c) 2021 Raia Software Inc.

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

local Tacview = require("Tacview187")

----------------------------------------------------------------
-- Constants
----------------------------------------------------------------

local automaticallyCorrectExplosionsSettingName = "automaticallyCorrectExplosions"

local EXPLOSION_LIFETIME = 0.1

----------------------------------------------------------------
-- UI commands and options
----------------------------------------------------------------

local automaticallyCorrectExplosionsMenuId
local automaticallyCorrectExplosions = true

local map

local Telemetry = Tacview.Telemetry

function IsIL2Flight()

	-- Check if this is an IL-2 flight

	local sourcePropertyIndex = Telemetry.GetGlobalTextPropertyIndex( "DataSource" , false )

	if sourcePropertyIndex == Telemetry.InvalidPropertyIndex then
		return false
	end

	local simulator, sampleIsValid = Telemetry.GetTextSample( 0, Telemetry.BeginningOfTime , sourcePropertyIndex) 

	if simulator == "IL-2 Sturmovik" then

		return true

	end

	return false

end

function CorrectExplosionsNow()

	-- Identify and action each explosion.

	local Telemetry = Tacview.Telemetry
	local AnyGivenTagActive = Telemetry.AnyGivenTagActive
	local GetCurrentTags = Telemetry.GetCurrentTags
	local GetLifeTime = Telemetry.GetLifeTime
	local GetObjectHandleByIndex = Telemetry.GetObjectHandleByIndex
	local Tags = Telemetry.Tags
	local SetLifeTimeEnd = Telemetry.SetLifeTimeEnd

	local objectCount = Telemetry.GetObjectCount()

	local count = objectCount-1

	for objectIndex=count,0,-1 do

		local objectHandle = GetObjectHandleByIndex(objectIndex)

		if not objectHandle then
			goto nextObject
		end

		local objectTags = GetCurrentTags(objectHandle)

		if not objectTags then
			goto nextObject
		end

		if not AnyGivenTagActive(objectTags, Tags.Explosion) then
			goto nextObject
		end

		local lifeTimeBegin, lifeTimeEnd = GetLifeTime( objectHandle )

		SetLifeTimeEnd(objectHandle , lifeTimeBegin + EXPLOSION_LIFETIME)

		::nextObject::

	end
end

function AutomaticallyCorrectExplosions()

	-- Enable/disable add-on

	automaticallyCorrectExplosions = not automaticallyCorrectExplosions

	-- Save option value in registry

	Tacview.AddOns.Current.Settings.SetBoolean(automaticallyCorrectExplosionsSettingName, automaticallyCorrectExplosions)

	-- Update menu with the new option value

	Tacview.UI.Menus.SetOption(automaticallyCorrectExplosionsMenuId, automaticallyCorrectExplosions)

	-- Fix pilot names if user has indicated to do so automatically

	if automaticallyCorrectExplosions then

		Tacview.Log.Info("Automatically correcting explosions");

		CorrectExplosionsNow()

	end

end

function OnDocumentLoaded()

	if not IsIL2Flight() then

		return
	end

	Tacview.Log.Debug("New document has been loaded")

	--Check if the user wants to correct explosions

	if automaticallyCorrectExplosions then

		Tacview.Log.Info("Automatically correcting explosions")

		CorrectExplosionsNow()

	end
end

----------------------------------------------------------------
-- Add-on initialization
----------------------------------------------------------------

function Initialize()

	-- Declare add-on information

	Tacview.AddOns.Current.SetTitle("IL-2 Explosions Corrector")
	Tacview.AddOns.Current.SetVersion("1.8.7")
	Tacview.AddOns.Current.SetAuthor("BuzyBee")
	Tacview.AddOns.Current.SetNotes("Correct explosions by making them disappear faster")

	-- Load user preferences 

	automaticallyCorrectExplosions = Tacview.AddOns.Current.Settings.GetBoolean(automaticallyCorrectExplosionsSettingName, automaticallyCorrectExplosions)

	-- Declare menus

	local mainMenuHandle = Tacview.UI.Menus.AddMenu(nil, "IL-2 Explosions Corrector")

	Tacview.UI.Menus.AddCommand(mainMenuHandle, "Correct Explosions Now", CorrectExplosionsNow)

	Tacview.UI.Menus.AddSeparator(mainMenuHandle)

	automaticallyCorrectExplosionsMenuId = Tacview.UI.Menus.AddOption(mainMenuHandle, "Automatically Correct Explosions", automaticallyCorrectExplosions, AutomaticallyCorrectExplosions)

	-- Register callbacks

	Tacview.Events.DocumentLoaded.RegisterListener(OnDocumentLoaded)

end

Initialize()


