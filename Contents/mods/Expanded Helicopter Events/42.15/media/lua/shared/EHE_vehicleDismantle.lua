require "Vehicles/TimedActions/ISRemoveBurntVehicle"

EHE_vehicleDismantle = EHE_vehicleDismantle or {}

function EHE_vehicleDismantle.metalToItems(metalKg)
    local bars   = math.floor(metalKg / 5)
    local sheets = math.floor((metalKg - bars * 5) / 0.5)
    return bars, sheets
end

EHE_vehicleDismantle.SKILL_REQ = 2

function EHE_vehicleDismantle.predicateBlowTorch(item)
    return (item ~= nil) and (item:hasTag(ItemTag.BLOW_TORCH) or item:getType() == "BlowTorch") and (item:getCurrentUses() > 0)
end

function EHE_vehicleDismantle.predicateWeldingMask(item)
    return item:hasTag(ItemTag.WELDING_MASK) or item:getType() == "WeldingMask"
end

function EHE_vehicleDismantle.isEligibleVehicle(vehicle)
    return vehicle and vehicle:getModData().EHE_metalKg ~= nil
end

function EHE_vehicleDismantle.meetsSkill(player)
    return player:getPerkLevel(Perks.MetalWelding) >= EHE_vehicleDismantle.SKILL_REQ
end


EHE_DismantleVehicleAction = ISRemoveBurntVehicle:derive("EHE_DismantleVehicleAction")

function EHE_DismantleVehicleAction:isValid()
    if not EHE_vehicleDismantle.predicateBlowTorch(self.character:getPrimaryHandItem()) then return false end
    return self.vehicle and not self.vehicle:isRemovedFromWorld()
end

function EHE_DismantleVehicleAction:update()
    ISRemoveBurntVehicle.update(self)
    self.item:setJobType(getText("ContextMenu_EHE_DismantleWreck"))
end

function EHE_DismantleVehicleAction:complete()
    local torch = self.character and self.character:getPrimaryHandItem()
    if not EHE_vehicleDismantle.predicateBlowTorch(torch) or not EHE_vehicleDismantle.meetsSkill(self.character) then return false end
    if not EHE_vehicleDismantle.isEligibleVehicle(self.vehicle) then return false end

    local metalKg = self.vehicle:getModData().EHE_metalKg or 0
    local bars, sheets = EHE_vehicleDismantle.metalToItems(metalKg)
    for i=1, bars do Actions.addOrDropItem(self.character, instanceItem("Base.MetalBar")) end
    for i=1, sheets do Actions.addOrDropItem(self.character, instanceItem("Base.SmallSheetMetal")) end

    local drain = math.min(torch:getCurrentUses(), math.floor(metalKg * 0.4))
    for i=1, drain do torch:Use(false, false, true) end

    addXp(self.character, Perks.MetalWelding, math.floor(metalKg * 2))
    self.vehicle:permanentlyRemove()
    return true
end

function EHE_DismantleVehicleAction:getDuration()
    if self.vehicle == nil then return 0 end
    if self.character:isMechanicsCheat() or self.character:isTimedActionInstant() then return 10 end
    return math.max(600, math.floor((self.vehicle:getModData().EHE_metalKg or 0) * 80))
end

function EHE_DismantleVehicleAction:new(character, vehicle)
    local o = ISBaseTimedAction.new(self, character)
    if EHE_vehicleDismantle.isEligibleVehicle(vehicle) then o.vehicle = vehicle end
    o.stopOnWalk = false
    o.stopOnRun = false
    o.maxTime = o:getDuration()
    return o
end

return EHE_vehicleDismantle
