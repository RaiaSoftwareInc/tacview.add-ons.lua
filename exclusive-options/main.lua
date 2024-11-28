
-- Tutorial - Exclusive Menu Options
-- Author: Erin 'BuzyBee' O'Reilly
-- Last update: 2023-07-28 (Tacview 1.9.0)

-- IMPORTANT: This script act both as a tutorial and as a real addon for Tacview.
-- Feel free to modify and improve this script!

--[[

MIT License

Copyright (c) 2023 Raia Software Inc.

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
local Tacview = require("Tacview190")

local exclusiveOption1 = true -- default
local exclusiveOption2 = false
local exclusiveOption3 = false

local exclusiveOption1MenuHandle
local exclusiveOption2MenuHandle
local exclusiveOption3MenuHandle

function UpdateMenus()

	-- Update menu with the new option value

	Tacview.UI.Menus.SetOption(exclusiveOption1MenuHandle, exclusiveOption1)
	Tacview.UI.Menus.SetOption(exclusiveOption2MenuHandle, exclusiveOption2)
	Tacview.UI.Menus.SetOption(exclusiveOption3MenuHandle, exclusiveOption3)

end


function OnExclusiveOption1()

	exclusiveOption1 = not exclusiveOption1
	exclusiveOption2 = false
	exclusiveOption3 = false

	UpdateMenus()
end

function OnExclusiveOption2()

	exclusiveOption1 = false
	exclusiveOption2 = not exclusiveOption2
	exclusiveOption3 = false

	UpdateMenus()
end

function OnExclusiveOption3()

	exclusiveOption1 = false
	exclusiveOption2 = false
	exclusiveOption3 = not exclusiveOption3


	UpdateMenus()
end


----------------------------------------------------------------
-- Initialize this addon
----------------------------------------------------------------

function Initialize()

	Tacview.AddOns.Current.SetTitle("Exclusive Options")
	Tacview.AddOns.Current.SetVersion("0.1")
	Tacview.AddOns.Current.SetAuthor("BuzyBee")
	Tacview.AddOns.Current.SetNotes("Tutorial on how to use exclusive menu options.")

	local mainMenuHandle = Tacview.UI.Menus.AddMenu(nil, "Exclusive Options")

	exclusiveOption1MenuHandle = Tacview.UI.Menus.AddExclusiveOption( mainMenuHandle , "Exclusive Option 1" , exclusiveOption1 , OnExclusiveOption1 )
	exclusiveOption2MenuHandle = Tacview.UI.Menus.AddExclusiveOption( mainMenuHandle , "Exclusive Option 2" , exclusiveOption2 , OnExclusiveOption2 )
	exclusiveOption3MenuHandle = Tacview.UI.Menus.AddExclusiveOption( mainMenuHandle , "Exclusive Option 3" , exclusiveOption3 , OnExclusiveOption3 )


end

Initialize()
