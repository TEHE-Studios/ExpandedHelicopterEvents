require "ExpandedHelicopter00b_IsoRangeScan"
local eventSoundHandler = require "ExpandedHelicopter01b_Sounds"

---@param targetType string IsoZombie or IsoPlayer
function eHelicopter:lookForHostiles(targetType)

	local selfSquare = self:getIsoGridSquare()
	if not selfSquare then
		return
	end

	local timeStamp = getTimeInMillis()
	--too soon to attack again OR will overlap with an announcement
	if (self.lastAttackTime+self.attackDelay >= timeStamp) then
		return
	end

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
	--prepare new index for self.hostilesToFireOn
	local newIndex = 0
	--iterate through and overwrite nil entries
	for i=1, n do
		if self.hostilesToFireOn[i]~=nil then
			newIndex = newIndex+1
			self.hostilesToFireOn[newIndex]=self.hostilesToFireOn[i]
		end
	end
	--cut off end of list based on newIndex
	for i=newIndex+1, n do
		self.hostilesToFireOn[i]=nil
	end

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
		--remove target
		table.remove(self.hostilesToFireOn,1)
	end
end


--for targeting
local bodyPartSelectionWeight = {
	["Hand_L"]=5,["Hand_R"]=5,["ForeArm_L"]=10,["ForeArm_R"]=10,
	["UpperArm_L"]=15,["UpperArm_R"]=15,["Torso_Upper"]=15,["Torso_Lower"]=15,
	["Head"]=1,["Neck"]=1,["Groin"]=2,["UpperLeg_L"]=15,["UpperLeg_R"]=15,
	["LowerLeg_L"]=10,["LowerLeg_R"]=10,["Foot_L"]=5,["Foot_R"]=5
}
local bodyPartSelection = {}
for type,weight in pairs(bodyPartSelectionWeight) do
	for i=1, weight do
		--print("body parts: "..i.." - "..type)
		table.insert(bodyPartSelection,type)
	end
end

local vehicleParts

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
function eHelicopter:fireOn(targetHostile)

	self.lastAttackTime = getTimeInMillis()

	local timesFiredOnSpecificHostile = 0
	table.insert(self.hostilesAlreadyFiredOn, targetHostile)
	for _,v in pairs(self.hostilesAlreadyFiredOn) do
		if v == targetHostile then
			timesFiredOnSpecificHostile = timesFiredOnSpecificHostile+1
		end
	end

	--fireSound
	local eventSound = "attackSingle"
	if self.hostilesToFireOnIndex > 1 then
		eventSound = "attackLooped"
	end
	--determine location of helicopter
	eventSoundHandler:playEventSound(self, eventSound)
	eventSoundHandler:playEventSound(self, "attackingSound")

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

	if (targetSquare:getTree()) then
		chance = (chance*0.8)
	end

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

		if (targetSquare:isVehicleIntersecting()) then
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

	--[[DEBUG] local hitReport = "-hit_report: "..self:heliToString(false)..timesFiredOnSpecificHostile..
			"  eMS:"..hostileVelocity.." %:"..chance.." "..tostring(targetHostile:getClass()) --]]

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
				if (targetSquare:isVehicleIntersecting()) then
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
					if not vehicleParts then
						vehicleParts = {}
						for partName,_ in pairs(ISCarMechanicsOverlay.PartList) do
							table.insert(vehicleParts, partName)
						end
					end
					for _,partName in pairs(vehicleParts) do
						table.insert(targetZones, partName)
					end
				else
					for i=0, 6 do
						table.insert(targetZones, "tires")
					end
				end

				local selectedZone = targetZones[ZombRand(#targetZones)+1]

				if selectedZone == "tires" then
					local tires = {"TireRearLeft","TireRearRight","TireFrontRight","TireFrontLeft"}
					---@type VehiclePart
					local tire = returnValidPartById(targetHostile,tires[ZombRand(#tires)+1])
					if tire then
						tire:damage(damage)
					end

				else
					local partDamage = damage
					local part = returnValidPartById(targetHostile,selectedZone)

					if part then

						local partWindow = part:getWindow()
						if partWindow then
							partWindow:damage(partDamage*10)
						end

						part:damage(partDamage)
					end
				end
			end

			if instanceof(targetHostile, "IsoGameCharacter") then

				if targetVehicle then
					local seatID = targetVehicle:getSeat(targetHostile)
					local door = targetVehicle:getPassengerDoor(seatID)
					if door then
						door:damage(damage)
						damage = damage*0.8
					end
					local window = door:getWindow()
					if window then
						window:damage(damage*10)
					end
				end

				local bpRandSelect = bodyPartSelection[ZombRand(#bodyPartSelection)+1]
				local bpType = BodyPartType.FromString(bpRandSelect)
				local clothingBP = BloodBodyPartType.FromString(bpRandSelect)

				--[[DEBUG]] local preHealth = targetHostile:getHealth()
				--apply damage to body part

				if (bpType == BodyPartType.Neck) or (bpType == BodyPartType.Head) then
					damage = damage*4
				elseif (bpType == BodyPartType.Torso_Upper) then
					damage = damage*2
				end

				if instanceof(targetHostile, "IsoZombie") then
					--Zombies receive damage directly because they don't have body parts or clothing protection
					damage = damage*3
					targetHostile:knockDown(true)

				elseif instanceof(targetHostile, "IsoPlayer") then
					--Messy process just to knock down the player effectively
					targetHostile:clearVariable("BumpFallType")
					targetHostile:setBumpType("stagger")
					targetHostile:setBumpDone(false)
					targetHostile:setBumpFall(ZombRand(0, 101) <= 25)
					local bumpFallType = {"pushedBehind","pushedFront"}
					bumpFallType = bumpFallType[ZombRand(1,3)]
					targetHostile:setBumpFallType(bumpFallType)

					--apply localized body part damage
					local bodyDMG = targetHostile:getBodyDamage()
					if bodyDMG then
						local bodyPart = bodyDMG:getBodyPart(bpType)
						if bodyPart then
							local protection = targetHostile:getBodyPartClothingDefense(BodyPartType.ToIndex(bpType), false, true)/100
							damage = damage * (1-(protection*0.75))
							--print("  EHE:[hit-dampened]: new damage:"..damage.." protection:"..protection)

							bodyDMG:AddDamage(bpType,damage)
							bodyPart:damageFromFirearm(damage)
						end
					end
				end

				targetHostile:addHole(clothingBP)
				targetHostile:addBlood(clothingBP, true, true, true)
				targetHostile:setHealth(targetHostile:getHealth()-(damage/100))

				--splatter a few times
				local splatIterations = ZombRand(1,3)
				for _=1, splatIterations do
					targetHostile:splatBloodFloor()
				end
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
	eventSoundHandler:playEventSound(self, "attackImpacts", targetHostile:getSquare())
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
