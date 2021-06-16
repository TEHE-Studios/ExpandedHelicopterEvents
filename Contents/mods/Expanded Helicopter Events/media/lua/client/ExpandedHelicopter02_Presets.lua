---Preset list, only include variables being changed.
---variables can be found in Main file, at the top, fields = variables
eHelicopter_PRESETS = {
	["increasingly_hostile"] = {
		presetProgression = {
			["patrol_only"] = 0,
			["patrol_only_emergency"] = 0.02,
			["patrol_only_quarantine"] = 0.05,
			["attack_only_undead_evac"] = 0.1,
			["attack_only_undead"] = 0.15,
			["attack_only_all"] = 0.75,
		}
	},

	["jet"] = {
		randomEdgeStart = true,
		frequencyFactor = 0.33,
		speed = 3,
		topSpeedFactor = 2,
		flightVolume = 25,
		flightSound = "eJetFlight",
		crashType = false,
		shadow = false,
	},

	["news_chopper"] = {
		hoverOnTargetDuration = {1500,2250},
		--eventSoundEffects = {["hoverOverTarget"]="eHeli_newscaster"},
		frequencyFactor = 2,
		speed = 0.1,
		cutOffFactor = 0.5,
		crashType = {"Bell206LBMWCrashed"}
	},

	["patrol_only"] = {
		announcerVoice = true,
		crew = {"AirCrew", "AirCrew", 75, "AirCrew", 50},
	},

	-- EmergencyFlyer QuarantineFlyer EvacuationFlyer NoticeFlyer PreventionFlyer
	["patrol_only_emergency"] = {
		announcerVoice = true,
		dropItems = {["EmergencyFlyer"]=250},
		crew = {"1MilitaryPilot", "1Soldier", 75, "1Soldier", 50},
	},

	["patrol_only_quarantine"] = {
		announcerVoice = true,
		dropItems = {["QuarantineFlyer"]=250},
		crew = {"1MilitaryPilot", "1Soldier", 75, "1Soldier", 50},
	},

	["attack_only_undead_evac"] = {
		hostilePreference = "IsoZombie",
		dropItems = {["EvacuationFlyer"]=250},
		crew = {"1MilitaryPilot", "1Soldier", 75, "1Soldier", 50},
	},

	["attack_only_undead"] = {
		hostilePreference = "IsoZombie",
		crew = {"1MilitaryPilot", "1Soldier", 75, "1Soldier", 50},
	},

	["attack_only_all"] = {
		hostilePreference = "IsoGameCharacter",
		crashType = {"UH1Hsurvivalistcrash"},
		crew = {"1SurvivalistPilot", "1Survivalist", 75, "1Survivalist", 50},
		cutOffFactor = 1.5,
	},

	["police_heli"] = {
		announcerVoice = false,
		attackDelay = 1100,
		cutOffFactor = 0.67,
		speed = 0.12,
		crashType = {"Bell206PoliceCrashed"},
		crew = {"1PolicePilot", "1PoliceOfficer", "1PoliceOfficer", 75},
		hostilePreference = "IsoZombie",
		eventSoundEffects = {
			["attackSingle"] = "eHeli_bolt_action_fire_singleshot",
			["attackLooped"] = "eHeli_bolt_action_fire_singleshot",
			["attackImpacts"] = {"eHeli_fire_impact1", "eHeli_fire_impact2", "eHeli_fire_impact3",  "eHeli_fire_impact4", "eHeli_fire_impact5"}
		}
	},

	["aid_helicopter"] = {
		announcerVoice = false,
		crashType = {"UH1Hmedevaccrash"},
		crew = {"1MilitaryPilot", "1Soldier", 100, "1Soldier", 100},
		dropPackages = {"FEMASupplyDrop"},
		dropItems = {["NoticeFlyer"]=250},
		cutOffFactor = 0.43,
	},

	["increasingly_helpful"] = {
		presetProgression = {
			["patrol_only"] = 0,
			["aid_helicopter"] = 0.25,
		}
	},
}


--- Under The Hood ---

---@param tableToLoadFrom table
---@param alternateTable table
function eHelicopter:loadVarsFrom(tableToLoadFrom, alternateTable, debugID)
	for var, value in pairs(tableToLoadFrom) do
		local newValue

		if (alternateTable and (alternateTable[var] ~= nil)) then
			newValue = alternateTable[var]
		else
			newValue = value
		end
		--[DEBUG]] print(" -"..debugID..": "..var.." =  ("..type(newValue)..")"..tostring(newValue))
		--tables needs to be copied piece by piece to avoid direct references links
		if type(newValue) == "table" then
			--[DEBUG]] print("--- "..var.." is a table (#"..#newValue.."); generating copy:")
			local tmpTable = {}
			for k,v in pairs(newValue) do
				tmpTable[k] = v
				--[DEBUG]] print( "------ "..k.." = ".."("..type(v)..") "..tostring(v))
			end
			self[var] = tmpTable
		else
			self[var] = newValue
		end
	end
end


function eHelicopter:randomSelectPreset(preset)
	local selection = preset.presetRandomSelection
	local pool = {}

	for key,entry in pairs(selection) do
		if type(entry) == "string" then
			local id = entry
			local iterations = 1
			local next = selection[key+1]
			if type(next) == "number" then
				iterations = next
			end

			for i=1, iterations do
				table.insert(pool, id)
			end
		end
	end

	local randomNum = ZombRand(#pool)+1
	local choice = pool[randomNum]

	print("randomSelectPreset:   pool size: "..#pool.."   choice: "..choice)

	return eHelicopter_PRESETS[choice]
end


function eHelicopter:progressionSelectPreset(preset)
	local pp = preset.presetProgression
	if pp then
		local DaysSinceApoc = getGameTime():getModData()["DaysBeforeApoc"]+getGameTime():getNightsSurvived()
		local cutOff = preset.cutOffFactor or eHelicopter.cutOffFactor
		local CutOffDay = cutOff*eHelicopterSandbox.config.cutOffDay
		local DaysOverCutOff = DaysSinceApoc/CutOffDay
		local presetIDTmp
		--run through presetProgression list
		for pID,pCutOff in pairs(pp) do
			--if progression % is less than DaysOverCutOff
			if pCutOff <= DaysOverCutOff then
				--if there is no stored % or progression % > stored %
				if (not presetIDTmp) or (presetIDTmp and (pCutOff > pp[presetIDTmp])) then
					--store qualifying choice
					presetIDTmp = pID
				end
			end
		end
		if presetIDTmp then
			return eHelicopter_PRESETS[presetIDTmp]
		end
	end
end


function eHelicopter:recursivePresetCheck(preset, iteration)
	iteration = iteration or 0
	print("EHE: recursivePresetCheck: ")
	if preset.presetRandomSelection then
		print("  EHE: presetRandomSelection: found")
		preset = self:randomSelectPreset(preset)
	end

	if preset.presetProgression then
		print("  EHE: presetProgression: found")
		preset = self:progressionSelectPreset(preset)
	end

	if (preset.presetProgression or preset.presetRandomSelection) and (iteration < 4) then
		print("  EHE: progression/selection: found; recursive: "..iteration)
		self:recursivePresetCheck(preset,iteration+1)
	end

	return preset
end


---@param ID string
function eHelicopter:loadPreset(ID)

	if not ID then
		return
	end

	local preset = eHelicopter_PRESETS[ID]

	if not preset then
		return
	end

	preset = self:recursivePresetCheck(preset)

	--use initial list of variables to reset the helicopter object to standard
	--[DEBUG]] print("loading preset: "..ID.."  vars:")
	--compare vars against initialVars and loaded preset
	self:loadVarsFrom(eHelicopter_initialVars, preset, "initialVars")
	--reset other vars not included with initialVars
	self:loadVarsFrom(eHelicopter_temporaryVariables, nil, "temporaryVariables")
end
