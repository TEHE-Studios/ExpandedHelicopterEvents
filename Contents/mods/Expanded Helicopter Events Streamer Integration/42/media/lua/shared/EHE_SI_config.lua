require "EHE_presets"

local config = {}


function config.checkValue(ID)
	local options = PZAPI.ModOptions:getOptions("EHE Streamer Integration")
	local option = options and options:getOption(ID)
	local value = option and option:getValue()
	return value
end


config.allowedPresets = nil
function config.fetchAllowedPresets()
	if config.allowedPresets then return config.allowedPresets end
	config.allowedPresets = {}
	for presetID,presetVariables in pairs(eHelicopter_PRESETS) do
		if presetVariables.doNotListForStreamerIntegration~=true then
			table.insert(config.allowedPresets, presetID)
		end
	end
	return config.allowedPresets
end


config.comboOptions = nil
function config.generateOptions()
	config.fetchAllowedPresets()
	if config.comboOptions then return end
	config.comboOptions = {"NONE"}
	for _,presetID in pairs(config.allowedPresets) do
		table.insert(config.comboOptions, presetID)
	end
	table.insert(config.comboOptions, "RANDOM")
end


function config.apply()

	---@type
	local options = PZAPI.ModOptions:create("EHE Streamer Integration", getText("UI_Config_EHE_SI"))

	options:addTitle(getText("UI_Config_EHE_SI_IntegrationToolTip1"))
	options:addTitle(getText("UI_Config_EHE_SI_IntegrationToolTip2"))

	options:addTickBox("EHE_SI_IntegrationOnly", getText("UI_Config_EHE_SI_IntegrationOnly"), true)

	options:addTickBox("EHE_SI_KeyPresserTargeted", getText("UI_Config_EHE_SI_KeyPresserTargeted"), true)

	options:addTextEntry("EHE_SI_HoursBeforeEvents",
			getText("UI_Config_EHE_SI_HoursBeforeEvents"), "0",
			getText("UI_Config_EHE_SI_HoursBeforeEventsTooltip"))

	options:addTextEntry("EHE_SI_HoursBetweenEvents",
			getText("UI_Config_EHE_SI_HoursBetweenEvents"), "0",
			getText("UI_Config_EHE_SI_HoursBetweenEventsTooltip"))

	for i=1, 9 do
		local combo = options:addComboBox("EHE_SI_Numbpad"..i, "Numbpad"..i, "integration for "..i)
		config.generateOptions()
		for _,preset in pairs(config.comboOptions) do
			combo:addItem(preset)
		end
	end
end

return config