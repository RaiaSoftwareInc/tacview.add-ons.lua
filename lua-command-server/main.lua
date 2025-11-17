
--[[
	Lua Command Server
	Executes Lua instructions recieved via a TCP socket.

	Author: Vyrtuoz
	Last update: 2025-08-14 (Tacview 1.9.5)

	Feel free to modify and improve this script!
--]]

--[[

	MIT License

	Copyright (c) 2019-2025 Raia Software Inc.

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

-- Compilation

require("lua-strict")

-- APIs

local server = require("server")
local Tacview = require("Tacview195")

-- Constants

local AddOnName = "Lua Command Server"
local AddOnVersion = "1.9.5"

----------------------------------------------------------------
-- Initialization
----------------------------------------------------------------

function OnInitialize()

	server.Initialize(AddOnName, AddOnVersion)

end

----------------------------------------------------------------
-- Shutdown
----------------------------------------------------------------

function OnShutdown()

	server.Shutdown()

end

----------------------------------------------------------------
-- Execute new instructions
----------------------------------------------------------------

function OnUpdate(dt, absoluteTime)

	server.Update(dt)

end

----------------------------------------------------------------
-- Initialize this addon
----------------------------------------------------------------

function Initialize()

	-- Declare add-on information

	Tacview.AddOns.Current.SetTitle(AddOnName)
	Tacview.AddOns.Current.SetVersion(AddOnVersion)
	Tacview.AddOns.Current.SetAuthor("Vyrtuoz")
	Tacview.AddOns.Current.SetNotes("Executes Lua instructions recieved via a TCP socket.")

	-- Register callbacks

	Tacview.Events.Update.RegisterListener(OnUpdate)
	Tacview.Events.Shutdown.RegisterListener(OnShutdown)

	-- Start the server

	OnInitialize()

end

Initialize()
