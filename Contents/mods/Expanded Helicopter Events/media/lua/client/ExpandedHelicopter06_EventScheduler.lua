---Inserts a new eHeliEvent (table) to the "EventsOnSchedule" table
---@param startDay number Day scheduled for start of this event
---@param startTime number Hour scheduled for the start of this event
---@param preset string Name of preset found in PRESETS
---Events are handled as tables because ModData does not save Lua "classes" properly, even though they are really tables.
function eHeliEvent_new(startDay, startTime, preset)
	if (not startDay) or (not startTime) then
		return
	end
	local newEvent = {["startDay"] = startDay, ["startTime"] = startTime, ["preset"] = preset, ["triggered"] = false}
	table.insert(getGameTime():getModData()["EventsOnSchedule"], newEvent)
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
---@param ID number position in "EventsOnSchedule"
function eHeliEvent_engage(ID)

	local eHeliEvent = getGameTime():getModData()["EventsOnSchedule"][ID]
	eHeliEvent.triggered = true
	
	--check if the event will occur
	local willFly,_ = eHeliEvent_weatherImpact()
	local foundTarget = eHelicopter:findTarget(nil, "eHeliEvent_engage")

	if SandboxVars.ExpandedHeli["Frequency_"..eHeliEvent.preset]==1 then
		willFly = false
	end

	if willFly and foundTarget then
		---@type eHelicopter
		local heli = getFreeHelicopter(eHeliEvent.preset)
		if heli then
			heli:launch(foundTarget)
		end
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


local eventsForScheduling = nil
function eHeliEvents_setEventsForScheduling()
	if not eventsForScheduling then
		eventsForScheduling = {}
		for presetID,presetVars in pairs(eHelicopter_PRESETS) do
			if presetVars.forScheduling then
				table.insert(eventsForScheduling, presetID)
			end
		end
	end
end


---Handles setting up the event scheduler
function eHeliEvents_OnGameStart()
	local GTMData = getGameTime():getModData()

	eHeliEvents_setEventsForScheduling()

	--if eHelicopterSandbox.config.resetEvents == true, reset
	if eHelicopterSandbox.config.resetEvents == true then
		EasyConfig_Chucked.loadConfig()
		GTMData["EventsOnSchedule"] = {}
		GTMData["DaysBeforeApoc"] = nil
		GTMData["DayOfLastCrash"] = nil
		local spawnerList = SpawnerTEMP.getOrSetPendingSpawnsList()
		spawnerList = {}
		local EHE = EasyConfig_Chucked.mods["ExpandedHelicopterEvents"]
		local resetEvents = EHE.menu["resetEvents"]
		resetEvents.selectedValue = "false"
		resetEvents.selectedLabel = "false"
		EHE.config.resetEvents = false
		EasyConfig_Chucked.saveConfig()
	end

	GTMData["DaysBeforeApoc"] = GTMData["DaysBeforeApoc"] or eHeli_getDaysBeforeApoc()
	GTMData["DayOfLastCrash"] = GTMData["DayOfLastCrash"] or getGameTime():getNightsSurvived()

	--if no EventsOnSchedule found make it an empty list
	if not GTMData["EventsOnSchedule"] then
		GTMData["EventsOnSchedule"] = {}
	end
end
Events.OnGameStart.Add(eHeliEvents_OnGameStart)


function eHeliEvent_ScheduleNew(nightsSurvived,currentHour,freqOverride)
	local GT = getGameTime()
	nightsSurvived = nightsSurvived or GT:getNightsSurvived()
	currentHour = currentHour or GT:getHour()
	local neverEnd = SandboxVars.ExpandedHeli.NeverEnding
	local daysIntoApoc = (GT:getModData()["DaysBeforeApoc"] or 0)+nightsSurvived

	local eventIDsScheduled = {}
	for k,v in pairs(GT:getModData()["EventsOnSchedule"]) do
		if not v.triggered and v.startDay == nightsSurvived then
			eventIDsScheduled[v.preset] = true
		end
	end

	if neverEnd or (daysIntoApoc <= SandboxVars.ExpandedHeli.CutOffDay) then
		local options = {}

		for k,presetID in pairs(eventsForScheduling) do
			if not eventIDsScheduled[presetID] then

				local presetSettings = eHelicopter_PRESETS[presetID]
				local schedulingFactor = presetSettings.schedulingFactor or eHelicopter.schedulingFactor
				local flightHours = presetSettings.flightHours or eHelicopter.flightHours

				local CutOffDayFactor = presetSettings.eventCutOffDayFactor or eHelicopter.eventCutOffDayFactor
				local cutOffDay = math.floor((CutOffDayFactor*SandboxVars.ExpandedHeli.CutOffDay)+0.5)

				local StartDayFactor = presetSettings.eventStartDayFactor or eHelicopter.eventStartDayFactor
				local startDay = math.floor((StartDayFactor*SandboxVars.ExpandedHeli.CutOffDay)+0.5)

				local dayAndHourInRange = ((daysIntoApoc >= startDay) and (daysIntoApoc <= cutOffDay) and (currentHour >= flightHours[1]) and (currentHour <= flightHours[2]))

				local freq = 3
				local presetFreq = SandboxVars.ExpandedHeli["Frequency_"..presetID]
				if presetFreq then
					freq = presetFreq-1
				end

				freq = freqOverride or freq

				--the greater the frequency the smaller the denominator
				local probabilityDenominator = ((10-freq)*2500)
				--less frequent over time
				probabilityDenominator = probabilityDenominator+(1000*(daysIntoApoc/SandboxVars.ExpandedHeli.CutOffDay))

				local eventAvailable = (dayAndHourInRange or (SandboxVars.ExpandedHeli.NeverEnding==true))

				--[[DEBUG] print(" processing preset: "..presetID.." a:"..tostring(dayAndHourInRange).." b:"..tostring(SandboxVars.ExpandedHeli.NeverEnding==true).." c:"..chance)--]]

				if eventAvailable then
					local weight = eHelicopter.eventSpawnWeight
					if presetSettings then
						if presetSettings.eventSpawnWeight then
							weight = presetSettings.eventSpawnWeight
						elseif inheritedSettings and inheritedSettings.eventSpawnWeight then
							weight = inheritedSettings.eventSpawnWeight
						end
					end

					weight = weight*freq

					for i=1, weight do
						if (ZombRand(probabilityDenominator) <= freq*schedulingFactor) then
							table.insert(options, presetID)
						end
					end
				end
			end
		end

		--[[DEBUG]
		if lessFreqOverTime > 0 then print("EHE:Scheduler: lessFreqOverTime:"..lessFreqOverTime) end
		local options_tally = {}
		for kk,vv in pairs(options) do if options_tally[vv] then options_tally[vv] = options_tally[vv]+1 else options_tally[vv] = 1 end end
		local options_string
		for kk,vv in pairs(options_tally) do
			if not options_string then options_string = " --- EHE:Options: "
			end options_string = options_string..tostring(kk).." "..tostring(vv)..", "
		end if options_string then print(options_string) end
		--]]

		local selectedPresetID = options[ZombRand(#options)+1]
		if selectedPresetID and (selectedPresetID ~= false) then
			local selectedPreset = eHelicopter_PRESETS[selectedPresetID]
			local flightHours = selectedPreset.flightHours or eHelicopter.flightHours
			local CutOffDayFactor = selectedPreset.eventCutOffDayFactor or eHelicopter.eventCutOffDayFactor
			local cutOffDay = math.floor((CutOffDayFactor*SandboxVars.ExpandedHeli.CutOffDay)+0.5)

			local dayOffset = {0,0,0,1,1,2}
			dayOffset = dayOffset[ZombRand(#dayOffset)+1]

			local startDay = math.min(nightsSurvived+dayOffset, cutOffDay)
			local startTime = ZombRand(flightHours[1],flightHours[2]+1)
			print(" -Scheduled: "..selectedPresetID.." [Day:"..startDay.." Time:"..startTime.."]")
			eHeliEvent_new(startDay, startTime, selectedPresetID)
		end
	end
end
Events.EveryHours.Add(eHeliEvent_ScheduleNew)



--Checks every hour if there is an event scheduled to engage
function eHeliEvent_Loop()
	local GT = getGameTime()
	local nightsSurvived = GT:getNightsSurvived()
	local HOUR = GT:getHour()
	local events = GT:getModData()["EventsOnSchedule"]

	for k,v in pairs(events) do
		if v.triggered then
			--clean out old events if any
			GT:getModData()["EventsOnSchedule"][k] = nil
		elseif (v.startDay <= nightsSurvived) and (v.startTime == HOUR) then
			print("EHE: LAUNCH INFO:  HELI ID:"..k.." - "..v.preset)
			if eHelicopter_PRESETS[v.preset] then
				eHeliEvent_engage(k)
			else
				GT:getModData()["EventsOnSchedule"][k] = nil
			end
		end
	end
end

Events.EveryHours.Add(eHeliEvent_Loop)