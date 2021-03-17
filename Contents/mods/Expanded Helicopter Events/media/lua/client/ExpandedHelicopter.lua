---@class eHelicopter
---@field targetPos Vector3
---@field movement Vector3 consider this as a kind of velocity (direction and speed)
---@field currentPosition Vector3
---@field speed number
---@field emitter FMODSoundEmitter
---@field ID number

eHelicopter = {}
eHelicopter.targetPos = Vector3.new()
eHelicopter.movement = Vector3.new()
eHelicopter.currentPosition = Vector3.new()
eHelicopter.speed = 20
eHelicopter.height = 20
eHelicopter.ID = 0

function eHelicopter:new()

	local o = {}
	setmetatable(o, self)
	return o
end

MAX_XY = 15000
MIN_XY = 0


--- This is the equivalent of a getter for Vector3---
function smashShmector(pointToString)
	--example: java.awt.Point[x=12345,y=12345]
	pointToString = string.gsub(pointToString, "java.awt.Point%[x=", "")
	pointToString = string.gsub(pointToString, "y=", "")
	pointToString = string.gsub(pointToString, "%]", "")
	return pointToString
end

---@param ShmectorTree Vector3
---@return number x of ShmectorTree
function Vector3GetX(ShmectorTree)
	local point = smashShmector(tostring(ShmectorTree:toAwtPoint()))
	local x,_ = point:match("^(.+),(.+)$")
	return tonumber(x)
end

---@param ShmectorTree Vector3
---@return number y of ShmectorTree
function Vector3GetY(ShmectorTree)
	local point = smashShmector(tostring(ShmectorTree:toAwtPoint()))
	local _,y = point:match("^(.+),(.+)$")
	return tonumber(y)
end


function eHelicopter:initPos()
	---@type float
	local initX = 0
	---@type float
	local initY = 0

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

	self.currentPosition:set(initX, initY, self.height)
end


function eHelicopter:isInBounds()

	if Vector3GetX(self.currentPosition) <= MAX_XY and Vector3GetX(self.currentPosition) >= MIN_XY and Vector3GetY(self.currentPosition) <= MAX_XY and Vector3GetY(self.currentPosition) >= MIN_XY then
		return true
	end

	return false
end


---Rewriting Vector3.aimAt to use Vector3 rather than Vector2
---@param newTargetPos Vector3
---@return Vector3
function eHelicopter:ehe_aimAt(newTargetPos)

	local direction = math.atan(Vector3GetY(newTargetPos) - Vector3GetY(self.currentPosition), Vector3GetX(newTargetPos) - Vector3GetX(self.currentPosition))
	local length = math.sqrt(Vector3GetX(self.currentPosition) * Vector3GetX(self.currentPosition) + Vector3GetY(self.currentPosition) * Vector3GetY(self.currentPosition))
	local new_x = math.cos(direction) * length
	local new_y = math.sin(direction) * length

	return Vector3.new(new_x, new_y, self.height)
end


function eHelicopter:aimAtTarget()
	---@type Vector3 aimedVector3
	local aimedVector3 = self:ehe_aimAt(self.targetPos)

	self.movement:set(aimedVector3)
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

	self.currentPosition:set(Vector3GetX(self.currentPosition) + Vector3GetX(movementVector3), Vector3GetY(self.currentPosition) + Vector3GetY(movementVector3), self.height)
	self.emitter:setPos(Vector3GetX(self.currentPosition),Vector3GetY(self.currentPosition),self.height)
end


function eHelicopter:dampenMovement()

	self.movement:set(
	--[[x]](Vector3GetX(self.movement) * math.max(0.1,((Vector3GetX(self.targetPos) - Vector3GetX(self.currentPosition)) / Vector3GetX(self.targetPos)))),
	--[[y]](Vector3GetY(self.movement) * math.max(0.1,((Vector3GetY(self.targetPos) - Vector3GetY(self.currentPosition)) / Vector3GetY(self.targetPos)))),
	--[[z]](self.height)
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
		local randNumFromActivePlayers = ZombRand(numActivePlayers)
		targetedPlayer = getSpecificPlayer(randNumFromActivePlayers)
	end

	self.targetPos:set(targetedPlayer:getX(),targetedPlayer:getY(),self.height)
	self:aimAtTarget()

	self.emitter = getWorld():getFreeEmitter(Vector3GetX(self.currentPosition), Vector3GetY(self.currentPosition), self.height)
	self.emitter:playSound("Helicopter", getSquare(Vector3GetX(self.currentPosition), Vector3GetY(self.currentPosition), self.height))

	table.insert(ALL_HELICOPTERS, self)
	self.ID = #ALL_HELICOPTERS
end


ALL_HELICOPTERS = {}

function updateAllHelicopters()
	for key,_ in ipairs(ALL_HELICOPTERS) do
		---@type eHelicopter heli
		local heli = ALL_HELICOPTERS[key]
		heli:update()
	end
end


function eHelicopter:unlaunch()
	ALL_HELICOPTERS[self.ID] = nil
	self.emitter.stopAll()
end


function eHelicopter:update()

	self:moveToPosition(self.targetPos, true)

	print("applyMovement: currentPosition: "..tostring(self.currentPosition))
	print("applyMovement: movement: "..tostring(self.movement))
	print("applyMovement: targetPos: "..tostring(self.targetPos))

	if not self:isInBounds() then
		self:unlaunch()
	end
end

Events.OnTick.Add(updateAllHelicopters)


--- Used only for testing purposes
Events.OnCustomUIKey.Add(function(key)
if key == Keyboard.KEY_0 then
	print("0 key pressed")

	---@type eHelicopter heli
	local heli = eHelicopter:new()
	heli:launch()

	end
end)
