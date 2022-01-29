---This is an utility function meant for large scale scans of isoGridSquares around a given IsoObject.
---The scans are done fractally - that is to say from a center (or centers) outward to fill a larger area.

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

	if center and center~= false then
		center = recursiveGetSquare(center)
	end

	if not center then
		return {}
	end

	if not fractalOffset then
		fractalOffset = 1
	else
		fractalOffset = (fractalOffset*2)+1
	end

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
		local currentX, currentY = centerX-fractalFactor, centerY+fractalFactor
		-- ring refers to the path going around center, -1 to skip center
		local expectedRingLength = (8*i)-1

		for _=0, expectedRingLength do
			--if on top-row and not at the upper-right
			if (currentY == centerY+fractalFactor) and (currentX < centerX+fractalFactor) then
				--move-right
				currentX = currentX+fractalOffset
				--if on right-column and not the bottom-right
			elseif (currentX == centerX+fractalFactor) and (currentY > centerY-fractalFactor) then
				--move down
				currentY = currentY-fractalOffset
				--if on bottom-row and not on far-left
			elseif (currentY == centerY-fractalFactor) and (currentX > centerX-fractalFactor) then
				--move left
				currentX = currentX-fractalOffset
				--if on left-column and not on top-left
			elseif (currentX == centerX-fractalFactor) and (currentY < centerY+fractalFactor) then
				--move up
				currentY = currentY+fractalOffset
			end

			---@type IsoGridSquare square
			local square = getCell():getOrCreateGridSquare(currentX, currentY, 0)
			--[DEBUG]] getWorldMarkers():addGridSquareMarker(square, 0.8, fractalOffset-1, 0, false, 0.5)
			table.insert(squares, square)
		end
	end
	--[[DEBUG
	print("---[ IsoRange ]---\n total "..#squares.."/"..((range*2)+1)^2)
	for k,v in pairs(squares) do
		---@type IsoGridSquare vSquare
		local vSquare = v
		print(" "..k..": "..centerX-vSquare:getX()..", "..centerY-vSquare:getY())
	end
	]]
	return squares
end