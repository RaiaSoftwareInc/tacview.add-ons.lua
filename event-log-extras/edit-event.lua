
-- Event Log Extras
-- Author: Erin 'BuzyBee' O'REILLY
-- Last update: 2025-01-17 (Tacview 1.9.4)

-- Feel free to modify and improve this script!

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

	-- The numeric property Disabled sets the object disabled or not disabled in the 3D view - native to Tacview
	
	-- The text property Disabled Request is part of the Excel Event Log add-on. It is text because it's custom and not supported by Tacview
	-- It is supported here in order to be compatible with the Event Log add-on.

----------------------------------------------------------------
-- Setup
----------------------------------------------------------------

require("LuaStrict")

local Tacview = require("Tacview195")

local event
local eventType
local editEventDialogBoxHandle
local sourceIdComboBoxHandle
local targetIdComboBoxHandle
local outcomeComboBoxHandle
local ammoTypeComboBoxHandle
local editButtonHandle

local bullseyeEditBoxHandle
local bullseyePickAPointButton

local bookmarkorMessageEditBoxHandle
local bookmarkOrMessageComboBoxHandles

local bookmarkOrMessageObjectIds

local messageEditBoxHandle
local messageComboBoxHandle

local bookmarkExtraInfo

local sourceIdObjectHandle

local sourceAndTargetObjects

local OutcomeList = require("outcome-list")
local AmmoList = require("ammo-list")

local GetObjectHandle = Tacview.Telemetry.GetObjectHandle
local GetCurrentObjectHandle = Tacview.Telemetry.GetCurrentObjectHandle
local GetObjectId = Tacview.Telemetry.GetObjectId

local WINDOW_WIDTH = 200
local WINDOW_HEIGHT = 250

function OnEditEvent()

	if editEventDialogBoxHandle then
		return
	end

	Tacview.Log.Info("Event found: " .. event)

	editEventDialogBoxHandle = Tacview.UI.DialogBox.Create("Edit Event", WINDOW_WIDTH, WINDOW_HEIGHT, "edit-event") 
	
	local eventComponents = splitString(event, "|")

	for k,v in ipairs(eventComponents) do
		print ("event components: " .. k .. " " .. v)
	end

	local xText = 10
	local yText = 10
	local xData	= 60
	local yData = 10

	sourceAndTargetObjects = GetAllSourceAndTargetObjects()

	local userFriendlyStrings = {}
	
	for i=1,#sourceAndTargetObjects do
		userFriendlyStrings[i] = sourceAndTargetObjects[i][2]
	end

	eventType = eventComponents[1]

	if eventComponents[1] == "Timeout" then
	
		for i=1,#eventComponents do
			
			local subcomponents = splitString(eventComponents[i], ":")
			
			if #subcomponents>1 then
	
				if subcomponents[1] == "SourceId" then
	
					Tacview.UI.DialogBox.AddText( editEventDialogBoxHandle , subcomponents[1] .. ":" , xText,yText,48,10)
					yText = yText + 25
	
					local sourceIdObjectId = subcomponents[2]
					sourceIdObjectHandle = GetCurrentObjectHandle(tonumber(sourceIdObjectId, 16))
	
					sourceIdComboBoxHandle = Tacview.UI.DialogBox.AddComboBox( editEventDialogBoxHandle , "" , xData , yData , 100, 128, false, OnChangeCallback )
					yData = yData + 25
					
					LoadComboBox(editEventDialogBoxHandle, sourceIdComboBoxHandle, userFriendlyStrings)
	
					local userFriendlyStringToBeMatched = ""
	
					local itemIndex
					
					for i=1,#sourceAndTargetObjects do
						if string.format("%X",GetObjectId(sourceAndTargetObjects[i][1])) == subcomponents[2] then
							userFriendlyStringToBeMatched = sourceAndTargetObjects[i][2]
							print("Found a match! " .. subcomponents[2] .. " = " .. userFriendlyStringToBeMatched )
							itemIndex = i
							break
						end
					end
	
					if itemIndex then
						Tacview.UI.DialogBox.SelectItem(editEventDialogBoxHandle, sourceIdComboBoxHandle, itemIndex-1)
					end
	
				elseif subcomponents[1] == "AmmoType" then
	
					Tacview.UI.DialogBox.AddText( editEventDialogBoxHandle , subcomponents[1] .. ":" , xText,yText,48,10)
					yText = yText + 25
	
					ammoTypeComboBoxHandle = Tacview.UI.DialogBox.AddComboBox( editEventDialogBoxHandle , subcomponents[2] , xData , yData , 100, 128, false, OnChangeCallback )
					LoadComboBox(editEventDialogBoxHandle, ammoTypeComboBoxHandle, AmmoList)
					
					yData = yData + 25
	
	
					local itemIndex
	
					for i=1,#AmmoList do
						if AmmoList[i] == subcomponents[2] then
							itemIndex = i
							break
						end
					end
	
					if itemIndex then
						Tacview.UI.DialogBox.SelectItem(editEventDialogBoxHandle, ammoTypeComboBoxHandle, itemIndex-1)
					end
	
				elseif subcomponents[1] == "TargetId" then
	
					Tacview.UI.DialogBox.AddText( editEventDialogBoxHandle , subcomponents[1] .. ":" , xText,yText,48,10)
					yText = yText + 25
	
					targetIdComboBoxHandle = Tacview.UI.DialogBox.AddComboBox( editEventDialogBoxHandle , "" , xData , yData , 100, 128, false, OnChangeCallback )
					LoadComboBox(editEventDialogBoxHandle, targetIdComboBoxHandle, userFriendlyStrings)
	
					yData = yData + 25
	
					local userFriendlyStringToBeMatched = ""
	
					local itemIndex
					
					for i=1,#sourceAndTargetObjects do
						if string.format("%X",GetObjectId(sourceAndTargetObjects[i][1])) == subcomponents[2] then
							userFriendlyStringToBeMatched = sourceAndTargetObjects[i][2]
							itemIndex = i
							break
						end
					end		
	
					if itemIndex then					
						Tacview.UI.DialogBox.SelectItem(editEventDialogBoxHandle, targetIdComboBoxHandle, itemIndex-1)
					end
	
				elseif subcomponents[1] == "Bullseye" then
	
					Tacview.UI.DialogBox.AddText( editEventDialogBoxHandle , subcomponents[1] .. ":" , xText,yText,48,10)
					yText = yText + 25
	
					local bullseye = splitString(subcomponents[2],"/")
	
					local msg = string.format("%03d",math.floor(bullseye[1]+0.5)) .. "/" .. 	
								string.format("%03d",math.floor(Tacview.Math.Units.MetersToNauticalMiles(bullseye[2]) + 0.5)) .. "/" .. 
								string.format("%02d",math.floor(Tacview.Math.Units.MetersToFeet(bullseye[3])/1000+0.5))
	
					bullseyeEditBoxHandle = Tacview.UI.DialogBox.AddEditBox( editEventDialogBoxHandle , msg , xData , yData , 100, 10 )
	
					yData = yData + 15
	
					Tacview.UI.DialogBox.AddText(editEventDialogBoxHandle , "CTRL+SHIFT+CLICK in 3D view to select a bullseye" , xData , yData , 100, 20 )
	
					yData = yData + 25 + 7
					yText = yText + 25
	
	
				elseif subcomponents[1] == "Outcome" then
	
					Tacview.UI.DialogBox.AddText( editEventDialogBoxHandle , subcomponents[1] .. ":" , xText,yText,48,10)
					yText = yText + 30
	
					outcomeComboBoxHandle = Tacview.UI.DialogBox.AddComboBox( editEventDialogBoxHandle , subcomponents[2] , xData , yData , 100, 128, true, OnChangeCallback )
					LoadComboBox(editEventDialogBoxHandle, outcomeComboBoxHandle, OutcomeList)
	
					yData = yData + 30
	
					local itemIndex
	
					for i=1,#OutcomeList do
						if OutcomeList[i] == subcomponents[2] then
							itemIndex = i
							break
						end
					end	
	
					if itemIndex then
						Tacview.UI.DialogBox.SelectItem(editEventDialogBoxHandle, outcomeComboBoxHandle, itemIndex-1)
					end
	
				end
	
			end
		end

	elseif eventComponents[1] == "Bookmark" or eventComponents[1] == "Message" then

		local msg = ""

		for i=2,#eventComponents do			
			if not is_hex_number(eventComponents[i]) then
				if string.find(eventComponents[i],"tacview:tacview") then
						local start_pos = string.find(eventComponents[i],"tacview:tacview")
						bookmarkExtraInfo = string.sub(eventComponents[i],start_pos)
						msg = string.sub(eventComponents[i], 1, start_pos-1)						
				else
					msg = eventComponents[i]
				end

				Tacview.UI.DialogBox.AddText( editEventDialogBoxHandle , "Text:", xText,yText,48,10)
				yText = yText + 25

				bookmarkorMessageEditBoxHandle = Tacview.UI.DialogBox.AddEditBox( editEventDialogBoxHandle , msg , xData , yData , 100, 10 )
				yData = yData + 25

			else -- is_hex_number(eventComponents[i])

				print("Found a hex number, it's " .. eventComponents[i])

				local objectId = eventComponents[2]
				local objectHandle = GetCurrentObjectHandle(tonumber(objectId, 16))
		
				Tacview.UI.DialogBox.AddText(editEventDialogBoxHandle , "Object " .. i-1 .. ":", xText,yText,48,10)
				yText = yText + 25

				if not bookmarkOrMessageComboBoxHandles then
					bookmarkOrMessageComboBoxHandles = {}
				end
	
				bookmarkOrMessageComboBoxHandles[#bookmarkOrMessageComboBoxHandles+1] = Tacview.UI.DialogBox.AddComboBox( editEventDialogBoxHandle , "" , xData , yData , 100, 128, false, OnChangeCallback )
	
				yData = yData + 25
						
				LoadComboBox(editEventDialogBoxHandle, bookmarkOrMessageComboBoxHandles[#bookmarkOrMessageComboBoxHandles], userFriendlyStrings)

				local userFriendlyStringToBeMatched = ""
	
				local itemIndex
					
				for j=1,#sourceAndTargetObjects do
					if string.format("%X",GetObjectId(sourceAndTargetObjects[j][1])) == eventComponents[i] then
						userFriendlyStringToBeMatched = sourceAndTargetObjects[j][2]
						itemIndex = j
						Tacview.UI.DialogBox.SelectItem(editEventDialogBoxHandle, bookmarkOrMessageComboBoxHandles[#bookmarkOrMessageComboBoxHandles], itemIndex-1)
						break
					end
				end
			end
		end
	end

	Tacview.UI.DialogBox.AddButton( editEventDialogBoxHandle , "Update" , xData , yData , 100 , 25 , OnClickedCallback )
	
	Tacview.UI.DialogBox.Show(editEventDialogBoxHandle, OnHideCallBack) 

end

function is_hex_number(text)
    return text:match("^%x+$") ~= nil
end

function splitString(input, separator)
    local result = {}
    for match in (input .. separator):gmatch("(.-)" .. separator) do
        table.insert(result, match)
    end

    return result
end

local GetObjectsTextPropertyIndex = Tacview.Telemetry.GetObjectsTextPropertyIndex
local GetTextSample = Tacview.Telemetry.GetTextSample
local GetAbsoluteTime = Tacview.Context.GetAbsoluteTime
local GetObjectHandle = Tacview.Telemetry.GetObjectHandle
local GetCurrentShortName = Tacview.Telemetry.GetCurrentShortName

function GetUserFriendlyName(objectHandle)

	local absoluteTime = GetAbsoluteTime()

	local identifierFound = false
	
	local identifyingString = ""

	local callSignPropertyIndex = Tacview.Telemetry.GetObjectsTextPropertyIndex( "CallSign" , false )

	if callSignPropertyIndex ~= Tacview.Telemetry.InvalidPropertyIndex then

		local callSign, sampleIsValid = Tacview.Telemetry.GetTextSample( objectHandle , absoluteTime , callSignPropertyIndex )

		if sampleIsValid then
			identifyingString = identifyingString .. callSign	
			identifierFound = true
		end
	end

	if not identifierFound then
		
		local namePropertyIndex = Tacview.Telemetry.GetObjectsTextPropertyIndex( "Name" , false )
	
		if namePropertyIndex ~= Tacview.Telemetry.InvalidPropertyIndex then
	
			local name, sampleIsValid = Tacview.Telemetry.GetTextSample( objectHandle , absoluteTime , namePropertyIndex )
	
			if sampleIsValid then
				identifyingString = identifyingString .. name	
				identifierFound = true
			end
		end
	end

	identifyingString = identifyingString .. "/" .. GetCurrentShortName( objectHandle )

	return identifyingString
end

function OnChangeCallback()

	-- do nothing?

end

function OnPickAPoint(longitude , latitude , altitude )

	local bullseyeTransform = GetBullseyeTransform()

	Tacview.UI.DialogBox.GetText( editEventDialogBoxHandle , sourceIdComboBoxHandle)

	local BRA = Tacview.Math.Vector.LongitudeLatitudeToBearingRangeAltitude(bullseyeTransform.longitude, bullseyeTransform.latitude, bullseyeTransform.altitude, longitude , latitude, altitude) -- Tacview 1.8.7

	Tacview.UI.DialogBox.SetText( editEventDialogBoxHandle , bullseyeEditBoxHandle, 	string.format("%03d",math.floor(math.deg(BRA.bearing)+0.5)) .. "/" .. 
																			string.format("%03d",math.floor(Tacview.Math.Units.MetersToNauticalMiles(BRA.range) + 0.5)) .. "/" .. 
																			string.format("%02d",math.floor(Tacview.Math.Units.MetersToFeet(BRA.altitude)/1000+0.5)))

end

local GetCurrentTags = Tacview.Telemetry.GetCurrentTags
local AnyGivenTagActive = Tacview.Telemetry.AnyGivenTagActive
local GetTextSample = Tacview.Telemetry.GetTextSample
local GetAbsoluteBearing = Tacview.Telemetry.GetAbsoluteBearing
local GetRange2D = Tacview.Telemetry.GetRange2D
local Normalize2Pi = Tacview.Math.Angle.Normalize2Pi
local GetCurrentTransform = Tacview.Telemetry.GetCurrentTransform
local Bullseye = Tacview.Telemetry.Tags.Bullseye
local GetAbsoluteTime = Tacview.Context.GetAbsoluteTime

function GetBullseyeTransform()

	local firstBullseyeHandle
	local colorMatchBullseyeHandle

	local activeObjectList = Tacview.Context.GetActiveObjectList()
	
	local colorPropertyIndex = Tacview.Telemetry.GetObjectsTextPropertyIndex("Color" , false)

	for i=1, #activeObjectList do
	
		local objectTags = GetCurrentTags(activeObjectList[i])
		
		if AnyGivenTagActive(objectTags, Bullseye) then
		
			local color = GetTextSample(activeObjectList[i], GetAbsoluteTime(), colorPropertyIndex)
			local sourceColor = GetTextSample(sourceIdObjectHandle, GetAbsoluteTime(), colorPropertyIndex)

			if not firstBullseyeHandle then
				firstBullseyeHandle = activeObjectList[i]
			end

			if color == sourceColor then
				colorMatchBullseyeHandle = activeObjectList[i]
			end
		end
	end
			
	if colorMatchBullseyeHandle then	
		
		return GetCurrentTransform( colorMatchBullseyeHandle )

	elseif firstBullseyeHandle then
	
		return GetCurrentTransform(firstBullseyeHandle)

	end

	return nil

end

function FormatBullseyeTextBoxToACMI()

	if not bullseyeEditBoxHandle then 
		return
	end

	local textFromBullseyeBox = Tacview.UI.DialogBox.GetText( editEventDialogBoxHandle , bullseyeEditBoxHandle)

	local BRA = splitString(textFromBullseyeBox,"/")

	local bearing = BRA[1]
	local range = math.floor(Tacview.Math.Units.NauticalMilesToMeters(BRA[2])+0.5)
	local altitude = math.floor(Tacview.Math.Units.FeetToMeters( BRA[3]*1000 ))

	return bearing .. "/" .. range .. "/" .. altitude

end

function OnClickedCallback(dialogBoxHandle , controlHandle)

	local eventPropertyIndex = Tacview.Telemetry.GetGlobalTextPropertyIndex("Event", false )

	if eventPropertyIndex == Tacview.Telemetry.InvalidPropertyIndex then
		Tacview.UI.MessageBox.Error("There are no events in this file to be edited.")
		return
	end

	local textFromSourceIdBox 
	if sourceIdComboBoxHandle then
		local sourceIdSelectedItemIndex = Tacview.UI.DialogBox.GetSelectedItemIndex(dialogBoxHandle, sourceIdComboBoxHandle)
		textFromSourceIdBox = sourceAndTargetObjects[sourceIdSelectedItemIndex+1][2]
	end
	
	local textFromAmmoTypeBox
	if ammoTypeComboBoxHandle then
		local ammoTypeSelectedItemIndex = Tacview.UI.DialogBox.GetSelectedItemIndex(dialogBoxHandle, ammoTypeComboBoxHandle)
		textFromAmmoTypeBox = AmmoList[ammoTypeSelectedItemIndex+1]
	end

	local textfromTargetIdBox
	if targetIdComboBoxHandle then
		local targetIdSelectedItemIndex = Tacview.UI.DialogBox.GetSelectedItemIndex(dialogBoxHandle, targetIdComboBoxHandle)
		textfromTargetIdBox = sourceAndTargetObjects[targetIdSelectedItemIndex+1][2]
	end
		
	local textFromOutcomeBox
	if outcomeComboBoxHandle then
		local outcomeIdSelectedItemIndex = Tacview.UI.DialogBox.GetSelectedItemIndex(dialogBoxHandle, outcomeComboBoxHandle)
		textFromOutcomeBox = OutcomeList[outcomeIdSelectedItemIndex+1]
	end
	
	local textFromBullseyeBox 
	if bullseyeEditBoxHandle then
		textFromBullseyeBox = Tacview.UI.DialogBox.GetText( dialogBoxHandle , bullseyeEditBoxHandle)
	end
	
	local textFromBookmarkOrMessageEditBox 
	if bookmarkorMessageEditBoxHandle then
		textFromBookmarkOrMessageEditBox = Tacview.UI.DialogBox.GetText( dialogBoxHandle , bookmarkorMessageEditBoxHandle)
	end
	
	local textFromBookmarkOrMessageObjetIdBox = {}
	if bookmarkOrMessageComboBoxHandles then
		for i=1,#bookmarkOrMessageComboBoxHandles do		
			local selectedItemIndex = Tacview.UI.DialogBox.GetSelectedItemIndex(dialogBoxHandle, bookmarkOrMessageComboBoxHandles[i])
			textFromBookmarkOrMessageObjetIdBox[i] = sourceAndTargetObjects[selectedItemIndex+1][2]
		end
	end

	local msg = ""

	-- The function GetTextSampleIndex returns the index "at or immediately after the specified absoluteTime" 
	-- But we want the event at the specified time or BEFORE.

	local index = Tacview.Telemetry.GetTextSampleIndex( 0 , Tacview.Context.GetAbsoluteTime(), eventPropertyIndex )

	local event, eventTime = Tacview.Telemetry.GetTextSampleFromIndex( 0 , index , eventPropertyIndex ) -- Tacview 1.8.0
	
	local indexToUse

	if eventTime == Tacview.Context.GetAbsoluteTime() then
		indexToUse = index
	else
		indexToUse = index-1		
	end

	if indexToUse < 0 then
		Tacview.Log.Info("There is no event prior to this time which can be edited.")
		return
	end

	local _,sampleTime = Tacview.Telemetry.GetTextSampleFromIndex(0 , indexToUse , eventPropertyIndex)
	
	
	if eventType == "Timeout" then

		msg = "Timeout|"

		if textFromSourceIdBox then
			local sourceObjectId = ConvertToObjectId(textFromSourceIdBox)
			msg = msg .. 	"SourceId:" .. string.format("%X", sourceObjectId)
		end	
						
		if textFromAmmoTypeBox then
			msg = msg .. "|AmmoType:"..textFromAmmoTypeBox
		end

		if textfromTargetIdBox then
			local targetObjectId = ConvertToObjectId(textfromTargetIdBox)
			msg = msg .. 	"|TargetId:" .. string.format("%X", targetObjectId)
		end

		if textFromBullseyeBox then
			msg = msg .. "|Bullseye:"..FormatBullseyeTextBoxToACMI(textFromBullseyeBox)
		end

		if textFromOutcomeBox then
			msg = msg .. "|Outcome:"..textFromOutcomeBox
		end

	elseif eventType == "Bookmark" or "Message" then

		msg = eventType.."|"

		for i=1,#textFromBookmarkOrMessageObjetIdBox do
		
			if textFromBookmarkOrMessageObjetIdBox[i] then
				local objectId = ConvertToObjectId(textFromBookmarkOrMessageObjetIdBox[i])
				msg = msg .. string.format("%X",objectId) .. "|" 
			end
		end

		if textFromBookmarkOrMessageEditBox then	
			msg = msg .. textFromBookmarkOrMessageEditBox
		end

		if bookmarkExtraInfo then
			msg = msg .. "\xEF\xBF\xBF" .. bookmarkExtraInfo
		end
	end

	if sampleTime then

		Tacview.Telemetry.SetTextSample( 0 , sampleTime , eventPropertyIndex , msg) 
	
		Tacview.Log.Info("Event edited successfully. New event: " .. msg)	
	end

	Tacview.UI.DialogBox.Hide(editEventDialogBoxHandle)

	Tacview.UI.Update()

end

function OnHideCallBack()		-- if user clicks X or when I call DialogueBox.Hide()

event=nil
eventType=nil
editEventDialogBoxHandle=nil
sourceIdComboBoxHandle=nil
targetIdComboBoxHandle=nil
outcomeComboBoxHandle=nil
ammoTypeComboBoxHandle=nil
editButtonHandle=nil

bullseyeEditBoxHandle=nil
bullseyePickAPointButton=nil

bookmarkorMessageEditBoxHandle=nil
bookmarkOrMessageComboBoxHandles=nil

bookmarkOrMessageObjectIds=nil

messageEditBoxHandle=nil
messageComboBoxHandle=nil

bookmarkExtraInfo=nil

sourceIdObjectHandle=nil

sourceAndTargetObjects=nil	

end

function ConvertToObjectId(identifyingString)
		
	for i=1,#sourceAndTargetObjects do
		if sourceAndTargetObjects[i][2] == identifyingString then
			return Tacview.Telemetry.GetObjectId(sourceAndTargetObjects[i][1])
		end
	end

	return 0
end

local function OnContextMenu(contextMenuId, objectHandle)

	local eventPropertyIndex = Tacview.Telemetry.GetGlobalTextPropertyIndex("Event", false)
	
	if eventPropertyIndex == Tacview.Telemetry.InvalidPropertyIndex then
		return
	end

	local sampleIsValid
	
	event, sampleIsValid = Tacview.Telemetry.GetTextSample(0, Tacview.Context.GetAbsoluteTime(), eventPropertyIndex)
	
	if sampleIsValid and not editEventDialogBoxHandle then
		Tacview.UI.Menus.AddCommand(contextMenuId, "Edit Event", OnEditEvent)
		return
	end
end

local GetObjectHandleByIndex = Tacview.Telemetry.GetObjectHandleByIndex
local GetCurrentTags = Tacview.Telemetry.GetCurrentTags
local AnyGivenTagActive = Tacview.Telemetry.AnyGivenTagActive
local FixedWing = Tacview.Telemetry.Tags.FixedWing
local Rotorcraft = Tacview.Telemetry.Tags.Rotorcraft
local AntiAircraft = Tacview.Telemetry.Tags.AntiAircraft
local Watercraft = Tacview.Telemetry.Tags.Watercraft
local GetObjectCount = Tacview.Telemetry.GetObjectCount
local GetObjectId = Tacview.Telemetry.GetObjectId

function GetAllSourceAndTargetObjects()

	local objects = {}

	local objectCount = GetObjectCount()

	for i=0,objectCount-1 do		
	
		local objectHandle = GetObjectHandleByIndex( i )
		local objectTags = GetCurrentTags( objectHandle )
		local objectId = GetObjectId( objectHandle )

		if AnyGivenTagActive(objectTags, FixedWing|Rotorcraft|AntiAircraft|Watercraft) then	
			objects[#objects+1] = {objectHandle, GetUserFriendlyName(objectHandle)}
		end
	end

	return objects
end

local AddItem = Tacview.UI.DialogBox.AddItem

function LoadComboBox(dialogBoxHandle, comboBoxHandle, list)

	if not dialogBoxHandle or not comboBoxHandle or not list then
		return
	end

	for i=1, #list do
		AddItem( dialogBoxHandle , comboBoxHandle , list[i] )
	end
end

function OnContextMenuTest(testContextMenuId, objectHandle)

	Tacview.UI.Menus.AddCommand(testContextMenuId, "Test Menu Item", OnTestFunction)

end

	
----------------------------------------------------------------
-- Initialize this addon
----------------------------------------------------------------

function InitializeEditEvent()

	-- Declare context menu for the 3D view

	Tacview.UI.Renderer.ContextMenu.RegisterListener(OnContextMenu)
	Tacview.UI.Renderer.Pick3DPoint.RegisterListener(OnPickAPoint)

end
