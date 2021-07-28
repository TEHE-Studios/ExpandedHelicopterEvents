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
		zombie:setFireKillRate(zombie:getFireKillRate()*1000001)
	else
		--print("AI onUpdate: specialZombie_nemesis")
		if zombie:isCrawling() then
			zombie:toggleCrawling()
		end

		if zombie:isBeingSteppedOn() then
			local squaresInRange = getIsoRange(zombie, 0)
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

		local target = zombie:getTarget()
		if target and instanceof(target, "IsoPlayer") and not zombie:getModData()["tempTarget"] then
			zombie:getModData()["tempTarget"] = target
			print("zombieAi new target = "..tostring(zombie:getModData()["tempTarget"]))
		end
		zombie:setTarget(zombie:getModData()["tempTarget"])
		zombie:pathToCharacter(zombie:getModData()["tempTarget"])
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
				specialAI(zombie)
			end
		end
	end
end
Events.OnZombieDead.Add(eHelicopter_zombieAI.onDead)


---@param zombie IsoObject | IsoGameCharacter | IsoZombie
---@param player IsoObject | IsoGameCharacter | IsoPlayer
function eHelicopter_zombieAI.onHit_nemesis(player, zombie, weapon, notsure)
	print("player:"..tostring(player))
	print("zombie:"..tostring(zombie))
	print("weapon:"..tostring(weapon))
	print("notsure:"..tostring(notsure))
end

---@param zombie IsoObject | IsoGameCharacter | IsoZombie
---@param player IsoObject | IsoGameCharacter | IsoPlayer
function eHelicopter_zombieAI.onHit(player, zombie, weapon, notsure)
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
				specialAI(zombie)
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
