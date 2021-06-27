require "OptionScreens/ServerSettingsScreen"
require "OptionScreens/SandBoxOptions"

eHelicopterSandbox = eHelicopterSandbox or {}

eHelicopterSandbox.config = {
	frequency = 2,
	resetEvents = false,
	cutOffDay = 30,
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

eHelicopterSandbox.menu = {

	generalTitle = {type = "Text", text = "General Settings"},
	frequency = {
		type = "Combobox",
		title = "Frequency",
		tooltip = "This will supplant the vanilla helicopter event frequency.",
		options = {{"Rare", 0}, {"Uncommon", 1}, {"Common", 2}, {"Frequent", 3}, {"Insane"}, 6}
		},
	generalSpace = {type = "Space"},

	cutOffDaySpaceA = {type = "Space"},
	cutOffDay = {
		type = "Numberbox",
		title = "Events Cutoff Day",
		tooltip = "The day events will be tapered to end on. Note: some events are scaled to go beyond this day.",
	},
	cutOffDaySpaceB = {type = "Space"},

	--eHelicopterSandbox.config.cutOffDay
	--[[
	testTitle = {type = "Text", text = "test",},

	testSpinBox = {
		type = "Spinbox",
		title = "testSpinBox",
		tooltip = "testSpinBox.",
		options = {{"A", 0},{"B", 1},{"C", 2},{"D", 3}}
	},

	testNumberbox = {
		type = "Numberbox",
		title = "testNumberbox",
		tooltip = "testNumberbox.",
	},

	testSpace = {type = "Space",},

	testTickbox = {
		type = "Tickbox",
		title = "testTickbox",
		tooltip = "testTickbox.",
	},

	testCombobox = {
		type = "Combobox",
		title = "testCombobox",
		tooltip = "testCombobox.",
		options = {{"A", 0},{"B", 1},{"C", 2},{"D", 3}}
	}]]
}



function loadAnnouncersToConfig()

	eHelicopterSandbox.menu["voiceSpaceA"] = {type = "Space"}
	eHelicopterSandbox.menu["voiceTitle"] = {type = "Text", text = "Voice Packs"}

	for k,_ in pairs(eHelicopter_announcers) do
		eHelicopterSandbox.menu[k] = {type = "Tickbox", title = k, tooltip = "", }
		eHelicopterSandbox.config[k] = true
	end

	eHelicopterSandbox.menu["voiceSpaceB"] = {type = "Space"}
end
--run on Lua load
loadAnnouncersToConfig()

function setAnnouncersLoaded()
	eHelicopter_announcersLoaded = {}
	for k,v in pairs(eHelicopterSandbox.config) do
		if (eHelicopter_announcers[k]) and (v == true) then
			table.insert(eHelicopter_announcersLoaded,k)
		end
	end
end
Events.OnGameStart.Add(setAnnouncersLoaded)

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
eHelicopterSandbox.menu["resetEventsA"] = {type = "Space", iteration=4}
eHelicopterSandbox.menu["resetEventsToolTip"] = {type = "Text", text = "Reset scheduled events in case of emergency:", a=0.65, customX=-67}
eHelicopterSandbox.menu["resetEvents"] = {type = "Tickbox", title = "Reset Events", tooltip = "", }


--load mod into EasyConfig
if EasyConfig_Chucked then
	EasyConfig_Chucked.addMod(eHelicopterSandbox.modId, eHelicopterSandbox.name, eHelicopterSandbox.config, eHelicopterSandbox.menu, "EXPANDED HELICOPTER EVENTS", "mainmenu")
end

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
end

Events.OnGameBoot.Add(HelicopterSandboxOptionOverride("OnGameBoot: "))
Events.OnGameStart.Add(HelicopterSandboxOptionOverride("OnGameStart: "))
Events.OnNewGame.Add(HelicopterSandboxOptionOverride("OnNewGame :"))

