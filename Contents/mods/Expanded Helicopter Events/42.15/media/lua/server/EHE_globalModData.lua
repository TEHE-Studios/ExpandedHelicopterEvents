---Credit to Konijima (Konijima#9279) for clearing up networking :thumbsup:

require("EHE_onClientToServerCommands.lua")
local util = require("EHE_util.lua")

local modData = {}

local ExpandedHeliEventsModData

local function initExpandedHeliEventsModData(isNewGame)
	local data = ModData.getOrCreate("ExpandedHelicopterEvents")

	if not data.EventsOnSchedule then data.EventsOnSchedule = {} end
	if not data.DayOfLastCrash then data.DayOfLastCrash = util.getWorldAgeDays() end
	if not data.DaysBeforeApoc then data.DaysBeforeApoc = util.getDaysSinceApoc() end

	ExpandedHeliEventsModData = data

	if not isNewGame then triggerEvent("EHE_ServerModDataReady") end
end

---@return table
function modData.get()
	return ExpandedHeliEventsModData
end

Events.OnInitGlobalModData.Add(initExpandedHeliEventsModData)

return modData
