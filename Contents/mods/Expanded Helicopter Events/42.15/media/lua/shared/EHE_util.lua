local util = {}

---Calculates if a flight should go out and the weather impact on flight safety
---@return boolean, number returns two values: willFly, impactOnFlightSafety
function util.weatherImpact()
	local CM = getClimateManager()

	local willFly = true
	local impactOnFlightSafety = 0

	local wind = CM:getWindIntensity()/2
	local fog = CM:getFogIntensity()/2
	local rain = CM:getRainIntensity()/3
	local snow = CM:getSnowIntensity()/2
	local thunder = CM:getIsThunderStorming()

	if (wind+rain+snow > 1.1) or (fog > 0.33) or (thunder == true) then willFly = false end

	impactOnFlightSafety = math.floor(((wind+rain+snow+fog)/6)+0.5)

	if SandboxVars.ExpandedHeli.WeatherImpactsEvents == false then return true, 0 end

	return willFly, impactOnFlightSafety
end


function util.getWorldAgeDays()
	return (getGameTime():getWorldAgeHours()/24)
end


function util.getActualPlayers()
	local seen = {}
	local list = {}

	local online = getOnlinePlayers()
	if online then
		for i = 0, online:size()-1 do
			local p = online:get(i)
			if p and not seen[p] then seen[p] = true; list[#list+1] = p end
		end
	end

	for i = 0, getNumActivePlayers()-1 do
		local p = getSpecificPlayer(i)
		if p and not seen[p] then seen[p] = true; list[#list+1] = p end
	end

	return list
end


function util.getActualLivingPlayers()
	local players = util.getActualPlayers()
	local livingPlayers = {}
	for i=1, #players do
		local p = players[i]
		if p and (not p:isDead()) and p:getX() >= 1 and p:getY() >= 1 then
			livingPlayers[#livingPlayers+1] = p
		end
	end
	return livingPlayers
end


util.eheBounds = {}
util.eheBounds.MAX_X = false
util.eheBounds.MIN_X = false
util.eheBounds.MAX_Y = false
util.eheBounds.MIN_Y = false
util.eheBounds.threshold = 1000

---Sets a min/max X/Y around all the players
function util.setDynamicGlobalXY()

	local livingPlayers = util.getActualLivingPlayers()

	util.eheBounds.MAX_X = false
	util.eheBounds.MIN_X = false
	util.eheBounds.MAX_Y = false
	util.eheBounds.MIN_Y = false

	for i=1, #livingPlayers do
		---@type IsoGameCharacter p
		local p = livingPlayers[i]

		local pX = p:getX()
		local pY = p:getY()

		if not util.eheBounds.MIN_X then
			util.eheBounds.MIN_X = pX-util.eheBounds.threshold
		else
			util.eheBounds.MIN_X = math.min(util.eheBounds.MIN_X, pX-util.eheBounds.threshold)
		end

		if not util.eheBounds.MAX_X then
			util.eheBounds.MAX_X = pX+util.eheBounds.threshold
		else
			util.eheBounds.MAX_X = math.max(util.eheBounds.MAX_X, pX+util.eheBounds.threshold)
		end

		if not util.eheBounds.MIN_Y then
			util.eheBounds.MIN_Y = pY-util.eheBounds.threshold
		else
			util.eheBounds.MIN_Y = math.min(util.eheBounds.MIN_Y, pY-util.eheBounds.threshold)
		end

		if not util.eheBounds.MAX_Y then
			util.eheBounds.MAX_Y = pY+util.eheBounds.threshold
		else
			util.eheBounds.MAX_Y = math.max(util.eheBounds.MAX_Y, pY+util.eheBounds.threshold)
		end
	end

	if (not util.eheBounds.MIN_X) or (not util.eheBounds.MAX_X) or (not util.eheBounds.MIN_Y) or (not util.eheBounds.MAX_Y) then
		--[[DEBUG]] print(" - EHE:ERROR: ".." X:"..tostring(util.eheBounds.MIN_X).."-"..tostring(util.eheBounds.MAX_X)..", Y:"..tostring(util.eheBounds.MIN_Y).."-"..tostring(util.eheBounds.MAX_Y))
		return
	end

	util.eheBounds.MAX_X = math.floor(util.eheBounds.MAX_X)
	util.eheBounds.MIN_X = math.floor(util.eheBounds.MIN_X)
	util.eheBounds.MAX_Y = math.floor(util.eheBounds.MAX_Y)
	util.eheBounds.MIN_Y = math.floor(util.eheBounds.MIN_Y)
	print(" -- EHE:XY: ".." MIN_X:"..util.eheBounds.MIN_X.." MAX_X:"..util.eheBounds.MAX_X.." MIN_Y:"..util.eheBounds.MIN_Y.." MAX_Y:"..util.eheBounds.MAX_Y)
end


---These is the equivalent of getters for Vector3
--tostring output of a Vector3: "Vector2 (X: %f, Y: %f) (L: %f, D:%f)"
---@param ShmectorTree Vector3
---@return number x of ShmectorTree
function util.Vector3GetX(ShmectorTree)
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
---@return number y of ShmectorTree
function util.Vector3GetY(ShmectorTree)
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
function util.getDaysSinceApoc()

	local monthsAfterApo = getSandboxOptions():getTimeSinceApo()-1
	--no months to count, go away
	if monthsAfterApo <= 0 then return 0 end

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


---@param item InventoryItem
function util.ageInventoryItem(item) if item and instanceof(item, "InventoryItem") then item:setAutoAge() end end


local flareSystem = require("EHE_flares.lua")
---@param vehicle BaseVehicle
function util.applyFlaresToEvent(vehicle)
	if not vehicle then return end

	local x, y, z = vehicle:getX(), vehicle:getY(), vehicle:getZ()
	local flares = 1 + ((ZombRand(10)==0 and 1) or 0)

	for i=1, flares do
		local sq = getSquare(x+ZombRand(-2,3), y+ZombRand(-2,3), z)
		if sq then
			---@type InventoryItem
			local flare = instanceItem("EHE.HandFlare")
			flare:getModData()["flareLit"] = true
			flareSystem.activateFlare(flare, flareSystem.Duration)
			sq:AddWorldInventoryItem(flare, 0, 0, 0)
		end
	end
end


---@param vehicle BaseVehicle
function util.applyCrashOnVehicle(vehicle)
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
function util.applyDeathOrCrawlerToCrew(arrayOfZombies)
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


---@param arrayOfZombies ArrayList
function util.applyDeathToCrew(arrayOfZombies)
	if arrayOfZombies then
		for i=0, arrayOfZombies:size()-1 do arrayOfZombies:get(i):setHealth(0) end
	end
end


---@param vehicle BaseVehicle
function util.applyParachuteToCarePackage(vehicle)
	if vehicle then
		EHE_spawner.request({
			funcType="item", spawnThis="EHE.EHE_Parachute", x=vehicle:getX(), y=vehicle:getY(), z=0,
			extraFunctions={"ageInventoryItem"}, processSquare="getOutsideSquareFromAbove" })
	end
end


function util.isIsoGridSquareOutside(square)
	if square and square:isOutside() and not square:isSolidTrans() and square:getRoomID()==-1 then
		return true
	end
	return false
end


--This attempts to get the outside (roof or ground) IsoGridSquare to any X/Y coordinate
---@param square IsoGridSquare
---@return IsoGridSquare
function util.getOutsideSquareFromAbove(square)
	if not square or not instanceof(square, "IsoGridSquare") then return end
	if util.isIsoGridSquareOutside(square) then return square end

	local x, y = square:getX(), square:getY()

	for i=1, 7 do
		local sq = getSquare(x, y, i)
		if util.isIsoGridSquareOutside(sq) then return sq end
	end
	return square
end


util.crashRoofHoleRadius = 2.5

---@param square IsoGridSquare
---@return IsoGridSquare
function util.getCrashSquare(square)
	if not square or not instanceof(square, "IsoGridSquare") then return end
	local ground = getSquare(square:getX(), square:getY(), 0) or square
	if util.isIsoGridSquareOutside(ground) then return ground end

	local roof = getSquare(ground:getX(), ground:getY(), 1)
	if not util.isIsoGridSquareOutside(roof) then return util.getOutsideSquareFromAbove(ground) end

	local range = math.ceil(util.crashRoofHoleRadius)
	for dx=-range, range do
		for dy=-range, range do
			if (dx*dx)+(dy*dy) <= util.crashRoofHoleRadius*util.crashRoofHoleRadius then
				local sq = getSquare(ground:getX()+dx, ground:getY()+dy, 1)
				if sq then util.destroySquareObjects(sq, 100, true) end
			end
		end
	end
	return ground
end


local isoRangeScan = require("EHE_IsoRangeScan.lua")
---@param square IsoGridSquare
function util.applyCrashDamageToWorld(square)
	local squares = isoRangeScan.getIsoRange(square, 9, nil, true)
	for k,sq in pairs(squares) do
		local s = util.getOutsideSquareFromAbove(sq) or sq
		if s then
			if ZombRand(101) <= 22 then
				IsoFireManager.StartFire(getCell(), s, true, ZombRand(200,450))
			end

			local tree = s:getTree()
			if tree then tree:toppleTree() end

			s:Burn()
		end
		--local point = getWorldMarkers():addGridSquareMarker(s, 1, 0, 0, true, 1)
	end
	---drawCircleExplosion(this.getFireRange(), this, IsoTrap.ExplosionMode.Fire)
end


util.crashFloorSprites = {default = "blends_natural_01_64"}
util.crashCrackSprites = {"d_streetcracks_1_16","d_streetcracks_1_17","d_streetcracks_1_18","d_streetcracks_1_19","d_streetcracks_1_20","d_streetcracks_1_21","d_streetcracks_1_22","d_streetcracks_1_23"}
util.crashKeepFloorSprites = {
	["blends_natural_01_0"]=true, ["blends_natural_01_5"]=true, ["blends_natural_01_6"]=true, ["blends_natural_01_7"]=true, ["floors_exterior_natural_01_24"]=true,
	["blends_street_01_48"]=true, ["blends_street_01_53"]=true, ["blends_street_01_54"]=true, ["blends_street_01_55"]=true, ["floors_exterior_natural_01_13"]=true,
}
util.crashSmearLength = 14
util.crashSmearTailLength = 2
util.crashSmearWidth = 4
util.crashSmearFloorCoreWidth = 1.6
util.crashApproachLength = 16
util.crashApproachSlope = 0.3
util.crashApproachWidth = 1
util.crashCollapseLevels = 2
---percent of vanilla scrap yield (ISMoveableDefinitions) that destroyed tiles leave behind
util.crashScrapYield = 50
---walls without material properties drop debris by sprite name, anything unmatched leaves stone rubble
util.crashWallDebris = { {"wood", "Base.UnusableWood"}, {"log", "Base.UnusableWood"}, {"metal", "Base.UnusableMetal"} }
util.crashWallDefaultDebris = "Base.Stone2"

---@param sq IsoGridSquare
---@param sq IsoGridSquare
---@param core boolean heavy damage: natural ground is dug out and indoor floors are torn up to the subfloor, otherwise grass is only flattened
function util.applyCrashGround(sq, core)
	local floor = sq:getFloor()
	if not floor or sq:isWaterSquare() then return end
	local spriteName = floor:getSprite() and floor:getSprite():getName()
	if not spriteName then return end

	if not luautils.stringStarts(spriteName, "blends_natural") then
		if sq:getRoom() then
			local replaceSprites = core and ISMoveableDefinitions and ISMoveableDefinitions:getInstance().floorReplaceSprites
			local sprite = replaceSprites and (#replaceSprites > 0) and getSprite(replaceSprites[ZombRand(#replaceSprites)+1])
			if sprite then
				floor:setSprite(sprite)
				floor:transmitUpdatedSpriteToClients()
			end
		elseif not util.crashKeepFloorSprites[spriteName] then
			floor:AttachExistingAnim(getSprite(util.crashCrackSprites[ZombRand(#util.crashCrackSprites)+1]), 0, 0, false, 0, false, 0.0)
			floor:transmitUpdatedSpriteToClients()
		end
		return
	end

	for i=sq:getObjects():size(),1,-1 do
		local o = sq:getObjects():get(i-1)
		if o:getSprite() and (
				o:getSprite():getProperties():has(IsoFlagType.canBeRemoved) or
				(o:getSprite():getProperties():has(IsoFlagType.vegitation) and o:getType() ~= IsoObjectType.tree) or
				(o:getSprite():getName() and luautils.stringStarts(o:getSprite():getName(), "blends_grassoverlays"))) then
			sq:transmitRemoveItemFromSquare(o)
		end
	end

	sq:removeGrass()

	if (not core) or util.crashKeepFloorSprites[spriteName] or spriteName == util.crashFloorSprites.default then return end

	floor:getModData().shovelled = true
	floor:setSprite(getSprite(util.crashFloorSprites.default))
	floor:RemoveAttachedAnims()
	floor:transmitUpdatedSpriteToClients()
	floor:transmitModData()
end


---Drops debris for a destroyed tile using the vanilla scrap definitions for its materials, falling to the ground below
---@param sq IsoGridSquare
---@param o IsoObject
function util.dropCrashScrap(sq, o)
	local props = o:getProperties()
	if not props or not ISMoveableDefinitions then return end
	local definitions = ISMoveableDefinitions:getInstance()
	local dropSquare = getSquare(sq:getX(), sq:getY(), 0) or sq
	local dropped = false

	for _,materialKey in ipairs({"Material", "Material2", "Material3"}) do
		local scrapDef = props:has(materialKey) and definitions.getScrapDefinition(props:get(materialKey))
		if scrapDef then
			local added = false
			for _,returnItems in ipairs({scrapDef.returnItems or {}, scrapDef.returnItemsStatic or {}}) do
				for _,entry in ipairs(returnItems) do
					local chance = (entry.chancePerRoll/100)*util.crashScrapYield
					for n=1, entry.maxAmount do
						if ZombRandFloat(0, 101) < chance then
							dropSquare:AddWorldInventoryItem(entry.returnItem, ZombRandFloat(0.1, 0.9), ZombRandFloat(0.1, 0.9), 0)
							added = true
						end
					end
				end
			end
			if (not added) and scrapDef.unusableItem then
				dropSquare:AddWorldInventoryItem(scrapDef.unusableItem, ZombRandFloat(0.1, 0.9), ZombRandFloat(0.1, 0.9), 0)
			end
			dropped = true
		end
	end

	if (not dropped) and (o:isWall() or props:has(IsoFlagType.WallNW) or o:getType() == IsoObjectType.wall) then
		local spriteName = string.lower((o:getSprite() and o:getSprite():getName()) or "")
		local debris = util.crashWallDefaultDebris
		for _,entry in ipairs(util.crashWallDebris) do
			if string.find(spriteName, entry[1], 1, true) then debris = entry[2] break end
		end
		for i=1, ZombRand(1, 3) do
			dropSquare:AddWorldInventoryItem(debris, ZombRandFloat(0.1, 0.9), ZombRandFloat(0.1, 0.9), 0)
		end
	end
end


---@param sq IsoGridSquare
---@param north boolean north wall destroyed
---@param west boolean west wall destroyed
function util.removeWallAttachments(sq, north, west)
	local faces = {}
	if north then
		table.insert(faces, {sq, IsoFlagType.attachedN})
		table.insert(faces, {sq:getAdjacentSquare(IsoDirections.N), IsoFlagType.attachedS})
	end
	if west then
		table.insert(faces, {sq, IsoFlagType.attachedW})
		table.insert(faces, {sq:getAdjacentSquare(IsoDirections.W), IsoFlagType.attachedE})
	end

	for _,face in ipairs(faces) do
		local faceSquare, flag = face[1], face[2]
		if faceSquare then
			local objects = faceSquare:getObjects()
			for i=objects:size(),1,-1 do
				local o = objects:get(i-1)
				if o:getProperties() and o:getProperties():has(flag) then
					if o:getContainer() then o:dumpContentsInSquare() end
					util.dropCrashScrap(faceSquare, o)
					faceSquare:transmitRemoveItemFromSquare(o)
				end
			end
		end
	end
end


---Removes walls, furniture, fixtures and other tiles; containers drop their contents first
---@param sq IsoGridSquare
---@param chance number percent per object
---@param includeFloor boolean also knock out the floor/roof (only used above ground level)
function util.destroySquareObjects(sq, chance, includeFloor)
	local objects = sq:getObjects()
	for i=objects:size(),1,-1 do
		local o = objects:get(i-1)
		local keep = instanceof(o, "IsoWorldInventoryObject") or instanceof(o, "IsoTree") or ((not includeFloor) and o:isFloor())
		if (not keep) and ZombRand(100) < chance then
			if instanceof(o, "IsoWindow") and (not o:isSmashed()) then o:smashWindow() end
			if instanceof(o, "IsoThumpable") or instanceof(o, "IsoDoor") then
				o:destroy()
			else
				local corner = o:getProperties() and o:getProperties():has(IsoFlagType.WallNW)
				local wallN = o:isWallN() or corner
				local wallW = o:isWallW() or corner
				if o:getContainer() then o:dumpContentsInSquare() end
				util.dropCrashScrap(sq, o)
				sq:transmitRemoveItemFromSquare(o)
				if wallN or wallW then util.removeWallAttachments(sq, wallN, wallW) end
			end
		end
	end
end


---@param sq IsoGridSquare
---@param core boolean
function util.applyCrashImpactToSquare(sq, core)
	if core then
		util.destroySquareObjects(sq, 50, sq:getZ() > 0)
	else
		local objects = sq:getObjects()
		for i=objects:size(),1,-1 do
			local o = objects:get(i-1)
			if instanceof(o, "IsoWindow") then
				if not o:isSmashed() then o:smashWindow() end
			elseif instanceof(o, "IsoDoor") or (instanceof(o, "IsoThumpable") and o:isDoor()) then
				if ZombRand(100) < 60 then o:destroy() end
			end
		end
	end
	if ZombRand(100) < 30 then sq:Burn(false) end
end


function util.applyCrashApproachDamage(impactSquare, headingX, headingY)
	local acrossX, acrossY = -headingY, headingX
	for d=1, util.crashApproachLength do
		local z = math.floor(d*util.crashApproachSlope)
		local centerX, centerY = impactSquare:getX()-(headingX*d), impactSquare:getY()-(headingY*d)
		for across=-util.crashApproachWidth, util.crashApproachWidth do
			local x = math.floor(centerX+(acrossX*across)+0.5)
			local y = math.floor(centerY+(acrossY*across)+0.5)
			for zz=math.max(0, z-1), math.min(7, z) do
				local sq = getSquare(x, y, zz)
				if sq then util.applyCrashImpactToSquare(sq, across == 0) end
			end
		end
	end
end


function util.applyCrashStructuralDamage(vehicle, extraParam)
	local impactSquare = isoRangeScan.recursiveGetSquare(vehicle)
	if not impactSquare then return end

	local headingX, headingY = 0, 0
	if extraParam then headingX, headingY = extraParam.headingX or 0, extraParam.headingY or 0 end
	local headingMagnitude = math.sqrt(headingX*headingX + headingY*headingY)
	if headingMagnitude > 0 then
		headingX, headingY = headingX/headingMagnitude, headingY/headingMagnitude
	else
		headingX, headingY = 1, 0
	end
	local acrossX, acrossY = -headingY, headingX

	local scanRadius = math.max(util.crashSmearLength, util.crashSmearWidth) + 2
	local squares = isoRangeScan.getIsoRange(impactSquare, scanRadius, nil, true)
	for k,sq in pairs(squares) do
		local dx, dy = sq:getX()-impactSquare:getX(), sq:getY()-impactSquare:getY()
		local along = dx*headingX + dy*headingY
		local across = dx*acrossX + dy*acrossY
		local absAcross = math.abs(across)

		if along >= -util.crashSmearTailLength and along <= util.crashSmearLength then
			local destroyChance = math.max(0, 100-(absAcross*(100/util.crashSmearWidth)))

			util.destroySquareObjects(sq, destroyChance, false)
			for z=1, util.crashCollapseLevels do
				local above = getSquare(sq:getX(), sq:getY(), sq:getZ()+z)
				if above then util.destroySquareObjects(above, destroyChance*(1-(z/(util.crashCollapseLevels+1))), true) end
			end

			local tree = sq:getTree()
			if tree and ZombRand(101) <= destroyChance then tree:toppleTree() end

			local alongFactor = (along >= 0) and (along/util.crashSmearLength) or (-along/util.crashSmearTailLength)
			local halfWidth = util.crashSmearFloorCoreWidth + ((util.crashSmearWidth-util.crashSmearFloorCoreWidth)*(1-(alongFactor*alongFactor)))
			if absAcross <= halfWidth then util.applyCrashGround(sq, absAcross <= util.crashSmearFloorCoreWidth) end
		end
	end

	util.applyCrashApproachDamage(impactSquare, headingX, headingY)

	local nearbyVehicles = isoRangeScan.getVehiclesInRange(impactSquare, scanRadius)
	for i=1, #nearbyVehicles do
		local nearbyVehicle = nearbyVehicles[i]
		if nearbyVehicle and nearbyVehicle ~= vehicle then
			local vdx, vdy = nearbyVehicle:getX()-impactSquare:getX(), nearbyVehicle:getY()-impactSquare:getY()
			local vAlong = vdx*headingX + vdy*headingY
			local vAcross = vdx*acrossX + vdy*acrossY
			if vAlong >= -util.crashSmearTailLength and vAlong <= util.crashSmearLength and math.abs(vAcross) <= util.crashSmearWidth then
				for p=0, nearbyVehicle:getPartCount()-1 do
					local nearbyVehiclePart = nearbyVehicle:getPartByIndex(p)
					if nearbyVehiclePart then nearbyVehiclePart:setCondition(0) end
				end
				IsoFireManager.StartFire(getCell(), nearbyVehicle:getSquare(), true, ZombRand(200,450))
			end
		end
	end
end


function util.getVehiclePartByName(vehicle, partName)
    for i = 0, vehicle:getPartCount() - 1 do
        local part = vehicle:getPartByIndex(i)
        if part and part:getId() == partName then
            return part
        end
    end
    return nil
end


function util.applyModularCrashParts(vehicle, crashParts)
    if not vehicle or not crashParts then return end
    local vx = vehicle:getX()
    local vy = vehicle:getY()

    for _, entry in ipairs(crashParts) do
        if ZombRand(100) < entry.chance then
            local part = util.getVehiclePartByName(vehicle, entry.part)
            if part then
                part:setCondition(0)
            end
            local angle = ZombRandFloat(0, math.pi * 2)
            if entry.scrapItem then
                local dist = ZombRand(3, 9)
                EHE_spawner.request({
                    funcType = "item",
                    spawnThis = entry.scrapItem,
                    x = math.floor(vx + math.cos(angle) * dist),
                    y = math.floor(vy + math.sin(angle) * dist),
                    z = 0,
                    extraFunctions = {"ageInventoryItem"},
                    processSquare = "getOutsideSquareFromAbove",
                })
            end
            if entry.scrapVehicle then
                local dist = ZombRand(5, 12)
                EHE_spawner.request({
                    funcType = "vehicle",
                    spawnThis = entry.scrapVehicle,
                    x = math.floor(vx + math.cos(angle) * dist),
                    y = math.floor(vy + math.sin(angle) * dist),
                    z = 0,
                    extraFunctions = {"applyVehicleMetalKg"},
                    processSquare = "getOutsideSquareFromAbove",
                })
            end
        end
    end
end


return util
