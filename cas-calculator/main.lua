
--[[
	CAS Calculator

	Author: BuzyBee
	Last update: 2020-10-18 (Tacview 1.8.5)

	Feel free to modify and improve this script!
--]]

--[[

	MIT License

	Copyright (c) 2020-2025 Raia Software Inc.

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

local Tacview = require("Tacview185")

function OnUpdate(dt, absoluteTime)

	local objectHandle = Tacview.Context.GetSelectedObject(0)
	
	if not objectHandle then
		return
	end
	
	local transform = Tacview.Telemetry.GetCurrentTransform(objectHandle)

	local ft2m = 0.3048
	
	local mach = Tacview.Telemetry.GetMachNumber( objectHandle , absoluteTime )
	local altitude = transform.altitude;

	if not mach then
		Tacview.Log.Info("Mach is not available")
		return
	end

	-- Temperature offset is not available from flight simulator

	local tempRaw = 0

	local altitudeArray = {0, 11000, 20000, 32000, 47000, 51000, 71000, 84852}
	local presRelsArray = {1, 2.23361105092158e-1, 5.403295010784876e-2, 8.566678359291667e-3, 1.0945601337771144e-3, 6.606353132858367e-4, 3.904683373343926e-5, 3.6850095235747942e-6}
	local tempsArray = {288.15, 216.65, 216.65, 228.65, 270.65, 270.65, 214.65,186.946}
	local tempGradArray = {-6.5, 0, 1, 2.8, 0, -2.8, -2, 0}
		
	local i = 0

	while altitude > altitudeArray[i+1] do	
		i=i+1
	end

	-- i defines the array position required for the calculations
	local alts = altitudeArray[i]
	local presRels = presRelsArray[i]
	local temps = tempsArray[i]
	local tempGrad = tempGradArray[i]/1000
		
	local deltaAlt = altitude - alts
	local stdTemp = temps + (deltaAlt*tempGrad) -- this is the standard temperature at STP

	local tempSI = stdTemp+tempRaw -- includes the temp offset
	local tempDegC = tempSI-273.15

	local airMol = 28.9644
	local rGas = 8.31432 --kg/Mol/K
	local g = 9.80665 -- m/s2
		
	local pSL = 101325 -- Pa
	local gMR = g*airMol/rGas

	local relPres
			
    if (math.abs(tempGrad) < 1e-10) then
        relPres = presRels * math.exp(-1*gMR*deltaAlt/1000/temps);
    else 
        relPres = presRels * (temps/stdTemp)^(gMR/tempGrad/1000);
    end

	local pressureSI = pSL*relPres

	local qc = pressureSI*((1+0.2*mach*mach)^(7/2)-1);

	-- Standard atmospheric values that remain constant
	local P0 = 101325
	local a0 = 340.29
	local cas = a0*math.sqrt(5*((qc/P0+ 1)^(2/7)-1))
	print("cas: " .. cas)
end

----------------------------------------------------------------
-- Add-on initialization
----------------------------------------------------------------

function Initialize()

	-- Declare add-on information

	Tacview.AddOns.Current.SetTitle("Calculate CAS")
	Tacview.AddOns.Current.SetVersion("0.0.1")
	Tacview.AddOns.Current.SetAuthor("BuzyBee")
	Tacview.AddOns.Current.SetNotes("Calculate CAS from MACH and ASL")

	--Tacview.UI.Menus.AddCommand(nil, "Calculate CAS", OnCalculateCAS)
	
	Tacview.Events.Update.RegisterListener( OnUpdate ) 	

end

Initialize()


