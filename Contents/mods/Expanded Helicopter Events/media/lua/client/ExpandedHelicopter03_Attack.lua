--TODO:
-- gather range of squares
-- gather list of zombies OR players in squares
-- create a fractalIsoRange (ex: 3x3 of 3x3 (81 squares))
-- -- kill zombies with in the most populated square?
--- --- delay in-between shots
--- --- target movement creates chance for a miss
--- look into creating dust-ups from bullet impacts


---@param targetType string IsoZombie or IsoPlayer
---@return table
function eHelicopter:attackScan(targetType, location)

	if not location then
		return {}
	end

	local fractalObjectsFound = getHumanoidsInFractalRange(location, 1, targetType)
	local objectsToFireOn = {}

	for fractalIndex=1, #fractalObjectsFound do
		local objectsArray = fractalObjectsFound[fractalIndex]

		if (not objectsToFireOn) or (#objectsArray > #objectsToFireOn) then
			objectsToFireOn = objectsArray
		end
	end

	return objectsToFireOn
end


---@param targetHostile IsoObject|IsoMovingObject|IsoGameCharacter
function eHelicopter:fireOn(targetHostile)

	--fireSound
	local fireNoise = self.fireSound[1]
	--determine location of helicopter

	local ehX, ehY, ehZ = self:getIsoCoords()

	--play sound file
	local gunEmitter = getWorld():getFreeEmitter()
	gunEmitter:playSound(fireNoise, ehX, ehY, ehZ)

	--virtual sound event to attract zombies
	--addSound(nil, ehX, ehY, 0, 250, 75)

	--set damage to kill
	print("hostile: ".. targetHostile:getClass():getSimpleName().." 100*movementspeed:".. 100*targetHostile:getMoveSpeed())

	if ZombRand(0, 100) < 100-(targetHostile:getMoveSpeed()*100) then
		targetHostile:setHealth(0)
	end

	--fireImpacts
	local impactNoise = self.fireImpacts[ZombRand(1,#self.fireImpacts)]
	gunEmitter:playSound(impactNoise, targetHostile:getSquare())
	targetHostile:splatBlood(2,50)

end


---@param center IsoGridSquare|IsoGameCharacter
---@param range number tiles to scan from center, not including center. ex: range of 1 = 3x3
---@param lookForType table strings, compared to getClass():getSimpleName()
function getHumanoidsInFractalRange(center, range, lookForType)

	--FractalRange = 3*3 made up of (9) range*range
	--example: range of 1, e is center
	--[a][b][c]  --[a] = [-1, 1][0, 1][1, 1]
	--[d][e][f]          [-1, 0][0, 0][1, 0]
	--[g][h][i]          [-1,-1][0,-1][1,-1]

	if not center then
		return {}
	elseif center:getClass():getSimpleName() ~= "IsoGridSquare" then
		center = center:getSquare()
	end

	--get distance from 1 center to the next using range*2 + 1 for the other center
	local fractalFactor = (range*2)+1
	--list of center's
	local cX, cY = center:getX(), center:getY()

	local fractalIsoRangeIndex = {
		--a's center
		getSquare(cX-fractalFactor,cY+fractalFactor,0),
		--b's center
		getSquare(cX,cY+fractalFactor,0),
		--c's center
		getSquare(cX+fractalFactor,cY+fractalFactor,0),
		--d's center
		getSquare(cX-fractalFactor,cY,0),
		--e's center, true center
		center,
		--f's center
		getSquare(cX+fractalFactor,cY,0),
		--g's center
		getSquare(cX-fractalFactor,cY-fractalFactor,0),
		--h's center
		getSquare(cX,cY-fractalFactor,0),
		--i's center
		getSquare(cX+fractalFactor,cY-fractalFactor,0),
	}

	local fractalObjectsFound = {}

	for fractalIndex=1, #fractalIsoRangeIndex do
		local objectsFound = getHumanoidsInRange(fractalIsoRangeIndex[fractalIndex], range, lookForType)
		table.insert(fractalObjectsFound, objectsFound)
	end

	return fractalObjectsFound
end


---@param center IsoObject
---@param range number tiles to scan from center, not including center. ex: range of 1 = 3x3
---@param lookForType table strings, compared to getClass():getSimpleName()
function getHumanoidsInRange(center, range, lookForType)

	if not center then
		return {}
	elseif center:getClass():getSimpleName() ~= "IsoGridSquare" then
		center = center:getSquare()
	end

	if (lookForType~="IsoZombie") and (lookForType~="IsoPlayer") then
		lookForType = nil
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
			local foName = foundObj:getClass():getSimpleName()

			if (not lookForType and ((foName=="IsoZombie") or (foName=="IsoPlayer"))) or (lookForType==foName) then
				if foundObj:isOutside() then
					table.insert(objectsFound, foundObj)
				end
			end
		end
	end

	return objectsFound
end


---@param center IsoObject | IsoGridSquare
---@param range number tiles to scan from center, not including center. ex: range of 1 = 3x3
---@return table of IsoGridSquare
function getIsoRange(center, range)

	--if center is not an IsoGridSquare then call center's getSquare

	if center:getClass():getSimpleName() ~= "IsoGridSquare" then
		center = center:getSquare()
	end

	local centerX, centerY = center:getX(), center:getY()
	--add center to squares at the start
	local squares = {center}

	--no point in running everything below, return squares
	if range < 1 then return squares end

	--create a ring of IsoGridSquare around center, i=1 skips center
	for i=1, range do

		--currentX and currentY have to pushed off center for the logic below to kick in
		local currentX, currentY = centerX+i, centerY+i
		-- ring refers to the path going around center, -1 to skip center
		local expectedRingLength = (8*i)-1

		for _=0, expectedRingLength do
			--if on top-row and not at the upper-right
			if (currentY == centerY+i) and (currentX < centerX+i) then
				--move-right
				currentX = currentX+1
				--if on right-column and not the bottom-right
			elseif (currentX == centerX+i) and (currentY > centerY-i) then
				--move down
				currentY = currentY-1
				--if on bottom-row and not on far-left
			elseif (currentY == centerY-i) and (currentX > centerX-i) then
				--move left
				currentX = currentX-1
				--if on left-column and not on top-left
			elseif (currentX == centerX-i) and (currentY < centerY+i) then
				--move up
				currentY = currentY+1
			end

			---@type IsoGridSquare square
			local square = getSquare(currentX, currentY, 0)
			table.insert(squares, square)
		end
	end

	--[[---DEBUG
	print("IsoRange: total "..#squares.."/"..((range*2)+1)^2)
	for k,v in pairs(squares) do
		---@type IsoGridSquare vSquare
		local vSquare = v
		print(k..": "..centerX-vSquare:getX()..", "..centerY-vSquare:getY())
	end
	--]]

	return squares
end