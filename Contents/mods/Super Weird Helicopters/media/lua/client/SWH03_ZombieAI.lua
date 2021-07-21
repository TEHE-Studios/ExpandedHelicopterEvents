eHelicopter_zombieAI = {}

---@param zombie IsoZombie | IsoGameCharacter | IsoObject
function eHelicopter_zombieAI.specialZombie_gottaGoFast(zombie)
	if not zombie then
		return
	end
	print("AI running: specialZombie_gottaGoFast")
	zombie:changeSpeed(1)
	zombie:setNoTeeth(true)
	if zombie:isCrawling() then
		zombie:toggleCrawling()
	end
	zombie:DoZombieStats()
end


---@param zombie IsoZombie | IsoGameCharacter | IsoObject
function eHelicopter_zombieAI.specialZombie_nemesis(zombie)
	if not zombie then
		return
	end
	print("AI running: specialZombie_nemesis")
	zombie:setNoTeeth(true)
	if zombie:isCrawling() then
		zombie:toggleCrawling()
	end
	zombie:DoZombieStats()
end


--[[ ---TODO: Cry
---@param location IsoGridSquare
---@param iterations number
---@param outfitID string
---@param aiID string
function eHelicopter_zombieAI:spawnZombieAI(location, iterations, outfitID, aiID)
	--if there is an actual location - IsoGridSquare may not be loaded in under certain circumstances
	if not location then
		return
	end

	local spawnedZombies = addZombiesInOutfit(location:getX(), location:getY(), location:getZ(), iterations, outfitID, 0)

	for i=0, spawnedZombies:size()-1 do
		---@type IsoGameCharacter | IsoZombie
		local zombie = spawnedZombies:get(i)
		--if there's an actual zombie
		if zombie then
			local zombieAIchange = eHelicopter_zombieAI["specialZombie_"..aiID]
			if zombieAIchange then
				print(" - EHE: ZombieAI "..aiID.." found.")
				eHelicopter_zombieAI.apply(zombie,aiID)
			end
		end
	end
end


function eHelicopter_zombieAI:spawnFastAlienZombieAI()
	--remember ZombRand stops 1 before max.
	local iterations = ZombRand(2,5)
	eHelicopter_zombieAI:spawnZombieAI(self:getIsoGridSquare(), iterations, "1AlienTourist", "gottaGoFast")
end

function eHelicopter_zombieAI:spawnNemesisSpiffoZombieAI()
	--remember ZombRand stops 1 before max.
	local iterations = ZombRand(1,3)
	eHelicopter_zombieAI:spawnZombieAI(self:getIsoGridSquare(), iterations, "1SpiffoBoss", "nemesis")
end


---@param zombie IsoZombie | IsoGameCharacter | IsoObject
---@param aiChanges string
function eHelicopter_zombieAI.apply(zombie,aiChanges)
	if not zombie or not aiChanges then
		return
	end
	local zombieAI = zombie:getInventory():AddItem("SWH.ZombieAI")
	if zombieAI then
		print("itemized zombieAI "..aiChanges.." created. : "..zombieAI:getBodyLocation())
		zombieAI:getModData()["zombieAIType"] = aiChanges
		zombie:setWornItem(zombieAI:getBodyLocation(), zombieAI)
	end
end
--]]

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

	local storedAIItem = zombie:getWornItems():getItem("Left_MiddleFinger")
	if storedAIItem then
		print("storedAIItem:getType() = "..storedAIItem:getType())
		local storedAI = storedAIItem:getType()
		if storedAI then
			print("yes AI is here: "..storedAI)
			local specialAI = eHelicopter_zombieAI["specialZombie_"..storedAI]
			if specialAI then
				specialAI(zombie)
			end
		end
	end
end

Events.OnZombieUpdate.Add(eHelicopter_zombieAI.checkForAI)
