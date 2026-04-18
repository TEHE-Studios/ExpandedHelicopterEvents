---This is an utility function meant for large scale scans of isoGridSquares around a given IsoObject.
---The scans are done from center (or centers) outward to fill a larger area.
local isoRangeScan = {}

---@param center IsoGameCharacter
function isoRangeScan.recursiveGetSquare(center)
	if not center then return nil end
	if instanceof(center, "IsoGameCharacter") and center:getVehicle() then center = center:getVehicle() end
	if not instanceof(center, "IsoGridSquare") then center = center:getSquare() end

	return center
end


---@param square IsoGridSquare
---@param returnFirst boolean
---@return table|BaseVehicle table of BaseVehicles or just 1 BaseVehicle
function isoRangeScan.getVehiclesIntersecting(square, returnFirst)
	local vehicles = getCell():getVehicles()
	local intersectingVehicles = {}
	for v=0, vehicles:size()-1 do
		---@type BaseVehicle
		local vehicle = vehicles:get(v)
		if vehicle:isIntersectingSquare(square:getX(),square:getY(),square:getZ()) then
			if returnFirst then return vehicle end
			table.insert(intersectingVehicles, vehicle)
		end
	end

	if #intersectingVehicles==1 then return intersectingVehicles[1] end

	return intersectingVehicles
end


---@param center IsoObject|IsoGridSquare
---@param range number tiles to scan from center, not including center. ex: range of 1 = 3x3
---@param lookForType string
function isoRangeScan.getHumanoidsInRange(center, range, lookForType, predicateFunction)

	if center then center = isoRangeScan.recursiveGetSquare(center) else return {} end

	local squaresInRange = isoRangeScan.getIsoRange(center, range)
	local objectsFound = {}

	for sq=1, #squaresInRange do

		---@type IsoGridSquare
		local square = squaresInRange[sq]
		local squareContents = square:getLuaMovingObjectList()

		for i=1, #squareContents do
			---@type IsoMovingObject|IsoGameCharacter foundObject
			local foundObj = squareContents[i]

			if instanceof(foundObj, lookForType) then
				if square:isOutside() and ((not predicateFunction) or (predicateFunction and predicateFunction(foundObj))) then
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
---@param predicateFunction function
function isoRangeScan.getHumanoidsInFractalRange(center, range, fractalRange, lookForType, predicateFunction)

	if center then center = isoRangeScan.recursiveGetSquare(center) else return {} end

	--range and fractalRange are flipped in the parameters here because:
	-- "fractalRange" represents the number of rows from center out but with an offset of "range" instead
	local fractalCenters = isoRangeScan.getIsoRange(center, fractalRange, range)
	local fractalObjectsFound = {}
	---print("getHumanoidsInFractalRange: centers found: "..#fractalCenters)
	--pass through each "center square" found
	for i=1, #fractalCenters do
		local objectsFound = isoRangeScan.getHumanoidsInRange(fractalCenters[i], range, lookForType, predicateFunction)
		---print(" fractal center "..i..":  "..#objectsFound)
		--store a list of objectsFound within the fractalObjectsFound list
		table.insert(fractalObjectsFound, objectsFound)
	end

	return fractalObjectsFound
end


function isoRangeScan.isWithInRange(radius,center,square)
	local dx = square:getX() - center:getX()
	local dy = square:getY() - center:getY()
	return (dx * dx + dy * dy) <= radius*radius
end


---@param center IsoObject | IsoGridSquare
---@param range number tiles to scan from center, not including center. ex: range of 1 = 3x3
---@param fractalOffset number fractal offset - spreads out squares by this number
---@return table of IsoGridSquare
function isoRangeScan.getIsoRange(center, range, fractalOffset, circular)
	if not center then return {} end
	center = isoRangeScan.recursiveGetSquare(center)
	if not center then return {} end

	local spread = fractalOffset and (fractalOffset * 2 + 1) or 1
	local centerX, centerY = center:getX(), center:getY()
	local squares = { center }

	if range < 1 then return squares end

	local radius = (range * spread)

	for i = 1, range do
		local fractalStep = i * spread
		local x, y = centerX - fractalStep, centerY + fractalStep
		local totalSteps = (8 * i) - 1

		for step = 1, totalSteps do
			-- Spiral movement: right, down, left, up
			if (y == centerY + fractalStep) and (x < centerX + fractalStep) then
				x = x + spread
			elseif (x == centerX + fractalStep) and (y > centerY - fractalStep) then
				y = y - spread
			elseif (y == centerY - fractalStep) and (x > centerX - fractalStep) then
				x = x - spread
			elseif (x == centerX - fractalStep) and (y < centerY + fractalStep) then
				y = y + spread
			end

			local square = getSquare(x, y, 0)
			if square then
				if not circular or isoRangeScan.isWithInRange(radius,center,square) then
					table.insert(squares, square)
				end
			end
		end
	end

	return squares
end

return isoRangeScan