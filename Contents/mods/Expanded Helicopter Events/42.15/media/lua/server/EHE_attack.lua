local eHelicopter = require("EHE_heliVariables.lua")
local isoRangeScan = require("EHE_IsoRangeScan.lua")
local eventSoundHandler = require("EHE_sounds.lua")
local util = require("EHE_util.lua")
local weaponStats = require("EHE_weaponStats.lua")

local function compressTableOfNils(table)
	local n = #table
	--prepare new index for self.hostilesToFireOn
	local newIndex = 0
	--iterate through and overwrite nil entries
	for i=1, n do
		if table[i]~=nil then
			newIndex = newIndex+1
			table[newIndex]=table[i]
		end
	end

	--overwrite rest of entries to nil based on newIndex
	for i=newIndex+1, n do table[i]=nil end
end


---@param targetType string|table IsoZombie, IsoPlayer, IsoAnimal, or an array of any combination of these
function eHelicopter:lookForHostiles(targetType)

	local selfSquare = self:getIsoGridSquare()
	if not selfSquare then return end

	if not self.currentWeapon then self.currentWeapon = weaponStats.pick(self.weaponArray, self.weaponCooldowns) end
	local weapon = self.currentWeapon

	local timeStamp = getTimeInMillis()
	--too soon to attack again OR will overlap with an announcement
	if (self.lastAttackTime+weapon.delay >= timeStamp) or (self.reloadingUntil > timeStamp) then return end

	--store numeration (length) of self.hostilesToFireOn
	local n = #self.hostilesToFireOn

	--clear entries that are too far
	for i=1, n do
		local hostile, hSq, distanceTo
		hostile = self.hostilesToFireOn[i]
		if hostile then hSq = hostile:getSquare() end
		if hSq then distanceTo = tonumber(hSq:DistTo(selfSquare)) end
		--if hostile is too far set to nil
		if (not hSq) or (not distanceTo) or (distanceTo and distanceTo > self.attackDistance) then
			self.hostilesToFireOn[i] = nil
		end
	end

	compressTableOfNils(self.hostilesToFireOn)

	if self.lastScanTime <= timeStamp then
		self.lastScanTime = timeStamp+(weapon.delay*2)
		--keep an eye out for new targets
		local scanningForTargets = self:attackScan(selfSquare, targetType, weapon)
		--if no more targets or newly scanned targets are greater size change target
		if (#self.hostilesToFireOn <=0) or (#scanningForTargets > self.hostilesToFireOnIndex) then
			--set targets
			self.hostilesToFireOn = scanningForTargets
			self.hostilesToFireOnIndex = #self.hostilesToFireOn
		end
	end

	--if there are hostiles identified
	if #self.hostilesToFireOn > 0 then

		--just grab the first target
		---@type IsoObject|IsoMovingObject|IsoGameCharacter hostile
		local hostile = self.hostilesToFireOn[1]
		self:fireOn(hostile)

		local hX, hY = hostile:getX(), hostile:getY()
		--remove target
		self.hostilesToFireOn[1] = nil

		if (weapon.splash > 0) and (not weapon.explosive) then
			for k,otherHostile in pairs(self.hostilesToFireOn) do
				if otherHostile and (self.reloadingUntil <= getTimeInMillis()) then
					local dist = IsoUtils.DistanceTo(hX, hY, otherHostile:getX(), otherHostile:getY())
					if dist <= weapon.splash then
						local randDelay = ZombRand(1,4)
						self:fireOn(otherHostile, randDelay)
						self.hostilesToFireOn[k] = nil
					end
				end
			end

			compressTableOfNils(self.hostilesToFireOn)
		end

		self.currentWeapon = false
	end
end



local vehicleParts = {
	"Battery", "BrakeFrontLeft", "BrakeFrontRight", "BrakeRearLeft", "BrakeRearRight",
	"DoorFrontLeft", "DoorFrontRight", "DoorRearLeft", "DoorRearRight",
	"Engine", "GasTank", "HeadlightLeft", "HeadlightRight", "EngineDoor", "Muffler",
	"SuspensionFrontLeft","SuspensionFrontRight","SuspensionRearLeft","SuspensionRearRight",
	"TireFrontLeft","TireFrontRight","TireRearLeft","TireRearRight",
	"WindowFrontLeft","WindowFrontRight","WindowRearLeft","WindowRearRight",
	"WindshieldRear","Windshield","TruckBed"
	}

---@param vehicle BaseVehicle
---@param partById string
local function returnValidPartById(vehicle, partById)
	if not vehicle or not partById then return end
	---@type VehiclePart
	local part = vehicle:getPartById(partById)
	if part and part:getInventoryItem() then
		return part
	end
end

---@param targetHostile IsoObject|IsoMovingObject|IsoGameCharacter|IsoPlayer|IsoZombie
function eHelicopter:fireOn(targetHostile, soundDelay)

	self.lastAttackTime = getTimeInMillis()

	local weapon = self.currentWeapon or weaponStats.pick(self.weaponArray, self.weaponCooldowns)
	self:useRound(weapon)
	if weapon.explosive then
		self:fireExplosive(weapon, targetHostile:getSquare())
		return
	end

	local timesFiredOnSpecificHostile = 0
	table.insert(self.hostilesAlreadyFiredOn, targetHostile)
	for _,v in pairs(self.hostilesAlreadyFiredOn) do
		if v == targetHostile then
			timesFiredOnSpecificHostile = timesFiredOnSpecificHostile+1
		end
	end

	if not soundDelay then
		--fireSound
		local eventSound = weapon.fireSound
		if self.hostilesToFireOnIndex > 1 then
			eventSound = weapon.loopedSound
		end
		--determine location of helicopter
		eventSoundHandler:playEventSound(self, eventSound, nil, nil, nil, soundDelay)
		eventSoundHandler:playEventSound(self, "attackingSound", nil, nil, nil, soundDelay)
	end

	local ehX, ehY, _ = self:getXYZAsInt()
	--virtual sound event to attract zombies
	getWorldSoundManager():addSound(nil, ehX, ehY, 0, weapon.soundRadius, 30, true, 15, 10)

	local chance = weapon.hitChance
	local damage = (weapon.minDamage+((ZombRand(0,101)/100)*(weapon.maxDamage-weapon.minDamage)))*weapon.projectileCount*weaponStats.damageScale

	---@type BaseVehicle
	local targetVehicle
	local hostileVelocity = 0

	if instanceof(targetHostile, "IsoGameCharacter") then
		--IsoGameCharacter:getMoveSpeed() doesn't seem to work on IsoPlayers (works on IsoZombie)
		local getxsublx = math.abs(targetHostile:getX()-targetHostile:getLastX())
		local getysubly = math.abs(targetHostile:getY()-targetHostile:getLastY())
		--floors float to 1000ths place decimal
		hostileVelocity = math.floor(math.sqrt((getxsublx * getxsublx + getysubly * getysubly)) * 1000) / 1000

	elseif instanceof(targetHostile, "BaseVehicles") then
		targetVehicle = targetHostile
		hostileVelocity = targetVehicle:getCurrentSpeedKmHour()/10
	end

	--convert hostileVelocity to a %
	local movementThrowOffAim = math.floor((100*hostileVelocity)+0.5)

	if instanceof(targetHostile, "IsoAnimal") then
		movementThrowOffAim = movementThrowOffAim/1.25
		chance = (chance/(timesFiredOnSpecificHostile/1.5))
	elseif instanceof(targetHostile, "IsoPlayer") then
		movementThrowOffAim = movementThrowOffAim*1.5
		chance = (chance/(timesFiredOnSpecificHostile*2))
	elseif instanceof(targetHostile, "IsoZombie") then
		--allow firing on zombies more for shock value
		movementThrowOffAim = movementThrowOffAim/1.5
		chance = (chance/(timesFiredOnSpecificHostile/2))
	end
	chance = chance-movementThrowOffAim


	local targetSquare = targetHostile:getSquare()

	if targetSquare and (targetSquare:getTree()) then chance = (chance*0.8) end

	if instanceof(targetHostile, "IsoGameCharacter") then
		if instanceof(targetHostile, "IsoPlayer") then
			if targetHostile:isNearVehicle() then
				chance = (chance*0.8)
			end
		end
		if (targetHostile:checkIsNearWall()>0) then
			chance = (chance*0.8)
		end

		targetVehicle = targetHostile:getVehicle()
		if targetVehicle then
			chance = (chance*0.6)
			damage = (damage*0.95)
		end

		if (targetSquare and targetSquare:isVehicleIntersecting()) then
			chance = (chance*0.8)
		end
	end


	local zone = targetHostile:getCurrentZone()
	if zone then
		local zoneType = zone:getType()
		if zoneType and (zoneType == "Forest") or (zoneType == "DeepForest") then
			chance = (chance/2)
		end
	end

	--floor things off to a whole number
	chance = math.floor(chance)

	--[DEBUG]] local hitReport = "-hit_report: "..self:heliToString(false)..timesFiredOnSpecificHostile.."  eMS:"..hostileVelocity.." %:"..chance.." "..tostring(targetHostile:getClass()) --]]

	local HIT = false
	local collateral = false
	if ZombRand(0, 101) <= chance then
		HIT = true
	else
		--collateral damage to vehicles
		if (not instanceof(targetHostile, "BaseVehicles")) then
			if targetVehicle then
				HIT = true
				collateral = true
				targetHostile = targetVehicle
			else
				if targetSquare and (targetSquare:isVehicleIntersecting()) then
					local vehicle = isoRangeScan.getVehiclesIntersecting(targetSquare, true)
					if vehicle then
						HIT = true
						collateral = true
						targetHostile = vehicle
					end
				end
			end
		end
	end

	if HIT then
		if weapon.maxDamage>0 then
			if instanceof(targetHostile, "BaseVehicle") then
				local targetZones = {"tires","tires","tires","tires","GasTank","Engine","random"}

				if collateral then
					for _,partName in pairs(vehicleParts) do table.insert(targetZones, partName) end
				else
					for i=0, 6 do table.insert(targetZones, "tires") end
				end

				local selectedZone = targetZones[ZombRand(#targetZones)+1]

				if selectedZone == "tires" then
					local tires = {"TireRearLeft","TireRearRight","TireFrontRight","TireFrontLeft"}
					---@type VehiclePart
					local tire = returnValidPartById(targetHostile,tires[ZombRand(#tires)+1])
					if tire then
						tire:damage(damage)
						targetHostile:transmitPartCondition(tire)
					end

				else
					local partDamage = damage
					local part = returnValidPartById(targetHostile,selectedZone)

					if part then

						local partWindow = part:getChildWindow()
						if partWindow then
							partWindow:damage(partDamage*10)
							targetHostile:transmitPartCondition(partWindow)
						end

						part:damage(partDamage)
						targetHostile:transmitPartCondition(part)
					end
				end
			end

			if instanceof(targetHostile, "IsoGameCharacter") then

				if targetVehicle then
					local seatID = targetVehicle:getSeat(targetHostile)
					local door = targetVehicle:getPassengerDoor(seatID)
					if door then
						door:damage(damage)
						targetVehicle:transmitPartCondition(door)
						damage = damage*0.8
					end
					local window = door:getWindow()
					if window then
						window:damage(damage*10)
						targetVehicle:transmitPartCondition(window)
					end
				end

				local targetType = tostring(targetHostile):match("^(.-)%{")
				local targetOnlineID = targetHostile:getOnlineID()
				heliEventAttackHitOnIsoGameCharacter(damage, targetType, targetOnlineID, targetHostile)
				--[DEBUG]] hitReport = hitReport .. "  [HIT] dmg:"..(damage/100).." hp:"..preHealth.." > "..targetHostile:getHealth()
			end
		end

		if self.addedFunctionsToEvents then
			local eventFunction = self.addedFunctionsToEvents["OnAttackHit"]
			if eventFunction then
				eventFunction(self, targetHostile)
			end
		end
	end
	--[DEBUG]] print(hitReport)

	if self.addedFunctionsToEvents then
		local eventFunction = self.addedFunctionsToEvents["OnAttack"]
		if eventFunction then
			eventFunction(self, targetHostile)
		end
	end

	--fireImpacts
	eventSoundHandler:playEventSound(self, weapon.impactSound, targetHostile:getSquare(), nil, nil, soundDelay)
end


---@param weapon table resolved weaponStats
function eHelicopter:useRound(weapon)
	if weapon.magazine <= 0 then return end
	local rounds = (self.weaponRounds[weapon.ID] or weapon.magazine)-1
	if rounds <= 0 then
		rounds = weapon.magazine
		self.reloadingUntil = getTimeInMillis()+weapon.reloadDelay
		if weapon.reloadSound then eventSoundHandler:playEventSound(self, weapon.reloadSound) end
	end
	self.weaponRounds[weapon.ID] = rounds
end


---@param weapon table resolved weaponStats
---@param targetSquare IsoGridSquare
function eHelicopter:fireExplosive(weapon, targetSquare)
	if not targetSquare then return end

	local x = targetSquare:getX()+ZombRand(-weapon.scatter, weapon.scatter+1)
	local y = targetSquare:getY()+ZombRand(-weapon.scatter, weapon.scatter+1)
	local z = targetSquare:getZ()
	local impactSquare = getSquare(x, y, z) or targetSquare
	local blastRadius = weapon.blastRadius

	eventSoundHandler:playEventSound(self, weapon.fireSound)
	eventSoundHandler:playEventSound(self, weapon.impactSound, impactSquare)
	getWorldSoundManager():addSound(nil, x, y, z, weapon.soundRadius, 100, true, 15, 10)

	if weapon.firePower > 0 then IsoFireManager.explode(getCell(), impactSquare, weapon.firePower) end

	local squares = isoRangeScan.getIsoRange(impactSquare, 1)
	for k,sq in pairs(squares) do
		local window = sq:getWindow()
		if window and (not window:isSmashed()) then window:smashWindow() end
		if sq == impactSquare or ZombRand(100) < 40 then util.applyCrashGround(sq) end
	end

	local maxDamage = weapon.maxDamage*weapon.projectileCount*weaponStats.damageScale
	local hostiles = isoRangeScan.getHumanoidsInRange(impactSquare, blastRadius, "IsoGameCharacter")
	for i=1, #hostiles do
		local hostile = hostiles[i]
		local falloff = 1-(impactSquare:DistTo(hostile)/(blastRadius+1))
		if falloff > 0 then
			local damage = (maxDamage*falloff*ZombRand(8,13))/10
			local targetType = tostring(hostile):match("^(.-)%{")
			heliEventAttackHitOnIsoGameCharacter(damage, targetType, hostile:getOnlineID(), hostile)
		end
	end

	local vehicles = isoRangeScan.getVehiclesInRange(impactSquare, blastRadius+1)
	for i=1, #vehicles do
		local vehicle = vehicles[i]
		for p=1, 3 do
			local part = returnValidPartById(vehicle, vehicleParts[ZombRand(#vehicleParts)+1])
			if part then
				part:damage(maxDamage/3)
				vehicle:transmitPartCondition(part)
			end
		end
	end
end


---@param targetType string|table IsoZombie, IsoPlayer, IsoAnimal, IsoGameCharacter, or an array of any combination
---@return table
function eHelicopter:attackScan(location, targetType, weapon)

	if not location then
		return {}
	end

	weapon = weapon or self.currentWeapon or weaponStats.get("EHE_Default")
	local fractalObjectsFound = isoRangeScan.getHumanoidsInFractalRange(location, weapon.scope, weapon.spread, targetType, self.hostilePredicate)
	local objectsToFireOn = {}

	for fractalIndex=1, #fractalObjectsFound do
		local objectsArray = fractalObjectsFound[fractalIndex]

		if (not objectsToFireOn) or (#objectsArray > #objectsToFireOn) then
			objectsToFireOn = objectsArray
		end
	end

	return objectsToFireOn
end
