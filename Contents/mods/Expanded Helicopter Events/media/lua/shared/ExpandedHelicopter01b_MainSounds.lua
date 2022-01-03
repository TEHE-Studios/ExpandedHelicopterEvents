require "ExpandedHelicopter01a_MainVariables"

eventSoundHandler = {}

storedLooperEvents = {}
function eventSoundHandler:handleLooperEvent(reusableID, DATA, command)
	if isClient() then
		---@type BaseSoundEmitter | FMODSoundEmitter
		local soundEmitter = storedLooperEvents[reusableID]
		if not soundEmitter and command ~= "drop" then
			storedLooperEvents[reusableID] = getWorld():getFreeEmitter()
			soundEmitter = storedLooperEvents[reusableID]
		end
		if soundEmitter then
			if command == "play" then
				if soundEmitter:isPlaying(DATA.soundEffect) then
					print("--soundEmitter:isPlaying:"..DATA.soundEffect)
					return
				end
				--print("--play:"..tostring(soundEmitter).." - "..DATA.soundEffect.." ("..DATA.x..","..DATA.y..")")
				--local square = getSquare(DATA.x, DATA.y, DATA.z)
				soundEmitter:playSound(DATA.soundEffect, DATA.x, DATA.y, DATA.z)
			elseif command == "setPos" then
				--print("--setPos:"..tostring(soundEmitter).." - x:"..DATA.x..","..DATA.y)
				soundEmitter:setPos(DATA.x,DATA.y,DATA.z)
			elseif command == "stop" then
				--print("--stop:"..tostring(soundEmitter).." - "..DATA)
				soundEmitter:stopSoundByName(DATA)
			elseif command == "drop" then
				--print("--drop:"..tostring(soundEmitter))
				soundEmitter:stopAll()
				storedLooperEvents[reusableID] = nil
			end
		end
	end
end


---@param soundEvent string
---@param otherLocation IsoGridSquare
---@param saveEmitter boolean
---@param stopSound boolean
---@param delay number
function eventSoundHandler:playEventSound(heli, soundEvent, otherLocation, saveEmitter, stopSound, delay)

	local soundEffect = heli.eventSoundEffects[soundEvent] or eHelicopter.eventSoundEffects[soundEvent] or soundEvent

	if not soundEffect or soundEffect=="IGNORE" then
		return
	end

	if delay then
		table.insert(heli.delayedEventSounds, {
			["event"]=soundEvent,
			["otherLocation"]=otherLocation,
			["saveEmitter"]=saveEmitter,
			["stopSound"]=stopSound,
			["delay"]=getTimestampMs()+delay
		})
		return
	end

	if type(soundEffect)=="table" then
		soundEffect = soundEffect[ZombRand(1,#soundEffect+1)]
	end

	local oL = (otherLocation~=nil)

	---@type FMODSoundEmitter | BaseSoundEmitter emitter
	local soundEmitter

	if oL then
		soundEmitter = heli.placedEventSoundEffectEmitters[soundEvent]
	else
		soundEmitter = heli.heldEventSoundEffectEmitters[soundEvent]
	end

	if stopSound then
		if isClient() and heli.looperEventIDs[soundEvent] then
			sendClientCommand("sendLooper", "ping", {reusableID=("HELI"..heli.ID), soundEffect=soundEffect, command="stop"})
		end
		if soundEmitter then
			soundEmitter:stopSoundByName(soundEffect)
		end
		return
	end

	--if otherlocation provided use it; if not use heli
	otherLocation = otherLocation or heli:getIsoGridSquare()

	if not soundEmitter then
		soundEmitter = getWorld():getFreeEmitter()
		if saveEmitter then
			if oL then
				heli.placedEventSoundEffectEmitters[soundEvent] = soundEmitter
			else
				heli.heldEventSoundEffectEmitters[soundEvent] = soundEmitter
			end
		end

		if soundEmitter:isPlaying(soundEffect) then
			print("--soundEmitter:isPlaying:"..soundEffect)
			return
		else

			if isClient() and heli.looperEventIDs[soundEvent] then
				sendClientCommand("sendLooper", "ping", {reusableID=("HELI"..heli.ID), soundEffect=soundEffect, command="play"})
			else
				print("--event:"..soundEvent..":"..soundEffect)
				soundEmitter:playSoundImpl(soundEffect, otherLocation)
			end
		end
	end
end


function eventSoundHandler:updatePos(heli,heliX,heliY)
	--Move held emitters to position

	if isClient() and heli.looperEventIDs then
		sendClientCommand("sendLooper", "ping", {reusableID=("HELI"..heli.ID), coords={x=heliX,y=heliX,z=heli.height}, command="setPos"})
	end

	for _,emitter in pairs(heli.heldEventSoundEffectEmitters) do
		emitter:setPos(heliX,heliY,heli.height)
	end
end


function eventSoundHandler:checkEventSounds(heli)
	--check delayed event sounds
	local currentTime = getTimestampMs()
	for placeInList,EventSound in pairs(heli.delayedEventSounds) do
		--event, otherLocation, saveEmitter, stopSound, delay
		if currentTime <= EventSound["delay"] then
			eventSoundHandler:playEventSound(heli, EventSound["otherLocation"], EventSound["saveEmitter"], EventSound["stopSound"])
			heli.delayedEventSounds[placeInList] = nil
		end
	end
end


function eventSoundHandler:stopAllHeldEventSounds(heli)
	--[[DEBUG]] local soundsStopped = false

	if isClient() and heli.looperEventIDs then
		sendClientCommand("sendLooper", "ping", {reusableID=("HELI"..heli.ID), command="drop"})
	end

	for event,emitter in pairs(heli.heldEventSoundEffectEmitters) do
		local soundEffect = heli.eventSoundEffects[event] or eHelicopter.eventSoundEffects[event] or event
		if soundEffect then
			soundsStopped = true
			emitter:stopAll()--stopSoundByName(soundEffect)
		end
	end
	for event,emitter in pairs(heli.placedEventSoundEffectEmitters) do
		local soundEffect = heli.eventSoundEffects[event] or eHelicopter.eventSoundEffects[event] or event
		if soundEffect then
			soundsStopped = true
			emitter:stopAll()--stopSoundByName(soundEffect)
		end
	end
	heli.delayedEventSounds = {}
	--[[DEBUG]] if soundsStopped then print(" - EHE: stopAllHeldEventSounds for "..heli:heliToString()) end
end