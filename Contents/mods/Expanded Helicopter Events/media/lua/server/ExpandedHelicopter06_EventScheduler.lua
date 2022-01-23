require "ExpandedHelicopter06b_EventScheduler"


--Checks every hour if there is an event scheduled to engage
function eHeliEvent_Loop()

	local GT = getGameTime()
	local globalModData = getExpandedHeliEventsModData()
	local DAY = GT:getDay()
	local HOUR = GT:getHour()
	local events = globalModData.EventsOnSchedule

	if getDebug() then print("--- EVERYHOUR:  isClient:"..tostring(isClient())) end

	for k,v in pairs(events) do

		if v.triggered or (not eHelicopter_PRESETS[v.preset]) then
			globalModData.EventsOnSchedule[k] = nil
		elseif (v.startDay <= DAY) and (v.startTime == HOUR) then
			print("EHE: SCHEDULED-LAUNCH INFO:  HELI ID:"..k.." - day:"..tostring(v.startDay).." time:"..tostring(v.startTime).." id:"..tostring(v.preset).." done:"..tostring(v.triggered))
			if eHelicopter_PRESETS[v.preset] then
				eHeliEvent_engage(k)
			end
		end
	end
end


local currentHour = -1
function eHeliEvent_OnHour()

	local GT = getGameTime()
	local HOUR = GT:getHour()

	if HOUR ~= currentHour then
		currentHour = HOUR
		eHeliEvent_ScheduleNew()
		eHeliEvent_Loop()
	end
end

Events.OnTick.Add(eHeliEvent_OnHour)