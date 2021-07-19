eHelicopter_zombieAI = {}

---@param location IsoGridSquare
function eHelicopter_zombieAI:spawnZombieAI(location, outfitID, aiID)
	if not location then
		return
	end
	--if there is an actual location - IsoGridSquare may not be loaded in under certain circumstances
	local spawnedZombies = addZombiesInOutfit(location:getX(), location:getY(), location:getZ(), 1, outfitID, 0)
	---@type IsoGameCharacter | IsoZombie
	local zombie = spawnedZombies:get(0)
	--if there's an actual zombie
	if zombie then
		local zombieAIchange = eHelicopter_zombieAI["specialZombie_"..aiID]
		if zombieAIchange then
			print(" - EHE: ZombieAI "..outfitID.." found.")
			eHelicopter_zombieAI.apply(zombie,"specialZombie_"..aiID)
		end
	end
end


function eHelicopter_zombieAI:spawnFastAlienZombieAI()
	--remember ZombRand stops 1 before max.
	local iterations = ZombRand(2,5)
	for i=1, iterations do
		eHelicopter_zombieAI:spawnZombieAI(self:getIsoGridSquare(), "1AlienTourist", "gottaGoFast")
	end
end

function eHelicopter_zombieAI:spawnNemesisSpiffoZombieAI()
	--remember ZombRand stops 1 before max.
	local iterations = ZombRand(1,3)
	for i=1, iterations do
		eHelicopter_zombieAI:spawnZombieAI(self:getIsoGridSquare(), "1SpiffoBoss", "nemesis")
	end
end


---@param zombie IsoZombie | IsoGameCharacter | IsoObject
---@param aiChanges string
function eHelicopter_zombieAI.apply(zombie,aiChanges)
	if not zombie or not aiChanges then
		return
	end
	local zMD = zombie:getModData()
	zMD["eheZombieType"] = tostring(aiChanges)
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
	local storedAIType = zMD["eheZombieType"]

	if storedAIType then
		print("yes AI is here: "..storedAIType)
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
