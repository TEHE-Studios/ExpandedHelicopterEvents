local presetCore = {}

presetCore.PRESETS = {}

function presetCore.registerPreset(ID, table)
	presetCore.PRESETS[ID] = table
end

function presetCore.alterSpecificParameter(ID, param, value)
	if not presetCore.PRESETS[ID] then print("ERROR: preset ", ID, "not found - attempted to set", param, "to ", tostring(value)) return end
	if not presetCore.PRESETS[ID][param] then print("ERROR: param ", param, " for preset ", ID, "not found - attempted to set to ", tostring(value)) return end
	presetCore.PRESETS[ID][param] = value
end

---@param table table
function presetCore.recursiveTableCopy(table)
	local tmpTable = {}

	for k, v in pairs(table) do
		if type(v) == "table" then
			tmpTable[k] = presetCore.recursiveTableCopy(v)
		else
			tmpTable[k] = v
		end
	end

	return tmpTable
end

return presetCore
