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

local socket = require("socket")
local Tacview = require("Tacview195")

-- Configuration

local server = {}

server.HostAddress = "127.0.0.1"
server.PortNumber = 50505
server.SendExecutionResults = true

-- Internal state

local addOnName
local addOnVersion
local serverSocket = nil
local connectedClients = {} -- [socket] = { receiveBuffer = "" }

----------------------------------------------------------------
-- Initialization
----------------------------------------------------------------

function server.Initialize(newAddOnName, newAddOnVersion)

	-- Setup general configuration.

	addOnName = newAddOnName
	addOnVersion = newAddOnVersion

	-- Create a new TCP server.

	local errorMessage

	serverSocket, errorMessage = socket.bind(server.HostAddress, server.PortNumber)

	if not serverSocket then

		Tacview.Log.Error("Lua Command Server could not start: " .. tostring(errorMessage))
		return false

	end

	-- Configure server.

    serverSocket:settimeout(0)

	pcall(function() serverSocket:setoption("reuseaddr", true) end)

	local boundIp, boundPort = serverSocket:getsockname()

	if not boundIp then

		boundIp = server.HostAddress

	end

	if boundIp == "0.0.0.0" then

		boundIp = "all-interfaces"

	end

	if not boundPort then

		boundPort = server.PortNumber

	end

    Tacview.Log.Info("Lua Command Server is now listening for instructions on " .. boundIp .. ":" .. boundPort)

	-- Complete.

	return true

end

----------------------------------------------------------------
-- Shutdown
----------------------------------------------------------------

function server.Shutdown()

    Tacview.Log.Info("Shutting down Lua Command Server.")

	-- Disconnect clients.

    for clientSocket,_ in pairs(connectedClients) do

        pcall(function() clientSocket:close() end)

    end

	-- Shutdown server connection.

    connectedClients = {}

    if serverSocket then

		pcall(function() serverSocket:close() end)
		serverSocket = nil

	end
end

----------------------------------------------------------------
-- Send data back to client.
----------------------------------------------------------------

local function SocketSend(clientSocket, text)

    pcall(function() clientSocket:send(text .. "\n") end)

end

----------------------------------------------------------------
-- Tools.
----------------------------------------------------------------

function JsonEscape(str)

	return str:gsub
	(
		'[%z\1-\31\\"]'
		,
		function(c)

			local escape_map =
			{
				['"']  = '\\"',
				['\\'] = '\\\\',
				['\b'] = '\\b',
				['\f'] = '\\f',
				['\n'] = '\\n',
				['\r'] = '\\r',
				['\t'] = '\\t',
			}

			return escape_map[c] or string.format("\\u%04x", c:byte())
		end
	)
end

----------------------------------------------------------------
-- Read data from client.
----------------------------------------------------------------

local function ExecuteLuaCommand(clientSocket, commandText)

    -- Remove CR if CRLF

    if #commandText > 0 and commandText:sub(-1) == "\r" then

        commandText = commandText:sub(1, -2)

    end

	-- Anything to execute?

    if commandText == "" then

		return

	end

	-- Compile instruction.

	local func, err = load(commandText, nil, "t", connectedClients[clientSocket].sandbox)

    if not func then

		SocketSend(clientSocket, "{\"Type\":\"Error\",\"Message\":\"" .. JsonEscape(tostring(err)) .. "\"}")
		Tacview.Log.Error(connectedClients[clientSocket].ip .. ":" .. connectedClients[clientSocket].port .. ": " .. tostring(err))

        return

    end

	-- Execute instruction.

    local success, result = pcall(func)

    if not success then

        if server.SendExecutionResults then

            SocketSend(clientSocket, "{\"Type\":\"Error\",\"Message\":\"" .. JsonEscape(tostring(result)) .. "\"}")
			Tacview.Log.Error(connectedClients[clientSocket].ip .. ":" .. connectedClients[clientSocket].port .. ": " .. tostring(result))

        end

    else

        if server.SendExecutionResults then

            SocketSend(clientSocket, "{\"Type\":\"Output\",\"Result\":\"" .. JsonEscape(tostring(result)) .. "\"}")

        end
    end
end

local function ProcessClientBuffer(clientSocket, clientState)

    -- Check if enough data to execute.

    local buffer = clientState.receiveBuffer
    local lastNewlinePosition = buffer:match(".*()\n")

    if not lastNewlinePosition then

		return

	end

	-- Execute each complete line of text.

    local startPosition = 1

    while true do

        local newlinePosition = buffer:find("\n", startPosition, true)

        if not newlinePosition or newlinePosition > lastNewlinePosition then

			break

		end

        local commandLine = buffer:sub(startPosition, newlinePosition - 1)

        ExecuteLuaCommand(clientSocket, commandLine)

        startPosition = newlinePosition + 1

    end

	-- Remove executed instructions from text buffer.

    clientState.receiveBuffer = buffer:sub(lastNewlinePosition + 1)

end

local function ReadCommandsFromClient(clientSocket, clientState)

	-- Appends incoming data to a text buffer.

    local receivedData, receiveError, partialData = clientSocket:receive("*a")
    local chunk = receivedData or partialData

    if chunk and #chunk > 0 then

        clientState.receiveBuffer = clientState.receiveBuffer .. chunk
        ProcessClientBuffer(clientSocket, clientState)

    end

	-- Remove client from the socket list when closed.

    if receiveError == "closed" then

		Tacview.Log.Info("Client ".. connectedClients[clientSocket].ip .. ":" .. connectedClients[clientSocket].port .. " disconnected.")

        connectedClients[clientSocket] = nil

        pcall(function() clientSocket:close() end)

        return false

    end

	-- Receive complete.

    return true

end

----------------------------------------------------------------
-- Execute new instructions
----------------------------------------------------------------

function server.Update(dt)

    -- Accept new connections requests.

    if serverSocket then

        while true do

            local newClientSocket = serverSocket:accept()

            if not newClientSocket then

				break

			end

            newClientSocket:settimeout(0)

			local clientIp, clientPort = newClientSocket:getpeername()

            connectedClients[newClientSocket] = { receiveBuffer = "", ip = clientIp, port = clientPort, sandbox = {}}
			setmetatable(connectedClients[newClientSocket].sandbox, {__index = _G})

			Tacview.Log.Info("Listening to new client ".. clientIp .. ":" .. clientPort .. " for Lua instructions.")

            SocketSend(newClientSocket, "{\"Type\":\"ServerReady\",\"Name\":\"".. JsonEscape(addOnName) .."\",\"Version\":\"".. JsonEscape(addOnVersion) .."\"}")

        end
    end

    -- Execute commands from existing clients.

    local readList = {}

    for clientSocket,_ in pairs(connectedClients) do

        table.insert(readList, clientSocket)

    end

    if #readList > 0 then

        local readableSockets = socket.select(readList, nil, 0)

        for _, clientSocket in ipairs(readableSockets) do

            local clientState = connectedClients[clientSocket]

            if clientState then

				-- ReadCommandsFromClient will remove closed sockets from the list.

				ReadCommandsFromClient(clientSocket, clientState)

			end
        end
    end
end

----------------------------------------------------------------
-- Returns an Instance of this Server to client code.
----------------------------------------------------------------

return server
