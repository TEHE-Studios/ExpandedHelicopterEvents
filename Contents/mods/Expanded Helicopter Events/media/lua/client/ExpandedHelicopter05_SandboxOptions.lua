require "EasyConfig_Chucked"
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
}



eHelicopterSandbox.modId = "ExpandedHelicopterEvents" -- needs to the same as in your mod.info
eHelicopterSandbox.name = "Expanded Helicopter Events" -- the name that will be shown in the MOD tab

eHelicopterSandbox.menu = {

	generalTitle = {type = "Text",text = "General Settings",},
	frequency = {
		type = "Combobox",
		title = "Frequency",
		tooltip = "This will supplant the vanilla helicopter event frequency.",
		options = {{"Never", 0}, {"Once", 1}, {"Sometimes", 2}, {"Often", 3}}
		},
	generalSpace = {type = "Space",},

	voiceTitle = {type = "Text",text = "Voice Packs",},
	voice1 = { type = "Tickbox", title = "Voice 1", tooltip = "", },
	voice2 = { type = "Tickbox", title = "Voice 2", tooltip = "", },
	voice3 = { type = "Tickbox", title = "Voice 3", tooltip = "", },
	voice4 = { type = "Tickbox", title = "Voice 4", tooltip = "", },
	voiceSpace = {type = "Space",},
}

--[[
	zombieTitle = {type = "Text",text = "Other Zombie Settings",},

	openDoorChance = {
		type = "Numberbox",
		title = "Thumps open doors (%)",
		tooltip = "The chance that a zombie will open an unlocked door by accident.",
		},

	zombieSpace = {type = "Space",},

	combatEnabled = {
		type = "Tickbox",
		title = "Alternative combat",
		tooltip = "The chance to hit several targets with a weapon depends on skills & current condition. Pushing does not interrupt movement. Turn speed is doubled.",
		},

	fasterSeasons = {
		type = "Combobox",
		title = "Season speed",
		tooltip = "Makes days pass faster on the clock. This speeds up seasons & weather simulation, but has no effects on day length or gameplay.",
		options = {{"1x", 0},{"2x", 1},{"3x", 2},{"4x", 3},}
		}

]]

EasyConfig.addMod(eHelicopterSandbox.modId, eHelicopterSandbox.name, eHelicopterSandbox.config, eHelicopterSandbox.menu, "Expanded Helicopter Events")


function HelicopterSandboxOptionOverride()
	---@type SandboxOptions
	local SANDBOX_OPTIONS = getSandboxOptions()
	---@type SandboxOptions.EnumSandboxOption | SandboxOptions.SandboxOption
	local sandboxHeliFreq = SANDBOX_OPTIONS:getOptionByName("Helicopter")

	print("VANILLA HELICOPTER SANDBOX OPTION: ".."<"..sandboxHeliFreq:getValueTranslationByIndex(sandboxHeliFreq:getValue()).."> ".."(".. sandboxHeliFreq:getValue()..")")

	if sandboxHeliFreq:getValue() ~= 1 then
		print("sandboxHeliFreq not <".. sandboxHeliFreq:getValueTranslationByIndex(1).."> (1)")
		sandboxHeliFreq:setValue(1) --1 = Never
		print("setting now: <"..sandboxHeliFreq:getValueTranslationByIndex(sandboxHeliFreq:getValue()).."> ".."(".. sandboxHeliFreq:getValue()..")")
	end
end


Events.OnGameStart.Add(HelicopterSandboxOptionOverride)

Events.OnCustomUIKey.Add(function(key)
	if key == Keyboard.KEY_4 then
		HelicopterSandboxOptionOverride()
	end
end)


