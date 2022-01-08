require "OptionScreens/ServerSettingsScreen"
require "OptionScreens/SandBoxOptions"
require "EasyConfigChucked1_Main"

eHelicopterSandbox = eHelicopterSandbox or {}

eHelicopterSandbox.modId = "ExpandedHelicopterEvents" -- needs to the same as in your mod.info
eHelicopterSandbox.name = "Expanded Helicopter Events" -- the name that will be shown in the MOD tab
eHelicopterSandbox.menuSpecificAccess = "mainmenu"

eHelicopterSandbox.config = eHelicopterSandbox.config or {}
eHelicopterSandbox.config.eventMarkersOn = true
eHelicopterSandbox.config.resetEvents = false

eHelicopterSandbox.menu = eHelicopterSandbox.menu or {}
eHelicopterSandbox.menu.sandBoxMovedText = {type = "Text", text = "Configuration options can be found in sandbox options.", r=1, g=0.2, b=0.2, a=0.65,customX=-56}
---voices added automatically


function loadAnnouncersToConfig()

	if eHelicopterSandbox.menu["voiceSpaceB"] then
		eHelicopterSandbox.menu["voiceSpaceB"] = nil
	end

	eHelicopterSandbox.menu["voiceSpaceA"] = {type = "Space"}
	eHelicopterSandbox.menu["voiceTitle"] = {type = "Text", text = "Voice Packs", }

	for k,params in pairs(eHelicopter_announcers) do
		if params.DoNotDisplayOnOptions ~= true then
			eHelicopterSandbox.menu[k] = {type = "Tickbox", title = k, tooltip = "", }
			eHelicopterSandbox.config[k] = eHelicopterSandbox.config[k] or true
		end
	end

	eHelicopterSandbox.menu["voiceSpaceB"] = {type = "Space"}
end

--add buffer space for reset feature
function sandboxOptionsEnd()
	eHelicopterSandbox.menu["generalSpaceA"] = nil
	eHelicopterSandbox.menu["resetEventsToolTip"] = nil
	eHelicopterSandbox.menu["resetEvents"] = nil
	eHelicopterSandbox.menu["generalSpaceD"] = nil
	eHelicopterSandbox.menu["eventMarkersOnToolTip"] =  nil
	eHelicopterSandbox.menu["eventMarkersOn"] = nil
	eHelicopterSandbox.menu["generalSpaceE"] = nil

	eHelicopterSandbox.menu["generalSpaceA"] = {type = "Space", alwaysAccessible = true}
	eHelicopterSandbox.menu["resetEventsToolTip"] = {type = "Text", text = "Reset scheduled events in case of emergency:", a=0.65, customX=-67}
	eHelicopterSandbox.menu["resetEvents"] = {type = "Tickbox", title = "Reset Events", tooltip = "", }
	eHelicopterSandbox.menu["generalSpaceD"] = {type = "Space"}
	eHelicopterSandbox.menu["eventMarkersOnToolTip"] = {type = "Text", text = "Toggle this on to enable event markers. \nNote: Events markers can be dragged.", a=0.65, customX=-67, }
	eHelicopterSandbox.menu["eventMarkersOn"] = { type = "Tickbox", title = "Event Markers", alwaysAccessible = true}
	eHelicopterSandbox.menu["generalSpaceE"] = {type = "Space", alwaysAccessible = true}

	loadAnnouncersToConfig()
end

EasyConfig_Chucked = EasyConfig_Chucked or {}
EasyConfig_Chucked.mods = EasyConfig_Chucked.mods or {}
EasyConfig_Chucked.mods[eHelicopterSandbox.modId] = eHelicopterSandbox
Events.OnGameBoot.Add(sandboxOptionsEnd)