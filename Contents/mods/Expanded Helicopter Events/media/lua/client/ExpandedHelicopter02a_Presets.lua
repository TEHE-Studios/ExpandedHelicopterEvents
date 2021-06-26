---Preset list, only include variables being changed.
---variables can be found in Main file, at the top, fields = variables
eHelicopter_PRESETS = {

	["military"] = {
		presetRandomSelection = {"increasingly_hostile",3,"increasingly_helpful",1}
	},

	["increasingly_hostile"] = {
		presetProgression = {
			["patrol_only"] = 0,
			["patrol_only_emergency"] = 0.02,
			["patrol_only_quarantine"] = 0.05,
			["attack_only_undead_evac"] = 0.1,
			["attack_only_undead"] = 0.15,
			["attack_only_all"] = 0.75,
		}
	},

	["civilian"] = {
		presetRandomSelection = {"news_chopper",1,"police_heli",3}
	},

	["jet"] = {
		randomEdgeStart = true,
		frequencyFactor = 0.66,
		speed = 3,
		topSpeedFactor = 2,
		flightVolume = 25,
		eventSoundEffects = {["flightSound"] = "eJetFlight"},
		crashType = false,
		shadow = false,
	},

	["news_chopper"] = {
		hoverOnTargetDuration = {1500,2250},
		eventSoundEffects = {["hoverOverTarget"]="eHeli_newscaster"},
		frequencyFactor = 2,
		speed = 0.1,
		cutOffFactor = 0.5,
		crashType = {"Bell206LBMWCrashed"}
	},

	["patrol_only"] = {
		announcerVoice = true,
		crew = {"AirCrew", "AirCrew", 75, "AirCrew", 50},
	},

	-- EmergencyFlyer QuarantineFlyer EvacuationFlyer NoticeFlyer PreventionFlyer
	["patrol_only_emergency"] = {
		announcerVoice = true,
		dropItems = {["EmergencyFlyer"]=250},
		crew = {"1MilitaryPilot", "1Soldier", 75, "1Soldier", 50},
	},

	["patrol_only_quarantine"] = {
		announcerVoice = true,
		dropItems = {["QuarantineFlyer"]=250},
		crew = {"1MilitaryPilot", "1Soldier", 75, "1Soldier", 50},
	},

	["attack_only_undead_evac"] = {
		hostilePreference = "IsoZombie",
		dropItems = {["EvacuationFlyer"]=250},
		crew = {"1MilitaryPilot", "1Soldier", 75, "1Soldier", 50},
	},

	["attack_only_undead"] = {
		hostilePreference = "IsoZombie",
		crew = {"1MilitaryPilot", "1Soldier", 75, "1Soldier", 50},
	},

	["attack_only_all"] = {
		hostilePreference = "IsoGameCharacter",
		crashType = {"UH1Hsurvivalistcrash"},
		crew = {"1SurvivalistPilot", "1Survivalist", 75, "1Survivalist", 50},
		cutOffFactor = 1.5,
	},

	["police_heli"] = {
		attackDelay = 1100,
		cutOffFactor = 0.67,
		attackSpread = 4,
		speed = 0.09,
		attackHitChance = 100,
		attackDamage = 35,
		crashType = {"Bell206PoliceCrashed"},
		crew = {"1PolicePilot", "1PoliceOfficer", "1PoliceOfficer", 75},
		hostilePreference = "IsoZombie",
		eventSoundEffects = {
			["attackSingle"] = "eHeli_bolt_action_fire_single",["attackLooped"] = "eHeli_bolt_action_fire_single",
			["attackImpacts"] = "eHeli_fire_impact",
			["flightSound"] = "eHeliPoliceSiren",
		},
		hoverOnTargetDuration = {750,1150},
	},

	["aid_helicopter"] = {
		crashType = {"UH1Hmedevaccrash"},
		crew = {"1MilitaryPilot", "1Soldier", 100, "1Soldier", 100},
		dropPackages = {"FEMASupplyDrop"},
		dropItems = {["NoticeFlyer"]=250},
		cutOffFactor = 0.43,
	},

	["increasingly_helpful"] = {
		presetProgression = {
			["patrol_only"] = 0,
			["aid_helicopter"] = 0.25,
		}
	},

	["TestHeli"] = {
		presetRandomSelection = {"news_chopper",1,"increasingly_helpful",3}
	},
}
