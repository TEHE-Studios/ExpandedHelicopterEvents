if 1==1 then return end ---Remove this Line to get started.
-----------------------------------------------------------
--- YOUR SUB-MOD FILE MUST GO IN MEDIA/SHARED/ IN ORDER TO WORK ---
-----------------------------------------------------------

---Presets should only include variables you want changed,
---if a variable is not listed it uses the default value OR in some cases any previously loaded preset.

---@class eHelicopter
---@field forScheduling boolean default: false, used for scheduler; leaving it as false means the event will not spawn from the scheduler
---@field schedulingFactor number multiplied against frequency to make them more or less likely - high number = more likely to be scheduled
---@field eventSpawnWeight number This number is how many times this event is included in the scheduler's pool of events
---@field eventStartDayFactor number This is number is multiplied against cutOffDay to act as when it will be able to spawn.
---@field eventCutOffDayFactor number This is multiplied against cutOffDay to act as the day this event no longer spawns
---@field doNotListForTwitchIntegration boolean default: false
---@field ignoreContinueScheduling boolean default: false

---@field inherit table default: false; Table of PresetIDs, each is loaded in order - previous variables are overwritten.

---@field presetProgression table default: false; Table of presetIDs and corresponding % preset is compared to Days/CuttOffDay
---example: {["presetA"]=0,["presetB"]=25,["presetC"]=50} = at 0% (days out of cutoff day) preset1 is chosen, at 25% presetB is chosen, etc.

---@field presetRandomSelection table default: false; Table of presetIDs and optional corresponding weight (weight is 1 if none found) in list to be chosen from.
---Example: {"presetA", 2, "presetB", "presetC", 4} = a list equal to {"presetA","presetA","presetB","presetC","presetC","presetC","presetC"}

---@field eventSpecialDates table table of specific in-game months/day tables; inGameDates/systemDates (table of tables)
--- EXAMPLES: {{1,1}} = 1st month and 1st day only
---           {{1}} = Entire 1st Month
---           {{2}, {3,15}} = Entire 2nd month to 3rd Month 15th day.
---If no day is provided it is assumed to use the entire month
--- example: { systemDates = {{1,1}}, inGameDates = {{2}, {3,15}}}

---@field radioChatter string default: "AEBS_Choppah" - you will need to add your own translation file for unique strings.
---@field flightHours table table of numbers, example, flightHours = {5, 22}
---@field hoverOnTargetDuration number|boolean How long the helicopter will hover over the player, this is subtracted from every tick, default: false
---@field searchForTargetDurationMS number How long the helicopter will search for last seen targets in ticks
---@field shadow boolean | WorldMarkers.GridSquareMarker if set to true a shadow (WorldMarkers.GridSquareMarker) will be created
---@field shadowTexture string texture filename to use for the shadow, default: "helicopter_shadow"
---@field eventMarkerIcon string texture filename to use for markers, default: "media/ui/helievent.png"
---@field crashType boolean|table is false no wreck will be spawned, otherwise use a table - only 1 entry will be selected at random, default: {"UH1HFuselage"}
---@field addedCrashChance number additional % to add to crash chance , default: 0.

---@field addedFunctionsToEvents table table of IDs for additional function calls on specific events, these functions need to be defined/before above the presets file
---Useful for submodders seeking to add more functionality to events.
---Simply make your preset's table filled with the names of functions you want to call.
---NOTE: Presets' file must be loaded after any called function's file to work.
---If you want your event to occur only once simply set the entry to false afterwards.
---All functions called have the following arguments: self (eHelicopter)
---OnCrash has the additional argument of: currentSquare (IsoGridSquare)
---OnAttack has the additional argument of: targetHostile (IsoObject|IsoMovingObject|IsoGameCharacter|IsoPlayer|IsoZombie)
---{ ["OnCrash"] = false, ["OnHover"] = false, ["OnFlyaway"] = false, ["OnAttack"] = false, ["OnSpawnCrew"] = false, ["OnArrived"] = false}

---@field scrapVehicles table table of additional `BaseVehicle` to act as extra large pieces, default: {"UH1HTail"} --{"Base.TYPE","Base.TYPE"}
---@field scrapItems table table of additional `InventoryItem` to act as extra small pieces, default: {"EHE.UH1HHalfSkirt", "EHE.UH1HRotorBlade", 2, "EHE.Bell206TailBlade", 2, "Base.ScrapMetal", 10}

---@field crew table list of IDs and chances (similar to how loot distribution is handled)
---The format ias ID, spawnChance, isFemaleChance
---Example: crew = {"pilot", 100, 50, "crew", 75, 50, "crew", 50, 50}
---The number after the ID is assumed for spawn chance, if there is no number found 100% is used.
---If there is a number after the spawnChance it it assumed for the isFemaleChance, if no number 50% is used.
---default: {"AirCrew", 100}

---@field formation table table of IDs to generate follower helis, default: {}
---@field dropItems table|boolean table of items IDs or false to disable
---@field dropPackages table|boolean table of vehicle IDs or false to disable

---@field looperEventIDs table of soundeffectIDs to act as loops
---(this is a workaround to handle looped sounds in MP)
---default: {["additionalFlightSound"]=true, ["flightSound"]=true}

---@field eventSoundEffects table table of additional soundeffectIDs with corresponding "IGNORE" or sound filenames
---default:
---eHelicopter.eventSoundEffects = {
---    ["hoverOverTarget"]="IGNORE",
---    ["flyOverTarget"]="IGNORE",
---    ["lostTarget"]="IGNORE",
---    ["foundTarget"]="IGNORE",
---    ["droppingPackage"]="IGNORE",
---    ["additionalAttackingSound"]="IGNORE",
---    ["additionalFlightSound"]="IGNORE", --LOOPED
---    ["soundAtEventOrigin"]="IGNORE",
---
---    ["attackSingle"] = "eHeli_machine_gun_fire_single",
---    ["attackLooped"] = "eHeli_machine_gun_fire_looped",
---    ["attackImpacts"] = "eHeli_fire_impact",
---    ["flightSound"] = "eMiliHeli", --LOOPED
---    ["crashEvent"] = "eHelicopterCrash",
---}

---@field announcerVoice string string ID of announcer, or false to disable, default: false

---@field randomEdgeStart boolean if the edge the event starts from will be random
--- default: true, false will force the edge to always be the closest

---@field speed number default: 1
---@field topSpeedFactor number speed x this = top "speed", default: 1.5
---@field flightVolume number range of flight sound to attract zombies, default: 75
---@field hostilePreference string default: false. 'false' for *none*, otherwise has to be 'IsoPlayer' or 'IsoZombie' or 'IsoGameCharacter'
---@field hostilePredicate function direct function reference, this has to be defined before (written above) it's used in a preset.
---@field attackDelay number delay in milliseconds between attacks, default: 60

---@field attackScope number number of rows from "center" IsoGridSquare out, default: 1
--- **area formula:** ((Scope*2)+1) ^2
--- scope:⠀0=1x1;⠀1=3x3;⠀2=5x5;⠀3=7x7;⠀4=9x9

---@field attackSpread number number of rows made of "scopes" from center-scope out, default: 3
---**formula for ScopeSpread area:**
---
---((Scope * 2)+1) * ((Spread * 2)+1) ^2
---
--- **Examples:**
---
---⠀  ⠀*scope* 🡇
--- -----------------------------------
--- *spread*⠀🡆 ⠀ | 00 | 01 | 02 | 03 |
--- -----------------------------------
--- ⠀  ⠀⠀⠀ ⠀| 00 | 01 | 09 | 25 | 49 |
--- -----------------------------------
--- ⠀  ⠀⠀⠀ ⠀| 01 | 09 | 81 | 225 | 441 |
--- -----------------------------------
--- ⠀  ⠀⠀⠀⠀  | 02 | 25 | 225 | 625 | 1225 |
--- -----------------------------------
--- ⠀  ⠀⠀⠀  ⠀| 03 | 49 | 441 | 1225 | 2401 |
--- -----------------------------------

---@field attackHitChance number multiplied against chance to hit in attacking, default: 85
---@field attackDamage number damage dealt to zombies/players on hit (gets randomized to: attackDamage * random(1 to 1.5)), default: 10

---=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=---

--- [ FILE HEADER ] --- FILE REQUIRES, AND SAFELY OVERWRITING/ADDING TO `eHelicopter_PRESETS`
--- This is required so that your sub-mod is loaded AFTER the original Expanded Helicopter Events
require "ExpandedHelicopter02a_Presets"
--- Additionally, if you want to modify or make use of an other sub-mod's presets you need to require their preset file.
-- require "SWH04_Presets" -- This is the filename for Super Weird Helis

--- This is also required before your presets are defined so presets are always adding onto the same table.
eHelicopter_PRESETS = eHelicopter_PRESETS or {}

--- TEMPLATE
--[[
eHelicopter_PRESETS["id_name"] = {
		variable = {values}
	}
]]

--- ALL PRESETS BELOW ARE COPIES OF THE VANILLA EVENTS, DO NOT INCLUDE THEM AGAIN IN YOUR SUB-MOD - THESE ARE LEFT HERE TO ACT AS EXAMPLES.
eHelicopter_PRESETS["military"] = {
    announcerVoice = true,
    forScheduling = true,
    crew = {"EHEMilitaryPilot", "EHESoldier", 75, "EHESoldier", 50},
    crashType = {"UH60GreenFuselage"},
    scrapItems = {"EHE.UH60Elevator", 1, "EHE.UH60WindowGreen", 1, "EHE.UH60DoorGreen", 1, "Base.ScrapMetal", 5},
    scrapVehicles = {"UH60GreenTail"},
    eventSpawnWeight = 20,
    schedulingFactor = 1.5,
    presetProgression = {
        ["patrol_only"] = 0,
        ["patrol_only_emergency"] = 0.0066,
        ["military_recon_hover"] = 0.0070,
        ["patrol_only_quarantine"] = 0.0165,
        ["attack_only_undead_evac"] = 0.033,
        ["attack_only_undead"] = 0.066,
        ["cargo_helicopter"] = 0.1900,
        ["attack_only_all"] = 0.2145,
    }
}

eHelicopter_PRESETS["patrol_only"] = {
    inherit = {"military"},
}


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
    formationIDs = {"attack_only_undead_evac", 25, {20,25}, "attack_only_undead_evac", 10, {20,25}},--"air_raid",
}

eHelicopter_PRESETS["attack_only_undead"] = {
    inherit = {"military"},
    announcerVoice = false,
    hostilePreference = "IsoZombie",
    formationIDs = {"attack_only_undead", 25, {12,17}, "attack_only_undead", 10, {12,17}},--"air_raid",
}

local function hostilePredicateNotMilitary(target)
    if not target then return end

    local militaryScore = 0
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
                        or item:getTags():contains("Military") then
                    militaryScore = militaryScore+1
                end
            end
        end
    end

    print("militaryScore: "..militaryScore)
    return militaryScore<3
end

eHelicopter_PRESETS["attack_only_all"] = {
    inherit = {"military"},
    announcerVoice = false,
    hostilePreference = "IsoGameCharacter",
    hostilePredicate = hostilePredicateNotMilitary,
    crashType = {"UH60GreenFuselage"},
    scrapItems = {"EHE.UH60Elevator", 1, "EHE.UH60WindowGreen", 1, "EHE.UH60DoorGreen", 1, "Base.ScrapMetal", 10},
    scrapVehicles = {"UH60GreenTail"},
    radioChatter = "AEBS_HostileMilitary",
    --formationIDs = {"air_raid"},
}

eHelicopter_PRESETS["cargo_helicopter"] = {
    inherit = {"military"},
    announcerVoice = false,
    crashType = false,
    crashType = {"UH60GreenFuselage"},
    scrapItems = {"EHE.UH60Elevator", 1, "EHE.UH60WindowGreen", 1, "EHE.UH60DoorGreen", 1, "Base.ScrapMetal", 10},
    eventSoundEffects = {
        ["flightSound"] = "eMiliHeliCargo",
    },
}

eHelicopter_PRESETS["military_recon_hover"] = {
    inherit = {"military"},
    announcerVoice = false,
    speed = 1.5,
    crashType = false,
    hoverOnTargetDuration = {200,400},
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
    formationIDs = {"patrol_only", 25, {12,17}, "patrol_only", 10, {12,17}},
    radioChatter = "AEBS_SupplyDrop",
    eventStartDayFactor = 0.034,
    eventCutOffDayFactor = 0.2145,
}


eHelicopter_PRESETS["jet"] = {
    speed = 15,
    topSpeedFactor = 2,
    flightVolume = 25,
    eventSoundEffects = {["flightSound"] = "eJetFlight"},
    crashType = false,
    shadow = false,
    eventMarkerIcon = "media/ui/jet.png",
    forScheduling = true,
    schedulingFactor = 4,
    eventSpawnWeight = 5,
    radioChatter = "AEBS_JetPass",
}

eHelicopter_PRESETS["air_raid"] = {
    doNotListForTwitchIntegration = true,
    crashType = false,
    shadow = false,
    speed = 0.5,
    topSpeedFactor = 3,
    flightVolume = 0,
    eventSoundEffects = {["flightSound"]="IGNORE",["soundAtEventOrigin"] = "eAirRaid"},
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
    doNotListForTwitchIntegration = true,
    speed = 18,
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
    ignoreContinueScheduling = true,
    radioChatter = "AEBS_JetBombing",
}

eHelicopter_PRESETS["news_chopper"] = {
    presetRandomSelection = {"news_chopper_hover", 1, "news_chopper_fleeing", 2, },
    eventSoundEffects = { ["additionalFlightSound"] = "eHeli_newscaster", ["flightSound"] = "eHelicopter", },
    speed = 1,
    crew = {"EHECivilianPilot", "EHENewsReporterVest", "EHENewsReporterVest", 40},
    crashType = {"Bell206LBMWFuselage"},
    scrapItems = {"EHE.Bell206HalfSkirt", "EHE.Bell206RotorBlade1", 2, "EHE.Bell206RotorBlade2", 2,  "EHE.Bell206TailBlade", 2, "Base.ScrapMetal", 10},
    scrapVehicles = {"Bell206LBMWTail"},
    forScheduling = true,
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
    presetRandomSelection = {"police_heli_emergency",3, "police_heli_firing",2},
    crashType = {"Bell206PoliceFuselage"},
    crew = {"EHEPolicePilot", "EHEPoliceOfficer", "EHEPoliceOfficer", 75},
    scrapItems = {"EHE.Bell206HalfSkirt", "EHE.Bell206RotorBlade1", 2, "EHE.Bell206RotorBlade2", 2,  "EHE.Bell206TailBlade", 2, "Base.ScrapMetal", 10},
    scrapVehicles = {"Bell206PoliceTail"},
    announcerVoice = "Police",
    eventSoundEffects = {
        ["foundTarget"] = "eHeli_PoliceSpotted",
    },
    forScheduling = true,
    eventStartDayFactor = 0.067,
    eventCutOffDayFactor = 0.22,
    radioChatter = "AEBS_UnauthorizedEntryPolice",
}

eHelicopter_PRESETS["police_heli_emergency"] = {
    inherit = {"police"},
    speed = 1.5,
    eventSoundEffects = {
        ["additionalFlightSound"] = "eHeliPoliceSiren",
        ["flightSound"] = "eHelicopter",
    },

}

eHelicopter_PRESETS["police_heli_firing"] = {
    inherit = {"police"},
    attackDelay = 1700,
    attackSpread = 4,
    speed = 1.0,
    attackHitChance = 95,
    attackDamage = 12,
    hostilePreference = "IsoZombie",
    eventSoundEffects = {
        ["attackSingle"] = "eHeliAlternatingShots",
        ["attackLooped"] = "eHeliAlternatingShots",
        ["additionalFlightSound"] = "eHeliPoliceSiren",
        ["flightSound"] = "eHelicopter",
    },
    hoverOnTargetDuration = {375,575},
}


eHelicopter_PRESETS["samaritan_drop"] = {
    crashType = false,
    crew = {"EHESurvivorPilot", 100, 0},
    dropPackages = {"SurvivorSupplyDrop"},
    speed = 1.0,
    eventMarkerIcon = "media/ui/jet.png",
    eventSoundEffects = {["flightSound"] = "ePropPlane"},
    forScheduling = true,
    eventCutOffDayFactor = 1,
    eventStartDayFactor = 0.48,
    eventSpawnWeight = 3,
    radioChatter = "AEBS_SamaritanDrop"
}


eHelicopter_PRESETS["survivor_heli"] = {
    speed = 1.5,
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


eHelicopter_PRESETS["raiders"] = {
    presetRandomSelection = {"raider_heli_passive",3,"raider_heli_harasser",1,"raider_heli_hostile",1},
    crashType = {"UH60GreenFuselage"},
    scrapItems = {"EHE.UH60Elevator", 1, "EHE.UH60WindowGreen", 1, "EHE.UH60DoorGreen", 1, "Base.ScrapMetal", 10},
    scrapVehicles = {"UH60GreenTail"},
    addedFunctionsToEvents = {["OnFlyaway"] = eHelicopter_dropTrash},
    crew = {"EHERaiderPilot", 100, 0, "EHERaider", 100, 0, "EHERaider", 100, 0, "EHERaider", 100, 0, "EHERaiderLeader", 75, 0},
    forScheduling = true,
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
        ["flightSound"] = "eMiliHeli",
        ["additionalFlightSound"] = "eHeliMusicPassive",
    },
}

eHelicopter_PRESETS["raider_heli_harasser"] = {
    inherit = {"raiders"},
    hoverOnTargetDuration = {450,850},
    speed = 2,
    attackDelay = 1000,
    attackSpread = 4,
    attackHitChance = 70,
    attackDamage = 50,
    flightVolume = 750,
    crashType = false,
    hostilePreference = "IsoZombie",
    eventSoundEffects = {
        ["flightSound"] = "eMiliHeli",
        ["attackSingle"] = "eHeliAlternatingShots",
        ["attackLooped"] = "eHeliAlternatingShots",
        ["additionalFlightSound"] = "eHeliMusicAggressive",
    },
}


eHelicopter_PRESETS["raider_heli_hostile"] = {
    inherit = {"raiders"},
    hoverOnTargetDuration = {650,1500},
    speed = 1.5,
    attackDelay = 650,
    attackSpread = 4,
    attackHitChance = 60,
    attackDamage = 10,
    flightVolume = 750,
    crashType = false,
    hostilePreference = "IsoPlayer",
    eventSoundEffects = {
        ["flightSound"] = "eMiliHeli",
        ["attackSingle"] = "eHeliAlternatingShots",
        ["attackLooped"] = "eHeliAlternatingShots",
        ["additionalFlightSound"] = "eHeliMusicAggressive",
    },
}
