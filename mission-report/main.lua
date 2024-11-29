
--[[
	Mission Report
	Exports an HTML report of events per pilot.

	Author: BuzyBee
	Last update: 2023-04-12 (Tacview 1.9.0)

	Feel free to modify and improve this script!
--]]

--[[

	MIT License

	Copyright (c) 2023-2024 Raia Software Inc.

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

--require("lua-strict")

-- Request Tacview API

local Tacview = require("Tacview190")

local DefaultPath = ""

function GenerateMissionReport()

	-- Ask the user to choose the ACMI file
	
	Tacview.UI.MessageBox.Info("Click OK when you are ready to choose the ACMI file from which to generate a mission report.")
	
	local fileName = GetOpenFileNames()
	
	if not fileName then
		Tacview.Log.Debug("No ACMI file was opened")
		return
	end	
	
	-- Export the XML flight log
	
	local executable = os.getenv("TACVIEW_DCS2ACMI_PATH").."..".."/Tacview64.exe"
	Tacview.Log.Debug("executable: " .. executable)
	local openFileCMD = "-Open:\"" .. fileName .."\""
	Tacview.Log.Debug("openFileCMD: " .. openFileCMD)
	local exportFlightLogCMD = "-ExportFlightLog:\"" .. Tacview.AddOns.Current.GetPath() .. "flight-log.xml\""
	Tacview.Log.Debug("exportFlightLogCMD: " .. exportFlightLogCMD)
	
	os.execute(executable .. openFileCMD .. exportFlightLogCMD)
	
	-- Parse the XML flight log
	
	local xmlParser = require("xmlparser")
	
	local doc = xmlParser.parseFile(Tacview.AddOns.Current.GetPath() .. "flight-log.xml")
	
	--print_table(doc,8)
	
	-- Ask the user for the target file name to save the HTML file
	
	Tacview.UI.MessageBox.Info("Click OK when you are ready to choose the location where the mission report should be saved.")

	local fileName = GetSaveFileNames()
	
	-- Create the HTML Mission Report

	CreateHTML(fileName, doc)	

end

function CreateHTML(fileName, doc)
	
	-- Create the HTML file
	
	local file = io.open(fileName, "wb")

	if not file then
		Tacview.UI.MessageBox.Error("Failed to export data.\n\nEnsure there is enough space and that you have permission to save in this location.")
		return
	end
	
	file:write("<!DOCTYPE html>\n")
	file:write("<html>\n")
	file:write("\t<head>\n")
	file:write("\t\t<title>Mission Report</title>\n")
	file:write("\t</head>\n")
	file:write("\t<body>\n")
	
	file:write("\t\t<h1>Hello World!</h1>\n")

	file:write("\t</body>\n")
	file:write("</html>")

	file:close()
end

function print_table(t, indent, max_depth, depth)
    indent = indent or ""
    max_depth = max_depth or 100
    depth = depth or 0
    
    if type(t) == "table" then
        if depth >= max_depth then
            print(indent .. "...")
            return
        end
        
        local coroutine_print = coroutine.wrap(function()
            for k, v in pairs(t) do
                io.write(indent.."["..tostring(k).."] = ")
                print_table(v, indent.."    ", max_depth, depth + 1)
            end
        end)
        coroutine_print()
    else
        print(tostring(t))
    end
end

function GetOpenFileNames()

	print(os.getenv("UserProfile").."/Documents/Tacview/")
	
	local openFileNameOptions =
		{
			defaultFileExtension = "acmi",
			fileName = Tacview.AddOns.Current.Settings.GetString("OpenFilePath", DefaultPath),
			fileTypeList =									
			{
				{"*.acmi", "ACMI file"}
			}
		}

		local fileNames = Tacview.UI.MessageBox.GetOpenFileName(openFileNameOptions)

	if not fileNames then
		Tacview.Log.Debug("Did not open any ACMI file.")
		return
	end

	Tacview.AddOns.Current.Settings.SetString("OpenFilePath", fileNames[1]);

	return fileNames[1]
end

function GetSaveFileNames()

	local saveFileNameOptions =
	{
		defaultFileExtension = "html",
		fileName = Tacview.AddOns.Current.Settings.GetString("SaveFilePath", DefaultPath),
		fileTypeList =
		{
			{"*.html", "Hyper Text Markup Language"}
		}
	}
	
	local fileName = Tacview.UI.MessageBox.GetSaveFileName(saveFileNameOptions)
	
	if not fileName then
		Tacview.Log.Debug("Did not save any HTML file.")
		return
	end

	Tacview.AddOns.Current.Settings.SetString("SaveFilePath", fileName);
	
	return fileName

end


----------------------------------------------------------------
-- Add-on initialization
----------------------------------------------------------------

function Initialize()

	-- Declare add-on information

	Tacview.AddOns.Current.SetTitle("Mission Report")
	Tacview.AddOns.Current.SetVersion("0.1")
	Tacview.AddOns.Current.SetAuthor("BuzyBee")
	Tacview.AddOns.Current.SetNotes("Generates an HTML mission report.")

	-- Declare menu

	Tacview.UI.Menus.AddCommand( nil , "Generate Mission Report" , GenerateMissionReport )

end

Initialize()
