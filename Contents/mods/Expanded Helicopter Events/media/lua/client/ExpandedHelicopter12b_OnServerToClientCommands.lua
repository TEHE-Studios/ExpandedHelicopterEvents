require "ExpandedHelicopter00c_SpawnerAPI"
require "ExpandedHelicopter01f_ShadowSystem"
require "ExpandedHelicopter11_EventMarkerHandler"
require "ExpandedHelicopter00a_Util"


local function copyAgainst(tableA,tableB)
	if not tableA or not tableB then return end
	for key,value in pairs(tableB) do tableA[key] = value end
	for key,_ in pairs(tableA) do if not tableB[key] then tableA[key] = nil end end
end

---Credit to Konijima (Konijima#9279) for clearing up networking :thumbsup:
LuaEventManager.AddEvent("EHE_ClientModDataReady") -- p1: isNewGame
--triggerEvent("EHE_ClientModDataReady", false) send change if any

local ExpandedHeliEventsModData --.EventsOnSchedule = {} --.DayOfLastCrash = 0 --.DaysBeforeApoc = 0
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
	if not storedShadows then return end
	for shadowID,_ in pairs(storedShadows) do
		if storedShadowsUpdateTimes and storedShadowsUpdateTimes[shadowID]+5000 <= currentTime then
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

local storedLooperEvents = {}
local storedLooperEventsSoundEffects = {}
local storedLooperEventsUpdateTimes = {}

local clientSideEventSoundHandler = {}

function clientSideEventSoundHandler:handleLooperEvent(reusableID, DATA, command)

	if getDebug() then print(" EHE:handleLooperEvent: "..reusableID.."  command:"..command) end
	
	---@type BaseSoundEmitter | FMODSoundEmitter
	local soundEmitter = storedLooperEvents[reusableID]
	if not soundEmitter and command ~= "drop" then
		storedLooperEvents[reusableID] = getWorld():getFreeEmitter()
		soundEmitter = storedLooperEvents[reusableID]
		if command=="setPos" then
			command = "play"
		end
	end
	if soundEmitter then

		if command ~= "setPos" then
			local emitterDebugText = "--loopedSound: "..getClientUsername().." ["..command.."]:"..tostring(soundEmitter).." - "..tostring(reusableID)
			if DATA and type(DATA)=="table" then for k,v in pairs(DATA) do emitterDebugText = emitterDebugText.." - ("..k.."="..tostring(v)..")" end
			else emitterDebugText = emitterDebugText.." - /!\\ (DATA = "..tostring(DATA)..")" end
			print(emitterDebugText)
		end

		storedLooperEventsUpdateTimes[reusableID] = getTimeInMillis()

		if not DATA then print(" --WARN: Command has a data of nil!")
		else
			if command == "play" then
				if soundEmitter:isPlaying(DATA.soundEffect) then
					print("--soundEmitter is already playing \`"..DATA.soundEffect.."\`")
					--local square = getSquare(DATA.x, DATA.y, DATA.z)
				else
					storedLooperEventsSoundEffects[reusableID] = storedLooperEventsSoundEffects[reusableID] or {}
					storedLooperEventsSoundEffects[reusableID][DATA.soundEffect] = true
					soundEmitter:playSound(DATA.soundEffect, DATA.x, DATA.y, DATA.z)
				end
			end

			if command == "setPos" then soundEmitter:setPos(DATA.x,DATA.y,DATA.z) end

			if command == "stop" then
				if DATA and DATA.soundEffect and type(DATA.soundEffect)=="table" then
					print("--soundEffect set:")
					for _,sound in pairs(DATA.soundEffect) do
						print("---stop:"..tostring(soundEmitter).." - ".." - "..sound)
						soundEmitter:stopSoundByName(sound)
					end
				else
					print("--stop:"..tostring(soundEmitter).." - ".." - "..tostring(DATA.soundEffect))
					soundEmitter:stopSoundByName(DATA.soundEffect)

				end
			end
		end

		if command == "stopAll" then
			soundEmitter:setVolumeAll(0)
			--soundEmitter:stopAll()
		end
	end
end


function clientSideEventSoundHandler.updateForPlayer(player)
	for emitterID,timeStamp in pairs(storedLooperEventsUpdateTimes) do
		if timeStamp~=false and timeStamp <= getGametimeTimestamp() then
			--[[DEBUG]] local printString = ""
			---@type FMODSoundEmitter | BaseSoundEmitter emitter
			local emitter = storedLooperEvents[emitterID]

			if storedLooperEventsSoundEffects[emitterID] then
				for sound,_ in pairs(storedLooperEventsSoundEffects[emitterID]) do
					if emitter:isPlaying(sound) then
						printString = sound..", "..printString
						emitter:stopSoundByName(sound)
					end
				end
			end
			--[[DEBUG]] if printString~="" then printString = "\n --- stopped: "..printString end
			--[[DEBUG]] print("-- EHE: "..emitterID.." clientSideEventSoundHandler.updateForPlayer: no update received; stopping sound. "..printString)
			emitter:setVolumeAll(0)
			--emitter:stopAll()
			storedLooperEventsSoundEffects[emitterID] = nil
			storedLooperEventsUpdateTimes[emitterID] = nil
		end
	end
end
Events.OnPlayerUpdate.Add(clientSideEventSoundHandler.updateForPlayer)


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
					print("-- EHE: eventMarkerHandler.updateForPlayer: no update received; stopping marker. ")
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


-- sendServerCommand(module, command, player, args) end -- to client
local function onServerCommand(_module, _command, _data)
	--clientside

	if getDebug() and _module=="sendLooper" and _command~="setPos" then
		local dataText = "{"
		for k,v in pairs(_data) do dataText = dataText..tostring(k).."="..tostring(v)..", " end
		print("_module:".._module.."  _command:".._command.."  _data:"..dataText.."}")
	end

	if _module == "EHE_ServerModData" and  _command == "severModData_received" then
		onClientModDataReady()

	elseif _module == "sendLooper" then
		storedLooperEventsUpdateTimes[_data.reusableID] = getGametimeTimestamp()+100

		if _command == "play" then
			clientSideEventSoundHandler:handleLooperEvent(_data.reusableID,
					{soundEffect=_data.soundEffect, x=_data.coords.x, y=_data.coords.y, z=_data.coords.z}, _command)

		elseif _command == "setPos" then
			clientSideEventSoundHandler:handleLooperEvent(_data.reusableID, {x=_data.coords.x, y=_data.coords.y, z=_data.coords.z}, _command)

		elseif _command == "stop" then
			clientSideEventSoundHandler:handleLooperEvent(_data.reusableID, {soundEffect=_data.soundEffect}, _command)

		elseif _command == "drop" then
			clientSideEventSoundHandler:handleLooperEvent(_data.reusableID, nil, _command)
		end

	elseif _module == "eventMarkerHandler" and _command == "setOrUpdateMarker" then
		eventMarkerHandler.setOrUpdate(_data.eventID, _data.icon, _data.duration, _data.posX, _data.posY, true)

	elseif _module == "eventShadowHandler" and _command == "setShadowPos" then
		eventShadowHandler:setShadowPos(_data.eventID, _data.texture, _data.x, _data.y, _data.z, true)
	end
end
Events.OnServerCommand.Add(onServerCommand)--/server/ to client
