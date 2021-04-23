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
			preset = eHelicopter_PRESETS[presetIDTmp]
		end
	end

	--local reportPreset = "loading preset: "..ID.."  vars:"
	for var,value in pairs(preset) do
		--reportPreset = reportPreset.." -"..var.." = "..tostring(value)
		self[var] = value
	end
	--print(reportPreset)
end


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
		hoverOnTargetDuration = ZombRand(15,20),
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
