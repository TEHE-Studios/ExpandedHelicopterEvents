local eHelicopter = require("EHE_mainVariables.lua")

local mainCore = {}

mainCore.ALL_HELICOPTERS = {}

---Do not call this function directly for new helicopters; use: mainCore.getFreeHelicopter instead
---eHelicopter:new is defined in EHE_heliCore, which is loaded before any gameplay events fire
function mainCore.getFreeHelicopter(preset)
	---@type eHelicopter heli
	local heli = eHelicopter:new()

	if preset then
		heli:loadPreset(preset)
	end

	return heli
end


---@param HelicopterOrPreset table
---@return number startDay
---@return number cutOffDay
function mainCore.fetchStartDayAndCutOffDay(HelicopterOrPreset)
	local startDayFactor = HelicopterOrPreset.eventStartDayFactor or eHelicopter.eventStartDayFactor
	local startDay = math.floor((startDayFactor*SandboxVars.ExpandedHeli.SchedulerDuration)+0.5)
	startDay = math.max(startDay, SandboxVars.ExpandedHeli.StartDay)
	local cutOffDayFactor = HelicopterOrPreset.eventCutOffDayFactor or eHelicopter.eventCutOffDayFactor
	local cutOffDay = math.floor((cutOffDayFactor*(startDay+SandboxVars.ExpandedHeli.SchedulerDuration))+0.5)
	return startDay, cutOffDay
end

return mainCore
