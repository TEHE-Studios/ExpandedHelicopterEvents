---@class eHelicopter
---@field target IsoMovingObject | IsoPlayer | IsoGameCharacter
---@field movement Vector3 consider this as a kind of velocity (direction and speed)
---@field currentPosition Vector3
---@field speed number
---@field emitter FMODSoundEmitter
---@field ID number

eHelicopter = {}
eHelicopter.movement = Vector3.new()
eHelicopter.currentPosition = Vector3.new()
eHelicopter.speed = 10
eHelicopter.height = 20
eHelicopter.ID = 0

function eHelicopter:new()

	local o = {}
	setmetatable(o, self)
	return o
end

MAX_XY = 15000
MIN_XY = 0
ALL_HELICOPTERS = {}


--- These is the equivalent of getters for Vector3---
--"Vector2 (X: %f, Y: %f) (L: %f, D:%f)"
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

	local h_x = tonumber(Vector3GetX(self.currentPosition))
	local h_y = tonumber(Vector3GetY(self.currentPosition))

	if h_x <= MAX_XY and h_x >= MIN_XY and h_y <= MAX_XY and h_y >= MIN_XY then
		return true
	end

	return false
end

function eHelicopter:getDistanceToTarget()

	local a = (self.target:getX() - Vector3GetX(self.currentPosition))*(self.target:getX() - Vector3GetX(self.currentPosition))
	local b = (self.target:getY() - Vector3GetY(self.currentPosition))*(self.target:getY() - Vector3GetY(self.currentPosition))

	return math.sqrt(a+b)
end


function eHelicopter:dampenMovement()
	return Vector3.new(
			(Vector3GetX(self.movement) * math.max(0.1,((self.target:getX() - Vector3GetX(self.currentPosition)) / self.target:getX()))),
			(Vector3GetY(self.movement) * math.max(0.1,((self.target:getY() - Vector3GetY(self.currentPosition)) / self.target:getY()))),
			(self.height)
	)
end

--[[
public Vector3 aimAt(Vector2 var1) {
	this.setLengthAndDirection(this.angleTo(var1), this.getLength());
	return this;
}

public float angleTo(Vector2 var1) {
	return (float)Math.atan2((double)(var1.y - this.y), (double)(var1.x - this.x));
}

public float getLength() {
	float var1 = this.getLengthSq();
	return (float)Math.sqrt((double)var1);
}

public float getLengthSq() {
	return this.x * this.x + this.y * this.y + this.z * this.z;
}

public Vector3 setLengthAndDirection(float var1, float var2) {
	this.x = (float)(Math.cos((double)var1) * (double)var2);
	this.y = (float)(Math.sin((double)var1) * (double)var2);
	return this;
}

]]

function eHelicopter:aimAtTarget()

	local angleTo = math.atan(self.target:getY() - Vector3GetY(self.currentPosition), self.target:getX() - Vector3GetX(self.currentPosition))
	local getLength = math.sqrt(Vector3GetX(self.currentPosition) * Vector3GetX(self.currentPosition) + Vector3GetY(self.currentPosition) * Vector3GetY(self.currentPosition))

	--setLengthAndDirection()
	local new_x = math.cos(angleTo) * getLength
	local new_y = math.sin(angleTo) * getLength

	local local_movement = Vector3.new(new_x, new_y, self.height)

	local_movement:normalize()
	local_movement:setLength(self.speed)

	return local_movement
end


---@param Aim boolean
---@param dampen boolean
function eHelicopter:moveToPosition(Aim, dampen)

	if Aim then self.movement:set(self:aimAtTarget()) end

	---@type Vector3
	local velocity = self.movement:clone()

	if dampen then velocity:set(self:dampenMovement()) end

	self.currentPosition:set(Vector3GetX(self.currentPosition) + Vector3GetX(velocity), Vector3GetY(self.currentPosition) + Vector3GetY(velocity), self.height)
	self.emitter:setPos(tonumber(Vector3GetX(self.currentPosition)),tonumber(Vector3GetY(self.currentPosition)),self.height)
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

	self.target = targetedPlayer

	local e_x = tonumber(Vector3GetX(self.currentPosition))
	local e_y = tonumber(Vector3GetY(self.currentPosition))

	self.emitter = getWorld():getFreeEmitter(e_x, e_y, self.height)
	self.emitter:playSoundImpl("Helicopter", getSquare(e_x, e_y, self.height))

	table.insert(ALL_HELICOPTERS, self)
	self.ID = #ALL_HELICOPTERS
end


function eHelicopter:update()

	self:moveToPosition(true, true)

	if not self:isInBounds() then
		self:unlaunch()
	end
end


function updateAllHelicopters()
	for key,_ in ipairs(ALL_HELICOPTERS) do
		---@type eHelicopter heli
		local heli = ALL_HELICOPTERS[key]
		heli:update()
	end
end

--- debug purposes
function helicopterReport()
	for key,_ in ipairs(ALL_HELICOPTERS) do
		---@type eHelicopter heli
		local heli = ALL_HELICOPTERS[key]
		print("HELI: "..heli.ID.." (x:"..Vector3GetX(heli.currentPosition)..", y:"..Vector3GetY(heli.currentPosition).."), ".."(dist: "..heli:getDistanceToTarget()..")")
		print("TARGET: (x:"..heli.target:getX()..", y:"..heli.target:getY()..")")
	end
end


function eHelicopter:unlaunch()
	ALL_HELICOPTERS[self.ID] = nil
	self.emitter:stopAll()
end


Events.OnTick.Add(updateAllHelicopters)
Events.EveryTenMinutes.Add(helicopterReport)

--- Used only for testing purposes
Events.OnCustomUIKey.Add(function(key)
if key == Keyboard.KEY_0 then
	print("0 key pressed")

	---@type eHelicopter heli
	local heli = eHelicopter:new()
	heli:launch()

	end
end)
