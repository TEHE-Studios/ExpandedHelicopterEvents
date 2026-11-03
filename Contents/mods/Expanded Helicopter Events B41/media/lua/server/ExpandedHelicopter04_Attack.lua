require "ExpandedHelicopter00b_IsoRangeScan"

local eventSoundHandler = require "ExpandedHelicopter01b_Sounds"

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


---@param targetType string IsoZombie or IsoPlayer
function eHelicopter:lookForHostiles(targetType)

	local selfSquare = self:getIsoGridSquare()
	if not selfSquare then return end

	local timeStamp = getTimeInMillis()
	--too soon to attack again OR will overlap with an announcement
	if (self.lastAttackTime+self.attackDelay >= timeStamp) then return end

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
		self.lastScanTime = timeStamp+(self.attackDelay*2)
		--keep an eye out for new targets
		local scanningForTargets = self:attackScan(selfSquare, targetType)
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

		if self.attackSplash > 0 then
			for k,otherHostile in pairs(self.hostilesToFireOn) do
				if otherHostile then
					local dist = IsoUtils.DistanceTo(hX, hY, otherHostile:getX(), otherHostile:getY())
					if dist <= self.attackSplash then
						local randDelay = ZombRand(1,4)
						self:fireOn(otherHostile, randDelay)
						self.hostilesToFireOn[k] = nil
					end
				end
			end

			compressTableOfNils(self.hostilesToFireOn)
		end

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

	local timesFiredOnSpecificHostile = 0
	table.insert(self.hostilesAlreadyFiredOn, targetHostile)
	for _,v in pairs(self.hostilesAlreadyFiredOn) do
		if v == targetHostile then
			timesFiredOnSpecificHostile = timesFiredOnSpecificHostile+1
		end
	end

	if not soundDelay then
		--fireSound
		local eventSound = "attackSingle"
		if self.hostilesToFireOnIndex > 1 then
			eventSound = "attackLooped"
		end
		--determine location of helicopter
		eventSoundHandler:playEventSound(self, eventSound, nil, nil, nil, soundDelay)
		eventSoundHandler:playEventSound(self, "attackingSound", nil, nil, nil, soundDelay)
	end

	local ehX, ehY, _ = self:getXYZAsInt()
	--virtual sound event to attract zombies
	getWorldSoundManager():addSound(nil, ehX, ehY, 0, 75, 30, true, 15, 10)

	local chance = self.attackHitChance
	local damage = (ZombRand(10,16) * self.attackDamage)/10

	---@type BaseVehicle
	local targetVehicle
	local hostileVelocity = 0

	if instanceof(targetHostile, "IsoGameCharacter") then
		--IsoGameCharacter:getMoveSpeed() doesn't seem to work on IsoPlayers (works on IsoZombie)
		local getxsublx = math.abs(targetHostile:getX()-targetHostile:getLx())
		local getysubly = math.abs(targetHostile:getY()-targetHostile:getLy())
		--floors float to 1000ths place decimal
		hostileVelocity = math.floor(math.sqrt((getxsublx * getxsublx + getysubly * getysubly)) * 1000) / 1000

	elseif instanceof(targetHostile, "BaseVehicles") then
		targetVehicle = targetHostile
		hostileVelocity = targetVehicle:getCurrentSpeedKmHour()/10
	end

	--convert hostileVelocity to a %
	local movementThrowOffAim = math.floor((100*hostileVelocity)+0.5)

	if instanceof(targetHostile, "IsoPlayer") then
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
					local vehicle = getVehiclesIntersecting(targetSquare, true)
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
		if self.attackDamage>0 then
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

				local targetType = tostring(targetHostile):match('[^.]+$'):match("(.-)@")
				local targetOnlineID = targetHostile:getOnlineID()
				heliEventAttackHitOnIsoGameCharacter(damage, targetType, targetOnlineID)
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
	eventSoundHandler:playEventSound(self, "attackImpacts", targetHostile:getSquare(), nil, nil, soundDelay)
end


---@param targetType string IsoZombie or IsoPlayer or IsoGameCharacter
---@return table
function eHelicopter:attackScan(location, targetType)

	if not location then
		return {}
	end

	local fractalObjectsFound = getHumanoidsInFractalRange(location, self.attackScope, self.attackSpread, targetType, self.hostilePredicate)
	local objectsToFireOn = {}

	for fractalIndex=1, #fractalObjectsFound do
		local objectsArray = fractalObjectsFound[fractalIndex]

		if (not objectsToFireOn) or (#objectsArray > #objectsToFireOn) then
			objectsToFireOn = objectsArray
		end
	end

	return objectsToFireOn
end
