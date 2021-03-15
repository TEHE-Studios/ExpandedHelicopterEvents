---@class eHelicopter
---@field soundRef long
---@field emitter FMODSoundEmitter
---@field pos position
---@field target _Vector2
---@field movement _Vector2
eHelicopter = {}
eHelicopter.target = { [x]=0, [y]=0 }
eHelicopter.movement = { [x]=0, [y]=0 }

---@class position
---@field x float
---@field y float
---@field z float
eHelicopter.pos = { [x]=0, [y]=0, [z]=20 }

---@param target IsoMovingObject
---@return long @sound reference number
function eHelicopter.playSound()
	eHelicopter.emitter = getWorld().getFreeEmitter(pos.x, pos.y, pos.z)
	ModLogger.debug("Created new helicopter emitter (" .. tostring(result) .. ')')

	return eHelicopter.emitter.playSoundImpl("Helicopter", self)
end


---@return boolean
function eHelicopter.isSoundPlaying() --- may not need
	return eHelicopter.emitter and eHelicopter.emitter.isPlaying("Helicopter") or false
end


function eHelicopter.initPos()
	---@type position
	local pos = eHelicopter.pos
	--places the helicopter on the "edge" of the map (edge being -15k to 15k)
	--50/50 chance for which axis is randomized entirely
	--followed by 50/50 whether the static axis is positive or negative
	--- there might be a more elegant mathematical implementation for this
	if ZombRand(101) > 50 then
		pos.y = ZombRand(0,15000)
		pos.x = 15000
		if ZombRand(101) > 50 then
			pos.x = 0
		end
	else
		pos.x = ZombRand(0,15000)
		pos.y = 15000
		if ZombRand(101) > 50 then
			pos.y = 0
		end
	end
	pos.z = 20
end


---@param targetedPlayer IsoMovingObject | IsoPlayer | IsoGameCharacter @ random player if blank
function eHelicopter.launch(targetedPlayer)

	if not targetedPlayer then
		--the -1 is to offset playerIDs starting at 0
		local numActivePlayers = getNumActivePlayers()-1
		print("numActivePlayers:"..numActivePlayers)
		local randNumFromActivePlayers = ZombRand(numActivePlayers)
		print("randNumFromActivePlayers:"..randNumFromActivePlayers)
		targetedPlayer = getSpecificPlayer(randNumFromActivePlayers)
	end

	print("targetedPlayer: "..targetedPlayer:getDescriptor():getForename().." "..targetedPlayer:getDescriptor():getSurname().." (pos:"..targetedPlayer:getX()..","..targetedPlayer:getY())

	eHelicopter.target:set(targetedPlayer:getX(),targetedPlayer:getY())
	--ModLogger.debug("Set helicopter target to player " .. target.getObjectName())

	eHelicopter.initPos()

	--start playing helicopter sound
	local ref = eHelicopter.playSound()
	ModLogger.debug("Playing helicopter noise (" .. tostring(ref) .. ')')
	eHelicopter.soundRef = ref
	---not sure if ref is useful for anything

	eHelicopter.setUpMovement(eHelicopter.target)

	Events.OnTick.Add(eHelicopter.update)
end


function eHelicopter.update()
	eHelicopter.moveStep(eHelicopter.movement)
	if ( helicopter.pos.x < 15000 and helicopter.pos.y < 15000 ) then
		eHelicopter.unlaunch()
	end
end

function eHelicopter.unlaunch()
	Events.OnTick.Remove(eHelicopter.update)
	eHelicopter.emitter.stopAll()
end

---@param destination _Vector2
function eHelicopter.setUpMovement(destination)

	eHelicopter.movement:set(eHelicopter.pos.x,eHelicopter.pos.y)

	movement:aimAt(destination)
	movement:normalize()
	movement:setLength(speed)

	return movement
end


---@param movement _Vector2
---@param destination _Vector2
function eHelicopter.moveStep(movement)

	eHelicopter.pos.x = eHelicopter.pos.x+movement.x
	eHelicopter.pos.y = eHelicopter.pos.y+movement.y

	print("HELI: X:"..eHelicopter.pos.x.."  Y:"..eHelicopter.pos.y)

	eHelicopter.emitter.setPos(eHelicopter.pos.x,eHelicopter.pos.y,eHelicopter.pos.z)
end


---@param movement _Vector2
---@param destination _Vector2
function eHelicopter.moveDampen(movement, destination)
	movement.x = movement.x * math.max(0.1,((destination.x - position.x)/destination.x))
	movement.y = movement.y * math.max(0.1,((destination.y - position.y)/destination.y))
end


--- Used only for testing purposes
Events.OnCustomUIKey.Add(function(key)
	if key == Keyboard.KEY_0 then
		eHelicopter.launch()
	--elseif key == Keyboard.KEY_9 then---add different behaviors + send away
	--	if eHelicopter.emitter then
	--		eHelicopter.emitter.stopAll()
	--		ModLogger.debug("Stopping helicopter emitter")
	--	else
	--		ModLogger.error("Unable to find helicopter emitter!")
	--	end
	end
end)
