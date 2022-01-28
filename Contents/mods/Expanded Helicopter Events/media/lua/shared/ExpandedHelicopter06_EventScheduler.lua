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
---Events are handled as tables because ModData does not save Lua "classes" properly, even though they are really tables.
function eHeliEvent_new(startDay, startTime, preset)
	if (not startDay) or (not startTime) then
		return
	end
	local newEvent = {["startDay"] = startDay, ["startTime"] = startTime, ["preset"] = preset, ["triggered"] = false}

	local globalModData = getExpandedHeliEventsModData()
	table.insert(globalModData.EventsOnSchedule, newEvent)
end


--Engages specific eHeliEvent based on ID
---@param ID number position in "EventsOnSchedule"
function eHeliEvent_engage(ID)

	local globalModData = getExpandedHeliEventsModData()
	local eHeliEvent = globalModData.EventsOnSchedule[ID]

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
			eHeliEvent.triggered = true
			heli:launch(foundTarget)
		end
	end
end


local eventsForScheduling
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
	globalModData.DaysBeforeApoc = globalModData.DaysBeforeApoc or eHeli_getDaysBeforeApoc()
	globalModData.DayOfLastCrash = globalModData.DayOfLastCrash or getGameTime():getNightsSurvived()
	--if no EventsOnSchedule found make it an empty list
	if not globalModData.EventsOnSchedule then
		globalModData.EventsOnSchedule = {}
	end
end
Events.OnGameStart.Add(eHeliEvents_OnGameStart)


---@param targetDate table table of numbers: 1=month, 2=day
---@param expectedDates table table of dates (like above)
function eHeliEvent_processSchedulerDates(targetDate, expectedDates)

	if (type(targetDate)~="table") or (type(expectedDates)~="table") or (#targetDate<=0) or (#expectedDates<=0) then
		print ("A")
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


function eHeliEvent_ScheduleNew(nightsSurvived,currentHour,freqOverride,noPrint)
	local GT = getGameTime()
	nightsSurvived = nightsSurvived or GT:getNightsSurvived()
	currentHour = currentHour or GT:getHour()
	local neverEnd = SandboxVars.ExpandedHeli.NeverEnding
	local globalModData = getExpandedHeliEventsModData()
	local daysIntoApoc = (globalModData.DaysBeforeApoc or 0)+nightsSurvived

	local eventIDsScheduled = {}
	for k,v in pairs(globalModData.EventsOnSchedule) do
		if not v.triggered and v.startDay == nightsSurvived then
			eventIDsScheduled[v.preset] = true
		end
	end
	
	if neverEnd or (daysIntoApoc <= SandboxVars.ExpandedHeli.CutOffDay) then
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
				end

				freq = freqOverride or freq

				--the greater the frequency the smaller the denominator
				local probabilityDenominator = ((10-freq)*2500)
				--less frequent over time
				probabilityDenominator = probabilityDenominator+(1000*(daysIntoApoc/SandboxVars.ExpandedHeli.CutOffDay))

				local eventAvailable = false

				if dayAndHourInRange then
					eventAvailable = true
				--if (daysIn > startDay) AND (not ignoring never-end) AND (never-end is on)
				elseif ((daysIntoApoc >= startDay) and (not presetSettings.ignoreNeverEnding) and SandboxVars.ExpandedHeli.NeverEnding==true) then
					eventAvailable = true
				end

				if (specialDatesObserved and (not specialDatesInRange)) then
					eventAvailable = false
				end

				--[[DEBUG] print(" processing preset: "..presetID.." a:"..tostring(dayAndHourInRange).." b:"..tostring(SandboxVars.ExpandedHeli.NeverEnding==true).." c:"..chance)--]]

				if eventAvailable then
					local weight = eHelicopter.eventSpawnWeight*freq
					local playersOnlineNum = 1
					local playersOnline = getOnlinePlayers()
					if playersOnline then
						playersOnlineNum = playersOnline:size()
					end
					
					local probabilityNumerator = math.floor(((freq*schedulingFactor)/playersOnlineNum) + 0.5 )

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
			local selectedPreset = eHelicopter_PRESETS[selectedPresetID]
			local flightHours = selectedPreset.flightHours or eHelicopter.flightHours
			local startDay, cutOffDay = fetchStartDayAndCutOffDay(selectedPreset)

			local dayOffset = {0,0,0,1,1,2}
			dayOffset = dayOffset[ZombRand(#dayOffset)+1]

			local nextStartDay = math.min(nightsSurvived+dayOffset, cutOffDay)
			local startTime = ZombRand(flightHours[1],flightHours[2]+1)

			if startTime >= 24 then
				startTime = startTime-24
			end

			if not noPrint==true then
				print(" -Scheduled: "..selectedPresetID.." [Day:"..nextStartDay.." Time:"..startTime.."]")
			end
			eHeliEvent_new(nextStartDay, startTime, selectedPresetID)
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

	--if getDebug() then print("---DAY:"..DAY.." HOUR:"..HOUR.."  isClient:"..tostring(isClient()).." isServer:"..tostring(isServer())) end
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