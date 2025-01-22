require "ExpandedHelicopter06_EventScheduler"

local EHETI_eHeliEvent_ScheduleNew = eHeliEvent_ScheduleNew
function eHeliEvent_ScheduleNew(startDay, startTime, preset)
	if eHelicopterSandbox.config.twitchIntegrationOnly == false then
		EHETI_eHeliEvent_ScheduleNew(startDay, startTime, preset)
	end
end


local function twitch_MoveHeliCloser(heli, playerChar)
	if not heli then return end
	print("EHE-TI: "..heli:heliToString().." moved closer to "..playerChar:getUsername()..".")
	local min, max = eheBounds.threshold/2, eheBounds.threshold-1
	local offsetX = ZombRand(min, max)
	if ZombRand(101) <= 50 then offsetX = 0-offsetX end
	local offsetY = ZombRand(min, max)
	if ZombRand(101) <= 50 then offsetY = 0-offsetY end
	heli.currentPosition:set(playerChar:getX()+offsetX, playerChar:getY()+offsetY, heli.height)
end


--Engages specific eHeliEvent based on ID
---@param ID number position in "EventsOnSchedule"
function eHeliEvent_engage(ID)

	local globalModData = getExpandedHeliEventsModData()
	local eHeliEvent = globalModData.EventsOnSchedule[ID]

	--check if the event will occur
	local willFly,_ = eHeliEvent_weatherImpact()
	local foundTarget

	if eHeliEvent.twitchTarget then
		willFly = true
		print(" --- EHE-TI: twitchTarget:"..eHeliEvent.twitchTarget)

		local players = getActualPlayers()
		for _,player in pairs(players) do
			if player:getUsername() == eHeliEvent.twitchTarget then
				foundTarget = player
			end
		end
		if not foundTarget then
			print(" ---- EHE-TI: Cannot find "..eHeliEvent.twitchTarget..".")
			eHeliEvent.triggered = true
			willFly = false
		end
	else
		if eHelicopterSandbox.config.twitchIntegrationOnly == true then
			eHeliEvent.triggered = true
			print(" ---- EHE-TI: "..eHeliEvent.preset.." event bypassed.")
			return
		end

		foundTarget = eHelicopter:findTarget(nil, "eHeliEvent_engage")
		if SandboxVars.ExpandedHeli["Frequency_"..eHeliEvent.preset]==1 then
			eHeliEvent.triggered = true
			willFly = false
		end
	end

	if willFly and foundTarget then
		---@type eHelicopter
		local heli = getFreeHelicopter(eHeliEvent.preset)
		if heli then
			eHeliEvent.triggered = true
			heli:launch(foundTarget, (not not eHeliEvent.twitchTarget) )
			if eHeliEvent.twitchTarget then twitch_MoveHeliCloser(heli, foundTarget) end
		end
	end

	triggerEvent("EHE_ServerModDataReady", false)
end


function eHeliEvent_new(startDay, startTime, preset, twitchTarget)
	if (not startDay) or (not startTime) then return end

	local newEvent = {["startDay"] = startDay, ["startTime"] = startTime, ["preset"] = preset, ["triggered"] = false}

	if twitchTarget then
		newEvent["twitchTarget"] = twitchTarget
		print(" ---- EHE-TI: Scheduled: "..tostring(preset).." d:"..tostring(startDay).." t: "..tostring(startTime).." tT:"..tostring(twitchTarget))
	end

	local globalModData = getExpandedHeliEventsModData()
	table.insert(globalModData.EventsOnSchedule, newEvent)
	triggerEvent("EHE_ServerModDataReady", false)
	eHeliEvent_Loop()
end