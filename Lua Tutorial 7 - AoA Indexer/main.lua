
-- AoA Indexer for Tacview (tutorial for 2D UI rendering)
-- Author: Frantz 'Vyrtuoz' RAIA
-- Last update: 2018-09-26 (Tacview 1.7.3)

-- IMPORTANT: This script act both as a tutorial and as a real addon for Tacview.
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
-- Constants
----------------------------------------------------------------

local AddOnEnabledSettingName = "DisplayAOAIndexer"

local IndexerWidth = 282 / 6
local IndexerHeight = 139

----------------------------------------------------------------
-- "Members"
----------------------------------------------------------------

local currentAoA = nil

local indexerTextureHandle = nil
local indexerRenderStateHandle = nil
local indexerVertexArrayHandle = nil
local indexerTextureCoordinateArrayHandleList = nil

----------------------------------------------------------------
-- UI commands and options
----------------------------------------------------------------

local addOnEnabledMenuId
local addOnEnabledOption = false

function OnMenuEnableAddOn()

	-- Change and save option

	addOnEnabledOption = not addOnEnabledOption

	Tacview.AddOns.Current.Settings.SetBoolean(AddOnEnabledSettingName, addOnEnabledOption)

	-- Update menu

	Tacview.UI.Menus.SetOption(addOnEnabledMenuId, addOnEnabledOption)

end

----------------------------------------------------------------
-- 2D Rendering
----------------------------------------------------------------

function DeclareRenderData()

	-- Only one texture is used, it contains all the different states.

	if not indexerTextureHandle then

		local addOnPath = Tacview.AddOns.Current.GetPath()
		indexerTextureHandle = Tacview.UI.Renderer.LoadTexture(addOnPath.."Textures/AoAIndexer.png", false)

	end

	-- The render state is used to define how to draw the instrument.
	-- We only need to specify the texture in our case.

	if not indexerRenderStateHandle then

		local renderState =
		{
			texture = indexerTextureHandle,
		}

		indexerRenderStateHandle = Tacview.UI.Renderer.CreateRenderState(renderState)

	end

	-- The following list of vertices is used to define the square shape of the instrument using two triangles.

	if not indexerVertexArrayHandle then

		local HalfWidth = IndexerWidth / 2
		local HalfHeight = IndexerHeight / 2

		local vertexArray =
		{
			-HalfWidth, HalfHeight, 0.0,
			-HalfWidth, -HalfHeight, 0.0,
			HalfWidth, -HalfHeight, 0.0,
			-HalfWidth, HalfHeight, 0.0,
			HalfWidth, HalfHeight, 0.0,
			HalfWidth, -HalfHeight, 0.0,
		}

		indexerVertexArrayHandle = Tacview.UI.Renderer.CreateVertexArray(vertexArray)

	end

	-- We animate the instrument by changing the textures coordinates
	-- to display another portion of the texture.

	if not indexerTextureCoordinateArrayHandleList then

		local baseTextureArray =
		{
			0.0, 0.0,
			0.0, 1.0,
			1.0, 1.0,
			0.0, 0.0,
			1.0, 0.0,
			1.0, 1.0,
		}

		indexerTextureCoordinateArrayHandleList = {}

		local IndexerStateCount = 6

		for stateIndex = 1, IndexerStateCount do

			local textureArray = {}

			local left = stateIndex / IndexerStateCount
			local width = 1 / IndexerStateCount

			for index = 1, #baseTextureArray, 2 do

				table.insert(textureArray, baseTextureArray[index] * width + left)
				table.insert(textureArray, baseTextureArray[index + 1])

			end

			table.insert(indexerTextureCoordinateArrayHandleList, Tacview.UI.Renderer.CreateTextureCoordinateArray(textureArray) )

		end
	end
end

function OnDrawTransparentUI()

	-- Data available?

	if not currentAoA then
		return
	end

	-- Calculate AoA index
	-- NOTE: Tacview return an AoA in radian

	-- The following values are based on DCS World F/A-18C documentation for demonstration purpose.
	-- Possible addon improvement:
	-- These values could be dynamically adjusted depending on the plane type/designation (F-16, F-14...)

	local currentAoADeg = math.deg(currentAoA)
	local indexerPosition = 0

	if currentAoADeg > 9.3 then

		indexerPosition = 5

	elseif currentAoADeg > 8.8 then

		indexerPosition = 4

	elseif currentAoADeg > 7.4 then

		indexerPosition = 3

	elseif currentAoADeg > 6.9 then

		indexerPosition = 2

	else

		indexerPosition = 1

	end

	-- Make sure rendering data are declared (only once, during the first OnDrawTransparentUI call)

	DeclareRenderData()

	-- Draw indexer

	-- Possible improvement:
	-- We could display the AoA value only when the gear is down

	local rendererHeight = Tacview.UI.Renderer.GetHeight()

	local transform =
	{
		x = 32 + IndexerWidth / 2,
		y = rendererHeight / 2,
		scale = 1.5,
	}

	Tacview.UI.Renderer.DrawUIVertexArray(transform, indexerRenderStateHandle, indexerVertexArrayHandle, indexerTextureCoordinateArrayHandleList[indexerPosition])

end

----------------------------------------------------------------
-- Main loop
----------------------------------------------------------------

-- Update is called once a frame by Tacview

function OnUpdate(dt, absoluteTime)

	-- Add-on enabled?

	currentAoA = nil

	if not addOnEnabledOption then

		return

	end

	-- This add-on is active only when one of the selected objects is a plane

	local objectHandle = Tacview.Context.GetSelectedObject(0)

	if not objectHandle or (Tacview.Telemetry.GetCurrentTags(objectHandle) & Tacview.Telemetry.Tags.FixedWing) == 0 then

		objectHandle = Tacview.Context.GetSelectedObject(1)

		if not objectHandle or (Tacview.Telemetry.GetCurrentTags(objectHandle) & Tacview.Telemetry.Tags.FixedWing) == 0 then

			return

		end

	end

	-- Retrieve AoA if available

	currentAoA = Tacview.Telemetry.GetCurrentAngleOfAttack(objectHandle)

end

----------------------------------------------------------------
-- Initialize this addon
----------------------------------------------------------------

function Initialize()

	-- Declare addon properties

	local currentAddOn = Tacview.AddOns.Current

	currentAddOn.SetTitle("Lua Tutorial 7 - AoA Indexer")
	currentAddOn.SetVersion("1.7.3")
	currentAddOn.SetAuthor("Vyrtuoz")
	currentAddOn.SetNotes("Displays military style AoA Indexer when the primary object selected is a plance.")

	-- Load preferences
	-- Use current addOnEnabledOption value as the default setting

	addOnEnabledOption = Tacview.AddOns.Current.Settings.GetBoolean(AddOnEnabledSettingName, addOnEnabledOption)

	-- Declare menus

	local addOnMenuId = Tacview.UI.Menus.AddMenu(nil, "AoA Indexer")
	addOnEnabledMenuId = Tacview.UI.Menus.AddOption(addOnMenuId, "Display AoA Indexer", addOnEnabledOption, OnMenuEnableAddOn)

	-- Register callbacks

	Tacview.Events.Update.RegisterListener(OnUpdate)

	Tacview.Events.DrawTransparentUI.RegisterListener(OnDrawTransparentUI)

end

Initialize()
