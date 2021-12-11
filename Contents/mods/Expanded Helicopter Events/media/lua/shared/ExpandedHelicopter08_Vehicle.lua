--[[EXPANDEDHELICOPTERS_TYPE_PATHS = {["Base.UH1H"]=true}

ISLockVehicleDoor = ISLockVehicleDoor or ISBaseTimedAction:derive("ISLockVehicleDoor")

ISLockVehicleDoor_isValid = ISLockVehicleDoor.isValid

function ISLockVehicleDoor:isValid()
	print("DEBUG DOOR LOCK: "..self.vehicle:getScriptName())
	if not EXPANDEDHELICOPTERS_TYPE_PATHS[vehicle:getScriptName()] then
		return self.part:getDoor() and not self.part:getDoor():isLocked()
	else
		return false
	end
end
]]


--[[
local VehicleCommands = {}
local Commands = {}

Commands_setDoorLocked = Commands.setDoorLocked
function Commands:setDoorLocked(player, args)
	local vehicle = getVehicleById(args.vehicle)
	if vehicle then

		print("DEBUG DOOR LOCK: "..vehicle:getScriptName())
		if not EXPANDEDHELICOPTERS_TYPE_PATHS[vehicle:getScriptName()] then
			Commands_setDoorLocked(player, args)
		end
	end
end

BaseVehicle_canLockDoor = BaseVehicle.canLockDoor
function BaseVehicle:canLockDoor(vehiclePart, isoGameCharacter)
	print("DEBUG DOOR LOCK: "..self:getScriptName())
	if EXPANDEDHELICOPTERS_TYPE_PATHS[self:getScriptName()] then
		return false
	else
		return BaseVehicle_canLockDoor(vehiclePart, isoGameCharacter)
	end
end

BaseVehicle_canUnlockDoor = BaseVehicle.canUnlockDoor
function BaseVehicle:canUnlockDoor(vehiclePart, isoGameCharacter)
	print("DEBUG DOOR LOCK: "..self:getScriptName())
	if EXPANDEDHELICOPTERS_TYPE_PATHS[self:getScriptName()] then
		return true
	else
		return BaseVehicle_canLockDoor(vehiclePart, isoGameCharacter)
	end
end]]