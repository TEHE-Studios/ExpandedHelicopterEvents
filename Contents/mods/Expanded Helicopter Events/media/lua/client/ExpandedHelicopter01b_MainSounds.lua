---@param event string
---@param otherLocation IsoGridSquare
---@param saveEmitter boolean
---@param stopSound boolean
---@param delay number
function eHelicopter:playEventSound(event, otherLocation, saveEmitter, stopSound, delay)

	local soundEffect = self.eventSoundEffects[event] or eHelicopter.eventSoundEffects[event]

	if not soundEffect then
		return
	end

	if delay then
		table.insert(self.delayedEventSounds, {["event"]=event, ["otherLocation"]=otherLocation, ["saveEmitter"]=saveEmitter, ["stopSound"]=stopSound, ["delay"]=getTimestampMs()+delay})
		return
	end

	if type(soundEffect)=="table" then
		soundEffect = soundEffect[ZombRand(1,#soundEffect+1)]
	end

	---@type FMODSoundEmitter | BaseSoundEmitter emitter
	local soundEmitter = self.heldEventSoundEffectEmitters[event]

	if stopSound and soundEmitter then
		soundEmitter:stopSoundByName(soundEffect)
		return
	end

	--if otherlocation provided use it; if not use self
	otherLocation = otherLocation or self:getIsoGridSquare()

	if not soundEmitter then
		soundEmitter = getWorld():getFreeEmitter()
		if saveEmitter then
			self.heldEventSoundEffectEmitters[event] = soundEmitter
		end
	elseif soundEmitter:isPlaying(soundEffect) then
		return
	end
	soundEmitter:playSound(soundEffect, otherLocation)
end


function eHelicopter:checkDelayedEventSounds()
	local currentTime = getTimestampMs()
	for placeInList,EventSound in pairs(self.delayedEventSounds) do
		--event, otherLocation, saveEmitter, stopSound, delay
		if currentTime <= EventSound["delay"] then
			self:playEventSound(EventSound["event"], EventSound["otherLocation"], EventSound["saveEmitter"], EventSound["stopSound"])
			self.delayedEventSounds[placeInList] = nil
		end
	end
end


function eHelicopter:stopAllHeldEventSounds()
	print(" - EHE: stopAllHeldEventSounds for "..self:heliToString())
	for event,emitter in pairs(self.heldEventSoundEffectEmitters) do
		local soundEffect = self.eventSoundEffects[event] or eHelicopter.eventSoundEffects[event]
		if soundEffect then
			print(" -- sound stoppage:"..event.." = "..soundEffect)
			emitter:stopSoundByName(soundEffect)
		else
			print(" -- sound stoppage: ERR: soundEffect = null")
		end
	end
end
