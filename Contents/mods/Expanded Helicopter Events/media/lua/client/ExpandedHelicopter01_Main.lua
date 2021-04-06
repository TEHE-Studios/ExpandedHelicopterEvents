--GLOBAL_VARIABLES
MAX_XY = 15000
MIN_XY = 2500
ALL_HELICOPTERS = {}

---@class eHelicopter
---@field preflightDistance number
---@field target IsoObject
---@field targetPosition Vector3 @Vector3 "position" of target
---@field state boolean
---@field lastMovement Vector3 @consider this to be velocity (direction/angle and speed/stepsize)
---@field currentPosition Vector3 @consider this a pair of coordinates
---@field lastAnnouncedTime number
---@field announcerVoice string
---@field rotorEmitter FMODSoundEmitter | BaseSoundEmitter
---@field ID number
---@field height number
---@field speed number
---@field topSpeedFactor number speed x this = top "speed"
---@field fireSound table sounds for firing
---@field fireImpacts table sounds for fire impact
---@field attackRangeDistance number
---@field attackRangeScope number
---@field lastAttackTime number
---@field attackDelay number
---@field hostilesToFireOn table

eHelicopter = {}
eHelicopter.preflightDistance = nil
eHelicopter.target = nil
eHelicopter.targetPosition = nil
eHelicopter.state = nil
eHelicopter.lastMovement = nil
eHelicopter.currentPosition = nil
eHelicopter.lastAnnouncedTime = 0
eHelicopter.announcerVoice = nil
eHelicopter.rotorEmitter = nil
eHelicopter.ID = 0
eHelicopter.height = 20
eHelicopter.speed = 0.25
eHelicopter.topSpeedFactor = 3
eHelicopter.fireSound = {"eHeli_fire_single","eHeli_fire_loop"}
eHelicopter.fireImpacts = {"eHeli_fire_impact1", "eHeli_fire_impact2", "eHeli_fire_impact3",  "eHeli_fire_impact4", "eHeli_fire_impact5"}
eHelicopter.attackRangeDistance = 50
eHelicopter.attackRangeScope = 3
eHelicopter.lastAttackTime = 0
eHelicopter.attackDelay = 0.00001
eHelicopter.hostilesToFireOnIndex = 0
eHelicopter.hostilesToFireOn = {}

---Do not call this function directly for new helicopters
---@see getFreeHelicopter instead
function eHelicopter:new()

	local o = {}
	setmetatable(o, self)
	self.__index = self
	table.insert(ALL_HELICOPTERS, o)
	o.ID = #ALL_HELICOPTERS
	
	return o
end


---returns first "unlaunched" helicopter found in ALL_HELICOPTERS -OR- creates a new instance
function getFreeHelicopter()
	for key,_ in ipairs(ALL_HELICOPTERS) do
		---@type eHelicopter heli
		local heli = ALL_HELICOPTERS[key]
		if heli.state == "unlaunched" then
			return heli
		end
	end
	return eHelicopter:new()
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
function eHelicopter:getIsoGridSquare()
	local ehX, ehY, _ = self:getXYZAsInt()

	return getSquare(ehX, ehY, 0)
end


function eHelicopter:isInBounds()
	local h_x, h_y, _ = self:getXYZAsInt()

	if h_x <= MAX_XY and h_x >= MIN_XY and h_y <= MAX_XY and h_y >= MIN_XY then
		return true
	end

	return false
end


function eHelicopter:getDistanceToTarget()

	local a = Vector3GetX(self.targetPosition) - Vector3GetX(self.currentPosition)
	local b = Vector3GetY(self.targetPosition) - Vector3GetY(self.currentPosition)

	return math.sqrt((a*a)+(b*b))
end


---@param movement Vector3
function eHelicopter:dampen(movement)
	--finds the fraction of distance to target and preflight distance to target
	local distanceCompare = self:getDistanceToTarget() / self.preflightDistance
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

	--account for sped up time
	local timeSpeed = getGameSpeed()
	local v_x = Vector3GetX(self.currentPosition)+(Vector3GetX(velocity)*timeSpeed)
	local v_y = Vector3GetY(self.currentPosition)+(Vector3GetY(velocity)*timeSpeed)

	--The actual movement occurs here when the modified `velocity` is added to `self.currentPosition`
	self.currentPosition:set(v_x, v_y, self.height)
	--Move emitter to position
	self.rotorEmitter:setPos(v_x,v_y,self.height)

	local heliVolume = 50

	if self.lastAnnouncedTime <= getTimestamp() then
		heliVolume = heliVolume+20
		self:announce()
	end

	--virtual sound event to attract zombies
	addSound(nil, v_x, v_y, 0, 250, heliVolume)

	--self:Report(re_aim, dampen)
end


---@param targetedPlayer IsoMovingObject | IsoPlayer | IsoGameCharacter random player if blank
function eHelicopter:launch(targetedPlayer)

	if not targetedPlayer then
		--the -1 is to offset playerIDs starting at 0
		local numActivePlayers = getNumActivePlayers()-1
		local randNumFromActivePlayers = ZombRand(numActivePlayers)
		targetedPlayer = getSpecificPlayer(randNumFromActivePlayers)
	end

	self.target = targetedPlayer
	self:setTargetPos()
	self:initPos(self.target)
	self.preflightDistance = self:getDistanceToTarget()
	self.rotorEmitter = getWorld():getFreeEmitter()

	local ehX, ehY, ehZ = self:getXYZAsInt()

	self.rotorEmitter:playSound("eHelicopter", ehX, ehY, ehZ)
	self:chooseVoice()
	self.state = "gotoTarget"
end


function eHelicopter:update()

	--threshold for reaching player should be self.speed * getGameSpeed
	if (self.state == "gotoTarget") and (self:getDistanceToTarget() <= ((self.topSpeedFactor*self.speed)*tonumber(getGameSpeed()))) then
		print("HELI: "..self.ID.." FLEW OVER TARGET".." (x:"..Vector3GetX(self.currentPosition)..", y:"..Vector3GetY(self.currentPosition)..")")
		self.state = "goHome"
		self.target = getSquare(self.target:getX(),self.target:getY(),0)
		self:setTargetPos()
	end

	local lockOn = true
	if self.state == "goHome" then
		lockOn = false
	end

	self:move(lockOn, true)
	self:lookForHostiles("IsoZombie")

	if not self:isInBounds() then
		self:unlaunch()
	end
end


function updateAllHelicopters()
	for key,_ in ipairs(ALL_HELICOPTERS) do
		---@type eHelicopter heli
		local heli = ALL_HELICOPTERS[key]

		if heli.state ~= "unlaunched" then
			heli:update()
		end
	end
end


function eHelicopter:unlaunch()
	print("HELI: "..self.ID.." UN-LAUNCH".." (x:"..Vector3GetX(self.currentPosition)..", y:"..Vector3GetY(self.currentPosition)..")")
	self.state = "unlaunched"
	self.rotorEmitter:stopAll()
end

Events.OnTick.Add(updateAllHelicopters)
