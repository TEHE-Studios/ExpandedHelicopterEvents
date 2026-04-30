require "EHE_presets.lua"

local subEvents = require("EHE_presetSubEvents.lua")
local SWH_subEvents = require("SWH_presetSubEvents.lua")

eHelicopter_PRESETS = eHelicopter_PRESETS or {}


eHelicopter_PRESETS["superWeirdEvents"] = {
	presetRandomSelection = {"Spiffocopter",2,"UFO",3,"IRS",3,"TISCreamery",3,"AttackOfTheStrippers",1,"SandyClaws",1},
	forScheduling = true,
	eventSpawnWeight = 5,
	eventStartDayFactor = 0,
	eventCutOffDayFactor = 1,
}

eHelicopter_PRESETS["superWeirdEventsCopyrighted"] = {
	inherit = {"superWeirdEvents"},
	presetRandomSelection = {"BuffCorrell",1,"Helikopter",1},
	forScheduling = true,
	eventSpawnWeight = 5,
	eventStartDayFactor = 0,
	eventCutOffDayFactor = 1,
}



eHelicopter_PRESETS["Spiffocopter"] = {
	presetProgression = {
		["Spiffocopter_inviteOnly"] = 0,
		["Spiffocopter_partyTime"] = 0.1,
	},
	crashType = {"Bell206SpiffoFuselage"},
	hoverOnTargetDuration = {1000,1225},
	scrapItems = {"EHE.Bell206HalfSkirt", "EHE.Bell206RotorBlade", 2, "EHE.Bell206TailBlade", 2, "Base.ScrapMetal", 10},
	scrapVehicles = {"Bell206SpiffoTail"},
	eventSoundEffects = {
		["flightSound"] = "eHelicopter"
	},
	dropPackages = {"SpiffoBurger"},
	announcerVoice = "Spiffo",
	dropItems = {["SWH.SpiffoInvite"]=250},
	crew = {
		{ outfit="SpiffoBoss", female=0 },
		{ outfit="SpiffoBoss", spawn=10, female=0 },
		{ outfit="SpiffoBoss", spawn=1, female=0 },
	},
	markerColor = {r=0.96,g=0.21,b=0.78},
}

eHelicopter_PRESETS["Spiffocopter_inviteOnly"] = {
	inherit = {"Spiffocopter"},
}

eHelicopter_PRESETS["Spiffocopter_partyTime"] = {
	inherit = {"Spiffocopter"},
	addedFunctionsToEvents = {["OnFlyaway"] = subEvents.dropCrewOff,["OnSpawnCrew"] = subEvents.crewSeek,},
}



eHelicopter_PRESETS["UFO"] = {
	presetRandomSelection = {"UFOTourists",4,"UFORednecks",1,"UFOFratBoys",1,"UFO_stealCow",1},
	crashType = {"UFO"},
	hoverOnTargetDuration = {1000,1225},
	speed = 6,
	topSpeedFactor = 2,
	addedFunctionsToEvents = {["OnFlyaway"] = SWH_subEvents.dropAliensOff,["OnSpawnCrew"] = subEvents.crewSeek,},
	scrapItems = false,
	scrapVehicles = false,
	addedCrashChance = 33,
	flightHours = {20,27},
	announcerVoice = "Aliens",
	eventMarkerIcon = "media/ui/markerUFO.png",
	eventSoundEffects = {
		["flightSound"] = "AlienUFOFlight"
	},
	markerColor = {r=0.96,g=0.21,b=0.78},
}

eHelicopter_PRESETS["UFO_noHoverBackEnd_DoNotUse"] = {
	doNotListForStreamerIntegration = true,
	crew = {
		{ outfit="AlienTourist", female=0 },
		{ outfit="AlienTourist", spawn=10, female=0 },
		{ outfit="AlienTourist", spawn=5, female=0 },
	},
}

eHelicopter_PRESETS["UFO_noHover"] = {
	inherit = {"UFO", "UFO_noHoverBackEnd_DoNotUse"},
	presetRandomSelection = {"UFOTourists",4,"UFORednecks",1,"UFOFratBoys",1,},
	hoverOnTargetDuration = false,
}

eHelicopter_PRESETS["UFO_stealCow"] = {
	inherit = {"UFO"},
	hoverOnTargetDuration = true,
	hostilePreference = "IsoAnimal",
	hostilePredicate = subEvents.hostilePredicateCow,
	addedFunctionsToEvents = {["OnAttack"] = SWH_subEvents.abductCow},

	eventSoundEffects = {
		["attackSingle"] = "alienShot",
		["attackLooped"] = "alienShot",
		["flightSound"] = { "AlienUFOFlight" },
	},
}


eHelicopter_PRESETS["UFOTourists"] = {
	inherit = {"UFO"},
	addedFunctionsToEvents = {["OnFlyaway"] = SWH_subEvents.dropAliensOff,["OnSpawnCrew"] = subEvents.crewSeek,["OnHover"] = SWH_subEvents.abductPlayer},
	crew = {
		{ outfit="AlienTourist", female=0 },
		{ outfit="AlienTourist", spawn=75, female=0 },
		{ outfit="AlienTourist", spawn=30, female=0 },
		{ outfit="AlienTourist", spawn=15, female=0 },
		{ outfit="AlienTourist", spawn=5, female=0 },
	},
}

eHelicopter_PRESETS["UFORednecks"] = {
	inherit = {"UFO"},
	addedFunctionsToEvents = {["OnFlyaway"] = SWH_subEvents.dropAliensOff,["OnSpawnCrew"] = subEvents.crewSeek,["OnHover"] = SWH_subEvents.abductPlayer},
	crashType = {"UFORedneck"},
	crew = {
		{ outfit="AlienTourist", female=0 },
		{ outfit="AlienTourist", spawn=75, female=0 },
		{ outfit="AlienTourist", spawn=30, female=0 },
		{ outfit="AlienTourist", spawn=15, female=0 },
		{ outfit="AlienTourist", spawn=5, female=0 },
	},

	eventSoundEffects = {
		["flightSound"] = "RedNeckAlienUFOFlight",
	},
}

eHelicopter_PRESETS["UFOFratBoys"] = {
	inherit = {"UFO"},
	addedFunctionsToEvents = {["OnFlyaway"] = SWH_subEvents.dropAliensOff,["OnSpawnCrew"] = subEvents.crewSeek,["OnHover"] = SWH_subEvents.abductPlayer},
	crew = {
		{ outfit="AlienTourist", female=0 },
		{ outfit="AlienTourist", spawn=75, female=0 },
		{ outfit="AlienTourist", spawn=30, female=0 },
		{ outfit="AlienTourist", spawn=15, female=0 },
		{ outfit="AlienTourist", spawn=5, female=0 },
	},
	eventSoundEffects = {
		["flightSound"] = { "AlienUFOFlight", "assBlastUSA" },
	},
	announcerVoice = "FratAliens",
}



eHelicopter_PRESETS["IRS"] = {
	presetProgression = {
		["IRS_Wave1"] = 0,
		["IRS_Wave2"] = 0.2,
		["IRS_Wave3"] = 0.5,
	},
	hoverOnTargetDuration = {1000,1225},
	crashType = {"Bell206IRSFuselage"},
	scrapItems = {"EHE.Bell206HalfSkirt", "EHE.Bell206RotorBlade", 2, "EHE.Bell206TailBlade", 2, "Base.ScrapMetal", 10},
	scrapVehicles = {"Bell206IRSTail"},
	attackDelay = 1000,
	attackSpread = 4,
	speed = 0.9,
	attackHitChance = 65,
	attackDamage = 12,
	hostilePreference = "IsoPlayer",
	dropItems = {["SWH.TenFortyForm"]=400},
	eventSoundEffects = {
		["attackSingle"] = "eHeli_bolt_action_fire_single",
		["attackLooped"] = "eHeli_bolt_action_fire_single",
		["flightSound"] = "eHelicopter",
	},
	addedFunctionsToEvents = {["OnFlyaway"] = subEvents.dropCrewOff,["OnSpawnCrew"] = subEvents.crewSeek,},
	announcerVoice = "IRS",
	markerColor = {r=0.96,g=0.21,b=0.78},
}

eHelicopter_PRESETS["IRS_noHover"] = {
	inherit = {"IRS"},
	hoverOnTargetDuration = false,
}

eHelicopter_PRESETS["IRS_Wave1"] = {
	inherit = {"IRS"},
	addedFunctionsToEvents = {["OnFlyaway"] = subEvents.dropCrewOff,["OnSpawnCrew"] = subEvents.crewSeek,},
	crew = {
		{ outfit="TaxMan", female=0 }, { outfit="TaxMan", female=0 },
		{ outfit="TaxMan", female=0 }, { outfit="TaxMan", female=0 },
		{ outfit="TaxMan", female=0 }, { outfit="TaxMan", female=0 },
		{ outfit="TaxMan", spawn=50, female=0 }, { outfit="TaxMan", spawn=50, female=0 },
		{ outfit="TaxMan", spawn=50, female=0 }, { outfit="TaxMan", spawn=50, female=0 },
		{ outfit="TaxMan", spawn=50, female=0 }, { outfit="TaxMan", spawn=50, female=0 },
	},
}

eHelicopter_PRESETS["IRS_Wave2"] = {
	inherit = {"IRS"},
	addedFunctionsToEvents = {["OnFlyaway"] = subEvents.dropCrewOff,["OnSpawnCrew"] = subEvents.crewSeek,},

	crew = {
		{ outfit="TaxMan", female=0 }, { outfit="TaxMan", female=0 },
		{ outfit="TaxMan", female=0 }, { outfit="TaxMan", female=0 },
		{ outfit="TaxMan", female=0 }, { outfit="TaxMan", female=0 },
		{ outfit="TaxMan", female=0 }, { outfit="TaxMan", female=0 },
		{ outfit="TaxMan", female=0 }, { outfit="TaxMan", female=0 },
		{ outfit="TaxMan", female=0 }, { outfit="TaxMan", female=0 },

		{ outfit="TaxMan", spawn=50, female=0 }, { outfit="TaxMan", spawn=50, female=0 },
		{ outfit="TaxMan", spawn=50, female=0 }, { outfit="TaxMan", spawn=50, female=0 },
		{ outfit="TaxMan", spawn=50, female=0 }, { outfit="TaxMan", spawn=50, female=0 },
		{ outfit="TaxMan", spawn=50, female=0 }, { outfit="TaxMan", spawn=50, female=0 },
		{ outfit="TaxMan", spawn=50, female=0 }, { outfit="TaxMan", spawn=50, female=0 },
		{ outfit="TaxMan", spawn=50, female=0 }, { outfit="TaxMan", spawn=50, female=0 },
	},
}

eHelicopter_PRESETS["IRS_Wave3"] = {
	inherit = {"IRS"},
	addedFunctionsToEvents = {["OnFlyaway"] = subEvents.dropCrewOff,["OnSpawnCrew"] = subEvents.crewSeek,},

	crew = {
		{ outfit="TaxMan", female=0 }, { outfit="TaxMan", female=0 },
		{ outfit="TaxMan", female=0 }, { outfit="TaxMan", female=0 },
		{ outfit="TaxMan", female=0 }, { outfit="TaxMan", female=0 },
		{ outfit="TaxMan", female=0 }, { outfit="TaxMan", female=0 },
		{ outfit="TaxMan", female=0 }, { outfit="TaxMan", female=0 },
		{ outfit="TaxMan", female=0 }, { outfit="TaxMan", female=0 },
		{ outfit="TaxMan", female=0 }, { outfit="TaxMan", female=0 },
		{ outfit="TaxMan", female=0 }, { outfit="TaxMan", female=0 },
		{ outfit="TaxMan", female=0 }, { outfit="TaxMan", female=0 },

		{ outfit="TaxMan", spawn=50, female=0 }, { outfit="TaxMan", spawn=50, female=0 },
		{ outfit="TaxMan", spawn=50, female=0 }, { outfit="TaxMan", spawn=50, female=0 },
		{ outfit="TaxMan", spawn=50, female=0 }, { outfit="TaxMan", spawn=50, female=0 },
		{ outfit="TaxMan", spawn=50, female=0 }, { outfit="TaxMan", spawn=50, female=0 },
		{ outfit="TaxMan", spawn=50, female=0 }, { outfit="TaxMan", spawn=50, female=0 },
		{ outfit="TaxMan", spawn=50, female=0 }, { outfit="TaxMan", spawn=50, female=0 },
		{ outfit="TaxMan", spawn=50, female=0 }, { outfit="TaxMan", spawn=50, female=0 },
		{ outfit="TaxMan", spawn=50, female=0 }, { outfit="TaxMan", spawn=50, female=0 },
		{ outfit="TaxMan", spawn=50, female=0 }, { outfit="TaxMan", spawn=50, female=0 },
	},
}


eHelicopter_PRESETS["TISCreamery"] = {
	presetRandomSelection = {"TISCreamery_Licks",2,"TISCreamery_Socks",1},
	crashType = {"TISIceCreamTruck"},
	hoverOnTargetDuration = {1000,1125},
	eventSoundEffects = {
		["flightSound"] = "IceCreamFlyBy",
	},
	addedFunctionsToEvents = {["OnFlyaway"] = subEvents.dropCrewOff,["OnSpawnCrew"] = subEvents.crewSeek,},
	scrapAndParts = false,
	markerColor = {r=0.96,g=0.21,b=0.78},
}

eHelicopter_PRESETS["TISCreamery_Licks"] = {
	inherit = {"TISCreamery"},
	crew = {
		{ outfit="SWH_IceCream", spawn=100, female=0 },
		{ outfit="SWH_IceCream", spawn=100, female=0 },
		{ outfit="SWH_IceCream", spawn=75, female=0 },
		{ outfit="SWH_IceCream", spawn=50, female=0 },
		{ outfit="SWH_IceCream", spawn=25, female=0 },
		{ outfit="SWH_IceCream", spawn=25, female=0 },
	},
}

eHelicopter_PRESETS["TISCreamery_Socks"] = {
	inherit = {"TISCreamery"},
	crew = {
		{ outfit="SockConnoisseur", female=0 },
	},
}



eHelicopter_PRESETS.survivors.dropPackages = {"SurvivorSupplyDrop","SurvivorSupplyDrop","SurvivorSupplyDrop","MCSupplyDrop"}


eHelicopter_PRESETS["Helikopter"] = {
	inherit = {"military_UH1H_attack_all"},
	markerColor = {r=0.96,g=0.21,b=0.78},
	callsigns = {"Helikopter"},
	eventSoundEffects = {
		["flightSound"] = { "eMiliHeli", "Helikopter" },
		["attackSingle"] = "eHeliM16GunfireSingle",
		["attackLooped"] = "eHeliM16GunfireSingle",
	}
}


eHelicopter_PRESETS["SandyClaws"] = {
	speed = 2,
	crashType = {"UH1HSantaFuselage"},
	scrapItems = {"EHE.UH1HHalfSkirt", "EHE.Bell206RotorBlade", 2, "EHE.Bell206TailBlade", 2, "Base.ScrapMetal", 10,},
	scrapVehicles = {"UH1HSantaTail"},
	crew = {
		{outfit="AlienSanta", female=0}
	},
	hoverOnTargetDuration = {1250,1500},
	attackDelay = 1700,
	attackSpread = 4,
	markerColor = {r=0.96,g=0.21,b=0.78},
	attackHitChance = 55,
	attackDamage = 10,
	hostilePreference = "IsoPlayer",
	eventSoundEffects = {
		["flightSound"] = { "eMiliHeli", "JangleBalls" },
		["attackSingle"] = "eHeliM16GunfireSingle",
		["attackLooped"] = "eHeliM16GunfireSingle",
	},
	addedFunctionsToEvents = {["OnFlyaway"] = subEvents.dropCrewOff,["OnSpawnCrew"] = subEvents.crewSeek,},
	eventSpawnWeight = 5,
	eventSpecialDates = { systemDates = {{12}}, inGameDates = {{12,20}, {12,25}}}
}
eHelicopter_PRESETS["SandyClaws_noHover"] = {
	inherit = {"SandyClaws"},
	hoverOnTargetDuration = false,
}


eHelicopter_PRESETS["AttackOfTheStrippers"] = {
	speed = 2.5,
	crew = {
		{ outfit="CowboyStripper", female=0 },
		{ outfit="CowboyStripper", female=0 },
		{ outfit="CowboyStripper", female=0 },
		{ outfit="CowboyStripper", female=0 },
		{ outfit="CowboyStripper", female=0 },
		{ outfit="CowboyStripper", spawn=50, female=0 },
		{ outfit="CowboyStripper", spawn=50, female=0 },
		{ outfit="CowboyStripper", spawn=50, female=0 },
		{ outfit="FiremanStripper", female=0 },
		{ outfit="FiremanStripper", female=0 },
		{ outfit="FiremanStripper", female=0 },
		{ outfit="FiremanStripper", female=0 },
		{ outfit="FiremanStripper", female=0 },
		{ outfit="FiremanStripper", spawn=50, female=0 },
		{ outfit="FiremanStripper", spawn=50, female=0 },
		{ outfit="FiremanStripper", spawn=50, female=0 },
	},

	hoverOnTargetDuration = {1250,1500},
	eventSoundEffects = {
		["flightSound"] = { "eMiliHeli", "assBlastUSA" },
	},
	addedFunctionsToEvents = {["OnFlyaway"] = subEvents.dropCrewOff,["OnSpawnCrew"] = subEvents.crewSeek,},
	markerColor = {r=0.96,g=0.21,b=0.78},
	eventSpecialDates = { systemDates = {{12}}, inGameDates = {{12,20}, {12,31}}}
}
eHelicopter_PRESETS["AttackOfTheStrippers_noHover"] = {
	inherit = {"AttackOfTheStrippers"},
	hoverOnTargetDuration = false,
}


eHelicopter_PRESETS["BuffCorrell"] = {
	crashType = false,
	crew = {
		{ outfit="EHESurvivorPilot", female=0 }
	},
	speed = 0.8,
	eventMarkerIcon = "media/ui/plane.png",
	--addedFunctionsToEvents = {["OnAttack"] = forceDance},
	---true actions dancing isn't on B42

	attackDelay = 1,
	attackDistance = 700,
	attackHitChance = 100,
	attackDamage = 0,
	hostilePreference = "IsoPlayer",
	--hostilePreference = "IsoGameCharacter",

	eventSoundEffects = {
		["attackSingle"] = "IGNORE",
		["attackLooped"] = "IGNORE",
		["attackImpacts"] = "IGNORE",
		["flightSound"] = { "ePropPlane", "buffcorrell" },
	},

	markerColor = {r=0.96,g=0.21,b=0.78},
	radioChatter = "AEBS_buffcorrell"
} 