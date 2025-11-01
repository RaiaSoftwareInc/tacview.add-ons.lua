--[[
	Auto Color

	Author: BuzyBee
	Last update: 2025-08-05

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

require("lua-strict")

local autoColor = true
local autoColorSettingName = "Auto Color"


local coloringInstructions = {
	{ pilotName = "Vyrtuoz", desiredColor = "Yellow" },
}

----------------------------------------------------------------
-- Request Tacview API
----------------------------------------------------------------

local Tacview = require("Tacview194")

----------------------------------------------------------------
-- UI commands and options
----------------------------------------------------------------


function OnAutoColor()

	autoColor = not autoColor

	Tacview.AddOns.Current.Settings.SetBoolean(autoColorSettingName, autoColor)

end

function OnUpdate( dt , absoluteTime )

	if not autoColor then
		return
	end

	local activeObjectList = Tacview.Context.GetActiveObjectList()

	local pilotPropertyIndex = Tacview.Telemetry.GetObjectsTextPropertyIndex("Pilot", false)
	local colorPropertyIndex = Tacview.Telemetry.GetObjectsTextPropertyIndex("Color", true)

	if pilotPropertyIndex == Tacview.Telemetry.InvalidPropertyIndex then
		return
	end

	for _,objectHandle in ipairs(activeObjectList) do

		local objectTags = Tacview.Telemetry.GetCurrentTags( objectHandle )

		if not objectTags then
			goto nextObject
		end

		if Tacview.Telemetry.AnyGivenTagActive( objectTags , Tacview.Telemetry.Tags.FixedWing|Tacview.Telemetry.Tags.Rotorcraft) then

			local pilot, sampleIsValid = Tacview.Telemetry.GetTextSample(objectHandle, absoluteTime , pilotPropertyIndex)


			if not sampleIsValid then
				return
			end

			for _, coloringInstruction in ipairs(coloringInstructions) do

				if coloringInstruction.pilotName == pilot then

					local color, sampleIsValid = Tacview.Telemetry.GetTextSample(objectHandle, absoluteTime , colorPropertyIndex)

					if sampleIsValid then

						if color == coloringInstruction.desiredColor then
							goto nextColoringInstruction
						end				
					end

					Tacview.Telemetry.SetTextSample( objectHandle , absoluteTime , colorPropertyIndex , coloringInstruction.desiredColor )
					
					Tacview.Log.Info("Changed the color of " .. coloringInstruction.pilotName .. " to " .. coloringInstruction.desiredColor)

					Tacview.UI.Update()
	
				end

				::nextColoringInstruction::
			end
		end

		::nextObject::
	end
end

----------------------------------------------------------------
-- Initialize this addon
----------------------------------------------------------------

function Initialize()

	-- Declare add-on information

	Tacview.AddOns.Current.SetTitle("Auto Color")
	Tacview.AddOns.Current.SetVersion("1.9.5")
	Tacview.AddOns.Current.SetAuthor("BuzyBee")
	Tacview.AddOns.Current.SetNotes("Automatically color objects with a specified pilot name.")

	-- Get user preferences

	autoColor = Tacview.AddOns.Current.Settings.GetBoolean(autoColorSettingName, autoColor)

	-- Declare menus

	local mainMenuHandle = Tacview.UI.Menus.AddMenu(nil, "Auto Color")

	Tacview.UI.Menus.AddOption( mainMenuHandle , "Color Objects Automatically" , autoColor , OnAutoColor)

	-- Register listeners

	Tacview.Events.Update.RegisterListener(OnUpdate)

end

Initialize()
