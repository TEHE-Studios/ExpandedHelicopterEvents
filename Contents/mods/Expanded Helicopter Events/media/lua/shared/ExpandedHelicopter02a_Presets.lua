eHelicopter_PRESETS = eHelicopter_PRESETS or {}

--- SEE FILE: ExpandedHelicopter_PRESETGUIDE.lua FOR INSTRUCTIONS AND HELP MAKING A SUB-MOD ---

eHelicopter_PRESETS["military"] = {
	announcerVoice = true,
	forScheduling = true,
	crew = {"EHEMilitaryPilot", "EHESoldier", 75, "EHESoldier", 50},
	crashType = {"UH60GreenFuselage"},
	scrapItems = {"EHE.UH60Elevator", 1, "EHE.UH60WindowGreen", 1, "EHE.UH60DoorGreen", 1, "Base.ScrapMetal", 5},
	scrapVehicles = {"UH60GreenTail"},
	eventSpawnWeight = 20,
	schedulingFactor = 1.5,
	markerColor = {r=0.29,g=0.78,b=0.21},
	radioChatter = "AEBS_Military",
	presetProgression = {
		["military_patrol"] = 0,
		["military_patrol_emergency"] = 0.0066,
		["military_recon_hover"] = 0.0070,
		["military_patrol_quarantine"] = 0.0165,
		["military_attack_undead_evac"] = 0.033,
		["military_attack_undead"] = 0.066,
		["military_attackhelicopter_zombies"] = 0.077,
		["military_cargo"] = 0.1900,
		["military_attack_all"] = 0.2145,
	}
}

eHelicopter_PRESETS["military_patrol"] = {
	inherit = {"military"},
}

-- EmergencyFlyer QuarantineFlyer EvacuationFlyer NoticeFlyer PreventionFlyer
eHelicopter_PRESETS["military_patrol_emergency"] = {
	inherit = {"military"},
	dropItems = {["EHE.EmergencyFlyer"]=250},
	announcerVoice = "FlyerChoppers",
	formationIDs = {"military_patrol_emergency", 25, {20,25}, "military_patrol_emergency", 10, {20,25}},
}

eHelicopter_PRESETS["military_recon_hover"] = {
	inherit = {"military"},
	announcerVoice = false,
	speed = 1.5,
	crashType = false,
	hoverOnTargetDuration = {200,400},
}

eHelicopter_PRESETS["military_patrol_quarantine"] = {
	inherit = {"military"},
	dropItems = {["EHE.QuarantineFlyer"]=250},
	announcerVoice = "FlyerChoppers",
	formationIDs = {"military_patrol_quarantine", 25, {20,25}, "military_patrol_quarantine", 10, {20,25}},
}

eHelicopter_PRESETS["military_attack_undead_evac"] = {
	announcerVoice = false,
	inherit = {"military"},
	hostilePreference = "IsoZombie",
	radioChatter = "AEBS_PurgeMilitary",
	dropItems = {["EHE.EvacuationFlyer"]=250},
	formationIDs = {"military_attack_undead_evac", 25, {20,25}, "military_attack_undead_evac", 10, {20,25}},
}

eHelicopter_PRESETS["military_attack_undead"] = {
	inherit = {"military"},
	announcerVoice = false,
	hostilePreference = "IsoZombie",
	radioChatter = "AEBS_PurgeMilitary",
	formationIDs = {"military_attack_undead", 25, {12,17}, "military_attack_undead", 10, {12,17}},
}

eHelicopter_PRESETS["military_cargo"] = {
	inherit = {"military"},
	announcerVoice = false,
	crashType = false,
	crashType = {"UH60GreenFuselage"},
	scrapItems = {"EHE.UH60Elevator", 1, "EHE.UH60WindowGreen", 1, "EHE.UH60DoorGreen", 1, "Base.ScrapMetal", 10},
	eventSoundEffects = {
		["flightSound"] = "eMiliHeliCargo",
	},
}

eHelicopter_PRESETS["military_attackhelicopter_zombies"] = {
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
	formationIDs = {"military_attack_undead", 25, {12,17}, "military_attack_undead", 10, {12,17}},
}

local function hostilePredicateCivilian(target)
	if not target then return end
	local nonCivScore = 0
	---@type IsoPlayer|IsoGameCharacter
	local player = target
	local wornItems = player:getWornItems()
	if wornItems then
		for i=0, wornItems:size()-1 do
			---@type InventoryItem
			local item = wornItems:get(i):getItem()
			if item then
				if string.match(string.lower(item:getFullType()),"army")
						or string.match(string.lower(item:getFullType()),"military")
						or string.match(string.lower(item:getFullType()),"riot")
						or string.match(string.lower(item:getFullType()),"police")
						or item:getTags():contains("Police")
						or item:getTags():contains("Military") then
					nonCivScore = nonCivScore+1
				end
			end
		end
	end
	return nonCivScore<3
end

eHelicopter_PRESETS["military_attack_all"] = {
	inherit = {"military"},
	announcerVoice = false,
	markerColor = {r=0.96,g=0.21,b=0.21},
	hostilePreference = "IsoGameCharacter",
	hostilePredicate = hostilePredicateCivilian,
	crashType = {"UH60GreenFuselage"},
	scrapItems = {"EHE.UH60Elevator", 1, "EHE.UH60WindowGreen", 1, "EHE.UH60DoorGreen", 1, "Base.ScrapMetal", 10},
	scrapVehicles = {"UH60GreenTail"},
	radioChatter = "AEBS_HostileMilitary",
}


eHelicopter_PRESETS["FEMA_drop"] = {
	inherit = {"military"},
	announcerVoice = false,
	forScheduling = true,
	crashType = {"UH60MedevacFuselage"},
	hoverOnTargetDuration = 500,
	dropPackages = {"FEMASupplyDrop"},
	dropItems = {["EHE.QuarantineFlyer"]=150},
	speed = 0.9,
	scrapItems = {"EHE.UH60Elevator", 1, "EHE.UH60WindowGreen", 1, "EHE.UH60DoorMedevac", 1, "Base.ScrapMetal", 5},
	scrapVehicles = {"UH60GreenTail"},
	eventSoundEffects = {
		["foundTarget"] = "eHeli_AidDrop_2",
		["droppingPackage"] = "eHeli_AidDrop_1and3",
	},
	formationIDs = {"military_patrol", 25, {12,17}, "military_patrol", 10, {12,17}},
	radioChatter = "AEBS_SupplyDrop",
	eventStartDayFactor = 0.034,
	eventCutOffDayFactor = 0.2145,
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
	eventMarkerIcon = "media/ui/plane.png",
	forScheduling = true,
	schedulingFactor = 4,
	eventSpawnWeight = 5,
	radioChatter = "AEBS_JetPass",
}

eHelicopter_PRESETS["air_raid"] = {
	doNotListForTwitchIntegration = true,
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


local function eHelicopter_jetBombing(heli)
	local heliX, heliY, _ = heli:getXYZAsInt()
	local cell = getCell()
	local vehiclesInCell = cell:getVehicles()
	for i=0, vehiclesInCell:size()-1 do
		---@type BaseVehicle
		local vehicle = vehiclesInCell:get(i)
		if vehicle and vehicle:isAlarmed() then
			vehicle:triggerAlarm()
		end
	end
end

eHelicopter_PRESETS["jet_bombing"] = {
	inherit = {"jet"},
	doNotListForTwitchIntegration = true,
	addedFunctionsToEvents = {["OnLaunch"] = eHelicopter_jetBombing},

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


eHelicopter_PRESETS["news_chopper"] = {
	presetRandomSelection = {"news_chopper_hover", 1, "news_chopper_fleeing", 2, },
	eventSoundEffects = {
		["flightSound"] = { "eHelicopter", "eHeli_newscaster" },
	},
	speed = 1,
	crew = {"EHECivilianPilot", "EHENewsReporterVest", "EHENewsReporterVest", 40},
	crashType = {"Bell206LBMWFuselage"},
	scrapItems = {"EHE.Bell206HalfSkirt", "EHE.Bell206RotorBlade1", 2, "EHE.Bell206RotorBlade2", 2,  "EHE.Bell206TailBlade", 2, "Base.ScrapMetal", 10},
	scrapVehicles = {"Bell206LBMWTail"},
	forScheduling = true,
	markerColor = {r=0.96,g=0.78,b=0.17},
	eventStartDayFactor = 0.067,
	eventCutOffDayFactor = 0.22,
	radioChatter = "AEBS_UnauthorizedEntryNews",
}

eHelicopter_PRESETS["news_chopper_hover"] = {
	inherit = {"news_chopper"},
	hoverOnTargetDuration = {750,1200},
}

eHelicopter_PRESETS["news_chopper_fleeing"] = {
	inherit = {"news_chopper"},
	speed = 1.6,
}

eHelicopter_PRESETS["police"] = {
	presetRandomSelection = {"police_heli_emergency",3, "police_heli_firing",2, "police_heli_fleeing",2},
	crashType = {"Bell206PoliceFuselage"},
	crew = {"EHEPolicePilot", "EHEPoliceOfficer", "EHEPoliceOfficer", 75},
	scrapItems = {"EHE.Bell206HalfSkirt", "EHE.Bell206RotorBlade1", 2, "EHE.Bell206RotorBlade2", 2,  "EHE.Bell206TailBlade", 2, "Base.ScrapMetal", 10},
	scrapVehicles = {"Bell206PoliceTail"},
	announcerVoice = "Police",
	eventSoundEffects = {
		["foundTarget"] = "eHeli_PoliceSpotted",
	},
	forScheduling = true,
	markerColor = {r=0.21,g=0.21,b=0.96},
	eventStartDayFactor = 0.067,
	eventCutOffDayFactor = 0.22,
	radioChatter = "AEBS_UnauthorizedEntryPolice",
}

eHelicopter_PRESETS["police_heli_emergency"] = {
	inherit = {"police"},
	speed = 1.5,
	eventSoundEffects = {
		["flightSound"] = { "eHelicopter", "eHeliPoliceSiren" },
	},

}

eHelicopter_PRESETS["police_heli_firing"] = {
	inherit = {"police"},
	attackDelay = 1700,
	attackSpread = 4,
	speed = 0.7,
	attackHitChance = 95,
	attackDamage = 12,
	hostilePreference = "IsoZombie",
	eventSoundEffects = {
		["attackSingle"] = "eHeliAlternatingShots",
		["attackLooped"] = "eHeliAlternatingShots",
		["flightSound"] = { "eHelicopter", "eHeliPoliceWarning" },
	},
	hoverOnTargetDuration = {375,575},
}

eHelicopter_PRESETS["police_heli_fleeing"] = {
	inherit = {"police"},
	speed = 1.5,
	eventSoundEffects = {
		["flightSound"] = "eHelicopter",
	},

}

eHelicopter_PRESETS["survivor_smallplane"] = {
	crashType = false,
	crew = {"EHESurvivorPilot", 100, 0},
	speed = 0.7,
	eventMarkerIcon = "media/ui/plane.png",
	eventSoundEffects = {
		["flightSound"] = "eSmallPropPlane",
	},
	forScheduling = true,
	markerColor = {r=0.29,g=0.78,b=0.21},
	eventCutOffDayFactor = 1,
	eventStartDayFactor = 0.48,
	eventSpawnWeight = 3,
}

eHelicopter_PRESETS["samaritan_drop"] = {
	crashType = false,
	crew = {"EHESurvivorPilot", 100, 0},
	dropPackages = {"SurvivorSupplyDrop"},
	speed = 1.0,
	eventMarkerIcon = "media/ui/plane.png",
	eventSoundEffects = {
		["flightSound"] = "eLargePropPlane",
	},
	forScheduling = true,
	markerColor = {r=0.29,g=0.78,b=0.21},
	eventCutOffDayFactor = 1,
	eventStartDayFactor = 0.48,
	eventSpawnWeight = 3,
	radioChatter = "AEBS_SamaritanDrop"
}

eHelicopter_PRESETS["survivor_heli"] = {
	speed = 2.0,
	crashType = {"Bell206SurvivalistFuselage"},
	crew = {"EHESurvivorPilot", 100, 0, "EHESurvivor", 100, 0, "EHESurvivor", 75, 0},
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


local function eHelicopter_dropTrash(heli)

	local heliX, heliY, _ = heli:getXYZAsInt()
	local trashItems = {"WhiskeyEmpty","SmashedBottle","BeerEmpty","BeerEmpty"}

	local moreTrashItems = {"SmashedBottle","SmashedBottle","SmashedBottle","SmashedBottle",
							"MayonnaiseEmpty","Pop3Empty","Pop2Empty","Pop3Empty","WhiskeyEmpty",
							"BeerCanEmpty","BeerCanEmpty","BeerCanEmpty","BeerCanEmpty","BeerEmpty"}
	local iterations = 10
	for i=1, iterations do
		local trashType = moreTrashItems[(ZombRand(#moreTrashItems)+1)]
		table.insert(moreTrashItems, trashType)
		table.insert(trashItems, trashType)
	end
	
	local soundEmitter = getWorld():getFreeEmitter(heliX, heliY, 0)
	soundEmitter:playSound("eHeliDumpTrash", heliX, heliY, 0)

	for _,trashType in pairs(trashItems) do
		heliY = heliY+ZombRand(-3,3)
		heliX = heliX+ZombRand(-3,3)
		SpawnerTEMP.spawnItem(trashType, heliX, heliY, 0, {"ageInventoryItem"}, nil, "getOutsideSquareFromAbove")
	end
end

eHelicopter_PRESETS["raiders"] = {
	presetRandomSelection = {"raider_heli_passive",3,"raider_heli_hostile",1},
	crashType = {"UH60GreenFuselage"},
	scrapItems = {"EHE.UH60Elevator", 1, "EHE.UH60WindowGreen", 1, "EHE.UH60DoorGreen", 1, "Base.ScrapMetal", 10},
	scrapVehicles = {"UH60GreenTail"},
	addedFunctionsToEvents = {["OnFlyaway"] = eHelicopter_dropTrash},
	crew = {"EHERaiderPilot", 100, 0, "EHERaider", 100, 0, "EHERaider", 100, 0, "EHERaider", 100, 0, "EHERaiderLeader", 75, 0},
	forScheduling = true,
	markerColor = {r=0.96,g=0.39,b=0.21},
	eventCutOffDayFactor = 1,
	eventStartDayFactor = 0.48,
	radioChatter = "AEBS_Raiders",
}


eHelicopter_PRESETS["raider_heli_passive"] = {
	inherit = {"raiders"},
	speed = 0.5,
	flightVolume = 750,
	crashType = false,
	eventSoundEffects = {
		["flightSound"] = { "eMiliHeli", "eHeliMusicPassive", "eHeliCrewLaughingAndDrinking" },
	},
}

eHelicopter_PRESETS["raider_heli_hostile"] = {
	inherit = {"raiders"},
	hoverOnTargetDuration = {650,1500},
	speed = 1.5,
	attackDelay = 650,
	attackSpread = 5,
	attackHitChance = 7,
	attackDamage = 10,
	flightVolume = 750,
	crashType = false,
	hostilePreference = "IsoPlayer",
	eventSoundEffects = {
		["flightSound"] = { "eMiliHeli", "eHeliMusicHostile", "eHeliCrewLaughingAndDrinking" },
		["attackSingle"] = "eHeliAlternatingShots",
		["attackLooped"] = "eHeliAlternatingShots",
	},
}