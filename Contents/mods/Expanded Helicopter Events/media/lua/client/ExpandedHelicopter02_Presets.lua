---Preset list, only include variables being changed.
eHelicopter_PRESETS = {
	["increasingly_hostile"] = {
		presetProgression = {["patrol_only"] = 0, ["attack_only_undead"] = 0.15, ["attack_only_all"] = 0.75}
	},

	["jet"] = {
		randomEdgeStart = true,
		frequencyFactor = 0.33,
		speed = 3,
		topSpeedFactor = 2,
		flightVolume = 25,
		flightSound = "eJetFlight",
		hostilePreference = false,
		announcerVoice = false
	},

	["news_chopper"] = {
		hoverOnTargetDuration = ZombRand(1500,2250),
		--eventSoundEffects = {["hoverOverTarget"]="eHeli_newscaster"},
		frequencyFactor = 2,
		speed = 0.2,
		topSpeedFactor = 5,
		hostilePreference = false,
		announcerVoice = false,
		cutOffDay = 15
	},

	["patrol_only"] = {
		hostilePreference = false
	},

	["attack_only_undead"] = {
		announcerVoice = false
	},

	["attack_only_all"] = {
		announcerVoice = false,
		hostilePreference = "IsoGameCharacter"
	},
}


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


---@param ID string
function eHelicopter:loadPreset(ID)

	if not ID then
		return
	end

	local preset = eHelicopter_PRESETS[ID]

	if not preset then
		return
	end

	local pp = preset.presetProgression
	if pp then
		local DaysSinceApoc = getGameTime():getModData()["DaysBeforeApoc"]+getGameTime():getNightsSurvived()
		local CutOff = preset.cutOffDay or eHelicopter.cutOffDay
		local DaysOverCutOff = DaysSinceApoc/CutOff
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
			--replace original preset with qualifying preset
			ID = presetIDTmp
			preset = eHelicopter_PRESETS[ID]
		end
	end

	--use initial list of variables to reset the helicopter object to standard
	--[DEBUG]] print("loading preset: "..ID.."  vars:")
	--compare vars against initialVars and loaded preset
	self:loadVarsFrom(eHelicopter_initialVars, preset, "initialVars")
	--reset other vars not included with initialVars
	self:loadVarsFrom(eHelicopter_temporaryVariables, nil, "temporaryVariables")
end
