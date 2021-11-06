farSquareSpawn = {}

function farSquareSpawn.getOrSetPendingSpawnsList()
	local GTMData = getGameTime():getModData()
	--if no EventsSchedule found make it an empty list
	if not GTMData.farSquarePendingSpawns then
		GTMData.farSquarePendingSpawns = {}
	end
	return GTMData.farSquarePendingSpawns
end


---@param objectType string
---@param x number
---@param y number
---@param z number
---@param funcsToApply table
function farSquareSpawn.setToSpawn(spawnFuncType, objectType, x, y, z, funcsToApply)
	local farSquarePendingSpawns = farSquareSpawn.getOrSetPendingSpawnsList()
	--[DEBUG]] print("farSquareSpawn.setToSpawn: added")
	table.insert(farSquarePendingSpawns, {spawnFuncType=spawnFuncType, objectType=objectType, x=x, y=y, z=z, funcsToApply=funcsToApply})
end


---@param square IsoGridSquare
function farSquareSpawn.parseSquare(square)
	local farSquarePendingSpawns = farSquareSpawn.getOrSetPendingSpawnsList()

	if #farSquarePendingSpawns < 1 then
		return
	end

	local sqX, sqY, sqZ = square:getX(), square:getY(), square:getZ()
	for key,entry in pairs(farSquarePendingSpawns) do
		if (not entry.spawned) and entry.x==sqX and entry.y==sqY and entry.z==sqZ then

			local isVehicle = entry.spawnFuncType=="Vehicle"
			local shiftedSquare = getOutsideSquareFromAbove(square,isVehicle)

			--If isVehicle and can't spawn on square look for nearby squares.
			if isVehicle and not shiftedSquare then
				local aSqOutsideAbove = {}
				for k,sq in pairs(getIsoRange(square, 2)) do
					local outsideSq = getOutsideSquareFromAbove(sq,isVehicle)
					if outsideSq then
						table.insert(aSqOutsideAbove,outsideSq)
					end
				end
				if #aSqOutsideAbove > 0 then
					shiftedSquare = aSqOutsideAbove[ZombRand(#aSqOutsideAbove)+1]
				end
			end

			if shiftedSquare then
				local spawnFunc = farSquareSpawn["spawn"..entry.spawnFuncType]

				if spawnFunc then
					local spawnedObject = spawnFunc(shiftedSquare, entry.objectType)

					if spawnedObject then
						--[DEBUG]] print("DEBUG: farSquareSpawn.parseSquare: "..tostring(spawnedObject).." "..square:getX()..","..square:getY())
						if entry.funcsToApply and (type(entry.funcsToApply)=="table") then
							for k,func in pairs(entry.funcsToApply) do
								if func then
									func(spawnedObject)
								end
							end
						end
						farSquarePendingSpawns[key] = nil
					end
				else
					farSquarePendingSpawns[key] = nil
				end
			else
				farSquarePendingSpawns[key] = nil
			end
		end
	end
end
Events.LoadGridsquare.Add(farSquareSpawn.parseSquare)


---@param square IsoGridSquare
---@param itemType string
---@return InventoryItem
function farSquareSpawn.spawnItem(square, itemType)
	if not square or not itemType then
		return
	end
	local item = square:AddWorldInventoryItem(itemType, 0, 0, 0)
	return item
end

---@param square IsoGridSquare
---@param vehicleType string
---@return BaseVehicle
function farSquareSpawn.spawnVehicle(square, vehicleType)
	if not square or not vehicleType then
		return
	end
	local vehicle = addVehicleDebug(vehicleType, IsoDirections.getRandom(), nil, square)
	return vehicle
end

---@param square IsoGridSquare
---@param outfitID string
---@return ArrayList Containing : IsoZombie
function farSquareSpawn.spawnZombie(square, outfitID)
	if not square or not outfitID then
		return
	end
	local zombies = addZombiesInOutfit(square:getX(), square:getY(), square:getZ(), 1, outfitID, 0)
	return zombies
end