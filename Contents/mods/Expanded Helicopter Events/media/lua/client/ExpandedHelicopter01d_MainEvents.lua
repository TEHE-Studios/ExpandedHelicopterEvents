---Heli goes down

---@param vehicle BaseVehicle
function eHelicopter.applyCrashOnVehicle(vehicle)
	if not vehicle then
		return
	end
	vehicle:crash(1000,true)
	vehicle:crash(1000,false)

	for i=0, vehicle:getPartCount() do
		---@type VehiclePart
		local part = vehicle:getPartByIndex(i) --VehiclePart
		if part then
			local partDoor = part:getDoor()
			if partDoor ~= nil then
				partDoor:setLocked(false)
			end
		end
	end
end


function eHelicopter:crash()

	if self.crashType then
		---@type IsoGridSquare

		if self.formationFollowingHelis then
			local newLeader
			for heli,offset in pairs(self.formationFollowingHelis) do
				if heli then
					newLeader = heli
					break
				end
			end
			if newLeader then
				newLeader.state = self.state
				self.formationFollowingHelis[newLeader] = nil
				newLeader.formationFollowingHelis = self.formationFollowingHelis
				self.formationFollowingHelis = {}
			end
		end

		local heliX, heliY, _ = self:getXYZAsInt()
		local actualSquare = getSquare(heliX,heliY,0)
		local currentSquare = getOutsideSquareFromAbove(actualSquare,true)

		local vehicleType = self.crashType[ZombRand(1,#self.crashType+1)]

		if currentSquare then
			local heli = addVehicleDebug(vehicleType, IsoDirections.getRandom(), nil, currentSquare)
			if heli then
				eHelicopter.applyCrashOnVehicle(heli)
			end
		else
			farSquareSpawn.setToSpawn("Vehicle", vehicleType, heliX, heliY, 0, {eHelicopter.applyCrashOnVehicle})
		end

		self.crashType = false

		--drop scrap and parts
		if self.scrapItems or self.scrapVehicles then
			self:dropScrap(6)
		end

		--drop package on crash
		if self.dropPackages then
			self:dropCarePackage(2)
		end

		--drop all items
		if self.dropItems then
			self:dropAllItems(4)
		end

		if self.addedFunctionsToEvents then
			local eventFunction = self.addedFunctionsToEvents["OnCrash"]
			if eventFunction then
				eventFunction(self, currentSquare)
			end
		end

		--[[DEBUG]] print("---- EHE: CRASH EVENT: HELI: "..self:heliToString(true)..":"..vehicleType.." day:" ..getGameTime():getNightsSurvived())
		self:spawnCrew()
		addSound(nil, heliX, heliY, 0, 250, 300)
		self:playEventSound("crashEvent")

		EHE_EventMarkerHandler.setOrUpdateMarkers(nil, "media/ui/crash.png", 1500, heliX, heliY)

		self:unlaunch()
		getGameTime():getModData()["DayOfLastCrash"] = math.max(1,getGameTime():getNightsSurvived())
		return true
	end
	return false
end


---@param arrayOfZombies ArrayList
function eHelicopter.applyDeathOrCrawlerToCrew(arrayOfZombies)
	if arrayOfZombies and arrayOfZombies:size()>0 then
		local zombie = arrayOfZombies:get(0)
		--33% to be dead on arrival
		if ZombRand(1,101) <= 33 then
			--print("crash spawned: "..outfitID.." killed")
			zombie:setHealth(0)
		else
			if ZombRand(1,101) <= 25 then
				--print("crash spawned: "..outfitID.." crawler")
				zombie:setCanWalk(false)
				zombie:setBecomeCrawler(true)
				zombie:knockDown(true)
			end
		end
	end
end

---Heli spawn crew
function eHelicopter:spawnCrew(deathChance,crawlChance)
	if not self.crew then
		return
	end

	local anythingSpawned = {}

	local addedEventFunction
	if self.addedFunctionsToEvents then
		addedEventFunction = self.addedFunctionsToEvents["OnSpawnCrew"]
	end

	for key,outfitID in pairs(self.crew) do

		--The chance this type of zombie is spawned
		local chance = self.crew[key+1]
		--If the next entry in the list is a number consider it to be a chance, otherwise use 100%
		if type(chance) ~= "number" then
			chance = 100
		end

		--NOTE: This is the chance the zombie will be female - 100% = female, 0% = male
		local femaleChance = self.crew[key+2]
		--If the next entry in the list is a number consider it to be a chance, otherwise use 50%
		if type(femaleChance) ~= "number" then
			femaleChance = 50
		end

		--assume all strings to be outfidID and roll chance/100
		if (type(outfitID) == "string") and (ZombRand(101) <= chance) then
			local heliX, heliY, _ = self:getXYZAsInt()
			--fuzz up the location
			local fuzzNums = {-5,-4,-3,-3,3,3,4,5}
			if heliX and heliY then
				heliX = heliX+fuzzNums[ZombRand(#fuzzNums)+1]
				heliY = heliY+fuzzNums[ZombRand(#fuzzNums)+1]
			end

			local bodyLoc = getOutsideSquareFromAbove(getSquare(heliX,heliY,0))
			--if there is an actual location - IsoGridSquare may not be loaded in under certain circumstances

			if bodyLoc then
				local spawnedZombies = addZombiesInOutfit(bodyLoc:getX(), bodyLoc:getY(), bodyLoc:getZ(), 1, outfitID, femaleChance)
				if spawnedZombies and spawnedZombies:size()>0 then
					eHelicopter.applyDeathOrCrawlerToCrew(spawnedZombies)
					local zombie = spawnedZombies:get(0)
					if zombie then
						table.insert(anythingSpawned, zombie)
					end
				end
			else
				farSquareSpawn.setToSpawn("Zombie", outfitID, heliX, heliY, 0, {eHelicopter.applyDeathOrCrawlerToCrew, addedEventFunction})
			end
		end
	end
	self.crew = false

	if #anythingSpawned and addedEventFunction then
		addedEventFunction(anythingSpawned)
	end

	return anythingSpawned
end


---Heli drops all items
function eHelicopter:dropAllItems(fuzz)
	fuzz = fuzz or 0
	for itemType,quantity in pairs(self.dropItems) do

		local fuzzyWeight = {}
		if fuzz == 0 then
			fuzzyWeight = {0}
		else
			for i=1, fuzz do
				for ii=i, (fuzz+1)-i do
					table.insert(fuzzyWeight, i)
				end
			end
		end

		for i=1, self.dropItems[itemType] do
			self:dropItem(itemType,fuzz*fuzzyWeight[ZombRand(#fuzzyWeight)+1])
		end
		self.dropItems[itemType] = nil
	end
end


---Heli drop items with chance
function eHelicopter:tryToDropItem(chance, fuzz)
	fuzz = fuzz or 0
	chance = (ZombRand(101) <= chance)
	for itemType,quantity in pairs(self.dropItems) do
		if (self.dropItems[itemType] > 0) and chance then
			self.dropItems[itemType] = self.dropItems[itemType]-1
			self:dropItem(itemType,fuzz)
		end
		if (self.dropItems[itemType] <= 0) then
			self.dropItems[itemType] = nil
		end
	end
end


---Heli drop item
function eHelicopter:dropItem(type, fuzz)
	fuzz = fuzz or 0
	if not self.dropItems then
		return
	end

	local heliX, heliY, _ = self:getXYZAsInt()
	if heliX and heliY then
		local minX, maxX = 2, 3+fuzz
		if ZombRand(1, 101) <= 50 then
			minX, maxX = -2, 0-(3+fuzz)
		end
		heliX = heliX+ZombRand(minX,maxX)
		local minY, maxY = 2, 3+fuzz
		if ZombRand(1, 101) <= 50 then
			minY, maxY = -2, 0-(3+fuzz)
		end
		heliY = heliY+ZombRand(minY,maxY)
	end
	local currentSquare = getOutsideSquareFromAbove(getSquare(heliX,heliY,0))

	if currentSquare then
		currentSquare:AddWorldInventoryItem(type, 0, 0, 0)
	else
		farSquareSpawn.setToSpawn("Item", type, heliX, heliY, 0)
	end
end


---@param vehicle BaseVehicle
function eHelicopter.applyParachuteToCarePackage(vehicle)
	vehicle:getSquare():AddWorldInventoryItem("EHE.EHE_Parachute", 0, 0, 0)
end

---Heli drop carePackage
---@param fuzz number
---@return BaseVehicle package
function eHelicopter:dropCarePackage(fuzz)
	fuzz = fuzz or 0

	if not self.dropPackages then
		return
	end

	local carePackage = self.dropPackages[ZombRand(1,#self.dropPackages+1)]
	local carePackagesWithOutChutes = {["FEMASupplyDrop"]=true}

	local heliX, heliY, _ = self:getXYZAsInt()
	if heliX and heliY then
		local minX, maxX = 2, 3+fuzz
		if ZombRand(1, 101) <= 50 then
			minX, maxX = -2, 0-(3+fuzz)
		end
		heliX = heliX+ZombRand(minX,maxX+1)
		local minY, maxY = 2, 3+fuzz
		if ZombRand(1, 101) <= 50 then
			minY, maxY = -2, 0-(3+fuzz)
		end
		heliY = heliY+ZombRand(minY,maxY+1)
	end
	local currentSquare = getOutsideSquareFromAbove(getSquare(heliX, heliY, 0),true)

	--[[DEBUG]] print("EHE: "..carePackage.." dropped: "..currentSquare:getX()..", "..currentSquare:getY())
	if currentSquare then
		local airDrop = addVehicleDebug(carePackage, IsoDirections.getRandom(), nil, currentSquare)
		if airDrop then
			if carePackagesWithOutChutes[carePackage]~=true then
				eHelicopter.applyParachuteToCarePackage(airDrop)
			end
		end
	else
		local parachuteFunc
		if carePackagesWithOutChutes[carePackage]~=true then
			parachuteFunc = eHelicopter.applyParachuteToCarePackage
		end
		farSquareSpawn.setToSpawn("Vehicle", carePackage, heliX, heliY, 0, {parachuteFunc})
	end

	self:playEventSound("droppingPackage")
	EHE_EventMarkerHandler.setOrUpdateMarkers(nil, "media/ui/airdrop.png", 1500, heliX, heliY)
	self.dropPackages = false
end


---Heli drop scrap
function eHelicopter:dropScrap(fuzz)
	fuzz = fuzz or 0

	local heliX, heliY, _ = self:getXYZAsInt()

	for key,partType in pairs(self.scrapItems) do
		if type(partType) == "string" then

			local iterations = self.scrapItems[key+1]
			if type(iterations) ~= "number" then
				iterations = 1
			end

			for i=1, iterations do
				if heliX and heliY then
					local minX, maxX = 2, 3+fuzz
					if ZombRand(101) <= 50 then
						minX, maxX = -2, 0-(3+fuzz)
					end
					heliX = heliX+ZombRand(minX,maxX)
					local minY, maxY = 2, 3+fuzz
					if ZombRand(101) <= 50 then
						minY, maxY = -2, 0-(3+fuzz)
					end
					heliY = heliY+ZombRand(minY,maxY)
				end

				local currentSquare = getOutsideSquareFromAbove(getSquare(heliX, heliY, 0),true)

				if currentSquare then
					currentSquare:AddWorldInventoryItem(partType, 0, 0, 0)
				else
					farSquareSpawn.setToSpawn("Item", partType, heliX, heliY, 0)
				end
			end
		end
	end

	for key,partType in pairs(self.scrapVehicles) do
		if type(partType) == "string" then

			local iterations = self.scrapVehicles[key+1]
			if type(iterations) ~= "number" then
				iterations = 1
			end

			for i=1, iterations do
				if heliX and heliY then
					local minX, maxX = 2, 3+fuzz
					if ZombRand(101) <= 50 then
						minX, maxX = -2, 0-(3+fuzz)
					end
					heliX = heliX+ZombRand(minX,maxX)
					local minY, maxY = 2, 3+fuzz
					if ZombRand(101) <= 50 then
						minY, maxY = -2, 0-(3+fuzz)
					end
					heliY = heliY+ZombRand(minY,maxY)
				end

				local currentSquare = getOutsideSquareFromAbove(getSquare(heliX, heliY, 0),true)

				if currentSquare then
					addVehicleDebug(partType, IsoDirections.getRandom(), nil, currentSquare)
				else
					farSquareSpawn.setToSpawn("Vehicle", partType, heliX, heliY, 0)
				end
			end
		end
	end

	self.scrapItems = false
	self.scrapVehicles = false
end


--addedFunctionsToEvents = {["OnFlyaway"] = eHelicopter:dropTrash()},
function eHelicopter_dropTrash(heli, location)

	local heliX, heliY, _ = heli:getXYZAsInt()
	local trashItems = {"Pop3Empty","PopEmpty","Pop2Empty","WhiskeyEmpty","BeerCanEmpty","BeerEmpty"}
	local iterations = 10

	for i=1, iterations do

		heliY = heliY+ZombRand(-2,3)
		heliX = heliX+ZombRand(-2,3)
		
		local currentSquare = getOutsideSquareFromAbove(getSquare(heliX, heliY, 0),true)

		local trashType = trashItems[(ZombRand(#trashItems)+1)]
		--more likely to drop the same thing
		table.insert(trashItems, trashType)

		if currentSquare then
			currentSquare:AddWorldInventoryItem(trashType, 0, 0, 0)
		else
			farSquareSpawn.setToSpawn("Item", trashType, heliX, heliY, 0)
		end
	end
end
