require "EHE_mainCore"
require "EHE_mainVariables"
require "EHE_spawner"
require "EHE_util"
--Heli goes down

local eventSoundHandler = require "EHE_sounds"
local pseudoSquare = require "EHE_psuedoSquare"


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

		local returned_sq
		local square = getSquare(heliX, heliY, 0) or pseudoSquare:new(heliX, heliY, 0)
		if square then
			---@type IsoGridSquare
			returned_sq = getOutsideSquareFromAbove_vehicle(square)
			if returned_sq then
				heliX = returned_sq:getX()
				heliY = returned_sq:getY()
			end
		end

		if not returned_sq then

			local vehicleType = self.crashType[ZombRand(1,#self.crashType+1)]

			local extraFunctions = {"applyCrashOnVehicle"}
			if self.addedFunctionsToEvents then
				local eventFunction = self.currentPresetID.."OnCrash"--self.addedFunctionsToEvents["OnCrash"]
				if eventFunction then
					table.insert(extraFunctions, eventFunction)
				end
			end

			sendClientCommand("SpawnerAPI", "spawn", {
				funcType="vehicle", spawnThis=vehicleType, x=heliX, y=heliY, z=0,
				extraFunctions=extraFunctions, processSquare="getOutsideSquareFromAbove_vehicle" })

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

			--[[DEBUG]] print("---- EHE: CRASH EVENT: "..self:heliToString(true)..":"..vehicleType.." day:" ..getGameTime():getNightsSurvived())
			self:spawnCrew()

			getWorldSoundManager():addSound(nil, heliX, heliY, 0, 175, 300, true, 0, 25)
			eventSoundHandler:playEventSound(self, "crashEvent")
			eventMarkerHandler.setOrUpdate(getRandomUUID(), "media/ui/crash.png", 2600, heliX, heliY, self.markerColor)

			self:unlaunch()

			local globalModData = getExpandedHeliEventsModData()
			globalModData.DayOfLastCrash = math.max(1,getGameTime():getNightsSurvived())
			return true
		end
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

			sendClientCommand("SpawnerAPI", "spawn", {
				funcType="zombie", spawnThis=outfitID, x=x, y=y, z=0,
				extraFunctions=onSpawnCrewEvents, extraParam=femaleChance, processSquare="getOutsideSquareFromAbove" })

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

	sendClientCommand("SpawnerAPI", "spawn", {
		funcType="item", spawnThis=type, x=heliX, y=heliY, z=0,
		extraFunctions={"ageInventoryItem"}, processSquare="getOutsideSquareFromAbove" })

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

	local returned_sq
	local square = getSquare(heliX, heliY, 0) or pseudoSquare:new(heliX, heliY, 0)
	if square then
		---@type IsoGridSquare
		returned_sq = getOutsideSquareFromAbove_vehicle(square)
		if returned_sq then
			heliX = returned_sq:getX()
			heliY = returned_sq:getY()
		end
	end

	if returned_sq then
		local extraFunctions = {"applyFlaresToEvent"}
		if self.addedFunctionsToEvents then
			local eventFunction = self.currentPresetID.."OnDrop"--self.addedFunctionsToEvents["OnCrash"]
			if eventFunction then
				table.insert(extraFunctions, eventFunction)
			end
		end

		sendClientCommand("SpawnerAPI", "spawn", {
			funcType="vehicle", spawnThis=carePackage, x=heliX, y=heliY, z=0,
			extraFunctions=extraFunctions, processSquare="getOutsideSquareFromAbove_vehicle" })

		--[[DEBUG]] print("EHE: "..carePackage.." dropped: "..heliX..", "..heliY)
		eventSoundHandler:playEventSound(self, "droppingPackage")
		addSound(nil, heliX, heliY, 0, 200, 150)
		eventMarkerHandler.setOrUpdate(getRandomUUID(), "media/ui/airdrop.png", 2000, heliX, heliY, self.markerColor)
		self.dropPackages = false
		return true
	end
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

				sendClientCommand("SpawnerAPI", "spawn", {
					funcType="item", spawnThis=partType, x=heliX, y=heliY, z=0,
					extraFunctions={"ageInventoryItem"}, processSquare="getOutsideSquareFromAbove" })
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

				sendClientCommand("SpawnerAPI", "spawn", {
					funcType="vehicle", spawnThis=partType, x=heliX, y=heliY, z=0,
					processSquare="getOutsideSquareFromAbove_vehicle" })

			end
		end
	end

	self.scrapItems = false
	self.scrapVehicles = false
end