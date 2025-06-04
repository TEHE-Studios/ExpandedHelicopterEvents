require "ExpandedHelicopter11_EventMarkerHandler"
require "ExpandedHelicopter00c_SpawnerAPI"

local subEvents = {}

function subEvents.eHelicopter_jetBombing(heli)
	local heliX, heliY, _ = heli:getXYZAsInt()
	local cell = getCell()
	local vehiclesInCell = cell:getVehicles()
	for i=0, vehiclesInCell:size()-1 do
		---@type BaseVehicle
		local vehicle = vehiclesInCell:get(i)
		if vehicle and vehicle:isAlarmed() then
			vehicle:triggerAlarm()
		end
	end
end


function subEvents.hostilePredicateCivilian(target)
	if not target then return end
	local nonCivScore = 0
	---@type IsoPlayer|IsoGameCharacter
	local player = target
	local wornItems = player:getWornItems()
	if wornItems then
		for i=0, wornItems:size()-1 do
			---@type InventoryItem
			local item = wornItems:get(i):getItem()
			if item then
				if string.match(string.lower(item:getFullType()),"army")
						or string.match(string.lower(item:getFullType()),"military")
						or string.match(string.lower(item:getFullType()),"riot")
						or string.match(string.lower(item:getFullType()),"police")
						or item:getTags():contains("Police")
						or item:getTags():contains("Military") then
					nonCivScore = nonCivScore+1
				end
			end
		end
	end
	return nonCivScore<3
end


function subEvents.eHelicopter_dropSupplies(heli)

	local heliX, heliY, _ = heli:getXYZAsInt()
	local SuppliesItems = {"556Carton","556Carton","556Carton","556Carton"}

	local moreSuppliesItems = {"556Carton","556Carton","556Carton",}
	local iterations = 10
	for i=1, iterations do
		local SuppliesType = moreSuppliesItems[(ZombRand(#moreSuppliesItems)+1)]
		table.insert(moreSuppliesItems, SuppliesType)
		table.insert(SuppliesItems, SuppliesType)
	end

	local soundEmitter = getWorld():getFreeEmitter(heliX, heliY, 0)
	soundEmitter:playSound("eHeliDumpSupplies", heliX, heliY, 0)

	for _,SuppliesType in pairs(SuppliesItems) do
		heliY = heliY+ZombRand(-3,3)
		heliX = heliX+ZombRand(-3,3)
		SpawnerTEMP.spawnItem(SuppliesType, heliX, heliY, 0, {"ageInventoryItem"}, nil, "getOutsideSquareFromAbove")
	end
end


function subEvents.eHelicopter_dropCrewOff(heli)
	if not heli then
		return
	end

	local x, y, z = heli:getXYZAsInt()
	local xOffset = ZombRand(20,35)
	local yOffset = ZombRand(20,35)

	local trueTarget = heli.trueTarget
	if trueTarget then
		local tX, tY = trueTarget:getX(), trueTarget:getY()
		xOffset=math.max(0,xOffset-tX)
		yOffset=math.max(0,yOffset-tY)
	end

	if ZombRand(101) <= 50 then
		xOffset=0-xOffset
	end
	if ZombRand(101) <= 50 then
		yOffset=0-yOffset
	end

	x = x+xOffset
	y = y+yOffset

	--[[DEBUG]] print("SWH: DEBUG: eHelicopter_dropCrewOff: "..x..","..y)
	--for k,v in pairs(heli.crew) do print(" -- k:"..tostring(k).." -- ("..tostring(v)..")") end

	eventMarkerHandler.setOrUpdate(getRandomUUID(), "media/ui/crew.png", 750, x, y)
	heli:spawnCrew(x, y, 0)
	heli.addedFunctionsToEvents.OnHover = false
end


function subEvents.eHelicopter_dropTrash(heli)

	local heliX, heliY, _ = heli:getXYZAsInt()
	local trashItems = {"WhiskeyEmpty","SmashedBottle","BeerEmpty","BeerEmpty"}

	local moreTrashItems = {"SmashedBottle","SmashedBottle","SmashedBottle","SmashedBottle",
							"MayonnaiseEmpty","Pop3Empty","Pop2Empty","Pop3Empty","WhiskeyEmpty",
							"BeerCanEmpty","BeerCanEmpty","BeerCanEmpty","BeerCanEmpty","BeerEmpty"}
	local iterations = 10
	for i=1, iterations do
		local trashType = moreTrashItems[(ZombRand(#moreTrashItems)+1)]
		table.insert(moreTrashItems, trashType)
		table.insert(trashItems, trashType)
	end

	local soundEmitter = getWorld():getFreeEmitter(heliX, heliY, 0)
	soundEmitter:playSound("eHeliDumpTrash", heliX, heliY, 0)

	for _,trashType in pairs(trashItems) do
		heliY = heliY+ZombRand(-3,3)
		heliX = heliX+ZombRand(-3,3)
		SpawnerTEMP.spawnItem(trashType, heliX, heliY, 0, {"ageInventoryItem"}, nil, "getOutsideSquareFromAbove")
	end
end


return subEvents