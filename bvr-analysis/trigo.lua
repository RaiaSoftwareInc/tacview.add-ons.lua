local Tacview = require("Tacview186")

function DistanceSiteGisementToLongitudeLatitude(transform, relBearing, range, elevation)
	local absBearing=transform.heading+relBearing
	local altitude=transform.altitude+range*math.sin(elevation)
	local long=transform.longitude
	local lat=transform.latitude
	-- print("reflong="..long,"reflat="..lat,"refalt="..altitude,"refhdg="..transform.heading)
	local position = Tacview.Math.Vector.BearingRangeAltitudeToLongitudeLatitude(long, lat, absBearing, range, altitude)
	return position
end

function IsTransformActive(objectHandle, currentTime)
	local beginTime, endTime = Tacview.Telemetry.GetTransformTimeRange(objectHandle)
	if currentTime>beginTime and currentTime<endTime then 
		return true
	else
		return false
	end
end

function ExtrapolatedSpeedVector(objectHandle, currentTime)
	local beginTime, endTime=Tacview.Telemetry.GetTransformTimeRange(objectHandle)
	-- print("test a")
	-- if currentTime>endTime-0.5 or currentTime<beginTime+0.5 then print("mauvaise transform") return "" end	
	local objectTransformEarly=Tacview.Telemetry.GetTransform(objectHandle,currentTime-0.5)
	local objectTransformLate=Tacview.Telemetry.GetTransform(objectHandle,currentTime+0.5)
		-- print("test b")
	local speedVector={
		x=objectTransformLate.x-objectTransformEarly.x,	
		y=objectTransformLate.y-objectTransformEarly.y,	
		z=objectTransformLate.z-objectTransformEarly.z
		}
	-- print("extrapolated", speedVector.x, speedVector.y)
	-- print("speed", Tacview.Math.Vector.GetLength(speedVector)*3600/1852)
	return speedVector
end

function round (x,decimals)
	local rounded
	local power=10^decimals
	local f=math.floor(x*power)
	if (x*power==f) or ((x*power)%2.0==0.5) then
		rounded=f/power
	else
		rounded=math.floor(x*power+0.5)/power
	end
	if decimals<=0 then rounded=math.floor(rounded) end
	return rounded
end

function GetRelevement(object1Transform, object2Transform) --return the angle between the North and the line between object1 and object2
	local object1Object2=GetNormalizedVectorBetweenTransform(object1Transform, object2Transform)
	local relevement=Tacview.Math.Angle.Normalize2Pi(Tacview.Math.Vector.AngleBetween(object1Object2,{x=1,y=0,z=0},{x=0,y=1,z=0}))
	-- print("relevement", relevement*180/math.pi)
	return relevement
end

function GetAperture(angle1, angle2)
	return math.abs(math.min(angle2-angle1,2*math.pi-angle2+angle1))
end


function GetTargetAspectAngle(object1Transform, object2Transform) --return the aspect angle of object2 seen from object1. Ie the angle between  (object1-->object2 line) and (object2 heading)
	local targetAspectAngle = Tacview.Math.Angle.NormalizePi(object2Transform.yaw - GetRelevement(object1Transform, object2Transform))
	-- print("Aspect angle", targetAspectAngle*180/math.pi)
	return targetAspectAngle
end

function GetVrb(object1Handle, object2Handle, currentTime)
	local object1Transform=Tacview.Telemetry.GetTransform(object1Handle, currentTime)
	local object2Transform=Tacview.Telemetry.GetTransform(object2Handle, currentTime)
	local object2Speed=ExtrapolatedSpeedVector(object2Handle, currentTime)
	local object1Object2BearingLine= Tacview.Math.Vector.Normalize(Tacview.Math.Vector.Subtract(object1Transform, object2Transform))
	local vrb=ScalarProduct(object1Object2BearingLine, object2Speed)
	return vrb
end

function GetAntennaTrainAngle3D(object1Transform, object2Transform) --returns the angle between object1 nose and another transform (in radians)
	local object1Vector={x=math.cos(object1Transform.pitch)*math.sin(object1Transform.yaw), y=math.cos(object1Transform.pitch)*math.cos(object1Transform.yaw), z=math.sin(object1Transform.pitch)}
	local object1Object2Vector=GetNormalizedVectorBetweenTransform(object1Transform, object2Transform)
	local antennaTrainAngle3D=Tacview.Math.Vector.AngleBetween( object1Vector , object1Object2Vector)	
	return antennaTrainAngle3D
	
end

function GetNormalizedVectorBetweenTransform(object1Transform, object2Transform)
	local deltaX = (object2Transform.longitude-object1Transform.longitude)*180/math.pi*60*1852*math.cos((object2Transform.latitude+object1Transform.latitude)/2)
	local deltaY = (object2Transform.latitude-object1Transform.latitude)*180/math.pi*60*1852
	local deltaZ = object2Transform.altitude-object1Transform.altitude

	return Tacview.Math.Vector.Normalize({x=deltaX, y=deltaY, z=deltaZ})
end

function GetNormalizedVectorBetweenTransform2D(object1Transform, object2Transform)
	local deltaX = (object2Transform.longitude-object1Transform.longitude)*180/math.pi*60*1852*math.cos((object2Transform.latitude+object1Transform.latitude)/2)
	local deltaY = (object2Transform.latitude-object1Transform.latitude)*180/math.pi*60*1852
	local deltaZ = 0
	return Tacview.Math.Vector.Normalize({x=deltaX, y=deltaY, z=deltaZ})
end

function ScalarProduct(vector1, vector2)
	return vector1.x*vector2.x+vector1.y*vector2.y+vector1.z*vector2.z
end
