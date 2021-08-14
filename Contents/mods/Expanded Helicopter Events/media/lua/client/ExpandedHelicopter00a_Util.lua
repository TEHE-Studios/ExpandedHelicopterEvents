Events.OnGameBoot.Add(print("Expanded Helicopter Events: ver:0.9.4"))


---IsoPlayer are player entities but also NPCs (from mods)
EHEIsoPlayers = {}

---@param playerObject IsoPlayer | IsoGameCharacter
function addToEIP(playerObject)

	if not playerObject then
		return
	end

	if playerObject:getX() < 1 or playerObject:getY() < 1 then
		print(" - EHE: ERR: IsoPlayers can't add; IsoPlayer x/y less than 1:"..playerObject:getFullName())
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

function addActualPlayersToEIP()
	for playerIndex=0, getNumActivePlayers()-1 do
		---@type IsoLivingCharacter | IsoGameCharacter
		addToEIP(getSpecificPlayer(playerIndex))
	end
end


Events.OnGameStart.Add(addActualPlayersToEIP)
Events.OnCreateLivingCharacter.Add(addToEIP)
Events.OnCharacterDeath.Add(removeFromEIP)


eheBounds = {}
eheBounds.MAX_X = false
eheBounds.MIN_X = false
eheBounds.MAX_Y = false
eheBounds.MIN_Y = false
eheBounds.threshold = 2500

---Sets a min/max X/Y around all the players
function setDynamicGlobalXY()

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

	eheBounds.MAX_X = math.floor(eheBounds.MAX_X)
	eheBounds.MIN_X = math.floor(eheBounds.MIN_X)
	eheBounds.MAX_Y = math.floor(eheBounds.MAX_Y)
	eheBounds.MIN_Y = math.floor(eheBounds.MIN_Y)
	print(" - EHE:XY: ".." MIN_X:"..eheBounds.MIN_X.." MAX_X:"..eheBounds.MAX_X.." MIN_Y:"..eheBounds.MIN_Y.." MAX_Y:"..eheBounds.MAX_Y)
end


function fetchRandomEdgeSquare()
	setDynamicGlobalXY()
	local minMaxX = {eheBounds.MIN_X, eheBounds.MAX_X}
	local minMaxY = {eheBounds.MIN_Y, eheBounds.MAX_Y}
	local randomX = ZombRand(eheBounds.MIN_X, eheBounds.MAX_X)
	local randomY = ZombRand(eheBounds.MIN_Y, eheBounds.MAX_Y)

	if ZombRand(101) <= 50 then
		randomX = minMaxX[ZombRand(1,3)]
	else
		randomY = minMaxY[ZombRand(1,3)]
	end

	local randomEdgeSquare = getCell():getOrCreateGridSquare(randomX,randomY,0)
	return randomEdgeSquare
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
