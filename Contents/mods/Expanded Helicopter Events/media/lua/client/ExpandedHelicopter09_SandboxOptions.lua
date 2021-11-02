require "OptionScreens/ServerSettingsScreen"
require "OptionScreens/SandBoxOptions"

eHelicopterSandbox = eHelicopterSandbox or {}
eHelicopterSandbox.config = { debugTests = false, frequency = 2, resetEvents = false, cutOffDay = 30, startDay = 0, neverEndingEvents = false, eventMarkersOn = true}
---voices added automatically

eHelicopterSandbox.modId = "ExpandedHelicopterEvents" -- needs to the same as in your mod.info
eHelicopterSandbox.name = "Expanded Helicopter Events" -- the name that will be shown in the MOD tab
eHelicopterSandbox.menuSpecificAccess = "mainmenu"

eHelicopterSandbox.menu = {
	frequency = { type = "Combobox", title = "Frequency", options = {{"Rare", 0}, {"Uncommon", 1}, {"Common", 2}, {"Frequent", 3}, {"Insane", 6}} },
	frequencyToolTip = {type = "Text", text = "This will supplant the vanilla helicopter event frequency.", a=0.65, customX=-56},
	generalSpaceA = {type = "Space"},

	startDay = { type = "Numberbox", title = "Events Start Day", },
	startDayToolTip = {type = "Text", text = "The day the scheduler will start assigning events to. \nNote: Some events are set to start later than this day.", a=0.65, customX=-56},
	generalSpaceB = {type = "Space"},

	cutOffDay = { type = "Numberbox", title = "Events CutOff Day", },
	cutOffDayToolTip = {type = "Text", text = "The day the scheduler will tapered events to end on. \nNote: Some events are scaled to go beyond this day.", a=0.65, customX=-56},
	generalSpaceC = {type = "Space"},

	neverEndingEvents = { type = "Tickbox", title = "Never Ending Events", },
	neverEndingEventsToolTip = {type = "Text", text = "Toggle this on so that the scheduler will always renew events. \nEvents will still progress through stages, and taper off in occurrence, but will never end.", a=0.65, customX=-56},
	generalSpaceD = {type = "Space"},
}



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

--[[
function loadPresetToConfig()
	eHelicopterSandbox.menu["presetsSpaceA"] = {type = "Space", iteration=2}
	eHelicopterSandbox.menu["presetsTitle"] = {type = "Text", text = "Events"}

	eHelicopterSandbox.menu["presetsSpaceB"] = {type = "Space"}
	eHelicopterSandbox.menu["presetsDefault"] = {type = "Text", text = "Default Values"}
	for var,value in pairs(eHelicopter_initialVars) do
		local varMenuID = "varForDefault"..var
		eHelicopterSandbox.menu[varMenuID] = {type = "Text", text = var.." = "..tostring(value),}
		--eHelicopterSandbox.config[var] = variableValue
	end
	eHelicopterSandbox.menu["presetsSpaceForpresetsDefault"] = {type = "Space", iteration=2}

	eHelicopterSandbox.menu["presetsSpaceC"] = {type = "Space"}
	for presetID,presetVars in pairs(eHelicopter_PRESETS) do
		eHelicopterSandbox.menu[presetID] = {type = "Text", text = presetID}
		for var,value in pairs(presetVars) do
			local varMenuID = "varFor"..presetID..var
			eHelicopterSandbox.menu[varMenuID] = {type = "Text", text = tostring(value),}
			--eHelicopterSandbox.config[var] = variableValue
		end
		local spaceID = "presetsSpaceFor"..presetID
		eHelicopterSandbox.menu[spaceID] = {type = "Space", iteration=2}
	end
	eHelicopterSandbox.menu["presetsSpaceD"] = {type = "Space"}
end
--run on Lua load
loadPresetToConfig()]]


--add buffer space for reset feature
function sandboxOptionsEnd()
	eHelicopterSandbox.menu["resetEventsA"] = nil
	eHelicopterSandbox.menu["resetEventsToolTip"] = nil
	eHelicopterSandbox.menu["resetEvents"] = nil
	eHelicopterSandbox.menu["debugTests"] = nil
	eHelicopterSandbox.menu["resetEventsA"] = {type = "Space"}
	eHelicopterSandbox.menu["resetEventsToolTip"] = {type = "Text", text = "Reset scheduled events in case of emergency:", a=0.65, customX=-67}
	eHelicopterSandbox.menu["resetEvents"] = {type = "Tickbox", title = "Reset Events", tooltip = "", }
	eHelicopterSandbox.menu["generalSpaceD"] = {type = "Space"}
	eHelicopterSandbox.menu["eventMarkersOnToolTip"] = {type = "Text", text = "Toggle this on to enable event markers. \nNote: Events markers can be dragged.", a=0.65, customX=-67, }
	eHelicopterSandbox.menu["eventMarkersOn"] = { type = "Tickbox", title = "Event Markers", alwaysAccessible = true}
	eHelicopterSandbox.menu["generalSpaceE"] = {type = "Space"}

	if getDebug() then
		eHelicopterSandbox.menu["debugTests"] = {type = "Tickbox", title = "EHE: Debug Test Suite", tooltip = "", alwaysAccessible = true }
	end
end

EasyConfig_Chucked = EasyConfig_Chucked or {}
EasyConfig_Chucked.mods = EasyConfig_Chucked.mods or {}
EasyConfig_Chucked.mods[eHelicopterSandbox.modId] = eHelicopterSandbox


gameVersion = getCore():getGameVersion()
oldGameVersion = true

--Overrides vanilla helicopter frequency on game boot
---@param hookEvent string optional
function HelicopterSandboxOptions(hookEvent)
	---@type SandboxOptions
	local SANDBOX_OPTIONS = getSandboxOptions()
	---@type SandboxOptions.EnumSandboxOption | SandboxOptions.SandboxOption
	local sandboxHeliFreq = SANDBOX_OPTIONS:getOptionByName("Helicopter")
	--if vanilla helicopter freq is not never then set to never	
	if sandboxHeliFreq:getValue() ~= 1 then
		sandboxHeliFreq:setValue(1) -- 1 = Never
		print("EHE: "..(hookEvent or "").."Setting vanilla helicopter frequency to \"never\".")
	end

	if (gameVersion and gameVersion:getMajor()>=41 and gameVersion:getMinor()>50) then
		oldGameVersion = false

		eHelicopterSandbox.menu.frequency = nil
		eHelicopterSandbox.menu.frequencyToolTip = nil
		eHelicopterSandbox.menu.generalSpaceA = nil
		eHelicopterSandbox.menu.startDay = nil
		eHelicopterSandbox.menu.startDayToolTip = nil
		eHelicopterSandbox.menu.generalSpaceB = nil
		eHelicopterSandbox.menu.cutOffDay = nil
		eHelicopterSandbox.menu.cutOffDayToolTip = nil
		eHelicopterSandbox.menu.generalSpaceC = nil
		eHelicopterSandbox.menu.neverEndingEvents = nil
		eHelicopterSandbox.menu.neverEndingEventsToolTip = nil
		eHelicopterSandbox.menu.generalSpaceD = nil

		eHelicopterSandbox.menu.sandBoxMovedText = {type = "Text", text = "Configuration options can be found in sandbox options.", r=1, g=0.2, b=0.2, a=0.65, customX=-56}
	else
		print("EHE: 41.50 or older version detected: Sandbox Options in Main Menu.")
	end
	loadAnnouncersToConfig()
	sandboxOptionsEnd()

	if not oldGameVersion then
		print("EHE: "..(hookEvent or "").."Setting vanilla helicopter Day/StartHour/EndHour to \"0\".")
		getGameTime():setHelicopterDay(0)
		getGameTime():setHelicopterStartHour(0)
		getGameTime():setHelicopterEndHour(0)
	end
end

Events.OnGameBoot.Add(HelicopterSandboxOptions("OnGameBoot: "))

