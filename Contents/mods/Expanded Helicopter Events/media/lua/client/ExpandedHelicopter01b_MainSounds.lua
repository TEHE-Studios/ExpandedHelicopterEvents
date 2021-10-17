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

	local oL = (otherLocation~=nil)

	---@type FMODSoundEmitter | BaseSoundEmitter emitter
	local soundEmitter

	if oL then
		soundEmitter = self.placedEventSoundEffectEmitters[event]
	else
		soundEmitter = self.heldEventSoundEffectEmitters[event]
	end

	if stopSound and soundEmitter then
		soundEmitter:stopSoundByName(soundEffect)
		return
	end

	--if otherlocation provided use it; if not use self
	otherLocation = otherLocation or self:getIsoGridSquare()

	if not soundEmitter then
		soundEmitter = getWorld():getFreeEmitter()
		if saveEmitter then
			if oL then
				self.placedEventSoundEffectEmitters[event] = soundEmitter
			else
				self.heldEventSoundEffectEmitters[event] = soundEmitter
			end
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
	--[[DEBUG]] local debugPrint = " - EHE: stopAllHeldEventSounds for "..self:heliToString().."\n -- sounds:"
	for event,emitter in pairs(self.heldEventSoundEffectEmitters) do
		local soundEffect = self.eventSoundEffects[event] or eHelicopter.eventSoundEffects[event]
		if soundEffect then
			--[[DEBUG]] debugPrint = debugPrint.." "..event.." = "..soundEffect..", "
			emitter:stopSoundByName(soundEffect)
		else
			--[[DEBUG]] debugPrint = debugPrint.." ERR: null, "
		end
	end
	for event,emitter in pairs(self.placedEventSoundEffectEmitters) do
		local soundEffect = self.eventSoundEffects[event] or eHelicopter.eventSoundEffects[event]
		if soundEffect then
			--[[DEBUG]] debugPrint = debugPrint.." "..event.." = "..soundEffect..", "
			emitter:stopSoundByName(soundEffect)
		else
			--[[DEBUG]] debugPrint = debugPrint.." ERR: null, "
		end
	end
	--[[DEBUG]] print(debugPrint)
end
