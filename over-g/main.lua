
--[[
	Over-G

	Author: BuzyBee
	Last update: 2020-09-14 (Tacview 1.8.4)

	Feel free to modify and improve this script!
--]]

--[[

	MIT License

	Copyright (c) 2020 Raia Software Inc.

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

local Tacview = require("Tacview184")

-- Constants 

local overG_ActivatedSettingName = "overG_Activated"
local overG_ActivatedMenuId
local overG_Activated = false

dofile(Tacview.AddOns.Current.GetPath() .."limit-list.lua")

local gLimitTable = limit_list()

local timeBetweenMessages = 2
local timeElapsed = timeBetweenMessages
local listOfOverG
local timeToDisplayListItem = 1
local chartOfOverGAircraftActualTime = {}
local chartOfOverGAircraftDisplayTime = {}


function OnUpdate( dt , absoluteTime )

	if not overG_Activated then 
		-- print("NOT overG_Activated") 
		return 
	end

	listOfOverG="Over-G Aircraft:"

	timeElapsed = timeElapsed + dt

	local pilotPropertyIndex = Tacview.Telemetry.GetObjectsTextPropertyIndex("Pilot",false)

	local objectCount = Tacview.Telemetry.GetObjectCount()

	-- print("Found "..objectCount.." objects")

	for objectIndex=0,objectCount-1 do
		
		local objectHandle = Tacview.Telemetry.GetObjectHandleByIndex(objectIndex)

		if not objectHandle then 
			--print("NOT objectHandle") 
			goto continue 
		end

		local objectTags = Tacview.Telemetry.GetCurrentTags(objectHandle)

		if not objectTags then 
			-- print("NOT objectTags") 
			goto continue 
		end

		local isFixedWing = Tacview.Telemetry.AnyGivenTagActive(objectTags,Tacview.Telemetry.Tags.FixedWing)

		if not isFixedWing then
			--print("NOT isFixedWing") 
			goto continue  
		end

		local verticalG = Tacview.Telemetry.GetVerticalGForce(objectHandle, absoluteTime)

		if not verticalG then
			--print("NOT verticalG") 
			goto continue  
		end

		local _,lifeTimeEnd = Tacview.Telemetry.GetLifeTime( objectHandle )

		if(absoluteTime > lifeTimeEnd) then
			--print("absoluteTime > lifeTimeEnd") 
			goto continue  
		end

		local shortName = Tacview.Telemetry.GetCurrentShortName(objectHandle)

		local gLimit = nil
		local guiltyParty = nil
		
		for aircraftName,gLimitTableEntry in pairs(gLimitTable) do
			--print("shortName="..shortName..", aircraftName="..aircraftName)
			if string.find(shortName, aircraftName,1,true) then
				--print("found "..shortName.." in gLimitTable as \""..aircraftName.."\" with gLimit ".. gLimitTable[aircraftName])
				gLimit = gLimitTableEntry
				break
			end
		end

		if not gLimit then
			--print("NOT gLimit")
			goto continue  
		end


		local pilot

		if pilotPropertyIndex and pilotPropertyIndex ~= Tacview.Telemetry.InvalidPropertyIndex then
			pilot = Tacview.Telemetry.GetTextSample(objectHandle, absoluteTime, pilotPropertyIndex)
		end

		if verticalG > gLimit then

			if not chartOfOverGAircraftActualTime[objectHandle] then
				chartOfOverGAircraftActualTime[objectHandle] = dt
				chartOfOverGAircraftDisplayTime[objectHandle] = dt
			else
				chartOfOverGAircraftActualTime[objectHandle] =  chartOfOverGAircraftActualTime[objectHandle] + dt
				chartOfOverGAircraftDisplayTime[objectHandle] = chartOfOverGAircraftDisplayTime[objectHandle] + dt
			end

			-- print("chartOfOverGAircraftActualTime[objectHandle]="..chartOfOverGAircraftActualTime[objectHandle])

			--print("verticalG of "..verticalG .. " is greater than gLimit of " .. gLimit)
			
			if timeElapsed > timeBetweenMessages then
				Tacview.SoundPlayer.Play(Tacview.AddOns.Current.GetPath() .. "over-g.wav" )
				timeElapsed = 0
			end


		else -- verticalG <= gLimit

			if chartOfOverGAircraftActualTime[objectHandle] then
				if chartOfOverGAircraftDisplayTime[objectHandle] < timeToDisplayListItem then
					chartOfOverGAircraftDisplayTime[objectHandle] = chartOfOverGAircraftDisplayTime[objectHandle] + dt
				else

					local msg = shortName

					if pilot then
						msg = msg .. " ("..pilot..") "
					end

					msg = msg .. "was over " .. gLimit .. " g for " .. string.format("%.1f",chartOfOverGAircraftActualTime[objectHandle]) .. " seconds"

					Tacview.Log.Info(msg) 

					chartOfOverGAircraftActualTime[objectHandle] = nil
					chartOfOverGAircraftDisplayTime[objectHandle] = nil

				end
			end
		end

		if chartOfOverGAircraftActualTime[objectHandle] then

			listOfOverG = listOfOverG .. "\n" .. string.format("%.1f",verticalG) .. ">"..gLimit .. "    " .. shortName

			if pilot then
				 listOfOverG = listOfOverG .. " ("..pilot .. ")"
			end

			listOfOverG = listOfOverG .. "    " .. string.format("%0.1f",chartOfOverGAircraftActualTime[objectHandle]) .. " s"
		end

	::continue::
	end
end

----------------------------------------------------------------
-- Menu callbacks
----------------------------------------------------------------

function OnMenuOverG()

	-- Enable/disable add-on

	overG_Activated = not overG_Activated

	-- Save option value in registry

	Tacview.AddOns.Current.Settings.SetBoolean(overG_ActivatedSettingName, overG_Activated)

	-- Update menu with the new option value

	Tacview.UI.Menus.SetOption(overG_ActivatedMenuId, overG_Activated)

end

local Margin = 16
local FontSize = 24
local FontColor = 0xFFA0FF46		-- HUD style green

local StatisticsRenderState =
{
	color = FontColor,
	blendMode = Tacview.UI.Renderer.BlendMode.Additive,
}

local statisticsRenderStateHandle

function OnDrawTransparentUI()

	if not overG_Activated then
		return
	end

	-- Compile render state

	if not statisticsRenderStateHandle then

		statisticsRenderStateHandle = Tacview.UI.Renderer.CreateRenderState(StatisticsRenderState)

	end

	local renderer = Tacview.UI.Renderer

	local transform =
	{
		x = Margin,
		y = (renderer.GetHeight() + 4 * FontSize) / 2,
		scale = FontSize,
	}

	renderer.Print(transform, statisticsRenderStateHandle, listOfOverG)

end


function OnDocumentLoadedOrUnloaded()

	chartOfOverGAircraftActualTime = {}

end



----------------------------------------------------------------
-- Add-on initialization
----------------------------------------------------------------

function Initialize()

	-- Declare add-on information

	Tacview.AddOns.Current.SetTitle("Over-G")
	Tacview.AddOns.Current.SetVersion("1.0")
	Tacview.AddOns.Current.SetAuthor("BuzyBee")
	Tacview.AddOns.Current.SetNotes("Display Over-G Aircraft")

	-- Create a menu item

-- Load user preferences 

	overG_Activated = Tacview.AddOns.Current.Settings.GetBoolean(overG_ActivatedSettingName, overG_Activated)

	-- Declare menus

	local mainMenuHandle = Tacview.UI.Menus.AddMenu(nil, "Over-G")

	overG_ActivatedMenuId = Tacview.UI.Menus.AddOption(mainMenuHandle, "Display Over-G Aircraft", overG_Activated, OnMenuOverG)

	-- Register callbacks

	Tacview.Events.Update.RegisterListener(OnUpdate)
	Tacview.Events.DrawTransparentUI.RegisterListener(OnDrawTransparentUI)

	Tacview.Events.DocumentLoaded.RegisterListener(OnDocumentLoadedOrUnloaded )
	Tacview.Events.DocumentUnload.RegisterListener(OnDocumentLoadedOrUnloaded )


end

Initialize()
