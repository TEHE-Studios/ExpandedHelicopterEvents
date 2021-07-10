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

	if not choice then
		print(" -- ERR: No choice selected in randomSelectPreset")
		return preset
	end

	print(" -- randomSelectPreset:   pool size: "..#pool.."   choice: "..choice)

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
			print(" -- progressionSelectPreset:  selection: "..presetIDTmp)
			return eHelicopter_PRESETS[presetIDTmp]
		end
	end
end


function eHelicopter:recursivePresetCheck(preset, iteration)
	iteration = iteration or 0
	print(" - EHE: recursivePresetCheck: ")
	if preset.presetRandomSelection then
		print(" -- EHE: presetRandomSelection: found")
		preset = self:randomSelectPreset(preset)
	end

	if preset.presetProgression then
		print(" -- EHE: presetProgression: found")
		preset = self:progressionSelectPreset(preset)
	end

	if (preset.presetProgression or preset.presetRandomSelection) and (iteration < 4) then
		print(" -- EHE: progression/selection: found; recursive: "..iteration)
		return self:recursivePresetCheck(preset,iteration+1)
	end

	if iteration >= 4 then
		print(" -- EHE: ERR: progression/selection: high recursive iteration: "..iteration)
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

	self:stopAllHeldEventSounds()
	preset = self:recursivePresetCheck(preset)
	for id,vars in pairs(eHelicopter_PRESETS) do if vars == preset then ID = id end end print(" -- loading preset: "..ID)
	--compare vars against initialVars and loaded preset
	self:loadVarsFrom(eHelicopter_initialVars, preset, "initialVars")
	--reset other vars not included with initialVars
	self:loadVarsFrom(eHelicopter_temporaryVariables, nil, "temporaryVariables")

	self.currentPresetID = ID
end