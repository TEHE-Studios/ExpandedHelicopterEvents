---@param table table
function eHelicopter.recursiveTableCopy(table)
	local tmpTable = {}

	for k,v in pairs(table) do
		if type(v) == "table" then
			tmpTable[k] = eHelicopter.recursiveTableCopy(v)
		else
			tmpTable[k] = v
		end
		--[DEBUG]] print(k.." = ".."("..type(v)..") "..tostring(v))
	end

	return tmpTable
end


---@param tableToLoadFrom table
function eHelicopter:loadVarsFrom(tableToLoadFrom, DEBUG_ID)
	--[DEBUG]] print("-- loadVarsFrom: "..DEBUG_ID)
	--[DEBUG]] local debugPrint = ""
	for var, value in pairs(tableToLoadFrom) do
		local newValue
		local ignore = ((var=="presetProgression") or (var=="presetRandomSelection") or (var=="inherit"))

		if not ignore then
			newValue = value
			--tables needs to be copied piece by piece to avoid direct references links
			if type(newValue) == "table" then
				--[DEBUG]] debugPrint = debugPrint..("--- "..var.." is a table (#"..#newValue.."); generating copy:\n")
				self[var] = eHelicopter.recursiveTableCopy(newValue)
			else
				--[DEBUG]] debugPrint = debugPrint..("-- "..var..": "..tostring(newValue).."\n")
				self[var] = newValue
			end
		end
	end
	--[DEBUG]] if DEBUG_ID~="initialVars" and DEBUG_ID~="temporaryVars" then print(debugPrint) end
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

		local globalModData = getExpandedHeliEventsModData()
		local DaysSinceApoc = globalModData.DaysBeforeApoc+getGameTime():getNightsSurvived()
		local startDay, cutOffDay = fetchStartDayAndCutOffDay(preset)
		local DaysOverCutOff = DaysSinceApoc/cutOffDay
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


function eHelicopter:recursivePresetCheck(preset, iteration, recursiveID)
	iteration = iteration or 0
	--Load preset vars
	self:loadVarsFrom(preset, "presetLoad:"..tostring(recursiveID))

	--[[DEBUG]] local rpcText
	if preset.presetRandomSelection then
		preset = self:randomSelectPreset(preset)
		local presetID
		for id,vars in pairs(eHelicopter_PRESETS) do
			if vars == preset then
				presetID = id
			end
		end
		self:loadVarsFrom(preset, "-- presetRand:"..tostring(presetID))
	end

	if preset.presetProgression then
		preset = self:progressionSelectPreset(preset)
		local presetID
		for id,vars in pairs(eHelicopter_PRESETS) do
			if vars == preset then
				presetID = id
			end
		end
		self:loadVarsFrom(preset, "-- presetProg:"..tostring(presetID))
	end

	if (preset.presetProgression or preset.presetRandomSelection) and (iteration < 4) then
		--[[DEBUG]] rpcText = rpcText.."\n -- EHE: progression/selection: found; recursive: "..iteration
		--[[DEBUG]] print(rpcText)
		local presetID
		for id,vars in pairs(eHelicopter_PRESETS) do
			if vars == preset then
				presetID = id
			end
		end
		return self:recursivePresetCheck(preset,iteration+1, presetID)
	end

	--[[DEBUG]] if iteration >= 4 then rpcText = rpcText.."\n -- EHE: ERR: progression/selection: high recursive iteration: "..iteration end
	--[[DEBUG]] if rpcText then print(rpcText) end

	return preset
end


---@param ID string
function eHelicopter:loadPreset(ID)

	if not ID then
		return
	end

	local preset = eHelicopter_PRESETS[ID]
	local masterID = ID

	if not preset then
		return
	end

	eventSoundHandler:stopAllHeldEventSounds(self)
	--[DEBUG]] print("\n------------[loadPreset:"..ID.."]------------")
	self:loadVarsFrom(eHelicopter_initialVars, "initialVars")
	if preset.inherit then
		for k,inheritedPresetID in pairs(preset.inherit) do
			local presetFound = eHelicopter_PRESETS[inheritedPresetID]
			if presetFound then
				self:loadVarsFrom(presetFound, "presetInherited")
			end
		end
	end
	preset = self:recursivePresetCheck(preset, nil, masterID)
	--reset other vars not included with initialVars
	self:loadVarsFrom(eHelicopter_temporaryVariables, "temporaryVars")
	for id,vars in pairs(eHelicopter_PRESETS) do
		if vars == preset then
			ID = id
		end
	end
	self.currentPresetID = ID
	self.masterPresetID = masterID

	--[[DEBUG]
	print("=-=-=-=-=-=-=[Confirming]=-=-=-=-=-=-=-=")
	for var, _ in pairs(eHelicopter_initialVars) do print(" - "..var.." = "..tostring(self[var])) end
	for var, _ in pairs(eHelicopter_temporaryVariables) do print(" - "..var.." = "..tostring(self[var])) end
	print("=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=")
	--]]
end