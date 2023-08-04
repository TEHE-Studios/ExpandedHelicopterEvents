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
---@field targetIntensityThreshold number factor difference of target intensity needed to change course, default 1.25, false = can't change course
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
---{ ["OnLaunch"] = false, ["OnCrash"] = false, ["OnHover"] = false, ["OnFlyaway"] = false, ["OnAttack"] = false, ["OnSpawnCrew"] = false, ["OnArrived"] = false}

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
---default: {["flightSound"]=true}

---@field eventSoundEffects table table of additional soundeffectIDs with corresponding "IGNORE" or sound filenames
---These can also be tables unto themselves - each entry gets played.
---default:
---eHelicopter.eventSoundEffects = {
---    ["hoverOverTarget"]="IGNORE",
---    ["flyOverTarget"]="IGNORE",
---    ["lostTarget"]="IGNORE",
---    ["foundTarget"]="IGNORE",
---    ["droppingPackage"]="IGNORE",
---    ["attackingSound"]="IGNORE",
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

---@field attackSplash number number of tiles from attack point that damage can be process on (will hit all targets with in this range), default = 0
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


--- DO NOT LEAVE THESE IN YOUR FILE THEY ARE HERE AS AN EXAMPLE
------ (COPIED HERE: 8/11/22 - Won't be updated unless system changes are made.

---This is a `function` that is defined above a preset that calls on it.
---@param heli eHelicopter will refer to the heli object itself
local function eHelicopter_dropTrash(heli)

    local heliX, heliY, _ = heli:getXYZAsInt()
    local trashItems = {"MayonnaiseEmpty","SmashedBottle","Pop3Empty","PopEmpty","Pop2Empty","WhiskeyEmpty","BeerCanEmpty","BeerEmpty"}
    local iterations = 10

    for i=1, iterations do

        heliY = heliY+ZombRand(-2,3)
        heliX = heliX+ZombRand(-2,3)

        local trashType = trashItems[(ZombRand(#trashItems)+1)]
        --more likely to drop the same thing
        table.insert(trashItems, trashType)

        SpawnerTEMP.spawnItem(trashType, heliX, heliY, 0, {"ageInventoryItem"}, nil, "getOutsideSquareFromAbove")
    end
end


--- Main raiders preset - it has a `presetRandomSelection` that selects one of the presets in that table
--- The number after the preset name accounts for "weight" for random selection.
eHelicopter_PRESETS["raiders"] = {
    presetRandomSelection = {"raider_heli_passive",3,"raider_heli_hostile",1},
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

--- "raider_heli_passive" preset, that inherits from "raiders"
--- When a preset inherits another it gets that preset's variables applied first, each entry in inherit gets applied in order.
--- For "raider_heli_passive", it inherits all of "raiders" variables, before speed/flightVolume/crashType/eventSoundEffects get overwritten.
eHelicopter_PRESETS["raider_heli_passive"] = {
    inherit = {"raiders"},
    speed = 0.5,
    flightVolume = 750,
    crashType = false,
    eventSoundEffects = {
        ["flightSound"] = { "eMiliHeli", "eHeliMusicPassive" },
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
        ["flightSound"] = { "eMiliHeli", "eHeliMusicHostile" },
        ["attackSingle"] = "eHeliAlternatingShots",
        ["attackLooped"] = "eHeliAlternatingShots",
    },
}