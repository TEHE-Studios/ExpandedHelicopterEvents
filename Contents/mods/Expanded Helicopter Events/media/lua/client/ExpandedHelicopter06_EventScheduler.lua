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

	if (wind+rain+snow > 1.1) or (fog > 0.33) or (thunder == true) then
		willFly = false
	end

	impactOnFlightSafety = math.floor(((wind+rain+snow+(fog*3))/6)+0.5)

	return willFly, impactOnFlightSafety
end


--Engages specific eHeliEvent based on ID
---@param ID number position in "EventsSchedule"
function eHeliEvent_engage(ID)

	local eHeliEvent = getGameTime():getModData()["EventsSchedule"][ID]
	eHeliEvent.triggered = true
	
	--check if the event will occur
	local willFly,_ = eHeliEvent_weatherImpact()
	local foundTarget = eHelicopter:findTarget()
	if willFly and foundTarget then
		---@type eHelicopter
		local heli = getFreeHelicopter(eHeliEvent.preset)
		if heli then
			heli:launch(foundTarget)
		end
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

	--grab old event based on ID
	local lastHeliEvent = getGameTime():getModData()["EventsSchedule"][ID]

	--override preset with lastHeliEvent's if preset is nil
	if not presetID and lastHeliEvent then
		presetID = lastHeliEvent.preset
	end

	local nightsSurvived = getGameTime():getNightsSurvived()
	local daysBefore = getGameTime():getModData()["DaysBeforeApoc"] or 0
	local daysIntoApoc = daysBefore+nightsSurvived
	local presetSettings = eHelicopter_PRESETS[presetID] or {}
	local COF = presetSettings.cutOffFactor or eHelicopter.cutOffFactor
	local cutOffDay = COF*eHelicopterSandbox.config.cutOffDay
	local freq = eHelicopterSandbox.config.frequency

	local hoursToShift
	
	--[[DEBUG]] local debugOuput = ""
	
	if not heliDay then
		--use old event's start day for reschedule, otherwise get new day
		if not lastHeliEvent then
			heliDay = nightsSurvived+ZombRand(0,3)
		else
			heliDay = math.min(lastHeliEvent.startDay, nightsSurvived)

			--[[DEBUG]] debugOuput = debugOuput.."EHE: Event Scheudler:\n - previous heli day:"..heliDay.." freq:"..freq.."\n"

			local freqFactor = presetSettings.frequencyFactor or eHelicopter.frequencyFactor
			local dayOffset

			if freq == 0 then
				dayOffset = {7,14}
			elseif freq == 1 then
				dayOffset = {5,10}
			elseif freq == 2 then
				dayOffset = {3,6}
			elseif freq == 3 then
				dayOffset = {1,2}
				freqFactor = freqFactor*0.85
			elseif freq == 6 then
				dayOffset = {0,0}
				freqFactor = freqFactor*0.25
			end

			--pick a random day offset (converted to hours) based on what is above also multiplied by the event's frequency factor
			local randomizedHoursOffset = (ZombRand(dayOffset[1]*24,dayOffset[2]*24)+1)*freqFactor
			--as days get closer to the cutoff the time between new events gets longer
			local lessFreqOverTimeHrs = (((7-freq)*24)*math.min(1,(daysIntoApoc/cutOffDay)))*freqFactor
			--combine randomizedOffset and lessFreqOverTime
			hoursToShift = randomizedHoursOffset+lessFreqOverTimeHrs
			--convert hoursToShift to whole days
			local daysToShift = math.floor((hoursToShift/24))
			--remove the day count from hours
			hoursToShift = math.floor(hoursToShift-(daysToShift*24))
			--finally shift them
			heliDay = heliDay+daysToShift

			--[[DEBUG]] debugOuput = debugOuput.."- hrs_shift:"..hoursToShift.." day_shift:"..daysToShift.."  new heli day:"..heliDay.."\n"
		end
	end

	if not heliStart then
		local HOUR = getGameTime():getHour()
		local maxStartTime = 22
		
		--if no hoursToShift left over from daysToShift use random amount
		if not hoursToShift then
			hoursToShift = ZombRand(6,12)
		end
		
		heliStart = HOUR+hoursToShift
		
		--if heliStart is greater than max time subtract the max
		--mathmatically the hour will always be passed this way and the leftover will be used the next day
		if heliStart > maxStartTime then
			heliStart = heliStart-maxStartTime
		end
		
		--clamp heliStart just in case
		heliStart = math.max(5, math.min(maxStartTime, heliStart))
	
	end

	--[[DEBUG]] print(debugOuput)	
		
	local neverEnd = eHelicopterSandbox.config.neverEndingEvents
	local renewHeli = (daysBefore+heliDay < cutOffDay)

	if neverEnd then
		renewHeli = true
	end

	if (not renewHeli) and (not lastHeliEvent) then
		return
	end

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
		GTMData["DaysBeforeApoc"] = nil
		GTMData["DayOfLastCrash"] = nil
		local EHE = EasyConfig_Chucked.mods["ExpandedHelicopterEvents"]
		local resetEvents = EHE.menu["resetEvents"]
		resetEvents.selectedValue = "false"
		resetEvents.selectedLabel = "false"
		EHE.config.resetEvents = false
		EasyConfig_Chucked.saveConfig()
	end

	GTMData["DaysBeforeApoc"] = GTMData["DaysBeforeApoc"] or eHeli_getDaysBeforeApoc()
	GTMData["DayOfLastCrash"] = GTMData["DayOfLastCrash"] or getGameTime():getNightsSurvived()

	--if the list is empty call new heli events
	if #GTMData["EventsSchedule"] < 1 then
		for preset,params in pairs(eHeliEvents_init) do
			setNextHeliFrom(params["ID"], params["heliDay"], params["heliStart"], preset)
		end
	end
end

Events.OnGameStart.Add(eHeliEvents_OnGameStart)


--Checks every hour if there is an event scheduled to engage
function eHeliEvent_Loop()
	local DAY = getGameTime():getNightsSurvived()
	local HOUR = getGameTime():getHour()
	for k,v in pairs(getGameTime():getModData()["EventsSchedule"]) do
		if (not v.triggered) and (v.startDay <= DAY) and (v.startTime == HOUR) then
			print("EHE: LAUNCH INFO:  HELI ID:"..k.." - "..v.preset)
			if eHelicopter_PRESETS[v.preset] then
				eHeliEvent_engage(k)
			end
		end
	end
end

Events.EveryHours.Add(eHeliEvent_Loop)
