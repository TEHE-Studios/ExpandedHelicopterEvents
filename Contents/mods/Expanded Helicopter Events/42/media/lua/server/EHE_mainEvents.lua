require "EHE_mainCore"
require "EHE_mainVariables"
require "EHE_spawner"
require "EHE_util"
--Heli goes down

local eventSoundHandler = require "EHE_sounds"
local pseudoSquare = require "EHE_pseudoSquare"


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
			returned_sq = getOutsideSquareFromAbove(square)
			if returned_sq then
				heliX = returned_sq:getX()
				heliY = returned_sq:getY()
			end
		end

		if not returned_sq then

			local vehicleType = self.crashType[ZombRand(1,#self.crashType+1)]

			local extraFunctions = {"applyCrashOnVehicle","applyCrashDamageToWorld"}
			if self.addedFunctionsToEvents then
				local eventFunction = self.currentPresetID.."OnCrash"--self.addedFunctionsToEvents["OnCrash"]
				if eventFunction then
					table.insert(extraFunctions, eventFunction)
				end
			end

			sendClientCommand("SpawnerAPI", "spawn", {
				funcType="vehicle", spawnThis=vehicleType, x=heliX, y=heliY, z=0,
				extraFunctions=extraFunctions, processSquare="getOutsideSquareFromAbove" })

			self.crashType = false
			self.state = "crashed"
			--drop scrap and parts
			if self.scrapItems or self.scrapVehicles then
				self:dropScrap(8)
			end

			--drop package on crash
			if self.dropPackages then
				self:dropCarePackage(4)
			end

			--drop all items
			if self.dropItems then
				self:dropAllItems(5)
			end

			--[[DEBUG]] print("---- EHE: CRASH EVENT: "..self:heliToString(true)..":"..vehicleType.." day:" ..getGameTime():getNightsSurvived())
			self:spawnDeadCrew()

			getWorldSoundManager():addSound(nil, heliX, heliY, 0, 175, 300, true, 0, 25)
			eventSoundHandler:playEventSound(self, "crashEvent")
			eventMarkerHandler.setOrUpdate(getRandomUUID(), "media/ui/crash.png", 3500, heliX, heliY, self.markerColor)

			self:unlaunch()

			local globalModData = getExpandedHeliEventsModData()
			globalModData.DayOfLastCrash = math.max(1,getGameTime():getNightsSurvived())
			return true
		end
	end
	return false
end


---Heli spawn crew
function eHelicopter:spawnDeadCrew(x, y, z)
	if not self.crew then return end

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

	for i=1, #self.crew do

		local crewMember = self.crew[i]

		local outfit = crewMember and crewMember.outfit
		if not outfit then
			print("ERROR: not crew-outfit found for: ", self:heliToString() or "UNKNOWN HELI EVENT")
		else

			local chance = crewMember and crewMember.spawn or 100
			local femaleChance = crewMember and crewMember.female or 50

			if (ZombRand(101) <= chance) then

				local fuzzNums = {-5,-4,-3,-3,3,3,4,5}
				if x and y then
					x = x+fuzzNums[ZombRand(#fuzzNums)+1]
					y = y+fuzzNums[ZombRand(#fuzzNums)+1]
				end

				sendClientCommand("SpawnerAPI", "spawn", {
					funcType="zombie", spawnThis=outfit, x=x, y=y, z=0,
					extraFunctions=onSpawnCrewEvents, extraParam=femaleChance, processSquare="getOutsideSquareFromAbove" })

			end
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
		returned_sq = getOutsideSquareFromAbove(square)
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
			extraFunctions=extraFunctions, processSquare="getOutsideSquareFromAbove" })

		--[[DEBUG]] print("EHE: "..carePackage.." dropped: "..heliX..", "..heliY)
		eventSoundHandler:playEventSound(self, "droppingPackage")
		addSound(nil, heliX, heliY, 0, 200, 150)
		eventMarkerHandler.setOrUpdate(getRandomUUID(), "media/ui/airdrop.png", 4000, heliX, heliY, self.markerColor)
		self.dropPackages = false
		return true
	end
end


function eHelicopter:calcDebrisTrail(list, funcType, extraData, fuzz)
	local baseX, baseY, baseZ = self:getXYZAsInt()
	if not baseX or not baseY then return end

	local angle = ZombRandFloat(0, math.pi * 2)
	local dx = math.cos(angle)
	local dy = math.sin(angle)

	fuzz = fuzz or 3

	for key,partType in pairs(list) do
		if type(partType) == "string" then

			local item = partType

			local iterations = list[key+1]
			if type(iterations) ~= "number" then iterations = 1 end

			for i = 1, iterations do
				local step = i + ZombRand(fuzz, fuzz*3)
				local offsetX = math.floor(dx * step + ZombRand(-1, 2))
				local offsetY = math.floor(dy * step + ZombRand(-1, 2))

				sendClientCommand("SpawnerAPI", "spawn", {
					funcType = funcType,
					spawnThis = item,
					x = baseX + offsetX,
					y = baseY + offsetY,
					z = 0,
					extraFunctions = extraData and extraData.extraFunctions,
					processSquare = extraData and extraData.processSquare
				})
			end
		end
	end
end


---Heli drop scrap
function eHelicopter:dropScrap(fuzz)
	if self.scrapItems then
		self:calcDebrisTrail(self.scrapItems, "item",
				{
					extraFunctions = {"ageInventoryItem"},
					processSquare = "getOutsideSquareFromAbove",
				}, fuzz)
		self.scrapItems = false
	end

	if self.scrapVehicles then
		self:calcDebrisTrail(self.scrapVehicles, "vehicle",
				{
					processSquare = "getOutsideSquareFromAbove",
				}, fuzz)
		self.scrapVehicles = false
	end
end