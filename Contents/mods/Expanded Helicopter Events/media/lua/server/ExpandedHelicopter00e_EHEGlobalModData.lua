---Credit to Konijima (Konijima#9279) for clearing up networking :thumbsup:

require "ExpandedHelicopter12a_OnClientToServerCommands"
require "ExpandedHelicopter00f_WeatherImpact"
require "ExpandedHelicopter00a_Util"

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