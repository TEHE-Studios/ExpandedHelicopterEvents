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
	eHeliEvents_init["civilian"] = {["ID"]=nil, ["heliDay"]=startDay+ZombRand(6,9), ["heliStart"]=nil}
	eHeliEvents_init["military"] = {["ID"]=nil, ["heliDay"]=startDay+ZombRand(0,3), ["heliStart"]=nil}
	eHeliEvents_init["aid_survivor"] = {["ID"]=nil, ["heliDay"]=startDay+math.floor(cutOffDay*(ZombRand(15,21)/10)), ["heliStart"]=nil}
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
	doNotListForTwitchIntegration = true,
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
	scrapAndParts = {"Bell206LBMWTail", "EHE.Bell206HalfSkirt", "EHE.Bell206RotorBlade", 2, "EHE.Bell206TailBlade", 2, "Base.ScrapMetal", 10},
	crew = {"EHECivilianPilot", "EHENewsReporterArmored", "EHENewsReporterArmored", 40},
	}


eHelicopter_PRESETS["patrol_only"] = {
	announcerVoice = true,
	crew = {"EHEMilitaryPilot", "EHESoldier", 75, "EHESoldier", 50},
	}


-- EmergencyFlyer QuarantineFlyer EvacuationFlyer NoticeFlyer PreventionFlyer
eHelicopter_PRESETS["patrol_only_emergency"] = {
	announcerVoice = true,
	dropItems = {["EHE.EmergencyFlyer"]=250},
	crew = {"EHEMilitaryPilot", "EHESoldier", 75, "EHESoldier", 50},
	formationIDs = {"patrol_only_emergency", 25, {20,25}, "patrol_only_emergency", 10, {20,25}},
	}


eHelicopter_PRESETS["patrol_only_quarantine"] = {
	announcerVoice = true,
	dropItems = {["EHE.QuarantineFlyer"]=250},
	crew = {"EHEMilitaryPilot", "EHESoldier", 75, "EHESoldier", 50},
	formationIDs = {"patrol_only_quarantine", 25, {20,25}, "patrol_only_quarantine", 10, {20,25}},
	}


eHelicopter_PRESETS["air_raid"] = {
	doNotListForTwitchIntegration = true,
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
	crashType = {"UH1HFuselage"},
	crew = {"EHEMilitaryPilot", "EHESoldier", 75, "EHESoldier", 50},
	scrapAndParts = {"UH1HTail", "EHE.UH1HHalfSkirt", "EHE.UH1HRotorBlade", 2, "EHE.Bell206TailBlade", 2, "Base.ScrapMetal", 10},
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
	scrapAndParts = {"Bell206PoliceTail", "EHE.Bell206HalfSkirt", "EHE.Bell206RotorBlade", 2, "EHE.Bell206TailBlade", 2, "Base.ScrapMetal", 10},
	announcerVoice = "Police",
	}


eHelicopter_PRESETS["aid_helicopter"] = {
	crashType = {"UH1HMedevacFuselage"},
	hoverOnTargetDuration = 500,
	crew = {"EHEMilitaryPilot", "EHESoldier", "EHESoldier"},
	dropPackages = {"FEMASupplyDrop"},
	dropItems = {["EHE.NoticeFlyer"]=250},
	speed = 0.09,
	scrapAndParts = {"UH1HMedevacTail", "EHE.UH1HHalfSkirt", "EHE.UH1HRotorBlade", 2, "EHE.Bell206TailBlade", 2, "Base.ScrapMetal", 10},
	eventSoundEffects = {
		["foundTarget"] = "eHeli_AidDrop_2",
		["droppingPackage"] = "eHeli_AidDrop_1and3",
		},
	formationIDs = {"patrol_only", 25, {12,17}, "patrol_only", 10, {12,17}},
	}


eHelicopter_PRESETS["aid_survivor"] = {
	presetRandomSelection = {"survivor_plane",2,"survivor_heli",1}
}


eHelicopter_PRESETS["survivor_plane"] = {
	crashType = false,
	crew = {"EHESurvivorPilot", 100, 0},
	dropPackages = {"SurvivorSupplyDrop"},
	speed = 0.07,
	eventSoundEffects = {["flightSound"] = "ePropPlane"},
	cutOffFactor = 3,
	frequencyFactor = 1.33,
}


eHelicopter_PRESETS["survivor_heli"] = {
	speed = 0.15,
	crashType = {"Bell206SurvivalistFuselage"},
	crew = {"EHESurvivorPilot", 100, 0, "EHESurvivor", 100, 0, "EHESurvivor", 75, 0},
	hostilePreference = "IsoZombie",
	eventSoundEffects = {
		["flightSound"] = "eHelicopter",
	},
	scrapAndParts = {"Bell206SurvivalistTail", "EHE.Bell206HalfSkirt", "EHE.Bell206RotorBlade", 2, "EHE.Bell206TailBlade", 2, "Base.ScrapMetal", 10},
	cutOffFactor = 3,
	frequencyFactor = 1.33,
}


eHelicopter_PRESETS["raiders"] = {
	presetRandomSelection = {"raider_heli_passive",3,"raider_heli_aggressive",1}
	}

eHelicopter_PRESETS["raider_heli_passive"] = {
	speed = 0.20,
	crashType = {"UH1HRaiderFuselage"},
	crew = {"EHERaiderPilot", 100, 0, "EHERaider", 100, 0, "EHERaider", 100, 0, "EHERaider", 100, 0, "EHERaiderLeader", 75, 0},
	eventSoundEffects = {
		["flightSound"] = "eMiliHeli",
		["additionalFlightSound"] = "eHeliMusicPassive",
	},
	scrapAndParts = {"UH1HRaiderTail", "EHE.UH1HHalfSkirt", "EHE.Bell206RotorBlade", 2, "EHE.Bell206TailBlade", 2, "Base.ScrapMetal", 10,},
	cutOffFactor = 3,
	frequencyFactor = 1.33,
}

eHelicopter_PRESETS["raider_heli_aggressive"] = {
	speed = 0.20,
	hoverOnTargetDuration = {2500,3000},
	attackDelay = 830,
	attackSpread = 4,
	attackHitChance = 55,
	attackDamage = 75,
	dropItems = {["EHE.EvacuationFlyer"]=250},
	crashType = {"UH1HFuselage"},
	crew = {"EHERaiderPilot", 100, 0, "EHERaider", 100, 0, "EHERaider", 100, 0, "EHERaider", 100, 0, "EHERaiderLeader", 75, 0},
	hostilePreference = "IsoZombie",
	eventSoundEffects = {
		["flightSound"] = "eMiliHeli",
		["attackSingle"] = "eHeli_bolt_action_fire_single",
		["attackLooped"] = "eHeli_bolt_action_fire_single",
		["additionalFlightSound"] = "eHeliMusicAggressive",
	},
	scrapAndParts = {"UH1HRaiderTail", "EHE.UH1HHalfSkirt", "EHE.Bell206RotorBlade", 2, "EHE.Bell206TailBlade", 2, "Base.ScrapMetal", 10,},
	cutOffFactor = 3,
	frequencyFactor = 1.33,
}