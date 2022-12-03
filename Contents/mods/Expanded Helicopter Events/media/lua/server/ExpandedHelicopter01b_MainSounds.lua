require "ExpandedHelicopter01a_MainVariables"

eventSoundHandler = {}

---@param soundEvent string
---@param otherLocation IsoGridSquare
---@param saveEmitter boolean
---@param stopSound boolean
---@param delay number
function eventSoundHandler:playEventSound(heli, soundEvent, otherLocation, saveEmitter, stopSound, delay)

	local soundEffect = heli.eventSoundEffects[soundEvent] or eHelicopter.eventSoundEffects[soundEvent] or soundEvent

	if soundEffect and type(soundEffect)=="table" then
		for _,sound in pairs(soundEffect) do
			eventSoundHandler:playEventSound(heli, sound, otherLocation, saveEmitter, stopSound, delay)
		end
		return
	end

	if not soundEffect or soundEffect=="IGNORE" then
		return
	end

	if delay then
		table.insert(heli.delayedEventSounds, { ["event"]=soundEvent, ["otherLocation"]=otherLocation,
			["saveEmitter"]=saveEmitter, ["stopSound"]=stopSound, ["delay"]=getGametimeTimestamp()+delay })
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
		if heli.looperEventIDs[soundEvent] then
			sendServerCommand("sendLooper", "stop", {reusableID=("HELI"..heli.ID), soundEffect=soundEffect})
		end

		if soundEmitter then
			soundEmitter:stopSoundByName(soundEffect)
		end
		return
	end

	--if otherlocation provided use it; if not use heli
	otherLocation = otherLocation or heli:getIsoGridSquare()

	if heli.looperEventIDs[soundEvent] then
		local heliX, heliY, heliZ = heli:getXYZAsInt()
		sendServerCommand("sendLooper", "play", {reusableID=("HELI"..heli.ID), soundEffect=soundEffect, coords={x=heliX,y=heliY,z=heliZ}})
		return
	end
	
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
			--print("--soundEmitter:isPlaying:"..soundEffect)
		else
			--print("--event:"..soundEvent..":"..soundEffect)
			soundEmitter:playSound(soundEffect, otherLocation)
		end
	end
end


function eventSoundHandler:updatePos(heli,heliX,heliY)
	--Move held emitters to position
	if heli.state == "unLaunched" then return end

	if heli.looperEventIDs then
		sendServerCommand("sendLooper", "setPos",{reusableID=("HELI"..heli.ID), coords={x=heliX,y=heliY,z=heli.height}})
	end

	for _,emitter in pairs(heli.heldEventSoundEffectEmitters) do
		emitter:setPos(heliX,heliY,heli.height)
	end
end


function eventSoundHandler:checkEventSounds(heli)
	--check delayed event sounds
	local currentTime = getGametimeTimestamp()
	for placeInList,EventSound in pairs(heli.delayedEventSounds) do
		--event, otherLocation, saveEmitter, stopSound, delay
		if currentTime <= EventSound["delay"] then
			eventSoundHandler:playEventSound(heli, EventSound["otherLocation"], EventSound["saveEmitter"], EventSound["stopSound"])
			heli.delayedEventSounds[placeInList] = nil
		end
	end
end


function eventSoundHandler:stopAllHeldEventSounds(heli)


	for soundID,_ in pairs(heli.looperEventIDs) do
		local soundEffect = heli.eventSoundEffects[soundID]
		sendServerCommand("sendLooper", "stop",{reusableID=("HELI"..heli.ID), soundEffect=soundEffect})
	end


	for event,emitter in pairs(heli.heldEventSoundEffectEmitters) do
		local soundEffect = heli.eventSoundEffects[event] or eHelicopter.eventSoundEffects[event] or event
		if soundEffect then emitter:stopSoundByName(soundEffect) end
	end
	for event,emitter in pairs(heli.placedEventSoundEffectEmitters) do
		local soundEffect = heli.eventSoundEffects[event] or eHelicopter.eventSoundEffects[event] or event
		if soundEffect then emitter:stopSoundByName(soundEffect) end
	end
	heli.delayedEventSounds = {}
	--[[DEBUG]] print(" - EHE: stopAllHeldEventSounds for "..heli:heliToString())
end