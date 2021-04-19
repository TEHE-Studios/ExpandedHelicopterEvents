require "_EasyConfig_Chucked"
require "OptionScreens/ServerSettingsScreen"
require "OptionScreens/SandBoxOptions"

eHelicopterSandbox = eHelicopterSandbox or {}

eHelicopterSandbox.config = {
	frequency = 2,
	resetEvents = false,
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
		options = {{"Never", 0}, {"Once", 1}, {"Sometimes", 2}, {"Often", 3}}
		},
	generalSpace = {type = "Space"},

	--voiceTitle = {type = "Text", text = "Voice Packs"},
	--voice1 = { type = "Tickbox", title = "Voice 1", tooltip = "", },
	--voiceSpace = {type = "Space"},

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


--add buffer space for reset feature
eHelicopterSandbox.menu["resetEventsA"] = {type = "Space", iteration=4}
eHelicopterSandbox.menu["resetEventsToolTip"] = {type = "Text", text = "Reset scheduled events in case of emergency:", a=0.65, customX=-67}
eHelicopterSandbox.menu["resetEvents"] = {type = "Tickbox", title = "Reset Events", tooltip = "", }


--load mod into EasyConfig
EasyConfig_Chucked.addMod(eHelicopterSandbox.modId, eHelicopterSandbox.name, eHelicopterSandbox.config, eHelicopterSandbox.menu, "EXPANDED HELICOPTER EVENTS")


--Overrides vanilla helicopter frequency on game boot
function HelicopterSandboxOptionOverride()
	---@type SandboxOptions
	local SANDBOX_OPTIONS = getSandboxOptions()
	---@type SandboxOptions.EnumSandboxOption | SandboxOptions.SandboxOption
	local sandboxHeliFreq = SANDBOX_OPTIONS:getOptionByName("Helicopter")
	--if vanilla helicopter freq is not never then set to never	
	if sandboxHeliFreq:getValue() ~= 1 then
		sandboxHeliFreq:setValue(1) -- 1 = Never
	end
end

Events.OnGameBoot.Add(HelicopterSandboxOptionOverride)

