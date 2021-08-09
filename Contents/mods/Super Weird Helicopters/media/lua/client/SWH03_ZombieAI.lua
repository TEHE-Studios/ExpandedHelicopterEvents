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

AttachedWeaponDefinitions.licking = {
	chance = 100, weaponLocation = {"Special Zombie AI"}, outfit = {"RobertJohnson"},
	bloodLocations = nil, addHoles = false, daySurvived = 0, weapons = { "ZombieAI.licking" } }
AttachedWeaponDefinitions.attachedWeaponCustomOutfit.RobertJohnson = { chance = 100, maxitem = 1, weapons = {AttachedWeaponDefinitions.licking} }


eHelicopter_zombieAI = {}

---@param zombie IsoZombie | IsoGameCharacter | IsoObject | IsoDeadBody
function eHelicopter_zombieAI.checkForAI(zombie)
	if not zombie then
		return
	end

	local AIs = {}

	local attachedItems = zombie:getAttachedItems()
	for i=0, attachedItems:size()-1 do
		---@type InventoryItem
		local storedAIItem = attachedItems:getItemByIndex(i)
		if storedAIItem and storedAIItem:getModule() == "ZombieAI" then
			local storedAI = storedAIItem:getType()
			--[DEBUG]] print(" --- storedAI: (attached) "..storedAI)
			AIs[storedAI] = true
		end
	end

	local container = zombie:getContainer()
	if container then
		local inventoryItems = container:getItems()
		for i=0, inventoryItems:size()-1 do
			---@type InventoryItem
			local storedAIItem = inventoryItems:get(i)
			if storedAIItem and storedAIItem:getModule() == "ZombieAI" then
				local storedAI = storedAIItem:getType()
				--[DEBUG]] print(" --- storedAI: (container) "..storedAI)
				AIs[storedAI] = true
			end
		end
	end

	return AIs
end


---@param zombie IsoZombie | IsoGameCharacter | IsoObject
---@param apply boolean
function eHelicopter_zombieAI.onUpdate_gottaGoFast(zombie, apply)
	if not zombie then
		return
	end
	if apply then
		print("EHE:SWH:SZ:AI onApply: gottaGoFast")
		zombie:changeSpeed(1)
		zombie:DoZombieStats()
		zombie:setSpeedMod(10)

	else
		if zombie:isCrawling() then
			zombie:toggleCrawling()
		end
	end
end


eHelicopter_zombieAI.lickingTracker = {}
---@param zombie IsoZombie | IsoGameCharacter | IsoObject | IsoMovingObject
---@param apply boolean
function eHelicopter_zombieAI.onUpdate_licking(zombie, apply)
	if not zombie then
		return
	end
	if apply then
		print("EHE:SWH:SZ:AI onApply: licking")
		zombie:setNoTeeth(true)
		zombie:changeSpeed(1)
		zombie:DoZombieStats()
		zombie:setSpeedMod(10)

	else
		if (not zombie:isDead()) and (not zombie:isOnFloor()) and zombie:isAttacking() then
			---@type BaseCharacterSoundEmitter | BaseSoundEmitter | FMODSoundEmitter
			local zombieEmitter = zombie:getEmitter()
			if zombieEmitter then
				zombieEmitter:stopSoundByName("MaleZombieCombined")
				zombieEmitter:stopSoundByName("FemaleZombieCombined")
				zombieEmitter:stopSoundByName("MaleZombieHurt")
				zombieEmitter:stopSoundByName("FemaleZombieHurt")
			end
			if (not eHelicopter_zombieAI.lickingTracker[zombie]) or (eHelicopter_zombieAI.lickingTracker[zombie] < getTimestampMs()) then
				eHelicopter_zombieAI.lickingTracker[zombie] = getTimestampMs()+ZombRand(800,900)
				zombie:playSound("ZombieLick")
			end
		end
	end
end

eHelicopter_zombieAI.nemesisFireDmgTracker = {}
---@param zombie IsoZombie | IsoGameCharacter | IsoObject
---@param apply boolean
function eHelicopter_zombieAI.onUpdate_nemesis(zombie, apply)
	if not zombie then
		return
	end
	if apply then
		print("EHE:SWH:SZ:AI onApply: nemesis")
		if ZombRand(101) <= 10 then
			zombie:changeSpeed(1)
		else
			zombie:changeSpeed(2)
		end
		zombie:setCanCrawlUnderVehicle(false)
		zombie:DoZombieStats()
		zombie:setHealth(zombie:getHealth()*1000001)
		zombie:setReanimatedPlayer(false)

	else
		zombie:setCanWalk(true)
		if zombie:isCrawling() then
			zombie:toggleCrawling()
		end
		zombie:setHealth(zombie:getHealth()*1000001)

		local currentFireDamage = eHelicopter_zombieAI.nemesisFireDmgTracker[zombie] or 0
		if zombie:isOnFire() then
			currentFireDamage = currentFireDamage+1
			eHelicopter_zombieAI.nemesisFireDmgTracker[zombie] = currentFireDamage
			--print("EHE:SWH:nemesis: zombie is on fire.")
		end

		if currentFireDamage > 250 then
			zombie:setHealth(0)
			--print("EHE:SWH:nemesis: zombie is crispy.")
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
								---flip car
								--print(" --SWH: car found near ZombieAI nemesis")
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
--[[
		local currentTarget = zombie:getTarget()
		local foreverTarget = zombie:getModData()["foreverTarget"] or zombie:getTarget()

		if currentTarget then
			zombie:getModData()["foreverTarget"] = currentTarget
		end
]]

		--zombie:getEnemyList()
		---EnemyList
	end
end


---@param AI_ID string
---@param location IsoGridSquare
function eHelicopter_zombieAI.reviveAI(AI_ID,location)
	if not AI_ID or not location then
		return
	end

	local squaresInRange = getIsoRange(location, 3)
	for sq=1, #squaresInRange do
		---@type IsoGridSquare
		local square = squaresInRange[sq]
		local squareContents = square:getDeadBodys()

		for i=0, squareContents:size()-1 do
			---@type IsoDeadBody
			local foundObj = squareContents:get(i)
			if instanceof(foundObj, "IsoDeadBody") then
				local AIs = eHelicopter_zombieAI.checkForAI(foundObj)
				if AIs and AIs[AI_ID]==true then
					foundObj:reanimateNow()
				end
			end
		end
	end
end


eHelicopter_zombieAI.reviveEvents = {}
function eHelicopter_zombieAI.reviveEventsLoop()
	for k,event in pairs(eHelicopter_zombieAI.reviveEvents) do
		if event and event.time <= getTimestampMs() then
			eHelicopter_zombieAI.reviveAI(event.AI_ID,event.location)
			eHelicopter_zombieAI.reviveEvents[k]=nil
		end
	end
end
Events.OnTick.Add(eHelicopter_zombieAI.reviveEventsLoop)


---@param zombie IsoObject | IsoGameCharacter | IsoZombie
---@param player IsoObject | IsoGameCharacter | IsoPlayer
function eHelicopter_zombieAI.onDead_nemesis(zombie, player, bodyPart, weapon)
	if not zombie then
		return
	end

	zombie:setHealth(zombie:getHealth()*1000001)
	local currentFireDamage = eHelicopter_zombieAI.nemesisFireDmgTracker[zombie] or 0
	if currentFireDamage < 250 then
		zombie:setOnDeathDone(false)
		table.insert(eHelicopter_zombieAI.reviveEvents,{time=getTimestampMs()+2000,AI_ID="nemesis",location=zombie:getSquare()})
	end
end


---@param zombie IsoObject | IsoGameCharacter | IsoZombie
---@param player IsoObject | IsoGameCharacter | IsoPlayer
function eHelicopter_zombieAI.onDead(zombie, player, bodyPart, weapon)
	if not zombie then
		return
	end

	local AIs = eHelicopter_zombieAI.checkForAI(zombie)
	if AIs then
		for AI_ID,_ in pairs(AIs) do
			local specialAI = eHelicopter_zombieAI["onDead_"..AI_ID]
			if specialAI then
				--[DEBUG]] print("SWH: AI found: <"..AI_ID..">")
				specialAI(zombie, player, bodyPart, weapon)
			end
		end
	end
end
Events.OnZombieDead.Add(eHelicopter_zombieAI.onDead)


---@param zombie IsoObject | IsoGameCharacter | IsoZombie
---@param player IsoObject | IsoGameCharacter | IsoPlayer
function eHelicopter_zombieAI.onHit_nemesis(zombie, player, bodypart, weapon)
	local currentFireDamage = eHelicopter_zombieAI.nemesisFireDmgTracker[zombie] or 0
	if currentFireDamage >= 250 then
		zombie:setHealth(0)
	end
end

---@param zombie IsoObject | IsoGameCharacter | IsoZombie
---@param player IsoObject | IsoGameCharacter | IsoPlayer
function eHelicopter_zombieAI.onHit(player, zombie, bodyPart, weapon)
	if not zombie then
		return
	end

	local AIs = eHelicopter_zombieAI.checkForAI(zombie)
	if AIs then
		for AI_ID,_ in pairs(AIs) do
			local specialAI = eHelicopter_zombieAI["onHit_"..AI_ID]
			if specialAI then
				specialAI(zombie, player, bodyPart, weapon)
			end
		end
	end
end
Events.OnWeaponHitCharacter.Add(eHelicopter_zombieAI.onHit)


---@param zombie IsoZombie | IsoGameCharacter | IsoObject
---@param apply boolean
function eHelicopter_zombieAI.onUpdate(zombie, apply)
	if not zombie or zombie:isDead() then
		return
	end

	local AIs = eHelicopter_zombieAI.checkForAI(zombie)
	if AIs then
		for AI_ID,_ in pairs(AIs) do
			local specialAI = eHelicopter_zombieAI["onUpdate_"..AI_ID]
			if specialAI then
				if zombie:getModData()["initApply"] ~= true then
					--[DEBUG]] print("EHE:SWH:SZ:initApply not true, setting `apply` to true")
					apply = true
					zombie:getModData()["initApply"] = true
				end
				specialAI(zombie, apply or false)
			end
		end
	end
end
Events.OnZombieUpdate.Add(eHelicopter_zombieAI.onUpdate)
