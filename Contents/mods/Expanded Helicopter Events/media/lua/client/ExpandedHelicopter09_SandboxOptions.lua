require "_EasyConfig_Chucked"
require "OptionScreens/ServerSettingsScreen"
require "OptionScreens/SandBoxOptions"

eHelicopterSandbox = eHelicopterSandbox or {}

eHelicopterSandbox.config = {
	debugTests = true,
	frequency = 2,
	resetEvents = false,
	cutOffDay = 30,
	startDay = 0,
	neverEndingEvents = false,
	--hostilePreference = "Zombie", --"Player", "All"
	--attackDelay = 95, --min:0.01, max:1000
	--attackDistance = 50, --min:1, max:300
	--attackScope = 1, --min=0, max=3
	--attackSpread = 2, --min=0, max=3
	--speed = 0.25, --min=0.01, max=50
	--topSpeedFactor = 3 --min=1, max=10
	---voices added automatically
}


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

	--[[
	testTitle = {type = "Text", text = "test",},

	testSpinBox = { type = "Spinbox", title = "testSpinBox", tooltip = "testSpinBox.", options = {{"A", 0},{"B", 1},{"C", 2},{"D", 3}} },

	testNumberbox = { type = "Numberbox", title = "testNumberbox", tooltip = "testNumberbox.", },

	testSpace = {type = "Space",},

	testTickbox = { type = "Tickbox", title = "testTickbox", tooltip = "testTickbox.", },

	testCombobox = { type = "Combobox", title = "testCombobox", tooltip = "testCombobox.", options = {{"A", 0},{"B", 1},{"C", 2},{"D", 3}} }
	--]]
}


function loadAnnouncersToConfig()

	if eHelicopterSandbox.menu["voiceSpaceB"] then
		eHelicopterSandbox.menu["voiceSpaceB"] = nil
	end

	eHelicopterSandbox.menu["voiceSpaceA"] = {type = "Space"}
	eHelicopterSandbox.menu["voiceTitle"] = {type = "Text", text = "Voice Packs", }

	for k,_ in pairs(eHelicopter_announcers) do
		eHelicopterSandbox.menu[k] = {type = "Tickbox", title = k, tooltip = "", }
		eHelicopterSandbox.config[k] = true
	end

	eHelicopterSandbox.menu["voiceSpaceB"] = {type = "Space"}
end
loadAnnouncersToConfig()

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
function sandboxOptionsEnd(bAdd)
	if bAdd then
		eHelicopterSandbox.menu["resetEventsA"] = {type = "Space"}
		eHelicopterSandbox.menu["resetEventsToolTip"] = {type = "Text", text = "Reset scheduled events in case of emergency:", a=0.65, customX=-67}
		eHelicopterSandbox.menu["resetEvents"] = {type = "Tickbox", title = "Reset Events", tooltip = "", }

		if getDebug() then
			eHelicopterSandbox.menu["debugTests"] = {type = "Tickbox", title = "EHE: Debug Test Suite", tooltip = "", alwaysAccessible = true }
		end
	else
		eHelicopterSandbox.menu["resetEventsA"] = nil
		eHelicopterSandbox.menu["resetEventsToolTip"] = nil
		eHelicopterSandbox.menu["resetEvents"] = nil
		eHelicopterSandbox.menu["debugTests"] = nil
	end
end
sandboxOptionsEnd(true)

EasyConfig_Chucked = EasyConfig_Chucked or {}
EasyConfig_Chucked.mods = EasyConfig_Chucked.mods or {}
EasyConfig_Chucked.mods[eHelicopterSandbox.modId] = eHelicopterSandbox


--Overrides vanilla helicopter frequency on game boot
---@param hookEvent string optional
function HelicopterSandboxOptionOverride(hookEvent)
	---@type SandboxOptions
	local SANDBOX_OPTIONS = getSandboxOptions()
	---@type SandboxOptions.EnumSandboxOption | SandboxOptions.SandboxOption
	local sandboxHeliFreq = SANDBOX_OPTIONS:getOptionByName("Helicopter")
	--if vanilla helicopter freq is not never then set to never	
	if sandboxHeliFreq:getValue() ~= 1 then
		sandboxHeliFreq:setValue(1) -- 1 = Never
		print("EHE: "..(hookEvent or "").."Setting vanilla helicopter frequency to \"never\".")
	end

	local gameVersion = getCore():getGameVersion()
	if gameVersion:getMajor()>=41 and gameVersion:getMinor()>50 then
		print("EHE: "..(hookEvent or "").."Setting vanilla helicopter Day/StartHour/EndHour to \"0\".")
		getGameTime():setHelicopterDay(0)
		getGameTime():setHelicopterStartHour(0)
		getGameTime():setHelicopterEndHour(0)
	end
end

Events.OnGameBoot.Add(HelicopterSandboxOptionOverride("OnGameBoot: "))
Events.OnGameStart.Add(HelicopterSandboxOptionOverride("OnGameStart: "))
Events.OnNewGame.Add(HelicopterSandboxOptionOverride("OnNewGame: "))

