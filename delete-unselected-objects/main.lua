
--[[
	Delete Unselected Objects

	Author: BuzyBee
	Last update: 2024-09-06 (Tacview 1.9.4)

	Feel free to modify and improve this script!
--]]

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

require("lua-strict")

-- Request Tacview API

local Tacview = require("Tacview194")

function OnCleanUp()

	-- Get the pilot names of the objects which will NOT be deleted

	local pilotPropertyIndex = Tacview.Telemetry.GetObjectsTextPropertyIndex("Pilot", false)
	
	if pilotPropertyIndex == Tacview.Telemetry.InvalidPropertyIndex then
		return
	end
	
	local primaryObjectHandle = Tacview.Context.GetSelectedObject(0)
	local secondaryObjectHandle = Tacview.Context.GetSelectedObject(1)
	
	local referencePilot1 = ""
	local referencePilot1sampleIsValid = false
	
	if primaryObjectHandle then
	
		referencePilot1, referencePilot1sampleIsValid = Tacview.Telemetry.GetTextSample(primaryObjectHandle, Tacview.Context.GetAbsoluteTime(), pilotPropertyIndex) 
		
		if not referencePilot1sampleIsValid then
			referencePilot1 = ""
		end
	end
	
	local referencePilot2 = ""
	local referencePilot2sampleIsValid = false
	
	if secondaryObjectHandle then
	
		referencePilot2, referencePilot2sampleIsValid = Tacview.Telemetry.GetTextSample(secondaryObjectHandle, Tacview.Context.GetAbsoluteTime(), pilotPropertyIndex ) 
		
		if not referencePilot2sampleIsValid then
			referencePilot2 = ""
		end
	end	
	
	-- Check the pilot name of every object and delete it if it does NOT match

	local count = Tacview.Telemetry.GetObjectCount()
	
	local numberOfObjectsDeleted = 0
	
	local objectHandles = {}

	for index=0,count-1 do
		objectHandles[index] = Tacview.Telemetry.GetObjectHandleByIndex(index) 
	end
	
	for k,objectHandle in ipairs(objectHandles) do
		
		if objectHandle then 
			
			local pilot, sampleisValid = Tacview.Telemetry.GetTextSample(objectHandle, Tacview.Context.GetAbsoluteTime(), pilotPropertyIndex ) 
		
			-- do not delete weapons fired by reference pilots
			
			if not sampleisValid or pilot =="" or (pilot ~= referencePilot1 and pilot ~= referencePilot2) then
				
				local parentObjectHandle = Tacview.Telemetry.GetCurrentParentHandle(objectHandle) 
				
				if not parentObjectHandle then
					Tacview.Telemetry.DeleteObject(objectHandle)
					numberOfObjectsDeleted = numberOfObjectsDeleted + 1
					goto nextObjectHandle
				else
					local parentPilot, parentSampleIsValid = Tacview.Telemetry.GetTextSample(parentObjectHandle, Tacview.Context.GetAbsoluteTime(), pilotPropertyIndex ) 
					
					if not parentSampleIsValid or parentPilot == "" or (parentPilot ~= referencePilot1 and parentPilot ~= referencePilot2) then
						Tacview.Telemetry.DeleteObject(objectHandle)
						numberOfObjectsDeleted = numberOfObjectsDeleted + 1
					end
				end
			end
		end
		::nextObjectHandle::
	end
	
	Tacview.UI.Update()

	Tacview.UI.MessageBox.Info("Deleted " .. numberOfObjectsDeleted .. " objects which did not have the pilot name " .. referencePilot1 .. " or " .. referencePilot2)
	Tacview.Log.Info("Deleted " .. numberOfObjectsDeleted .. " objects which did not have the pilot name " .. referencePilot1 .. " or " .. referencePilot2)	
end


----------------------------------------------------------------
-- Add-on initialization
----------------------------------------------------------------

function Initialize()

	-- Declare add-on information

	Tacview.AddOns.Current.SetTitle("Delete Unselected Objects")
	Tacview.AddOns.Current.SetVersion("1.9.4")
	Tacview.AddOns.Current.SetAuthor("BuzyBee")
	Tacview.AddOns.Current.SetNotes("Remove all objects which do not have the pilot name of the selected objects.")

	Tacview.UI.Menus.AddCommand(nil, "Delete Unselected Objects", OnCleanUp)
	
	

end

Initialize()


