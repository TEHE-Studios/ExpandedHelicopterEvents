---Preset list, only include variables being changed.
---variables can be found in Main Variables file, at the top, fields = variables

eHelicopter_PRESETS = eHelicopter_PRESETS or {}

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
	presetRandomSelection = {"news_chopper",1,"police_heli",3}
	}


eHelicopter_PRESETS["jet"] = {
	randomEdgeStart = true,
	frequencyFactor = 0.66,
	speed = 2.8,
	topSpeedFactor = 2,
	flightVolume = 25,
	eventSoundEffects = {["flightSound"] = "eJetFlight"},
	crashType = false,
	shadow = false,
	}


eHelicopter_PRESETS["news_chopper"] = {
	hoverOnTargetDuration = {1500,2250},
	eventSoundEffects = {["hoverOverTarget"]="eHeli_newscaster"},
	frequencyFactor = 2,
	speed = 0.06,
	cutOffFactor = 0.5,
	crashType = {"Bell206LBMWFuselage"},
	scrapAndParts = {["vehicleSection"]="Base.Bell206LBMWTail"},
	}


eHelicopter_PRESETS["patrol_only"] = {
	announcerVoice = true,
	crew = {"AirCrew", "AirCrew", 75, "AirCrew", 50},
	}


-- EmergencyFlyer QuarantineFlyer EvacuationFlyer NoticeFlyer PreventionFlyer
eHelicopter_PRESETS["patrol_only_emergency"] = {
	announcerVoice = true,
	dropItems = {["EmergencyFlyer"]=250},
	crew = {"1MilitaryPilot", "1Soldier", 75, "1Soldier", 50},
	}


eHelicopter_PRESETS["patrol_only_quarantine"] = {
	announcerVoice = true,
	dropItems = {["QuarantineFlyer"]=250},
	crew = {"1MilitaryPilot", "1Soldier", 75, "1Soldier", 50},
	}


eHelicopter_PRESETS["attack_only_undead_evac"] = {
	hostilePreference = "IsoZombie",
	dropItems = {["EvacuationFlyer"]=250},
	crew = {"1MilitaryPilot", "1Soldier", 75, "1Soldier", 50},
	}


eHelicopter_PRESETS["attack_only_undead"] = {
	hostilePreference = "IsoZombie",
	crew = {"1MilitaryPilot", "1Soldier", 75, "1Soldier", 50},
	}


eHelicopter_PRESETS["attack_only_all"] = {
	hostilePreference = "IsoGameCharacter",
	crashType = {"UH1Hsurvivalistcrash"},
	crew = {"1SurvivalistPilot", "1Survivalist", 75, "1Survivalist", 50},
	cutOffFactor = 1.5,
	}


eHelicopter_PRESETS["police_heli"] = {
	attackDelay = 1100,
	cutOffFactor = 0.67,
	attackSpread = 4,
	speed = 0.06,
	attackHitChance = 100,
	attackDamage = 35,
	crashType = {"Bell206PoliceCrashed"},
	crew = {"1PolicePilot", "1PoliceOfficer", "1PoliceOfficer", 75},
	hostilePreference = "IsoZombie",
	eventSoundEffects = {
		["attackSingle"] = "eHeli_bolt_action_fire_single",
		["attackLooped"] = "eHeli_bolt_action_fire_single",
		["additionalFlightSound"] = "eHeliPoliceSiren",
		},
	hoverOnTargetDuration = {750,1150},
	}


eHelicopter_PRESETS["aid_helicopter"] = {
	crashType = {"UH1Hmedevaccrash"},
	crew = {"1MilitaryPilot", "1Soldier", 100, "1Soldier", 100},
	dropPackages = {"FEMASupplyDrop"},
	dropItems = {["NoticeFlyer"]=250},
	cutOffFactor = 0.43,
	speed = 0.06,
	eventSoundEffects = {
		["foundTarget"] = "eHeli_AidDrop_2",
		["droppingPackage"] = "eHeli_AidDrop_1and3",
		},
	}