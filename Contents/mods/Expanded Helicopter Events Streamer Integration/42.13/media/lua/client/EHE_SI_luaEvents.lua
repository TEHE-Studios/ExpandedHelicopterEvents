local config = require "EHE_SI_config"
Events.OnGameBoot.Add(config.apply)

local keyPress = require "EHE_SI_keyPress.lua"
Events.OnKeyPressed.Add(keyPress.OnKeyPressed)