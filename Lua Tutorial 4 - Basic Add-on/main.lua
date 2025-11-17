
-- To communicate with Tacview, we first need to declare which interface we want to use.
-- For instance this tutorial has been programmed for Tacview 1.7.3

local Tacview = require("Tacview173")

-- Before anything else we should name our add-on

Tacview.AddOns.Current.SetTitle("Lua Tutorial 4 - Basic demo")
Tacview.AddOns.Current.SetVersion("1.7.3")
Tacview.AddOns.Current.SetAuthor("Vyrtuoz")
Tacview.AddOns.Current.SetNotes("Basic tutorial to show how to use Tacview Lua API")

-- We can directly ask Tacview to display specific information in its log

Tacview.Log.Info("Hello, I am a text displayed in Tacview console using Tacview 1.7.3 Lua API!")
