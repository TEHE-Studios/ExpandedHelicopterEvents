require "EHE_SI_scheduleOverrides"

local config = require "EHE_SI_config"

local function onCommand(_module, _command, _player, _event)

    if _module == "EHE_SI_Integration" then
        if getDebug() then print("Received command from " .. _player:getUsername() .." [".._module..".".._command.."]") end
        if _command == "scheduleEvent" then

            local appliedDayDelay, appliedHourDelay = 0, 0
            local configDelayBetween = config and tonumber(config.checkValue("EHE_SI_HoursBetweenEvents")) or 0

            local tHoursDelayBetweenEvents = math.max(0, configDelayBetween)
            if tHoursDelayBetweenEvents>0 then
                local latestEventDay = 0
                local latestEventHour = 0

                local globalModData = getExpandedHeliEventsModData()
                for _,event in pairs(globalModData.EventsOnSchedule) do
                    if (eHelicopter_PRESETS[event.preset]) and event.streamerTarget and event.streamerTarget==_event.streamerTarget then
                        if (event.startDay > latestEventDay) then
                            latestEventDay = event.startDay
                            latestEventHour = event.startTime
                        elseif (event.startDay == latestEventDay) then
                            if (event.startTime > latestEventHour) then
                                latestEventHour = event.startTime
                            end
                        end
                    end
                end

                local DaysDelayBetweenEvents = math.floor(tHoursDelayBetweenEvents/24)
                local HoursDelayBetweenEvents = math.floor(tHoursDelayBetweenEvents-(DaysDelayBetweenEvents*24))

                appliedDayDelay = latestEventDay+DaysDelayBetweenEvents
                appliedHourDelay = latestEventHour+HoursDelayBetweenEvents
            end

            local configTimeBefore = config and tonumber(config.checkValue("EHE_SI_HoursBeforeEvents")) or 0
            local tHoursBeforeEvents = math.max(0, configTimeBefore)
            local DaysBeforeAllowed = math.floor(tHoursBeforeEvents/24)
            local HoursBeforeAllowed = math.floor(tHoursBeforeEvents-(DaysBeforeAllowed*24))

            local GT = getGameTime()
            local currentDay = GT:getNightsSurvived()
            local currentHour = GT:getHour()

            local startDay, startTime = 0, 0
            local dayHoursSelection = {
                ["beforeAllowed"]={ d = DaysBeforeAllowed, h = HoursBeforeAllowed },
                ["current"]={ d = currentDay, h = currentHour },
                ["appliedDelay"]={ d = appliedDayDelay, h = appliedHourDelay }
            }

            for ID,dayHours in pairs(dayHoursSelection) do

                if dayHours.h > 24 then
                    local dAdded = math.floor(dayHours.h/24)
                    dayHours.h = dayHours.h-(dAdded*24)
                    dayHours.d = dayHours.d+dAdded
                end

                if (dayHours.d > startDay) then
                    startDay = dayHours.d
                    startTime = dayHours.h
                elseif (dayHours.d == startDay) then
                    if (dayHours.h > startTime) then
                        startTime = dayHours.h
                    end
                end
            end

            if _event.presetID=="RANDOM" then _event.presetID = config.allowedPresets[ZombRand(#config.allowedPresets+1)] end

            print("-- scheduleEvent: KP:".._event.EHE_SI_Key.."  presetConfig:"..tostring(_event.presetID).."  presetID:"..tostring(_event.presetID).. " cD:"..currentDay.." cH:"..currentHour)

            if not _event.presetID or _event.presetID=="NONE" then return end

            eHeliEvent_new(startDay, startTime, _event.presetID, _event.streamerTarget)
        end
    end
end
Events.OnClientCommand.Add(onCommand)--/client/ to server