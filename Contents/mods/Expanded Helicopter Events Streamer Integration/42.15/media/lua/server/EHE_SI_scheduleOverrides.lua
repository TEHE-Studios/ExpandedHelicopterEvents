require "EHE_eventScheduler"

local config = require "EHE_SI_config"

local EHE_SI_eHeliEvent_ScheduleNew = eHeliEvent_ScheduleNew
function eHeliEvent_ScheduleNew(startDay, startTime, preset)
	if config.checkValue("EHE_SI_IntegrationOnly") == false then
		EHE_SI_eHeliEvent_ScheduleNew(startDay, startTime, preset)
	end
end


local function integration_MoveHeliCloser(heli, playerChar)
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

	if eHeliEvent.streamerTarget then
		willFly = true

		local players = getActualPlayers()
		for _,player in pairs(players) do
			if player:getUsername() == eHeliEvent.streamerTarget then
				foundTarget = player
			end
		end
		if not foundTarget then
			eHeliEvent.triggered = true
			willFly = false
		end
	else
		if config.checkValue("EHE_SI_IntegrationOnly") == true then eHeliEvent.triggered = true return end

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
			heli:launch(foundTarget, (not not eHeliEvent.streamerTarget) )
			if eHeliEvent.streamerTarget then integration_MoveHeliCloser(heli, foundTarget) end
		end
	end

	triggerEvent("EHE_ServerModDataReady", false)
end


function eHeliEvent_new(startDay, startTime, preset, SI_Target)
	if (not startDay) or (not startTime) then return end

	local newEvent = {["startDay"] = startDay, ["startTime"] = startTime, ["preset"] = preset, ["triggered"] = false}

	if SI_Target then
		newEvent["streamerTarget"] = SI_Target
		print(" ---- EHE-SI: Scheduled: "..tostring(preset).." d:"..tostring(startDay).." t: "..tostring(startTime).." tT:"..tostring(SI_Target))
	end

	local globalModData = getExpandedHeliEventsModData()
	table.insert(globalModData.EventsOnSchedule, newEvent)
	triggerEvent("EHE_ServerModDataReady", false)
	eHeliEvent_Loop()
end