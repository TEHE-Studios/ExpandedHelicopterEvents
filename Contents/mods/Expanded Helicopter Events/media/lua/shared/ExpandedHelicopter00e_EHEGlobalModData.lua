require "ExpandedHelicopter00a_Util"

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
end

function getExpandedHeliEventsModData()
	local modData = ModData.get("ExpandedHelicopterEvents")
	return modData
end

Events.OnInitGlobalModData.Add(initExpandedHeliEventsModData)