local group = AttachedLocations.getGroup("Human")
group:getOrCreateLocation("Special Zombie AI"):setAttachmentName("special_zombie_AI")


AttachedWeaponDefinitions.gottaGoFast = {
	chance = 100, weaponLocation = {"Special Zombie AI"}, outfit = {"AlienTourist"},
	bloodLocations = nil, addHoles = false, daySurvived = 0, weapons = { "ZombieAI.gottaGoFast" } }
AttachedWeaponDefinitions.attachedWeaponCustomOutfit.AlienTourist = { chance = 100, maxitem = 1, weapons = {AttachedWeaponDefinitions.gottaGoFast} }


AttachedWeaponDefinitions.nemesis = {
	chance = 100, weaponLocation = {"Special Zombie AI"}, outfit = {"SpiffoBoss"},
	bloodLocations = nil, addHoles = false, daySurvived = 0, weapons = { "ZombieAI.nemesis" } }
AttachedWeaponDefinitions.attachedWeaponCustomOutfit.SpiffoBoss = { chance = 100, maxitem = 1, weapons = {AttachedWeaponDefinitions.nemesis} }


eHelicopter_zombieAI = {}


---@param zombie IsoZombie | IsoGameCharacter | IsoObject
---@param apply boolean
function eHelicopter_zombieAI.specialZombie_gottaGoFast(zombie, apply)
	if not zombie then
		return
	end
	if apply then
		print("AI onApply: specialZombie_gottaGoFast")
		zombie:changeSpeed(1)
		zombie:DoZombieStats()
		zombie:setSpeedMod(10)

	else
		--print("AI onUpdate: specialZombie_gottaGoFast")
		if zombie:isCrawling() then
			zombie:toggleCrawling()
		end
	end
end


---@param zombie IsoZombie | IsoGameCharacter | IsoObject
---@param apply boolean
function eHelicopter_zombieAI.specialZombie_nemesis(zombie, apply)
	if not zombie then
		return
	end
	if apply then
		print("AI onApply: specialZombie_nemesis")
		zombie:changeSpeed(3)
		zombie:setCanCrawlUnderVehicle(false)
		zombie:DoZombieStats()
		zombie:setHealth(zombie:getHealth()*1000001)
		zombie:setAvoidDamage(true)
	else
		zombie:setCanWalk(true)
		zombie:setHealth(zombie:getHealth()*1000001)

		local currentFireDamage = zombie:getModData()["nemesisFireDmg"] or 0
		if zombie:isOnFire() then
			currentFireDamage = currentFireDamage+1
			zombie:getModData()["nemesisFireDmg"] = currentFireDamage
			print("EHE:SWH:specialZombie_nemesis: zombie is on fire.")
		end

		if currentFireDamage > 50 then
			zombie:setHealth(0)
			print("EHE:SWH:specialZombie_nemesis: zombie is crispy.")
		end

		if zombie:isBeingSteppedOn() then
			local squaresInRange = getIsoRange(zombie, 1)
			for k,sq in pairs(squaresInRange) do
				---@type IsoGridSquare
				local square = sq
				local objs = square:getMovingObjects()
				for i=0, objs:size()-1 do
					local foundObj = objs:get(i)

					if foundObj and (foundObj ~= zombie) then
						if instanceof(foundObj, "BaseVehicle") then
							---@type BaseVehicle
							local car = foundObj
							if car then
								car:flipUpright()
							end

						elseif instanceof(foundObj, "IsoGameCharacter") then
							---@type IsoGameCharacter | IsoPlayer | IsoZombie
							local char = foundObj
							if (not char:getBumpedChr()) and (not char:isOnFloor()) and (not char:getVehicle()) and ZombieOnGroundState.isCharacterStandingOnOther(char, zombie) then
								char:setBumpedChr(zombie)

								if instanceof(char, "IsoPlayer") then
									char:clearVariable("BumpFallType")
									char:setBumpType("stagger")
									char:setBumpDone(false)
									char:setBumpFallType("pushedFront")
								end
								--knock down zombie
								if instanceof(char, "IsoZombie") then
									char:knockDown(true)
								end
							end
						end
					end
				end
			end
		end

		---EnemyList

	end
end


---@param zombie IsoObject | IsoGameCharacter | IsoZombie
---@param player IsoObject | IsoGameCharacter | IsoPlayer
function eHelicopter_zombieAI.onDead_nemesis(zombie, player, bodypart, weapon)
	local currentFireDamage = zombie:getModData()["nemesisFireDmg"] or 0
	if currentFireDamage < 50 then
		zombie:setReanimate(true)
		print("EHE:SWH:specialZombie_nemesis: zombie is not dying today.")
	end
end

---@param zombie IsoObject | IsoGameCharacter | IsoZombie
---@param player IsoObject | IsoGameCharacter | IsoPlayer
function eHelicopter_zombieAI.onDead(zombie, player, bodypart, weapon)
	if not zombie then
		return
	end

	local attachedItems = zombie:getAttachedItems()
	for i=0, attachedItems:size()-1 do
		---@type InventoryItem
		local storedAIItem = attachedItems:getItemByIndex(i)
		if storedAIItem and storedAIItem:getModule() == "ZombieAI" then
			local storedAI = storedAIItem:getType()
			local specialAI = eHelicopter_zombieAI["onDead_"..storedAI]
			if specialAI then
				specialAI(zombie, player, bodypart, weapon)
			end
		end
	end
end
Events.OnZombieDead.Add(eHelicopter_zombieAI.onDead)


---@param zombie IsoObject | IsoGameCharacter | IsoZombie
---@param player IsoObject | IsoGameCharacter | IsoPlayer
function eHelicopter_zombieAI.onHit_nemesis(zombie, player, bodypart, weapon)
	local currentFireDamage = zombie:getModData()["nemesisFireDmg"] or 0
	if currentFireDamage < 50 then
		zombie:setHealth(zombie:getHealth()*1000001)
		print("EHE:SWH:specialZombie_nemesis: zombie is not dying today.")
	end
end

---@param zombie IsoObject | IsoGameCharacter | IsoZombie
---@param player IsoObject | IsoGameCharacter | IsoPlayer
function eHelicopter_zombieAI.onHit(player, zombie, bodyPart, weapon)
	if not zombie then
		return
	end

	local attachedItems = zombie:getAttachedItems()
	for i=0, attachedItems:size()-1 do
		---@type InventoryItem
		local storedAIItem = attachedItems:getItemByIndex(i)
		if storedAIItem and storedAIItem:getModule() == "ZombieAI" then
			local storedAI = storedAIItem:getType()
			local specialAI = eHelicopter_zombieAI["onHit_"..storedAI]
			if specialAI then
				specialAI(player, zombie, bodyPart, weapon)
			end
		end
	end
end
Events.OnWeaponHitCharacter.Add(eHelicopter_zombieAI.onHit)



---@param zombie IsoZombie | IsoGameCharacter | IsoObject
---@param apply boolean
function eHelicopter_zombieAI.checkForAI(zombie, apply)
	if not zombie then
		return
	end
	if zombie:isDead() then
		print("EHE:SWH:SZ:checkForAI: zombie is dead.")
		return
	end
	local attachedItems = zombie:getAttachedItems()
	for i=0, attachedItems:size()-1 do
		---@type InventoryItem
		local storedAIItem = attachedItems:getItemByIndex(i)
		if storedAIItem and storedAIItem:getModule() == "ZombieAI" then
			local storedAI = storedAIItem:getType()
			local specialAI = eHelicopter_zombieAI["specialZombie_"..storedAI]
			if specialAI then
				if zombie:getModData()["initApply"] ~= true then
					print("initApply not true, setting `apply` to true")
					apply = true
					zombie:getModData()["initApply"] = true
				end

				specialAI(zombie, apply or false)
			end
		end
	end
end
Events.OnZombieUpdate.Add(eHelicopter_zombieAI.checkForAI)
