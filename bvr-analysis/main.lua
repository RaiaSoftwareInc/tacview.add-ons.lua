
----------------------------------------------------------------
-- Setup
----------------------------------------------------------------

require("LuaStrict")
require("trigo")

local Tacview = require("Tacview186")

----------------------------------------------------------------
-- Constants
----------------------------------------------------------------

-- Special control characters to change the text color on the fly

local OrangeColor = string.char(2)
local DefaultColor = string.char(1)

local Margin = 8
local FontSize = 18
local FontColor = 0xFFA0FF46		-- HUD style green

local StatisticsRenderState =
{
	color = FontColor,
	blendMode = Tacview.UI.Renderer.BlendMode.Additive,
}



----------------------------------------------------------------
-- "BVR parameters"
----------------------------------------------------------------

local test, currentTime, objectHandle1, objectHandle2, distance, vr, vrb, vorth1, vorth2, deltaC1, deltaC2, deltaB1, deltaB2, deltaZ1, deltaZ2, speed1, speed2


-- Drawing data

local statisticsRenderStateHandle

----------------------------------------------------------------
-- 2D Rendering
----------------------------------------------------------------

function OnDrawTransparentUI()

	-- Compile render state

	if not statisticsRenderStateHandle then
		statisticsRenderStateHandle = Tacview.UI.Renderer.CreateRenderState(StatisticsRenderState)
	end
	
	local renderer = Tacview.UI.Renderer

	if objectHandle1 and objectHandle2 then
		local BVRinfo1 = "Distance: "..OrangeColor..distance.." Nm"..DefaultColor
							.."\nVr: "..OrangeColor..vr.." kt"..DefaultColor
							.."\nVrb: "..OrangeColor..vrb.." kt"..DefaultColor
							.."\nSpeed: "..OrangeColor..speed1.." kt"..DefaultColor
							.."\nδb: "..OrangeColor..deltaB1..DefaultColor
							.."\nδc: "..OrangeColor..deltaC1..DefaultColor
							.."\nΔZ: "..OrangeColor..deltaZ1.." ft"..DefaultColor
							-- .."\nTest: "..test
							

		local transform =
		{
			x = Margin,
			y = (renderer.GetHeight() + 4 * FontSize) / 2,
			scale = FontSize,
		}

		renderer.Print(transform, statisticsRenderStateHandle, BVRinfo1)
	end

end

----------------------------------------------------------------
-- Main loop
----------------------------------------------------------------

-- Update is called once a frame by Tacview

function OnUpdate(dt, absoluteTime)

if Tacview.Telemetry.IsLikeEmpty()==true then
	return
end

-- "Get Selected objects"
objectHandle1=Tacview.Context.GetSelectedObject( 0 )
objectHandle2=Tacview.Context.GetSelectedObject( 1 )
currentTime= Tacview.Context.GetAbsoluteTime()

-- print("objectID", objectHandle1, objectHandle2)

	if objectHandle1 and objectHandle2  then

		local objectTransform1=Tacview.Telemetry.GetCurrentTransform( objectHandle1 )
		local objectTransform2=Tacview.Telemetry.GetCurrentTransform( objectHandle2 )

		distance=round(Tacview.Math.Vector.GetDistanceBetweenObjects(objectTransform1, objectTransform2)/1852,1)

		deltaB1=round(GetTargetAspectAngle(objectTransform1, objectTransform2)*180/math.pi,0)
		if deltaB1<0 then deltaB1 = math.abs(deltaB1).."°G" else deltaB1=math.abs(deltaB1).."°D" end
		deltaB2=round(GetTargetAspectAngle(objectTransform2, objectTransform1)*180/math.pi,0)
		if deltaB2<0 then deltaB2 = math.abs(deltaB2).."°G" else deltaB2=math.abs(deltaB2).."°D" end
		
		deltaC1=round(GetAntennaTrainAngle3D(objectTransform1, objectTransform2)*180/math.pi,0)
		if deltaC1<0 then deltaC1 = math.abs(deltaC1).."°G" else deltaC1=math.abs(deltaC1).."°D" end
		deltaC2=round(GetAntennaTrainAngle3D(objectTransform2, objectTransform1)*180/math.pi,0)
		if deltaC2<0 then deltaC2 = math.abs(deltaC2).."°G" else deltaC2=math.abs(deltaC2).."°D" end
		
		deltaZ1=round((objectTransform1.altitude-objectTransform2.altitude)/0.305,-2)
		deltaZ2=-deltaZ1
		
		local objectTransform1=Tacview.Telemetry.GetTransform(objectHandle1, currentTime+0.2)
		local objectTransform2=Tacview.Telemetry.GetTransform(objectHandle2, currentTime+0.2)
		local objectTransform1Early=Tacview.Telemetry.GetTransform(objectHandle1, currentTime-0.2)
		local objectTransform2Early=Tacview.Telemetry.GetTransform(objectHandle2, currentTime-0.2)
		speed1=Tacview.Math.Vector.GetDistanceBetweenObjects(objectTransform1Early, objectTransform1)/0.4
		speed2=Tacview.Math.Vector.GetDistanceBetweenObjects(objectTransform2Early, objectTransform2)/0.4
		
		speed1=round(speed1*3600/1852,0)
		speed2=round(speed2*3600/1852,0)
		
		
		
		
		local distanceEarly=Tacview.Math.Vector.GetDistanceBetweenObjects(objectTransform1Early, objectTransform2Early)/0.4
		local distanceLate=Tacview.Math.Vector.GetDistanceBetweenObjects(objectTransform1, objectTransform2)/0.4
		vr=(distanceEarly-distanceLate)
		-- vr, vorth1=GetVrAndVorth(objectHandle1, objectHandle2, currentTime)
		-- vr, vorth2=GetVrAndVorth(objectHandle2, objectHandle1, currentTime)	
		vr=round(vr*3600/1852,0)
		
		vrb=GetVrb(objectHandle1, objectHandle2, currentTime)
		vrb=round(vrb*3600/1852,0)
		-- vorth1=round(vorth1*3600/1852,0)
		-- vorth2=round(vorth2*3600/1852,0)
		
	end
end

----------------------------------------------------------------
-- Initialize this addon
----------------------------------------------------------------

function Initialize()

	-- Declare addon properties

	local currentAddOn = Tacview.AddOns.Current

	currentAddOn.SetTitle("BVR Analysis")
	currentAddOn.SetVersion("1.0.0")
	currentAddOn.SetAuthor("Tickler")
	currentAddOn.SetNotes("Display advanced informations for BVR engagement.")

	-- Register callbacks

	Tacview.Events.Update.RegisterListener(OnUpdate)

	Tacview.Events.DrawTransparentUI.RegisterListener(OnDrawTransparentUI)
	
	
end

Initialize()

