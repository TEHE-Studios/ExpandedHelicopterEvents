require "ExpandedHelicopter02a_Presets"
require "ExpandedHelicopter09_EasyConfigOptions"

twitchIntegrationPresets = {"NONE"}
function generateTwitchIntegrationPresets()
	for presetID,presetVariables in pairs(eHelicopter_PRESETS) do
		if presetVariables.doNotListForTwitchIntegration~=true then
			table.insert(twitchIntegrationPresets, presetID)
		end
	end
	table.insert(twitchIntegrationPresets, "RANDOM")
end

function EHETI_generateOptions()
	local newOptions = {}
	for key,presetID in pairs(twitchIntegrationPresets) do
		table.insert(newOptions, {presetID, key})
	end
	return newOptions
end


function applyTwitchIntegration()
	eHelicopterSandbox.menu.twitchSpace = nil
	eHelicopterSandbox.menu.twitchIntegrationText = nil
	eHelicopterSandbox.menu.twitchIntegrationToolTip = nil
	eHelicopterSandbox.menu.twitchIntegrationOnly = nil
	eHelicopterSandbox.menu.twitchStreamerTargeted = nil
	eHelicopterSandbox.menu.twitchHoursBeforeEventsAllowed = nil
	eHelicopterSandbox.menu.twitchHoursBeforeEventsAllowedTooltip = nil
	eHelicopterSandbox.menu.twitchHoursDelayBetweenEvents = nil
	eHelicopterSandbox.menu.twitchHoursDelayBetweenEventsTooltip = nil
	eHelicopterSandbox.menu.twitchSpaceMid = nil
	eHelicopterSandbox.menu.twitchSpaceEnd = nil

	generateTwitchIntegrationPresets()

	eHelicopterSandbox.menu.twitchSpace = {type = "Space", alwaysAccessible = true}
	eHelicopterSandbox.menu.twitchIntegrationText = {type = "Text", alwaysAccessible = true, }
	eHelicopterSandbox.menu.twitchIntegrationToolTip1 = {type = "Text", alwaysAccessible = true, a=0.6,}
	eHelicopterSandbox.menu.twitchIntegrationToolTip2 = {type = "Text", alwaysAccessible = true, a=0.6, addAfter="\n"}
	eHelicopterSandbox.menu.twitchIntegrationOnly = {type = "Tickbox", alwaysAccessible = true, tooltip = "", }
	eHelicopterSandbox.menu.twitchStreamerTargeted = {type = "Tickbox", alwaysAccessible = true, tooltip = "", }

	eHelicopterSandbox.menu.twitchHoursBeforeEventsAllowed = {type = "Numberbox", alwaysAccessible = true, tooltip = "", }
	eHelicopterSandbox.menu.twitchHoursBeforeEventsAllowedTooltip = {type = "Text", alwaysAccessible = true, tooltip = "", a=0.6,}

	eHelicopterSandbox.menu.twitchHoursDelayBetweenEvents = {type = "Numberbox", alwaysAccessible = true, tooltip = "", }
	eHelicopterSandbox.menu.twitchHoursDelayBetweenEventsTooltip = {type = "Text", alwaysAccessible = true, tooltip = "", a=0.6,}

	eHelicopterSandbox.menu.twitchSpaceMid = {type = "Space", alwaysAccessible = true}
	for i=1, 9 do
		eHelicopterSandbox.menu["Numpad"..i] = nil
		eHelicopterSandbox.menu["Numpad"..i] = eHelicopterSandbox.menu["Numpad"..i] or {type = "Combobox", alwaysAccessible = true, options = EHETI_generateOptions(), noTranslate=true }
		eHelicopterSandbox.config["Numpad"..i] = eHelicopterSandbox.config["Numpad"..i] or eHelicopterSandbox.config["Numpad"..i] or 1
	end
	eHelicopterSandbox.menu.twitchSpaceEnd = {type = "Space", alwaysAccessible = true}
	eHelicopterSandbox.config.twitchIntegrationOnly = eHelicopterSandbox.config.twitchIntegrationOnly or false
	eHelicopterSandbox.config.twitchStreamerTargeted = eHelicopterSandbox.config.twitchStreamerTargeted or true
	eHelicopterSandbox.config.twitchHoursBeforeEventsAllowed = eHelicopterSandbox.config.twitchHoursBeforeEventsAllowed or 0
	eHelicopterSandbox.config.twitchHoursDelayBetweenEvents = eHelicopterSandbox.config.twitchHoursDelayBetweenEvents or 0
end

Events.OnGameBoot.Add(applyTwitchIntegration)