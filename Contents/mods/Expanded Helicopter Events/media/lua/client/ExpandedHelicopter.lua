---@class eHelicopter
---@field target IsoMovingObject | IsoPlayer | IsoGameCharacter
---@field targetPosition Vector3 @Vector3 "position" of target
---@field movement Vector3 @consider this to be velocity (direction/angle and speed/stepsize)
---@field currentPosition Vector3 @consider this a pair of coordinates
---@field speed number
---@field emitter FMODSoundEmitter
---@field ID number

eHelicopter = {}
eHelicopter.target = nil
eHelicopter.targetPosition = Vector3.new()
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

--Global Vars
MAX_XY = 15000
MIN_XY = 0
ALL_HELICOPTERS = {}


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
function eHelicopter:initPos()

	--Very scuffed way to grab a point along the 'edge' of the map.
	--initX/initY starts off as anything within map's range of MIN_XY and MAX_XY
	--50/50 chance to clamp initX -OR- initY to edge, then another 50/50 as to if that edge is MIN_XY -OR- MAX_XY
	
	---@type float
	local initX = ZombRand(MIN_XY,MAX_XY)
	---@type float
	local initY = ZombRand(MIN_XY,MAX_XY)
	
	if ZombRand(101) > 50 then 
		if ZombRand(101) > 50 then 
			initX = MIN_XY 
		else 
			initX = MAX_XY 
		end
	else 
		if ZombRand(101) > 50 then 
			initY = MIN_XY 
		else 
			initY = MAX_XY 
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
	---check if this vanilla function returns Vector2
	local a = (Vector3GetX(self.targetPosition) - Vector3GetX(self.currentPosition))*(Vector3GetX(self.targetPosition) - Vector3GetX(self.currentPosition))
	local b = (Vector3GetY(self.targetPosition) - Vector3GetY(self.currentPosition))*(Vector3GetY(self.targetPosition) - Vector3GetY(self.currentPosition))

	return math.sqrt(a+b)
end


function eHelicopter:dampenMovement()
	local returnV = Vector3.new(
		---@
		--try without math.max - could be losing float status
		---@
		(Vector3GetX(self.movement) * math.max(0.1,((Vector3GetX(self.targetPosition) - Vector3GetX(self.currentPosition)) / Vector3GetX(self.targetPosition)))),
		(Vector3GetY(self.movement) * math.max(0.1,((Vector3GetY(self.targetPosition) - Vector3GetY(self.currentPosition)) / Vector3GetY(self.targetPosition)))),
		(self.height)
	)
	print("dampened vector:"..tostring(returnV)) --- @_@ test this first- check if float status is lost
	return returnV
end


---These are the currently some of the broken methods for Vector3 due to references to Vector2 which is not properly exposed.
--[[ 
public Vector3 aimAt(Vector2 var1) { this.setLengthAndDirection(this.angleTo(var1), this.getLength()); return this; }

public float angleTo(Vector2 var1) { return (float)Math.atan2((double)(var1.y - this.y), (double)(var1.x - this.x)); }

public float getLength() { float var1 = this.getLengthSq(); return (float)Math.sqrt((double)var1); }

public float getLengthSq() { return this.x * this.x + this.y * this.y + this.z * this.z; }

public Vector3 setLengthAndDirection(float var1, float var2) { this.x = (float)(Math.cos((double)var1) * (double)var2);
	this.y = (float)(Math.sin((double)var1) * (double)var2); return this; }

]] ---Vector3.add() is also broken.


function eHelicopter:setTargetPos()
	if self.target then
		eHelicopter.targetPosition:set(self.target:getX(), self.target:getY(), self.target:getZ())
	end
end


---Aim eHelicopter at it's defined target
---@return Vector3
function eHelicopter:aimAtTarget()
	
	self:setTargetPos()
	--self.currentPosition:aimAt()
	local angleTo = math.atan(Vector3GetY(self.targetPosition) - Vector3GetY(self.currentPosition), Vector3GetX(self.targetPosition) - Vector3GetX(self.currentPosition))
	local getLength = math.sqrt(Vector3GetX(self.currentPosition) * Vector3GetX(self.currentPosition) + Vector3GetY(self.currentPosition) * Vector3GetY(self.currentPosition))

	--setLengthAndDirection()
	local new_x = math.cos(angleTo) * getLength
	local new_y = math.sin(angleTo) * getLength
	
	local local_movement = Vector3.new(new_x, new_y, 0)

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
	
	--The actual movement occurs here when `velocity` is added to `self.currentPosition`
	-- Can't use Vector3:add() since it returns a Vector2
	---self.currentPosition:add(velocity)
	self.currentPosition:set(Vector3GetX(self.currentPosition) + Vector3GetX(velocity), Vector3GetY(self.currentPosition) + Vector3GetY(velocity), self.height)
	
	--Move emitter to postion - note toNumber is needed for Vector3GetX/Y due to setPos not behaving with lua's pseudo "float"
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
	
	-- emitters do not work with lua's psuedo floats - tonumber() is needed
	local e_x = tonumber(Vector3GetX(self.currentPosition))
	local e_y = tonumber(Vector3GetY(self.currentPosition))
	
	--note: look into why getfreeemitter and playsound even need a location
	self.emitter = getWorld():getFreeEmitter(e_x, e_y, self.height)
	self.emitter:playSoundImpl("Helicopter", getSquare(e_x, e_y, self.height))

	table.insert(ALL_HELICOPTERS, self)
	self.ID = #ALL_HELICOPTERS
end


function eHelicopter:update()
	
	self:moveToPosition(true, true)
	
	if self:getDistanceToTarget() <= 1 then
		print("HELI: "..self.ID.." FLEW OVER TARGET")
	end

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
		print("TARGET: (x:"..Vector3GetX(heli.targetPosition)..", y:"..Vector3GetY(heli.targetPosition)..")")
	end
end


function eHelicopter:unlaunch()
	print("HELI: "..self.ID.." UN-LAUNCH")
	ALL_HELICOPTERS[self.ID] = nil
	self.emitter:stopAll()
end


Events.OnTick.Add(updateAllHelicopters)
Events.EveryTenMinutes.Add(helicopterReport)


--- Used only for testing purposes
Events.OnCustomUIKey.Add(function(key)
if key == Keyboard.KEY_0 then
	---@type eHelicopter heli
	local heli = eHelicopter:new()
	heli:launch()
	print("HELI: "..heli.ID.." LAUNCHED")
	end
end)
