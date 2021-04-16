function eHeliEvent_new(replacePos, startDay, startTime, endTime, renew)

	if (not startDay) or (not startTime) or (not endTime) then
		return
	end

	local o = {["startDay"] = startDay, ["startTime"] = startTime, ["endTime"] = endTime, ["renew"] = renew, ["triggered"] = false}

	if replacePos then
		getGameTime():getModData()["EventsSchedule"][replacePos] = o
	else
		table.insert(getGameTime():getModData()["EventsSchedule"], o)
	end
end


function eHeliEvent_engage(ID)
	if eHelicopterSandbox.config.frequency == 0 then
		return
	end

	local eHeliEvent = getGameTime():getModData()["EventsSchedule"][ID]
	eHeliEvent.triggered = true

	getFreeHelicopter():launch()

	if eHeliEvent.renew then
		setNextHeliFrom(ID)
	end
end


function setNextHeliFrom(ID, heliDay, heliStart, heliEnd)

	if eHelicopterSandbox.config.frequency == 0 then
		return
	end

	local lastHeliEvent = getGameTime():getModData()["EventsSchedule"][ID]

	if not heliDay then
		if lastHeliEvent then
			heliDay = lastHeliEvent.startDay
		else
			heliDay = getGameTime():getNightsSurvived()
		end
		-- options = Never=0, Once=1, Sometimes=2, Often=3
		if eHelicopterSandbox.config.frequency <= 2 then
			heliDay = heliDay+ZombRand(10, 16)
			-- if frequency is 3 / often
		elseif eHelicopterSandbox.config.frequency == 3 then
			heliDay = heliDay+ZombRand(6, 10)
		end
	end

	if not heliStart then
		--start time is random from hour 9 to 19
		heliStart = ZombRand(9, 19)
	end

	if not heliEnd then
		--end time is start time + 1 to 5 hours
		heliEnd = heliStart+ZombRand(1,5)
	end

	local renewHeli = true
	if eHelicopterSandbox.config.frequency == 1 then
		renewHeli = false
	end

	eHeliEvent_new(ID, heliDay, heliStart, heliEnd, renewHeli)
end


function eHeliEvents_OnGameStart()

	--if no ModData found make it an empty list
	if not getGameTime():getModData()["EventsSchedule"] then
		getGameTime():getModData()["EventsSchedule"] = {}
	end

	--if the list is empty call new heli event
	if #getGameTime():getModData()["EventsSchedule"] < 1 then
		setNextHeliFrom(nil, getGameTime():getNightsSurvived())
	end
end

Events.OnGameStart.Add(eHeliEvents_OnGameStart)


function eHeliEvent_Loop()
	local DAY = getGameTime():getNightsSurvived()
	local HOUR = getGameTime():getHour()

	for k,v in pairs(getGameTime():getModData()["EventsSchedule"]) do
		if (not v.triggered) and (v.startDay <= DAY) and (v.startTime >= HOUR) then
			eHeliEvent_engage(k)
		end
	end
end

Events.EveryHours.Add(eHeliEvent_Loop)