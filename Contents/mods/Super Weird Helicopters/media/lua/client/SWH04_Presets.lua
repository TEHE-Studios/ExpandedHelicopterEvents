---Event Scheduler List
eHeliEvents_init = eHeliEvents_init or {}
--[[
eHeliEvents_init["preset"] = {["ID"]=nil, ["heliDay"]=configStartDay, ["heliStart"]=nil}
]]
eHeliEvents_init["Spiffocopter"] = {["ID"]=nil, ["heliDay"]=configStartDay, ["heliStart"]=nil}
eHeliEvents_init["UFO"] = {["ID"]=nil, ["heliDay"]=configStartDay, ["heliStart"]=nil}
eHeliEvents_init["IRS"] = {["ID"]=nil, ["heliDay"]=configStartDay, ["heliStart"]=nil}
eHeliEvents_init["TISCreamery"] = {["ID"]=nil, ["heliDay"]=configStartDay, ["heliStart"]=nil}


---Preset list, only include variables being changed.
---variables can be found in Main Variables file, at the top, fields = variables
eHelicopter_PRESETS = eHelicopter_PRESETS or {}

--[[
eHelicopter_PRESETS["id_name"] = {
		variable = {values}
	}
]]

eHelicopter_PRESETS["Spiffocopter"] = {
	crashType = {"Bell206SpiffoFuselage"},
	hostilePreference = "IsoPlayer",
	hoverOnTargetDuration = {2000,2250},
	scrapAndParts = {["vehicleSection"]="Bell206SpiffoTail"},
	crew = {"SpiffoBoss"},
	addedCrashChance = 75,
	frequencyFactor = 0.1,
}

eHelicopter_PRESETS["UFO"] = {
	crashType = {"UFO"},
	hostilePreference = "IsoPlayer",
	hoverOnTargetDuration = {2000,2250},
	crew = {"AlienTourist", "AlienTourist", "AlienTourist",60, "AlienTourist",30, "AlienTourist",10, },
	addedCrashChance = 25,
	frequencyFactor = 0.1,
}

eHelicopter_PRESETS["IRS"] = {
	crashType = {"Bell206IRSFuselage"},
	hostilePreference = "IsoPlayer",
	hoverOnTargetDuration = {2000,2250},
	scrapAndParts = {["vehicleSection"]="Bell206IRSTail"},
	crew = {"1TaxMan", "1TaxMan", "1TaxMan", "1TaxMan", "1TaxMan",
			"1TaxMan", "1TaxMan", "1TaxMan", "1TaxMan", "1TaxMan",
			"1TaxMan", "1TaxMan", "1TaxMan", "1TaxMan", "1TaxMan",
			"1TaxMan", "1TaxMan", "1TaxMan", "1TaxMan", "1TaxMan",
			"1TaxMan", "1TaxMan", "1TaxMan", "1TaxMan", "1TaxMan"},
	addedCrashChance = 25,
	frequencyFactor = 0.1,
}

eHelicopter_PRESETS["TISCreamery"] = {
	crashType = {"TISIceCreamTruck"},
	hostilePreference = "IsoPlayer",
	hoverOnTargetDuration = {2000,2250},
	addedCrashChance = 25,
	crew = {"RobertJohnson"},
	frequencyFactor = 0.1,
}
