---@class eHelicopter
---@field emitter FMODSoundEmitter
eHelicopter = {}
eHelicopter.MAX_XY = 15000
eHelicopter.MIN_XY = 0

---@field targetPos Vector3
---@field movement Vector3 consider this as a kind of velocity (direction and speed)
eHelicopter.targetPos = Vector3.new()
eHelicopter.movement = Vector3.new()
eHelicopter.currentPosition = Vector3.new()

eHelicopter.speed = 20


function eHelicopter.initPos()

	local initX = 0
	local initY = 0
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

	eHelicopter.currentPosition:set(initX, initY, initZ)
end


---@param targetedPlayer IsoMovingObject | IsoPlayer | IsoGameCharacter @ random player if blank
function eHelicopter.launch(targetedPlayer)

	eHelicopter.initPos()

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

	eHelicopter.aimAtTarget()

	print("targetedPlayer: "..targetedPlayer:getDescriptor():getForename().." "..targetedPlayer:getDescriptor()
			:getSurname().." (pos:"..targetedPlayer:getX()..","..targetedPlayer:getY())

	eHelicopter.targetPos:set(targetedPlayer:getX(),targetedPlayer:getY(),eHelicopter.currentPosition.z)

	eHelicopter.emitter = getWorld():getFreeEmitter(eHelicopter.currentPosition.x, eHelicopter.currentPosition.y, eHelicopter.currentPosition.z)
	if not eHelicopter.emitter then print("no emitter found") end
	--eHelicopter.emitter:playSound("Helicopter", getSquare(eHelicopter.currentPosition.x, eHelicopter.currentPosition.y, eHelicopter.currentPosition.z))

	Events.OnTick.Add(eHelicopter.update)
end


function eHelicopter.isInBounds()

	if ( eHelicopter.currentPosition.x <= MAX_XY and
			eHelicopter.currentPosition.x >= MIN_XY and
			eHelicopter.currentPosition.y <= MAX_XY and
			eHelicopter.currentPosition.y >= MIN_XY ) then
		return true
	end
	return false
end


function eHelicopter.update()

	eHelicopter.moveToPosition(eHelicopter.targetPos, true)

	if not eHelicopter.isInBounds() then
		eHelicopter.unlaunch()
	end
end


function eHelicopter.unlaunch()

	Events.OnTick.Remove(eHelicopter.update)
	eHelicopter.emitter.stopAll()
end


---Rewriting Vector3.aimAt to use Vector3
---@param currentPos Vector3
---@param target Vector3
---@return Vector3
function eHelicopter.ehe_aimAt(currentPos,target)

	---@type Vector3 movement
	local movementVector3 = Vector3.new()

	local direction = Math:atan2((target.y - currentPos.y), (target.x - currentPos.x))
	local length = Math:sqrt(currentPos.x * currentPos.x + currentPos.y * currentPos.y)

	movementVector3:setLengthAndDirection(direction, length)
	movementVector3.z = eHelicopter.currentPosition.z

	return movementVector3
end


function eHelicopter.aimAtTarget()

	print("eHelicopter.currentPosition: "..tostring(eHelicopter.currentPosition))
	print("eHelicopter.targetPos: "..tostring(eHelicopter.targetPos))

	eHelicopter.movement:set(eHelicopter.ehe_aimAt(eHelicopter.currentPosition,eHelicopter.targetPos))

	print("eHelicopter.movement: "..tostring(eHelicopter.movement))

	eHelicopter.movement:normalize()
	eHelicopter.movement:setLength(eHelicopter.speed)
end


---@param dampen boolean
function eHelicopter.applyMovement(dampen)

	---@type Vector3 movement
	local movementVector3 = eHelicopter.movement:clone()

	if dampen then
		eHelicopter.dampenMovement(movementVector3)
	end

	eHelicopter.currentPosition:add(movementVector3)

	print("HELI: X:"..eHelicopter.currentPosition.x .."  Y:"..eHelicopter.currentPosition.y)

	eHelicopter.emitter:setPos(eHelicopter.currentPosition.x,eHelicopter.currentPosition.y,eHelicopter.currentPosition.z)
end


---@param movement Vector3
function eHelicopter.dampenMovement(movement)

	--movement:set((movement.x * math.max(0.1,((eHelicopter.targetPos.x - eHelicopter.currentPosition.x) / eHelicopter.targetPos.x))), (movement.y * math.max(0.1,((eHelicopter.targetPos.y - eHelicopter.currentPosition.y) / eHelicopter.targetPos.y))), (eHelicopter.currentPosition.z))
end


---@param destination Vector3
---@param dampen boolean
function eHelicopter.moveToPosition(destination, dampen)

	if destination then
		eHelicopter.aimAtTarget(destination)
	end

	eHelicopter.applyMovement(dampen)
end


--- Used only for testing purposes
Events.OnCustomUIKey.Add(function(key)
if key == Keyboard.KEY_0 then
	print("0 key pressed :')")
	eHelicopter.launch()
	--elseif key == Keyboard.KEY_9 then---add different behaviors + send away
	--	if eHelicopter.emitter then
	--		eHelicopter.emitter.stopAll()
	--		print("Stopping helicopter emitter")
	--	else
	--		print("Unable to find helicopter emitter!")
	--	end
	end
end)
