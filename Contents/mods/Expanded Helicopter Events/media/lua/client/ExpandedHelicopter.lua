---@class eHelicopter
---@field target IsoMovingObject | IsoPlayer | IsoGameCharacter
---@field targetPosition Vector3 @Vector3 "position" of target
---@field lastMovement Vector3 @consider this to be velocity (direction/angle and speed/stepsize)
---@field currentPosition Vector3 @consider this a pair of coordinates
---@field speed number
---@field emitter FMODSoundEmitter
---@field ID number

eHelicopter = {}
eHelicopter.target = nil
eHelicopter.targetPosition = Vector3.new()
eHelicopter.lastMovement = Vector3.new()
eHelicopter.currentPosition = Vector3.new()
eHelicopter.speed = 25
eHelicopter.height = 20
eHelicopter.ID = 0

function eHelicopter:new()

	local o = {}
	setmetatable(o, self)
	return o
end

--Global Vars
MAX_XY = 15000
MIN_XY = 1
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

	--clamp
	initX = math.max(MIN_XY, math.min(MAX_XY, initX))
	initY = math.max(MIN_XY, math.min(MAX_XY, initY))

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

	local a = Vector3GetX(self.targetPosition) - Vector3GetX(self.currentPosition)
	local b = Vector3GetY(self.targetPosition) - Vector3GetY(self.currentPosition)

	return math.sqrt((a*a)+(b*b))
end


---@param movement Vector3
function eHelicopter:dampen(movement)
	return movement:set(
		(Vector3GetX(movement) * ((Vector3GetX(self.targetPosition) - Vector3GetX(self.currentPosition)) / Vector3GetX(self.targetPosition))),
		(Vector3GetY(movement) * ((Vector3GetY(self.targetPosition) - Vector3GetY(self.currentPosition)) / Vector3GetY(self.targetPosition))),
		(self.height)
	)
end


function eHelicopter:setTargetPos()
	if self.target then
		eHelicopter.targetPosition:set(self.target:getX(), self.target:getY(), self.height)
	end
end


---Aim eHelicopter at it's defined target
---@return Vector3
function eHelicopter:aimAtTarget()
	
	---source: https://gamedev.stackexchange.com/questions/23447/moving-from-ax-y-to-bx1-y1-with-constant-speed
	
	self:setTargetPos()

	local movement_x = Vector3GetX(self.targetPosition) - Vector3GetX(self.currentPosition)
	local movement_y = Vector3GetY(self.targetPosition) - Vector3GetY(self.currentPosition)
	
	--difference between target's and current's x/y
	local local_movement = Vector3.new(movement_x,movement_y,0)
	
	local report = "aimAtTarget: ".."x:"..movement_x.." y:"..movement_y
	
	--normalize (shrink) the difference
	local_movement:normalize()
	
	report = report.."   ".." n:x:"..Vector3GetX(local_movement).." n:y:"..Vector3GetY(local_movement)
	
	--multiply the difference based on speed
	local_movement:setLength(self.speed)
	
	report = report.."   ".." sl:x:"..Vector3GetX(local_movement).." sl:y:"..Vector3GetY(local_movement)
	
	print(report)
	
	return local_movement
	
	--[[
	self:setTargetPos()

	local local_movement = Vector3.new()

	local atan_arg0 = Vector3GetY(self.targetPosition) - Vector3GetY(self.currentPosition)
	local atan_arg1 = Vector3GetX(self.targetPosition) - Vector3GetX(self.currentPosition)
	local angleTo = math.atan(atan_arg0, atan_arg1)

	local_movement:setLengthAndDirection(angleTo,self.currentPosition:getLength())
	local_movement:normalize()
	local_movement:setLength(self.speed)

	return local_movement]]
end


---@param aim boolean
---@param dampen boolean
function eHelicopter:moveToPosition(aim, dampen)
	

	---@type Vector3
	local velocity

	if aim then
		velocity = self:aimAtTarget()
		self.lastMovement:set(velocity)
	else
		velocity = self.lastMovement:clone()
	end

	if dampen then
		velocity = self:dampen(velocity)
	end
	
	--The actual movement occurs here when `velocity` is added to `self.currentPosition`
	-- Can't use Vector3:add() since it returns a Vector2
	---self.currentPosition:add(velocity)
	self.currentPosition:set(Vector3GetX(self.currentPosition) + Vector3GetX(velocity), Vector3GetY(self.currentPosition) + Vector3GetY(velocity), self.height)

	--Move emitter to position - note toNumber is needed for Vector3GetX/Y due to setPos not behaving with lua's pseudo "float"
	self.emitter:setPos(tonumber(Vector3GetX(self.currentPosition)),tonumber(Vector3GetY(self.currentPosition)),self.height)

	self:Report(aim, dampen)
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
	
	-- emitters do not work with lua's pseudo floats - tonumber() is needed
	local e_x = tonumber(Vector3GetX(self.currentPosition))
	local e_y = tonumber(Vector3GetY(self.currentPosition))
	
	--note: look into why getFreeEmitter and playSoundImpl even need a location
	self.emitter = getWorld():getFreeEmitter(e_x, e_y, self.height)
	self.emitter:playSoundImpl("Helicopter", getSquare(e_x, e_y, self.height))

	table.insert(ALL_HELICOPTERS, self)
	self.ID = #ALL_HELICOPTERS
end


function eHelicopter:update()

	if self:getDistanceToTarget() <= 1 then
		print("HELI: "..self.ID.." FLEW OVER TARGET".." (x:"..Vector3GetX(self.currentPosition)..", y:"..Vector3GetY(self.currentPosition)..")")
	else
		self:moveToPosition(true, true)
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

--- debug purposes -- this will flood your output
function eHelicopter:Report(aim, dampen)
	---@type eHelicopter heli
	local heli = self
	local report = " a:"..tostring(aim).." d:"..tostring(dampen).." "
	print("HELI: "..heli.ID.." (x:"..Vector3GetX(heli.currentPosition)..", y:"..Vector3GetY(heli.currentPosition)..")")
	print("(dist: "..heli:getDistanceToTarget()..")"..report)
	print("TARGET: (x:"..Vector3GetX(heli.targetPosition)..", y:"..Vector3GetY(heli.targetPosition)..")")
	print("-----------------------------------------------------------------")
end


function eHelicopter:unlaunch()
	print("HELI: "..self.ID.." UN-LAUNCH".." (x:"..Vector3GetX(self.currentPosition)..", y:"..Vector3GetY(self.currentPosition)..")")
	ALL_HELICOPTERS[self.ID] = nil
	self.emitter:stopAll()
end


Events.OnTick.Add(updateAllHelicopters)


--- Used only for testing purposes
Events.OnCustomUIKey.Add(function(key)
if key == Keyboard.KEY_0 then
	---@type eHelicopter heli
	local heli = eHelicopter:new()
	heli:launch()
	print("HELI: "..heli.ID.." LAUNCHED".." (x:"..Vector3GetX(heli.currentPosition)..", y:"..Vector3GetY(heli.currentPosition)..")")
	end
end)
