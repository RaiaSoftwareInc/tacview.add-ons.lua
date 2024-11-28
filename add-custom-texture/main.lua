
--[[
	Add Custom Texture

	Author: BuzyBee
	Last update: 2024-11-28 (Tacview 1.9.4)

	Feel free to modify and improve this script!
--]]

--[[

	MIT License

	Copyright (c) 2021-2024 Raia Software Inc.

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

--[[ 

	Terrain.AddCustomTexture( textureId , layerId , fileName , filter , topLeftLongitude , topLeftLatitude , topRightLongitude , topRightLatitude , bottomRightLongitude , bottomRightLatitude , bottomLeftLongitude , bottomLeftLatitude ) -- Tacview 1.8.7

	Declare a new custom texture which will be visible by default.

	Each custom texture is uniquely identified via its text textureId.

	Use layerId to display the texture only when data from a specific source is loaded,
	leave it blank to load the texture regardless of the simulator. It is not currently possible to specify multiple layers for one texture.

	Currently supported layers:

		- "Real World"
		- "DCS World"
		- "Falcon 4"
		- "IL2"
		- "EECH"

	NOTE: X-Plane and Microsoft Flight Simulator / P3D will use the "Real World" layer.

	FileName is a case sensitive name of the texture file stored in %ProgramData%\Tacview\Data\Terrain\Textures\ or %APPDATA%\Tacview\Data\Terrain\Textures\

	Currently supported file format/extension:

		- webp
		- png
		- jpg/jpeg
		- tga

	Use the filter parameter to choose the way the texture is overlaid onto the terrain:
		- nil: original (using texture native alpha channel when available for blend)
		- "Translucent": 50% translucent picture
		- "AdaptiveGreyScale": adaptive grey scale layer
		- "AdaptiveColor": adaptive color layer

	When fully qualitied such as "IL2-BoS.png", Tacview will load the image with the specified filter.

	If the file name is specified without any extension (e.g. "DCS-Caucasus4Tacview-v1"), Tacview will attempt to load any image starting with
	the name followed by a special character specifying the way the texture will be displayed:

		- T: 50% translucent picture
		- B: adaptive grey scale layer
		- C: adaptive color layer

	For example:

		"IL2-BoS.png" will load the file "\Data\Terrain\Textures\IL2-BoS.png"
		"DCS-Caucasus4Tacview-v1" will load the file "\Data\Terrain\Textures\DCS-Caucasus4Tacview-v1T.png" and display it half translucent over the base layer.

	The texture coordinates are in radian, and the projection will be quadratic.

	NOTE: Tacview will automatically cache any declared texture, there is no need to explicitly load/unload a texture.

	NOTE: Because of the way Tacview manages files resources, it will not be able to display a new picture which did not exist on the disk
	before the application start. A work around that limitation, is to provide a full path for your texture file, this will bypass Tacview file manager and
	directly load the data. The picture will still be cached, this will not degrade loading performances.
--]]

require("lua-strict")

-- Request Tacview API

local Tacview = require("Tacview187")

function OnAddCustomTexture()

	Tacview.Terrain.AddCustomTexture("MyCustomTexture", "", "MyCustomTexture.jpg", "Translucent", math.rad(0), math.rad(47), math.rad(2), math.rad(47), math.rad(2), math.rad(45), math.rad(0), math.rad(45) )
	
	Tacview.Terrain.ShowCustomTexture("Bike")

end


----------------------------------------------------------------
-- Add-on initialization
----------------------------------------------------------------

function Initialize()

	-- Declare add-on information

	Tacview.AddOns.Current.SetTitle("Add Custom Texture")
	Tacview.AddOns.Current.SetVersion("0.0.1")
	Tacview.AddOns.Current.SetAuthor("BuzyBee")
	Tacview.AddOns.Current.SetNotes("Add Custom Texture tutorial")

	Tacview.UI.Menus.AddCommand(nil, "Add Custom Texture", OnAddCustomTexture)

end

Initialize()


