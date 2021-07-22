local group = AttachedLocations.getGroup("Human")
group:getOrCreateLocation("Special Zombie AI"):setAttachmentName("special_zombie_AI")

eHelicopter_zombieAI = {}

---@param zombie IsoZombie | IsoGameCharacter | IsoObject
function eHelicopter_zombieAI.specialZombie_gottaGoFast(zombie, apply)
	if not zombie then
		return
	end
	if apply then
		print("AI onApply: specialZombie_gottaGoFast")
		zombie:changeSpeed(1)
		zombie:setNoTeeth(true)
		zombie:DoZombieStats()
	else
		print("AI onUpdate: specialZombie_gottaGoFast")
		if zombie:isCrawling() then
			zombie:toggleCrawling()
		end
	end
end

---@param zombie IsoZombie | IsoGameCharacter | IsoObject
function eHelicopter_zombieAI.specialZombie_nemesis(zombie, apply)
	if not zombie then
		return
	end
	if apply then
		print("AI onApply: specialZombie_nemesis")
		zombie:setNoTeeth(true)
		zombie:setCanCrawlUnderVehicle(false)
		zombie:DoZombieStats()
	else
		print("AI onUpdate: specialZombie_nemesis")
		if zombie:isCrawling() then
			zombie:toggleCrawling()
		end
	end
end


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
				eHelicopter_zombieAI.apply(zombie, aiID)
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

	local itemizedZombieAI = InventoryItemFactory.CreateItem("ZombieAI."..aiChanges)
	if itemizedZombieAI then
		print("itemizedZombieAI: "..aiChanges.." applied.")
		zombie:setAttachedItem("Special Zombie AI", itemizedZombieAI)
		---WARNING: IsoZombie ModData does not save but we can use it to individualize variables
		zombie:getModData()["applyNextUpdate"] = true
	end
end


---@param zombie IsoZombie | IsoGameCharacter | IsoObject
function eHelicopter_zombieAI.checkForAI(zombie, apply)
	if not zombie then
		return
	end

	if zombie:getModData()["applyNextUpdate"] == true then
		apply = true
		zombie:getModData()["applyNextUpdate"] = false
	end

	local attachedItems = zombie:getAttachedItems()
	for i=0, attachedItems:size()-1 do
		---@type InventoryItem
		local storedAIItem = attachedItems:getItemByIndex(i)
		if storedAIItem and storedAIItem:getModule() == "ZombieAI" then
			local storedAI = storedAIItem:getType()
			local specialAI = eHelicopter_zombieAI["specialZombie_"..storedAI]
			if specialAI then
				specialAI(zombie, apply or false)
			end
		end
	end
end
Events.OnZombieUpdate.Add(eHelicopter_zombieAI.checkForAI)


---Load technique borrowed from SoulFilcher
function eHelicopter_zombieAI.load_zombieAI()
	local zombies = getPlayer():getCell():getZombieList()
	for i=0, zombies:size()-1 do
		local zombie = zombies:get(i)
		eHelicopter_zombieAI.checkForAI(zombie, true)
	end
end
Events.OnGameStart.Add(eHelicopter_zombieAI.load_zombieAI)