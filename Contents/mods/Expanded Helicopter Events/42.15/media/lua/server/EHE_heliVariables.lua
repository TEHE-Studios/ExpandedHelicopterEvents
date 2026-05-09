local vars = {}
---CHECK THE PRESETGUIDE FILE IN /SHARED/ FOR MORE INFORMATION
vars.forScheduling = false
-- eventSpawnWeight and schedulingFactor accept {base, dropOff, minimum} for window-based tapering
-- e.g. schedulingFactor = {50, 0.9, 1.5}  means: start at 50, drop 90% to floor 1.5 by cutOffDay
vars.schedulingFactor = 1
vars.eventSpawnWeight = 10
vars.eventStartDayFactor = 0
vars.doNotListForStreamerIntegration = false
vars.ignoreContinueScheduling = false
vars.eventSpecialDates = false
vars.eventCutOffDayFactor = 0.34
vars.radioChatter = "AEBS_Choppah"
vars.flightHours = { 5, 22}
vars.targetIntensityThreshold = 1.25
vars.hoverOnTargetDuration = false
vars.searchForTargetDuration = 30000
vars.shadow = true
vars.shadowTexture = "helicopter_shadow"
vars.markerColor = { r=1, g=1, b=1}
vars.eventMarkerIcon = "media/ui/helievent.png"
vars.crashType = { "UH1HFuselage"}
vars.addedCrashChance = 0
vars.addedFunctionsToEvents = false --{ ["OnLaunch"] = false, ["OnCrash"] = false, ["OnHover"] = false, ["OnFlyaway"] = false, ["OnAttackHit"] = false, ["OnAttack"] = false, ["OnSpawnCrew"] = false, ["OnArrived"] = false}
vars.scrapVehicles = { "UH1HTail"} --{"Base.TYPE","Base.TYPE"}
vars.scrapItems = { "EHE.UH1HHalfSkirt", "EHE.UH1HRotorBlade", 2, "EHE.Bell206TailBlade", 2, "Base.ScrapMetal", 10}
vars.crew = { { outfit="AirCrew"} }
vars.formationIDs = {}
vars.dropItems = false
vars.dropPackages = false
vars.looperEventIDs = { ["flightSound"]=true}
vars.eventSoundEffects = {
	["hoverOverTarget"]="IGNORE",
	["flyOverTarget"]="IGNORE",
	["lostTarget"]="IGNORE",
	["foundTarget"]="IGNORE",
	["droppingPackage"]="IGNORE",
	["attackingSound"]="IGNORE",
	["soundAtEventOrigin"]="IGNORE",
	--
	["attackSingle"] = "eHeli_machine_gun_fire_single",
	["attackLooped"] = "eHeli_machine_gun_fire_looped",
	["attackImpacts"] = "eHeli_fire_impact",
	["flightSound"] = "eMiliHeli",--LOOP
	["crashEvent"] = "eHelicopterCrash",
}

vars.announcerVoice = false
vars.randomEdgeStart = true
vars.inherit = false
vars.presetProgression = false
vars.presetRandomSelection = false
vars.speed = 1
vars.topSpeedFactor = 1.5
vars.flightVolume = 75
vars.hostilePreference = false
vars.hostilePredicate = false
vars.attackDelay = 60
vars.attackScope = 1
vars.attackSpread = 3
vars.attackSplash = 0
vars.attackHitChance = 85
vars.attackDamage = 10

---// UNDER THE HOOD STUFF //---

---This function, when called stores the above listed variables, on game load, for reference later
---
---NOTE: Any variable which is by default `nil` can't be loaded over - consider making it false if you need it
---@param listToSaveTo table
---@param checkIfNotIn table
function vars.variableBackUp(listToSaveTo, checkIfNotIn)--, debugID)
	for k,v in pairs(vars) do
		if ((not checkIfNotIn) or (checkIfNotIn[k] == nil)) then
			--[DEBUG]] print("EHE: "..debugID..": "..k.." = ".."("..type(v)..") "..tostring(v))
			--tables have to be copied piece by piece or risk creating a direct reference link
			if type(v) == "table" then
				--[DEBUG]] print("--- "..k.." is a table (#"..#v.."); generating copy:")
				local tmpTable = {}
				for kk,vv in pairs(v) do
					--[DEBUG]] print( "------ "..kk.." = ".."("..type(vv)..") "..tostring(vv))
					tmpTable[kk] = vv
				end
				listToSaveTo[k]=tmpTable
			else
				listToSaveTo[k]=v
			end
		end
	end
end

--store "initial" vars to reference when loading presets
vars.initialVars = {}
vars.variableBackUp(vars.initialVars, nil, "initialVars")

--the below variables are to be considered "temporary"
---@field forceUnlaunchTime table|boolean table of day,hour | false when not set
vars.forceUnlaunchTime = false
---@field height number
vars.height = 7
---@field state string
vars.state = false
---@field crashing
vars.crashing = false
---@field timeUntilCanAnnounce number
vars.timeUntilCanAnnounce = -1
---@field preflightDistance number
vars.preflightDistance = false
---@field lastAnnouncedLine string
vars.lastAnnouncedLine = false
---@field heldEventSoundEffectEmitters table
vars.heldEventSoundEffectEmitters = {}
---@field placedEventSoundEffectEmitters table
vars.placedEventSoundEffectEmitters = {}
---@field delayedEventSounds table
vars.delayedEventSounds = {}
---@field target IsoObject
vars.target = false
---@field trueTarget IsoGameCharacter
vars.trueTarget = false
---@field timeSinceLastSeenTarget number
vars.timeSinceLastSeenTarget = -1
---@field timeSinceLastRoamed number
vars.timeSinceLastRoamed = -1
---@field attackDistance number
vars.attackDistance = false
---@field targetPosition Vector3 "position" of target, pair of coordinates which can utilize Vector3 math
vars.targetPosition = false
---@field lastMovement Vector3 consider this to be velocity (direction/angle and speed/step-size)
vars.lastMovement = false
---@field currentPosition Vector3 consider this a pair of coordinates which can utilize Vector3 math
vars.currentPosition = false
---@field lastAttackTime number
vars.lastAttackTime = -1
---@field hostilesToFireOnIndex number
vars.hostilesToFireOnIndex = 0
---@field hostilesToFireOn table
vars.hostilesToFireOn = {}
---@field hostilesAlreadyFiredOn table
vars.hostilesAlreadyFiredOn = {}
---@field lastScanTime number
vars.lastScanTime = -1
---@field formationFollowingHelis table table of actual flying helis
vars.formationFollowingHelis = {}
---@field currentPresetID string
vars.currentPresetID = "<none>"
---@field masterPresetID string
vars.masterPresetID = false--"<none>"

--This stores the above "temporary" variables for resetting eHelicopters later
vars.temporaryVariables = {}
vars.variableBackUp(vars.temporaryVariables, vars.initialVars, "temporaryVariables")

--ID must not be reset ever
---@field ID number
vars.ID = 0

---@param HelicopterOrPreset table
---@return number startDay
---@return number cutOffDay
function vars.fetchStartDayAndCutOffDay(HelicopterOrPreset)
	local startDayFactor = HelicopterOrPreset.eventStartDayFactor or vars.eventStartDayFactor
	local startDay = math.floor((startDayFactor * SandboxVars.ExpandedHeli.SchedulerDuration) + 0.5)
	startDay = math.max(startDay, SandboxVars.ExpandedHeli.StartDay)
	local cutOffDayFactor = HelicopterOrPreset.eventCutOffDayFactor or vars.eventCutOffDayFactor
	local cutOffDay = math.floor((cutOffDayFactor * (startDay + SandboxVars.ExpandedHeli.SchedulerDuration)) + 0.5)
	return startDay, cutOffDay
end


return vars