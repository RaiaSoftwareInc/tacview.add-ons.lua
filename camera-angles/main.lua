
--[[
	Strike Fighter League

	Author: BuzyBee
	Last update: 2026-05-05 (Tacview 1.9.5)

	Feel free to modify and improve this script!
--]]

--[[

	MIT License

	Copyright (c) 2026 Raia Software Inc.

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

-- Request Tacview API

local Tacview = require("Tacview195")

local bfmTopDownSettingName = "BFM Top-Down"
local bfmTopDown = false
local bfmTopDownMenuHandle = nil

local bfmAircraftViewSettingName = "BFM Side View"
local bfmAircraftView = false
local bfmAircraftViewMenuHandle = nil

local trialAircraftViewSettingName = "Trial Aircraft View"
local trialAircraftView = false
local trialAircraftViewMenuHandle = nil

local trialTopViewSettingName = "Trial Top View"
local trialTopView = false
local trialTopViewMenuHandle = nil

local gateBoundsComputed  = false

--local backgroundRenderStateHandle
--local textRenderStateHandle

--local backgroundVertexArrayHandle

--local backgroundTransform1
--local backgroundTransform2
--local backgroundTransform3
--local backgroundTransform4

--local textTransform1
--local textTransform2
--local textTransform3
--local textTransform4

--local msg1
--local msg2

function OnBFMTopDown()

	bfmTopDown = not bfmTopDown

	Tacview.AddOns.Current.Settings.SetBoolean(bfmTopDownSettingName, bfmTopDown ) 

	Tacview.UI.Menus.SetOption(bfmTopDownMenuHandle, bfmTopDown ) 

	-- other options are false

	bfmAircraftView = false	
	Tacview.AddOns.Current.Settings.SetBoolean(bfmAircraftViewSettingName, false ) 
	Tacview.UI.Menus.SetOption(bfmAircraftViewMenuHandle, false )

	trialAircraftView = false	
	Tacview.AddOns.Current.Settings.SetBoolean(trialAircraftViewSettingName, false ) 
	Tacview.UI.Menus.SetOption(trialAircraftViewMenuHandle, false )	

	trialTopView = false
	Tacview.AddOns.Current.Settings.SetBoolean(trialTopViewSettingName, false ) 
	Tacview.UI.Menus.SetOption(trialTopViewMenuHandle, false ) 
end

function OnBFMSideView()

	bfmAircraftView = not bfmAircraftView

	Tacview.AddOns.Current.Settings.SetBoolean(bfmAircraftViewSettingName, bfmAircraftView ) 

	Tacview.UI.Menus.SetOption(bfmAircraftViewMenuHandle, bfmAircraftView ) 

	-- other options are false

	bfmTopDown = false
	Tacview.AddOns.Current.Settings.SetBoolean(bfmTopDownSettingName, false ) 
	Tacview.UI.Menus.SetOption(bfmTopDownMenuHandle, false )

	trialAircraftView = false	
	Tacview.AddOns.Current.Settings.SetBoolean(trialAircraftViewSettingName, false ) 
	Tacview.UI.Menus.SetOption(trialAircraftViewMenuHandle, false )

	trialTopView = false
	Tacview.AddOns.Current.Settings.SetBoolean(trialTopViewSettingName, false ) 
	Tacview.UI.Menus.SetOption(trialTopViewMenuHandle, false ) 

end

function OnTrialAircraftView()

	trialAircraftView = not trialAircraftView

	Tacview.AddOns.Current.Settings.SetBoolean(trialAircraftViewSettingName, trialAircraftView ) 

	Tacview.UI.Menus.SetOption(trialAircraftViewMenuHandle, trialAircraftView ) 

	-- other options are false

	bfmTopDown = false
	Tacview.AddOns.Current.Settings.SetBoolean(bfmTopDownSettingName, false ) 
	Tacview.UI.Menus.SetOption(bfmTopDownMenuHandle, false )

	bfmAircraftView = false
	Tacview.AddOns.Current.Settings.SetBoolean(bfmAircraftViewSettingName, false ) 
	Tacview.UI.Menus.SetOption(bfmAircraftViewMenuHandle, false )

	trialTopView = false
	Tacview.AddOns.Current.Settings.SetBoolean(trialTopViewSettingName, false ) 
	Tacview.UI.Menus.SetOption(trialTopViewMenuHandle, false ) 
end


function OnTrialTopView()

	trialTopView = not trialTopView

	Tacview.AddOns.Current.Settings.SetBoolean(trialAircraftViewSettingName, trialTopView ) 

	Tacview.UI.Menus.SetOption(trialAircraftViewMenuHandle, trialTopView ) 

	-- other options are false

	bfmTopDown = false
	Tacview.AddOns.Current.Settings.SetBoolean(bfmTopDownSettingName, false ) 
	Tacview.UI.Menus.SetOption(bfmTopDownMenuHandle, false )

	bfmAircraftView = false
	Tacview.AddOns.Current.Settings.SetBoolean(bfmAircraftViewSettingName, false ) 
	Tacview.UI.Menus.SetOption(bfmAircraftViewMenuHandle, false )

	trialAircraftView = false	
	Tacview.AddOns.Current.Settings.SetBoolean(trialAircraftViewSettingName, false ) 
	Tacview.UI.Menus.SetOption(trialAircraftViewMenuHandle, false )
end

function OnUpdate(dt, absoluteTime)

	if bfmTopDown then

		-- Satellite View

		if  Tacview.Settings.GetString("UI.View.Camera.Mode") ~= "Satellite" then
	
			Tacview.Settings.SetString("UI.View.Camera.Mode","Satellite")
		end	

		-- Focus the camera on the center between the two players
		-- (In Satellite View it is not necessary to place the camera in position)

		local player1 = Tacview.Context.GetSelectedObject(0) 
		local player2 = Tacview.Context.GetSelectedObject(1) 

		if not player1 or not player2 then
			return
		end

		local transform1 = Tacview.Telemetry.GetCurrentTransform(player1)
		local transform2 = Tacview.Telemetry.GetCurrentTransform(player2)

		local midpointVector = { 	x = (transform1.x + transform2.x)/2, 
									y =(transform1.y + transform2.y)/2, 
									z = (transform1.z + transform2.z)/2		}

		local cameraVectorSpherical = Tacview.Math.Vector.CartesianToLongitudeLatitude(midpointVector)

		Tacview.Context.Camera.SetSphericalPosition( cameraVectorSpherical.longitude , cameraVectorSpherical.latitude , cameraVectorSpherical.altitude )

		-- Set range based on bounding sphere

		local radius = 0.5 * Tacview.Math.Vector.GetDistanceBetweenObjects( transform1 , transform2 )

		local range = radius / math.sin(math.rad(60)/2)

		Tacview.Context.Camera.SetRangeToTarget( range )

	elseif bfmAircraftView then

		-- Dogfight Mode Centered

		if 	Tacview.Settings.GetString("UI.View.Camera.Mode") ~= "External" or
			not Tacview.Settings.GetBoolean("UI.View.Camera.Dogfight.Enabled") or
			Tacview.Settings.GetString("UI.View.Camera.Dogfight.Mode") ~= "Centered" then

			Tacview.Settings.SetString("UI.View.Camera.Mode","External")
			Tacview.Settings.SetBoolean("UI.View.Camera.Dogfight.Enabled", true)
			Tacview.Settings.SetString("UI.View.Camera.Dogfight.Mode", "Centered") 
		end		

		-- Set range based on bounding sphere

		local player1 = Tacview.Context.GetSelectedObject(0) 
		local player2 = Tacview.Context.GetSelectedObject(1) 

		if not player1 or not player2 then
			return
		end

		local transform1 = Tacview.Telemetry.GetCurrentTransform(player1)
		local transform2 = Tacview.Telemetry.GetCurrentTransform(player2)


		local radius = 0.5 * Tacview.Math.Vector.GetDistanceBetweenObjects( transform1 , transform2 )

		local range = radius / math.sin(math.rad(60)/2)

		Tacview.Context.Camera.SetRangeToTarget( range )

		-- Determine who is on offense vs. defense

		--[[local p1offense 
		local p2offense

		local P1 = {x = transform1.x, y = transform1.y, z = transform1.z}
		local P2 = {x = transform2.x, y = transform2.y, z = transform2.z}

		local forwardPoint1 = Tacview.Math.Vector.LocalToGlobal( transform1 , {x=0,y=0,z=-1})
		local forwardPoint2 =  Tacview.Math.Vector.LocalToGlobal( transform2 , {x=0,y=0,z=-1})

		local forwardVector1 = Tacview.Math.Vector.Subtract(forwardPoint1, P1)
		local forwardVector2 = Tacview.Math.Vector.Subtract(forwardPoint2, P2)

		local direction12 = Tacview.Math.Vector.Subtract(P2, P1) -- from player 1 to player 2
		local direction21 = Tacview.Math.Vector.Subtract(P1, P2) -- from player 2 to player 1
		
		local unitDirection12 = Tacview.Math.Vector.Normalize(direction12)
		local unitDirection21 = Tacview.Math.Vector.Normalize(direction21)
		
		local unitForwardVector1 = Tacview.Math.Vector.Normalize(forwardVector1)
		local unitForwardVector2 = Tacview.Math.Vector.Normalize(forwardVector2)
		
		local p1PointingAtP2 = unitForwardVector1.x*unitDirection12.x + unitForwardVector1.y*unitDirection12.y + unitForwardVector1.z*unitDirection12.z
		local p2PointingAtP1 = unitForwardVector2.x*unitDirection21.x + unitForwardVector2.y*unitDirection21.y + unitForwardVector2.z*unitDirection21.z

		if p1PointingAtP2 > 0.7 and p2PointingAtP1 < 0.3 then
			-- Player 1 is offensive
			p1offense = true
			p2offense = false
		elseif p2PointingAtP1 > 0.7 and p1PointingAtP2 < 0.3 then
			-- Player 2 is offensive
			p1offense	= false
			p2offense = true
		else
			p1offense = false
			p2offense = false
		end 

		local defensivePlayerTransform
		
		if p1offense then 
			defensivePlayerTransform = transform2
		elseif p2offense then		
			defensivePlayerTransform = transform1
		else
			if not defensivePlayerTransform then 
				-- initialize a random defender
				defensivePlayerTransform = transform1
			else
				--do not switch defenders
			end
		end	--]]

		-- True Side View (not helpful)

		--[[local vectorBetweenPlayers = Tacview.Math.Vector.Subtract({x = transform2.x, y = transform2.y, z = transform2.z} , {x = transform1.x, y = transform1.y, z = transform1.z} )

		local vectorBetweenPlayersNormalized = Tacview.Math.Vector.Normalize(vectorBetweenPlayers) 
	
		local midpointVector = { x = (transform1.x + transform2.x)/2, 
							y =(transform1.y + transform2.y)/2, 
							z = (transform1.z + transform2.z)/2	}

		local midpointVectorNormalized = Tacview.Math.Vector.Normalize(midpointVector) 

		local midpointVectorSpherical = Tacview.Math.Vector.CartesianToLongitudeLatitude(midpointVector)

		local crossVector = CrossProduct(vectorBetweenPlayersNormalized, midpointVectorNormalized)

		local crossVectorNormalized = Tacview.Math.Vector.Normalize(crossVector) 

		local radius = 0.5 * Tacview.Math.Vector.GetDistanceBetweenObjects( transform1 , transform2 )

		local range = radius / math.sin(math.rad(60)/2)

		local cameraVector =
		{
			x = midpointVector.x + range * crossVectorNormalized.x,
			y = midpointVector.y + range * crossVectorNormalized.y,
			z = midpointVector.z + range * crossVectorNormalized.z
		}

		local cameraVectorSpherical = Tacview.Math.Vector.CartesianToLongitudeLatitude(cameraVector)

		Tacview.Context.Camera.SetSphericalPosition( cameraVectorSpherical.longitude , cameraVectorSpherical.latitude , cameraVectorSpherical.altitude)
		
		local bearingRangeAltitude=
			Tacview.Math.Vector.LongitudeLatitudeToBearingRangeAltitude(
				cameraVectorSpherical.longitude,
				cameraVectorSpherical.latitude,
				cameraVectorSpherical.altitude,
				midpointVectorSpherical.longitude,
				midpointVectorSpherical.latitude,
				midpointVectorSpherical.altitude
			)

		local yaw = bearingRangeAltitude.bearing
		
		local pitch = math.atan( midpointVectorSpherical.altitude - cameraVectorSpherical.altitude, bearingRangeAltitude.range)

			local roll = 0

		Tacview.Context.Camera.SetRotation(
			roll,
			pitch,
			yaw
		)--]]

	elseif trialAircraftView then

		-- Dogfight Mode Look Forward

		if 	Tacview.Settings.GetString("UI.View.Camera.Mode") ~= "External" or
			not Tacview.Settings.GetBoolean("UI.View.Camera.Dogfight.Enabled") or
			Tacview.Settings.GetString("UI.View.Camera.Dogfight.Mode") ~= "LookForward" then

			Tacview.Settings.SetString("UI.View.Camera.Mode","External")
			Tacview.Settings.SetBoolean("UI.View.Camera.Dogfight.Enabled", true)
			Tacview.Settings.SetString("UI.View.Camera.Dogfight.Mode", "LookForward") 
		end	

		-- Get as close as possible

		Tacview.Context.Camera.SetRangeToTarget(0)

		-- Control camera rotation

		Tacview.Context.Camera.SetRotation(0, -math.pi/2/4, 0)

		-- True side view (not helpful)

		--[[local positionVector = {x = transform1.x, y = transform1.y, z = transform1.z}
		
		local positionVectorNormalized = Tacview.Math.Vector.Normalize(positionVector) 

		local forwardPoint = Tacview.Math.Vector.LocalToGlobal(transform1, {x=0,y=0,z=-1} )

		local forwardVector = Tacview.Math.Vector.Subtract(forwardPoint, positionVector)

		local forwardVectorNormalized = Tacview.Math.Vector.Normalize(forwardVector) 

		local crossVector = CrossProduct(positionVectorNormalized,forwardVectorNormalized)

		local crossVectorNormalized = Tacview.Math.Vector.Normalize(crossVector) 

		local range = 500

		local cameraVector = { 	x = positionVector.x + range*crossVectorNormalized.x,
								y = positionVector.y + range*crossVectorNormalized.y,
								z = positionVector.z + range*crossVectorNormalized.z
							}

		local cameraVectorSpherical = Tacview.Math.Vector.CartesianToLongitudeLatitude(cameraVector)

		Tacview.Context.Camera.SetSphericalPosition(cameraVectorSpherical.longitude , cameraVectorSpherical.latitude , cameraVectorSpherical.altitude )

		local positionVectorSpherical = Tacview.Math.Vector.CartesianToLongitudeLatitude(positionVector)

		local bearingRangeAltitude =
			Tacview.Math.Vector.LongitudeLatitudeToBearingRangeAltitude(
				cameraVectorSpherical.longitude,
				cameraVectorSpherical.latitude,
				cameraVectorSpherical.altitude,
				positionVectorSpherical.longitude,
				positionVectorSpherical.latitude,
				positionVectorSpherical.altitude
			)
		
		local yaw = bearingRangeAltitude.bearing
		
		local pitch = math.atan(	positionVectorSpherical.altitude - cameraVectorSpherical.altitude,
						bearingRangeAltitude.range )

		Tacview.Context.Camera.SetRotation(0, pitch, yaw)--]]

	elseif trialTopView then

		-- Satellite View

		if  Tacview.Settings.GetString("UI.View.Camera.Mode") ~= "Satellite" then
	
			Tacview.Settings.SetString("UI.View.Camera.Mode","Satellite")
		end	

		-- Perform calculations on the gates to get the midpoint and maximum distance from midpoint to object

		local midpointVector = {x=0,y=0,z=0}
		local radius = 0

		if not gateBoundsComputed  then
			radius, midpointVector = ComputeGateBounds()
		end	

		-- In Satellite View it is not necessary to place the camera , just tell it where to point.

		local cameraVectorSpherical = Tacview.Math.Vector.CartesianToLongitudeLatitude(midpointVector)

		Tacview.Context.Camera.SetSphericalPosition( cameraVectorSpherical.longitude , cameraVectorSpherical.latitude , cameraVectorSpherical.altitude )

		-- Set range using bounding sphere

		local range = radius / math.sin(math.rad(60)/2)

		Tacview.Context.Camera.SetRangeToTarget(range )

	end
end

function CrossProduct(vector1, vector2) 

	return	{
			x = vector1.y * vector2.z - vector1.z * vector2.y,
			y = vector1.z * vector2.x - vector1.x * vector2.z,
			z = vector1.x * vector2.y - vector1.y * vector2.x
			}
end

function OnContextMenu(contextMenuId, objectHandle)

		bfmTopDownMenuHandle = Tacview.UI.Menus.AddExclusiveOption(contextMenuId, "BFM Top-Down", bfmTopDown, OnBFMTopDown)
		bfmAircraftViewMenuHandle = Tacview.UI.Menus.AddExclusiveOption(contextMenuId, "BFM Side View", bfmAircraftView, OnBFMSideView)
		trialAircraftViewMenuHandle = Tacview.UI.Menus.AddExclusiveOption(contextMenuId, "Trial Aircraft View", trialAircraftView, OnTrialAircraftView)
		trialTopViewMenuHandle = Tacview.UI.Menus.AddExclusiveOption(contextMenuId, "Trial Top View", trialTopView, OnTrialTopView)
end

function ComputeGateBounds()

		local objectTransforms = {}
		local center = {x=0, y=0, z=0}

		local objectCount = Tacview.Telemetry.GetObjectCount()

		for i=0,objectCount-1 do
			
			local objectHandle = Tacview.Telemetry.GetObjectHandleByIndex(i)

			if objectHandle then

				local objectTags = Tacview.Telemetry.GetCurrentTags(objectHandle)

				if objectTags then

					if not Tacview.Telemetry.AnyGivenTagActive(objectTags, Tacview.Telemetry.Tags.Bullseye|Tacview.Telemetry.Tags.FixedWing) then
			
						local transform = Tacview.Telemetry.GetCurrentTransform(objectHandle)
					
						if transform then
						
							objectTransforms[#objectTransforms+1]  = transform
						
							center.x = center.x + transform.x
							center.y = center.y + transform.y
							center.z = center.z + transform.z
						
						end
					end
				end
			end
		end

		-- Calculate the center point of all relevant objects and find the maximum distances between the center and each object

		local midpointVector = {
			x = center.x / #objectTransforms,
			y = center.y / #objectTransforms,
			z = center.z / #objectTransforms
		}

		-- Get the maximum distance between the midpoint and any relevant object

		local radius = 0

		for i = 1, #objectTransforms do
			local distance = Tacview.Math.Vector.GetDistanceBetweenObjects(midpointVector,objectTransforms[i])
			radius = math.max(radius, distance)
		end

		return radius, midpointVector

end

--[[function OnDrawTransparentUI()

	if BFMTopDown or bfmAircraftView then

		local BackgroundHeight = 100
		local BackgroundWidth = 100

		local FontSize = 16
	
		local height = Tacview.UI.Renderer.GetHeight()
		local width = Tacview.UI.Renderer.GetWidth()
	
		if not backgroundRenderStateHandle then
	
			local backgroundRenderState =
			{
				color = 0x80FFFFFF,	
			}
	
			backgroundRenderStateHandle = Tacview.UI.Renderer.CreateRenderState(backgroundRenderState)
	
		end
	
		if not textRenderStateHandle then
	
			local textRenderState =
			{
				color = 0xFFFF0000,
			}
	
			textRenderStateHandle = Tacview.UI.Renderer.CreateRenderState(textRenderState)
	
		end
	
		if not backgroundVertexArrayHandle then
	
			local vertexArray =
			{
				0,0,0,
				0,-BackgroundHeight,0,
				BackgroundWidth,-BackgroundHeight,0,
				0,0,0,
				BackgroundWidth,0,0,
				BackgroundWidth,-BackgroundHeight,0,
				0,0,0,
			}
	
			backgroundVertexArrayHandle = Tacview.UI.Renderer.CreateVertexArray(vertexArray)
	
		end

	
		if not backgroundTransform1 then
			backgroundTransform1 =
			{	
				x = 300,
				y = height-25,
				scale = 1,
			}
		end	

		if not backgroundTransform2 then
			backgroundTransform2 =
			{	
				x = width-125,
				y = height-25,
				scale = 1,
			}
		end		

		if not backgroundTransform3 then
			backgroundTransform3 =
			{	
				x = 300,
				y = 125,
				scale = 1,
			}
		end
	
		if not backgroundTransform4 then
			backgroundTransform4 =
			{	
				x = width - 125,
				y = 125,
				scale = 1,
			}
		end		

		if not textTransform1 then
			textTransform1 =
			{	
				x = 300,
				y = height-25-FontSize,
				scale = FontSize,
			}
		end
	
		if not textTransform2 then
			textTransform2 =
			{	
				x = width-125,
				y = height-25-FontSize,
				scale = FontSize,
			}
		end		
	
		if not textTransform3 then
			textTransform3 =
			{	
				x = 300,
				y = 125-FontSize,
				scale = FontSize,
			}
		end		
	
		if not textTransform4 then
			textTransform4 =
			{	
				x = width - 125,
				y = 125-FontSize,
				scale = FontSize,
			}
		end
	
		Tacview.UI.Renderer.DrawUIVertexArray(backgroundTransform1, backgroundRenderStateHandle, backgroundVertexArrayHandle)
		Tacview.UI.Renderer.DrawUIVertexArray(backgroundTransform2, backgroundRenderStateHandle, backgroundVertexArrayHandle)
		Tacview.UI.Renderer.DrawUIVertexArray(backgroundTransform3, backgroundRenderStateHandle, backgroundVertexArrayHandle)
		Tacview.UI.Renderer.DrawUIVertexArray(backgroundTransform4, backgroundRenderStateHandle, backgroundVertexArrayHandle)

		local player1 = Tacview.Context.GetSelectedObject(0) 
		local player2 = Tacview.Context.GetSelectedObject(1)

		if not player1 or not player2 then
			return
		end

		local pilot1 = ""
		local pilot2 = ""
		local color1 = ""
		local color2 = ""

		local pilotPropertyIndex = Tacview.Telemetry.GetObjectsTextPropertyIndex("Pilot", false)

		if pilotPropertyIndex ~= Tacview.Telemetry.InvalidPropertyIndex then

			pilot1 = Tacview.Telemetry.GetTextSample( player1 , Tacview.Context.GetAbsoluteTime() , pilotPropertyIndex )
			pilot2 = Tacview.Telemetry.GetTextSample( player2 , Tacview.Context.GetAbsoluteTime() , pilotPropertyIndex )
		end

		local colorPropertyIndex = Tacview.Telemetry.GetObjectsTextPropertyIndex("Color", false)

		if colorPropertyIndex ~= Tacview.Telemetry.InvalidPropertyIndex then

			color1 = Tacview.Telemetry.GetTextSample( player1 , Tacview.Context.GetAbsoluteTime() , colorPropertyIndex )
			color2 = Tacview.Telemetry.GetTextSample( player2 , Tacview.Context.GetAbsoluteTime() , colorPropertyIndex )
		end

		msg1 = color1 .. " - " .. pilot1

		if p1offense then
			
			msg1 = msg1 .. "\nOffense"
		
		elseif not p1offense then
			
			if p2offense then
				msg1 = msg1 .. "\nDefense"
			else
				msg1 = msg1 .. "\nNeutral"
			end
		end

		msg2 = color2 .. " - " .. pilot2

		if p2offense then
			
			msg2 = msg2 .. "\nOffense"
		
		elseif not p2offense then
		
			if p1offense then
				msg2 = msg2 .. "\nDefense"
			else
				msg2 = msg2 .. "\nNeutral"
			end
		end			

		Tacview.UI.Renderer.Print(textTransform1, textRenderStateHandle, msg1)
		Tacview.UI.Renderer.Print(textTransform2, textRenderStateHandle, msg2)
		Tacview.UI.Renderer.Print(textTransform3, textRenderStateHandle, "POINT TOTAL")
		Tacview.UI.Renderer.Print(textTransform4, textRenderStateHandle, "POINT TOTAL")
	end
end --]]

function OnDocumentLoaded()

	gateBoundsComputed  = false
end

function OnShutdown()

	Tacview.Settings.SetBoolean("UI.View.Overlay.Visible","true")
end



----------------------------------------------------------------
-- Add-on initialization
----------------------------------------------------------------

function Initialize()

	-- Declare add-on information

	Tacview.AddOns.Current.SetTitle("Strike Fighter League")
	Tacview.AddOns.Current.SetVersion("0.1")
	Tacview.AddOns.Current.SetAuthor("BuzyBee")
	Tacview.AddOns.Current.SetNotes("Special options requested by Strike Fighter League")

	bfmTopDown = Tacview.AddOns.Current.Settings.GetBoolean(bfmTopDownSettingName, false )
	bfmAircraftView = Tacview.AddOns.Current.Settings.GetBoolean(bfmAircraftViewSettingName, false )
	trialAircraftView = Tacview.AddOns.Current.Settings.GetBoolean(trialAircraftViewSettingName, false )

		Tacview.Settings.SetBoolean("UI.View.Overlay.Visible","false")

	Tacview.UI.Renderer.ContextMenu.RegisterListener(OnContextMenu) -- Tacview 1.7.6
	Tacview.Events.Update.RegisterListener(OnUpdate) -- Tacview 1.7.2
	-- Tacview.Events.DrawTransparentUI.RegisterListener(OnDrawTransparentUI) -- Tacview 1.7.2
	Tacview.Events.DocumentLoaded.RegisterListener(OnDocumentLoaded) 
	Tacview.Events.Shutdown.RegisterListener( OnShutdown ) 

end

Initialize()


