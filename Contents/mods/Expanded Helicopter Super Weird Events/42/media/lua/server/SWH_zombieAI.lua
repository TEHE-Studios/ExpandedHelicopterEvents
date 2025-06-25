if isServer() then return end

local isoRangeScan = require "EHE_IsoRangeScan"

local eHelicopter_zombieAI = {}

eHelicopter_zombieAI.outfitsToAI = {

	["AlienTourist"] = "gottaGoFast",
	["AlienRedneck"] = "gottaGoFast",
	["AlienSanta"] = "gottaGoFast",
	["AlienBeefo"] = "gottaGoFast",

	["SpiffoBoss"] = "nemesis",

	["RobertJohnson"] = "licking",
	["SockConnoisseur"] = "sockThief",

	["TaxMan"] = "fodder",

}


---@param zombie IsoZombie | IsoGameCharacter | IsoObject | IsoDeadBody
function eHelicopter_zombieAI.checkForAI(zombie)
	if not zombie then return end

	local zombieOutfit = zombie:getOutfitName()
	local AI = zombieOutfit and eHelicopter_zombieAI.outfitsToAI[zombieOutfit]
	return AI
end



---@param zombie IsoZombie | IsoGameCharacter | IsoObject
---@param apply boolean
function eHelicopter_zombieAI.onUpdate_fodder(zombie, apply)
	if not zombie then return end
	if apply then
		--print("EHE:SWH:SZ:AI onApply: fodder")
		zombie:setHealth(0.01)
		zombie:setAttackedBy(getCell():getFakeZombieForHit())
	end
end


---@param zombie IsoZombie | IsoGameCharacter | IsoObject
---@param apply boolean
function eHelicopter_zombieAI.onUpdate_gottaGoFast(zombie, apply)
	if not zombie then return end

	if apply then
		--print("EHE:SWH:SZ:AI onApply: gottaGoFast")
	else
		zombie:setWalkType("sprint1")
		if zombie:isCrawling() then zombie:toggleCrawling()end
	end
end


eHelicopter_zombieAI.lickingTracker = {}
---@param zombie IsoZombie | IsoGameCharacter | IsoObject | IsoMovingObject
---@param apply boolean
function eHelicopter_zombieAI.onUpdate_licking(zombie, apply)
	if not zombie then return end

	if apply then
		--print("EHE:SWH:SZ:AI onApply: licking")
		zombie:setNoTeeth(true)
	else
		zombie:setWalkType("sprint1")
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


---@param zombie IsoZombie | IsoGameCharacter | IsoObject | IsoMovingObject
---@param apply boolean
function eHelicopter_zombieAI.onUpdate_sockThief(zombie, apply)
	if not zombie and not zombie:isDead() then return end

	if apply then
		zombie:setNoTeeth(true)
	else
		zombie:setWalkType("sprint1")

		--(String, r, g, b, UIFont, scrambleF, TAG)
		zombie:addLineChatElement("Sock Connoisseur", 1, 1, 1, UIFont.NewSmall, 100, "default")

		if (not zombie:isOnFloor()) then

			---@type BaseCharacterSoundEmitter | BaseSoundEmitter | FMODSoundEmitter
			local zombieEmitter = zombie:getEmitter()
			if zombieEmitter then
				zombieEmitter:stopSoundByName("MaleZombieCombined")
				zombieEmitter:stopSoundByName("FemaleZombieCombined")
				zombieEmitter:stopSoundByName("MaleZombieHurt")
				zombieEmitter:stopSoundByName("FemaleZombieHurt")
			end

			if zombie:isForceEatingAnimation() then
				if not zombieEmitter:isPlaying("sockThiefSniff") then
					zombie:playSound("sockThiefSniff")
				end
			end

			local target = zombie:getTarget()
			if zombie and target and instanceof(target, "IsoPlayer") then
				---@type IsoPlayer | IsoGameCharacter | IsoObject | IsoMovingObject
				local player = target
				if zombie:getDistanceSq(player) <= 0.66 and zombie:getCurrentState() == AttackState.instance() then

					if (not player:getBumpedChr()) and (not player:isOnFloor()) and (not player:getVehicle()) then
						player:setBumpedChr(target)
						player:clearVariable("BumpFallType")
						player:setBumpType("stagger")
						player:setBumpDone(false)
						player:setBumpFall(true)
						player:setBumpFallType("pushedFront")

						local playerWornItems = player:getWornItems()
						if not playerWornItems then return end
						local socks, shoes
						for i=0, playerWornItems:size()-1 do
							local wornItem = playerWornItems:get(i)
							local item = wornItem and wornItem:getItem()
							if item then
								if item:getBodyLocation()=="Socks" then socks = item end
								if item:getBodyLocation()=="Shoes" then shoes = item end
							end
						end
						if socks then
							player:removeWornItem(socks)
							player:getInventory():DoRemoveItem(socks)
							player:getSquare():AddWorldInventoryItem(socks, 0, 0, 0)
						end
						if shoes then
							player:removeWornItem(shoes)
							player:getInventory():DoRemoveItem(shoes)
							player:getSquare():AddWorldInventoryItem(shoes, 0, 0, 0)
						end
						zombie:setForceEatingAnimation(true)
					end
				end
			end
		end
	end
end


eHelicopter_zombieAI.nemesisFireDmgTracker = {}
---@param zombie IsoZombie | IsoGameCharacter | IsoObject | IsoMovingObject
---@param apply boolean
function eHelicopter_zombieAI.onUpdate_nemesis(zombie, apply)
	if not zombie then
		return
	end

	if apply then
		zombie:setCanCrawlUnderVehicle(false)
		zombie:setReanimatedPlayer(false)

	else

		zombie:setWalkType("slow1")
		zombie:setCanWalk(true)

		if zombie:isCrawling() then zombie:toggleCrawling() end
		--zombie:setHealth(100)
		--zombie:setAttackedBy(getCell():getFakeZombieForHit())

		local currentFireDamage = eHelicopter_zombieAI.nemesisFireDmgTracker[zombie] or 0
		if zombie:isOnFire() then
			currentFireDamage = currentFireDamage+1
			eHelicopter_zombieAI.nemesisFireDmgTracker[zombie] = currentFireDamage
			--print("EHE:SWH:nemesis: zombie is on fire.")
		end

		if currentFireDamage > eHelicopter_zombieAI.nemesis_burnTime then
			zombie:setHealth(0)
			zombie:setAttackedBy(getCell():getFakeZombieForHit())
			--print("EHE:SWH:nemesis: zombie is crispy.")
			return
		end

		if zombie:isOnFloor() then
			local squaresInRange = isoRangeScan.getIsoRange(zombie, 1)
			for k,sq in pairs(squaresInRange) do
				---@type IsoGridSquare
				local square = sq
				local objs = square:getMovingObjects()
				for i=0, objs:size()-1 do
					local foundObj = objs:get(i)

					if foundObj and (foundObj ~= zombie) then
						if instanceof(foundObj, "BaseVehicle") then

							---@type BaseVehicle | IsoObject | IsoMovingObject
							local car = foundObj
							--flip car
							if car then
								zombie:getModData()["pushedCars"] = zombie:getModData()["pushedCars"] or {}
								local pushedCarRecord = zombie:getModData()["pushedCars"][car]
								if not pushedCarRecord or (pushedCarRecord < getTimestampMs()) then

									local pushForce = 15

									local x_fuzz = ZombRand(3,5)
									if ZombRand(100) <= 50 then
										x_fuzz = 0-x_fuzz
									end
									local y_fuzz = ZombRand(3,5)
									if ZombRand(100) <= 50 then
										y_fuzz = 0-y_fuzz
									end

									local vector3f_a = Vector3f.new(zombie:getX(),zombie:getY(),zombie:getZ())
									local vector3f_b = Vector3f.new(car:getX()+x_fuzz,car:getY()+y_fuzz,car:getZ()+1)

									car:addImpulse(vector3f_a,vector3f_b:mul(pushForce))
									car:setPhysicsActive(true)
									zombie:getModData()["pushedCars"][car] = getTimestampMs()+250
								end
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

		local foreverTarget = zombie:getModData()["foreverTarget"]
		if not foreverTarget then
			---@type IsoMovingObject | IsoGameCharacter | IsoObject
			local choice
			for character,value in pairs(EHEIsoPlayers) do
				if (not choice) or (choice and character and (zombie:getDistanceSq(choice) < zombie:getDistanceSq(character))) then
					choice = character
				end
			end
			zombie:getModData()["foreverTarget"] = choice
		end
		if (not zombie:getTarget()) and foreverTarget then
			zombie:spotted(foreverTarget, true)
		end

	end
end


---@param AI_ID string
---@param location IsoGridSquare
function eHelicopter_zombieAI.reviveAI(AI_ID,location)
	if not AI_ID or not location then return end

	local squaresInRange = isoRangeScan.getIsoRange(location, 3)
	for sq=1, #squaresInRange do
		---@type IsoGridSquare
		local square = squaresInRange[sq]
		local squareContents = square:getDeadBodys()

		for i=0, squareContents:size()-1 do
			---@type IsoDeadBody
			local foundObj = squareContents:get(i)
			if instanceof(foundObj, "IsoDeadBody") then
				if eHelicopter_zombieAI.checkForAI(foundObj) == "nemesis" then
					foundObj:reanimateNow()
					location:playSound("SpiffoGiggle")
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


eHelicopter_zombieAI.nemesis_burnTime = 500
---@param zombie IsoObject | IsoGameCharacter | IsoZombie
---@param player IsoObject | IsoGameCharacter | IsoPlayer
function eHelicopter_zombieAI.onDead_nemesis(zombie, player, bodyPart, weapon)
	zombie:setHealth(1000)
	local currentFireDamage = eHelicopter_zombieAI.nemesisFireDmgTracker[zombie] or 0
	if currentFireDamage < eHelicopter_zombieAI.nemesis_burnTime then
		zombie:setOnDeathDone(false)
		table.insert(eHelicopter_zombieAI.reviveEvents,{time=getTimestampMs()+2000,AI_ID="nemesis",location=zombie:getSquare()})
	end
end


---@param zombie IsoObject | IsoGameCharacter | IsoZombie
---@param player IsoObject | IsoGameCharacter | IsoPlayer
function eHelicopter_zombieAI.onDead_gottaGoFast(zombie, player, bodyPart, weapon)
	if ZombRand(100) <= 25 then zombie:getInventory():AddItems("SWH.AlienPowerCells", ZombRand(1,4)) end
	if ZombRand(1000) <= 1 then zombie:getInventory():AddItem("SWH.AlienBlaster") end
end


---@param zombie IsoObject | IsoGameCharacter | IsoZombie
---@param player IsoObject | IsoGameCharacter | IsoPlayer
function eHelicopter_zombieAI.onDead(zombie, player, bodyPart, weapon)
	if not zombie then return end

	local AI = eHelicopter_zombieAI.checkForAI(zombie)
	local specialAI = AI and eHelicopter_zombieAI["onDead_"..AI]
	if specialAI then
		--[DEBUG]] print("SWH: AI found: <"..AI_ID..">")
		specialAI(zombie, player, bodyPart, weapon)
	end
end
Events.OnZombieDead.Add(eHelicopter_zombieAI.onDead)



---@param zombie IsoObject | IsoGameCharacter | IsoZombie
---@param player IsoObject | IsoGameCharacter | IsoPlayer
---@param handWeapon HandWeapon | InventoryItem
function eHelicopter_zombieAI.onHit_nemesis(player, zombie, handWeapon, damage)

	local currentFireDamage = eHelicopter_zombieAI.nemesisFireDmgTracker[zombie] or 0
	if currentFireDamage >= eHelicopter_zombieAI.nemesis_burnTime then
		zombie:setHealth(0)
	else

		if ZombRand(4) < 1 then
			---@type BaseSoundEmitter | FMODSoundEmitter
			local zombieEmitter = zombie:getEmitter()
			if not zombieEmitter:isPlaying("SpiffoGiggle") then zombieEmitter:playSound("SpiffoGiggle") end
		end

		if handWeapon:getFullType()~="Base.BareHands" then
			zombie:setAvoidDamage(true)
		end
	end
end


---@param attacker IsoObject | IsoGameCharacter | IsoZombie
---@param target IsoObject | IsoGameCharacter | IsoPlayer
function eHelicopter_zombieAI.onHit(attacker, target, bodyPart, weapon)
	local targetAI = eHelicopter_zombieAI.checkForAI(target)
	local onGetHitEvent = targetAI and eHelicopter_zombieAI["onHit_"..targetAI]
	if onGetHitEvent then onGetHitEvent(attacker, target, bodyPart, weapon) end
end
Events.OnWeaponHitCharacter.Add(eHelicopter_zombieAI.onHit)


---@param zombie IsoZombie | IsoGameCharacter | IsoObject
---@param apply boolean
function eHelicopter_zombieAI.onUpdate(zombie, apply)
	if not zombie or zombie:isDead() then return end

	local AI = eHelicopter_zombieAI.checkForAI(zombie)
	local specialAI = AI and eHelicopter_zombieAI["onUpdate_"..AI]
	if specialAI then
		if zombie:getModData()["initApply"] ~= true then
			--[DEBUG]] print("EHE:SWH:SZ:initApply not true, setting `apply` to true")
			apply = true
			zombie:getModData()["initApply"] = true
		end
		specialAI(zombie, apply or false)
	end
end
Events.OnZombieUpdate.Add(eHelicopter_zombieAI.onUpdate)


return eHelicopter_zombieAI
