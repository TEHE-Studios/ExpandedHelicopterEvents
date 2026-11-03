eHelicopter = {}
---CHECK THE PRESETGUIDE FILE IN /SHARED/ FOR MORE INFORMATION
eHelicopter.forScheduling = false
eHelicopter.schedulingFactor = 1
eHelicopter.eventSpawnWeight = 10
eHelicopter.eventStartDayFactor = 0
eHelicopter.doNotListForTwitchIntegration = false
eHelicopter.ignoreContinueScheduling = false
eHelicopter.eventSpecialDates = false
eHelicopter.eventCutOffDayFactor = 0.34
eHelicopter.radioChatter = "AEBS_Choppah"
eHelicopter.flightHours = {5, 22}
eHelicopter.targetIntensityThreshold = 1.25
eHelicopter.hoverOnTargetDuration = false
eHelicopter.searchForTargetDuration = 30000
eHelicopter.shadow = true
eHelicopter.shadowTexture = "helicopter_shadow"
eHelicopter.markerColor = {r=1,g=1,b=1}
eHelicopter.eventMarkerIcon = "media/ui/helievent.png"
eHelicopter.crashType = {"UH1HFuselage"}
eHelicopter.addedCrashChance = 0
eHelicopter.addedFunctionsToEvents = false --{ ["OnLaunch"] = false, ["OnCrash"] = false, ["OnHover"] = false, ["OnFlyaway"] = false, ["OnAttackHit"] = false, ["OnAttack"] = false, ["OnSpawnCrew"] = false, ["OnArrived"] = false}
eHelicopter.scrapVehicles = {"UH1HTail"} --{"Base.TYPE","Base.TYPE"}
eHelicopter.scrapItems = {"EHE.UH1HHalfSkirt", "EHE.UH1HRotorBlade", 2, "EHE.Bell206TailBlade", 2, "Base.ScrapMetal", 10}
eHelicopter.crew = {"AirCrew", 100}
eHelicopter.formationIDs = {}
eHelicopter.dropItems = false
eHelicopter.dropPackages = false
eHelicopter.looperEventIDs = {["flightSound"]=true}
eHelicopter.eventSoundEffects = {
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

eHelicopter.announcerVoice = false
eHelicopter.randomEdgeStart = true
eHelicopter.inherit = false
eHelicopter.presetProgression = false
eHelicopter.presetRandomSelection = false
eHelicopter.speed = 1
eHelicopter.topSpeedFactor = 1.5
eHelicopter.flightVolume = 75
eHelicopter.hostilePreference = false
eHelicopter.hostilePredicate = false
eHelicopter.attackDelay = 60
eHelicopter.attackScope = 1
eHelicopter.attackSpread = 3
eHelicopter.attackSplash = 0
eHelicopter.attackHitChance = 85
eHelicopter.attackDamage = 10

---// UNDER THE HOOD STUFF //---

---This function, when called stores the above listed variables, on game load, for reference later
---
---NOTE: Any variable which is by default `nil` can't be loaded over - consider making it false if you need it
---@param listToSaveTo table
---@param checkIfNotIn table
function eHelicopter_variableBackUp(listToSaveTo, checkIfNotIn)--, debugID)
	for k,v in pairs(eHelicopter) do
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
eHelicopter_initialVars = {}
eHelicopter_variableBackUp(eHelicopter_initialVars, nil, "initialVars")

--the below variables are to be considered "temporary"
---@field forceUnlaunchTime table|boolean table of day,hour | false when not set
eHelicopter.forceUnlaunchTime = false
---@field height number
eHelicopter.height = 7
---@field state string
eHelicopter.state = false
---@field crashing
eHelicopter.crashing = false
---@field timeUntilCanAnnounce number
eHelicopter.timeUntilCanAnnounce = -1
---@field preflightDistance number
eHelicopter.preflightDistance = false
---@field lastAnnouncedLine string
eHelicopter.lastAnnouncedLine = false
---@field heldEventSoundEffectEmitters table
eHelicopter.heldEventSoundEffectEmitters = {}
---@field placedEventSoundEffectEmitters table
eHelicopter.placedEventSoundEffectEmitters = {}
---@field delayedEventSounds table
eHelicopter.delayedEventSounds = {}
---@field target IsoObject
eHelicopter.target = false
---@field trueTarget IsoGameCharacter
eHelicopter.trueTarget = false
---@field timeSinceLastSeenTarget number
eHelicopter.timeSinceLastSeenTarget = -1
---@field timeSinceLastRoamed number
eHelicopter.timeSinceLastRoamed = -1
---@field attackDistance number
eHelicopter.attackDistance = false
---@field targetPosition Vector3 "position" of target, pair of coordinates which can utilize Vector3 math
eHelicopter.targetPosition = false
---@field lastMovement Vector3 consider this to be velocity (direction/angle and speed/step-size)
eHelicopter.lastMovement = false
---@field currentPosition Vector3 consider this a pair of coordinates which can utilize Vector3 math
eHelicopter.currentPosition = false
---@field lastAttackTime number
eHelicopter.lastAttackTime = -1
---@field hostilesToFireOnIndex number
eHelicopter.hostilesToFireOnIndex = 0
---@field hostilesToFireOn table
eHelicopter.hostilesToFireOn = {}
---@field hostilesAlreadyFiredOn table
eHelicopter.hostilesAlreadyFiredOn = {}
---@field lastScanTime number
eHelicopter.lastScanTime = -1
---@field formationFollowingHelis table table of actual flying helis
eHelicopter.formationFollowingHelis = {}
---@field currentPresetID string
eHelicopter.currentPresetID = "<none>"
---@field masterPresetID string
eHelicopter.masterPresetID = false--"<none>"

--This stores the above "temporary" variables for resetting eHelicopters later
eHelicopter_temporaryVariables = {}
eHelicopter_variableBackUp(eHelicopter_temporaryVariables, eHelicopter_initialVars, "temporaryVariables")

--ID must not be reset ever
---@field ID number
eHelicopter.ID = 0


---returns heli's ID and preset; optionally: returns location's x and y
---@param location boolean return x and y coords with ID and preset
function eHelicopter:heliToString(location)

	local selfIDPresetState = self.ID.." ("..self.currentPresetID..") ["..tostring(self.state).."]"
	local returnString = "HELI "

	if self==eHelicopter then
		returnString = returnString.." SYSTEM"
	else
		returnString = returnString..selfIDPresetState
	end

	if location then
		local h_x, h_y, _ = self:getXYZAsInt()
		if h_x and h_y then
			returnString = returnString.." (x:"..h_x..", y:"..h_y..")"
		else
			returnString = returnString.." (x:?, y:?)"
		end
	end
	return returnString
end


function eHelicopter:hoverAndFlyOverReport(STATE)
	if self.trueTarget and self.trueTarget:getClass() and self.target and self.target:getClass() then

		local additionalDebug = ""
		if getDebug() then
			if self.trueTarget then additionalDebug = " tT:"..self.trueTarget:getClass():getSimpleName() end
			if self.target then additionalDebug = additionalDebug.." t:"..self.target:getClass():getSimpleName() end
		end

		print(" - "..self:heliToString(true).." "..STATE..additionalDebug)
	end
end


--- Debug: Reports helicopter's useful variables -- note: this will flood your output
function eHelicopter:Report(aiming, dampen)
	---@type eHelicopter heli
	local report = " a:"..tostring(aiming).." d:"..tostring(dampen).." "
	print(" > "..self:heliToString(true))
	print("   TARGET: (x:"..Vector3GetX(self.targetPosition)..", y:"..Vector3GetY(self.targetPosition)..")")
	print("   (dist: "..self:getDistanceToVector(self.target).."  "..report)
	print("-----------------------------------------------------------------")
end