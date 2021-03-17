---@class eHelicopter
---@field targetPos Vector3
---@field movement Vector3 consider this as a kind of velocity (direction and speed)
---@field currentPosition Vector3
---@field speed number
---@field emitter FMODSoundEmitter

eHelicopter = {}
eHelicopter.targetPos = {}--Vector3.new()
eHelicopter.movement = {}--Vector3.new()
eHelicopter.currentPosition = {}--Vector3.new()
eHelicopter.speed = 20

function eHelicopter:new()

	local o = {}
	setmetatable(o, self)
	return o
end

MAX_XY = 15000
MIN_XY = 0


function eHelicopter:initPos()
	---@type float
	local initX = 0
	---@type float
	local initY = 0
	---@type float
	local initZ = 20

	if ZombRand(101) > 50 then --50/50
		initX = MAX_XY
		initY = ZombRand(MIN_XY,MAX_XY)
		if ZombRand(101) > 50 then --50/50
			initX = MIN_XY
		end
	else
		initX = ZombRand(MIN_XY,MAX_XY)
		initY = MAX_XY
		if ZombRand(101) > 50 then --50/50
			initY = MIN_XY
		end
	end

	self.currentPosition = Vector3.new(initX, initY, initZ)
	print("initPos: currentPosition: "..tostring(self.currentPosition))

end


function eHelicopter:isInBounds()

	if ( self.currentPosition.x <= MAX_XY and
			self.currentPosition.x >= MIN_XY and
			self.currentPosition.y <= MAX_XY and
			self.currentPosition.y >= MIN_XY ) then
		return true
	end
	return false
end


function eHelicopter:update()

	self:moveToPosition(self.targetPos, true)

	if not self:isInBounds() then
		self:unlaunch()
	end
end


function eHelicopter:unlaunch()

	Events.OnTick.Remove(self.update)
	self.emitter.stopAll()
end


---Rewriting Vector3.aimAt to use Vector3 rather than Vector2
---@param targetPosition Vector3
---@return Vector3
function eHelicopter:ehe_aimAt(targetPosition)

	print("applyMovement: currentPosition: "..tostring(self.currentPosition))
	print("applyMovement: movement: "..tostring(self.movement))
	print("applyMovement: targetPosition: "..tostring(targetPosition))
	print("applyMovement: targetPos: "..tostring(self.targetPos))

	---@type Vector3 movementVector3
	local movementVector3 = Vector3.new()
	---@type float
	local direction = math.atan(targetPosition.y - self.currentPosition.y, targetPosition.x - self.currentPosition.x)
	---@type float
	local length = math.sqrt(self.currentPosition.x * self.currentPosition.x + self.currentPosition.y * self.currentPosition.y)

	movementVector3:setLengthAndDirection(direction, length)
	movementVector3.z = self.currentPosition.z

	return movementVector3
end


function eHelicopter:aimAtTarget()

	---@type Vector3 aimedVector3
	local aimedVector3 = self:ehe_aimAt(self.targetPos)

	print("aimAtTarget: aimedVector3: "..tostring(aimedVector3))

	self.movement = Vector3.new(aimedVector3)

	print("aimAtTarget: currentPosition: "..tostring(self.currentPosition))
	print("aimAtTarget: targetPos: "..tostring(self.targetPos))
	print("aimAtTarget: movement: "..tostring(self.movement))

	self.movement:normalize()
	self.movement:setLength(self.speed)
end


---@param dampen boolean
function eHelicopter:applyMovement(dampen)

	---@type Vector3 movement
	local movementVector3 = self.movement:clone()

	if dampen then
		self:dampenMovement(movementVector3)
	end

	self.currentPosition.x = self.currentPosition.x + movementVector3.x
	self.currentPosition.y = self.currentPosition.y + movementVector3.y

	print("applyMovement: currentPosition: "..tostring(self.currentPosition))
	print("applyMovement: movement: "..tostring(self.movement))
	print("applyMovement: targetPos: "..tostring(self.targetPos))

	self.emitter:setPos(self.currentPosition.x,self.currentPosition.y,self.currentPosition.z)
end


function eHelicopter:dampenMovement()

	self.movement:set(
	--[[x]](movement.x * math.max(0.1,((self.targetPos.x - self.currentPosition.x) / self.targetPos.x))),
	--[[y]](movement.y * math.max(0.1,((self.targetPos.y - self.currentPosition.y) / self.targetPos.y))),
	--[[z]](self.currentPosition.z)
	)
end


---@param destination Vector3
---@param dampen boolean
function eHelicopter:moveToPosition(destination, dampen)

	if destination then
		self:aimAtTarget(destination)
	end

	self:applyMovement(dampen)
end


---@param targetedPlayer IsoMovingObject | IsoPlayer | IsoGameCharacter random player if blank
function eHelicopter:launch(targetedPlayer)

	self:initPos()

	if not targetedPlayer then
		--the -1 is to offset playerIDs starting at 0
		local numActivePlayers = getNumActivePlayers()-1
		print("numActivePlayers: "..numActivePlayers)
		local randNumFromActivePlayers = ZombRand(numActivePlayers)
		print("randNumFromActivePlayers: "..randNumFromActivePlayers)
		targetedPlayer = getSpecificPlayer(randNumFromActivePlayers)
	end

	if not targetedPlayer then
		print("no targetedPlayer")
		return
	end
	
	print("launch: currentPosition: "..tostring(self.currentPosition))

	print("launch: target:"..targetedPlayer:getDescriptor():getSurname().."  (x: "..targetedPlayer:getX().." y: "..targetedPlayer:getY()..")")

	self.targetPos = Vector3.new(targetedPlayer:getX(),targetedPlayer:getY(),self.currentPosition.z)

	self:aimAtTarget()

	print("launch: targetPos: "..tostring(self.targetPos))

	self.emitter = getWorld():getFreeEmitter(self.currentPosition.x, self.currentPosition.y, self.currentPosition.z)
	if not self.emitter then print("no emitter found") end
	--self.emitter:playSound("Helicopter", getSquare(self.currentPosition.x, self.currentPosition.y, self.currentPosition.z))

	Events.OnTick.Add(self.update)
end


--- Used only for testing purposes
Events.OnCustomUIKey.Add(function(key)
if key == Keyboard.KEY_0 then
	print("0 key pressed")

	---@type eHelicopter heli
	local heli = eHelicopter:new()
	heli:launch()

	--elseif key == Keyboard.KEY_9 then---add different behaviors + send away
	--	if eHelicopter.emitter then
	--		eHelicopter.emitter.stopAll()
	--		print("Stopping helicopter emitter")
	--	else
	--		print("Unable to find helicopter emitter!")
	--	end
	end
end)
