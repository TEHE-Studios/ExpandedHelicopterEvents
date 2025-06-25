require "EHE_presets"

local config = {}


config.comboOptions = {"NONE"}
function config.generateTwitchIntegrationPresets()
	for presetID,presetVariables in pairs(eHelicopter_PRESETS) do
		if presetVariables.doNotListForTwitchIntegration~=true then
			table.insert(config.comboOptions, presetID)
		end
	end
	table.insert(config.comboOptions, "RANDOM")
end


function config.generateOptions()
	local newOptions = {}
	for key,presetID in pairs(config.comboOptions) do
		table.insert(newOptions, {presetID, key})
	end
	return newOptions
end


function config.apply()

	local options = PZAPI.ModOptions:create("EHE Streamer Integration", getText("UI_Config_EHE_SI"))

	options:addTitle(getText("UI_Config_EHE_SI_IntegrationToolTip"))

	options:addTickBox("EHE_SI_IntegrationOnly",
			getText("UI_Config_SpeechCanAttractsZombies"), true,
			getText("UI_Config_SpeechCanAttractsZombiesToolTip"))

	options:addTickBox("EHE_SI_StreamerTargeted",
			getText("UI_Config_EHE_SI_StreamerTargeted"), true, nil)

	options:addTickBox("EHE_SI_HoursBeforeEventsAllowed",
			getText("UI_Config_EHE_SI_HoursBeforeEventsAllowed"), true,
			getText("UI_Config_EHE_SI_HoursBeforeEventsAllowedTooltip"))

	options:addTickBox("EHE_SI_HoursDelayBetweenEvents",
			getText("UI_Config_EHE_SI_HoursDelayBetweenEvents"), true,
			getText("UI_Config_EHE_SI_HoursDelayBetweenEventsTooltip"))

	options:addComboBox("NumpPad Integration")

	for i=1, 9 do
		local combo = options:addComboBox("EHE_SI_NumpPad"..i, "NumpPad"..i, "integration for "..i)

		for _,preset in pairs(config.comboOptions) do
			combo:addItem(preset)
		end
	end
end

return config

---eHelicopterSandbox