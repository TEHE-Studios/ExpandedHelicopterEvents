local util = require("EHE_util.lua")

local eHelicopter = isServer() and require("EHE_mainVariables.lua")
local modData = isServer() and require("EHE_globalModData.lua")
local mainCore = isServer() and require("EHE_mainCore.lua")

local presetCore = {}

presetCore.PRESETS = {}

function presetCore.registerPreset(ID,table)
	presetCore.PRESETS[ID] = table
end

function presetCore.alterSpecificParameter(ID,param,value)
	if not presetCore.PRESETS[ID] then print("ERROR: preset ", ID, "not found - attempted to set", param, "to ", tostring(value)) return end
	if not presetCore.PRESETS[ID][param] then print("ERROR: param ", param, " for preset ", ID, "not found - attempted to set to ", tostring(value)) return end
	presetCore.PRESETS[ID][param] = value
end

---@param table table
function presetCore.recursiveTableCopy(table)
	local tmpTable = {}

	for k,v in pairs(table) do
		if type(v) == "table" then
			tmpTable[k] = presetCore.recursiveTableCopy(v)
		else
			tmpTable[k] = v
		end
		--[DEBUG]] print(k.." = ".."("..type(v)..") "..tostring(v))
	end

	return tmpTable
end


---@param tableToLoadFrom table
function presetCore:loadVarsFrom(tableToLoadFrom, DEBUG_ID)
	if not tableToLoadFrom then return end
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
				self[var] = presetCore.recursiveTableCopy(newValue)
			else
				--[DEBUG]] debugPrint = debugPrint..("-- "..var..": "..tostring(newValue).."\n")
				self[var] = newValue
			end
		end
	end
	--[DEBUG]] if DEBUG_ID~="initialVars" and DEBUG_ID~="temporaryVars" then print(debugPrint) end
end


function presetCore:randomSelectPreset(preset)
	local selection = preset.presetRandomSelection
	local pool = {}

	for key,entry in ipairs(selection) do
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

	return presetCore.PRESETS[choice]
end


function presetCore:progressionSelectPreset(preset)

	local pp = preset.presetProgression
	if pp then

		local globalModData = modData.get()
		local DaysSinceApoc = globalModData.DaysBeforeApoc+util.getWorldAgeDays()
		local startDay, cutOffDay = mainCore.fetchStartDayAndCutOffDay(preset)
		if not cutOffDay or cutOffDay <= 0 then return end
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
			return presetCore.PRESETS[presetIDTmp]
		end
	end
end


function presetCore:recursivePresetCheck(preset, iteration, recursiveID)
	iteration = iteration or 0
	--Load preset vars
	self:loadVarsFrom(preset, "presetLoad:"..tostring(recursiveID))

	if preset.presetRandomSelection then
		local randSelect = self:randomSelectPreset(preset)
		if not randSelect then
			print("ERROR: Preset:",preset," failed `randomSelectPreset`.")
		else
			preset = randSelect

			local presetID
			for id,vars in pairs(presetCore.PRESETS) do
				if vars == preset then
					presetID = id
				end
			end
			self:loadVarsFrom(preset, "-- presetRand:"..tostring(presetID))
		end
	end

	if preset.presetProgression then
		local progressSelect = self:progressionSelectPreset(preset)
		if not progressSelect then
			print("ERROR: Preset:",preset," failed `progressionSelectPreset`.")
		else
			preset = progressSelect
			local presetID
			for id,vars in pairs(presetCore.PRESETS) do
				if vars == preset then
					presetID = id
				end
			end
			self:loadVarsFrom(preset, "-- presetProg:"..tostring(presetID))
		end
	end

	if not preset then print("ERROR: recursivePresetCheck failed : present became nil.") return end

	if (preset.presetProgression or preset.presetRandomSelection) and (iteration < 4) then
		local presetID
		for id,vars in pairs(presetCore.PRESETS) do
			if vars == preset then
				presetID = id
			end
		end
		return self:recursivePresetCheck(preset,iteration+1, presetID)
	end
	
	--[[DEBUG]]
	if iteration > 0 then print("-- EHE: ERR: progression/selection: high recursive iteration: "..tostring(iteration)) end

	return preset
end


---@param ID string
function presetCore:loadPreset(ID)

	if not ID then return end

	local preset = presetCore.PRESETS[ID]
	local masterID = ID

	if not preset then return end

	--eventSoundHandler:stopAllHeldEventSounds(self)
	--[DEBUG]] print("\n------------[loadPreset:"..ID.."]------------")
	self:loadVarsFrom(eHelicopter.initialVars, "initialVars")
	if preset.inherit then
		for k,inheritedPresetID in pairs(preset.inherit) do
			local presetFound = presetCore.PRESETS[inheritedPresetID]
			if presetFound then
				self:loadVarsFrom(presetFound, "presetInherited")
			end
		end
	end
	preset = self:recursivePresetCheck(preset, nil, masterID)
	--reset other vars not included with initialVars
	self:loadVarsFrom(eHelicopter.temporaryVariables, "temporaryVars")
	for id,vars in pairs(presetCore.PRESETS) do
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

return presetCore