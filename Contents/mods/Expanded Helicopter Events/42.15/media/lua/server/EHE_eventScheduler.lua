local eHelicopter = require "EHE_mainVariables"
local modData = require "EHE_globalModData"
local util = require "EHE_util"
local mainCore = require "EHE_heliCore"
require "EHE_presets"


--- Could look into utilizing the fact that days are tracked in float
local lastTickHour = -1
local function eHeliEvent_OnHour()
	local gameTime = getGameTime()
	local currentHour = gameTime:getHour()
	if currentHour ~= lastTickHour then
		lastTickHour = currentHour
		eHeliEvent_ScheduleNew()
		eHeliEvent_Loop()
	end
end

if not isClient() then Events.OnTick.Add(eHeliEvent_OnHour) end


---@param startDay number Day scheduled for start of this event
---@param startTime number Hour scheduled for the start of this event
---@param preset string Name of preset found in PRESETS
function eHeliEvent_new(startDay, startTime, preset)
	if (not startDay) or (not startTime) then return end

	local newEvent = {["startDay"] = startDay, ["startTime"] = startTime, ["preset"] = preset, ["triggered"] = false}

	local globalModData = modData.get()
	table.insert(globalModData.EventsOnSchedule, newEvent)
	triggerEvent("EHE_ServerModDataReady", false)
end


---@param ID number position in "EventsOnSchedule"
function eHeliEvent_engage(ID)

	local globalModData = modData.get()
	local eHeliEvent = globalModData.EventsOnSchedule[ID]

	if not eHeliEvent or not eHeliEvent.preset then
		print("ERROR: scheduler given invalid event (preset:"..tostring(eHeliEvent.preset)..") - CLEARING")
		globalModData.EventsOnSchedule[ID] = nil
		triggerEvent("EHE_ServerModDataReady", false)
		return
	end


	local willFly,_ = util.weatherImpact()
	local foundTarget = eHelicopter:findTarget(nil, "eHeliEvent_engage")

	local frequencyDisabled = SandboxVars.ExpandedHeli["Frequency_"..eHeliEvent.preset]==1
	if frequencyDisabled then
		willFly = false
		eHeliEvent.triggered = true
	end

	print("[EHE] engage: preset="..tostring(eHeliEvent.preset).." willFly="..tostring(willFly).." foundTarget="..tostring(foundTarget~=nil))

	if willFly and foundTarget then
		local heli = mainCore.getFreeHelicopter(eHeliEvent.preset)
		if heli then
			eHeliEvent.triggered = true
			heli:launch(foundTarget)
			triggerEvent("EHE_ServerModDataReady", false)
		else
			print("[EHE] engage: no free helicopter available")
		end
	elseif not willFly and not frequencyDisabled then
		local selectedPreset = eHelicopter_PRESETS[eHeliEvent.preset]
		local flightHours = (selectedPreset and selectedPreset.flightHours) or eHelicopter.flightHours
		local rawNewTime = eHeliEvent.startTime + 3

		if rawNewTime <= flightHours[2] then
			print("[EHE] engage: weather blocked - pushing startTime "..eHeliEvent.startTime.." -> "..wrappedNewTime.." (raw "..rawNewTime.." within flightHours ceiling "..flightHours[2]..")")
			eHeliEvent.startTime = wrappedNewTime
			triggerEvent("EHE_ServerModDataReady", false)
		else
			print("[EHE] engage: weather blocked - raw push "..rawNewTime.." exceeds flightHours ceiling "..flightHours[2].."; event will expire")
		end
	end
end


local eventsForScheduling
local function eHeliEvents_setEventsForScheduling()
	if not eventsForScheduling then
		eventsForScheduling = {}
		for presetID, presetVars in pairs(eHelicopter_PRESETS) do
			local forScheduling = presetVars.forScheduling

			if forScheduling then
				if SandboxVars.ExpandedHeli.AirRaidSirenEvent==false and presetID=="air_raid" then forScheduling = false end
				local presetFreq = SandboxVars.ExpandedHeli["Frequency_"..presetID]
				if presetFreq and presetFreq==1 then forScheduling = false end
			end

			if forScheduling then table.insert(eventsForScheduling, presetID) end
		end
		print("[EHE] eventsForScheduling built: "..#eventsForScheduling.." presets")
	end
end


local function eHeliEvents_getLastScheduledApocDay()
	local globalModData = modData.get()
	local daysBeforeApoc = globalModData.DaysBeforeApoc or 0
	local lastEventDay = nil
	for _, event in pairs(globalModData.EventsOnSchedule) do
		local apocDay = daysBeforeApoc + event.startDay
		if not lastEventDay or apocDay > lastEventDay then
			lastEventDay = apocDay
		end
	end
	return lastEventDay
end


---@param fromApocDay number start of range in apoc days (inclusive)
---@param toApocDay number end of range in apoc days (inclusive)
local function eHeliEvents_prefillSchedule(fromApocDay, toApocDay)
	local globalModData = modData.get()
	local daysBeforeApoc = globalModData.DaysBeforeApoc or 0
	local startApocDay = math.max(math.floor(fromApocDay), math.floor(daysBeforeApoc + util.getWorldAgeDays()))

	print("[EHE] prefillSchedule: filling apocDays "..startApocDay.." to "..toApocDay)

	for apocDay = startApocDay, toApocDay do
		eHeliEvent_ScheduleNew(apocDay - daysBeforeApoc, 12, nil, true)
	end

	triggerEvent("EHE_ServerModDataReady", false)
	print("[EHE] prefillSchedule: complete. toApocDay="..toApocDay)
end


local function eHeliEvents_OnGameStart()
	local globalModData = modData.get()
	eHeliEvents_setEventsForScheduling()
	globalModData.DaysBeforeApoc = globalModData.DaysBeforeApoc or util.getDaysSinceApoc()
	globalModData.DayOfLastCrash = globalModData.DayOfLastCrash or util.getWorldAgeDays()
	if not globalModData.EventsOnSchedule then
		globalModData.EventsOnSchedule = {}
	end

	local startDay = SandboxVars.ExpandedHeli.StartDay or 0
	local duration = SandboxVars.ExpandedHeli.SchedulerDuration or 90
	local daysBeforeApoc = math.floor(globalModData.DaysBeforeApoc or 0)
	local targetEnd = daysBeforeApoc + startDay + duration
	local lastScheduledApocDay = eHeliEvents_getLastScheduledApocDay() or 0

	print("[EHE] OnGameStart: lastScheduledApocDay="..lastScheduledApocDay.." targetEnd="..targetEnd.." worldAge="..tostring(util.getWorldAgeDays()))

	if lastScheduledApocDay < targetEnd then
		print("[EHE] OnGameStart: schedule incomplete, prefilling")
		eHeliEvents_prefillSchedule(daysBeforeApoc + startDay, targetEnd)
	else
		print("[EHE] OnGameStart: schedule up to date")
	end

	triggerEvent("EHE_ServerModDataReady", false)
end
Events.OnGameStart.Add(eHeliEvents_OnGameStart)


---@param targetDate table table of numbers: 1=month, 2=day
---@param expectedDates table table of dates (like above)
local function eHeliEvent_processSchedulerDates(targetDate, expectedDates)

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


local function eHeliEvent_determineContinuation()
	local continueMode = SandboxVars.ExpandedHeli.ContinueSchedulingEvents
	-- 1=No, 2=All, 3=Late-Game

	local oldContinue = SandboxVars.ExpandedHeli.ContinueScheduling~=nil
	if oldContinue then
		continueMode = oldContinue==true and 2 or 1
		SandboxVars.ExpandedHeli.ContinueScheduling = nil
	end

	local oldContinueLG = SandboxVars.ExpandedHeli.ContinueSchedulingLateGameOnly~=nil
	if oldContinueLG then
		continueMode = oldContinueLG==true and 3 or 1
		SandboxVars.ExpandedHeli.ContinueSchedulingLateGameOnly = nil
	end

	if oldContinue or oldContinueLG then
		SandboxVars.ExpandedHeli.ContinueSchedulingEvents = continueMode
	end

	return continueMode>1, continueMode>=3
end


function eHeliEvent_ScheduleNew(currentDay, currentHour, freqOverride, noPrint)
	local gameTime = getGameTime()
	local globalModData = modData.get()
	local continueScheduling, csLateGameOnly = eHeliEvent_determineContinuation()

	if not currentDay then
		local lastScheduledApocDay = eHeliEvents_getLastScheduledApocDay()
		if lastScheduledApocDay then
			local duration = SandboxVars.ExpandedHeli.SchedulerDuration or 90
			local daysBeforeApoc = globalModData.DaysBeforeApoc or 0
			local startDay = SandboxVars.ExpandedHeli.StartDay or 0
			local daysIntoApoc = daysBeforeApoc + util.getWorldAgeDays()
			local schedulerEndApocDay = daysBeforeApoc + startDay + duration
			local referenceDay = math.max(lastScheduledApocDay, schedulerEndApocDay)
			local extensionThreshold = referenceDay - duration * 0.5
			print("[EHE] ScheduleNew hourly: daysIntoApoc="..string.format("%.1f",daysIntoApoc).." lastScheduledApocDay="..lastScheduledApocDay.." referenceDay="..referenceDay.." threshold="..extensionThreshold.." continueScheduling="..tostring(continueScheduling))
			if continueScheduling and daysIntoApoc >= extensionThreshold then
				print("[EHE] ScheduleNew: extending schedule by "..duration.." days")
				eHeliEvents_prefillSchedule(lastScheduledApocDay + 1, lastScheduledApocDay + duration)
			end
			return
		end
	end

	currentDay = currentDay or util.getWorldAgeDays()
	currentHour = currentHour or gameTime:getHour()
	local daysIntoApoc = (globalModData.DaysBeforeApoc or 0) + currentDay

	local eventIDsScheduled = {}
	for _, event in pairs(globalModData.EventsOnSchedule) do
		if not event.triggered and event.startDay == currentDay then
			eventIDsScheduled[event.preset] = true
		end
	end

	local schedulerStartDay = SandboxVars.ExpandedHeli.StartDay or 0
	local schedulerDuration = SandboxVars.ExpandedHeli.SchedulerDuration or 90

	if not ((continueScheduling or (daysIntoApoc <= (schedulerStartDay+schedulerDuration))) and (daysIntoApoc >= schedulerStartDay)) then
		if not noPrint then print("[EHE] ScheduleNew: day "..currentDay.." outside scheduling window") end
		return
	end

	local options = {}

	eHeliEvents_setEventsForScheduling()

	if #eventsForScheduling <= 0 then
		print("[EHE] ScheduleNew: no schedulable events found")
		return
	end

	for _, presetID in pairs(eventsForScheduling) do

		local presetSettings = eHelicopter_PRESETS[presetID]
		if (not eventIDsScheduled[presetID]) and presetSettings and eHelicopter then

			local sfRaw = presetSettings.schedulingFactor or eHelicopter.schedulingFactor
			local schedulingFactor = type(sfRaw)=="table" and (sfRaw[1] or 1) or (sfRaw or 1)
			local startDay, cutOffDay = mainCore.fetchStartDayAndCutOffDay(presetSettings)
			local specialDatesObserved = presetSettings.eventSpecialDates or eHelicopter.eventSpecialDates
			local specialDatesInRange = false
			if specialDatesObserved then
				if specialDatesObserved.inGameDates then
					local currentInGameDate = {gameTime:getMonth(), gameTime:getDay()}
					if eHeliEvent_processSchedulerDates(currentInGameDate, specialDatesObserved.inGameDates) == true then
						specialDatesInRange = true
					end
				end
				if specialDatesObserved.systemDates then
					local osDate = os.date("*t")
					local currentSystemDate = {osDate.month, osDate.day}
					if eHeliEvent_processSchedulerDates(currentSystemDate, specialDatesObserved.systemDates) == true then
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

			local probabilityDenominator = ((10-freq)*2500)
			probabilityDenominator = probabilityDenominator + (1000*(daysIntoApoc/SandboxVars.ExpandedHeli.SchedulerDuration))

			local eventAvailable = false
			local dayInRange = ((daysIntoApoc >= startDay) and (daysIntoApoc <= cutOffDay))
			local startDayValid = daysIntoApoc >= startDay
			local notIgnore = not presetSettings.ignoreContinueScheduling
			local contScheduleValid = (continueScheduling==true and ((not csLateGameOnly) or (csLateGameOnly and cutOffDay>=SandboxVars.ExpandedHeli.SchedulerDuration)))

			if dayInRange then
				eventAvailable = true
			elseif (startDayValid and notIgnore and contScheduleValid) then
				eventAvailable = true
			end

			if (specialDatesObserved and (not specialDatesInRange)) then eventAvailable = false end

			if eventAvailable then
				local wRaw = presetSettings.eventSpawnWeight or eHelicopter.eventSpawnWeight
				local baseWeight = type(wRaw)=="table" and (wRaw[1] or 10) or (wRaw or 10)
				local wDropOff = type(wRaw)=="table" and wRaw[2] or nil
				local wMin = type(wRaw)=="table" and (wRaw[3] or 1) or 1
				local sfDropOff = type(sfRaw)=="table" and sfRaw[2] or nil
				local sfMin = type(sfRaw)=="table" and (sfRaw[3] or 1) or 1

				local progress = (cutOffDay > startDay) and math.max(0, math.min(1, (daysIntoApoc-startDay)/(cutOffDay-startDay))) or 0

				if sfDropOff then
					schedulingFactor = math.max(schedulingFactor - schedulingFactor*sfDropOff*progress, sfMin)
				end

				local probabilityNumerator = math.floor((freq*schedulingFactor) + 0.5)

				local weight = baseWeight
				if wDropOff then
					weight = math.max(baseWeight - baseWeight*wDropOff*progress, wMin)
				end
				weight = math.floor(weight * freq + 0.5)

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
	if not noPrint then
		print("[EHE] ScheduleNew day="..currentDay.." options="..#options.." selected="..tostring(selectedPresetID))
	end

	if selectedPresetID and (selectedPresetID ~= false) then

		local selectedFreq = SandboxVars.ExpandedHeli["Frequency_"..selectedPresetID]
		local insane = (freqOverride or selectedFreq) == 6
		local selectedPreset = eHelicopter_PRESETS[selectedPresetID]
		local flightHours = selectedPreset.flightHours or eHelicopter.flightHours
		local startDay, cutOffDay = mainCore.fetchStartDayAndCutOffDay(selectedPreset)
		local iterations = insane and 10 or 1
		local latestStartDay

		for i=1, iterations do
			local dayOffsets = {0,0,0,1,1,2,2}
			local dayOffset = dayOffsets[ZombRand(#dayOffsets)+1]

			local nextStartDay = math.min(currentDay+dayOffset, cutOffDay)
			local startTime = ZombRand(flightHours[1], flightHours[2]+1)
			if startTime > 24 then startTime = startTime-24 end

			if not noPrint then print(" -Scheduled: "..selectedPresetID.." [Day:"..nextStartDay.." Time:"..startTime.."]") end

			latestStartDay = math.max(nextStartDay, (latestStartDay or 0))

			eHeliEvent_new(nextStartDay, startTime, selectedPresetID)
		end

		if latestStartDay then
			local pushVanillaDay = math.max(gameTime:getHelicopterDay1(), latestStartDay+30)
			gameTime:setHelicopterDay(pushVanillaDay)
		end
	end
end


function eHeliEvent_Loop()

	local gameTime = getGameTime()
	local globalModData = modData.get()
	local worldDay = util.getWorldAgeDays()
	local currentHour = gameTime:getHour()
	local events = globalModData.EventsOnSchedule

	for eventID, event in pairs(events) do

		if event.triggered or (not eHelicopter_PRESETS[event.preset]) then
		elseif (event.startDay <= worldDay) and (event.startTime == currentHour) then
			if eHelicopter_PRESETS[event.preset] then
				print(" \[EHE\]: SCHEDULED-LAUNCH INFO:  ["..eventID.."] - day:"..tostring(event.startDay).." time:"..tostring(event.startTime).." id:"..tostring(event.preset).." done:"..tostring(event.triggered))
				eHeliEvent_engage(eventID)
			end
		end
	end
end
