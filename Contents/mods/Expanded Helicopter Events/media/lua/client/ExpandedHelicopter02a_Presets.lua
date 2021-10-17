---Preset list, only include variables being changed.
---variables can be found in Main Variables file, at the top, fields = variables
eHelicopter_PRESETS = eHelicopter_PRESETS or {}

---Event Schedule Initiation
function eHeliEventsinit()
	eHeliEvents_init = eHeliEvents_init or {}

	local startDay = 0
	local cutOffDay = 30
	if oldGameVersion then
		startDay = eHelicopterSandbox.config.startDay
		cutOffDay = eHelicopterSandbox.config.cutOffDay
	else
		startDay = SandboxVars.ExpandedHeli.StartDay
		cutOffDay = SandboxVars.ExpandedHeli.CutOffDay
	end

	eHeliEvents_init["jet"] = {["ID"]=nil, ["heliDay"]=startDay, ["heliStart"]=12}
	eHeliEvents_init["jet_bombing"] = {["ID"]=nil, ["heliDay"]=startDay+cutOffDay*0.2, ["heliStart"]=12, ["neverRenew"]=true}
	eHeliEvents_init["air_raid"] = {["ID"]=nil, ["heliDay"]=startDay+cutOffDay*0.2, ["heliStart"]=11, ["neverRenew"]=true}
	eHeliEvents_init["civilian"] = {["ID"]=nil, ["heliDay"]=startDay+ZombRand(6,8), ["heliStart"]=nil}
	eHeliEvents_init["military"] = {["ID"]=nil, ["heliDay"]=startDay+ZombRand(0,2), ["heliStart"]=nil}
	eHeliEvents_init["aid_survivor"] = {["ID"]=nil, ["heliDay"]=startDay+math.floor(cutOffDay*ZombRand(1,1.3)), ["heliStart"]=nil}
end
Events.OnGameStart.Add(eHeliEventsinit)

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
	}


eHelicopter_PRESETS["jet_bombing"] = {
	speed = 2.8,
	topSpeedFactor = 2,
	flightVolume = 25,
	eventSoundEffects = {["flightSound"] = "eJetFlight", ["soundAtEventOrigin"] = "eCarpetBomb"},
	crashType = false,
	shadow = false,
}


eHelicopter_PRESETS["news_chopper"] = {
	hoverOnTargetDuration = {1500,2250},
	eventSoundEffects = { ["hoverOverTarget"] = "eHeli_newscaster", ["flightSound"] = "eHelicopter", },
	frequencyFactor = 2,
	speed = 0.07,
	crashType = {"Bell206LBMWFuselage"},
	scrapAndParts = {"Bell206PoliceTail", "EHE.Bell206RotorBlade", 4},
	crew = {"EHECivilianPilot", "EHENewsReporterArmored", "EHENewsReporterArmored", 40},
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


eHelicopter_PRESETS["air_raid"] = {
	crashType = false,
	shadow = false,
	speed = 0.05,
	eventSoundEffects = {["soundAtEventOrigin"] = "eAirRaid"},
}


eHelicopter_PRESETS["attack_only_undead_evac"] = {
	hostilePreference = "IsoZombie",
	dropItems = {["EHE.EvacuationFlyer"]=250},
	crew = {"EHEMilitaryPilot", "EHESoldier", 75, "EHESoldier", 50},
	formationIDs = {"air_raid", "attack_only_undead_evac", 25, {20,25}, "attack_only_undead_evac", 10, {20,25}},
	}


eHelicopter_PRESETS["attack_only_undead"] = {
	hostilePreference = "IsoZombie",
	crew = {"EHEMilitaryPilot", "EHESoldier", 75, "EHESoldier", 50},
	formationIDs = {"air_raid", "attack_only_undead", 25, {12,17}, "attack_only_undead", 10, {12,17}},
	}


eHelicopter_PRESETS["attack_only_all"] = {
	hostilePreference = "IsoGameCharacter",
	crashType = {"UH1HSurvivalistFuselage"},
	crew = {"EHESurvivalistPilot", "EHESurvivalist", 75, "EHESurvivalist", 50},
	scrapAndParts = {"UH1HSurvivalistTail"},
	formationIDs = {"air_raid"},
	}


eHelicopter_PRESETS["police_heli"] = {
	attackDelay = 1100,
	attackSpread = 4,
	speed = 0.08,
	attackHitChance = 100,
	attackDamage = 35,
	crashType = {"Bell206PoliceFuselage"},
	crew = {"EHEPolicePilot", "EHEPoliceOfficer", "EHEPoliceOfficer", 75},
	hostilePreference = "IsoZombie",
	eventSoundEffects = {
		["attackSingle"] = "eHeli_bolt_action_fire_single",
		["attackLooped"] = "eHeli_bolt_action_fire_single",
		["additionalFlightSound"] = "eHeliPoliceSiren",
		["flightSound"] = "eHelicopter",
		},
	hoverOnTargetDuration = {750,1150},
	scrapAndParts = {"Bell206PoliceTail", "EHE.Bell206RotorBlade", 4},
	announcerVoice = "Police",
	}


eHelicopter_PRESETS["aid_helicopter"] = {
	crashType = {"UH1HMedevacFuselage"},
	hoverOnTargetDuration = 500,
	crew = {"EHEMilitaryPilot", "EHESoldier", 100, "EHESoldier", 100},
	dropPackages = {"FEMASupplyDrop"},
	dropItems = {["EHE.NoticeFlyer"]=250},
	speed = 0.09,
	scrapAndParts = {"UH1HMedevacTail"},
	eventSoundEffects = {
		["foundTarget"] = "eHeli_AidDrop_2",
		["droppingPackage"] = "eHeli_AidDrop_1and3",
		},
	formationIDs = {"patrol_only", 25, {12,17}, "patrol_only", 10, {12,17}},
	}


eHelicopter_PRESETS["aid_survivor"] = {
	crashType = false,
	crew = {"EHECivilianPilot",},
	dropPackages = {"FEMASupplyDrop"},
	speed = 0.07,
	eventSoundEffects = {["flightSound"] = "ePropPlane"},
	cutOffFactor = 3,
}