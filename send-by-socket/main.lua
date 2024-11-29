
-- Tutorial on how to send data by socket
-- Author: Erin 'BuzyBee' O'Reilly
-- Last update: 2023-01-30 (Tacview 1.8.9)

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

require("LuaStrict")

local Tacview = require("Tacview188")

local host = "127.0.0.1"
local port = 55555
local tcp

function InitializeSocket()

	local socket = require("socket")
	
	tcp = assert(socket.tcp())
	
	print("tcp: " .. tostring(tcp))
	
	local success, err = tcp:connect(host,port)
	
	if not success then
		Tacview.Log.Error("Attempt to connect: " .. err)
	end
	
end

function OnUpdate(dt, absoluteTime)

	tcp:send(absoluteTime .. "\n")

end

function OnShutdown()

	tcp:close()

end



----------------------------------------------------------------
-- Initialize this addon
----------------------------------------------------------------

function Initialize()

	-- Declare addon properties

	local currentAddOn = Tacview.AddOns.Current

	currentAddOn.SetTitle("Tutorial - Send by Socket")
	currentAddOn.SetVersion("0.1")
	currentAddOn.SetAuthor("BuzyBee")
	currentAddOn.SetNotes("Demonstrate how to send data by socket.")

	-- Declare menus

	local addOnMenuId = Tacview.UI.Menus.AddMenu(nil, "Tutorial - Send by Socket")

	-- Initialize services

	InitializeSocket()

	-- Register callbacks

	Tacview.Events.Update.RegisterListener(OnUpdate)
	Tacview.Events.Shutdown.RegisterListener(OnShutdown)


end

Initialize()
