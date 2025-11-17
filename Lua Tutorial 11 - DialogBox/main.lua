
-- DialogBox demonstration from Lua
-- Author: Frantz 'Vyrtuoz' Raia
-- Last update: 2021-03-12 (Tacview 1.8.6)

-- Feel free to modify and improve this script!

--[[

MIT License

Copyright (c) 2021-2025 Raia Software Inc.

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

local Tacview = require("Tacview186")

----------------------------------------------------------------
-- Constants
----------------------------------------------------------------

----------------------------------------------------------------
-- Current state
----------------------------------------------------------------

local dialogBoxHandle = 0
local messageControlHandle = 0
local fuelControlHandle = 0
local sendMessageButtonHandle = 0

----------------------------------------------------------------
-- Tools
----------------------------------------------------------------

function UpdateSendButton()

	local dialogBox = Tacview.UI.DialogBox
	local textToSend = dialogBox.GetText(dialogBoxHandle, messageControlHandle)

	dialogBox.EnableControl(dialogBoxHandle, sendMessageButtonHandle, textToSend ~= "")
end

----------------------------------------------------------------
-- Events
----------------------------------------------------------------

-- Called whenever the dialog box has been closed

function OnDialogBoxHide(sourceDialogBoxHandle, sourceControlHandle)

	-- Use controlHandle to know if the user as clicked on your [OK] button
	-- so you can start appropriate operation if relevant

	Tacview.Log.Info("The dialog box "..sourceDialogBoxHandle.." has been closed by the command "..sourceControlHandle);

	dialogBoxHandle = 0
	messageControlHandle = 0
	fuelControlHandle = 0
	sendMessageButtonHandle = 0

end

function OnSendButtonClicked(sourceDialogBoxHandle, sourceControlHandle)

	Tacview.Log.Info("The button "..sourceControlHandle.." has been clicked in the dialog box "..sourceDialogBoxHandle);

	local dialogBox = Tacview.UI.DialogBox

	local textToSend = dialogBox.GetText(sourceDialogBoxHandle, messageControlHandle)

	if textToSend ~= "" then

		Tacview.Log.Info("Text ["..textToSend.."] has been sent.");

	end

	dialogBox.SetText(sourceDialogBoxHandle, messageControlHandle, "")
	dialogBox.EnableControl(dialogBoxHandle, sendMessageButtonHandle, false);
end

function OnFuelTrackingClicked(sourceDialogBoxHandle, sourceControlHandle)

	Tacview.Log.Info("The button "..sourceControlHandle.." has been clicked in the dialog box "..sourceDialogBoxHandle);

	local dialogBox = Tacview.UI.DialogBox

	local mustTrackFuel = dialogBox.IsBoxChecked(sourceDialogBoxHandle, fuelControlHandle)

	if mustTrackFuel then

		Tacview.Log.Info("Fuel tracking enabled");

	else

		Tacview.Log.Info("Fuel tracking DISABLED");

	end
end

function OnTextMessageChanged(sourceDialogBoxHandle, sourceControlHandle)

	UpdateSendButton()

end

----------------------------------------------------------------
-- Create and display the dialog box
----------------------------------------------------------------

-- You can use the following optional callback to save dialog box content

function OnDisplayDialogBox()

	local dialogBox = Tacview.UI.DialogBox

	-- Check parameters

	if dialogBoxHandle ~= 0 then
		return
	end

	-- Create the dialog box

	-- Remember that all coordinates are in Dialog Units (not pixels)
	-- Dialog units are proportional to the current font size.

	-- The optional last parameter is a local id used by Tacview to automatically restore previous position for this dialog box

	dialogBoxHandle = dialogBox.Create("Link 16 Telemetry", 457, 240, "ConfigDialog")

	-- Connection parameters

	dialogBox.AddGroupBox(dialogBoxHandle, "Connection Parameters", 7, 7, 150 - 7, 240 - 2*7)

	dialogBox.AddText(dialogBoxHandle, "Host IP Address", 14, 30, 120)
	dialogBox.AddEditBox(dialogBoxHandle, "127.0.0.1", 14, 40, 120)

	dialogBox.AddText(dialogBoxHandle, "Host Port Number", 14, 70, 120)
	dialogBox.AddEditBox(dialogBoxHandle, "1234", 14, 80, 120)

	-- Messages filtering

	dialogBox.AddGroupBox(dialogBoxHandle, "Message Filtering", 150 + 7, 7, 150 - 7, 240 - 2*7)

	dialogBox.AddText(dialogBoxHandle, "Unit PPLI (J2)", 157 + 7, 30, 120)
	dialogBox.AddCheckBox(dialogBoxHandle, "Air", true, 157 + 7 + 7, 43, 60)
	dialogBox.AddCheckBox(dialogBoxHandle, "Surface", true, 157 + 7 + 7, 53, 60)

	dialogBox.AddText(dialogBoxHandle, "Track (J3)", 157 + 7, 70, 120)
	dialogBox.AddCheckBox(dialogBoxHandle, "Air", true, 157 + 7 + 7, 83, 60)
	dialogBox.AddCheckBox(dialogBoxHandle, "Surface", true, 157 + 7 + 7, 93, 60)

	dialogBox.AddText(dialogBoxHandle, "Other", 157 + 7, 110, 120)
	fuelControlHandle = dialogBox.AddCheckBox(dialogBoxHandle, "Fuel (J13)", false, 157 + 7 + 7, 123, 60, 0, OnFuelTrackingClicked)

	-- Send a message

	dialogBox.AddGroupBox(dialogBoxHandle, "Send Message", 300 + 7, 7, 150 - 7, 240 - 2*7)

	dialogBox.AddText(dialogBoxHandle, "FreeText (J28.2)", 307 + 7, 30, 120)
	messageControlHandle = dialogBox.AddEditBox(dialogBoxHandle, "", 307 + 7, 40, 120, 140, OnTextMessageChanged)
	sendMessageButtonHandle = dialogBox.AddButton(dialogBoxHandle, "Send", 344, 187, 60, 0, OnSendButtonClicked)

	-- Display the dialog box

	dialogBox.Show(dialogBoxHandle, OnDialogBoxHide)

	-- Update controls state (must be done after display)

	UpdateSendButton();
end

----------------------------------------------------------------
-- Initialize this addon
----------------------------------------------------------------

function Initialize()

	-- Declare addon properties

	local currentAddOn = Tacview.AddOns.Current

	currentAddOn.SetTitle("Lua Tutorial 11 - Dialog Box")
	currentAddOn.SetVersion("1.8.6")
	currentAddOn.SetAuthor("Vyrtuoz")
	currentAddOn.SetNotes("Shows how to display an interactive Dialog Box from Lua.")

	-- Create a menu item

	local mainMenuHandle = Tacview.UI.Menus.AddCommand(nil, "Dialog Box Demo", OnDisplayDialogBox)

end

Initialize()
