EHE_vehicleDismantle = EHE_vehicleDismantle or {}

function EHE_vehicleDismantle.metalToItems(metalKg)
    local bars   = math.floor(metalKg / 5)
    local sheets = math.floor((metalKg - bars * 5) / 0.5)
    return bars, sheets
end

if isClient() then return EHE_vehicleDismantle end

local SKILL_REQ = 2

local function hasTorch(player)
    for i = 0, player:getInventory():getItems():size() - 1 do
        local item = player:getInventory():getItems():get(i)
        if item:getType() == "BlowTorch" and item:getCurrentAmmo() > 0 then
            return item
        end
    end
end

local function hasMask(player)
    local inv = player:getInventory()
    return inv:getFirstTaggedItem("WeldingMask") or inv:getFirstTaggedItem("WeldingMask_equipped")
end

local function isEligibleVehicle(vehicle)
    return vehicle:getModData().EHE_metalKg ~= nil
end

local function meetsSkill(player)
    return player:getPerkLevel(Perks.MetalWelding) >= SKILL_REQ
end


EHE_DismantleVehicleAction = ISBaseTimedAction:derive("EHE_DismantleVehicleAction")

function EHE_DismantleVehicleAction:new(player, vehicle)
    local o = ISBaseTimedAction.new(self, player)
    o.vehicle  = vehicle
    o.torch    = hasTorch(player)
    local metalKg = vehicle:getModData().EHE_metalKg or 0
    o.maxTime  = math.max(600, math.floor(metalKg * 80))
    return o
end

function EHE_DismantleVehicleAction:isValid()
    if not self.vehicle or not isEligibleVehicle(self.vehicle) then return false end
    if not hasTorch(self.character) then return false end
    if not hasMask(self.character)  then return false end
    if not meetsSkill(self.character) then return false end
    return true
end

function EHE_DismantleVehicleAction:update()
    self.character:setMetabolicTarget(Metabolics.HeavyWork)
end

function EHE_DismantleVehicleAction:perform()
    local torch = hasTorch(self.character)
    if torch then
        local drain = math.min(torch:getCurrentAmmo(), math.floor((self.vehicle:getModData().EHE_metalKg or 5) * 0.4))
        torch:setCurrentAmmo(torch:getCurrentAmmo() - drain)
    end
    sendClientCommand(self.character, "EHE_vehicleDismantle", "dismantle", {
        vehicleId = self.vehicle:getId(),
    })
    self.character:getXp():AddXP(Perks.MetalWelding, math.floor((self.vehicle:getModData().EHE_metalKg or 0) * 2))
    ISBaseTimedAction.perform(self)
end

function EHE_DismantleVehicleAction:stop()
    ISBaseTimedAction.stop(self)
end


local function onFillWorldObjectContextMenu(playerIndex, context, worldobjects, test)
    local player = getSpecificPlayer(playerIndex)
    if not player then return end

    for _, obj in ipairs(worldobjects) do
        if instanceof(obj, "BaseVehicle") and isEligibleVehicle(obj) then
            if test then return true end

            local option = context:addOption(getText("ContextMenu_EHE_DismantleWreck"), worldobjects, nil)
            local subMenu = ISContextMenu:getNew(context)
            context:addSubMenu(option, subMenu)

            if not meetsSkill(player) then
                option.notAvailable = true
                option.toolTip = ISToolTip:new()
                option.toolTip.description = getText("Tooltip_EHE_NeedWeldingSkill", SKILL_REQ)
            elseif not hasTorch(player) then
                option.notAvailable = true
                option.toolTip = ISToolTip:new()
                option.toolTip.description = getText("Tooltip_EHE_NeedTorch")
            elseif not hasMask(player) then
                option.notAvailable = true
                option.toolTip = ISToolTip:new()
                option.toolTip.description = getText("Tooltip_EHE_NeedMask")
            else
                local metalKg = obj:getModData().EHE_metalKg
                local bars, sheets = EHE_vehicleDismantle.metalToItems(metalKg)
                option.toolTip = ISToolTip:new()
                option.toolTip.description = string.format("~%d metal bars, ~%d sheet metal", bars, sheets)
                subMenu:addOption(getText("ContextMenu_EHE_DismantleWreck"), worldobjects,
                    function() ISTimedActionQueue.add(EHE_DismantleVehicleAction:new(player, obj)) end)
            end
        end
    end
end

Events.OnFillWorldObjectContextMenu.Add(onFillWorldObjectContextMenu)

return EHE_vehicleDismantle
