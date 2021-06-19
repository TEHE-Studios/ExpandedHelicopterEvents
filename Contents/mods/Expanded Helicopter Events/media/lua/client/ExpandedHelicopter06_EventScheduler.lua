---Inserts a new eHeliEvent (table) to the "EventsSchedule" table
---@param replacePos number If not nil, replace specific entry in "EventsSchedule", otherwise insert as normal (at end)
---@param startDay number Day scheduled for start of this event
---@param startTime number Hour scheduled for the start of this event
---@param preset string Name of preset found in PRESETS
---@param renew boolean If the event reschedules after completion
---Events are handled as tables because ModData does not save Lua "classes" properly, even though they are really tables.
function eHeliEvent_new(replacePos, startDay, startTime, preset, renew)
	
	if (not startDay) or (not startTime) then
		return
	end

	local newEvent = {["startDay"] = startDay, ["startTime"] = startTime, ["preset"] = preset, ["renew"] = renew, ["triggered"] = false}

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

	impactOnFlightSafety = math.floor(((wind+rain+snow+(fog*3))/6)+0.5)

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
	if willFly and (getNumActivePlayers() > 0) then
		getFreeHelicopter(eHeliEvent.preset):launch()
	end
	--replace event in schedule with newly generated values
	if eHeliEvent.renew then
		setNextHeliFrom(ID)
	end
end


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
	--roll the year back if apocStartMonth is negative
	if apocStartMonth <= 0 then
		apocStartMonth = 12+apocStartMonth
		startYear = startYear-1
	end
	local apocDays = 0
	--count each month at a time to get correct day count
	for month=0, monthsAfterApo do
		apocStartMonth = apocStartMonth+1
		--roll year forward if needed, reset month
		if apocStartMonth > 12 then
			apocStartMonth = 1
			startYear = startYear+1
		end
		--months of the year start at 0
		local daysInM = gameTime:daysInMonth(startYear, apocStartMonth-1)
		--if this is the first month being counted subtract starting day date
		if month==0 then
			daysInM = daysInM-gameTime:getStartDay()+1
		end
		apocDays = apocDays+daysInM
	end

	return apocDays
end


---Generates a schedule time for an event, either from scratch or a previous event.
---@param ID number Position in schedule
---@param heliDay number Day to start event
---@param heliStart number Hour to start event
function setNextHeliFrom(ID, heliDay, heliStart, presetID)
	
	local freq = eHelicopterSandbox.config.frequency
	--if freq is never
	if freq == 0 then
		return
	end
	--grab old event based on ID
	local lastHeliEvent = getGameTime():getModData()["EventsSchedule"][ID]

	--override preset with lastHeliEvent's if preset is nil
	if not presetID and lastHeliEvent then
		presetID = lastHeliEvent.preset
	end

	local nightsSurvived = getGameTime():getNightsSurvived()
	local daysIntoApoc = getGameTime():getModData()["DaysBeforeApoc"]+nightsSurvived
	local presetSettings = eHelicopter_PRESETS[presetID] or {}
	local cutOff = presetSettings.cutOffFactor or eHelicopter.cutOffFactor
	local cutOffDay = cutOff*eHelicopterSandbox.config.cutOffDay
	local startMinMax = presetSettings.startDayMinMax or eHelicopter.startDayMinMax
	local freqFactor = presetSettings.frequencyFactor or eHelicopter.frequencyFactor

	if cutOffDay and nightsSurvived > cutOffDay then
		return
	end

	if not heliDay then
		heliDay = nightsSurvived
		--use old event's start day for reschedule, otherwise get new day
		if lastHeliEvent then
			heliDay = lastHeliEvent.startDay
			--options = Never=0, Once=1, Sometimes=2, Often=3
			if freq <= 2 then
				startMinMax = {3*freqFactor, 6*freqFactor}
			elseif freq == 3 then
				startMinMax = {1*freqFactor, 2*freqFactor}
			end

			local randomizedStart = ZombRand(startMinMax[1],startMinMax[2])
			--as days get closer to the cutoff the time between new events gets longer
			local lessFreqOverTime = ((7-freq)*(daysIntoApoc/cutOffDay))

			heliDay = heliDay+randomizedStart+lessFreqOverTime
			--trim non integer
			heliDay = math.floor(heliDay)
		end
	end

	if not heliStart then
		--start time is random from hour 6 to 20
		heliStart = ZombRand(6, 20)
	end

	local daysBefore = getGameTime():getModData()["DaysBeforeApoc"]
	local renewHeli = (not ((freq == 1) or (daysBefore+heliDay > cutOffDay)))

	eHeliEvent_new(ID, heliDay, heliStart, presetID, renewHeli)
end


---Handles setting up the event scheduler
function eHeliEvents_OnGameStart()
	local GTMData = getGameTime():getModData()
	--if no EventsSchedule found make it an empty list
	if not GTMData["EventsSchedule"] then
		GTMData["EventsSchedule"] = {}
	end

	--if eHelicopterSandbox.config.resetEvents == true, reset
	if eHelicopterSandbox.config.resetEvents == true then
		EasyConfig_Chucked.loadConfig()
		GTMData["EventsSchedule"] = {}
		local EHE = EasyConfig_Chucked.mods["ExpandedHelicopterEvents"]
		local resetEvents = EHE.configMenu["resetEvents"]
		resetEvents.selectedValue = "false"
		resetEvents.selectedLabel = "false"
		EHE.config.resetEvents = false
		EasyConfig_Chucked.saveConfig()
	end

	GTMData["DaysBeforeApoc"] = GTMData["DaysBeforeApoc"] or eHeli_getDaysBeforeApoc()
	GTMData["DayOfLastCrash"] = GTMData["DayOfLastCrash"] or getGameTime():getDaysSurvived()

	--if the list is empty call new heli events
	if #GTMData["EventsSchedule"] < 1 then
		setNextHeliFrom(nil, nil, nil, "increasingly_hostile")
		setNextHeliFrom(nil, nil, nil, "jet")
		setNextHeliFrom(nil, nil, nil, "civilian")
		setNextHeliFrom(nil, nil, nil, "increasingly_helpful")
	end
end

Events.OnGameStart.Add(eHeliEvents_OnGameStart)

--Checks every hour if there is an event scheduled to engage
function eHeliEvent_Loop()
	local DAY = getGameTime():getNightsSurvived()
	local HOUR = getGameTime():getHour()

	for k,v in pairs(getGameTime():getModData()["EventsSchedule"]) do
		if (not v.triggered) and (v.startDay <= DAY) and (v.startTime == HOUR) then
			print("Events Scheduled: "..v.preset)
			if eHelicopter_PRESETS[v.preset] then
				eHeliEvent_engage(k)
			end
		end
	end
end

Events.EveryHours.Add(eHeliEvent_Loop)
