---@param targetType string IsoZombie or IsoPlayer
function eHelicopter:lookForHostiles(targetType)

	local selfSquare = self:getIsoGridSquare()
	if not selfSquare then
		return
	end

	--store numeration (length) of self.hostilesToFireOn
	local n = #self.hostilesToFireOn

	--clear entries that are too far
	for i=1, n do
		local hostile = self.hostilesToFireOn[i]
		local distanceTo = tonumber(hostile:getSquare():DistTo(selfSquare))
		--if hostile is too far set to nil
		if distanceTo > self.attackDistance then
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

	--keep an eye out for new targets
	local scanningForTargets = self:attackScan(selfSquare, targetType)
	--if no more targets or newly scanned targets are greater size change target
	if (#self.hostilesToFireOn <=0) or (#scanningForTargets > self.hostilesToFireOnIndex) then
		--set targets
		self.hostilesToFireOn = scanningForTargets
		self.hostilesToFireOnIndex = #self.hostilesToFireOn
	end

	local timeStamp = getTimestampMs()
	--too soon to attack again OR will overlap with an announcement THEN return
	if (self.lastAttackTime+self.attackDelay >= timeStamp) or (self.timeUntilCanAnnounce >= timeStamp) then
		return
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


---@param targetHostile IsoObject|IsoMovingObject|IsoGameCharacter|IsoPlayer|IsoZombie
function eHelicopter:fireOn(targetHostile)

	self.lastAttackTime = getTimestampMs()
	self.timeUntilCanAnnounce = getTimestampMs()+self.attackDelay-1

	--fireSound
	local fireNoise = self.fireSound[1]
	local eventSound = "attackSingle"

	if self.hostilesToFireOnIndex > 1 then
		fireNoise = self.fireSound[2]
		eventSound = "attackLooped"
	end

	self:playEventSound(eventSound)

	--determine location of helicopter
	local ehX, ehY, ehZ = self:getXYZAsInt()

	--play sound file
	local gunEmitter = getWorld():getFreeEmitter()
	gunEmitter:playSound(fireNoise, ehX, ehY, ehZ)

	--virtual sound event to attract zombies
	addSound(nil, ehX, ehY, 0, 250, 75)

	local movementThrowOffAim = math.floor((50*targetHostile:getMoveSpeed())+0.5)
	local chance = 100-movementThrowOffAim

	local zone = targetHostile:getCurrentZone()
	if zone then
		local zoneType = zone:getType()
		if zoneType and (zoneType == "Forest") or (zoneType == "DeepForest") then
			chance = math.floor(chance/2)
		end
	end

	--[[debug]] local hitReport = "fireNoise: "..fireNoise.." movementThrowOffAim:"..movementThrowOffAim

	if ZombRand(0, 100) < chance then
		--kill zombie
		targetHostile:setHealth(0)
		--[[debug]] hitReport = hitReport .. "  [HIT]"
	else
		--toss down
		targetHostile:knockDown(true)
	end

	targetHostile:splatBlood(2,200)
	--[[debug]] print(hitReport)
	
	--fireImpacts
	local impactNoise = self.fireImpacts[ZombRand(1,#self.fireImpacts)]
	gunEmitter:playSound(impactNoise, targetHostile:getSquare())


end


---@param targetType string IsoZombie or IsoPlayer or IsoGameCharacter
---@return table
function eHelicopter:attackScan(location, targetType)

	if not location then
		return {}
	end

	local fractalObjectsFound = getHumanoidsInFractalRange(location, self.attackScope, self.attackSpread, targetType)
	local objectsToFireOn = {}

	for fractalIndex=1, #fractalObjectsFound do
		local objectsArray = fractalObjectsFound[fractalIndex]

		if (not objectsToFireOn) or (#objectsArray > #objectsToFireOn) then
			objectsToFireOn = objectsArray
		end
	end

	return objectsToFireOn
end

---@param center IsoGameCharacter
function recursiveGetSquare(center)
	if not center then
		return nil
	end

	if instanceof(center, "IsoGameCharacter") and center:getVehicle() then
		center = center:getVehicle()
	end

	if not instanceof(center, "IsoGridSquare") then
		center = center:getSquare()
	end

	return center
end


---@param center IsoObject|IsoGridSquare
---@param range number tiles to scan from center, not including center. ex: range of 1 = 3x3
---@param lookForType string
function getHumanoidsInRange(center, range, lookForType)

	if center then
		center = recursiveGetSquare(center)
	else
		return {}
	end

	local squaresInRange = getIsoRange(center, range)
	local objectsFound = {}

	for sq=1, #squaresInRange do

		---@type IsoGridSquare
		local square = squaresInRange[sq]
		local squareContents = square:getLuaMovingObjectList()

		for i=1, #squareContents do
			---@type IsoMovingObject|IsoGameCharacter foundObject
			local foundObj = squareContents[i]

			if instanceof(foundObj, lookForType) and instanceof(foundObj, "IsoGameCharacter") then
				if foundObj:isOutside() then
					table.insert(objectsFound, foundObj)
				end
			end
		end
	end

	return objectsFound
end


---@param center
---@param range number tiles to scan from center, not including center. ex: range of 1 = 3x3
---@param fractalRange number number of rows, made up of `range`, from the center range
---@param lookForType string
function getHumanoidsInFractalRange(center, range, fractalRange, lookForType)

	if center then
		center = recursiveGetSquare(center)
	else
		return {}
	end

	--range and fractalRange are flipped in the parameters here because:
	-- "fractalRange" represents the number of rows from center out but with an offset of "range" instead
	local fractalCenters = getIsoRange(center, fractalRange, range)
	local fractalObjectsFound = {}
	---print("getHumanoidsInFractalRange: centers found: "..#fractalCenters)
	--pass through each "center square" found
	for i=1, #fractalCenters do
		local objectsFound = getHumanoidsInRange(fractalCenters[i], range, lookForType)
		---print(" fractal center "..i..":  "..#objectsFound)
		--store a list of objectsFound within the fractalObjectsFound list
		table.insert(fractalObjectsFound, objectsFound)
	end

	return fractalObjectsFound
end


---@param center IsoObject | IsoGridSquare
---@param range number tiles to scan from center, not including center. ex: range of 1 = 3x3
---@param fractalOffset number fractal offset - spreads out squares by this number
---@return table of IsoGridSquare
function getIsoRange(center, range, fractalOffset)

	if center then
		center = recursiveGetSquare(center)
	else
		return {}
	end

	if not fractalOffset then
		fractalOffset = 1
	else
		fractalOffset = (fractalOffset*2)+1
	end

	local centerCell = center:getCell()
	--true center
	local centerX, centerY = center:getX(), center:getY()
	--add center to squares at the start
	local squares = {center}

	--no point in running everything below, return squares
	if range < 1 then return squares end

	--create a ring of IsoGridSquare around center, i=1 skips center
	for i=1, range do

		local fractalFactor = i*fractalOffset
		--currentX and currentY have to pushed off center for the logic below to kick in
		local currentX, currentY = centerX+fractalFactor, centerY+fractalFactor
		-- ring refers to the path going around center, -1 to skip center
		local expectedRingLength = (8*i)-1

		for _=0, expectedRingLength do
			--if on top-row and not at the upper-right
			if (currentY == centerY+fractalFactor) and (currentX < centerX+fractalFactor) then
				--move-right
				currentX = currentX+fractalFactor
				--if on right-column and not the bottom-right
			elseif (currentX == centerX+fractalFactor) and (currentY > centerY-fractalFactor) then
				--move down
				currentY = currentY-fractalFactor
				--if on bottom-row and not on far-left
			elseif (currentY == centerY-fractalFactor) and (currentX > centerX-fractalFactor) then
				--move left
				currentX = currentX-fractalFactor
				--if on left-column and not on top-left
			elseif (currentX == centerX-fractalFactor) and (currentY < centerY+fractalFactor) then
				--move up
				currentY = currentY+fractalFactor
			end

			---@type IsoGridSquare square
			local square = centerCell:getOrCreateGridSquare(currentX, currentY, 0)
			table.insert(squares, square)
		end
	end
	--[[
	---DEBUG
	print("---[ IsoRange ]---")
	print(" total "..#squares.."/"..((range*2)+1)^2)
	for k,v in pairs(squares) do
		---@type IsoGridSquare vSquare
		local vSquare = v
		print(" "..k..": "..centerX-vSquare:getX()..", "..centerY-vSquare:getY())
	end
	]]
	return squares
end