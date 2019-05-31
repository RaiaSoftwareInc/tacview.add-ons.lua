require("lua-strict")

local Tacview = require("Tacview176")

local mainMenuHandle = Tacview.UI.Menus.AddMenu(nil, "LightWave Exporter")

function ExportObject(objectHandle, fileName, frameRate)

	local lifeTimeBegin, lifeTimeEnd = Tacview.Telemetry.GetLifeTime(objectHandle) 
	local dt = 1/frameRate
	
	local telemetryTimeBegin, telemetryTimeEnd = Tacview.Telemetry.GetDataTimeRange() 
	
	local timeBegin = math.max(lifeTimeBegin, telemetryTimeBegin)
	local timeEnd = math.min(lifeTimeEnd, telemetryTimeEnd)
	
	print("timeBegin: ", timeBegin, " timeEnd: ", timeEnd, " dt: ", dt)	
	
	local initialPosition = Tacview.Telemetry.GetTransform( objectHandle , timeBegin )
	
	local u0, v0, altitude0 = initialPosition.u, initialPosition.v, initialPosition.altitude
	
	local file = io.open(fileName, "wb")
	
	print("u0: ",u0," v0: ",v0," altitude0: ",altitude0)
	
	print(initialPosition.u-u0 .. " " .. initialPosition.v-v0 .. " " .. initialPosition.altitude-altitude0)
	
	--header
	file:write("Frame Number,Relative Time,u,v,altitude,roll,pitch,heading\n")
	
	local frameNumber=0
	
	local rollWrap, pitchWrap, headingWrap = 0, 0, 0
	
	
	for absoluteTime = timeBegin, timeEnd, dt do
	
		local objectTransform = Tacview.Telemetry.GetTransform( objectHandle , absoluteTime ) 
		
		local previousObjectTransform = Tacview.Telemetry.GetTransform( objectHandle , absoluteTime - dt )
		
		local rollDiff		= objectTransform.roll-previousObjectTransform.roll
		local pitchDiff		= objectTransform.pitch-previousObjectTransform.pitch
		local headingDiff	= objectTransform.heading-previousObjectTransform.heading
		
		if rollDiff>math.pi then 
			rollWrap = rollWrap - 2*math.pi
		elseif rollDiff<-math.pi then
			rollWrap = rollWrap + 2*math.pi
		end
		
		if pitchDiff>math.pi then 
			pitchWrap = pitchWrap - 2*math.pi
		elseif pitchDiff<-math.pi then
			pitchWrap = pitchWrap + 2*math.pi
		end
		
		if headingDiff>math.pi then 
			headingWrap = headingWrap - 2*math.pi
		elseif headingDiff<-math.pi then
			headingWrap = headingWrap + 2*math.pi
		end
		
		local relativeTime = absoluteTime-timeBegin
		
		local totalRoll 	= objectTransform.roll + rollWrap
		local totalPitch 	= objectTransform.pitch + pitchWrap
		local totalHeading 	= objectTransform.heading + headingWrap
		
		file:write(string.format("%u,%.02f,%g,%g,%g | roll=%g,%g,%g | totalroll=%g,%g,%g | rollwrap=%g,%g,%g\n",
			frameNumber,relativeTime,objectTransform.u-u0,objectTransform.v-v0,objectTransform.altitude-altitude0,
			math.deg(objectTransform.roll),math.deg(objectTransform.pitch),math.deg(objectTransform.heading), 
			math.deg(totalRoll),math.deg(totalPitch),math.deg(totalHeading), 
			math.deg(rollWrap), math.deg(pitchWrap),math.deg(headingWrap)))
		
--		file:write(frameNumber,", ",relativeTime,", ",objectTransform.u-u0,", ",objectTransform.v-v0,", ",objectTransform.altitude-altitude0,"\n")
		
		frameNumber=frameNumber+1
		
		
	end
	
	






















end




function Export(frameRate)

	Tacview.Log.Info(frameRate .. " selected")

	-- Retrieve selected object
	
	local selectedObjectHandle = Tacview.Context.GetSelectedObject(0) or Tacview.Context.GetSelectedObject(1)
	
	if not selectedObjectHandle then
		Tacview.UI.MessageBox.Info("Please select an object to export.")
		return
	end
	
	-- Retrieve file name
	
	local fileName = "C:/Downloads/LightwaveExportTest.csv"

	if not fileName then
		return
	end
	
	ExportObject(selectedObjectHandle, fileName, frameRate)
	

end

function OnExport24()
 
	Export(24)

end

function OnExport25()

	Export(25)

end

function OnExport2997()

	Export(29.97)

end

function OnExport30()

	Export(30)

end

Tacview.UI.Menus.AddCommand(mainMenuHandle, "Export Selected Object @ 24 Hz", OnExport24)
Tacview.UI.Menus.AddCommand(mainMenuHandle, "Export Selected Object @ 25 Hz", OnExport25)
Tacview.UI.Menus.AddCommand(mainMenuHandle, "Export Selected Object @ 29.97 Hz", OnExport2997)
Tacview.UI.Menus.AddCommand(mainMenuHandle, "Export Selected Object @ 30 Hz", OnExport30)

function initialize()

	Tacview.AddOns.Current.SetTitle("LightWave Exporter")
	Tacview.AddOns.Current.SetVersion("1.0")
	Tacview.AddOns.Current.SetAuthor("BuzyBee")
	Tacview.AddOns.Current.SetNotes("...")

end

initialize()
