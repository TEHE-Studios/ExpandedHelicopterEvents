--GLOBAL_VARIABLES
MAX_XY = 15000
MIN_XY = 2500
ALL_HELICOPTERS = {}

---@class eHelicopter
eHelicopter = {}

---@field hoverOnTargetDuration number|boolean How long the helicopter will hover over the player, this is subtracted from every tick
eHelicopter.hoverOnTargetDuration = false

---@field searchForTargetDurationMS number How long the helicopter will search for last seen targets
eHelicopter.searchForTargetDuration = 30000

---@field shadow boolean | WorldMarkers.GridSquareMarker
eHelicopter.shadow = true

---@field crashType boolean
eHelicopter.crashType = {"UH1HCrash"}

---@field crew table list of IDs and chances (similar to how loot distribution is handled)
---Example: crew = {"pilot", 100, "crew", 75, "crew", 50}
---If there is no number following a string a chance of 100% will be applied.
eHelicopter.crew = {"AirCrew", 100}

---@field dropItems table
eHelicopter.dropItems = false

---@field dropPackages table
eHelicopter.dropPackages = false

---@field eventSoundEffects table
eHelicopter.eventSoundEffects = {--{["hoverOverTarget"]=nil,["flyOverTarget"]=nil}
	["attackSingle"] = "eHeli_machine_gun_fire_singleshot",
	["attackLooped"] = "eHeli_machine_gun_fire_looped",
	["attackImpacts"] = {"eHeli_fire_impact1", "eHeli_fire_impact2", "eHeli_fire_impact3",  "eHeli_fire_impact4", "eHeli_fire_impact5"}
	}

---@field announcerVoice string
eHelicopter.announcerVoice = false

---@field randomEdgeStart boolean
eHelicopter.randomEdgeStart = false

---@field presetProgression table Table of presetIDs and corresponding % preset is switched to (compared to Days/CuttOffDay)
eHelicopter.presetProgression = false

---@field frequencyFactor number This is multiplied against the min/max day range; less than 1 results in higher frequency, more than 1 results in less frequency
eHelicopter.frequencyFactor = 1

---@field startDayMinMax table two numbers: min and max start day can be
eHelicopter.startDayMinMax = {0,1}

---@field cutOffFactor number This is multiplied against eHelicopterSandbox.config.cutOffDay
eHelicopter.cutOffFactor = 1

---@field speed number
eHelicopter.speed = 0.15

---@field topSpeedFactor number speed x this = top "speed"
eHelicopter.topSpeedFactor = 3

---@field flightSound string sound to loop during flight
eHelicopter.flightSound = "eHelicopter"

---@field flightVolume number
eHelicopter.flightVolume = 50

---@field hostilePreference string
---set to 'false' for *none*, otherwise has to be 'IsoPlayer' or 'IsoZombie' or 'IsoGameCharacter'
eHelicopter.hostilePreference = false

---@field attackDelay number delay in milliseconds between attacks
eHelicopter.attackDelay = 55

---@field attackScope number number of rows from "center" IsoGridSquare out
--- **area formula:** ((Scope*2)+1) ^2
---
--- scope:⠀0=1x1;⠀1=3x3;⠀2=5x5;⠀3=7x7;⠀4=9x9
eHelicopter.attackScope = 1

---@field attackSpread number number of rows made of "scopes" from center-scope out
---**formula for ScopeSpread area:**
---
---((Scope * 2)+1) * ((Spread * 2)+1) ^2
---
--- **Examples:**
---
---⠀  ⠀*scope* 🡇
--- -----------------------------------
--- *spread*⠀🡆 ⠀ | 00 | 01 | 02 | 03 |
--- -----------------------------------
--- ⠀  ⠀⠀⠀ ⠀| 00 | 01 | 09 | 25 | 49 |
--- -----------------------------------
--- ⠀  ⠀⠀⠀ ⠀| 01 | 09 | 81 | 225 | 441 |
--- -----------------------------------
--- ⠀  ⠀⠀⠀⠀  | 02 | 25 | 225 | 625 | 1225 |
--- -----------------------------------
--- ⠀  ⠀⠀⠀  ⠀| 03 | 49 | 441 | 1225 | 2401 |
--- -----------------------------------
eHelicopter.attackSpread = 3


---// UNDER THE HOOD STUFF //---

---This function, when called stores the above listed variables, on game load, for reference later
---
---NOTE: Any variable which is by default `nil` can't be loaded over - consider making it false if you need it
---@param listToSaveTo table
---@param checkIfNotIn table
function eHelicopter_variableBackUp(listToSaveTo, checkIfNotIn)--, debugID)
	for k,v in pairs(eHelicopter) do
		if ((not checkIfNotIn) or (checkIfNotIn[k] == nil)) then
			--[DEBUG]] print("EHE: "..debugID..": "..k.." = ".."("..type(v)..") "..tostring(v))
			--tables have to be copied piece by piece or risk creating a direct reference link
			if type(v) == "table" then
				--[DEBUG]] print("--- "..k.." is a table (#"..#v.."); generating copy:")
				local tmpTable = {}
				for kk,vv in pairs(v) do
					--[DEBUG]] print( "------ "..kk.." = ".."("..type(vv)..") "..tostring(vv))
					tmpTable[kk] = vv
				end
				listToSaveTo[k]=tmpTable
			else
				listToSaveTo[k]=v
			end
		end
	end
end

--store "initial" vars to reference when loading presets
eHelicopter_initialVars = {}
eHelicopter_variableBackUp(eHelicopter_initialVars, nil, "initialVars")

--the below variables are to be considered "temporary"
---@field height number
eHelicopter.height = 7
---@field state string
eHelicopter.state = false
---@field crashing
eHelicopter.crashing = false
---@field rotorEmitter FMODSoundEmitter | BaseSoundEmitter
eHelicopter.rotorEmitter = false
---@field timeUntilCanAnnounce number
eHelicopter.timeUntilCanAnnounce = -1
---@field preflightDistance number
eHelicopter.preflightDistance = false
---@field announceEmitter FMODSoundEmitter | BaseSoundEmitter
eHelicopter.announceEmitter = false
---@field eventSoundEffectEmitters table
eHelicopter.eventSoundEffectEmitters = {}
---@field target IsoObject
eHelicopter.target = false
---@field trueTarget IsoGameCharacter
eHelicopter.trueTarget = false
---@field timeSinceLastSeenTarget number
eHelicopter.timeSinceLastSeenTarget = -1
---@field timeSinceLastRoamed number
eHelicopter.timeSinceLastRoamed = -1
---@field attackDistance number
eHelicopter.attackDistance = false
---@field targetPosition Vector3 "position" of target, pair of coordinates which can utilize Vector3 math
eHelicopter.targetPosition = false
---@field lastMovement Vector3 consider this to be velocity (direction/angle and speed/step-size)
eHelicopter.lastMovement = false
---@field currentPosition Vector3 consider this a pair of coordinates which can utilize Vector3 math
eHelicopter.currentPosition = false
---@field lastAttackTime number
eHelicopter.lastAttackTime = -1
---@field hostilesToFireOnIndex number
eHelicopter.hostilesToFireOnIndex = 0
---@field hostilesToFireOn table
eHelicopter.hostilesToFireOn = {}
---@field hostilesAlreadyFiredOn table
eHelicopter.hostilesAlreadyFiredOn = {}
---@field lastScanTime number
eHelicopter.lastScanTime = -1
---@field shadowBobRate number
eHelicopter.shadowBobRate = 0.05
---@field timeSinceLastShadowBob number
eHelicopter.timeSinceLastShadowBob = -1

--This stores the above "temporary" variables for resetting eHelicopters later
eHelicopter_temporaryVariables = {}
eHelicopter_variableBackUp(eHelicopter_temporaryVariables, eHelicopter_initialVars, "temporaryVariables")

--ID must not be reset ever
---@field ID number
eHelicopter.ID = 0


---@param event string
---@param otherLocation IsoGridSquare
---@param saveEmitter boolean
---@param stopSound boolean
function eHelicopter:playEventSound(event, otherLocation, saveEmitter, stopSound)

	local soundEffect = self.eventSoundEffects[event]

	if not soundEffect then
		return
	end

	if type(soundEffect)=="table" then
		soundEffect = soundEffect[ZombRand(1,#soundEffect+1)]
	end

	---@type FMODSoundEmitter | BaseSoundEmitter emitter
	local soundEmitter = self.eventSoundEffectEmitters[event]

	if stopSound and soundEmitter then
		soundEmitter:stopSoundByName(soundEffect)
		return
	end
	
	--if otherlocation provided use it; if not use self
	otherLocation = otherLocation or self:getIsoGridSquare()

	if not soundEmitter then
		soundEmitter = getWorld():getFreeEmitter()
		if saveEmitter then
			self.eventSoundEffectEmitters[event] = soundEmitter
		end
	elseif soundEmitter:isPlaying(soundEffect) then
		return
	end
	soundEmitter:playSound(soundEffect, otherLocation)
end


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
	for _,h in ipairs(ALL_HELICOPTERS) do
		if h.state == "unLaunched" then
			heli = h
			break
		end
	end

	if not heli then
		heli = eHelicopter:new()
	end
	
	if preset then
		heli:loadPreset(preset)
	end
	
	return heli
end


---These is the equivalent of getters for Vector3
--tostring output of a Vector3: "Vector2 (X: %f, Y: %f) (L: %f, D:%f)"
---@param ShmectorTree Vector3
---@return float x of ShmectorTree
function Vector3GetX(ShmectorTree)
	return string.match(tostring(ShmectorTree), "%(X%: (.-)%, Y%: ")
end


---@param ShmectorTree Vector3
---@return float y of ShmectorTree
function Vector3GetY(ShmectorTree)
	return string.match(tostring(ShmectorTree), "%, Y%: (.-)%) %(")
end


---Initialize Position
---@param targetedPlayer IsoMovingObject | IsoPlayer | IsoGameCharacter
---@param randomEdge boolean true = uses random edge, false = prefers closer edge
function eHelicopter:initPos(targetedPlayer, randomEdge)

	--player's location
	local tpX = targetedPlayer:getX()
	local tpY = targetedPlayer:getY()

	--assign a random spawn point for the helicopter within a radius from the player
	--these values are being clamped to not go passed MIN_XY/MAX edges
	local offset = 500
	local initX = ZombRand(math.max(MIN_XY, tpX-offset), math.min(MAX_XY, tpX+offset))
	local initY = ZombRand(math.max(MIN_XY, tpY-offset), math.min(MAX_XY, tpY+offset))

	if not self.currentPosition then
		self.currentPosition = Vector3.new()
	end

	if randomEdge then
		
		local initPosXY = {initX, initY}
		local randEdge = {MIN_XY, MAX_XY}
		
		--randEdge stops being a list and becomes a random part of itself
		randEdge = randEdge[ZombRand(1,#randEdge+1)]
		
		--this takes either initX/initY (within initPosXY) and makes it either MIN_XY/MAX (randEdge)
		initPosXY[ZombRand(1, #initPosXY+1)] = randEdge
		
		self.currentPosition:set(initPosXY[1], initPosXY[2], self.height)
		
		return
	end
	
	--Looks for the closest edge to initX and initY to modify it to be along either MIN_XY/MAX_XY
	--differences between initX and MIN_XY/MAX_XY edge values
	local xDiffToMin = math.abs(initX-MIN_XY)
	local xDiffToMax = math.abs(initX-MAX_XY)
	local yDiffToMin = math.abs(initY-MIN_XY)
	local yDiffToMax = math.abs(initY-MAX_XY)
	--this list uses x/yDifftoMin/Max's values as keys storing their respective corresponding edges
	local xyDiffCorrespondingEdge = {[xDiffToMin]=MIN_XY, [xDiffToMax]=MAX_XY, [yDiffToMin]=MIN_XY, [yDiffToMax]=MAX_XY}
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
	local ehX = math.floor(Vector3GetX(self.currentPosition) + 0.5)
	local ehY = math.floor(Vector3GetY(self.currentPosition) + 0.5)
	local ehZ = self.height

	return ehX, ehY, ehZ
end


---@return IsoGridSquare of eHelicopter
function eHelicopter:getIsoGridSquare()
	local ehX, ehY, _ = self:getXYZAsInt()
	local square = getCell():getOrCreateGridSquare(ehX, ehY, 0)
	return square
end


---@return boolean
function eHelicopter:isInBounds()
	local h_x, h_y, _ = self:getXYZAsInt()

	if h_x <= MAX_XY and h_x >= MIN_XY and h_y <= MAX_XY and h_y >= MIN_XY then
		return true
	end

	return false
end


---@param vector Vector3
---@return number
function eHelicopter:getDistanceToVector(vector)

	local a = Vector3GetX(vector) - Vector3GetX(self.currentPosition)
	local b = Vector3GetY(vector) - Vector3GetY(self.currentPosition)

	return math.sqrt((a*a)+(b*b))
end


---@param object IsoObject
---@return number
function eHelicopter:getDistanceToIsoObject(object)
	if not object then
		return
	end

	local a = object:getX() - Vector3GetX(self.currentPosition)
	local b = object:getY() - Vector3GetY(self.currentPosition)

	return math.sqrt((a*a)+(b*b))
end


---@param movement Vector3
---@return Vector3
function eHelicopter:dampen(movement)
	self:setTargetPos()
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
	if not self.target then
		return
	end
	local tx, ty, tz = self.target:getX(), self.target:getY(), self.height

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


---@param re_aim boolean recalculate angle to target
---@param dampen boolean adjust speed based on distance to target
function eHelicopter:move(re_aim, dampen)

	---@type Vector3
	local velocity

	if not self.lastMovement then
		re_aim = true
	end

	local storedSpeed = self.speed
	--if there's more than 5 targets
	if #self.hostilesToFireOn > 5 then
		--slow speed down while shooting
		self.speed = self.speed/2
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

	if dampen then
		velocity = self:dampen(velocity)
	end

	--restore speed
	self.speed = storedSpeed

	--account for sped up time
	local timeSpeed = getGameSpeed()
	local v_x = Vector3GetX(self.currentPosition)+(Vector3GetX(velocity)*timeSpeed)
	local v_y = Vector3GetY(self.currentPosition)+(Vector3GetY(velocity)*timeSpeed)
	--The actual movement occurs here when the modified `velocity` is added to `self.currentPosition`
	self.currentPosition:set(v_x, v_y, self.height)
	--Move emitter to position
	self.rotorEmitter:setPos(v_x,v_y,self.height)

	--self:Report(re_aim, dampen)
end


---@param range number
function eHelicopter:findTarget(range)
	--the -1 is to offset playerIDs starting at 0
	local weightPlayersList = {}
	local numActivePlayers = getNumActivePlayers()-1

	for i=0, numActivePlayers do
		---@type IsoGameCharacter p
		local p = getSpecificPlayer(i)

		if p and ((not range) or (self:getDistanceToIsoObject(p) <= range)) then
			local iterations = 3

			local zone = p:getCurrentZone()
			if zone then
				local zoneType = zone:getType()
				if zoneType and (zoneType == "Forest") or (zoneType == "DeepForest") then
					iterations = 1
				end
			end

			for _=1, iterations do
				table.insert(weightPlayersList, p)
			end
		end
	end

	local target

	if #weightPlayersList then
		target = weightPlayersList[ZombRand(1, #weightPlayersList+1)]
	end

	return target
end


---@param targetedPlayer IsoMovingObject | IsoPlayer | IsoGameCharacter random player if blank
function eHelicopter:launch(targetedPlayer)

	if not targetedPlayer then
		targetedPlayer = self:findTarget()
	end
	--sets target to targetedPlayer's square so that the heli doesn't necessarily head straight for the player 
	self.target = targetedPlayer:getSquare()
	--maintain trueTarget
	self.trueTarget = targetedPlayer
	--setTargetPos is a vector format of self.target
	self:setTargetPos()
	
	self:initPos(self.target,self.randomEdgeStart)
	self.preflightDistance = self:getDistanceToVector(self.targetPosition)
	self.rotorEmitter = getWorld():getFreeEmitter()

	local ehX, ehY, ehZ = self:getXYZAsInt()

	self.rotorEmitter:playSound(self.flightSound, ehX, ehY, ehZ)

	if self.hoverOnTargetDuration and type(self.hoverOnTargetDuration) == "table" then
		if #self.hoverOnTargetDuration >= 2 then
			self.hoverOnTargetDuration = ZombRand(self.hoverOnTargetDuration[1],self.hoverOnTargetDuration[2])
		else
			self.hoverOnTargetDuration = false
		end
	end

	if not self.attackDistance then
		self.attackDistance = ((self.attackScope*2)+1)*((self.attackSpread*2)+1)
	end

	if self.announcerVoice ~= false then
		self:chooseVoice()
	end
	
	self.state = "gotoTarget"

	--weatherImpact is a float, 0 to 1
	local _, weatherImpact = eHeliEvent_weatherImpact()
	
	--increase crash chance as the apocalypse goes on
	local cutOffDay = self.cutOffFactor*eHelicopterSandbox.config.cutOffDay
	local daysIntoApoc = getGameTime():getModData()["DaysBeforeApoc"]+getGameTime():getNightsSurvived()
	--fraction of days over cutoff divided by 4 = max +25% added crashChance
	local apocImpact = (daysIntoApoc/cutOffDay)/4

	local crashChance = (weatherImpact+apocImpact)*100

	if self.crashType and (not self.crashing) and ZombRand(0,100) <= crashChance then
		self.crashing = true
	end
end


---Heli goes home
function eHelicopter:goHome()
	self.state = "goHome"
	--set truTarget to target's current location -- this prevents changing course while flying away
	self.trueTarget = getSquare(self.target:getX(),self.target:getY(),0)
	self.target = self.trueTarget
	self:setTargetPos()
end


--This attempts to get the outside (roof or ground) IsoGridSquare to any X/Y coordinate
---@param square IsoGridSquare
---@return IsoGridSquare
function getOutsideSquare(square)
	if not square then
		return
	end

	if square:isOutside() and square:isSolidFloor() then
		return square
	end

	local x, y = square:getX(), square:getY()
	local cell = square:getCell()

	for i=1, 7 do
		local sq = cell:getOrCreateGridSquare(x, y, i)
		if sq and sq:isOutside() and sq:isSolidFloor() then
			return sq
		end
	end
end


---Heli spawn crew
function eHelicopter:spawnCrew()
	if not self.crew then
		return
	end

	for key,outfitID in pairs(self.crew) do
		
		local chance = self.crew[key+1]
		--if the next entry in the list is a number consider it to be a chance, otherwise use 100%
		if type(chance) ~= "number" then
			chance = 100
		end
		--assume all strings to be outfidID and roll chance/100
		if (type(outfitID) == "string") and (ZombRand(100) <= chance) then
			local heliX, heliY, _ = self:getXYZAsInt()
			--fuzz up the location
			if heliX and heliY then
				heliX = heliX+ZombRand(-3,3)
				heliY = heliY+ZombRand(-3,3)
			end
			
			local bodyLoc = getOutsideSquare(getSquare(heliX, heliY, 0))
			--if there is an actual location - IsoGridSquare may not be loaded in under certain circumstances
			if bodyLoc then
				local spawnedZombies = addZombiesInOutfit(bodyLoc:getX(), bodyLoc:getY(), bodyLoc:getZ(), 1, outfitID, 50)
				---@type IsoGameCharacter | IsoZombie
				local zombie = spawnedZombies:get(0)
				--if there's an actual zombie
				if zombie then
					--33% to be dead on arrival
					if ZombRand(100) <= 33 then
						print("crash spawned: "..outfitID.." killed")
						zombie:setHealth(0)
					else
						--+1 because zombRand starts at 0
						local typeChange = ZombRand(6)+1
						--1/6 chance to be fake dead
						if typeChange == 6 then
							print("crash spawned: "..outfitID.." fakeDead")
							zombie:setFakeDead(true)
						--2/6 chance to be a crawler
						elseif typeChange >= 4 then
							print("crash spawned: "..outfitID.." crawler")
							zombie:setBecomeCrawler(true)
						--3/6 chance for normaltype zombie
						else
							print("crash spawned: "..outfitID)
						end
					end
				end
			end
		end
	end
end


---Heli goes down
function eHelicopter:crash()

	if self.crashType then
		---@type IsoGridSquare
		local selfSquare = self:getIsoGridSquare()
		local currentSquare = getOutsideSquare(selfSquare)

		if currentSquare and currentSquare:isSolidTrans() then
			currentSquare = nil
		end
		--[DEBUG]] print("-- EHE: squares for crashing:  "..tostring(selfSquare).."  "..tostring(currentSquare))
		if currentSquare then
			local vehicleType = self.crashType[ZombRand(1,#self.crashType+1)]
			---@type BaseVehicle
			local heli = addVehicleDebug("Base."..vehicleType, IsoDirections.getRandom(), nil, currentSquare)
			if heli then
				--[DEBUG]] print("---- EHE: CRASH EVENT: "..vehicleType.."  "..currentSquare:getX()..", "..currentSquare:getY()..", "..currentSquare:getZ())
				heli:playSound("HeliCrash")
				addSound(nil, currentSquare:getX(), currentSquare:getY(), 0, 100, 100)
				self:unlaunch()
				self:spawnCrew()
				return true
			end
		end
	end
end


---Heli drop item
function eHelicopter:dropItem(type)

	if self.dropItems then

		local heliX, heliY, _ = self:getXYZAsInt()
		if heliX and heliY then
			heliX = heliX+ZombRand(-3,3)
			heliY = heliY+ZombRand(-3,3)
		end
		local currentSquare = getOutsideSquare(getSquare(heliX, heliY, 0))
		
		if currentSquare and currentSquare:isSolidTrans() then
			currentSquare = nil
		end

		if currentSquare then
			local _ = currentSquare:AddWorldInventoryItem("EHE."..type, 0, 0, 0)
		end
	end
end


---Heli drop carePackage
function eHelicopter:dropCarePackage()

	local carePackage = self.dropPackages[ZombRand(1,#self.dropPackages+1)]
	local selfSquare = self:getIsoGridSquare()
	local currentSquare = getOutsideSquare(selfSquare)

	if currentSquare and currentSquare:isSolidTrans() then
		currentSquare = nil
	end

	if currentSquare then
		--[DEBUG]] print("EHE: "..carePackage.." dropped: "..currentSquare:getX()..", "..currentSquare:getY())
		---@type BaseVehicle airDrop
		local airDrop = addVehicleDebug("Base."..carePackage, IsoDirections.getRandom(), nil, currentSquare)
		if airDrop then
			return airDrop
		end
	end
end


function eHelicopter:update()

	local timeStampMS = getTimestampMs()
	local thatIsCloseEnough = (self.topSpeedFactor*self.speed)*tonumber(getGameSpeed())
	local distanceToTrueTarget = self:getDistanceToIsoObject(self.trueTarget)

	--- __le operation stacktrace tmp test
	if not self.trueTarget then print("EHE: ERR: self.trueTarget") end
	if not distanceToTrueTarget then print("EHE: ERR: distanceToTrueTarget") end
	if not self.attackDistance then print("EHE: ERR: self.attackDistance") end

	--if trueTarget is within range
	if distanceToTrueTarget <= (self.attackDistance*4) then
		--if trueTarget is outside then sync targets
		if self.trueTarget:isOutside() then
			if distanceToTrueTarget > self.attackDistance then
				self.target = self.trueTarget
			end
			self.timeSinceLastSeenTarget = timeStampMS
		else
			--prevent constantly changing targets during roaming
			if (self.timeSinceLastRoamed < timeStampMS) then
				self.timeSinceLastRoamed = timeStampMS+10000 --10 seconds

				--random offset used for roaming
				local offset = self.attackDistance
				local randOffset = {-offset,offset}

				local tx = self.target:getX()
				--50% chance to offset x
				if ZombRand(1,100) <= 50 then
					--pick from randOffset, 50% negative or positive
					tx = tx+randOffset[ZombRand(1,#randOffset+1)]
				end
				local ty = self.target:getY()
				--50% chance to offset y
				if ZombRand(1,100) <= 50 then
					--pick from randOffset, 50% negative or positive
					tx = tx+randOffset[ZombRand(1,#randOffset+1)]
				end
				--set target to square from calculated offset
				self.target = getSquare(tx,ty,0)
			end
		end

		self:setTargetPos()
		--if trueTarget is not a gridSquare and timeSinceLastSeenTarget exceeds searchForTargetDuration set trueTarget to current target
		if (not instanceof(self.trueTarget, "IsoGridSquare")) and (self.timeSinceLastSeenTarget+self.searchForTargetDuration < timeStampMS) then
			self.trueTarget = self.target
		end
	end

	if instanceof(self.trueTarget, "IsoGridSquare") and self.hoverOnTargetDuration then
		self:findTarget(self.attackDistance*4)
	end

	local distToTarget = self:getDistanceToVector(self.targetPosition)
	thatIsCloseEnough = thatIsCloseEnough+4
	local crashMin = thatIsCloseEnough*33
	local crashMax = thatIsCloseEnough*ZombRand(crashMin,100)

	if self.crashing and (distToTarget <= crashMax) and (distToTarget >= crashMin) then
		if self:crash() then
			return
		end
	end

	if self.hoverOnTargetDuration then
		thatIsCloseEnough = thatIsCloseEnough*ZombRand(2,4)
	end

	local preventMovement = false
	if (self.state == "gotoTarget") and (distToTarget <= thatIsCloseEnough) then
		if self.hoverOnTargetDuration then

			--[[DEBUG]] if getDebug() then self:hoverAndFlyOverReport("HOVERING OVER TARGET") end
			self:playEventSound("hoverOverTarget", nil, true)
			self.hoverOnTargetDuration = self.hoverOnTargetDuration-(1*getGameSpeed())
			if self.hoverOnTargetDuration <= 0 then
				self.hoverOnTargetDuration = false
			end
			preventMovement=true
		else
			--[[DEBUG]] if getDebug() then self:hoverAndFlyOverReport("FLEW OVER TARGET") end
			self:playEventSound("hoverOverTarget",nil, nil, true)
			self:playEventSound("flyOverTarget")
			--self:crash()
			self:goHome()
		end
	end

	local lockOn = true
	if self.state == "goHome" then
		lockOn = false
	end

	local currentSquare = self:getIsoGridSquare()
	--drop carpackage
	local packageDropRange = thatIsCloseEnough*100
	local packageDropRateChance = ZombRand(100) <= ((distToTarget/packageDropRange)*100)+10
	if self.dropPackages and packageDropRateChance and (distToTarget <= packageDropRange) then
		--returns true if dropped
		if self:dropCarePackage() then
			--clears droppackges to prevent more than 1
			self.dropPackages = false
		end
	end
	--drop items
	local itemDropRange = thatIsCloseEnough*250
	if self.dropItems and (distToTarget <= itemDropRange) then
		for k,_ in pairs(self.dropItems) do
			local dropChance = ZombRand(100) <= ((itemDropRange-distToTarget)/itemDropRange)*10
			if (self.dropItems[k] > 0) and dropChance then
				self.dropItems[k] = self.dropItems[k]-1
				self:dropItem(k)
			end
			if (self.dropItems[k] <= 0) then
				self.dropItems[k] = nil
			end
		end
	end
	--if it's ok to move do so, and update the shadow's position
	if not preventMovement then
		self:move(lockOn, true)
		if currentSquare then
			if self.shadow ~= false then
				if self.shadow == true then
					self.shadow = getWorldMarkers():addGridSquareMarker("circle_shadow", nil, currentSquare, 0.2, 0.2, 0.2, false, 6)
				end

				local shadowSquare = getOutsideSquare(currentSquare) or currentSquare
				if shadowSquare then
					self.shadow:setPos(shadowSquare:getX(),shadowSquare:getY(),shadowSquare:getZ())
				end
			end
		end
	end

	--shadowBob
	if self.shadow and (self.shadow ~= true) and (self.timeSinceLastShadowBob < timeStampMS) then
		self.timeSinceLastShadowBob = timeStampMS+10
		local shadowSize = self.shadow:getSize()
		shadowSize = shadowSize+self.shadowBobRate
		if shadowSize >= 6.5 then
			self.shadowBobRate = 0-math.abs(self.shadowBobRate)
		elseif shadowSize <= 6 then
			self.shadowBobRate = math.abs(self.shadowBobRate)
		end
		self.shadow:setSize(shadowSize)
	end

	local volumeFactor = 1
	if currentSquare then
		local zoneType = currentSquare:getZoneType()
		if (zoneType == "Forest") or (zoneType == "DeepForest") then
			volumeFactor = 0.25
		end
		addSound(nil, currentSquare:getX(),currentSquare:getY(), 0, (self.flightVolume*5)*volumeFactor, self.flightVolume*volumeFactor)
	end

	if self.announcerVoice and (not self.crashing) and (distToTarget <= thatIsCloseEnough*1500) then
		self:announce()
	end

	if self.hostilePreference and (not self.crashing) then
		self:lookForHostiles(self.hostilePreference)
	end

	if not self:isInBounds() then
		self:unlaunch()
	end
end


function updateAllHelicopters()
	for key,_ in ipairs(ALL_HELICOPTERS) do
		---@type eHelicopter heli
		local heli = ALL_HELICOPTERS[key]

		if heli.state and heli.state ~= "unLaunched" then
			heli:update()
		end
	end
end


function eHelicopter:unlaunch()
	print("HELI: "..self.ID.." UN-LAUNCH".." (x:"..Vector3GetX(self.currentPosition)..", y:"..Vector3GetY(self.currentPosition)..")")
	self.rotorEmitter:stopAll()
	--stop old emitter to prevent occasional "phantom" announcements
	if self.announceEmitter then
		self.announceEmitter:stopAll()
	end
	for event,emitter in pairs(self.eventSoundEffectEmitters) do
		emitter:stopSoundByName(event)
	end
	if self.shadow and type(self.shadow)~="boolean" then
		self.shadow:remove()
	end
	self.state = "unLaunched"
end


Events.OnTick.Add(updateAllHelicopters)
