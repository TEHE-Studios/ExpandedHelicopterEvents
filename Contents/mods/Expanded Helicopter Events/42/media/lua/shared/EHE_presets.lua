eHelicopter_PRESETS = eHelicopter_PRESETS or {}

local subEvents = require("EHE_presetSubEvents.lua")

-- The military will warn the public, drop flyers, perform some evacuations, engage zombies, and later falter and disintegrate
eHelicopter_PRESETS["military_friendly"] = {
	announcerVoice = true,
	forScheduling = true,
	crew = {
		{ outfit="EHE_HelicopterPilot" },
		{ outfit="EHE_Soldier", spawn=75 },
		{ outfit="EHE_Soldier", spawn=50 },
	},
	crashType = {"UH60GreenFuselage"},
	scrapItems = {"EHE.UH60Elevator", 1, "EHE.UH60WindowGreen", 1, "EHE.UH60DoorGreen", 1, "Base.ScrapMetal", 5},
	scrapVehicles = {"UH60GreenTail"},
	eventSpawnWeight = 30,
	schedulingFactor = 1.5,
	markerColor = {r=0.37, g=1.00, b=0.27},
	radioChatter = "AEBS_Military",
	presetProgression = {
		["military_UH1H_patrol"] = 0,
		["military_UH1H_patrol_emergency"] = 0.0066,
		["military_OH58A_recon_hover"] = 0.0100,
		["military_UH1H_patrol_quarantine"] = 0.0165,
		["military_UH1H_attack_undead_evac"] = 0.033,
		["military_UH1H_attack_undead"] = 0.066,
		["military_OH58D_attack_zombies"] = 0.077,
		["military_CH47_evac"] = 0.1900,
		["military_CH47_evac_chaotic"] = 0.1900,
		["military_UH1H_command_evac"] = 0.2360,
		["military_UH1H_deserters"] = 0.2450,
	}
}

-- Basic fly over
eHelicopter_PRESETS["military_UH1H_patrol"] = {
	inherit = {"military_friendly"},
}

-- EmergencyFlyer QuarantineFlyer EvacuationFlyer NoticeFlyer PreventionFlyer
eHelicopter_PRESETS["military_UH1H_patrol_emergency"] = {
	inherit = {"military_friendly"},
	dropItems = {["EHE.EmergencyFlyer"]=250},
	announcerVoice = "FlyerChoppers",
	formationIDs = {"military_UH1H_patrol_emergency", 25, {20,25}, "military_UH1H_patrol_emergency", 10, {20,25}},
}

-- Basically the earlier version of the news helicopter
eHelicopter_PRESETS["military_OH58A_recon_hover"] = {
	inherit = {"military_friendly"},
	announcerVoice = false,
	speed = 1.5,
	crashType = false,
	hoverOnTargetDuration = {200,400},
}

-- Later stage announcement and flyer helicopter
eHelicopter_PRESETS["military_UH1H_patrol_quarantine"] = {
	inherit = {"military_friendly"},
	dropItems = {["EHE.QuarantineFlyer"]=250},
	announcerVoice = "FlyerChoppers",
	formationIDs = {"military_UH1H_patrol_quarantine", 25, {20,25}, "military_UH1H_patrol_quarantine", 10, {20,25}},
}

-- Making passes to strafe and throwing out flyers
eHelicopter_PRESETS["military_UH1H_attack_undead_evac"] = {
	announcerVoice = false,
	inherit = {"military_friendly"},
	hostilePreference = "IsoZombie",
	radioChatter = "AEBS_PurgeMilitary",
	dropItems = {["EHE.EvacuationFlyer"]=250},
	formationIDs = {"military_UH1H_attack_undead_evac", 25, {20,25}, "military_UH1H_attack_undead_evac", 10, {20,25}},
}

-- Making passes to strafe zombies
eHelicopter_PRESETS["military_UH1H_attack_undead"] = {
	inherit = {"military_friendly"},
	announcerVoice = false,
	hostilePreference = "IsoZombie",
	radioChatter = "AEBS_PurgeMilitary",
	formationIDs = {"military_UH1H_attack_undead", 25, {12,17}, "military_UH1H_attack_undead", 10, {12,17}},
}

-- Kiowa attacking zombies
eHelicopter_PRESETS["military_OH58D_attack_zombies"] = {
	inherit = {"military_friendly"},
	announcerVoice = false,
	crashType = false,
	speed = 0.3,
	attackDelay = 44,
	attackSpread = 5,
	attackSplash = 2,
	attackHitChance = 70,
	attackDamage = 100,
	-- Attack helicopters stop operating around the time the military falls apart completely
	eventCutOffDayFactor = 0.2360,
	eventSoundEffects = {
		["attackSingle"] = "eHeli30mmCannon",
		["attackLooped"] = "eHeli30mmCannon",
		["flightSound"] = { "eMiliHeli"},
	},
	hostilePreference = "IsoZombie",
	radioChatter = "AEBS_PurgeMilitary",
	formationIDs = {"military_UH1H_attack_undead", 25, {12,17}, "military_UH1H_attack_undead", 10, {12,17}},
}

-- Last evacuations passing through (waiting for assets)
eHelicopter_PRESETS["military_CH47_evac"] = {
	inherit = {"military_friendly"},
	crew = {
		{ outfit="EHE_HelicopterPilot", spawn=100, female=0 },
		{ outfit="EHE_HelicopterPilot", spawn=100, female=0 },
		{ outfit="EHE_Soldier", spawn=100, female=0 },
		{ outfit="EHE_Soldier", spawn=100, female=0 },
		{ outfit="Evacuee", spawn=100, female=50 }, { outfit="Evacuee", spawn=100, female=50 },
		{ outfit="Evacuee", spawn=100, female=50 }, { outfit="Evacuee", spawn=100, female=50 },
		{ outfit="Evacuee", spawn=100, female=50 },
		{ outfit="Evacuee", spawn=90, female=50 }, { outfit="Evacuee", spawn=90, female=50 },
		{ outfit="Evacuee", spawn=90, female=50 }, { outfit="Evacuee", spawn=90, female=50 },
		{ outfit="Evacuee", spawn=90, female=50 },
		{ outfit="Evacuee", spawn=80, female=50 }, { outfit="Evacuee", spawn=80, female=50 },
		{ outfit="Evacuee", spawn=80, female=50 }, { outfit="Evacuee", spawn=80, female=50 },
		{ outfit="Evacuee", spawn=80, female=50 },
		{ outfit="Evacuee", spawn=70, female=50 }, { outfit="Evacuee", spawn=70, female=50 },
		{ outfit="Evacuee", spawn=70, female=50 }, { outfit="Evacuee", spawn=70, female=50 },
		{ outfit="Evacuee", spawn=70, female=50 },
	},
	crashType = false,
	announcerVoice = false,
	scrapItems = {"Base.ScrapMetal", 10},
	eventSoundEffects = {
		["flightSound"] = {"eMiliHeliCargo"}
	},
}
-- Someone turns into a zombie onboard and they accidentally shoot the wrong person. Chaos ensues. People fall out. (waiting for assets)
eHelicopter_PRESETS["military_CH47_evac_chaotic"] = {
	inherit = {"military_friendly"},
	crew = {
		{ outfit="EHE_HelicopterPilot", spawn=100, female=0 },
		{ outfit="EHE_HelicopterPilot", spawn=100, female=0 },
		{ outfit="EHE_Soldier", spawn=100, female=0 },
		{ outfit="EHE_Soldier", spawn=100, female=0 },
		{ outfit="Evacuee", spawn=100, female=50 }, { outfit="Evacuee", spawn=100, female=50 },
		{ outfit="Evacuee", spawn=100, female=50 }, { outfit="Evacuee", spawn=100, female=50 },
		{ outfit="Evacuee", spawn=100, female=50 },
		{ outfit="Evacuee", spawn=90, female=50 }, { outfit="Evacuee", spawn=90, female=50 },
		{ outfit="Evacuee", spawn=90, female=50 }, { outfit="Evacuee", spawn=90, female=50 },
		{ outfit="Evacuee", spawn=90, female=50 },
		{ outfit="Evacuee", spawn=80, female=50 }, { outfit="Evacuee", spawn=80, female=50 },
		{ outfit="Evacuee", spawn=80, female=50 }, { outfit="Evacuee", spawn=80, female=50 },
		{ outfit="Evacuee", spawn=80, female=50 },
		{ outfit="Evacuee", spawn=70, female=50 }, { outfit="Evacuee", spawn=70, female=50 },
		{ outfit="Evacuee", spawn=70, female=50 }, { outfit="Evacuee", spawn=70, female=50 },
		{ outfit="Evacuee", spawn=70, female=50 },
	},
	crashType = false,
	announcerVoice = false,
	scrapItems = {"Base.ScrapMetal", 10},
	eventSoundEffects = {
		["flightSound"] = {"eMiliHeliCargo", "eCH47Panic"}
	},
}
-- Commanders are leaving, could fall out of the sky leaving something.
eHelicopter_PRESETS["military_UH1H_command_evac"] = {
	inherit = {"military_friendly"},
	radioChatter = "AEBS_MilitaryLeaving",
	announcerVoice = false,
}
-- Soldiers are now deserting, not specifically interested in the player. Setting up the late apocalypse faction and events.
eHelicopter_PRESETS["military_UH1H_deserters"] = {
	inherit = {"military_friendly"},
	crashType = false,
	announcerVoice = false,
	radioChatter = "AEBS_DesertersStarting",
}

-- [ The military will now begin shooting anyone they see ]
eHelicopter_PRESETS["military_hostile"] = {
	announcerVoice = true,
	forScheduling = true,
	crew = {
		{ outfit="EHE_HelicopterPilot" },
		{ outfit="EHE_Soldier", spawn=75 },
		{ outfit="EHE_Soldier", spawn=50 },
	},
	crashType = {"UH60GreenFuselage"},
	scrapItems = {"EHE.UH60Elevator", 1, "EHE.UH60WindowGreen", 1, "EHE.UH60DoorGreen", 1, "Base.ScrapMetal", 5},
	scrapVehicles = {"UH60GreenTail"},
	eventSpawnWeight = 30,
	schedulingFactor = 1.5,
	-- Starts after the air raid siren
	eventStartDayFactor = 0.067,
	addedFunctionsToEvents = {["OnAttack"] = subEvents.militaryChangeColor},
	markerColor = {r=0.37, g=1.00, b=0.27},
	radioChatter = "AEBS_Military",
	presetProgression = {
		["military_UH1H_attack_all"] = 0.2145,
		["military_OH58D_attack_all"] = 0.2330,
	}
}
-- UH-1H strafing everything it sees
eHelicopter_PRESETS["military_UH1H_attack_all"] = {
	inherit = {"military_hostile"},
	announcerVoice = false,
	markerColor = {r=1.00, g=0.28, b=0.28},
	hostilePreference = "IsoGameCharacter",
	hostilePredicate = subEvents.hostilePredicateCivilian,
	eventStartDayFactor = 0.067,
	crashType = {"UH60GreenFuselage"},
	scrapItems = {"EHE.UH1HHalfSkirt2", 2, "EHE.UH60Elevator", 1, "EHE.UH60WindowGreen", 1, "EHE.UH60DoorGreen", 1, "Base.ScrapMetal", 10},
	scrapVehicles = {"UH60GreenTail"},
	radioChatter = "AEBS_HostileMilitary",
}
-- Kiowa attacking everything
eHelicopter_PRESETS["military_OH58D_attack_all"] = {
	inherit = {"military_hostile"},
	announcerVoice = false,
	crashType = false,
	speed = 0.3,
	attackDelay = 44,
	attackSpread = 5,
	attackSplash = 2,
	attackHitChance = 70,
	attackDamage = 100,
	eventStartDayFactor = 0.067,
	-- Attack helicopters stop operating around the time the military falls apart completely
	eventCutOffDayFactor = 0.2360,
	eventSoundEffects = {
		["attackSingle"] = "eHeli30mmCannon",
		["attackLooped"] = "eHeli30mmCannon",
		["flightSound"] = { "eMiliHeli"},
	},
	hostilePreference = "IsoGameCharacter",
	radioChatter = "AEBS_HostileMilitary",
	formationIDs = {"military_UH1H_attack_undead", 25, {12,17}, "military_UH1H_attack_undead", 10, {12,17}},
}

-- [ Keep tabs on people without helicopters, each successive spotting of the player will add heat to the system ]
eHelicopter_PRESETS["drones"] = {
	announcerVoice = false,
	forScheduling = true,
	crashType = false,
	eventSpawnWeight = 30,
	schedulingFactor = 1.5,
	markerColor = {r=0.37, g=1.00, b=0.27},
	radioChatter = "AEBS_Drone",
	presetProgression = {
		["drone_RQ2Pioneer_flyover"] = 0,
		["drone_RQ2Pioneer_loiter"] = 0.0070,
	},
	addedFunctionsToEvents = {["OnApproach"] = subEvents.spottedPlayerOnApproach},
}
eHelicopter_PRESETS["drone_RQ2Pioneer_flyover"] = {
	inherit = {"drones"},
	speed = 1.0,
	shadow = false,
	flightVolume = 10,

	eventSoundEffects = {
		["flightSound"] = "ePioneerDrone"
	},
	eventMarkerIcon = "media/ui/plane.png",
	eventSpawnWeight = 1,
	forScheduling = true,
	crashType = false,
}
eHelicopter_PRESETS["drone_RQ2Pioneer_loiter"] = {
	inherit = {"drones"},
	speed = 0.5,
	shadow = false,
	flightVolume = 25,
	eventSoundEffects = {
		["flightSound"] = "ePioneerDrone"
	},
	eventMarkerIcon = "media/ui/plane.png",
	hoverOnTargetDuration = {1000,1500},
	eventSpawnWeight = 1,
	forScheduling = true,
	crashType = false,
}
-- Shift over to hostile events, player should flee and hide
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
-- [ Jets get progressively more aggressive as the military falters ]
eHelicopter_PRESETS["jets"] = {
	announcerVoice = false,
	forScheduling = true,
	crashType = false,
	eventSpawnWeight = 30,
	schedulingFactor = 1.5,
	markerColor = {r=0.37, g=1.00, b=0.27},
	radioChatter = "AEBS_Drone",
	presetProgression = {
		["jet_pass"] = 0,
		["jet_bombing_cluster"] = 0.0070,
		["jet_bombing_napalm"] = 0.0070,
	},
	addedFunctionsToEvents = {["OnApproach"] = subEvents.spottedPlayerOnApproach},
}
-- Passing jet, mostly stirs up activity
eHelicopter_PRESETS["jet_pass"] = {
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
	addedFunctionsToEvents = {["OnApproach"] = subEvents.spottedPlayerOnApproach},
}
-- The player has been warned to flee, up to them now
eHelicopter_PRESETS["jet_bombing_cluster"] = {
	inherit = {"jets"},
	doNotListForStreamerIntegration = true,
	addedFunctionsToEvents = {["OnLaunch"] = subEvents.jetBombing},

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
eHelicopter_PRESETS["jet_bombing_napalm"] = {
	inherit = {"jets"},
	doNotListForStreamerIntegration = true,
	addedFunctionsToEvents = {["OnLaunch"] = subEvents.jetBombing},

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
-- [ News here to emulate the vanilla helicopter ]
eHelicopter_PRESETS["news_Bell206"] = {
	presetRandomSelection = {"news_Bell206_hover", 1},
	eventSoundEffects = {
		["flightSound"] = { "eHelicopter", "eHeli_newscaster" },
	},
	speed = 1,
	crew = {
		{ outfit="EHE_CivilianPilot", },
		{ outfit="EHE_NewsReporter", },
		{ outfit="EHE_NewsReporter", spawn = 40 },
	},
	crashType = {"Bell206LBMWFuselage"},
	scrapItems = {"Base.ScrapMetal", 10},
	scrapVehicles = {"Bell206LBMWTail"},
	forScheduling = true,
	markerColor = {r=1.00, g=0.85, b=0.20},
	eventStartDayFactor = 0.067,
	eventCutOffDayFactor = 0.22,
	radioChatter = "AEBS_UnauthorizedEntryNews",
	addedFunctionsToEvents = {["OnApproach"] = subEvents.spottedPlayerOnApproach},---Because they're LIVE.
}

eHelicopter_PRESETS["news_Bell206_hover"] = {
	inherit = {"news_Bell206"},
	hoverOnTargetDuration = {750,1200},
}
-- [ KY State Police mostly, other cops fleeing their states thrown in for variety later in the apocalypse ]
eHelicopter_PRESETS["police"] = {
	presetRandomSelection = {"police_Bell206_emergency",3, "police_Bell206_hovering",2, "police_Bell206_firing",2, "police_Bell206_fleeing",2,"police_Bell206_fleeing",2},
	crew = {
		{ outfit="EHEPolicePilot" },
		{ outfit="EHEPoliceOfficer" },
		{ outfit="EHEPoliceOfficer", spawn=75 },
	},
	scrapItems = {"Base.ScrapMetal", 10},
	scrapVehicles = {"Bell206PoliceTail"},
	announcerVoice = "Police",
	eventSoundEffects = {
		["foundTarget"] = "eHeli_PoliceSpotted",
	},
	forScheduling = true,
	markerColor = {r=0.28, g=0.28, b=1.00},
	eventStartDayFactor = 0.067,
	eventCutOffDayFactor = 0.22,
	eventSpawnWeight = 10,
	radioChatter = "AEBS_UnauthorizedEntryPolice",
}

eHelicopter_PRESETS["police_Bell206_KY_emergency"] = {
	inherit = {"police"},
	speed = 1.5,
	eventSoundEffects = {
		["flightSound"] = { "eHelicopter", "eHeliPoliceSiren" },
	},
}

eHelicopter_PRESETS["police_Bell206_firing"] = {
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

eHelicopter_PRESETS["police_Bell206_hovering"] = {
	inherit = {"police"},
	speed = 1.5,
	eventSoundEffects = {
		["flightSound"] = "eHelicopter",
	},
	hoverOnTargetDuration = {800,1000},
}

eHelicopter_PRESETS["police_Bell206_fleeing"] = {
	inherit = {"police"},
	speed = 1.5,
	eventSoundEffects = {
		["flightSound"] = "eHelicopter",
	},
}
-- [ Early apocalypse survivors after civilization collapses ]
eHelicopter_PRESETS["survivors"] = {
	presetRandomSelection = {"survivors_Bell206_N720HP",1, "survivors_Bell206_N177TV",1, "survivors_Bell206_N3KY",1, "survivors_Cessna172",1},
	crew = {
		{ outfit = "EHE_StrangerPilot", female = 0 },
		{ outfit = "EHE_Stranger", spawn = 50, female = 0 },
	},
	forScheduling = true,
    markerColor = {r=0.813, g=0.813, b=0.813},
	eventSpawnWeight = 5,
	eventCutOffDayFactor = 1,
	eventStartDayFactor = 0.48,
}
-- Cops from Tennessee
eHelicopter_PRESETS["survivors_Bell206_N720HP"] = {
	speed = 2.0,
	crashType = {"Bell206Fuselage_N720HP"},
	crew = {
		{ outfit="EHE_SurvivorPilot", 0 },
		{ outfit="EHE_Survivor", 0 },
		{ outfit="EHE_Survivor", spawn = 75, female = 0 },
	},
	eventSoundEffects = {
		["flightSound"] = "eHelicopter",
	},
	scrapItems = {"Base.ScrapMetal", 10},
	scrapVehicles = {"Bell206Tail_N720HP"},
	forScheduling = true,
	eventCutOffDayFactor = 1,
	eventStartDayFactor = 0.48,
	radioChatter = "AEBS_SurvivorCops",
}

-- Cops from Indiana
eHelicopter_PRESETS["survivors_Bell206_N95SP"] = {
	speed = 2.0,
	crashType = {"Bell206Fuselage_N95SP"},
	crew = {
		{ outfit="EHE_SurvivorPilot", 0 },
		{ outfit="EHE_Survivor", 0 },
		{ outfit="EHE_Survivor", spawn = 75, female = 0 },
	},
	eventSoundEffects = {
		["flightSound"] = "eHelicopter",
	},
	scrapItems = {"Base.ScrapMetal", 10},
	scrapVehicles = {"Bell206Tail_N95SP"},
	forScheduling = true,
	eventCutOffDayFactor = 1,
	eventStartDayFactor = 0.48,
	radioChatter = "AEBS_SurvivorCops",
}
-- Fleeing reporters
eHelicopter_PRESETS["survivors_Bell206_N177TV"] = {
	speed = 2.0,
	crashType = {"Bell206Fuselage_N177TV"},
	crew = {
		{ outfit="EHE_SurvivorPilot", 0 },
		{ outfit="EHE_Survivor", 0 },
		{ outfit="EHE_Survivor", spawn = 75, female = 0 },
	},
	eventSoundEffects = {
		["flightSound"] = "eHelicopter",
	},
	scrapItems = {"Base.ScrapMetal", 10},
	scrapVehicles = {"Bell206Tail_N177TV"},
	forScheduling = true,
	eventCutOffDayFactor = 1,
	eventStartDayFactor = 0.48,
	radioChatter = "AEBS_SurvivorNews",
}
-- Fleeing reporters
eHelicopter_PRESETS["survivors_Bell206_N5740A"] = {
	speed = 2.0,
	crashType = {"Bell206Fuselage_N5740A"},
	crew = {
		{ outfit="EHE_SurvivorPilot", 0 },
		{ outfit="EHE_Survivor", 0 },
		{ outfit="EHE_Survivor", spawn = 75, female = 0 },
	},
	eventSoundEffects = {
		["flightSound"] = "eHelicopter",
	},
	scrapItems = {"Base.ScrapMetal", 10},
	scrapVehicles = {"Bell206Tail_N5740A"},
	forScheduling = true,
	eventCutOffDayFactor = 1,
	eventStartDayFactor = 0.48,
	radioChatter = "AEBS_SurvivorNews",
}
-- Richlords fleeing
eHelicopter_PRESETS["survivors_Bell206_N120LH"] = {
	speed = 2.0,
	crashType = {"Bell206Fuselage_N120LH"},
	crew = {
		{ outfit="EHE_SurvivorPilot", 0 },
		{ outfit="EHE_Survivor", 0 },
		{ outfit="EHE_Survivor", spawn = 75, female = 0 },
	},
	eventSoundEffects = {
		["flightSound"] = "eHelicopter",
	},
	scrapItems = {"Base.ScrapMetal", 10, "Base.MoneyBundle", 50, "Base.Money", 10, "Base.Briefcase_Money", 5, "Base.Briefcase", 3},
	scrapVehicles = {"Bell206SurvivalistTail"},
	forScheduling = true,
	eventCutOffDayFactor = 1,
	eventStartDayFactor = 0.48,
}
-- Friendly now ex-soldiers trying to find safety, contrast to the deserters
eHelicopter_PRESETS["survivors_soldiers_UH1H"] = {
	speed = 2.0,
	crashType = {"Bell206SurvivalistFuselage"},
	crew = {
		{ outfit="EHE_SurvivorPilot", 0 },
		{ outfit="EHE_Survivor", 0 },
		{ outfit="EHE_Survivor", spawn = 75, female = 0 },
	},
	eventSoundEffects = {
		["flightSound"] = "eMiliHeli",
	},
	scrapVehicles = {"Bell206SurvivalistTail"},
	forScheduling = true,
	eventCutOffDayFactor = 1,
	eventStartDayFactor = 0.48,
	radioChatter = "AEBS_SurvivorSoldiers",
}
-- Taking off from nearby small airfields to ditch traffic
eHelicopter_PRESETS["survivors_Cessna172"] = {
	crew = {
		{ outfit="EHE_SurvivorPilot", female = 0 },
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
-- [ Former soldiers turned profiteers. Logically should only be using a single helicopter. ]
eHelicopter_PRESETS["deserters"] = {
	presetRandomSelection = {"deserters_UH1H_friendly",3,"deserters_UH1H_hostile",2,"deserters_UH1H_scoutingparty",3,"deserters_UH1H_diversion",4,},
	crashType = {"UH60GreenFuselage"},
	scrapItems = {"EHE.UH1HHalfSkirt2", 2, "EHE.UH60Elevator", 1, "EHE.UH60WindowGreen", 1, "EHE.UH60DoorGreen", 1, "Base.ScrapMetal", 10},
	scrapVehicles = {"UH60GreenTail"},
	addedFunctionsToEvents = {["OnFlyaway"] = subEvents.dropTrash},
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
	eventStartDayFactor = 0.80,
	eventCutOffDayFactor = 1.00,
	radioChatter = "AEBS_Deserters",
}
-- Looking around and dropping off people, not strictly hostile
eHelicopter_PRESETS["deserters_UH1H_scoutingparty"] = {
	inherit = {"deserters"},
	speed = 1.5,
	flightVolume = 1500,
	crashType = false,
	eventSoundEffects = {
		["flightSound"] = { "eMiliHeli" },
	},

	addedFunctionsToEvents = {["OnApproach"] = subEvents.spawnNPCs},
}
-- Basic flyover pulling zombies around
eHelicopter_PRESETS["deserters_UH1H_friendly"] = {
	inherit = {"deserters"},
	speed = 1.5,
	flightVolume = 1500,
	eventSoundEffects = {
		["flightSound"] = { "eMiliHeli", "eHeliMusicPassive"},
	},
}
-- Specifically targeting the player and dropping off a landing party
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

	addedFunctionsToEvents = {["OnApproach"] = subEvents.spawnNPCs},

	eventSoundEffects = {
		["flightSound"] = { "eMiliHeli", "eHeliMusicHostile"},
		["attackSingle"] = "eHeliAlternatingShots",
		["attackLooped"] = "eHeliAlternatingShots",
	},
}
-- pulling around zombies around far more dramatically and taking potshots
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