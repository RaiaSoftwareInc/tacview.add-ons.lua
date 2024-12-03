
-- Event Log Extras
-- Author: Erin 'BuzyBee' O'REILLY
-- Last update: 2024-11-28 (Tacview 1.9.4)

-- Feel free to modify and improve this script!

--[[

MIT License

Copyright (c) 2024 Raia Software Inc.

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

local Tacview = require("Tacview194")


local function OnContextMenu(contextMenuId, objectHandle)

	local eventPropertyIndex = Tacview.Telemetry.GetGlobalTextPropertyIndex("Event", false)
	
	if eventPropertyIndex == Tacview.Telemetry.InvalidPropertyIndex then
		print("no event")
		return
	end
	
	local event, sampleIsValid = Tacview.Telemetry.GetTextSample(0, Tacview.Context.GetAbsoluteTime(), eventPropertyIndex)
	
	if sampleIsValid then
		
		print(event)
		
		--Tacview.UI.Menus.AddCommand(contextMenuId, "Edit Event", OnEditEvent)
		
	end


end

function OnEditEvent()

	print("editing event")

	local dialogueBoxHangle = Tacview.UI.DialogBox.Create( "Edit Event" , 0 , 0 , "" )
	
	Tacview.UI.DialogBox.Show(dialogueBoxHangle)

end
	
----------------------------------------------------------------
-- Initialize this addon
----------------------------------------------------------------

function InitializeEditEvent()

	-- Declare context menu for the 3D view

	Tacview.UI.Renderer.ContextMenu.RegisterListener(OnContextMenu)
end
