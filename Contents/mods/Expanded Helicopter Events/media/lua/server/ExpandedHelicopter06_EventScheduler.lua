require "ExpandedHelicopter00f_WeatherImpact"
require "ExpandedHelicopter00e_EHEGlobalModData"
require "ExpandedHelicopter00a_Util"
require "ExpandedHelicopter09_EasyConfigOptions"
require "ExpandedHelicopter02a_Presets"
require "ExpandedHelicopter01a_MainVariables"

---Inserts a new eHeliEvent (table) to the "EventsOnSchedule" table
---@param startDay number Day scheduled for start of this event
---@param startTime number Hour scheduled for the start of this event
---@param preset string Name of preset found in PRESETS
function eHeliEvent_new(startDay, startTime, preset)
	if (not startDay) or (not startTime) then return end

	local newEvent = {["startDay"] = startDay, ["startTime"] = startTime, ["preset"] = preset, ["triggered"] = false}

	local globalModData = getExpandedHeliEventsModData()
	table.insert(globalModData.EventsOnSchedule, newEvent)
	triggerEvent("EHE_ServerModDataReady", false)
end


--Engages specific eHeliEvent based on ID
---@param ID number position in "EventsOnSchedule"
function eHeliEvent_engage(ID)

	local globalModData = getExpandedHeliEventsModData()
	local eHeliEvent = globalModData.EventsOnSchedule[ID]

	if not eHeliEvent or not eHeliEvent.preset then
		print("ERROR: scheduler given invalid event (preset:"..tostring(eHeliEvent.preset)..") - CLEARING")
		globalModData.EventsOnSchedule[ID] = nil
		triggerEvent("EHE_ServerModDataReady", false)
		return
	end

	--check if the event will occur
	local willFly,_ = eHeliEvent_weatherImpact()
	local foundTarget = eHelicopter:findTarget(nil, "eHeliEvent_engage")

	if SandboxVars.ExpandedHeli["Frequency_"..eHeliEvent.preset]==1 then
		willFly = false
		eHeliEvent.triggered = true
	end

	if willFly and foundTarget then
		---@type eHelicopter
		local heli = getFreeHelicopter(eHeliEvent.preset)
		if heli then
			eHeliEvent.triggered = true
			heli:launch(foundTarget)
		end
	end
	triggerEvent("EHE_ServerModDataReady", false)
end


local eventsForScheduling
function eHeliEvents_setEventsForScheduling()
	if not eventsForScheduling then
		eventsForScheduling = {}
		for presetID,presetVars in pairs(eHelicopter_PRESETS) do

			local forScheduling = presetVars.forScheduling

			if forScheduling then
				if SandboxVars.ExpandedHeli.AirRaidSirenEvent==false and presetID=="air_raid" then forScheduling = false end
				local presetFreq = SandboxVars.ExpandedHeli["Frequency_"..presetID]
				if presetFreq and presetFreq==1 then forScheduling = false end
			end

			if forScheduling then
				table.insert(eventsForScheduling, presetID)
			end
		end
	end
end


---Handles setting up the event scheduler
function eHeliEvents_OnGameStart()
	local globalModData = getExpandedHeliEventsModData()
	eHeliEvents_setEventsForScheduling()
	--if eHelicopterSandbox.config.resetEvents == true, reset
	if eHelicopterSandbox.config.resetEvents == true then
		EasyConfig_Chucked.loadConfig()
		globalModData.EventsOnSchedule = {}
		globalModData.DaysBeforeApoc = false
		globalModData.DayOfLastCrash = false
		local spawnerList = SpawnerTEMP.getOrSetPendingSpawnsList()
		spawnerList = {}
		local EHE = EasyConfig_Chucked.mods["ExpandedHelicopterEvents"]
		local resetEvents = EHE.menu["resetEvents"]
		resetEvents.selectedValue = "false"
		resetEvents.selectedLabel = "false"
		EHE.config.resetEvents = false
		EasyConfig_Chucked.saveConfig()
	end
	globalModData.DaysBeforeApoc = globalModData.DaysBeforeApoc or eHeli_getDaysSinceApoc()
	globalModData.DayOfLastCrash = globalModData.DayOfLastCrash or getGameTime():getNightsSurvived()
	--if no EventsOnSchedule found make it an empty list
	if not globalModData.EventsOnSchedule then
		globalModData.EventsOnSchedule = {}
	end
	triggerEvent("EHE_ServerModDataReady", false)
end
Events.OnGameStart.Add(eHeliEvents_OnGameStart)


---@param targetDate table table of numbers: 1=month, 2=day
---@param expectedDates table table of dates (like above)
function eHeliEvent_processSchedulerDates(targetDate, expectedDates)

	if (type(targetDate)~="table") or (type(expectedDates)~="table") or (#targetDate<=0) or (#expectedDates<=0) then
		return false
	end

	local targetMonth = targetDate[1]
	local targetDay = targetDate[2] or 1

	local expectedDateMIN = expectedDates[1]
	local MIN_month
	local MIN_day
	if expectedDateMIN and type(expectedDateMIN)=="table" then
		MIN_month = expectedDateMIN[1]
		MIN_day = expectedDateMIN[2]
	end

	local expectedDateMAX = expectedDates[2]
	local MAX_month
	local MAX_day
	if expectedDateMAX and type(expectedDateMAX)=="table" then
		MAX_month = expectedDateMAX[1]
		MAX_day = expectedDateMAX[2]
	end

	--no expected max for range; if month is current; if min day is current day is min day = true
	if not expectedDateMAX then
		if (MIN_month==targetMonth) and ((not MIN_day) or (MIN_day==targetDay)) then
			return true
		end
	else
		if ((MAX_month<=targetMonth) and ((not MAX_day) or (MAX_day<=targetDay))) and ((MAX_month>=targetMonth) and ((not MAX_day) or (MAX_day>=targetDay))) then
			return true
		end
	end
	return false
end


function eHeliEvent_determineContinuation()
	local continue = SandboxVars.ExpandedHeli.ContinueSchedulingEvents
	-- 1=No, 2=All, 3=Late-Game

	---safely handle old sandbox options
	local oldContinue = SandboxVars.ExpandedHeli.ContinueScheduling~=nil
	if oldContinue then
		continue = oldContinue==true and 2 or 1
		SandboxVars.ExpandedHeli.ContinueScheduling = nil
	end

	local oldContinueLG = SandboxVars.ExpandedHeli.ContinueSchedulingLateGameOnly~=nil
	if oldContinueLG then
		continue = oldContinueLG==true and 3 or 1
		SandboxVars.ExpandedHeli.ContinueSchedulingLateGameOnly = nil
	end

	if oldContinue or oldContinueLG then
		SandboxVars.ExpandedHeli.ContinueSchedulingEvents = continue
	end

	return continue>1, continue>=3
end


function eHeliEvent_ScheduleNew(nightsSurvived,currentHour,freqOverride,noPrint)
	local GT = getGameTime()
	nightsSurvived = nightsSurvived or GT:getNightsSurvived()
	currentHour = currentHour or GT:getHour()
	local continueScheduling, csLateGameOnly = eHeliEvent_determineContinuation()
	local globalModData = getExpandedHeliEventsModData()
	local daysIntoApoc = (globalModData.DaysBeforeApoc or 0)+nightsSurvived

	local eventIDsScheduled = {}
	for k,v in pairs(globalModData.EventsOnSchedule) do
		if not v.triggered and v.startDay == nightsSurvived then
			eventIDsScheduled[v.preset] = true
		end
	end

	local schedulerStartDay = SandboxVars.ExpandedHeli.StartDay or 0
	local schedulerDuration = SandboxVars.ExpandedHeli.SchedulerDuration or 90

	if (continueScheduling or (daysIntoApoc <= (schedulerStartDay+schedulerDuration))) and (daysIntoApoc >= schedulerStartDay) then
		local options = {}

		eHeliEvents_setEventsForScheduling()

		if #eventsForScheduling <= 0 then
			return
		end

		for k,presetID in pairs(eventsForScheduling) do

			local presetSettings = eHelicopter_PRESETS[presetID]
			if (not eventIDsScheduled[presetID]) and presetSettings and eHelicopter then

				local schedulingFactor = presetSettings.schedulingFactor or eHelicopter.schedulingFactor
				local flightHours = presetSettings.flightHours or eHelicopter.flightHours
				local startDay, cutOffDay = fetchStartDayAndCutOffDay(presetSettings)
				local dayAndHourInRange = ((daysIntoApoc >= startDay) and (daysIntoApoc <= cutOffDay) and (currentHour >= flightHours[1]) and (currentHour <= flightHours[2]))

				local specialDatesObserved = presetSettings.eventSpecialDates or eHelicopter.eventSpecialDates
				local specialDatesInRange = false
				if specialDatesObserved then
					if specialDatesObserved.inGameDates then
						local currentInGameDate = {GT:getMonth(), GT:getDay()}
						if eHeliEvent_processSchedulerDates(currentInGameDate,specialDatesObserved.inGameDates) == true then
							specialDatesInRange = true
						end
					end
					if specialDatesObserved.systemDates then
						local osDate = os.date("*t")
						local currentSystemDate = {osDate.month, osDate.day}
						if eHeliEvent_processSchedulerDates(currentSystemDate,specialDatesObserved.systemDates) == true then
							specialDatesInRange = true
						end
					end
				end

				local freq = 3
				local presetFreq = SandboxVars.ExpandedHeli["Frequency_"..presetID]
				if presetFreq then
					freq = presetFreq-1
					if freq == 5 then freq = 50 end
				end

				freq = freqOverride or freq

				--the greater the frequency the smaller the denominator
				local probabilityDenominator = ((10-freq)*2500)
				--less frequent over time
				probabilityDenominator = probabilityDenominator+(1000*(daysIntoApoc/SandboxVars.ExpandedHeli.SchedulerDuration))

				local eventAvailable = false

				if dayAndHourInRange then
					eventAvailable = true

					--if (daysIn > startDay) AND (not ignoring never-end) AND (never-end is on)
				elseif ((daysIntoApoc >= startDay) and (not presetSettings.ignoreContinueScheduling) and (continueScheduling==true and ( (not csLateGameOnly) or (csLateGameOnly and cutOffDay>=SandboxVars.ExpandedHeli.SchedulerDuration) )) ) then
					eventAvailable = true
				end

				if (specialDatesObserved and (not specialDatesInRange)) then
					eventAvailable = false
				end

				--[[DEBUG] print(" processing preset: "..presetID.." a:"..tostring(dayAndHourInRange).." b:"..tostring(SandboxVars.ExpandedHeli.csLateGameOnly==true).." c:"..chance)--]]

				if eventAvailable then
					local weight = eHelicopter.eventSpawnWeight*freq
					local probabilityNumerator = math.floor((freq*schedulingFactor) + 0.5 )

					for i=1, weight do
						if (ZombRand(probabilityDenominator) <= probabilityNumerator) then
							table.insert(options, presetID)
						end
					end
				end
			end
		end

		--[[DEBUG]
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

			local freq = SandboxVars.ExpandedHeli["Frequency_"..selectedPresetID]
			local insane = (freqOverride or freq) == 6

			local selectedPreset = eHelicopter_PRESETS[selectedPresetID]
			local flightHours = selectedPreset.flightHours or eHelicopter.flightHours
			local startDay, cutOffDay = fetchStartDayAndCutOffDay(selectedPreset)

			local iterations = insane and 10 or 1

			local latestStartDay

			for i=1, iterations do
				local dayOffset = {0,0,0,1,1,2}
				dayOffset = dayOffset[ZombRand(#dayOffset)+1]

				local nextStartDay = math.min(nightsSurvived+dayOffset, cutOffDay)
				local startTime = ZombRand(flightHours[1],flightHours[2]+1)

				if startTime > 24 then startTime = startTime-24 end

				if not noPrint==true then print(" -Scheduled: "..selectedPresetID.." [Day:"..nextStartDay.." Time:"..startTime.."]") end

				latestStartDay = math.max(nextStartDay, (latestStartDay or 0))

				eHeliEvent_new(nextStartDay, startTime, selectedPresetID)
			end

			if latestStartDay then
				---Push vanilla event down the calendar.
				local pushVanillaDay = math.max(GT:getHelicopterDay1(),latestStartDay+3)
				GT:setHelicopterDay(pushVanillaDay)
			end
		end
	end
end


--Checks every hour if there is an event scheduled to engage
function eHeliEvent_Loop()

	local GT = getGameTime()
	local globalModData = getExpandedHeliEventsModData()
	local DAY = GT:getNightsSurvived()
	local HOUR = GT:getHour()
	local events = globalModData.EventsOnSchedule

	for k,v in pairs(events) do

		if v.triggered or (not eHelicopter_PRESETS[v.preset]) then
		elseif (v.startDay <= DAY) and (v.startTime == HOUR) then
			if eHelicopter_PRESETS[v.preset] then
				print(" \[EHE\]: SCHEDULED-LAUNCH INFO:  ["..k.."] - day:"..tostring(v.startDay).." time:"..tostring(v.startTime).." id:"..tostring(v.preset).." done:"..tostring(v.triggered))
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

if not isClient() then
	Events.OnTick.Add(eHeliEvent_OnHour)
end