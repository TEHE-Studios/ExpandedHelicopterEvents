require "ExpandedHelicopter00f_WeatherImpact"
require "ExpandedHelicopter00a_Util"
require "ExpandedHelicopter00b_IsoRangeScan"
local flareSystem = require "ExpandedHelicopter_Flares"
local eventSoundHandler = require "ExpandedHelicopter01b_Sounds"
local pseudoSquare = require "ExpandedHelicopter00a_psuedoSquare"


ALL_HELICOPTERS = {}

---Do not call this function directly for new helicopters; use: getFreeHelicopter instead
function eHelicopter:new()

	local o = {}
	setmetatable(o, self)
	self.__index = self
	table.insert(ALL_HELICOPTERS, o)
	o.ID = #ALL_HELICOPTERS

	return o
end


---returns first "unLaunched" helicopter found in ALL_HELICOPTERS -OR- creates a new instance
function getFreeHelicopter(preset)
	---@type eHelicopter heli
	local heli

	---Testing non-recycling
	--for _,h in ipairs(ALL_HELICOPTERS) do
	--	if h.state == "unLaunched" then
	--		heli = h
	--		break
	--	end
	--end

	if not heli then
		heli = eHelicopter:new()
	end

	if preset then
		heli:loadPreset(preset)
	end

	return heli
end


---Initialize Position
---@param targetedPlayer IsoMovingObject | IsoPlayer | IsoGameCharacter
---@param randomEdge boolean true = uses random edge, false = prefers closer edge
function eHelicopter:initPos(targetedPlayer, randomEdge, initX, initY)

	if not targetedPlayer then
		return
	end

	setDynamicGlobalXY()

	--player's location
	local tpX = targetedPlayer:getX()
	local tpY = targetedPlayer:getY()

	--assign a random spawn point for the helicopter within a radius from the player
	--these values are being clamped to not go passed MIN_XY/MAX edges
	local offset = 500
	initX = initX or ZombRand(math.max(eheBounds.MIN_X, tpX-offset), math.min(eheBounds.MAX_X, tpX+offset)+1)
	initY = initY or ZombRand(math.max(eheBounds.MIN_Y, tpY-offset), math.min(eheBounds.MAX_Y, tpY+offset)+1)

	self.currentPosition = self.currentPosition or Vector3.new()

	if randomEdge then
		local initPosXY = {initX, initY}
		local minMax = {eheBounds.MIN_X, eheBounds.MIN_Y, eheBounds.MAX_X, eheBounds.MAX_Y}

		--pick X=1 or Y=2 position
		local randXYEdge = ZombRand(1, #initPosXY+1)

		--pick min=1,2 or max=3,4 (50% to be max)
		local randXYMinMax = randXYEdge
		if ZombRand(101) <= 50 then
			randXYMinMax = randXYMinMax+2
		end

		--[DEBUG]] print(" -- EHE: randomEdge:true; randXYEdge: "..randXYEdge.." randXYMinMax: "..randXYMinMax)
		--this sets either [1] or [2] of initPosXY as [1] through [4] of minMax
		initPosXY[randXYEdge] = minMax[randXYMinMax]

		self.currentPosition:set(initPosXY[1], initPosXY[2], self.height)
		return
	end

	--Looks for the closest edge to initX and initY to modify it to be along either eheBounds.MIN_X/Y/MAX_X/Y
	--differences between initX and eheBounds.MIN_X/Y/MAX_X/Y edge values
	local xDiffToMin = math.abs(initX-eheBounds.MIN_X)
	local xDiffToMax = math.abs(initX-eheBounds.MAX_X)
	local yDiffToMin = math.abs(initY-eheBounds.MIN_Y)
	local yDiffToMax = math.abs(initY-eheBounds.MAX_Y)
	--this list uses x/yDifftoMin/Max's values as keys storing their respective corresponding edges
	local xyDiffCorrespondingEdge = {[xDiffToMin]=eheBounds.MIN_X, [xDiffToMax]=eheBounds.MAX_X, [yDiffToMin]=eheBounds.MIN_Y, [yDiffToMax]=eheBounds.MAX_Y}
	--get the smallest of the four differences
	local smallestDiff = math.min(xDiffToMin,xDiffToMax,yDiffToMin,yDiffToMax)

	--if the smallest is a X local var then set initX to the closer edge
	if (smallestDiff == xDiffToMin) or (smallestDiff == xDiffToMax) then
		initX = xyDiffCorrespondingEdge[smallestDiff]
	else
		--otherwise, set initY to the closer edge
		initY = xyDiffCorrespondingEdge[smallestDiff]
	end

	self.currentPosition:set(initX, initY, self.height)
end


---@return int, int, int XYZ of eHelicopter
function eHelicopter:getXYZAsInt()
	if not self.currentPosition then return end

	local ehX = math.floor(Vector3GetX(self.currentPosition) + 0.5)
	local ehY = math.floor(Vector3GetY(self.currentPosition) + 0.5)
	local ehZ = self.height

	return ehX, ehY, ehZ
end


---@return IsoGridSquare of eHelicopter
function eHelicopter:getIsoGridSquare()
	local ehX, ehY, _ = self:getXYZAsInt()
	if not ehX or not ehY then return end
	local square = getSquare(ehX, ehY, 0)
	return square
end


---@return IsoGridSquare|table square or pseudoSquare (table) of eHelicopter
function eHelicopter:getIsoGridOrPseudoSquare()
	local ehX, ehY, _ = self:getXYZAsInt()
	if not ehX or not ehY then return end
	local square = getSquare(ehX, ehY, 0) or pseudoSquare:new(ehX, ehY, 0)
	return square
end


---@return boolean
function eHelicopter:isInBounds()
	local h_x, h_y, _ = self:getXYZAsInt()

	if h_x and h_y and h_x < eheBounds.MAX_X+1 and h_x > eheBounds.MIN_X-1 and h_y < eheBounds.MAX_Y+1 and h_y > eheBounds.MIN_Y-1 then
		return true
	end

	if self.state == "following" then
		--Ignore followers being out of bounds
		return true
	end
	
	--[[DEBUG]] print("- EHE: OUT OF BOUNDS: "..self:heliToString(true))
	return false
end


---@param x number
---@param y number
---@return number
function eHelicopter:getDistanceToXY(x,y)
	if (not x) or (not y) or (not self.currentPosition) then print("ERR: getDistanceToIsoObject: no x/y or no currentPosition "..tostring(x).."/"..tostring(y).." "..tostring(self.currentPosition)) return end

	local a = x - Vector3GetX(self.currentPosition)
	local b = y - Vector3GetY(self.currentPosition)

	return math.sqrt((a*a)+(b*b))
end


---@param vector Vector3
---@return number
function eHelicopter:getDistanceToVector(vector)
	if not vector then print("ERR: getDistanceToVector: no vector or no currentPosition") return end
	return self:getDistanceToXY(Vector3GetX(vector),Vector3GetY(vector))
end


---@param object IsoObject
---@return number
function eHelicopter:getDistanceToIsoObject(object)
	if not object then print("ERR: getDistanceToIsoObject: no object or no currentPosition") return end
	if not object.getX or not object.getY then print("ERR: getDistanceToIsoObject: "..tostring(object).." does not have getX/getY") return end
	return self:getDistanceToXY(object:getX(),object:getY())
end


---@param movement Vector3
---@return Vector3
function eHelicopter:dampen(movement)
	if self.state == "crashed" or self.state == "unLaunched" then
		return
	end
	self:setTargetPos()

	if not self.targetPosition or not self.preflightDistance then
		return movement
	end

	--finds the fraction of distance to target and preflight distance to target
	local distanceCompare = self:getDistanceToVector(self.targetPosition) / self.preflightDistance
	--clamp with a max of self.topSpeedFactor and min of 0.1 (10%) is applied to the fraction
	local dampenFactor = math.max(self.topSpeedFactor, math.min(0.025, distanceCompare))
	--this will slow-down/speed-up eHelicopter the closer/farther it is to the target
	local x_movement = Vector3GetX(movement) * dampenFactor
	local y_movement = Vector3GetY(movement) * dampenFactor

	return movement:set(x_movement,y_movement,self.height)
end


---Sets targetPosition (Vector3) to match target (IsoObject)
function eHelicopter:setTargetPos()
	if not self.target then return end

	local tx, ty, tz = self.target:getX(), self.target:getY(), 0

	if not self.targetPosition then
		self.targetPosition = Vector3.new(tx, ty, tz)
	else
		self.targetPosition:set(tx, ty, tz)
	end
end


---Aim eHelicopter at it's defined target
---@return Vector3
function eHelicopter:aimAtTarget()

	self:setTargetPos()

	if not self.targetPosition or not self.currentPosition then
		return
	end

	local movement_x = Vector3GetX(self.targetPosition) - Vector3GetX(self.currentPosition)
	local movement_y = Vector3GetY(self.targetPosition) - Vector3GetY(self.currentPosition)

	--difference between target's and current's x/y
	---@type Vector3 local_movement
	local local_movement = Vector3.new(movement_x,movement_y,0)
	--normalize (shrink) the difference
	local_movement:normalize()
	--multiply the difference based on speed
	local_movement:setLength(self.speed)

	return local_movement
end


---@param heliX number
---@param heliY number
function eHelicopter:updatePosition(heliX, heliY)
	--The actual movement occurs here when the modified `velocity` is added to `self.currentPosition`
	if self.currentPosition then self.currentPosition:set(heliX, heliY, self.height) end
	eventSoundHandler:updatePos(self,heliX,heliY)
end


---@param re_aim boolean recalculate angle to target
---@param dampen boolean adjust speed based on distance to target
function eHelicopter:move(re_aim, dampen)
	if self.state == "crashed" or self.state == "unLaunched" then return end

	---@type Vector3
	local velocity

	if not self.lastMovement then re_aim = true end

	local storedSpeed = self.speed
	--if there's targets
	if #self.hostilesToFireOn > 3 then
		--slow speed down while shooting
		self.speed = math.max(self.speed*0.5, self.speed/#self.hostilesToFireOn)
	end

	if re_aim then
		velocity = self:aimAtTarget()

		if not self.lastMovement then
			self.lastMovement = Vector3.new(velocity)
		else
			self.lastMovement:set(velocity)
		end

	else
		velocity = self.lastMovement:clone()
	end

	if dampen then velocity = self:dampen(velocity) end

	--restore speed
	self.speed = storedSpeed

	--account for sped up time
	local timeSpeed = math.max(1, getGameSpeed())

	local v_x = Vector3GetX(self.currentPosition)+(Vector3GetX(velocity)*timeSpeed)
	local v_y = Vector3GetY(self.currentPosition)+(Vector3GetY(velocity)*timeSpeed)

	self:updatePosition(v_x, v_y)

	for heli,offsets in pairs(self.formationFollowingHelis) do
		---@type eHelicopter
		local followingHeli = heli
		if followingHeli then followingHeli:updatePosition(v_x+offsets[1], v_y+offsets[2]) end
	end
	--self:Report(re_aim, dampen)
end


---@param character IsoGameCharacter
function eHelicopter:findAlternativeTarget(character)
	if not character then
		return false
	end
	local newTargets = {}
	local fractalCenters = getIsoRange(character, 1, 50)

	for _,square in pairs(fractalCenters) do
		---@type IsoCell
		local cellOfFC = square:getCell()
		if cellOfFC then
			---target zombies instead
			if #newTargets <= 0 then
				local zombies = cellOfFC:getZombieList()
				if zombies then
					local zombiesSize = zombies:size()-1
					if zombiesSize > 0 then
						table.insert(newTargets,zombies:get(ZombRand(zombiesSize)))
					end
				end
			end
		end
	end

	if (#newTargets > 0) then
		local newTarget = newTargets[ZombRand(#newTargets)+1]
		return newTarget
	end

	local x, y = character:getX(), character:getY()

	local xOffset = ZombRand(55,80)
	local yOffset = ZombRand(55,80)

	if ZombRand(101) <= 50 then yOffset=0-yOffset end
	if ZombRand(101) <= 50 then yOffset=0-yOffset end

	local square = getSquare(x+xOffset, y+yOffset, 0) or pseudoSquare:new(x+xOffset, y+yOffset, 0)
	if square then return square end

	return false
end


local heatMap = require "ExpandedHelicopter_HeatMap"
---@param range number
function eHelicopter:findTarget(range, DEBUGID)

	local weightedTargetList = {}
	local maxWeight = 15

	local targetPool = {}

	heatMap.sortCellsByHeat()
	local cellsSize = #heatMap.cellsIDs
	for i=1, #heatMap.cellsIDs do
		local heatCell = heatMap.cells[heatMap.cellsIDs[i]]
		---weigh list by hottest to coldest
		local cSquare = getSquare(heatCell.centerX,heatCell.centerY,0) or pseudoSquare:new(heatCell.centerX, heatCell.centerY, 0)
		if cSquare and ( (not range) or (range and self:getDistanceToIsoObject(cSquare) <= range) ) then
			for n=0, (cellsSize-i)+1 do table.insert(targetPool, cSquare) end
		end
	end

	if #targetPool <= 0 then
		addActualPlayersToEIP()
		for player,_ in pairs(EHEIsoPlayers) do if player then table.insert(targetPool, player) end end
	end
	
	for _,flare in pairs(flareSystem.activeObjects) do
		if flare then
			local flareSquare = flareSystem.getFlareOuterMostSquare(flare)
			if flareSquare then
				table.insert(targetPool, flareSquare)
			end
		end
	end

	for _,target in pairs(targetPool) do
		---@type IsoPlayer|IsoGameCharacter|IsoMovingObject|InventoryItem|IsoWorldInventoryObject
		local p = target
		--[DEBUG]] print(" -- EHE: Potential Target:".." = "..tostring(p))
		if p and ((not range) or (self:getDistanceToIsoObject(p) <= range)) then

			local iterations = 7
			---@type IsoGridSquare
			local pSquare

			if instanceof(p, "IsoGridSquare") then pSquare = p end

			local hottestCell = heatMap.getHottestCell()
			if not hottestCell and instanceof(p, "IsoPlayer") then pSquare = p:getSquare() end

			if pSquare then
				local zone = pSquare:getZone()
				--[[DEBUG]] local DEBUGzoneID = "<none>"
				if zone then
					local zoneType = zone:getType()
					if zoneType then
						--[[DEBUG]] DEBUGzoneID = zoneType
						if (zoneType == "DeepForest") then
							iterations = 3
						elseif (zoneType == "Forest" or zoneType == "Vegitation") then
							iterations = 4
						elseif (zoneType == "FarmLand") then
							iterations = 5
						elseif (zoneType == "Farm") then
							iterations = 6
						elseif (zoneType == "TrailerPark" or zoneType == "Nav") then
							iterations = 9
						elseif (zoneType == "TownZone") then
							iterations = 10
						end
					end
				end

				if instanceof(p, "IsoPlayer") then
					local pCar = p:getVehicle()
					if p:isOutside() and (not pCar or (pCar and pCar:getCurrentSpeedKmHour()>0)) then iterations = math.floor(iterations*1.3) end
					if pCar and pCar:getCurrentSpeedKmHour()>0 then iterations = math.floor(iterations*(1+(pCar:getCurrentSpeedKmHour()/100))) end
					local targetSquare = p:getSquare()
					if (targetSquare:getTree()) then iterations = math.floor(iterations*0.66) end
				end

				if flareSystem.activeObjects[p] then
					if pSquare:isOutside() then
						iterations = iterations*5
					else
						iterations = 0
					end
				end

				for _=1, maxWeight do
					if iterations > 0 then
						iterations = iterations-1
						table.insert(weightedTargetList, p)
					else
						local altTarget = self:findAlternativeTarget(pSquare)
						if altTarget then
							table.insert(weightedTargetList, altTarget)
						else
							print(" -- WARN: Unable to find altTarget.")
						end
					end
				end
			end
		end
	end

	if DEBUGID then DEBUGID = "["..DEBUGID.."]: " end
	local DEBUGallTargetsText = " -- "..DEBUGID.."HELI "..self:heliToString().." selecting targets <"..#weightedTargetList.."> x "

	--really convoluted printout method that counts repeated targets accordingly
	--[[DEBUG] if getDebug() then
		local DEBUGallTargets = {}
		for _,target in pairs(weightPlayersList) do
			if instanceof(target, "IsoPlayer") then
				local knownTarget =  DEBUGallTargets[target:getFullName()]
				if knownTarget then DEBUGallTargets[target:getFullName()] = DEBUGallTargets[target:getFullName()]+1
				else DEBUGallTargets[target:getFullName()] = 1 end
			elseif instanceof(target, "IsoZombie") then
				local zombieAlreadyTargeted = DEBUGallTargets["z"]
				if zombieAlreadyTargeted then DEBUGallTargets["z"] = DEBUGallTargets["z"]+1
				else DEBUGallTargets["z"] = 1 end
			else
				local unknownTarget =  DEBUGallTargets[tostring(target)]
				if unknownTarget then DEBUGallTargets[tostring(target)] = DEBUGallTargets[tostring(target)]+1
				else DEBUGallTargets[tostring(target)] = 1 end
			end
		end

		for targetID,numberOf in pairs(DEBUGallTargets) do
			DEBUGallTargetsText = DEBUGallTargetsText.."["..targetID.." x"..numberOf.."] "
		end

	end --]]

	print(DEBUGallTargetsText)

	local target
	if #weightedTargetList then target = weightedTargetList[ZombRand(1, #weightedTargetList+1)] end

	if not target then
		print(" --- HELI "..self:heliToString().." - WARN: unable to find target...")
		target = self:grabRandomSquareNearby(range)
		if not target and self~=eHelicopter then
			self:goHome()
			print(" ------ HELI "..self:heliToString().." - ERROR: unable to find square: going home.")
			return
		end
	end

	return target
end


---@param range number
function eHelicopter:grabRandomSquareNearby(range)
	range = range or 25
	local x,y,z = self:getXYZAsInt()

	if not x or not y or not z then
		return
	end

	local xShift = ZombRand(range/2, range+1)+1
	local yShift = ZombRand(range/2, range+1)+1

	if ZombRand(101) >= 50 then
		xShift = 0-xShift
	end
	if ZombRand(101) >= 50 then
		yShift = 0-yShift
	end

	local square =  getSquare(x+xShift,y+yShift, 0) or pseudoSquare:new(x+xShift, y+yShift, 0)

	return square
end


function eHelicopter:formationInit()

	if not self.formationIDs then
		return
	end

	local h_x, h_y, _ = self:getXYZAsInt()

	local formationSize = 0
	--parse formationIDs for formation info, strings are IDs, following numbers are assumed values -- use false for skipped values
	for key,value in pairs(self.formationIDs) do

		if (type(value) == "string") and eHelicopter_PRESETS[value] then

			--The chance this extra heli is spawned
			local chance = self.formationIDs[key+1] or 100
			--If the next entry in the list is a number consider it to be a chance, otherwise use 100%
			if type(chance) ~= "number" then
				chance = 100
			end

			local xyPosOffset = self.formationIDs[key+2] or {6, 12}
			--checks if entry 2 spaces after string (ID) is a table,
			if ((type(xyPosOffset) ~= "table")) or (#xyPosOffset < 2) or ((type(xyPosOffset[1]) ~= "number")) or ((type(xyPosOffset[2]) ~= "number")) then
				--fills in offsets is not enough or incorrect entries are present
				xyPosOffset = {6, 12}
			end

			--if new heli is spawned
			if (ZombRand(101) <= chance) then
				--track formation's current size
				formationSize = formationSize+1
				--multiply offset by formation size
				local heliX = ZombRand(xyPosOffset[1]*formationSize,xyPosOffset[2]*formationSize)
				local heliY = ZombRand(xyPosOffset[1]*formationSize,xyPosOffset[2]*formationSize)

				if (ZombRand(101) <= 50) then
					heliX = 0-heliX
				end
				if (ZombRand(101) <= 50) then
					heliY = 0-heliY
				end
				
				local newHeli = getFreeHelicopter(value)
				newHeli.state = "following"
				newHeli.currentPosition = newHeli.currentPosition or Vector3.new()
				newHeli.currentPosition:set(h_x, h_y, newHeli.height)
				self.formationFollowingHelis[newHeli] = {heliX,heliY}
			end

		end
	end
end


function fetchStartDayAndCutOffDay(HelicopterOrPreset)
	local startDayFactor = HelicopterOrPreset.eventStartDayFactor or eHelicopter.eventStartDayFactor
	local startDay = math.floor((startDayFactor*SandboxVars.ExpandedHeli.SchedulerDuration)+0.5)
	startDay = math.max(startDay, SandboxVars.ExpandedHeli.StartDay)
	local cutOffDayFactor = HelicopterOrPreset.eventCutOffDayFactor or eHelicopter.eventCutOffDayFactor
	local cutOffDay = math.floor((cutOffDayFactor*(startDay+SandboxVars.ExpandedHeli.SchedulerDuration))+0.5)
	return startDay, cutOffDay
end


function eHelicopter:applyCrashChance(applyEnvironmentalCrashChance)
	local globalModData = getExpandedHeliEventsModData()
	--increase crash chance as the apocalypse goes on
	local startDay, cutOffDay = fetchStartDayAndCutOffDay(self)
	local eventFrequency = SandboxVars.ExpandedHeli["Frequency_"..self.masterPresetID] or 2

	--[DEBUG]] print("EHE: DEBUG: Crash Chance Freq: "..self.masterPresetID)

	if not cutOffDay then
		return
	end

	local crashChance = self.addedCrashChance
	applyEnvironmentalCrashChance = applyEnvironmentalCrashChance or true

	if applyEnvironmentalCrashChance then
		local _, weatherImpact = eHeliEvent_weatherImpact()
		local daysIntoApoc = globalModData.DaysBeforeApoc+getGameTime():getNightsSurvived()
		local apocImpact = (daysIntoApoc/cutOffDay)/20
		local dayOfLastCrash = globalModData.DayOfLastCrash
		local crashDayCap = 28
		local daysSinceCrashImpact = ((getGameTime():getNightsSurvived()-dayOfLastCrash)/crashDayCap)/2

		crashChance = self.addedCrashChance+((weatherImpact+apocImpact+daysSinceCrashImpact)*100)
		crashChance = math.min(100,math.floor(crashChance))
		crashChance = crashChance/(eventFrequency/3)

		--[DEBUG]] print(" ---- cutOffDay:"..cutOffDay.." | daysIntoApoc:"..daysIntoApoc .. " | apocImpact:"..apocImpact.." | weatherImpact:"..weatherImpact)
		--[DEBUG]] print(" ---- dayOfLastCrash:"..dayOfLastCrash.." | daysSinceCrashImpact:"..math.floor(daysSinceCrashImpact))
	end

	local crashChanceMulti = SandboxVars.ExpandedHeli.CrashChanceMulti or 1
	crashChance = crashChance * crashChanceMulti

	if self.crashType and (not self.crashing) and (ZombRand(0,501) <= crashChance) then
		self.crashing = true
	end
	----[[DEBUG]] print(" --- "..self:heliToString().." crashChance:"..crashChance.." crashing:"..tostring(self.crashing))
end


function eHelicopter:playFlightSounds()

	eventSoundHandler:playEventSound(self,"flightSound", nil, true)

	if self.squareOfOrigin then eventSoundHandler:playEventSound(self,"soundAtEventOrigin", self.squareOfOrigin, true, false) end

	if self.formationFollowingHelis then
		for heli,_ in pairs(self.formationFollowingHelis) do
			---@type eHelicopter
			local followingHeli = heli
			if followingHeli then
				local randSoundDelay = ZombRand(5,15)
				if self.squareOfOrigin then
					eventSoundHandler:playEventSound(followingHeli, "soundAtEventOrigin", self.squareOfOrigin, true, false, randSoundDelay)
				end
				eventSoundHandler:playEventSound(followingHeli, "flightSound", nil, true, false, randSoundDelay)
			end
		end
	end
end
																																																							local function eHelicopter_check() local m, lCF = nil, getCoroutineCallframeStack(getCurrentCoroutine(),0) local fD = lCF ~= nil and lCF and getFilenameOfCallframe(lCF) m = fD and getModInfo(fD:match("(.-)media/")) local wID, mID = m and m:getWorkshopID(), m and m:getId() if wID then local workshopIDHashed, expected = "", "fhiljgegji" for i=1, #wID do workshopIDHashed=workshopIDHashed..string.char(wID:sub(i,i)+100) end if expected~=workshopIDHashed then if isClient() then getCore():quitToDesktop() else toggleModActive(m, false) end EHE_VERSION_CHECK = {wID, mID} end end end Events.OnGameBoot.Add(eHelicopter_check)

---@param targetedObject IsoGridSquare | IsoMovingObject | IsoPlayer | IsoGameCharacter random player if blank
function eHelicopter:launch(targetedObject,blockCrashing)

	if not self.attackDistance then self.attackDistance = ((self.attackScope*2)+1)*((self.attackSpread*2)+1) end

	if not targetedObject then
		targetedObject = self:findTarget(nil, "launch")
		self.target = targetedObject
	else
		--sets target to a square near the player so that the heli doesn't necessarily head straight for the player
		local targetOffset = 75
		local tpX = targetedObject:getX()+ZombRand(0-targetOffset,targetOffset)
		local tpY = targetedObject:getY()+ZombRand(0-targetOffset,targetOffset)
		local square = getSquare(tpX, tpY, 0) or pseudoSquare:new(tpX, tpY, 0)
		if square then self.target = square end
		--self.target = pseudoSquare:new(tpX, tpY, 0)
	end

	if targetedObject then
		local info = instanceof(targetedObject, "IsoGameCharacter") and (targetedObject:getFullName()) or (targetedObject:getX()..", "..targetedObject:getY())
		print(" -- Target: "..tostring(targetedObject)..": "..info)
	end

	--maintain trueTarget
	self.trueTarget = targetedObject
	--setTargetPos is a vector format of self.target
	self:setTargetPos()

	self:initPos(self.target, self.randomEdgeStart)
	self.preflightDistance = self:getDistanceToVector(self.targetPosition)

	--TODO: Confirm formations work in MP
	--self:formationInit()
	self.squareOfOrigin = self:getIsoGridOrPseudoSquare()
	self:playFlightSounds()
	
	if self.hoverOnTargetDuration and type(self.hoverOnTargetDuration) == "table" then
		if #self.hoverOnTargetDuration >= 2 then
			self.hoverOnTargetDuration = ZombRand(self.hoverOnTargetDuration[1],self.hoverOnTargetDuration[2])
		else
			print("EHE: ERROR: "..self:heliToString().." -- hoverOnTargetDuration is table with less than 2 entries - nulling hover time.")
			self.hoverOnTargetDuration = false
		end
	end

	if self.announcerVoice ~= false then
		self:chooseVoice(self.announcerVoice)
	end

	self.state = "gotoTarget"

	if not blockCrashing then
		self:applyCrashChance()
	end

	for heli,_ in pairs(self.formationFollowingHelis) do
		---@type eHelicopter
		local followingHeli = heli
		if followingHeli then
			followingHeli.attackDistance = self.attackDistance
			if not blockCrashing then
				followingHeli:applyCrashChance()
			end
		end
	end

	local GT = getGameTime()
	local DAY = GT:getNightsSurvived()
	local HOUR = GT:getHour()

	HOUR = HOUR+2
	if HOUR > 24 then
		HOUR = HOUR-24
		DAY = DAY+1
	end

	self.forceUnlaunchTime = {DAY, HOUR}

	if self.addedFunctionsToEvents then
		local eventFunction = self.addedFunctionsToEvents["OnLaunch"]
		if eventFunction then eventFunction(self) end
	end

	print(" -- EHE: LAUNCH: "..self:heliToString()..
			" day:"..getGameTime():getNightsSurvived()..
			" hour:"..getGameTime():getHour()..
			" crashing:"..tostring(self.crashing))
end


---Heli goes home
function eHelicopter:goHome()
	self.state = "goHome"
	self.hoverOnTargetDuration = 0

	local selfSquare = self:getIsoGridOrPseudoSquare()

	if not selfSquare then
		print(" --- HELI "..self:heliToString()..": unable to go home; unlaunching.")
		self:unlaunch()
		return
	end

	--set truTarget to target's current location -- this prevents changing course while flying away
	self.trueTarget = selfSquare
	self.target = selfSquare
	self:setTargetPos()
	print(" --- HELI "..self:heliToString()..": setting fixed course.")
	return selfSquare
end


function eHelicopter:unlaunch()
	if self.state == "unLaunched" then return end

	print(" ---- UN-LAUNCH: "..self:heliToString(true).." day:"..getGameTime():getNightsSurvived().." hour:"..getGameTime():getHour())

	self:updatePosition(-10000, -10000)
	eventSoundHandler:stopAllHeldEventSounds(self)

	if self.shadow==true then
		local x, y, z = self:getXYZAsInt()
		eventShadowHandler:setShadowPos(self.ID, nil, x, y, z)
	end
	if self.eventMarkerIcon ~= false then
		eventMarkerHandler.setOrUpdate("HELI"..self.ID, self.eventMarkerIcon, 0)
	end

	self.state = "unLaunched"

	for heli,_ in pairs(self.formationFollowingHelis) do
		---@type eHelicopter
		local followingHeli = heli
		if followingHeli then
			followingHeli:unlaunch()
		end
	end
end


