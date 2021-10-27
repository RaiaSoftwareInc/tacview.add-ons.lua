
-- Checking global-variable declaration
-- Programming in Programming in Lua Fourth edition
-- by Roberto Ierusalimschy.
-- ISBN 8590379868

-- This is an official code to automatically detect undeclared global variables in Lua.
-- Thanks to the way Lua is working, the performance is negligible.

local declaredNames = {}
setmetatable(_G, {
  __newindex = function (t, n, v)
  if not declaredNames[n] then
    local w = debug.getinfo(2, "S").what
    if w ~= "main" and w ~= "C" then
      error("attempt to write to undeclared variable "..n, 2)
    end
    declaredNames[n] = true
  end
  rawset(t, n, v) -- do the actual set
  end,
  __index = function (_, n)
  if not declaredNames[n] then
    error("attempt to read undeclared variable "..n, 2)
  else
    return nil
  end
  end,
})

-- If you want to declare a global variable from a function,
-- then you can use the following helper:

function declareGlobal (name, initval)
  rawset(_G, name, initval or false)
end

-- If we need to test whether a variable exists, we cannot simply compare it to nil because, if it is nil, the
-- access will raise an error. Instead, we use rawget, which avoids the metamethod:

function isGlobalDeclared (name)
  return rawget(_G, name) ~= nil
end
