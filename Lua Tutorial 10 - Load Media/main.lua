
-- Load media tutorial for Tacview
-- Author: Erin 'BuzyBee' O'Reilly
-- Last update: 2020-12-17 (Tacview 1.8.0)

-- Feel free to modify and improve this script!

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

----------------------------------------------------------------
-- Setup
----------------------------------------------------------------

require("LuaStrict")

local Tacview = require("Tacview185")

----------------------------------------------------------------
-- Constants
----------------------------------------------------------------

local NumberOfMediaWindowsAvailable = 4

----------------------------------------------------------------
-- Menu callbacks
----------------------------------------------------------------

function OnLoadMediaFile()

	-- Request file name(s) of media file(s) from user

	local openFileNameOptions =
		{
			defaultFileExtension = "mp4",
			multiSelection = true,

			fileTypeList =									
			{
				{"*.mp4;*.ogg", "Media"},
				-- Add more file types as desired 
			}
		}

	local fileNames = Tacview.UI.MessageBox.GetOpenFileName(openFileNameOptions)

	if not fileNames then
		Tacview.Log.Info("LOAD MEDIA: No files selected")
		return
	end

	-- Load the file(s)

	local playerId = 0

	local numberOfFilesToLoad = math.min(#fileNames, NumberOfMediaWindowsAvailable)
	
	for fileNameIndex = 1, numberOfFilesToLoad do
		Tacview.Media.Load(playerId, fileNames[fileNameIndex])
		playerId = playerId + 1
	end	
end

----------------------------------------------------------------
-- Initialize this addon
----------------------------------------------------------------

function Initialize()

	-- Declare addon properties

	local currentAddOn = Tacview.AddOns.Current

	currentAddOn.SetTitle("Lua Tutorial 10 - Load Media")
	currentAddOn.SetVersion("1.8.5")
	currentAddOn.SetAuthor("BuzyBee")
	currentAddOn.SetNotes("Shows how to load a media file programatically.")

	-- Create a menu item

	local mainMenuHandle = Tacview.UI.Menus.AddCommand(nil, "Load Media File", OnLoadMediaFile)

end

Initialize()
