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
		--print("AI onUpdate: specialZombie_gottaGoFast")
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
		--print("AI onUpdate: specialZombie_nemesis")
		if zombie:isCrawling() then
			zombie:toggleCrawling()
		end
	end
end


---@param zombie IsoZombie | IsoGameCharacter | IsoObject
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
				if not zombie:getModData()["initApply"] then
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