require "ExpandedHelicopter00f_WeatherImpact"
require "ExpandedHelicopter00a_Util"

local ExpandedHeliEventsModData = nil
function initExpandedHeliEventsModData()
	local modData = ModData.getOrCreate("ExpandedHelicopterEvents")
	if not modData.EventsOnSchedule then
		modData.EventsOnSchedule = {}
	end

	if not modData.DayOfLastCrash then
		modData.DayOfLastCrash = getGameTime():getNightsSurvived()
	end

	if not modData.DaysBeforeApoc then
		modData.DaysBeforeApoc = eHeli_getDaysBeforeApoc()
	end

	ExpandedHeliEventsModData = modData
end

function getExpandedHeliEventsModData()
	return ExpandedHeliEventsModData
end

Events.OnInitGlobalModData.Add(initExpandedHeliEventsModData)