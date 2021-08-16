---Preset list, only include variables being changed.
---variables can be found in Main Variables file, at the top, fields = variables
eHelicopter_PRESETS = eHelicopter_PRESETS or {}

---Event Schedule Initiation
function eHeliEventsinit()
	eHeliEvents_init = eHeliEvents_init or {}
	eHeliEvents_init["jet"] = {["ID"]=nil, ["heliDay"]=eHelicopterSandbox.config.startDay+ZombRand(0,3), ["heliStart"]=nil}
	eHeliEvents_init["civilian"] = {["ID"]=nil, ["heliDay"]=eHelicopterSandbox.config.startDay+ZombRand(6,8), ["heliStart"]=nil}
	eHeliEvents_init["military"] = {["ID"]=nil, ["heliDay"]=eHelicopterSandbox.config.startDay+ZombRand(0,3), ["heliStart"]=nil}
end
Events.OnGameBoot.Add(eHeliEventsinit)

--[[

eHelicopter_PRESETS["id_name"] = {
		variable = {values}
	}

]]


eHelicopter_PRESETS["military"] = {
	presetRandomSelection = {"increasingly_hostile",3,"increasingly_helpful",1}
	}


eHelicopter_PRESETS["increasingly_hostile"] = {
	presetProgression = {
		["patrol_only"] = 0,
		["patrol_only_emergency"] = 0.02,
		["patrol_only_quarantine"] = 0.05,
		["attack_only_undead_evac"] = 0.1,
		["attack_only_undead"] = 0.2,
		["attack_only_all"] = 0.65,
		}
	}


eHelicopter_PRESETS["increasingly_helpful"] = {
	presetProgression = {
		["patrol_only"] = 0,
		["patrol_only_emergency"] = 0.02,
		["patrol_only_quarantine"] = 0.05,
		["attack_only_undead_evac"] = 0.1,
		["aid_helicopter"] = 0.2,
		["attack_only_all"] = 0.65,
		}
	}


eHelicopter_PRESETS["civilian"] = {
	presetRandomSelection = {"news_chopper",1,"police_heli",3},
	cutOffFactor = 0.67,
	}


eHelicopter_PRESETS["jet"] = {
	frequencyFactor = 0.66,
	speed = 2.8,
	topSpeedFactor = 2,
	flightVolume = 25,
	eventSoundEffects = {["flightSound"] = "eJetFlight"},
	crashType = false,
	shadow = false,
	formationIDs = {"jet", 65, {10,16}, "jet", 25, {10,16}},
	}


eHelicopter_PRESETS["news_chopper"] = {
	hoverOnTargetDuration = {1500,2250},
	eventSoundEffects = {["hoverOverTarget"]="eHeli_newscaster"},
	frequencyFactor = 2,
	speed = 0.06,
	crashType = {"Bell206LBMWFuselage"},
	scrapAndParts = {["vehicleSection"]="Bell206LBMWTail"},
	crew = {"1CivilianPilot", "1NewsReporterArmored", "1NewsReporterArmored", 40},
	--formationIDs = {"police_heli", 100, {6,12}},
	}


eHelicopter_PRESETS["patrol_only"] = {
	announcerVoice = true,
	crew = {"AirCrew", "AirCrew", 75, "AirCrew", 50},
	}


-- EmergencyFlyer QuarantineFlyer EvacuationFlyer NoticeFlyer PreventionFlyer
eHelicopter_PRESETS["patrol_only_emergency"] = {
	announcerVoice = true,
	dropItems = {["EHE.EmergencyFlyer"]=250},
	crew = {"1MilitaryPilot", "1Soldier", 75, "1Soldier", 50},
	formationIDs = {"patrol_only_emergency", 25, {20,25}, "patrol_only_emergency", 10, {20,25}},
	}


eHelicopter_PRESETS["patrol_only_quarantine"] = {
	announcerVoice = true,
	dropItems = {["EHE.QuarantineFlyer"]=250},
	crew = {"1MilitaryPilot", "1Soldier", 75, "1Soldier", 50},
	formationIDs = {"patrol_only_quarantine", 25, {20,25}, "patrol_only_quarantine", 10, {20,25}},
	}


eHelicopter_PRESETS["attack_only_undead_evac"] = {
	hostilePreference = "IsoZombie",
	dropItems = {["EHE.EvacuationFlyer"]=250},
	crew = {"1MilitaryPilot", "1Soldier", 75, "1Soldier", 50},
	formationIDs = {"attack_only_undead_evac", 25, {20,25}, "attack_only_undead_evac", 10, {20,25}},
	}


eHelicopter_PRESETS["attack_only_undead"] = {
	hostilePreference = "IsoZombie",
	crew = {"1MilitaryPilot", "1Soldier", 75, "1Soldier", 50},
	formationIDs = {"attack_only_undead", 25, {12,17}, "attack_only_undead", 10, {12,17}},
	}


eHelicopter_PRESETS["attack_only_all"] = {
	hostilePreference = "IsoGameCharacter",
	crashType = {"UH1HSurvivalistFuselage"},
	crew = {"1SurvivalistPilot", "1Survivalist", 75, "1Survivalist", 50},
	scrapAndParts = {["vehicleSection"]="UH1HSurvivalistTail"},
	}


eHelicopter_PRESETS["police_heli"] = {
	attackDelay = 1100,
	attackSpread = 4,
	speed = 0.06,
	attackHitChance = 100,
	attackDamage = 35,
	crashType = {"Bell206PoliceFuselage"},
	crew = {"1PolicePilot", "1PoliceOfficer", "1PoliceOfficer", 75},
	hostilePreference = "IsoZombie",
	eventSoundEffects = {
		["attackSingle"] = "eHeli_bolt_action_fire_single",
		["attackLooped"] = "eHeli_bolt_action_fire_single",
		["additionalFlightSound"] = "eHeliPoliceSiren",
		},
	hoverOnTargetDuration = {750,1150},
	scrapAndParts = {["vehicleSection"]="Bell206PoliceTail"},
	announcerVoice = "Police",
	}


eHelicopter_PRESETS["aid_helicopter"] = {
	crashType = {"UH1HMedevacFuselage"},
	crew = {"1MilitaryPilot", "1Soldier", 100, "1Soldier", 100},
	dropPackages = {"FEMASupplyDrop"},
	dropItems = {["EHE.NoticeFlyer"]=250},
	speed = 0.06,
	scrapAndParts = {["vehicleSection"]="UH1HMedevacTail"},
	eventSoundEffects = {
		["foundTarget"] = "eHeli_AidDrop_2",
		["droppingPackage"] = "eHeli_AidDrop_1and3",
		},
	formationIDs = {"patrol_only", 25, {12,17}, "patrol_only", 10, {12,17}},
	}
