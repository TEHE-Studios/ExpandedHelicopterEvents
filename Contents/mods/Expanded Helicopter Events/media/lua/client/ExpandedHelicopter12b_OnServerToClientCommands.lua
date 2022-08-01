require "ExpandedHelicopter00c_SpawnerAPI"
require "ExpandedHelicopter01f_ShadowSystem"
require "ExpandedHelicopter01b_MainSounds"
require "ExpandedHelicopter11_EventMarkerHandler"


storedShadows = {}
storedShadowsUpdateTimes = {}
function eventShadowHandler.updateForPlayer(player)
	local currentTime = getTimeInMillis()
	for shadowID,_ in pairs(storedShadows) do
		if storedShadowsUpdateTimes[shadowID]+5000 <= currentTime then
			print("-- EHE: WARN: eventShadowHandler.updateForPlayer: no update received")
			---@type WorldMarkers.GridSquareMarker
			local shadow = storedShadows[shadowID]
			shadow:setAlpha(0)
			storedShadows[shadowID] = nil
			storedShadowsUpdateTimes[shadowID] = nil
		end
	end
end
Events.OnPlayerUpdate.Add(eventShadowHandler.updateForPlayer)


storedLooperEvents = {}
storedLooperEventsUpdateTimes = {}
function eventSoundHandler.updateForPlayer(player)
	local currentTime = getTimeInMillis()
	for emitterID,timeStamp in pairs(storedLooperEventsUpdateTimes) do
		if timeStamp+5000 <= currentTime then
			print("-- EHE: WARN: eventSoundHandler.updateForPlayer: no update received")
			---@type FMODSoundEmitter | BaseSoundEmitter emitter
			local emitter = storedLooperEvents[emitterID]
			emitter:stopAll()
			storedLooperEventsUpdateTimes[emitterID] = nil
		end
	end
end
Events.OnPlayerUpdate.Add(eventSoundHandler.updateForPlayer)


function eventMarkerHandler.updateForPlayer(player)
	local personalMarkers = eventMarkerHandler.markers[player]
	if personalMarkers then
		for id,_ in pairs(personalMarkers) do
			local marker = eventMarkerHandler.markers[player][id]
			if marker then
				local currentTime = getGametimeTimestamp()
				local currentTimeMS = getTimeInMillis()
				local expireTime = eventMarkerHandler.expirations[player][id]
				if (expireTime <= currentTime) and (marker.lastUpdateTime+100 <= currentTimeMS) then
					print("-- EHE: WARN: eventMarkerHandler.updateForPlayer: no update received")
					marker:setDuration(0)
				end
			end
		end
	end
end
Events.OnPlayerUpdate.Add(eventMarkerHandler.updateForPlayer)


--if isClient() then sendClientCommand(player, module, command, args) end -- to server
local function onCommand(_module, _command, _dataA, _dataB)
	--clientside
	if _module == "sendLooper" then
		--print("--pong")
		if _command == "play" then
			--print("--play")
			eventSoundHandler:handleLooperEvent(_dataA.reusableID,
					{soundEffect=_dataA.soundEffect, x=_dataA.coords.x, y=_dataA.coords.y, z=_dataA.coords.z}, _dataA.command)

		elseif _command == "setPos" then
			--print("--loop setPos")
			eventSoundHandler:handleLooperEvent(_dataA.reusableID, {x=_dataA.coords.x, y=_dataA.coords.y, z=_dataA.coords.z}, _dataA.command)

		elseif _command == "stop" then
			--print("--loop stop")
			eventSoundHandler:handleLooperEvent(_dataA.reusableID, _dataA.soundEffect, _dataA.command)

		elseif _command == "drop" then
			--print("--loop drop")
			eventSoundHandler:handleLooperEvent(_dataA.reusableID, nil, _dataA.command)
		end

	elseif _module == "eventMarkerHandler" and _command == "setOrUpdateMarker" then
		--sendServerCommand("EventMarkerHandler", "setOrUpdateMarker", _dataB)
		eventMarkerHandler.setOrUpdate(_dataA.eventID, _dataA.icon, _dataA.duration, _dataA.posX, _dataA.posY, true)

	elseif _module == "eventShadowHandler" and _command == "setShadowPos" then
		--sendServerCommand("eventShadowHandler", "setShadowPos", _dataB)
		eventShadowHandler:setShadowPos(_dataA.eventID, _dataA.texture, _dataA.x, _dataA.y, _dataA.z, true)
	end
end
--Events.OnClientCommand.Add(onCommand)--/client/ to server
Events.OnServerCommand.Add(onCommand)--/server/ to client
