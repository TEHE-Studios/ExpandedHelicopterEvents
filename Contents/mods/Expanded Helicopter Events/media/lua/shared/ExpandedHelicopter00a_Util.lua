---IsoPlayer are player entities but also NPCs (from mods)
EHEIsoPlayers = {}

---@param playerObject IsoPlayer | IsoGameCharacter
function addToEIP(playerObject)

	if not playerObject then
		return
	end

	if playerObject:getX() < 1 or playerObject:getY() < 1 then
		print(" - EHE: WARN: IsoPlayers can't add; IsoPlayer x/y less than 1:"..playerObject:getFullName())
		return
	end

	print(" - EHE: IsoPlayers adding:"..playerObject:getFullName())

	if not playerObject:isDead() then
		EHEIsoPlayers[playerObject] = true
	end
end

---@param playerObject IsoPlayer | IsoGameCharacter
function removeFromEIP(playerObject)
	if EHEIsoPlayers[playerObject] then
		print(" - EHE: IsoPlayers removing:"..playerObject:getFullName())
		EHEIsoPlayers[playerObject] = nil
	end
end

function getActualPlayers()
	local players = {}

	local playersOnline = getOnlinePlayers()
	if playersOnline then
		for i=0, playersOnline:size()-1 do
			local player = playersOnline:get(i)
			players[player] = true
		end
	end

	for playerIndex=0, getNumActivePlayers()-1 do
		players[getSpecificPlayer(playerIndex)] = true
	end

	local cleanedPlayerList = {}
	--print("--getActualPlayers: ")
	for playerObj,_ in pairs(players) do
		--print(" --"..playerObj:getUsername())
		table.insert(cleanedPlayerList, playerObj)
	end

	return cleanedPlayerList
end

function addActualPlayersToEIP()
	local playersOnline = getActualPlayers()
	for _,playerObj in pairs(playersOnline) do
		addToEIP(playerObj)
	end
end

Events.OnCreateLivingCharacter.Add(addToEIP)
Events.OnCharacterDeath.Add(removeFromEIP)


eheBounds = {}
eheBounds.MAX_X = false
eheBounds.MIN_X = false
eheBounds.MAX_Y = false
eheBounds.MIN_Y = false
eheBounds.threshold = 500

---Sets a min/max X/Y around all the players
function setDynamicGlobalXY()

	addActualPlayersToEIP()

	eheBounds.MAX_X = false
	eheBounds.MIN_X = false
	eheBounds.MAX_Y = false
	eheBounds.MIN_Y = false

	for character,value in pairs(EHEIsoPlayers) do
		---@type IsoGameCharacter p
		local p = character

		local pX = p:getX()
		local pY = p:getY()

		if not eheBounds.MIN_X then
			eheBounds.MIN_X = pX-eheBounds.threshold
		else
			eheBounds.MIN_X = math.min(eheBounds.MIN_X, pX-eheBounds.threshold)
		end

		if not eheBounds.MAX_X then
			eheBounds.MAX_X = pX+eheBounds.threshold
		else
			eheBounds.MAX_X = math.max(eheBounds.MAX_X, pX+eheBounds.threshold)
		end

		if not eheBounds.MIN_Y then
			eheBounds.MIN_Y = pY-eheBounds.threshold
		else
			eheBounds.MIN_Y = math.min(eheBounds.MIN_Y, pY-eheBounds.threshold)
		end

		if not eheBounds.MAX_Y then
			eheBounds.MAX_Y = pY+eheBounds.threshold
		else
			eheBounds.MAX_Y = math.max(eheBounds.MAX_Y, pY+eheBounds.threshold)
		end
	end

	if (not eheBounds.MIN_X) or (not eheBounds.MAX_X) or (not eheBounds.MIN_Y) or (not eheBounds.MAX_Y) then
		--[[DEBUG]] print(" - EHE:ERROR: ".." X:"..tostring(eheBounds.MIN_X).."-"..tostring(eheBounds.MAX_X)..", Y:"..tostring(eheBounds.MIN_X).."-"..tostring(eheBounds.MIN_X))
		return
	end

	eheBounds.MAX_X = math.floor(eheBounds.MAX_X)
	eheBounds.MIN_X = math.floor(eheBounds.MIN_X)
	eheBounds.MAX_Y = math.floor(eheBounds.MAX_Y)
	eheBounds.MIN_Y = math.floor(eheBounds.MIN_Y)
	print(" -- EHE:XY: ".." MIN_X:"..eheBounds.MIN_X.." MAX_X:"..eheBounds.MAX_X.." MIN_Y:"..eheBounds.MIN_Y.." MAX_Y:"..eheBounds.MAX_Y)
end


---These is the equivalent of getters for Vector3
--tostring output of a Vector3: "Vector2 (X: %f, Y: %f) (L: %f, D:%f)"
---@param ShmectorTree Vector3
---@return float x of ShmectorTree
function Vector3GetX(ShmectorTree)
	if not ShmectorTree then
		return ""
	end
	local tostring = tostring(ShmectorTree)
	local coordinate = string.match(tostring, "%(X%: (.-)%, Y%: ")
	coordinate = string.gsub(coordinate, ",",".")
	--[debug]] print("EHE: Vector3-GetX-Workaround:  "..tostring.."  =  "..coordinate)
	return coordinate
end


---@param ShmectorTree Vector3
---@return float y of ShmectorTree
function Vector3GetY(ShmectorTree)
	if not ShmectorTree then
		return ""
	end
	local tostring = tostring(ShmectorTree)
	local coordinate = string.match(tostring, "%, Y%: (.-)%) %(")
	coordinate = string.gsub(coordinate, ",",".")
	--[debug]] print("EHE: Vector3-GetY-Workaround:  "..tostring.."  =  "..coordinate)
	return coordinate
end


---Check how many days it has been since the start of the apocalypse; corrects for sandbox option "Months since Apoc"
---@return number Days since start of in-game apocalypse
function eHeli_getDaysBeforeApoc()

	local monthsAfterApo = getSandboxOptions():getTimeSinceApo()-1
	--no months to count, go away
	if monthsAfterApo <= 0 then
		return 0
	end

	local gameTime = getGameTime()
	local startYear = gameTime:getStartYear()
	--months of the year start at 0
	local apocStartMonth = (gameTime:getStartMonth()+1)-monthsAfterApo
	--roll the year back if apocStartMonth is negative
	if apocStartMonth <= 0 then
		apocStartMonth = 12+apocStartMonth
		startYear = startYear-1
	end
	local apocDays = 0
	--count each month at a time to get correct day count
	for month=0, monthsAfterApo do
		apocStartMonth = apocStartMonth+1
		--roll year forward if needed, reset month
		if apocStartMonth > 12 then
			apocStartMonth = 1
			startYear = startYear+1
		end
		--months of the year start at 0
		local daysInM = gameTime:daysInMonth(startYear, apocStartMonth-1)
		--if this is the first month being counted subtract starting day date
		if month==0 then
			daysInM = daysInM-gameTime:getStartDay()+1
		end
		apocDays = apocDays+daysInM
	end

	return apocDays
end


--This attempts to get the outside (roof or ground) IsoGridSquare to any X/Y coordinate
---@param square IsoGridSquare
---@return IsoGridSquare
function getOutsideSquareFromAbove(square,isVehicle)
	if not square then
		return
	end

	if square:isOutside() and square:isSolidFloor() then
		return square
	end

	--if isVehicle is true don't allow the code to look for roof tiles
	if isVehicle then
		return
	end

	local x, y = square:getX(), square:getY()

	for i=1, 7 do
		local sq = getSquare(x, y, i)
		if sq and sq:isOutside() and sq:isSolidFloor() then
			return sq
		end
	end
end


---@param item InventoryItem
function ageInventoryItem(item)
	if item then
		item:setAutoAge()
	end
end


---@param vehicle BaseVehicle
function applyCrashOnVehicle(vehicle)
	if not vehicle then
		return
	end
	vehicle:crash(1000,true)
	vehicle:crash(1000,false)

	for i=0, vehicle:getPartCount() do
		---@type VehiclePart
		local part = vehicle:getPartByIndex(i) --VehiclePart
		if part then
			local partDoor = part:getDoor()
			if partDoor ~= nil then
				partDoor:setLocked(false)
			end
		end
	end
end


---@param arrayOfZombies ArrayList
function applyDeathOrCrawlerToCrew(arrayOfZombies)
	if arrayOfZombies and arrayOfZombies:size()>0 then
		local zombie = arrayOfZombies:get(0)
		--33% to be dead on arrival
		if ZombRand(1,101) <= 33 then
			--print("crash spawned: "..outfitID.." killed")
			zombie:setHealth(0)
		else
			if ZombRand(1,101) <= 25 then
				--print("crash spawned: "..outfitID.." crawler")
				zombie:setCanWalk(false)
				zombie:setBecomeCrawler(true)
				zombie:knockDown(true)
			end
		end
	end
end


---@param vehicle BaseVehicle
function applyParachuteToCarePackage(vehicle)
	if vehicle then
		SpawnerTEMP.spawnItem("EHE.EHE_Parachute", vehicle:getX(), vehicle:getY(), 0, nil, nil, "getOutsideSquareFromAbove")
	end
end