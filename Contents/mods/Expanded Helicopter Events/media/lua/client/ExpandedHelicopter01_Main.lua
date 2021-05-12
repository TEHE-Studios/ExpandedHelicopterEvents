--GLOBAL_VARIABLES
MAX_XY = 15000
MIN_XY = 2500
ALL_HELICOPTERS = {}

---@class eHelicopter
eHelicopter = {}

---@field hoverOnTargetDuration number How long the helicopter will hover over the player, this is subtracted from every tick
eHelicopter.hoverOnTargetDuration = false

---@field canCrash boolean
eHelicopter.canCrash = "Base.UH1HCrash"

---@field eventSoundEffects table
eHelicopter.eventSoundEffects = {}--{["hoverOverTarget"]=nil,["flyOverTarget"]=nil,["attackLooped"]=nil,["attackSingle"]=nil}

---@field eventSoundEffects table
eHelicopter.eventSoundEffectEmitters = {}

---@field announcerVoice string
eHelicopter.announcerVoice = true

---@field randomEdgeStart boolean
eHelicopter.randomEdgeStart = false

---@field presetProgression table Table of presetIDs and corresponding % preset is switched to (compared to Days/CuttOffDay)
eHelicopter.presetProgression = false

---@field frequencyFactor number This is multiplied against the min/max day range; less than 1 results in higher frequency, more than 1 results in less frequency
eHelicopter.frequencyFactor = 1

---@field startDayMinMax table two numbers: min and max start day can be
eHelicopter.startDayMinMax = {0,1}

---@field cutOffDay number event cut-off day after apocalypse start, NOT game start
eHelicopter.cutOffDay = 30

---@field speed number
eHelicopter.speed = 0.25

---@field topSpeedFactor number speed x this = top "speed"
eHelicopter.topSpeedFactor = 3

---@field flightSound string sound to loop during flight
eHelicopter.flightSound = "eHelicopter"

---@field flightVolume number
eHelicopter.flightVolume = 50

---@field fireSound table sounds for firing
eHelicopter.fireSound = {"eHeli_fire_single","eHeli_fire_loop"}

---@field fireImpacts table sounds for fire impact
eHelicopter.fireImpacts = {"eHeli_fire_impact1", "eHeli_fire_impact2", "eHeli_fire_impact3",  "eHeli_fire_impact4", "eHeli_fire_impact5"}

---@field hostilePreference string
---set to 'false' for *none*, otherwise has to be 'IsoPlayer' or 'IsoZombie' or 'IsoGameCharacter'
eHelicopter.hostilePreference = "IsoZombie"

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
function eHelicopter_variableBackUp(listToSaveTo, checkIfNotIn, debugID)
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
---@field target IsoObject
eHelicopter.target = false
---@field trueTarget IsoGameCharacter
eHelicopter.trueTarget = false
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

--This stores the above "temporary" variables for resetting eHelicopters later
eHelicopter_temporaryVariables = {}
eHelicopter_variableBackUp(eHelicopter_temporaryVariables, eHelicopter_initialVars, "temporaryVariables")

--ID must not be reset ever
---@field ID number
eHelicopter.ID = 0


---@param event string
---@param stopSound boolean
function eHelicopter:playEventSound(event, stopSound)

	local soundEffect = self.eventSoundEffects[event]

	if not soundEffect then
		return
	end
	---@type FMODSoundEmitter | BaseSoundEmitter emitter
	local soundEmitter = self.eventSoundEffectEmitters[event]
	if stopSound and soundEmitter then
		soundEmitter:stopSoundByName(soundEffect)
		return
	end
	--determine location of helicopter
	local ehX, ehY, ehZ = self:getXYZAsInt()

	if not soundEmitter then
		soundEmitter = getWorld():getFreeEmitter()
		self.eventSoundEffectEmitters[event] = soundEmitter
	elseif soundEmitter:isPlaying(soundEffect) then
		return
	end
	soundEmitter:playSound(soundEffect, ehX, ehY, ehZ)
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
		randEdge = randEdge[ZombRand(1,#randEdge)]
		
		--this takes either initX/initY (within initPosXY) and makes it either MIN_XY/MAX (randEdge)
		initPosXY[ZombRand(1, #initPosXY)] = randEdge
		
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
function eHelicopter:getIsoGridSquare(zLevel)
	local ehX, ehY, _ = self:getXYZAsInt()
	local square = getSquare(ehX, ehY, zLevel or 0)
	--squares on non-zero z levels may not be loaded
	if not square and zLevel then
		--grab cell on floor if cell is loaded
		square = getSquare(ehX, ehY, 0)
		if square then
			return square:getCell():getOrCreateGridSquare(ehX, ehY, zLevel)
		end
	end

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

	local a = object:getX() - Vector3GetX(self.currentPosition)
	local b = object:getY() - Vector3GetY(self.currentPosition)

	return math.sqrt((a*a)+(b*b))
end


---@param movement Vector3
---@return Vector3
function eHelicopter:dampen(movement)
	--finds the fraction of distance to target and preflight distance to target
	local distanceCompare = self:getDistanceToVector(self.targetPosition) / self.preflightDistance
	--clamp with a max of self.topSpeedFactor and min of 0.1 (10%) is applied to the fraction 
	local dampenFactor = math.max(self.topSpeedFactor, math.min(0.1, distanceCompare))
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


---@param targetedPlayer IsoMovingObject | IsoPlayer | IsoGameCharacter random player if blank
function eHelicopter:launch(targetedPlayer)

	if not targetedPlayer then
		--the -1 is to offset playerIDs starting at 0
		local weightPlayersList = {}
		local numActivePlayers = getNumActivePlayers()-1

		for i=0, numActivePlayers do
			---@type IsoGameCharacter p
			local p = getSpecificPlayer(i)

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

		targetedPlayer = weightPlayersList[ZombRand(1, #weightPlayersList)]
	end

	self.target = targetedPlayer:getSquare()
	self.trueTarget = targetedPlayer
	self:setTargetPos()
	self:initPos(self.target,self.randomEdgeStart)
	self.preflightDistance = self:getDistanceToVector(self.targetPosition)
	self.rotorEmitter = getWorld():getFreeEmitter()

	local ehX, ehY, ehZ = self:getXYZAsInt()

	self.rotorEmitter:playSound(self.flightSound, ehX, ehY, ehZ)

	if not self.attackDistance then
		self.attackDistance = ((self.attackScope*2)+1)*((self.attackSpread*2)+1)
	end

	if self.announcerVoice ~= false then
		self:chooseVoice(self.announcerVoice)
	end
	self.state = "gotoTarget"

	local _, weatherImpact = eHeliEvent_weatherImpact()
	if (not self.crashing) and ZombRand(0,100) <= weatherImpact*100 then
		self.crashing = true
	end
end


---Heli goes home
function eHelicopter:goHome()
	self.state = "goHome"
	self.trueTarget = getSquare(self.target:getX(),self.target:getY(),0)
	self.target = self.trueTarget
	self:setTargetPos()
end


---Heli goes down
function eHelicopter:crash()

	if self.canCrash then
		---@type IsoGridSquare
		local square = self:getIsoGridSquare(self.height)
		local vehicleType = self.canCrash

		print("EHE: CRASH EVENT: "..square:getX()..", "..square:getY())

		---@type BaseVehicle
		local heli = addVehicleDebug(vehicleType, IsoDirections.S, nil, square)
		heli:playSound("VehicleTireExplode")
		heli:playSound("VehicleCrash")
		heli:playSound("VehicleCrash1")
		heli:playSound("VehicleCrash2")
		heli:playSound("VehicleHitObject")
		addSound(nil, square:getX(), square:getY(), 0, 100, 100)
	end
	self:unlaunch()
end


function eHelicopter:update()
	--check if trueTarget is a player/zombie
	if instanceof(self.trueTarget, "IsoGameCharacter") then
		--if trueTarget is within range
		if (self:getDistanceToIsoObject(self.trueTarget) <= (self.attackDistance*2)) then
			--if trueTarget is outside then match target to trueTarget otherwise scramble target to random nearby square
			if self.trueTarget:isOutside() then
				self.target = self.trueTarget
			else
				local offset = math.floor(self.attackDistance*0.75)
				local tx = Vector3GetX(self.targetPosition)+ZombRand(-offset,offset)
				local ty = Vector3GetY(self.targetPosition)+ZombRand(-offset,offset)
				self.target = getSquare(tx,ty,0)
			end
		else
		--if target is out of range, confirm target is a near by square, then set trueTarget to current target - loss of target
			if not instanceof(self.target, "IsoGridSquare") then
				local offset = math.floor(self.attackDistance*0.75)
				local tx = Vector3GetX(self.currentPosition)+ZombRand(-offset,offset)
				local ty = Vector3GetY(self.currentPosition)+ZombRand(-offset,offset)
				self.target = getSquare(tx,ty,0)
			end
			self.trueTarget = self.target
		end
	end

	local distToTarget = self:getDistanceToVector(self.targetPosition)
	local thatIsCloseEnough = (self.topSpeedFactor*self.speed)*tonumber(getGameSpeed())
	local crashMin = thatIsCloseEnough*33
	local crashMax = thatIsCloseEnough*ZombRand(crashMin,100)

	if self.crashing and (distToTarget <= crashMax) and (distToTarget >= crashMin) then
		self:crash()
		return
	end

	local preventMovement = false
	if (self.state == "gotoTarget") and (distToTarget <= thatIsCloseEnough) then
		if self.hoverOnTargetDuration then

			--[[DEBUG]] if getDebug() then self:hoverAndFlyOverReport("HOVERING OVER TARGET") end

			self:playEventSound("hoverOverTarget")
			self.hoverOnTargetDuration = self.hoverOnTargetDuration-1
			if self.hoverOnTargetDuration == 0 then
				self.hoverOnTargetDuration = false
			end
			preventMovement=true
		else
			--[[DEBUG]] if getDebug() then self:hoverAndFlyOverReport("FLEW OVER TARGET") end
			self:playEventSound("hoverOverTarget",true)
			self:playEventSound("flyOverTarget")
			self:goHome()
		end
	end

	local lockOn = true
	if self.state == "goHome" then
		lockOn = false
	end

	if not preventMovement then
		self:move(lockOn, true)
	end

	local v_x = tonumber(Vector3GetX(self.currentPosition))
	local v_y = tonumber(Vector3GetY(self.currentPosition))
	addSound(nil, v_x, v_y, 0, (self.flightVolume*5), self.flightVolume)

	if self.announcerVoice and (not self.crashing) then
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

		if heli.state ~= "unLaunched" then
			heli:update()
		end
	end
end


function eHelicopter:unlaunch()
	print("HELI: "..self.ID.." UN-LAUNCH".." (x:"..Vector3GetX(self.currentPosition)..", y:"..Vector3GetY(self.currentPosition)..")")
	self.state = "unLaunched"
	self.rotorEmitter:stopAll()
end

Events.OnTick.Add(updateAllHelicopters)
