-- Load LuaSocket library
socket = require("socket")

-- DCS World server information
local serverIP = "127.0.0.1"  -- Change this to your DCS World server IP
local serverPort = 42674       -- Change this to your DCS World server port

-- Create a TCP socket
local client = socket.tcp()

-- Connect to the DCS World server
local success, err = client:connect(serverIP, serverPort)

if not success then
    print("Failed to connect to DCS World:", err)
else
	print("Connected to DCS World!")
end

-- Send a message to DCS World (replace this with your actual message)
local message = "XtraLib.Stream.0\nTacview.RealTimeTelemetry.0\nHost username\n38e095a027baf2bc"
client:send(message)

-- Receive response from DCS World
local response, err = client:receive()
if not response then
    print("Failed to receive response:", err)
else
	print("DCS World response:", response)
end

-- Close the connection
client:close()
