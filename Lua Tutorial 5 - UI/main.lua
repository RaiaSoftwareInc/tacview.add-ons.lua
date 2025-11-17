
-- To communicate with Tacview, we first need to declare which interface we want to use.
-- For instance this tutorial has been programmed for Tacview 1.7.3

local Tacview = require("Tacview173")

-- Before anything else we should name our add-on

Tacview.AddOns.Current.SetTitle("Lua Tutorial 5 - UI demo")
Tacview.AddOns.Current.SetVersion("1.7.3")
Tacview.AddOns.Current.SetAuthor("Vyrtuoz")
Tacview.AddOns.Current.SetNotes("How to use Tacview UI")

-- Display a messagebox when called

function OnClickMe()

	if Tacview.UI.MessageBox.Question("What do you think?", "Shall we continue?") == Tacview.UI.MessageBox.OK then
		Tacview.UI.MessageBox.Info("All right let's go!")
	else
		Tacview.UI.MessageBox.Info("Sorry about that, I guess I will have to fly alone...")
	end

end

-- Declare a main menu, then insert a command in it.
-- As soon as the user will select the "Click me!" menu option, the function OnClickMe will be called

local mainMenuHandle = Tacview.UI.Menus.AddMenu(nil, "Lua UI demo")

Tacview.UI.Menus.AddCommand(mainMenuHandle, "Click me!", OnClickMe)

-- You can easily use menus to offer options to the user

local optionMenuHandle
local optionValue = false

function OnOptionSelect()

	-- Switch the option value

	optionValue = not optionValue

	Tacview.Log.Info("The option has been changed to", optionValue)

	-- Change the option menu value

	Tacview.UI.Menus.SetOption(optionMenuHandle, optionValue)

end

optionMenuHandle = Tacview.UI.Menus.AddOption(mainMenuHandle, "Switch me!", optionValue, OnOptionSelect)
