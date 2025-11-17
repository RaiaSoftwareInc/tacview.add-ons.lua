
-- LuaSocket dll is already integrated in Tacview.
-- Simply load the appropriate lua helper modules to access its features.

socket = require("socket")
print(socket._VERSION)

http = require("socket.http")
print(http.request("https://httpbin.org/user-agent"))
