
-- Carrier landing pattern
-- version 2.40

-- Made by Tickler

-- It is suggested to load LuaStrict.lua to make sure you do not access undefined variables by mistake.

--version 2.3 Z axis inverted -- FIXED
--version 2.4 pattern slightly modified to match NAVAIR 00-80T-105 

require("LuaStrict")

local Tacview = require("Tacview185")

function CosDeg(angle)
	return math.cos(angle/180*math.pi)
end

function SinDeg(angle)
	return math.sin(angle/180*math.pi)
end



----------------------------------------------------------------
-- Constants
----------------------------------------------------------------

local NoDisplayEnabledSettingName = "Hidden"
local CaseIEnabledSettingName = "Case I"
local CaseIIIEnabledSettingName = "Case III"
local MarshallIEnabledSettingName = "Display Case I Marshall"

local TrailWidth = 3.0				-- pixels
local WallWidth = 1.0				-- pixels
local TrailColor = 0xFFFFFF66		-- hud style blue
local MarshallColor = 0xFF0000FF	

-- Case I pattern (distances in m)

local CaseIWidth = 1.25*1852  --separation from the ship abeam+offset to the right at the beginning (0.1Nm)	
local CaseILength = 1*1852 --distance after overhead until the break
local DeckAngle = -9 --Angle between the BRC and the FB
local OverheadAlt= 800/3.28
local AbeamAlt = 600/3.28
local DeckAlt = 70/3.28
local GrooveAlt = 62+DeckAlt
local FinalLength= 0.55*1852
local LastTurnWidth = FinalLength*SinDeg(DeckAngle+180)+CaseIWidth-0.2*1852
local LastTurnCenter = FinalLength*SinDeg(DeckAngle+180)-LastTurnWidth/2
local LastTurnWake = FinalLength*CosDeg(DeckAngle)
local InitialLength	= 3*1852			--length of the initial segment
local MarshallAlt, MarshallDist, MarshallRad, MarshallLength, CaseIIIOffsetTemp, lastIndex
local CaseIIIOffset=0
local CaseIIIWP = {}


--Axis
-- +X : right side of the ship
-- +Y : Vertical up
-- +Z : ship front


local CaseIWP =
{
	0.2*1852,								 				OverheadAlt, 								InitialLength,						--Initial
	0.2*1852,								 				OverheadAlt, 								0,									-- overhead
	0.1*1852+CaseIWidth/2*(-1+CosDeg(0)), 					OverheadAlt, 								-(CaseILength+CaseIWidth/2*SinDeg(0)),						-- break
	0.1*1852+CaseIWidth/2*(-1+CosDeg(10)),  					OverheadAlt, 							-(CaseILength+CaseIWidth/2*SinDeg(10)),		--Break turn
	0.1*1852+CaseIWidth/2*(-1+CosDeg(20)),  					OverheadAlt, 							-(CaseILength+CaseIWidth/2*SinDeg(20)),		--Break turn
	0.1*1852+CaseIWidth/2*(-1+CosDeg(30)), 	 				OverheadAlt, 							-(CaseILength+CaseIWidth/2*SinDeg(30)),		--Break turn
	0.1*1852+CaseIWidth/2*(-1+CosDeg(40)), 					OverheadAlt, 							-(CaseILength+CaseIWidth/2*SinDeg(40)),		--Break turn
	0.1*1852+CaseIWidth/2*(-1+CosDeg(50)), 					OverheadAlt, 							-(CaseILength+CaseIWidth/2*SinDeg(50)),		--Break turn
	0.1*1852+CaseIWidth/2*(-1+CosDeg(60)), 					OverheadAlt, 							-(CaseILength+CaseIWidth/2*SinDeg(60)),		--Break turn
	0.1*1852+CaseIWidth/2*(-1+CosDeg(70)), 					OverheadAlt, 							-(CaseILength+CaseIWidth/2*SinDeg(70)),		--Break turn
	0.1*1852+CaseIWidth/2*(-1+CosDeg(80)),  					OverheadAlt, 							-(CaseILength+CaseIWidth/2*SinDeg(80)),		--Break turn
	0.1*1852+CaseIWidth/2*(-1+CosDeg(90)),  					OverheadAlt, 							-(CaseILength+CaseIWidth/2*SinDeg(90)),		--Break turn
	0.1*1852+CaseIWidth/2*(-1+CosDeg(100)), 					OverheadAlt, 							-(CaseILength+CaseIWidth/2*SinDeg(100)),		--Break turn
	0.1*1852+CaseIWidth/2*(-1+CosDeg(110)), 	 				OverheadAlt, 							-(CaseILength+CaseIWidth/2*SinDeg(110)),		--Break turn
	0.1*1852+CaseIWidth/2*(-1+CosDeg(120)), 					OverheadAlt, 							-(CaseILength+CaseIWidth/2*SinDeg(120)),
	0.1*1852+CaseIWidth/2*(-1+CosDeg(130)), 					OverheadAlt, 							-(CaseILength+CaseIWidth/2*SinDeg(130)),
	0.1*1852+CaseIWidth/2*(-1+CosDeg(140)), 					OverheadAlt, 							-(CaseILength+CaseIWidth/2*SinDeg(140)),
	0.1*1852+CaseIWidth/2*(-1+CosDeg(150)), 					OverheadAlt, 							-(CaseILength+CaseIWidth/2*SinDeg(150)),
	0.1*1852+CaseIWidth/2*(-1+CosDeg(160)), 					OverheadAlt, 							-(CaseILength+CaseIWidth/2*SinDeg(160)),
	0.1*1852+CaseIWidth/2*(-1+CosDeg(170)), 					OverheadAlt, 							-(CaseILength+CaseIWidth/2*SinDeg(170)),
	0.1*1852+CaseIWidth/2*(-1+CosDeg(180)), 					OverheadAlt, 							-(CaseILength+CaseIWidth/2*SinDeg(180)),
	0.1*1852-CaseIWidth,									AbeamAlt,									0,									-- Abeam
	LastTurnCenter-LastTurnWidth/2*CosDeg(0),		AbeamAlt-0/180*(AbeamAlt-GrooveAlt),		LastTurnWake+LastTurnWidth/2*SinDeg(0),		--last turn
	LastTurnCenter-LastTurnWidth/2*CosDeg(10),		AbeamAlt-10/180*(AbeamAlt-GrooveAlt),		LastTurnWake+LastTurnWidth/2*SinDeg(10),
	LastTurnCenter-LastTurnWidth/2*CosDeg(20),		AbeamAlt-20/180*(AbeamAlt-GrooveAlt),		LastTurnWake+LastTurnWidth/2*SinDeg(20),
	LastTurnCenter-LastTurnWidth/2*CosDeg(30),		AbeamAlt-30/180*(AbeamAlt-GrooveAlt),		LastTurnWake+LastTurnWidth/2*SinDeg(30),
	LastTurnCenter-LastTurnWidth/2*CosDeg(40),		AbeamAlt-40/180*(AbeamAlt-GrooveAlt),		LastTurnWake+LastTurnWidth/2*SinDeg(40),
	LastTurnCenter-LastTurnWidth/2*CosDeg(50),		AbeamAlt-50/180*(AbeamAlt-GrooveAlt),		LastTurnWake+LastTurnWidth/2*SinDeg(50),
	LastTurnCenter-LastTurnWidth/2*CosDeg(60),		AbeamAlt-60/180*(AbeamAlt-GrooveAlt),		LastTurnWake+LastTurnWidth/2*SinDeg(60),
	LastTurnCenter-LastTurnWidth/2*CosDeg(70),		AbeamAlt-70/180*(AbeamAlt-GrooveAlt),		LastTurnWake+LastTurnWidth/2*SinDeg(70),
	LastTurnCenter-LastTurnWidth/2*CosDeg(80),		AbeamAlt-80/180*(AbeamAlt-GrooveAlt),		LastTurnWake+LastTurnWidth/2*SinDeg(80),
	LastTurnCenter-LastTurnWidth/2*CosDeg(90),		AbeamAlt-90/180*(AbeamAlt-GrooveAlt),		LastTurnWake+LastTurnWidth/2*SinDeg(90),
	LastTurnCenter-LastTurnWidth/2*CosDeg(100),		AbeamAlt-100/180*(AbeamAlt-GrooveAlt),		LastTurnWake+LastTurnWidth/2*SinDeg(100),
	LastTurnCenter-LastTurnWidth/2*CosDeg(110),		AbeamAlt-110/180*(AbeamAlt-GrooveAlt),		LastTurnWake+LastTurnWidth/2*SinDeg(110),
	LastTurnCenter-LastTurnWidth/2*CosDeg(120),		AbeamAlt-120/180*(AbeamAlt-GrooveAlt),		LastTurnWake+LastTurnWidth/2*SinDeg(120),	
	LastTurnCenter-LastTurnWidth/2*CosDeg(130),		AbeamAlt-130/180*(AbeamAlt-GrooveAlt),		LastTurnWake+LastTurnWidth/2*SinDeg(130),	
	LastTurnCenter-LastTurnWidth/2*CosDeg(140),		AbeamAlt-140/180*(AbeamAlt-GrooveAlt),		LastTurnWake+LastTurnWidth/2*SinDeg(140),	
	LastTurnCenter-LastTurnWidth/2*CosDeg(150),		AbeamAlt-150/180*(AbeamAlt-GrooveAlt),		LastTurnWake+LastTurnWidth/2*SinDeg(150),	
	LastTurnCenter-LastTurnWidth/2*CosDeg(160),		AbeamAlt-160/180*(AbeamAlt-GrooveAlt),		LastTurnWake+LastTurnWidth/2*SinDeg(160),	
	LastTurnCenter-LastTurnWidth/2*CosDeg(170),		AbeamAlt-170/180*(AbeamAlt-GrooveAlt),		LastTurnWake+LastTurnWidth/2*SinDeg(170),	
	LastTurnCenter-LastTurnWidth/2*CosDeg(180),		AbeamAlt-180/180*(AbeamAlt-GrooveAlt),		LastTurnWake+LastTurnWidth/2*SinDeg(180),			--last turn
	-5,											DeckAlt,									50
}



local MarshallIWP = {}

for index=1, 37*3, 3 do
	MarshallIWP[index] = -1.75*1852*(1+CosDeg((index-1)/3*10))+0.1*1852
	MarshallIWP[index+1] = 2000/3.28
	MarshallIWP[index+2] = 1.75*1852*SinDeg((index-1)/3*10)				 			
end


lastIndex = #MarshallIWP
for index=1, 9*3, 3 do
	MarshallIWP[lastIndex+index] = MarshallIWP[lastIndex-2]+(index-1)/3*SinDeg(210)*InitialLength/5*2/3
	MarshallIWP[lastIndex+index+1] = 2000/3.28-(2000/3.28-OverheadAlt)*index/27
	MarshallIWP[lastIndex+index+2] = MarshallIWP[lastIndex]-(index-1)/3*CosDeg(210)*InitialLength/5*2/3
end
---[[
lastIndex = #MarshallIWP
for index=1, 19*3, 3 do
	MarshallIWP[lastIndex+index] = MarshallIWP[lastIndex-2]/2+0.1*1852+(MarshallIWP[lastIndex-2]/2-0.1*1852)*CosDeg((index-1)/3*10)	
	MarshallIWP[lastIndex+index+1] = OverheadAlt
	MarshallIWP[lastIndex+index+2] = MarshallIWP[lastIndex]-MarshallIWP[lastIndex-2]/2*SinDeg((index-1)/3*10)
end

--]]


function CaseIIIPatternUpdate()
	-- Case III constants
	MarshallAlt = 6000/3.28
	MarshallDist = 21*1852
	MarshallRad = 272/60/math.pi*1852  --250 kt IAS = 272 kt GS. Half turn in 60sec
	MarshallLength = 272/60*2*1852

	local WPindex
	local CaseIIIx, CaseIIIy, CaseIIIz, CaseIIIArcing

	-- Case III pattern construction
	
	for WPindex=1, 18*3, 3 do 							--Marshall cold turn	
		CaseIIIx = -MarshallDist+MarshallRad*SinDeg((WPindex-1)/3*10)
		CaseIIIy = MarshallRad*(CosDeg((WPindex-1)/3*10)-1)
		CaseIIIz = MarshallAlt
		CaseIIIWP[WPindex] = CaseIIIx*SinDeg(CaseIIIOffset)+CaseIIIy*CosDeg(CaseIIIOffset)
		CaseIIIWP[WPindex+1] = CaseIIIz
		CaseIIIWP[WPindex+2] = -(CaseIIIx*CosDeg(CaseIIIOffset)-CaseIIIy*SinDeg(CaseIIIOffset))
	end
	 
	for WPindex=18*3+1, 24*3, 3 do							-- Marshall cold leg
		CaseIIIx = -MarshallDist-(WPindex-(18*3+1))/3*1/5*MarshallLength
		CaseIIIy = -2*MarshallRad
		CaseIIIz = MarshallAlt
		CaseIIIWP[WPindex] = CaseIIIx*SinDeg(CaseIIIOffset)+CaseIIIy*CosDeg(CaseIIIOffset)
		CaseIIIWP[WPindex+1] = CaseIIIz
		CaseIIIWP[WPindex+2] = -(CaseIIIx*CosDeg(CaseIIIOffset)-CaseIIIy*SinDeg(CaseIIIOffset))
	end	
		
	for WPindex=24*3+1, 41*3, 3 do							-- Marshall hot
		CaseIIIx = -MarshallDist-MarshallLength+MarshallRad*SinDeg((WPindex-(24*3+1))/3*10+180)
		CaseIIIy = MarshallRad*(CosDeg((WPindex-(24*3+1))/3*10+180)-1)
		CaseIIIWP[WPindex] = CaseIIIx*SinDeg(CaseIIIOffset)+CaseIIIy*CosDeg(CaseIIIOffset)
		CaseIIIWP[WPindex+1] = CaseIIIz
		CaseIIIWP[WPindex+2] = -(CaseIIIx*CosDeg(CaseIIIOffset)-CaseIIIy*SinDeg(CaseIIIOffset))
	end	
	
	for WPindex=41*3+1, 47*3, 3 do							-- Marshall hot leg
		CaseIIIx = -MarshallDist-MarshallLength*(1-(WPindex-(41*3+1))/3*1/5)
		CaseIIIy = 0
		CaseIIIz = MarshallAlt
		CaseIIIWP[WPindex] = CaseIIIx*SinDeg(CaseIIIOffset)+CaseIIIy*CosDeg(CaseIIIOffset)
		CaseIIIWP[WPindex+1] = CaseIIIz
		CaseIIIWP[WPindex+2] = -(CaseIIIx*CosDeg(CaseIIIOffset)-CaseIIIy*SinDeg(CaseIIIOffset))
	end	

	for WPindex=47*3+1, 53*3, 3 do							-- Descent 
		CaseIIIx = -MarshallDist+(WPindex-(47*3+1))/3*1852
		CaseIIIy = 0
		CaseIIIz = MarshallAlt-(WPindex-(47*3+1))/3*1/6*(6000-1200)/3.28
		CaseIIIWP[WPindex] = CaseIIIx*SinDeg(CaseIIIOffset)+CaseIIIy*CosDeg(CaseIIIOffset)
		CaseIIIWP[WPindex+1] = CaseIIIz
		CaseIIIWP[WPindex+2] = -(CaseIIIx*CosDeg(CaseIIIOffset)-CaseIIIy*SinDeg(CaseIIIOffset))
	end	
	
	CaseIIIArcing = CaseIIIOffset
	for WPindex=53*3+1, 59*3, 3 do							-- Arcing 
		CaseIIIx = -12*1852
		CaseIIIy = 0
		CaseIIIz = 1200/3.28
		CaseIIIWP[WPindex] = CaseIIIx*SinDeg(CaseIIIArcing)+CaseIIIy*CosDeg(CaseIIIArcing)
		CaseIIIWP[WPindex+1] = CaseIIIz
		CaseIIIWP[WPindex+2] = -(CaseIIIx*CosDeg(CaseIIIArcing)-CaseIIIy*SinDeg(CaseIIIArcing))
		CaseIIIArcing=CaseIIIArcing-CaseIIIOffset/5
	end		
	
	CaseIIIWP[178]=0											--Dirty up 10 Nm
	CaseIIIWP[179]=1200/3.28
	CaseIIIWP[180]=10*1852
	
	CaseIIIWP[181]=0											-- Glide 3 Nm
	CaseIIIWP[182]=1200/3.28
	CaseIIIWP[183]=3*1852
	
	CaseIIIWP[184]=-20											-- Glide 3 Nm
	CaseIIIWP[185]=DeckAlt
	CaseIIIWP[186]=50
end

----------------------------------------------------------------
-- "Members"
----------------------------------------------------------------
local vertexListTrail = nil
local vertexListWall = nil
local vertexTrailMarshall = nil
local vertexWallMarshall = nil
local renderStateHandle = nil
local renderStateHandleMarshall = nil
currentCarrierTransform, isTransformValid = nil
currentCarrierAngled = nil



----------------------------------------------------------------
-- UI commands and options
----------------------------------------------------------------

local NoDisplayMenuId, CaseIEnabledMenuId, CaseIIIEnabledMenuId, MarshallIMenuId

local NoDisplayEnabled = false
local CaseIEnabled = true
local CaseIIIEnabled=false
local MarshallIEnabled = false

function NoDisplayEnableAddOn()

	NoDisplayEnabled = true
	CaseIEnabled = false
	CaseIIIEnabled = false

	Tacview.AddOns.Current.Settings.SetBoolean(NoDisplayEnabledSettingName, NoDisplayEnabled)
	Tacview.AddOns.Current.Settings.SetBoolean(CaseIEnabledSettingName, CaseIEnabled)
	Tacview.AddOns.Current.Settings.SetBoolean(CaseIIIEnabledSettingName, CaseIIIEnabled)

	Tacview.UI.Menus.SetOption(NoDisplayMenuId, NoDisplayEnabled)
	Tacview.UI.Menus.SetOption(CaseIEnabledMenuId, CaseIEnabled)
	Tacview.UI.Menus.SetOption(CaseIIIEnabledMenuId, CaseIIIEnabled)
	
end

function CaseIEnableAddOn()

	NoDisplayEnabled=false
	CaseIEnabled = true
	CaseIIIEnabled = false

	Tacview.AddOns.Current.Settings.SetBoolean(NoDisplayEnabledSettingName, NoDisplayEnabled)
	Tacview.AddOns.Current.Settings.SetBoolean(CaseIEnabledSettingName, CaseIEnabled)
	Tacview.AddOns.Current.Settings.SetBoolean(CaseIIIEnabledSettingName, CaseIIIEnabled)

	Tacview.UI.Menus.SetOption(NoDisplayMenuId, NoDisplayEnabled)
	Tacview.UI.Menus.SetOption(CaseIEnabledMenuId, CaseIEnabled)
	Tacview.UI.Menus.SetOption(CaseIIIEnabledMenuId, CaseIIIEnabled)
	
end

function CaseIIIEnableAddOn()

	NoDisplayEnabled = false
	CaseIEnabled = false
	CaseIIIEnabled = true
	
	Tacview.AddOns.Current.Settings.SetBoolean(NoDisplayEnabledSettingName, NoDisplayEnabled)
	Tacview.AddOns.Current.Settings.SetBoolean(CaseIEnabledSettingName, CaseIEnabled)
	Tacview.AddOns.Current.Settings.SetBoolean(CaseIIIEnabledSettingName, CaseIIIEnabled)

	Tacview.UI.Menus.SetOption(NoDisplayMenuId, NoDisplayEnabled)
	Tacview.UI.Menus.SetOption(CaseIEnabledMenuId, CaseIEnabled)
	Tacview.UI.Menus.SetOption(CaseIIIEnabledMenuId, CaseIIIEnabled)
end

function onEnterCaseIIIOffset()
	CaseIIIOffsetTemp = Tacview.UI.MessageBox.InputText(
							"Carrier Landing Pattern", 
							"Enter the angular offset in degrees (°)\n"..
							"This is the angle between the carrier's final bearing and the marshall radial.\n"..
							"Offset > 0: Marshall is offset to the left\n"..
							"Offset < 0: Marshall is offset to the right",
							tostring(CaseIIIOffset))
							
	print("Case III Offset temp : ", CaseIIIOffsetTemp)
	if CaseIIIOffsetTemp ~= nil then 
		CaseIIIOffset=CaseIIIOffsetTemp
	end
	CaseIIIPatternUpdate()
end

function MarshallIEnableAddOn()

	MarshallIEnabled=not MarshallIEnabled

	Tacview.AddOns.Current.Settings.SetBoolean(MarshallIEnabledSettingName, MarshallIEnabled)

	Tacview.UI.Menus.SetOption(MarshallIMenuId, MarshallIEnabled)

end

	
----------------------------------------------------------------
-- 2D Rendering
----------------------------------------------------------------

function DeclareRenderData()

	-- The render state is used to define how to draw the instrument.
	-- We only need to specify the texture in our case.

	if not renderStateHandle then

		local renderState =
		{
			color = TrailColor,
			blendMode = Tacview.UI.Renderer.BlendMode.Additive,
		}

		renderStateHandle = Tacview.UI.Renderer.CreateRenderState(renderState)

	end

	if not renderStateHandleMarshall then

		local renderState =
		{
			color = MarshallColor,
			blendMode = Tacview.UI.Renderer.BlendMode.Additive,
		}

		renderStateHandleMarshall = Tacview.UI.Renderer.CreateRenderState(renderState)

	end

end

function OnDrawTransparentObjects()

	-- Any data available?

	if not vertexListTrail or next(vertexListTrail) == nil then
		return
	end

	-- Make sure rendering data are declared (only once, during the first OnDrawTransparentUI call)

	DeclareRenderData()

	-- Draw the trail

	Tacview.UI.Renderer.DrawLines(renderStateHandle, WallWidth, vertexListWall)
	Tacview.UI.Renderer.DrawLineStrip(renderStateHandle, TrailWidth, vertexListTrail)
	
	if not vertexTrailMarshall or next(vertexTrailMarshall) == nil then
		return
	end
	
	Tacview.UI.Renderer.DrawLines(renderStateHandleMarshall, WallWidth, vertexWallMarshall)
	Tacview.UI.Renderer.DrawLineStrip(renderStateHandleMarshall, TrailWidth, vertexTrailMarshall)
	
end

-------------------------------------------------------------
-- Additional function
-------------------------------------------------------------


--------------------------------------------------------------
-- Main Loop
--------------------------------------------------------------

function OnUpdate(dt, absoluteTime)
	
	vertexListTrail = {}
	vertexListWall = {}
	vertexTrailMarshall = {}
	vertexWallMarshall = {}
	local LongitudeLatitudeToCartesian = Tacview.Math.Vector.LongitudeLatitudeToCartesian


	-- Add-On enabled ?
	
	if NoDisplayEnabled then
		return
	end
	
	local objectHandle = Tacview.Context.GetSelectedObject(0)
	
	-- if selected object (primary or secondary) is not AircraftCarrier, return
	if not objectHandle or (Tacview.Telemetry.GetCurrentTags(objectHandle) & Tacview.Telemetry.Tags.AircraftCarrier) == 0 then
		
		objectHandle = Tacview.Context.GetSelectedObject(1)
		
		if not objectHandle or (Tacview.Telemetry.GetCurrentTags(objectHandle) & Tacview.Telemetry.Tags.AircraftCarrier) == 0 then	
			return
			
		end
	
	end

	local trailItemIndex = 1
	local wallItemIndex = 1
		
	--get currentCarrierTransform position and track

	currentCarrierTransform, isTransformValid = Tacview.Telemetry.GetTransform( objectHandle, absoluteTime)

	if CaseIEnabled then
		for pointIndex=1,#CaseIWP-2,3 do

			local xyz = Tacview.Math.Vector.LocalToGlobal(currentCarrierTransform, {x=CaseIWP[pointIndex],y=CaseIWP[pointIndex+1],z=CaseIWP[pointIndex+2]})

			vertexListTrail[trailItemIndex] = {xyz.x, xyz.y, xyz.z}
			trailItemIndex = trailItemIndex + 1	

			local groundPoint = Tacview.Math.Vector.LocalToGlobal(currentCarrierTransform, {x=CaseIWP[pointIndex],y=0,z=CaseIWP[pointIndex+2]})

			vertexListWall[wallItemIndex] = {groundPoint.x, groundPoint.y, groundPoint.z}
			vertexListWall[wallItemIndex + 1] = {xyz.x, xyz.y, xyz.z}

			wallItemIndex = wallItemIndex + 2
		end
		
		if MarshallIEnabled then
			trailItemIndex=1
			wallItemIndex= 1
			
			for pointIndex=1,#MarshallIWP-2,3 do

				local xyz = Tacview.Math.Vector.LocalToGlobal(currentCarrierTransform, {x=MarshallIWP[pointIndex],y=MarshallIWP[pointIndex+1],z=MarshallIWP[pointIndex+2]})

				vertexTrailMarshall[trailItemIndex] = {xyz.x, xyz.y, xyz.z}
				trailItemIndex = trailItemIndex + 1	

				local groundPoint = Tacview.Math.Vector.LocalToGlobal(currentCarrierTransform, {x=MarshallIWP[pointIndex],y=0,z=MarshallIWP[pointIndex+2]})

				vertexWallMarshall[wallItemIndex] = {groundPoint.x, groundPoint.y, groundPoint.z}
				vertexWallMarshall[wallItemIndex + 1] = {xyz.x, xyz.y, xyz.z}

				wallItemIndex = wallItemIndex + 2
			end
		end
	elseif CaseIIIEnabled then
		currentCarrierAngled = currentCarrierTransform
		currentCarrierAngled.yaw = currentCarrierTransform.yaw+DeckAngle/180*math.pi  --Angular offset to be aligned with angled deck
		for pointIndex=1,#CaseIIIWP-2,3 do

			local xyz = Tacview.Math.Vector.LocalToGlobal(currentCarrierAngled, {x=CaseIIIWP[pointIndex],y=CaseIIIWP[pointIndex+1],z=CaseIIIWP[pointIndex+2]})


			vertexListTrail[trailItemIndex] = {xyz.x, xyz.y, xyz.z}
			trailItemIndex = trailItemIndex + 1		
			
			local groundPoint = Tacview.Math.Vector.LocalToGlobal(currentCarrierAngled, {x=CaseIIIWP[pointIndex],y=0,z=CaseIIIWP[pointIndex+2]})

			vertexListWall[wallItemIndex] = {groundPoint.x, groundPoint.y, groundPoint.z}
			vertexListWall[wallItemIndex + 1] = {xyz.x, xyz.y, xyz.z}

			wallItemIndex = wallItemIndex + 2
		end
	
	end
end


------------------------------------------------------------
-- Initialize this addOnEnableOption
------------------------------------------------------------

function Initialize()

 -- Declare addon propertiers
 
	local currentAddOn = Tacview.AddOns.Current
 
	currentAddOn.SetTitle("Carrier Landing Pattern")
	currentAddOn.SetVersion("2.4")
	currentAddOn.SetAuthor("Tickler")
	currentAddOn.SetNotes("Displays the carrier landing pattern")
	 
	--Load preferences
	--Use current addOnEnableOption value as the default setting
	 
	NoDisplayEnabled = Tacview.AddOns.Current.Settings.GetBoolean(NoDisplayEnabledSettingName, NoDisplayEnabled)
	CaseIEnabled = Tacview.AddOns.Current.Settings.GetBoolean(CaseIEnabledSettingName, CaseIEnabled)
	CaseIIIEnabled = Tacview.AddOns.Current.Settings.GetBoolean(CaseIIIEnabledSettingName, CaseIIIEnabled)

	MarshallIEnabled = Tacview.AddOns.Current.Settings.GetBoolean(MarshallIEnabledSettingName, MarshallIEnabled)
	 
	--Declare menus
 
	local addOnMenuId = Tacview.UI.Menus.AddMenu(nil, "Carrier Landing Pattern")

	NoDisplayMenuId = Tacview.UI.Menus.AddExclusiveOption(addOnMenuId, "Hidden", NoDisplayEnabled, NoDisplayEnableAddOn)
	CaseIEnabledMenuId = Tacview.UI.Menus.AddExclusiveOption(addOnMenuId, "Display Case I Pattern", CaseIEnabled, CaseIEnableAddOn)
	CaseIIIEnabledMenuId = Tacview.UI.Menus.AddExclusiveOption(addOnMenuId, "Display Case III Pattern", CaseIIIEnabled, CaseIIIEnableAddOn)

	Tacview.UI.Menus.AddSeparator(addOnMenuId)

	MarshallIMenuId=Tacview.UI.Menus.AddOption(addOnMenuId, "Display Case I Marshall", MarshallIEnabled, MarshallIEnableAddOn)

	Tacview.UI.Menus.AddSeparator(addOnMenuId)

	Tacview.UI.Menus.AddCommand(addOnMenuId, "Case III Angular Offset...", onEnterCaseIIIOffset)

	-- Register callbacks
	
	CaseIIIPatternUpdate()

	Tacview.Events.Update.RegisterListener(OnUpdate)

	Tacview.Events.DrawTransparentObjects.RegisterListener(OnDrawTransparentObjects)

end

Initialize()