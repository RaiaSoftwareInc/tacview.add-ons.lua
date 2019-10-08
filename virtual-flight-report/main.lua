
-- Virtual Flight Report
-- Author: Erin 'BuzyBee' O'Reilly
-- Last update: 2019-10-07 (Tacview 1.8.0)

-- IMPORTANT: This script act both as a tutorial and as a real addon for Tacview.
-- Feel free to modify and improve this script!

--[[

MIT License

Copyright (c) 2019 Raia Software Inc.

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

----------------------------------------------------------------
-- Setup
----------------------------------------------------------------

require("LuaStrict")

declareGlobal("unpack", nil)
declareGlobal("module", nil)

local Tacview = require("Tacview180")

----------------------------------------------------------------
-- HTTPPOST  service
----------------------------------------------------------------


function PostData()

	local selectedObjectHandle = Tacview.Context.GetSelectedObject(0) or Tacview.Context.GetSelectedObject(1)

	local btnpirep 		= "A"
    local dateFilled	= "B"
    local flightDate	= "C"
    local depicao		= "DDDD"
    local arricao 		= "EEEE"
    local route 		= "F"
    local aircraft 		= "G"
    local fuel 			= "H"
    local miles 		= "I"
    local pax 			= "J"	 
    local dh 			= "K"
    local dm 			= "L"
    local ds 			= "M"
    local ah 			= "N"
    local am 			= "O"
    local as 			= "P"
    local th 			= "Q"
    local tm 			= "R"
    local ts 			= "S"
    local comments 		= "T"
    local pilot 		= "U"
    local flight_number = "V"

	


--[[
	local callSignPropertyIndex = Tacview.Telemetry.GetObjectsNumericPropertyIndex("pilot", false)

	if callSignPropertyIndex ~= Tacview.Telemetry.InvalidPropertyIndex then

		local isSampleValid

		callSign, isSampleValid = telemetry.GetNumericSample(selectedObjectHandle, absoluteTime, callSignPropertyIndex)

		if isSampleValid == true then

			pilot = callSign

		end
	end

	print("CallSign/Pilot ="..pilot)--]]

    local http = require"socket.http"
    local ltn12 = require"ltn12"

    local reqbody = "btnpirep="		..btnpirep..
					"&date_filled="	..dateFilled..
					"&date="		..flightDate..
					"&depicao="		..depicao..
					"&arricao="		..arricao..
					"&route="		..route..
					"&aircraft="	..aircraft..
					"&fuel="		..fuel..
					"&miles="		..miles..
					"&pax="			..pax..
					"&dh="			..dh..
					"&dm="			..dm..
					"&ds="			..ds..
					"&ah="			..ah..
					"&am="			..am..
					"&as="			..as..
					"&th="			..th..
					"&tm="			..tm..
					"&ts="			..ts..
					"&comments="	..comments..
					"&pilot="		..pilot..
					"&flight_number="..flight_number

    local respbody = {} 

    local result, respcode, respheaders, respstatus = http.request {
        method = "POST",
        url = "http://127.0.0.1/virtual-flight-report/index.php",
        source = ltn12.source.string(reqbody),
        headers = 
		{
			["content-length"] = #reqbody,        
			["Content-Type"] =  "application/x-www-form-urlencoded" 
        },
        sink = ltn12.sink.table(respbody)
    }
	respbody = table.concat(respbody)
	print(respbody)

end

function SendVirtualFlightReport()

	local sendVirtualFlightReport = Tacview.UI.MessageBox.Question("Click OK to send a Virtual Flight Report now") 

	if(sendVirtualFlightReport==Tacview.UI.MessageBox.OK) then
		PostData()
	else
		return
	end

end

----------------------------------------------------------------
-- Initialize this addon
----------------------------------------------------------------

function Initialize()

	-- Declare addon properties

	local currentAddOn = Tacview.AddOns.Current

	currentAddOn.SetTitle("Virtual Flight Report")
	currentAddOn.SetVersion("0.1")
	currentAddOn.SetAuthor("BuzyBee")
	currentAddOn.SetNotes("Send flight report to specific website via HTTP POST.")

	-- Declare menus

	Tacview.UI.Menus.AddCommand( nil , "Virtual Flight Report" , SendVirtualFlightReport )

end

Initialize()
