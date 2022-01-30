require "ExpandedHelicopter01c_MainCore"
require "ExpandedHelicopter01a_MainVariables"
require "ExpandedHelicopter00c_SpawnerAPI"
require "ExpandedHelicopter00a_Util"
--Heli goes down


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
		local vehicleType = self.crashType[ZombRand(1,#self.crashType+1)]

		local extraFunctions = {"applyCrashOnVehicle"}
		if self.addedFunctionsToEvents then
			local eventFunction = self.currentPresetID.."OnCrash"--self.addedFunctionsToEvents["OnCrash"]
			if eventFunction then
				table.insert(extraFunctions, eventFunction)
			end
		end

		SpawnerTEMP.spawnVehicle(vehicleType, heliX, heliY, 0, extraFunctions, nil, "getOutsideSquareFromAbove_vehicle")

		self.crashType = false
		self.state = "crashed"
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

		--[[DEBUG]] print("---- EHE: CRASH EVENT: HELI: "..self:heliToString(true)..":"..vehicleType.." day:" ..getGameTime():getNightsSurvived())
		self:spawnCrew()
		addSound(nil, heliX, heliY, 0, 250, 300)
		eventSoundHandler:playEventSound(self, "crashEvent")

		eventMarkerHandler.setOrUpdate(getRandomUUID(), "media/ui/crash.png", 180, heliX, heliY)

		self:unlaunch()

		local globalModData = getExpandedHeliEventsModData()
		globalModData.DayOfLastCrash = math.max(1,getGameTime():getNightsSurvived())
		return true
	end
	return false
end


---Heli spawn crew
function eHelicopter:spawnCrew(x, y, z)
	if not self.crew then
		return
	end

	local heliX, heliY, heliZ = self:getXYZAsInt()
	x = x or heliX
	y = y or heliY
	z = z or heliZ

	local onSpawnCrewEvents = {"applyDeathOrCrawlerToCrew"}
	local preset = eHelicopter_PRESETS[self.currentPresetID]
	if preset then
		local presetFuncs = preset.addedFunctionsToEvents
		if presetFuncs then
			if presetFuncs.OnSpawnCrew then
				onSpawnCrewEvents = {self.currentPresetID.."OnSpawnCrew"}
			end
		end
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

			--fuzz up the location
			local fuzzNums = {-5,-4,-3,-3,3,3,4,5}
			if x and y then
				x = x+fuzzNums[ZombRand(#fuzzNums)+1]
				y = y+fuzzNums[ZombRand(#fuzzNums)+1]
			end

			SpawnerTEMP.spawnZombie(outfitID, x, y, 0, onSpawnCrewEvents, femaleChance, "getOutsideSquareFromAbove")

		end
	end
	self.crew = false
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
		local min, max = 0-3-fuzz, 3+fuzz
		heliX = heliX+ZombRand(min,max)
		heliY = heliY+ZombRand(min,max)
	end

	SpawnerTEMP.spawnItem(type, heliX, heliY, 0, {"ageInventoryItem"}, nil, "getOutsideSquareFromAbove")
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

	local extraFunctions = {}
	if carePackagesWithOutChutes[carePackage]~=true then
		table.insert(extraFunctions, "applySoundToEvent")
	end

	SpawnerTEMP.spawnVehicle(carePackage, heliX, heliY, 0, extraFunctions, nil, "getOutsideSquareFromAbove_vehicle")
	--[[DEBUG]] print("EHE: "..carePackage.." dropped: "..heliX..", "..heliY)
	eventSoundHandler:playEventSound(self, "droppingPackage")
	addSound(nil, heliX, heliY, 0, 200, 150)
	eventMarkerHandler.setOrUpdate(getRandomUUID(), "media/ui/airdrop.png", 180, heliX, heliY)
	self.dropPackages = false
	return true
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

				SpawnerTEMP.spawnItem(partType, heliX, heliY, 0, {"ageInventoryItem"}, nil, "getOutsideSquareFromAbove")
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

				SpawnerTEMP.spawnVehicle(partType, heliX, heliY, 0, nil, nil, "getOutsideSquareFromAbove")
			end
		end
	end

	self.scrapItems = false
	self.scrapVehicles = false
end


--addedFunctionsToEvents = {["OnFlyaway"] = eHelicopter:dropTrash()},
function eHelicopter_dropTrash(heli)

	local heliX, heliY, _ = heli:getXYZAsInt()
	local trashItems = {"MayonnaiseEmpty","SmashedBottle","Pop3Empty","PopEmpty","Pop2Empty","WhiskeyEmpty","BeerCanEmpty","BeerEmpty"}
	local iterations = 10

	for i=1, iterations do

		heliY = heliY+ZombRand(-2,3)
		heliX = heliX+ZombRand(-2,3)

		local trashType = trashItems[(ZombRand(#trashItems)+1)]
		--more likely to drop the same thing
		table.insert(trashItems, trashType)

		SpawnerTEMP.spawnItem(trashType, heliX, heliY, 0, {"ageInventoryItem"}, nil, "getOutsideSquareFromAbove")
	end
end
