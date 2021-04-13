require "_EasyConfig_Chucked"
require "OptionScreens/ServerSettingsScreen"
require "OptionScreens/SandBoxOptions"

--[[
eHelicopterSandboxOptions = {}
eHelicopterSandboxOptions.freq = {["value"]=2, ["default"]=2, ["type"]="dropdown",
	["options"]={[1]="Sandbox_HelicopterFreq_option1",[2]="Sandbox_HelicopterFreq_option2",[3]="Sandbox_HelicopterFreq_option3",[4]="Sandbox_HelicopterFreq_option4"}
	}

eHelicopterSandboxOptions.hostilePreference = {["value"]="IsoZombie", ["default"]="IsoZombie", ["type"]="multi-choice",
	["options"]={[1]="IsoZombie",[2]="IsoPlayer",[3]="All"}
	}

eHelicopterSandboxOptions.attackDelay = {["value"]=95, ["default"]=95, ["type"]="number", ["min"]=0.01, ["max"]=1000}
eHelicopterSandboxOptions.attackDistance = {["value"]=50, ["default"]=50, ["type"]="number", ["min"]=1, ["max"]=300}
eHelicopterSandboxOptions.attackScope = {["value"]=1, ["default"]=1, ["type"]="number", ["min"]=0, ["max"]=3}
eHelicopterSandboxOptions.attackSpread = {["value"]=2, ["default"]=2, ["type"]="number", ["min"]=0, ["max"]=3}
eHelicopterSandboxOptions.speed = {["value"]=0.25, ["default"]=0.25, ["type"]="number", ["min"]=0.01, ["max"]=50}
eHelicopterSandboxOptions.topSpeedFactor = {["value"]=3, ["default"]=3, ["type"]="number", ["min"]=1, ["max"]=10}
]]

eHelicopterSandbox = eHelicopterSandbox or {}

eHelicopterSandbox.config = {
	frequency = 2,
	--hostilePreference = "Zombie",
	--attackDelay = 95,
	--attackDistance = 50,
	--attackScope = 1,
	--attackSpread = 2,
	--speed = 0.25,
	--topSpeedFactor = 3
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
		eHelicopterSandbox.menu[k] = { type = "Tickbox", title = k, tooltip = "", }
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


EasyConfig_Chucked.addMod(eHelicopterSandbox.modId, eHelicopterSandbox.name, eHelicopterSandbox.config, eHelicopterSandbox.menu, "EXPANDED HELICOPTER EVENTS")


function HelicopterSandboxOptionOverride()
	---@type SandboxOptions
	local SANDBOX_OPTIONS = getSandboxOptions()
	---@type SandboxOptions.EnumSandboxOption | SandboxOptions.SandboxOption
	local sandboxHeliFreq = SANDBOX_OPTIONS:getOptionByName("Helicopter")

	print("VANILLA HELICOPTER SANDBOX OPTION: ".."<"..sandboxHeliFreq:getValueTranslationByIndex(sandboxHeliFreq:getValue()).."> ".."(".. sandboxHeliFreq:getValue()..")")

	if sandboxHeliFreq:getValue() ~= 1 then
		print("sandboxHeliFreq not \"never\"")
		sandboxHeliFreq:setValue(1) --1 = Never
		print("setting now to: <"..sandboxHeliFreq:getValueTranslationByIndex(sandboxHeliFreq:getValue()).."> ".."(".. sandboxHeliFreq:getValue()..")")
	end
end


Events.OnGameBoot.Add(HelicopterSandboxOptionOverride)

Events.OnCustomUIKey.Add(function(key)
	if key == Keyboard.KEY_4 then
		HelicopterSandboxOptionOverride()
	end
end)


