require "EHE_shadowSystem"
require "EHE_eventMarkerHandler"
require "EHE_util"


local function copyAgainst(tableA,tableB)
	if not tableA or not tableB then return end
	for key,value in pairs(tableB) do tableA[key] = value end
	for key,_ in pairs(tableA) do if not tableB[key] then tableA[key] = nil end end
end

---Credit to Konijima (Konijima#9279) for clearing up networking :thumbsup:
LuaEventManager.AddEvent("EHE_ClientModDataReady")

local ExpandedHeliEventsModData
local function receiveGlobalModData(name, data)
	if name == "ExpandedHelicopterEvents" then
		copyAgainst(ExpandedHeliEventsModData,data)
	end
end
Events.OnReceiveGlobalModData.Add(receiveGlobalModData)

function getExpandedHeliEventsModData_Client()
	triggerEvent("EHE_ServerModDataReady", false)
	return ExpandedHeliEventsModData
end

local function initGlobalModData(isNewGame)
	if isClient() then
		if ModData.exists("ExpandedHelicopterEvents") then
			ModData.remove("ExpandedHelicopterEvents")
		end
	end

	ExpandedHeliEventsModData = ModData.getOrCreate("ExpandedHelicopterEvents")
	if isNewGame then print("- New Game Initialized!") else print("- Existing Game Initialized!") end
	triggerEvent("EHE_ClientModDataReady")
end
Events.OnInitGlobalModData.Add(initGlobalModData)

local function onClientModDataReady()
	if not isClient() then copyAgainst(getExpandedHeliEventsModData(), ExpandedHeliEventsModData)
	else ModData.request("ExpandedHelicopterEvents") end
end
Events.EHE_ClientModDataReady.Add(onClientModDataReady)


function eventShadowHandler.updateForPlayer(player)
	local currentTime = getTimeInMillis()
	if not eventShadowHandler.storedShadows then return end
	for shadowID,shadowData in pairs(eventShadowHandler.storedShadows) do
		if shadowData.updateTime and shadowData.updateTime+5000 <= currentTime then
			eventShadowHandler.storedShadows[shadowID] = nil
		else
			eventShadowHandler.render(shadowID)
		end
	end
end
Events.OnPreUIDraw.Add(eventShadowHandler.updateForPlayer)


local clientSideEventSoundHandler = {}
storedLooperEvents = {}
storedLooperEventsLocations = {}
storedLooperEventsSoundEffects = {}
storedLooperEventsUpdateTimes = {}


---@param emitter BaseSoundEmitter | FMODSoundEmitter
---@param player IsoObject|IsoMovingObject|IsoGameCharacter|IsoPlayer
function clientSideEventSoundHandler.attenuateEmitterToPlayer(player, emitter, x, y, z, maxDistance)
	
	local pX, pY, pZ = player:getX(), player:getY(), player:getZ()
	maxDistance = maxDistance or (eheBounds.threshold * 0.8)
	local euclideanDist = math.sqrt((x - pX)^2 + (y - pY)^2 + (z - pZ)^2)
	local volume = math.max(0, 1 - (euclideanDist / maxDistance))

	emitter:setVolumeAll(volume)

	local angle = math.atan2(y - pY, x - pX)
	local emitterDist = 2
	local sound_x = pX + emitterDist * math.cos(angle)
	local sound_y = pY + emitterDist * math.sin(angle)
	local sound_z = pZ
	emitter:setPos(sound_x, sound_y, sound_z)
	emitter:tick()

	return getSquare(sound_x, sound_y, sound_z), volume
end


function clientSideEventSoundHandler.updateForPlayer(player)
	for ID,emitter in pairs(storedLooperEvents) do
		local timestamp = storedLooperEventsUpdateTimes[ID]
		if timestamp~=false then
			if timestamp >= getGametimeTimestamp() then
				local storedSounds = storedLooperEventsSoundEffects[ID]
				if storedSounds then
					for sound,ref in pairs(storedSounds) do
						if not emitter:isPlaying(ref) then

							local loc = storedLooperEventsLocations[ID]
							if not loc then

								for i=1, #ALL_HELICOPTERS do
									local helicopter = ALL_HELICOPTERS[i]
									---@type eHelicopter heli
									local heli = helicopter
									if heli and heli.ID and heli.ID == ID then
										local ehX, ehY, ehZ = heli:getXYZAsInt()
										loc = {x=ehX, y=ehY, z=ehZ}
									end
								end
							end
							clientSideEventSoundHandler:handleLooperEvent(ID, {soundEffect=sound, x=loc.x, y=loc.y, z=loc.z}, "play")
						end
					end
				end
			else
				clientSideEventSoundHandler:handleLooperEvent(ID, nil, "stopAll")
			end
		end
	end
end
Events.OnPlayerUpdate.Add(clientSideEventSoundHandler.updateForPlayer)


function clientSideEventSoundHandler:handleLooperEvent(reusableID, DATA, command)

	---@type BaseSoundEmitter | FMODSoundEmitter
	local soundEmitter = storedLooperEvents[reusableID]
	if not soundEmitter and (command == "setPos" or command == "play") then
		storedLooperEvents[reusableID] = getWorld():getFreeEmitter()
		soundEmitter = storedLooperEvents[reusableID]
		if command=="setPos" then command = "play" end
	end
	if soundEmitter then

		--[[
		if getDebug() and command ~= "setPos" then
			print("_data.reusableID: ", reusableID, "  cmd:",command,"  sound:", DATA and DATA.soundEffect, " loc:", DATA.x,",",DATA.y)
			getPlayer():Say("   _data.reusableID:: "..tostring(reusableID).." cmd:"..tostring(command).."  sound:"..tostring(DATA and DATA.soundEffect).." loc:"..tostring(DATA.x)..","..tostring(DATA.y))
		end
		--]]

		storedLooperEventsUpdateTimes[reusableID] = getGametimeTimestamp()+100

		if not DATA then
		else
			if command == "play" then
				local soundRef = storedLooperEventsSoundEffects[reusableID] and storedLooperEventsSoundEffects[reusableID][DATA.soundEffect]
				if soundRef and soundEmitter:isPlaying(soundRef) then
				else
					storedLooperEventsSoundEffects[reusableID] = storedLooperEventsSoundEffects[reusableID] or {}

					local sq, vol = clientSideEventSoundHandler.attenuateEmitterToPlayer(getPlayer(), soundEmitter, DATA.x, DATA.y, DATA.z)
					if sq then
						storedLooperEventsSoundEffects[reusableID][DATA.soundEffect] = soundEmitter:playSoundImpl(DATA.soundEffect, sq)
						soundEmitter:setVolumeAll(vol)
						soundEmitter:tick()
					end

				end
			end

			if command == "setPos" then
				clientSideEventSoundHandler.attenuateEmitterToPlayer(getPlayer(), soundEmitter, DATA.x,DATA.y,DATA.z)
				storedLooperEventsLocations[reusableID] = {x=DATA.x, y=DATA.y, z=DATA.z}
				--soundEmitter:setPos(DATA.x,DATA.y,DATA.z)
			end

			if command == "stop" then
				if DATA and DATA.soundEffect then
					if type(DATA.soundEffect)=="table" then
						for _,sound in pairs(DATA.soundEffect) do
							local soundRef = storedLooperEventsSoundEffects[reusableID] and storedLooperEventsSoundEffects[reusableID][sound]
							soundEmitter:stopSound(soundRef)
							soundEmitter:tick()
						end
					else
						local soundRef = storedLooperEventsSoundEffects[reusableID] and storedLooperEventsSoundEffects[reusableID][DATA.soundEffect]
						soundEmitter:stopSound(soundRef)
						soundEmitter:tick()
					end
				end
			end
		end

		if command == "stopAll" then

			soundEmitter:setVolumeAll(0)
			soundEmitter:stopAll()
			soundEmitter:tick()

			storedLooperEvents[reusableID] = nil
			storedLooperEventsSoundEffects[reusableID] = nil
			storedLooperEventsUpdateTimes[reusableID] = nil
			storedLooperEventsLocations[reusableID] = nil
		end
	end
end




function eventMarkerHandler.updateForPlayer(player)
	local personalMarkers = eventMarkerHandler.markers[player]
	if personalMarkers then
		for id,_ in pairs(personalMarkers) do
			---@type ISUIElement
			local marker = eventMarkerHandler.markers[player][id]
			if marker and marker:getEnabled() then
				local currentTime = getGametimeTimestamp()
				local currentTimeMS = getTimeInMillis()
				local expireTime = eventMarkerHandler.expirations[player][id]
				if (expireTime <= currentTime) and (marker.lastUpdateTime+100 <= currentTimeMS) then
					eventMarkerHandler.markers[player][id] = nil
					eventMarkerHandler.expirations[player][id] = nil
					marker:setDuration(0)
					marker:setEnabled(false)
				end
			end
		end
	end
end
Events.OnPlayerUpdate.Add(eventMarkerHandler.updateForPlayer)


local eheFlareSystem = require "EHE_flares"
-- sendServerCommand(module, command, player, args) end -- to client
local function onServerCommand(_module, _command, _data)

	if _module == "flyOver" and _command == "wakeUp" then getPlayer():forceAwake() end

	if _module == "flare" and _command == "updateClient" then
		if _data.soundEffect and _data.coords.x and _data.coords.y and _data.coords.z then
			local sq = getSquare(_data.coords.x, _data.coords.y, _data.coords.z)
			if sq then
				getWorld():getFreeEmitter():playSoundImpl(_data.soundEffect, sq)
			end
		end

		if _data.flare then
			if _data.duration then eheFlareSystem.sendDuration(_data.flare, _data.duration) end

			if _data.active ~= nil and _data.coords.x and _data.coords.y and _data.coords.z then
				eheFlareSystem.processLightSource(_data.flare, _data.coords.x, _data.coords.y, _data.coords.z, _data.active)
			end
		end
	end


	if _module == "EHE_ServerModData" and  _command == "severModData_received" then
		onClientModDataReady()

	elseif _module == "helicopterEvent" and  _command == "attack" then
		heliEventAttackHitOnIsoGameCharacter(_data.damage, _data.targetType, _data.targetID)

	elseif _module == "sendLooper" then

		if _command == "play" then
			clientSideEventSoundHandler:handleLooperEvent(_data.reusableID,
					{soundEffect=_data.soundEffect, x=_data.coords.x, y=_data.coords.y, z=_data.coords.z}, _command)

		elseif _command == "playOnce" then

			local emitter = getWorld():getFreeEmitter()

			local maxDistance = nil
			if _data.soundEffect == "eAirRaid" or _data.soundEffect == "eCarpetBomb" or _data.soundEffect == "eBomb" then
				maxDistance = 5000
			end

			local sq, vol = clientSideEventSoundHandler.attenuateEmitterToPlayer(getPlayer(), emitter, _data.coords.x, _data.coords.y, _data.coords.z, maxDistance)
			if sq and emitter then
				emitter:playSoundImpl(_data.soundEffect, sq)
				if vol then emitter:setVolumeAll(vol) end
				emitter:tick()
			end

		elseif _command == "setPos" then
			clientSideEventSoundHandler:handleLooperEvent(_data.reusableID, {x=_data.coords.x, y=_data.coords.y, z=_data.coords.z}, _command)

		elseif _command == "stop" then
			clientSideEventSoundHandler:handleLooperEvent(_data.reusableID, {soundEffect=_data.soundEffect}, _command)

		elseif _command == "stopAll" then
			clientSideEventSoundHandler:handleLooperEvent(_data.reusableID, {}, _command)
		end


	elseif _module == "eventMarkerHandler" and _command == "setOrUpdateMarker" then
		eventMarkerHandler.setOrUpdate(_data.eventID, _data.icon, _data.duration, _data.posX, _data.posY, _data.color)


	elseif _module == "eventShadowHandler" and _command == "setShadowPos" then
		eventShadowHandler:setShadowPos(_data.eventID, _data.texture, _data.x, _data.y, _data.z)
	end

end
Events.OnServerCommand.Add(onServerCommand)--/server/ to client
