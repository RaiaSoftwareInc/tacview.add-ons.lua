
-- It is suggested to load LuaStrict.lua to make sure you do not access undefined variables by mistake.

require("LuaStrict")

-- Each Lua addon runs in its own virtual machine, so you can do whatever you want in your scripts,
-- this will not prevent other addons from running properly.

-- In Tacview, Lua if full 64-bit and all the default libraries are loaded and available to the user.

print("LuaStrict tutorial test:")

declareGlobal("MyGlobalVariable", math.pi)

if isGlobalDeclared("MyGlobalVariable") then
	print("pi="..MyGlobalVariable)
end

local localVariable = 2 * MyGlobalVariable

print("2*pi="..localVariable)

-- With LuaStrict the following code will trigger an error because AnotherGlobalVariable is not declared.

-- Uncomment the following line to test LuaStrict:
-- local anotherLocalVariable = AnotherGlobalVariable + 2
