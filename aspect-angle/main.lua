
--[[
	Aspect Angle
	Print Aspect Angle

	Author: BuzyBee
	Last update: 2024-03-08 (Tacview 1.9.3)

	Feel free to modify and improve this script!
--]]

--[[

	MIT License

	Copyright (c) 2024 Raia Software Inc.

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

local Tacview = require("Tacview193")

function OnUpdate(dt, absoluteTime)

	local handle0= Tacview.Context.GetSelectedObject(0)
	local handle1= Tacview.Context.GetSelectedObject(1)
	
	if not (handle0 and handle1) then
		return
	end
	
	local transform0 = Tacview.Telemetry.GetTransform(handle0, absoluteTime)

    local transform1 = Tacview.Telemetry.GetTransform(handle1, absoluteTime)
	
    local P0 = { x = transform0.x, y = transform0.y, z = transform0.z}

    local P1 = { x = transform1.x, y = transform1.y, z = transform1.z}
	
	local LOS = Tacview.Math.Vector.Subtract(P0, P1)
	
	local targetTransformYawOnly = transform1
	
	targetTransformYawOnly.roll = 0
	targetTransformYawOnly.pitch = 0
	
	local pointForward2D = Tacview.Math.Vector.LocalToGlobal( targetTransformYawOnly , {x=0,y=0,z=-1})
	local pointRight2D = Tacview.Math.Vector.LocalToGlobal( targetTransformYawOnly , {x=1,y=0,z=0} )
	
	local targetForwardVector = Tacview.Math.Vector.Subtract(pointForward2D, P1)
	local targetRightVector = Tacview.Math.Vector.Subtract(pointRight2D, P1)
	
	local forwardProjection = DotProduct(targetForwardVector,LOS)
	local rightProjection = DotProduct(targetRightVector,LOS)
	
	local aspectAngle = Tacview.Math.Angle.NormalizePi(math.atan(forwardProjection, rightProjection) + math.pi/2) 
	
	local suffix = ""
	local signAdjustedAspectAngle
	
	if aspectAngle<0 then
		suffix="L"
		signAdjustedAspectAngle = -1 * aspectAngle		
	elseif aspectAngle>0 then
		suffix = "R"
		signAdjustedAspectAngle = aspectAngle
	end
	
	print(string.format("%03d",math.floor(math.deg(signAdjustedAspectAngle)+0.5)) .. suffix)

end

function DotProduct(vector1,vector2)

	return vector1.x*vector2.x + vector1.y*vector2.y + vector1.z*vector2.z

end

----------------------------------------------------------------
-- Initialize this addon
----------------------------------------------------------------

function Initialize()

	Tacview.AddOns.Current.SetTitle("Aspect Angle")
	Tacview.AddOns.Current.SetVersion("0.1")
	Tacview.AddOns.Current.SetAuthor("BuzyBee")
	Tacview.AddOns.Current.SetNotes("Print aspect angle")

	Tacview.Events.Update.RegisterListener(OnUpdate)
	
end

Initialize()
