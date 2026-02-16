---Credit to Konijima (Konijima#9279) for clearing up networking :thumbsup:

require "EHE_onClientToServerCommands"
require "EHE_weatherImpact"
require "EHE_util"

local ExpandedHeliEventsModData

local function initExpandedHeliEventsModData(isNewGame)
	local modData = ModData.getOrCreate("ExpandedHelicopterEvents")

	if not modData.EventsOnSchedule then modData.EventsOnSchedule = {} end
	if not modData.DayOfLastCrash then modData.DayOfLastCrash = getGameTime():getNightsSurvived() end
	if not modData.DaysBeforeApoc then modData.DaysBeforeApoc = eHeli_getDaysSinceApoc() end

	ExpandedHeliEventsModData = modData

	if not isNewGame then triggerEvent("EHE_ServerModDataReady") end
end

function getExpandedHeliEventsModData()
	return ExpandedHeliEventsModData
end

Events.OnInitGlobalModData.Add(initExpandedHeliEventsModData)