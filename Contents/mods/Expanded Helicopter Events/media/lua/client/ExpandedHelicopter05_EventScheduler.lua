---Inserts a new eHeliEvent (table) to the "EventsSchedule" table
---@param replacePos number If not nil, replace specific entry in "EventsSchedule", otherwise insert as normal (at end)
---@param startDay number Day scheduled for start of this event
---@param startTime number Hour scheduled for the start of this event
---@param endTime number Hour scheduled for the end of this event
---@param preset string Name of preset found in PRESETS
---@param renew boolean If the event reschedules after completion
---Events are handled as tables because ModData does not save Lua "classes" properly, even though they are really tables.
function eHeliEvent_new(replacePos, startDay, startTime, endTime, preset, renew)
	
	if (not startDay) or (not startTime) or (not endTime) then
		return
	end

	local newEvent = {["startDay"] = startDay, ["startTime"] = startTime, ["endTime"] = endTime, ["preset"] = preset, ["renew"] = renew, ["triggered"] = false}

	if replacePos then
		getGameTime():getModData()["EventsSchedule"][replacePos] = newEvent
	else
		table.insert(getGameTime():getModData()["EventsSchedule"], newEvent)
	end
end


---Calculates if a flight should go out and the weather impact on flight safety
---@return boolean, number returns two values: willFly, impactOnFlightSafety
function eHeliEvent_weatherImpact()
	local CM = getClimateManager()
	
	local willFly = true
	local impactOnFlightSafety = 0
	
	local wind = CM:getWindIntensity()
	local fog = CM:getFogIntensity()
	local rain = CM:getRainIntensity()/2
	local snow = CM:getSnowIntensity()/2
	local thunder = CM:getIsThunderStorming()

	if (wind+rain+snow > 0.90) or (fog > 0.33) or (thunder == true) then
		willFly = false
	end

	impactOnFlightSafety = (wind+rain+snow+(fog*3))/6

	return willFly, impactOnFlightSafety
end


--Engages specific eHeliEvent based on ID
---@param ID number position in "EventsSchedule"
function eHeliEvent_engage(ID)
	--if frequency is set to never
	if eHelicopterSandbox.config.frequency == 0 then
		return
	end

	local eHeliEvent = getGameTime():getModData()["EventsSchedule"][ID]
	eHeliEvent.triggered = true
	
	--check if the event will occur
	local willFly,_ = eHeliEvent_weatherImpact()
	if willFly then
		getFreeHelicopter(eHeliEvent.preset):launch()
	end
	--replace event in schedule with newly generated values
	if eHeliEvent.renew then
		setNextHeliFrom(ID)
	end
end


---General events cut-off day after apocalypse, NOT game start
eHeliEvent_cutOffDay = 30
---Check how many days it has been since the start of the apocalypse; corrects for sandbox option "Months since Apoc"
---@return number Days since start of in-game apocalypse
function eHeli_getDaysBeforeApoc()

	local monthsAfterApo = getSandboxOptions():getTimeSinceApo()-1
	--no months to count, go away
	if monthsAfterApo <= 0 then
		return 0
	end

	local gameTime = getGameTime()
	local startYear = gameTime:getStartYear()
	--months of the year start at 0
	local apocStartMonth = (gameTime:getStartMonth()+1)-monthsAfterApo
	--roll the year back
	if apocStartMonth <= 0 then
		apocStartMonth = 12+apocStartMonth
		startYear = startYear-1
	end
	--days of the month start at 0
	local apocDays = gameTime:getStartDay()+1
	--count each month at a time to get correct day count
	for _=1, monthsAfterApo do
		apocStartMonth = apocStartMonth+1
		--roll year forward if needed, reset month
		if apocStartMonth > 12 then
			apocStartMonth = 1
			startYear = startYear+1
		end
		--months of the year start at 0
		local daysInM = gameTime:daysInMonth(startYear, apocStartMonth-1)
		apocDays = apocDays+daysInM
	end

	return apocDays
end


---Generates a schedule time for an event, either from scratch or a previous event.
---@param ID number Position in schedule
---@param heliDay number Day to start event
---@param heliStart number Hour to start event
---@param heliEnd number Hour to end event
function setNextHeliFrom(ID, heliDay, heliStart, heliEnd, preset)
	
	local freq = eHelicopterSandbox.config.frequency
	--if freq is never
	if freq == 0 then
		return
	end
	--grab old event based on ID
	local lastHeliEvent = getGameTime():getModData()["EventsSchedule"][ID]

	if not heliDay then
	
		local nightsSurvived = getGameTime():getNightsSurvived()
		--if there is an old event use it's start day for calculating the next start day
		if lastHeliEvent then
			heliDay = lastHeliEvent.startDay
		--otherwise use nightsSurvived / current day
		else
			heliDay = nightsSurvived
		end

		--options = Never=0, Once=1, Sometimes=2, Often=3
		if freq <= 2 then
			heliDay = heliDay+ZombRand(3, 6)
		--if frequency is often
		elseif freq == 3 then
			heliDay = heliDay+ZombRand(1, 2)
		end
		--as days get closer to the cutoff the time between new events gets longer
		heliDay = heliDay+math.floor((7-freq)*(nightsSurvived/eHeliEvent_cutOffDay))
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
	--if freq is once OR new heliDay is beyond cutOffDay don't renew further
	if (freq == 1) or (eHeli_getDaysBeforeApoc()+heliDay > eHeliEvent_cutOffDay) then
		renewHeli = false
	end
	
	--override preset with lastHeliEvent's if preset is nil
	preset = preset or lastHeliEvent.preset
	
	eHeliEvent_new(ID, heliDay, heliStart, heliEnd, preset, renewHeli)
end


---Handles setting up the event scheduler
function eHeliEvents_OnGameStart()

	--if no ModData found make it an empty list
	if not getGameTime():getModData()["EventsSchedule"] then
		getGameTime():getModData()["EventsSchedule"] = {}
	end

	--if eHelicopterSandbox.config.resetEvents == true, reset
	if eHelicopterSandbox.config.resetEvents == true then
		getGameTime():getModData()["EventsSchedule"] = {}
		local EHE = EasyConfig_Chucked.mods["ExpandedHelicopterEvents"]
		local resetEvents = EHE.configMenu["resetEvents"]
		resetEvents.selectedValue = "false"
		resetEvents.selectedLabel = "false"
		EHE.config.resetEvents = false
		EasyConfig_Chucked.saveConfig()
	end

	--if the list is empty call new heli event
	if #getGameTime():getModData()["EventsSchedule"] < 1 then
		setNextHeliFrom(nil, getGameTime():getNightsSurvived())
	end
end

Events.OnGameStart.Add(eHeliEvents_OnGameStart)

--Checks every hour if there is an event scheduled to engage
function eHeliEvent_Loop()
	local DAY = getGameTime():getNightsSurvived()
	local HOUR = getGameTime():getHour()

	for k,v in pairs(getGameTime():getModData()["EventsSchedule"]) do
		if (not v.triggered) and (v.startDay <= DAY) and (v.startTime == HOUR) then
			eHeliEvent_engage(k)
		end
	end
end

Events.EveryHours.Add(eHeliEvent_Loop)
