eHelicopter_zombieAI = {}
---@param zombie IsoZombie | IsoGameCharacter | IsoObject
---@param aiChanges string
function eHelicopter_zombieAI.apply(zombie,aiChanges)
	if not zombie  or not aiChanges then
		return
	end
	local zMD = zombie:getModData()
	zMD["ehe_zombieType"] = aiChanges
end


eHelicopter_zombieAI.lastCheckedForAI = 0
---@param zombie IsoZombie | IsoGameCharacter | IsoObject
function eHelicopter_zombieAI.checkForAI(zombie)
	if not zombie then
		return
	end

	local timeStampMS = getTimestampMs()
	if timeStampMS <= eHelicopter_zombieAI.lastCheckedForAI then
		return
	end
	eHelicopter_zombieAI.lastCheckedForAI = timeStampMS+500

	local zMD = zombie:getModData()
	local storedAIType = zMD["ehe_zombieType"]

	if storedAIType then
		local specialAI = eHelicopter_zombieAI[storedAIType]
		if specialAI then
			specialAI(zombie)
		end
	end
end
Events.OnZombieUpdate.Add(eHelicopter_zombieAI.checkForAI)


---@param zombie IsoZombie | IsoGameCharacter | IsoObject
function eHelicopter_zombieAI.specialZombie_gottaGoFast(zombie)
	if not zombie then
		return
	end
	zombie:changeSpeed(1)
	zombie:DoZombieStats()
end
