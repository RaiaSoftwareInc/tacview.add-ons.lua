
-- Landing Signal Officer for Tacview
-- Author: Erin 'BuzyBee' O'REILLY
-- Last update: 2020-11-12 (Tacview 1.8.5)

-- IMPORTANT: This script act both as a tutorial and as a real addon for Tacview.
-- Feel free to modify and improve this script!

--[[

MIT License

Copyright (c) 2020-2024 Raia Software Inc.

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
-- Eligible Aircraft List with corresponding 3D object filenames
----------------------------------------------------------------

function EligibleAircraftList()

	return 
		{
			["T-38"] =	"FixedWing.T-38.cockpit.obj",
			["M2000"] =	"FixedWing.Mirage 2000.cockpit.obj"
		}
	 
end
