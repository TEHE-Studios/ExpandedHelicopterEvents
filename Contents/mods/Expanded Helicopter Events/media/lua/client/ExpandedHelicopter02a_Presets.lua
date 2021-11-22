---Preset list, only include variables being changed.
---variables can be found in Main Variables file, at the top, fields = variables
eHelicopter_PRESETS = eHelicopter_PRESETS or {}

--[[
eHelicopter_PRESETS["id_name"] = {
		variable = {values}
	}
]]

--- forScheduling string used for scheduler; leaving it as nil means the event will not spawn from the scheduler
--- schedulingFactor number multiplied against frequency to make them more or less likely - high number = more likely to be scheduled
--- eventSpawnWeight number This number is how many times this event is included in the scheduler's pool of events
--- eventStartDayFactor number This is number is multiplied against cutOffDay to act as when it will be able to spawn.
--- eventCutOffDayFactor number This is multiplied against cutOffDay to act as the day this event no longer spawns


eHelicopter_PRESETS["military"] = {
	presetRandomSelection = {"increasingly_hostile",3,"increasingly_helpful",1},
	announcerVoice = true,
	crew = {"EHEMilitaryPilot", "EHESoldier", 75, "EHESoldier", 50},
	forScheduling = true,
	eventSpawnWeight = 20,
	schedulingFactor = 1.5,
	}


eHelicopter_PRESETS["increasingly_hostile"] = {
	presetProgression = {
		["patrol_only"] = 0,
		["patrol_only_emergency"] = 0.0066,
		["patrol_only_quarantine"] = 0.0165,
		["attack_only_undead_evac"] = 0.033,
		["attack_only_undead"] = 0.066,
		["attack_only_all"] = 0.2145,
		}
	}


eHelicopter_PRESETS["increasingly_helpful"] = {
	presetProgression = {
		["patrol_only"] = 0,
		["patrol_only_emergency"] = 0.0066,
		["patrol_only_quarantine"] = 0.0165,
		["attack_only_undead_evac"] = 0.033,
		["aid_helicopter"] = 0.066,
		["attack_only_all"] = 0.2145,
		}
	}


eHelicopter_PRESETS["patrol_only"] = {
	inherit = {"military"},
}

-- EmergencyFlyer QuarantineFlyer EvacuationFlyer NoticeFlyer PreventionFlyer
eHelicopter_PRESETS["patrol_only_emergency"] = {
	inherit = {"military"},
	dropItems = {["EHE.EmergencyFlyer"]=250},
	announcerVoice = "FlyerChoppers",
	formationIDs = {"patrol_only_emergency", 25, {20,25}, "patrol_only_emergency", 10, {20,25}},
}

eHelicopter_PRESETS["patrol_only_quarantine"] = {
	inherit = {"military"},
	dropItems = {["EHE.QuarantineFlyer"]=250},
	announcerVoice = "FlyerChoppers",
	formationIDs = {"patrol_only_quarantine", 25, {20,25}, "patrol_only_quarantine", 10, {20,25}},
}

eHelicopter_PRESETS["attack_only_undead_evac"] = {
	announcerVoice = false,
	inherit = {"military"},
	hostilePreference = "IsoZombie",
	dropItems = {["EHE.EvacuationFlyer"]=250},
	formationIDs = {"air_raid", "attack_only_undead_evac", 25, {20,25}, "attack_only_undead_evac", 10, {20,25}},
}

eHelicopter_PRESETS["attack_only_undead"] = {
	inherit = {"military"},
	announcerVoice = false,
	hostilePreference = "IsoZombie",
	formationIDs = {"air_raid", "attack_only_undead", 25, {12,17}, "attack_only_undead", 10, {12,17}},
}

eHelicopter_PRESETS["aid_helicopter"] = {
	inherit = {"military"},
	announcerVoice = false,
	crashType = {"UH1HMedevacFuselage"},
	hoverOnTargetDuration = 500,
	dropPackages = {"FEMASupplyDrop"},
	dropItems = {["EHE.NoticeFlyer"]=250},
	speed = 0.09,
	scrapItems = {"EHE.UH1HHalfSkirt", "EHE.UH1HRotorBlade", 2, "EHE.Bell206TailBlade", 2, "Base.ScrapMetal", 10},
	scrapVehicles = {"UH1HMedevacTail"},
	eventSoundEffects = {
		["foundTarget"] = "eHeli_AidDrop_2",
		["droppingPackage"] = "eHeli_AidDrop_1and3",
	},
	formationIDs = {"patrol_only", 25, {12,17}, "patrol_only", 10, {12,17}},
}

eHelicopter_PRESETS["attack_only_all"] = {
	inherit = {"military"},
	announcerVoice = false,
	hostilePreference = "IsoGameCharacter",
	scrapItems = {"EHE.UH1HHalfSkirt", "EHE.UH1HRotorBlade", 2, "EHE.Bell206TailBlade", 2, "Base.ScrapMetal", 10},
	scrapVehicles = {"UH1HTail"},
	formationIDs = {"air_raid"},
}



eHelicopter_PRESETS["jet"] = {
	speed = 2.8,
	topSpeedFactor = 2,
	flightVolume = 25,
	eventSoundEffects = {["flightSound"] = "eJetFlight"},
	crashType = false,
	shadow = false,
	eventMarkerIcon = "media/ui/jet.png",
	forScheduling = true,
	schedulingFactor = 4,
	eventSpawnWeight = 5,
	}

eHelicopter_PRESETS["air_raid"] = {
	doNotListForTwitchIntegration = true,
	crashType = false,
	shadow = false,
	speed = 0.05,
	eventSoundEffects = {["soundAtEventOrigin"] = "eAirRaid"},
	eventMarkerIcon = false,
	forScheduling = true,
	flightHours = {11, 11},
	eventSpawnWeight = 50,
	schedulingFactor = 99999,
	eventStartDayFactor = 0.067,
	eventCutOffDayFactor = 0.067,
}

eHelicopter_PRESETS["jet_bombing"] = {
	doNotListForTwitchIntegration = true,
	speed = 2.8,
	topSpeedFactor = 2,
	flightVolume = 25,
	eventSoundEffects = {["flightSound"] = "eJetFlight", ["soundAtEventOrigin"] = "eCarpetBomb"},
	crashType = false,
	shadow = false,
	eventMarkerIcon = "media/ui/jet.png",
	forScheduling = true,
	flightHours = {12, 12},
	eventSpawnWeight = 50,
	schedulingFactor = 99999,
	eventStartDayFactor = 0.067,
	eventCutOffDayFactor = 0.067,
}


eHelicopter_PRESETS["news_chopper"] = {
	presetRandomSelection = {"news_chopper_hover", 1, "news_chopper_fleeing", 2, },
	eventSoundEffects = { ["hoverOverTarget"] = "eHeli_newscaster", ["flightSound"] = "eHelicopter", },
	speed = 0.10,
	crew = {"EHECivilianPilot", "EHENewsReporterVest", "EHENewsReporterVest", 40},
	crashType = {"Bell206LBMWFuselage"},
	scrapItems = {"Bell206LBMWTail", "EHE.Bell206HalfSkirt", "EHE.Bell206RotorBlade", 2, "EHE.Bell206TailBlade", 2, "Base.ScrapMetal", 10},
	scrapVehicles = {"Bell206LBMWTail"},
	forScheduling = true,
	eventStartDayFactor = 0.067,
	eventCutOffDayFactor = 0.22,
	}

eHelicopter_PRESETS["news_chopper_hover"] = {
	inherit = {"news_chopper"},
	hoverOnTargetDuration = {1500,2400},
	}

eHelicopter_PRESETS["news_chopper_fleeing"] = {
	inherit = {"news_chopper"},
	speed = 0.16,
	}



eHelicopter_PRESETS["police"] = {
	presetRandomSelection = {"police_heli_emergency",3, "police_heli_firing",2},
	crashType = {"Bell206PoliceFuselage"},
	crew = {"EHEPolicePilot", "EHEPoliceOfficer", "EHEPoliceOfficer", 75},
	scrapItems = {"Bell206PoliceTail", "EHE.Bell206HalfSkirt", "EHE.Bell206RotorBlade", 2, "EHE.Bell206TailBlade", 2, "Base.ScrapMetal", 10},
	scrapVehicles = {"Bell206PoliceTail"},
	announcerVoice = "Police",
	forScheduling = true,
	eventStartDayFactor = 0.067,
	eventCutOffDayFactor = 0.22,
	}

eHelicopter_PRESETS["police_heli_emergency"] = {
	inherit = {"police"},
	speed = 0.15,
	eventSoundEffects = {
		["additionalFlightSound"] = "eHeliPoliceEmergencyWarning",
		["flightSound"] = "eHelicopter",
		},

	}

eHelicopter_PRESETS["police_heli_firing"] = {
	inherit = {"police"},
	attackDelay = 1700,
	attackSpread = 4,
	speed = 0.10,
	attackHitChance = 95,
	attackDamage = 12,
	hostilePreference = "IsoZombie",
	eventSoundEffects = {
		["attackSingle"] = "eHeliM16GunfireSingle",
		["attackLooped"] = "eHeliM16GunfireSingle",
		["additionalFlightSound"] = "eHeliPoliceSiren",
		["flightSound"] = "eHelicopter",
		},
	hoverOnTargetDuration = {750,1150},
	}



eHelicopter_PRESETS["samaritan_drop"] = {
	crashType = false,
	crew = {"EHESurvivorPilot", 100, 0},
	dropPackages = {"SurvivorSupplyDrop"},
	speed = 0.10,
	eventSoundEffects = {["flightSound"] = "ePropPlane"},
	forScheduling = true,
	eventCutOffDayFactor = 1,
	eventStartDayFactor = 0.66,
	eventSpawnWeight = 3,
}


eHelicopter_PRESETS["survivor_heli"] = {
	speed = 0.15,
	crashType = {"Bell206SurvivalistFuselage"},
	crew = {"EHESurvivorPilot", 100, 0, "EHESurvivor", 100, 0, "EHESurvivor", 75, 0},
	eventSoundEffects = {
		["flightSound"] = "eHelicopter",
	},
	scrapItems = {"Bell206PoliceTail", "EHE.Bell206HalfSkirt", "EHE.Bell206RotorBlade", 2, "EHE.Bell206TailBlade", 2, "Base.ScrapMetal", 10},
	scrapVehicles = {"Bell206SurvivalistTail"},
	forScheduling = true,
	eventCutOffDayFactor = 1,
	eventStartDayFactor = 0.66,
}



eHelicopter_PRESETS["raiders"] = {
	presetRandomSelection = {"raider_heli_passive",3,"raider_heli_aggressive",1},
	speed = 0.20,
	crashType = {"UH1HRaiderFuselage"},
	scrapItems = {"EHE.UH1HHalfSkirt", "EHE.Bell206RotorBlade", 2, "EHE.Bell206TailBlade", 2, "Base.ScrapMetal", 10,},
	scrapVehicles = {"UH1HRaiderTail"},
	addedFunctionsToEvents = {["OnFlyaway"] = eHelicopter_dropTrash},
	crew = {"EHERaiderPilot", 100, 0, "EHERaider", 100, 0, "EHERaider", 100, 0, "EHERaider", 100, 0, "EHERaiderLeader", 75, 0},
	forScheduling = true,
	eventCutOffDayFactor = 1,
	eventStartDayFactor = 0.66,
	}

eHelicopter_PRESETS["raider_heli_passive"] = {
	inherit = {"raiders"},
	eventSoundEffects = {
		["flightSound"] = "eMiliHeli",
	},
}

eHelicopter_PRESETS["raider_heli_aggressive"] = {
	inherit = {"raiders"},
	hoverOnTargetDuration = {2500,3000},
	attackDelay = 1700,
	attackSpread = 4,
	attackHitChance = 55,
	attackDamage = 10,
	hostilePreference = "IsoZombie",
	eventSoundEffects = {
		["flightSound"] = "eMiliHeli",
		["attackSingle"] = "eHeliM16GunfireSingle",
		["attackLooped"] = "eHeliM16GunfireSingle",
		["additionalFlightSound"] = "eHeliMusicAggressive",
	},
}
