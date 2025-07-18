eHelicopter_PRESETS = eHelicopter_PRESETS or {}

local subEvents = require("EHE_presetSubEvents.lua")

eHelicopter_PRESETS["military"] = {
	announcerVoice = true,
	forScheduling = true,
	crew = {
		{ outfit="EHE_HelicopterPilot" },
		{ outfit="EHE_Soldier", spawn=75 },
		{ outfit="EHE_Soldier", spawn=50 },
	},
	crashType = {"UH60GreenFuselage"},
	scrapItems = {"EHE.UH1HHalfSkirt2", 2, "EHE.UH60Elevator", 1, "EHE.UH60WindowGreen", 1, "EHE.UH60DoorGreen", 1, "Base.ScrapMetal", 5},
	scrapVehicles = {"UH60GreenTail"},
	eventSpawnWeight = 20,
	schedulingFactor = 1.5,
	markerColor = {r=0.37, g=1.00, b=0.27},
	radioChatter = "AEBS_Military",
	presetProgression = {
		["military_RQ2Pioneer_earlyflyover"] = 0,
		["military_UH1H_patrol"] = 0,
		["military_UH1H_patrol_emergency"] = 0.0066,
		["military_RQ2Pioneer_loiter"] = 0.0070,
		["military_OH58A_recon_hover"] = 0.0070,
		["military_UH1H_patrol_quarantine"] = 0.0165,
		["military_UH1H_attack_undead_evac"] = 0.033,
		["military_UH1H_attack_undead"] = 0.066,
		["military_RQ2Pioneer_lateflyover"] = 0.070,
		["military_OH58D_attack_zombies"] = 0.077,
		["military_CH47"] = 0.1900,
		["military_UH1H_attack_all"] = 0.2145,
	}
}

eHelicopter_PRESETS["military_RQ2Pioneer_earlyflyover"] = {
	speed = 1.0,
	shadow = false,
	flightVolume = 10,
	eventSoundEffects = {
		["flightSound"] = "ePioneerDrone"
	},
	eventMarkerIcon = "media/ui/plane.png",
	forScheduling = true,
	crashType = false,
}

eHelicopter_PRESETS["military_RQ2Pioneer_loiter"] = {
	speed = 0.5,
	shadow = false,
	flightVolume = 25,
	eventSoundEffects = {
		["flightSound"] = "ePioneerDrone"
	},
	eventMarkerIcon = "media/ui/plane.png",
	hoverOnTargetDuration = {1000,1500},
	forScheduling = true,
	crashType = false,
}

-- add in drone crash
eHelicopter_PRESETS["military_RQ2Pioneer_lateflyover"] = {
	speed = 1.0,
	shadow = false,
	flightVolume = 25,
	eventSoundEffects = {
		["flightSound"] = "ePioneerDrone"
	},
	eventMarkerIcon = "media/ui/plane.png",
	forScheduling = true,
	crashType = false,
}

eHelicopter_PRESETS["military_UH1H_patrol"] = {
	inherit = {"military"},
}

-- EmergencyFlyer QuarantineFlyer EvacuationFlyer NoticeFlyer PreventionFlyer
eHelicopter_PRESETS["military_UH1H_patrol_emergency"] = {
	inherit = {"military"},
	dropItems = {["EHE.EmergencyFlyer"]=250},
	announcerVoice = "FlyerChoppers",
	formationIDs = {"military_UH1H_patrol_emergency", 25, {20,25}, "military_UH1H_patrol_emergency", 10, {20,25}},
}

eHelicopter_PRESETS["military_OH58A_recon_hover"] = {
	inherit = {"military"},
	announcerVoice = false,
	speed = 1.5,
	crashType = false,
	hoverOnTargetDuration = {200,400},
}

eHelicopter_PRESETS["military_UH1H_patrol_quarantine"] = {
	inherit = {"military"},
	dropItems = {["EHE.QuarantineFlyer"]=250},
	announcerVoice = "FlyerChoppers",
	formationIDs = {"military_UH1H_patrol_quarantine", 25, {20,25}, "military_UH1H_patrol_quarantine", 10, {20,25}},
}

eHelicopter_PRESETS["military_UH1H_attack_undead_evac"] = {
	announcerVoice = false,
	inherit = {"military"},
	hostilePreference = "IsoZombie",
	radioChatter = "AEBS_PurgeMilitary",
	dropItems = {["EHE.EvacuationFlyer"]=250},
	formationIDs = {"military_UH1H_attack_undead_evac", 25, {20,25}, "military_UH1H_attack_undead_evac", 10, {20,25}},
}

eHelicopter_PRESETS["military_UH1H_attack_undead"] = {
	inherit = {"military"},
	announcerVoice = false,
	hostilePreference = "IsoZombie",
	radioChatter = "AEBS_PurgeMilitary",
	formationIDs = {"military_UH1H_attack_undead", 25, {12,17}, "military_UH1H_attack_undead", 10, {12,17}},
}

eHelicopter_PRESETS["military_CH47"] = {
	inherit = {"military"},
	announcerVoice = false,
	crashType = false,
	crashType = {"UH60GreenFuselage"},
	scrapItems = {"EHE.UH1HHalfSkirt2", 2, "EHE.UH60Elevator", 1, "EHE.UH60WindowGreen", 1, "EHE.UH60DoorGreen", 1, "Base.ScrapMetal", 10},
	eventSoundEffects = {
		["flightSound"] = "eMiliHeliCargo",
	},
}

eHelicopter_PRESETS["military_OH58D_attack_zombies"] = {
	inherit = {"military"},
	announcerVoice = false,
	crashType = false,
	speed = 0.3,
	attackDelay = 44,
	attackSpread = 5,
	attackSplash = 2,
	attackHitChance = 70,
	attackDamage = 100,
	eventSoundEffects = {
		["attackSingle"] = "eHeli30mmCannon",
		["attackLooped"] = "eHeli30mmCannon",
		["flightSound"] = { "eMiliHeli"},
	},
	hostilePreference = "IsoZombie",
	radioChatter = "AEBS_PurgeMilitary",
	formationIDs = {"military_UH1H_attack_undead", 25, {12,17}, "military_UH1H_attack_undead", 10, {12,17}},
}

eHelicopter_PRESETS["military_UH1H_attack_all"] = {
	inherit = {"military"},
	announcerVoice = false,
	markerColor = {r=1.00, g=0.28, b=0.28},
	hostilePreference = "IsoGameCharacter",
	hostilePredicate = subEvents.hostilePredicateCivilian,
	crashType = {"UH60GreenFuselage"},
	scrapItems = {"EHE.UH1HHalfSkirt2", 2, "EHE.UH60Elevator", 1, "EHE.UH60WindowGreen", 1, "EHE.UH60DoorGreen", 1, "Base.ScrapMetal", 10},
	scrapVehicles = {"UH60GreenTail"},
	radioChatter = "AEBS_HostileMilitary",
}

eHelicopter_PRESETS["jet"] = {
	speed = 15,
	topSpeedFactor = 2,
	flightVolume = 25,
	targetIntensityThreshold = false,
	eventSoundEffects = {
		["flightSound"] = "eJetFlight"
	},
	crashType = false,
	shadow = false,
	eventMarkerIcon = "media/ui/jet.png",
	forScheduling = true,
	schedulingFactor = 4,
	eventSpawnWeight = 5,
	radioChatter = "AEBS_JetPass",
}

eHelicopter_PRESETS["air_raid"] = {
	doNotListForStreamerIntegration = true,
	crashType = false,
	shadow = false,
	speed = 0.65,
	targetIntensityThreshold = false,
	topSpeedFactor = 3,
	flightVolume = 0,
	looperEventIDs = {
		["soundAtEventOrigin"]=true
	},
	eventSoundEffects = {
		["flightSound"]="IGNORE",
		["soundAtEventOrigin"] = "eAirRaid",
	},
	eventMarkerIcon = false,
	forScheduling = true,
	flightHours = {11, 11},
	eventSpawnWeight = 50,
	schedulingFactor = 99999,
	eventStartDayFactor = 0.067,
	eventCutOffDayFactor = 0.067,
	ignoreContinueScheduling = true,
	radioChatter = "AEBS_AirRaid",
}

eHelicopter_PRESETS["jet_bombing"] = {
	inherit = {"jet"},
	doNotListForStreamerIntegration = true,
	addedFunctionsToEvents = {["OnLaunch"] = subEvents.eHelicopter_jetBombing},

	eventSoundEffects = {
		["flightSound"] = "eJetFlight",
		["soundAtEventOrigin"] = "eCarpetBomb",
	},

	flightHours = {12, 12},
	eventSpawnWeight = 50,
	schedulingFactor = 99999,
	eventStartDayFactor = 0.067,
	eventCutOffDayFactor = 0.067,
	ignoreContinueScheduling = true,
	radioChatter = "AEBS_JetBombing",
}

eHelicopter_PRESETS["news_Bell206"] = {
	presetRandomSelection = {"news_Bell206_hover", 1, "news_Bell206_fleeing", 2, },
	eventSoundEffects = {
		["flightSound"] = { "eHelicopter", "eHeli_newscaster" },
	},
	speed = 1,
	crew = {
		{ outfit="EHECivilianPilot", },
		{ outfit="EHENewsReporterVest", },
		{ outfit="EHENewsReporterVest", spawn = 40 },
	},
	crashType = {"Bell206LBMWFuselage"},
	scrapItems = {"EHE.Bell206HalfSkirt", "EHE.Bell206RotorBlade1", 2, "EHE.Bell206RotorBlade2", 2,  "EHE.Bell206TailBlade", 2, "Base.ScrapMetal", 10},
	scrapVehicles = {"Bell206LBMWTail"},
	forScheduling = true,
	markerColor = {r=1.00, g=0.85, b=0.20},
	eventStartDayFactor = 0.067,
	eventCutOffDayFactor = 0.22,
	radioChatter = "AEBS_UnauthorizedEntryNews",
}

eHelicopter_PRESETS["news_Bell206_hover"] = {
	inherit = {"news_Bell206"},
	hoverOnTargetDuration = {750,1200},
}

eHelicopter_PRESETS["news_Bell206_fleeing"] = {
	inherit = {"news_Bell206"},
	speed = 1.6,
}

eHelicopter_PRESETS["police"] = {
	presetRandomSelection = {"police_Bell206_KY_emergency",3, "police_Bell206_KY_hovering",2, "police_Bell206_KY_firing",2, "police_Bell206_KY_fleeing",2, "police_Bell206_TN_fleeing",2, "police_Bell206_OH_fleeing",2},
	crashType = {"Bell206PoliceFuselage"},
	crew = {
		{ outfit="EHEPolicePilot" },
		{ outfit="EHEPoliceOfficer" },
		{ outfit="EHEPoliceOfficer", spawn=75 },
	},
	scrapItems = {"EHE.Bell206HalfSkirt", "EHE.Bell206RotorBlade1", 2, "EHE.Bell206RotorBlade2", 2,  "EHE.Bell206TailBlade", 2, "Base.ScrapMetal", 10},
	scrapVehicles = {"Bell206PoliceTail"},
	announcerVoice = "Police",
	eventSoundEffects = {
		["foundTarget"] = "eHeli_PoliceSpotted",
	},
	forScheduling = true,
	markerColor = {r=0.28, g=0.28, b=1.00},
	eventStartDayFactor = 0.067,
	eventCutOffDayFactor = 0.22,
	radioChatter = "AEBS_UnauthorizedEntryPolice",
}

eHelicopter_PRESETS["police_Bell206_KY_emergency"] = {
	inherit = {"police"},
	speed = 1.5,
	eventSoundEffects = {
		["flightSound"] = { "eHelicopter", "eHeliPoliceSiren" },
	},
}

eHelicopter_PRESETS["police_Bell206_KY_firing"] = {
	inherit = {"police"},
	attackDelay = 1700,
	attackSpread = 4,
	speed = 0.7,
	attackHitChance = 95,
	attackDamage = 80,
	hostilePreference = "IsoZombie",
	eventSoundEffects = {
		["attackSingle"] = "eHeliAlternatingShots",
		["attackLooped"] = "eHeliAlternatingShots",
		["flightSound"] = { "eHelicopter", "eHeliPoliceWarning" },
	},
	hoverOnTargetDuration = {375,575},
}

eHelicopter_PRESETS["police_Bell206_KY_hovering"] = {
	inherit = {"police"},
	speed = 1.5,
	eventSoundEffects = {
		["flightSound"] = "eHelicopter",
	},
	hoverOnTargetDuration = {800,1000},
}

eHelicopter_PRESETS["police_Bell206_KY_fleeing"] = {
	inherit = {"police"},
	speed = 1.5,
	eventSoundEffects = {
		["flightSound"] = "eHelicopter",
	},
}

eHelicopter_PRESETS["police_Bell206_TN_fleeing"] = {
	inherit = {"police"},
	speed = 1.5,
	eventSoundEffects = {
		["flightSound"] = "eHelicopter",
	},
}

eHelicopter_PRESETS["police_Bell206_OH_fleeing"] = {
	inherit = {"police"},
	speed = 1.5,
	eventSoundEffects = {
		["flightSound"] = "eHelicopter",
	},
}

eHelicopter_PRESETS["survivor_Cessna172"] = {
	crashType = false,
	crew = {
		{ outfit="EHE_SurvivorPilot", female=0 },
	},
	speed = 0.7,
	eventMarkerIcon = "media/ui/plane.png",
	eventSoundEffects = {
		["flightSound"] = "eSmallPropPlane",
	},
	forScheduling = true,
	markerColor = {r=0.37, g=1.00, b=0.27},
	eventCutOffDayFactor = 1,
	eventStartDayFactor = 0.48,
	eventSpawnWeight = 3,
}

eHelicopter_PRESETS["survivor_bell206"] = {
	speed = 2.0,
	crashType = {"Bell206SurvivalistFuselage"},
	crew = {
		{ outfit="EHE_SurvivorPilot", 0 },
		{ outfit="EHE_Survivor", 0 },
		{ outfit="EHE_Survivor", spawn=75, female=0 },
	},
	eventSoundEffects = {
		["flightSound"] = "eHelicopter",
	},
	scrapItems = {"EHE.Bell206HalfSkirt", "EHE.Bell206RotorBlade1", 2, "EHE.Bell206RotorBlade2", 2,  "EHE.Bell206TailBlade", 2, "Base.ScrapMetal", 10},
	scrapVehicles = {"Bell206SurvivalistTail"},
	forScheduling = true,
	crashType = false,
	eventCutOffDayFactor = 1,
	eventStartDayFactor = 0.48,
	radioChatter = "AEBS_SurvivorHeli",
}
-- add cessna model
eHelicopter_PRESETS["strangers"] = {
	presetRandomSelection = {"strangers_flyover_search",3, "strangers_flyover_drop",1,},
	crashType = {"UH60GreenFuselage"},
	scrapItems = {"EHE.UH1HHalfSkirt2", 2, "EHE.UH60Elevator", 1, "EHE.UH60WindowGreen", 1, "EHE.UH60DoorGreen", 1, "Base.ScrapMetal", 10},
	scrapVehicles = {"UH60GreenTail"},
	addedFunctionsToEvents = {["OnFlyaway"] = subEvents.eHelicopter_dropTrash},
	crew = {
		{ outfit = "EHE_StrangerPilot", female = 0 },
		{ outfit = "EHE_Stranger", female = 0 },
		{ outfit = "EHE_Stranger", female = 0 },
	},
	forScheduling = true,
    markerColor = {r=0.813, g=0.813, b=0.813}
	eventCutOffDayFactor = 1,
	eventStartDayFactor = 0.48,
}

eHelicopter_PRESETS["strangers_flyover_search"] = {
	inherit = {"strangers"},
	crashType = false,
	crew = {
		{ outfit="EHE_SurvivorPilot", female = 0 }
	},
	dropPackages = {"SurvivorSupplyDrop"},
	speed = 1.0,
	eventMarkerIcon = "media/ui/plane.png",
	eventSoundEffects = {
		["flightSound"] = "eSmallPropPlane",
	},
	forScheduling = true,
	radioChatter = "AEBS_StrangersSearch",
}

eHelicopter_PRESETS["strangers_flyover_drop"] = {
	inherit = {"strangers"},
	crashType = false,
	crew = {
		{ outfit="EHE_SurvivorPilot", female = 0 }
	},
	speed = 0.3,
	eventMarkerIcon = "media/ui/plane.png",
	eventSoundEffects = {
		["flightSound"] = "eSmallPropPlane",
	},
	forScheduling = true,
	radioChatter = "AEBS_StrangersDrop",
}

eHelicopter_PRESETS["deserters"] = {
	presetRandomSelection = {"deserters_UH1H_passive",3,"deserters_UH1H_hostile",2,"deserters_UH1H_scoutingparty",3,"deserters_UH1H_diversion",4,},
	crashType = {"UH60GreenFuselage"},
	scrapItems = {"EHE.UH1HHalfSkirt2", 2, "EHE.UH60Elevator", 1, "EHE.UH60WindowGreen", 1, "EHE.UH60DoorGreen", 1, "Base.ScrapMetal", 10},
	scrapVehicles = {"UH60GreenTail"},
	addedFunctionsToEvents = {["OnFlyaway"] = subEvents.eHelicopter_dropTrash},
	crew = {
		{ outfit = "EHE_DeserterPilot", female = 0 },
		{ outfit = "EHE_Deserter", female = 0 },
		{ outfit = "EHE_Deserter", female = 0 },
		{ outfit = "EHE_Deserter", female = 0 },
		{ outfit = "EHE_DeserterLeader", spawn = 75, female = 0 },
	},
	forScheduling = true,
	markerColor = {r=1.00, g=0.48, b=0.27},
	eventCutOffDayFactor = 1,
	eventStartDayFactor = 0.48,
	radioChatter = "AEBS_deserters",
}

eHelicopter_PRESETS["deserters_UH1H_scoutingparty"] = {
	inherit = {"deserters"},
	speed = 1.5,
	flightVolume = 1500,
	crashType = false,
	eventSoundEffects = {
		["flightSound"] = { "eMiliHeli" },
	},

	addedFunctionsToEvents = {["OnApproach"] = eHelicopter_spawnNPCs},
}

eHelicopter_PRESETS["deserters_UH1H_passive"] = {
	inherit = {"deserters"},
	speed = 1.5,
	flightVolume = 1500,
	crashType = false,
	eventSoundEffects = {
		["flightSound"] = { "eMiliHeli", "eHeliMusicPassive"},
	},
}

eHelicopter_PRESETS["deserters_UH1H_raidingparty"] = {
	inherit = {"deserters"},
	hoverOnTargetDuration = {650,1500},
	speed = 1.5,
	attackDelay = 650,
	attackSpread = 5,
	attackHitChance = 7,
	attackDamage = 70,
	flightVolume = 3500,
	crashType = false,
	hostilePreference = "IsoPlayer",

	addedFunctionsToEvents = {["OnApproach"] = eHelicopter_spawnNPCs},

	eventSoundEffects = {
		["flightSound"] = { "eMiliHeli", "eHeliMusicHostile"},
		["attackSingle"] = "eHeliAlternatingShots",
		["attackLooped"] = "eHeliAlternatingShots",
	},
}

eHelicopter_PRESETS["deserters_UH1H_diversion"] = {
	inherit = {"deserters"},
	hoverOnTargetDuration = {650,1500},
	speed = 1.5,
	flightVolume = 3500,
	crashType = false,
	eventSoundEffects = {
		["flightSound"] = { "eMiliHeli", "eHeliMusicHostile", "eHeliCrewLaughingAndDrinking"},
	},
}